#!/usr/bin/env python3

"""Given component scores for an array of hapsets, with one .tar.gz file per hapset
containing scores for that hapset, extract all score files to local files, and
make lists of the extracted files.
"""

import os
import os.path
import argparse
import subprocess

import argparse
import csv
import collections
import concurrent.futures
import contextlib
import copy
import functools
import glob
import gzip
import io
import json
import logging
import math
import multiprocessing
import os
import os.path
import pathlib
import random
import re
import shutil
import subprocess
import sys
import tempfile
import time

# * Utils

_log = logging.getLogger(__name__)
logging.basicConfig(level=logging.DEBUG,
                    format='%(asctime)s %(levelname)s %(message)s')

MAX_INT32 = (2 ** 31)-1

def dump_file(fname, value):
    """store string in file"""
    with open(fname, 'w')  as out:
        out.write(str(value))

def _pretty_print_json(json_val, sort_keys=True):
    """Return a pretty-printed version of a dict converted to json, as a string."""
    return json.dumps(json_val, indent=4, separators=(',', ': '), sort_keys=sort_keys)

def _write_json(fname, json_val):
    dump_file(fname=fname, value=_pretty_print_json(json_val))

def _load_dict_sorted(d):
    return collections.OrderedDict(sorted(d.items()))

def _json_loads(s):
    return json.loads(s.strip(), object_hook=_load_dict_sorted, object_pairs_hook=collections.OrderedDict)

def _json_loadf(fname):
    return _json_loads(slurp_file(fname))

json_loadf = _json_loadf

def slurp_file(fname, maxSizeMb=50):
    """Read entire file into one string.  If file is gzipped, uncompress it on-the-fly.  If file is larger
    than `maxSizeMb` megabytes, throw an error; this is to encourage proper use of iterators for reading
    large files.  If `maxSizeMb` is None or 0, file size is unlimited."""
    fileSize = os.path.getsize(fname)
    if maxSizeMb  and  fileSize > maxSizeMb*1024*1024:
        raise RuntimeError('Tried to slurp large file {} (size={}); are you sure?  Increase `maxSizeMb` param if yes'.
                           format(fname, fileSize))
    with open_or_gzopen(fname) as f:
        return f.read()

def open_or_gzopen(fname, *opts, **kwargs):
    mode = 'r'
    open_opts = list(opts)
    assert type(mode) == str, "open mode must be of type str"

    # 'U' mode is deprecated in py3 and may be unsupported in future versions,
    # so use newline=None when 'U' is specified
    if len(open_opts) > 0:
        mode = open_opts[0]
        if sys.version_info[0] == 3:
            if 'U' in mode:
                if 'newline' not in kwargs:
                    kwargs['newline'] = None
                open_opts[0] = mode.replace("U","")

    # if this is a gzip file
    if fname.endswith('.gz'):
        # if text read mode is desired (by spec or default)
        if ('b' not in mode) and (len(open_opts)==0 or 'r' in mode):
            # if python 2
            if sys.version_info[0] == 2:
                # gzip.open() under py2 does not support universal newlines
                # so we need to wrap it with something that does
                # By ignoring errors in BufferedReader, errors should be handled by TextIoWrapper
                return io.TextIOWrapper(io.BufferedReader(gzip.open(fname)))

        # if 't' for text mode is not explicitly included,
        # replace "U" with "t" since under gzip "rb" is the
        # default and "U" depends on "rt"
        gz_mode = str(mode).replace("U","" if "t" in mode else "t")
        gz_opts = [gz_mode]+list(opts)[1:]
        return gzip.open(fname, *gz_opts, **kwargs)
    else:
        return open(fname, *open_opts, **kwargs)

def find_one_file(glob_pattern):
    """If exactly one file matches `glob_pattern`, returns the path to that file, else fails."""
    matching_files = list(glob.glob(glob_pattern))
    if len(matching_files) == 1:
        return os.path.realpath(matching_files[0])
    raise RuntimeError(f'find_one_file({glob_pattern}): {len(matching_files)} matches - {matching_files}')

def available_cpu_count():
    """
    Return the number of available virtual or physical CPUs on this system.
    The number of available CPUs can be smaller than the total number of CPUs
    when the cpuset(7) mechanism is in use, as is the case on some cluster
    systems.

    Adapted from http://stackoverflow.com/a/1006301/715090
    """

    cgroup_cpus = MAX_INT32
    try:
        def get_cpu_val(name):
            return float(slurp_file('/sys/fs/cgroup/cpu/cpu.'+name).strip())
        cfs_quota = get_cpu_val('cfs_quota_us')
        if cfs_quota > 0:
            cfs_period = get_cpu_val('cfs_period_us')
            _log.debug('cfs_quota %s, cfs_period %s', cfs_quota, cfs_period)
            cgroup_cpus = max(1, int(cfs_quota / cfs_period))
    except Exception as e:
        pass

    proc_cpus = MAX_INT32
    try:
        with open('/proc/self/status') as f:
            status = f.read()
        m = re.search(r'(?m)^Cpus_allowed:\s*(.*)$', status)
        if m:
            res = bin(int(m.group(1).replace(',', ''), 16)).count('1')
            if res > 0:
                proc_cpus = res
    except IOError:
        pass

    _log.debug('cgroup_cpus %d, proc_cpus %d, multiprocessing cpus %d',
               cgroup_cpus, proc_cpus, multiprocessing.cpu_count())
    return min(cgroup_cpus, proc_cpus, multiprocessing.cpu_count())

def execute(action, **kw):
    succeeded = False
    try:
        _log.debug('Running command: %s', action)
        subprocess.check_call(action, shell=True, **kw)
        succeeded = True
    finally:
        _log.debug('Returned from running command: succeeded=%s, command=%s', succeeded, action)

def chk(cond, msg):
    if not cond:
        raise RuntimeError(f'chk failed: {msg}')

def mkdir_p(dirpath):
    ''' Verify that the directory given exists, and if not, create it.
    '''
    try:
        os.makedirs(dirpath)
    except OSError as exc:  # Python >2.5
        if exc.errno == errno.EEXIST and os.path.isdir(dirpath):
            pass
        else:
            raise

def extract_hapset_component_scores(args):
    hapset_component_scores_files = parse_file_list(args.hapset_component_scores)

    component2scores = collections.defaultdict(list)

    for hapset_num, hapset_component_scores_file in enumerate(hapset_component_scores_files):
        chk(hapset_components_scores_file.endswith('.tar.gz'))
        hapset_dirname = os.path.realpath(f'{hapset_num:04}_' + os.path.basename(hapset_components_scores_file)[:-len('.tar.gz')])
        mkdir_p(hapset_dirname)
        execute(f'tar -xvzf {hapset_component_scores_file} -C {hapset_dirname}')
        manifest = json_loadf(find_one_file(os.path.join(hapset_dirname, '*.manifest.json')))

        for component in args.components:
            component2scores[component].append(find_one_file(os.path.join(hapset_dirname, manifest[component])))
            
    for component in args.components:
        scores_files_fname = f'{args.out_fnames_prefix}.{component}.scores_files.txt'
        dump_file(fname=scores_files_fname, value='\n'.join(component2scores[component]))
        

def parse_file_list(z):
    z_orig = copy.deepcopy(z)
    z = list(z or [])
    result = []
    while z:
        f = z.pop()
        if not f.startswith('@'):
            result.append(f)
        else:
            z.extend(slurp_file(f[1:]).strip().split('\n'))
    _log.info(f'parse_file_list: parsed {z_orig} as {result}')
    return result[::-1]

def parse_args():
    parser = argparse.ArgumentParser()

    parser.add_argument('--hapset-component-scores', required=True, help='files containing component scores per hapset')
    parser.add_argument('--components', required=True,
                        choices=('ihs', 'ihh12', 'nsl', 'delihh', 'xpehh', 'fst', 'delDAF', 'derFreq', 'iSAFE'),
                        nargs='+', help='which component scores to extract')
    parser.add_argument('--out-fnames-prefix', required=True, help='prefix output filenames with this prefix')
    
    return parser.parse_args()


if __name__ == '__main__':
    extract_hapset_component_scores(parse_args())
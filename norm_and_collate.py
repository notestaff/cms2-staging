#!/usr/bin/env python3

"""Normalize component scores, and collate the results.
"""

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

import pandas as pd

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

# * Parsing args

def parse_args():
    parser = argparse.ArgumentParser()

    parser.add_argument('--input-json', help='inputs passed as json')
    parser.add_argument('--out-normed-collated', help='output file for normed and collated results')

    # parser.add_argument('--pops-info-json', help='info about populations')
    # parser.add_argument('--sel-pop', type=int, help='putatively selected pop')

    # parser.add_argument('--ihs-raw', help='raw ihs scores')
    # parser.add_argument('--nsl-raw', help='raw nsl scores')
    # parser.add_argument('--ihh12-raw', help='raw ihh12 scores')
    # parser.add_argument('--xpehh-raw', nargs='+', help='raw xpehh scores')

    # parser.add_argument('--norm-bins-ihs', help='IHS bins data from neutral sims, for normalization')
    # parser.add_argument('--norm-bins-nsl', help='IHS bins data from neutral sims, for normalization')
    # parser.add_argument('--norm-bins-ihh12', help='IHS bins data from neutral sims, for normalization')
    
    
    return parser.parse_args()

# * orig_main

def orig_main(args):
    cmsdir = args.cmsdir # "/data/ilya-work/proj/cms2-work/cms/cms/cms/"
    writedir = args.writedir # "/data/mytmp/run5/"
    #"/idi/sabeti-scratch/jvitti/remodel/run2/"
    simRecomFile =  args.simRecomFile # "/idi/sabeti-scratch/jvitti/params/test_recom.recom"
    pops = args.pops or [1,2,3,4]

    #basedir = writedir + model + "_" + regime + "_sel" + str(selpop) + "/"
    basedir = writedir + model + "_" + regime + "/"
    
    tped_dir = basedir + "tpeds/"
    thispop = selpop

    replicate_idstring = "rep" + str(irep)
    replicate_idstring2 = replicate_idstring + "_pop" + str(thispop)
    
    tped_filename = tped_dir + replicate_idstring + "_0_" + str(selpop) + ".tped"
    if not os.path.isfile(tped_filename):
        tped_filename += ".gz"                    
    if not os.path.isfile(tped_filename):
        print(('missing: ', tped_filename))    
        sys.exit(0)                

    ihh12_commandstring = "/ilya/miniconda3/envs/selscan-env/bin/selscan"
    #"python " + cmsdir + "scans.py selscan_ihh12" 
    ihh12_unnormedfileprefix = basedir + "ihh12/" + replicate_idstring2
    #ihh12_argstring = tped_filename + " " + ihh12_unnormedfileprefix + " --threads 7 "
    ihh12_unnormedfilename = ihh12_unnormedfileprefix + ".ihh12.out"
    
    ihh12_argstring = " --ihh12 --tped " + tped_filename + " --out " + ihh12_unnormedfileprefix + " --threads 8"
    ihh12_fullcmd = ihh12_commandstring + " " + ihh12_argstring
    
    print(ihh12_fullcmd)
    if not os.path.isfile(ihh12_unnormedfilename)  and not os.path.isfile(ihh12_unnormedfilename + ".gz"):
        execute(ihh12_fullcmd)


    ihs_commandstring = "/ilya/miniconda3/envs/selscan-env/bin/selscan"
    #ihs_commandstring = "python " + cmsdir + "scans.py selscan_ihs"
    ihs_outfileprefix = basedir + "ihs/" + replicate_idstring2
    ihs_unnormedfile = ihs_outfileprefix + ".ihs.out"
    #ihs_argstring = tped_filename + " " + ihs_outfileprefix + " --threads 7 "
    ihs_argstring = " --ihs --ihs-detail --tped " + tped_filename + " --out " + ihs_outfileprefix + " --threads 8"
    ihs_fullcmd = ihs_commandstring + " " + ihs_argstring
    #ihs_normedfile = ihs_unnormedfile + ".norm"
    print(ihs_fullcmd)
    if not os.path.isfile(ihs_unnormedfile) and not os.path.isfile(ihs_unnormedfile + ".gz"):
        execute(ihs_fullcmd)
    
    delihh_commandstring = "python " + cmsdir + "composite.py delihh_from_ihs"
    delihh_unnormedfile =  basedir + "delihh/" + replicate_idstring2
    delihh_argstring = ihs_unnormedfile + " "+ delihh_unnormedfile
    delihh_fullcmd = delihh_commandstring + " " + delihh_argstring 
    delihh_normedfile = delihh_unnormedfile + ".norm"
    print(delihh_fullcmd)
    if not os.path.isfile(delihh_unnormedfile) and not os.path.isfile(delihh_unnormedfile + ".gz"):
        execute(delihh_fullcmd)        
    
    nsl_commandstring = "/ilya/miniconda3/envs/selscan-env/bin/selscan"
    #nsl_commandstring = "python " + cmsdir + "scans.py selscan_nsl" 
    nsl_unnormedfileprefix = basedir + "nsl/" + replicate_idstring2
    #nsl_argstring = tped_filename + " " + nsl_unnormedfileprefix
    nsl_argstring = " --nsl --tped " + tped_filename + " --out " + nsl_unnormedfileprefix + " --threads 8"
    nsl_fullcmd = nsl_commandstring + " " + nsl_argstring
    nsl_unnormedfilename = nsl_unnormedfileprefix + ".nsl.out"
    print(nsl_fullcmd)
    if not os.path.isfile(nsl_unnormedfilename)  and not os.path.isfile(nsl_unnormedfilename + ".gz"):
        execute(nsl_fullcmd)

    tpeddir = tped_dir


    altpops = pops[:]
    altpops.remove(int(thispop))
    for altpop in altpops:
        #xpehh_commandstring = "python " + cmsdir + "scans.py selscan_xpehh --threads 7"
        xpehh_commandstring = "/ilya/miniconda3/envs/selscan-env/bin/selscan"
        #tped2 = tpeddir + "rep" + str(irep) + "_" + str(altpop) + ".tped"
        #tped_filename2 = get_tped_filename(selpop, irep, ancestralpop, altpop, model, tped_dir)
        tped_filename2 = tped_dir + replicate_idstring + "_0_" + str(altpop) + ".tped"
        if not os.path.isfile(tped_filename2):
            tped_filename2 += ".gz"                    
    
        xpehh_outfileprefix = basedir + "xpehh/" + replicate_idstring2 + "_vs" + str(altpop)
        xpehh_unnormedfile = basedir + "xpehh/" + replicate_idstring2 + "_vs" + str(altpop) + ".xpehh.out"
        #xpehh_argumentstring = tped_filename + " " + xpehh_outfileprefix + " " + tped_filename2 + " --threads 8"
        xpehh_argumentstring = " --xpehh --tped " + tped_filename + " --out " + xpehh_outfileprefix + " --threads 8 --tped-ref " + tped_filename2
        xpehh_fullcmd = xpehh_commandstring + " " + xpehh_argumentstring
        print(xpehh_fullcmd)
        if not os.path.isfile(xpehh_unnormedfile) and not os.path.isfile(xpehh_unnormedfile + ".gz"):
            execute(xpehh_fullcmd)

        #fstdeldaf_commandstring = "python " + cmsdir + "composite.py freqscores"
        #fstdeldaf_outfilename = basedir + "freqs/"  + replicate_idstring2 + "_vs" + str(altpop)
        #fstdeldaf_argumentstring = tped_filename + " " + tped_filename2 + " " + simRecomFile + " " + fstdeldaf_outfilename 
        #fstdeldaf_fullcmd = fstdeldaf_commandstring + " " + fstdeldaf_argumentstring 
        #print(fstdeldaf_fullcmd)
        #if not os.path.isfile(fstdeldaf_outfilename):
        #    execute(fstdeldaf_fullcmd)

# * compute_component_scores

def compute_component_scores(args):
    args.threads = min(args.threads, available_cpu_count())
    shutil.copyfile(args.replica_info, f'{args.replica_id_string}.replica_info.json')
    replicaInfo = _json_loadf(args.replica_info)
    pop_id_to_idx = dict([(pop_id, idx) for idx, pop_id in enumerate(replicaInfo['popIds'])])
    sel_pop_idx = pop_id_to_idx[args.sel_pop]
    sel_pop_tped = replicaInfo["tpedFiles"][sel_pop_idx]

    selscan_cmd_base = \
        f'selscan --threads {args.threads} --tped {sel_pop_tped} ' \
        f'--out {args.out_basename}'
    for component in args.components:
        alt_pop_tped = '' if component not in ('xpehh',) else f' --tped-ref {replicaInfo["tpedFiles"][pop_id_to_idx[args.alt_pop]]} '
        cmd = f'{selscan_cmd_base} {alt_pop_tped} --{component}'
        execute(cmd)

    if False:
        execute(f'selscan --threads {args.threads} --ihh12 --tped {replicaInfo["tpedFiles"][sel_pop_idx]} '
                f'--out {args.replica_id_string} ')
        execute(f'selscan --threads {args.threads} --ihs --ihs-detail --tped {replicaInfo["tpedFiles"][sel_pop_idx]} '
                f'--out {args.replica_id_string} ')
        execute(f'selscan --threads {args.threads} --nsl --tped {replicaInfo["tpedFiles"][sel_pop_idx]} '
                f'--out {args.replica_id_string} ')

    if False:
        for alt_pop in replicaInfo['popIds']:
            if alt_pop == args.sel_pop: continue
            alt_pop_idx = pop_id_to_idx[alt_pop]
            execute(f'selscan --threads {args.threads} --xpehh --tped {replicaInfo["tpedFiles"][this_pop_idx]} '
                    f'--tped-ref {replicaInfo["tpedFiles"][alt_pop_idx]} '
                    f'--out {args.replica_id_string}__altpop_{alt_pop} ')

    # if args.ihs_bins:
    #     execute(f'norm --ihs --bins {args.n_bins_ihs} --load-bins {args.ihs_bins} --files {args.replica_id_string}.ihs.out '
    #             f'--log {args.replica_id_string}.ihs.out.{args.n_bins_ihs}bins.norm.log ')
    # else:
    #     execute(f'touch {args.replica_id_string}.ihs.out.{args.n_bins_ihs}bins.norm '
    #             f'{args.replica_id_string}.ihs.out.{args.n_bins_ihs}bins.norm.log')

    # if args.nsl_bins:
    #     execute(f'norm --nsl --bins {args.n_bins_nsl} --load-bins {args.nsl_bins} --files {args.replica_id_string}.nsl.out '
    #             f'--log {args.replica_id_string}.nsl.out.{args.n_bins_nsl}bins.norm.log ')
    # else:
    #     execute(f'touch {args.replica_id_string}.nsl.out.{args.n_bins_nsl}bins.norm '
    #             f'{args.replica_id_string}.nsl.out.{args.n_bins_nsl}bins.norm.log')

    # if args.ihh12_bins:
    #     execute(f'norm --ihh12 --load-bins {args.ihh12_bins} --files {args.replica_id_string}.ihh12.out '
    #             f'--log {args.replica_id_string}.ihh12.out.norm.log ')
    # else:
    #     execute(f'touch {args.replica_id_string}.ihh12.out.norm {args.replica_id_string}.ihh12.out.norm.log')

def normalize_and_collate_scores(args):

    def descr_df(df, msg):
        """Describe a DataFrame"""
        return
        print('===BEG=======================\n', msg)
        print(df.describe(), '\n')
        df.info(verbose=True, null_counts=True)
        print('===END=======================\n', msg)
        

    inps = _json_loadf(args.input_json)
    execute(f'norm --ihs --bins {inps["n_bins_ihs"]} --load-bins {inps["norm_bins_ihs"]} --files {inps["ihs_out"]} '
            f'--log {inps["ihs_out"]}.{inps["n_bins_ihs"]}bins.norm.log ')

    ihs_normed = pd.read_table(f'{inps["ihs_out"]}.{inps["n_bins_ihs"]}bins.norm',
                               names='id pos p1 ihh1 ihh2 ihs ihsnormed ihs_outside_cutoff'.split(), index_col=('id', 'pos', 'p1'),
                               low_memory=False)

    descr_df(ihs_normed, 'ihs_normed')

    collated = ihs_normed

    execute(f'norm --nsl --bins {inps["n_bins_nsl"]} --load-bins {inps["norm_bins_nsl"]} --files {inps["nsl_out"]} '
            f'--log {inps["nsl_out"]}.{inps["n_bins_nsl"]}bins.norm.log ')

    nsl_normed = pd.read_table(f'{inps["nsl_out"]}.{inps["n_bins_nsl"]}bins.norm',
                               names='id pos p1 ihh1_nsl ihh2_nsl nsl nslnormed nsl_outside_cutoff'.split(), index_col=('id', 'pos', 'p1'),
                               low_memory=False)

    descr_df(nsl_normed, 'nsl_normed')
    collated = collated.join(nsl_normed, how='outer')
    descr_df(collated, 'collated after nsl_normed')

    execute(f'norm --ihh12 --bins {inps["n_bins_ihh12"]} --load-bins {inps["norm_bins_ihh12"]} --files {inps["ihh12_out"]} '
            f'--log {inps["ihh12_out"]}.norm.log ')

    ihh12_normed = pd.read_table(f'{inps["ihh12_out"]}.norm', index_col=('id', 'pos', 'p1'),
                                 low_memory=False).rename(columns={'crit': 'ihh12_crit'})

    descr_df(ihh12_normed, 'ihh12_normed')
    collated = collated.join(ihh12_normed, how='outer')
    descr_df(collated, 'collated after ihh12_normed')

    for other_pop_idx, (xpehh_out, norm_bins_xpehh) in enumerate(zip(inps["xpehh_out"], inps["norm_bins_xpehh"])):
        execute(f'norm --xpehh --bins {inps["n_bins_xpehh"]} --load-bins {norm_bins_xpehh} --files {xpehh_out} '
                f'--log {xpehh_out}.norm.log ')
        xpehh_normed = pd.read_table(xpehh_out+".norm", index_col=('id', 'pos', 'p1'), low_memory=False).add_suffix(f'_{other_pop_idx}')
        descr_df(xpehh_normed, f'xpehh_normed_{other_pop_idx}')
        collated = collated.join(xpehh_normed, how='outer')
        descr_df(collated, f'collated after xpehh_normed_{other_pop_idx}')

    collated['max_xpehh'] = collated.filter(like='normxpehh').max(axis='columns')
    descr_df(collated, 'collated final')
    collated.reset_index().\
        rename(columns={'ihsnormed':'ihs_normed', 'nslnormed': 'nsl_normed', 'normihh12': 'ihh12_normed',
                        'max_xpehh': 'max_xpehh_normed'})\
                    .to_csv(args.out_normed_collated, sep='\t', na_rep='nan', index=False)
        
    

    #
    # compute fst and deltadaf
    #
 
if __name__=='__main__':
  #compute_component_scores(parse_args())
  normalize_and_collate_scores(parse_args())

version 1.0

#
# tofix:

#   - fix odd ihs norm scores
#   - add taking max of relevant xpop scores
#

#
#   - fix norm program to:
#      - not load all files in memory
#      - use accurate accumulators for sum and sum-of-sq

#
# jvitti's score norming incl xpop
# /idi/sabeti-scratch/jvitti/cms/cms/dists/scores_func.py
#

#
#      - add norming of metrics beyond ihs
#

#   - fix workflow:
#      - group norm computation into blocks, then flatten
#

#
# WDL workflow: cms2_component_scores
#
# Computation of CMS2 component scores
#

struct SweepInfo {
  Int  selPop
  Float selGen
  Int selBegPop
  Float selBegGen
  Float selCoeff
  Float selFreq
}

struct ModelInfo {
  String modelId
  Array[String] modelIdParts
  Array[Int] popIds
  Array[String] popNames
  SweepInfo sweepInfo
}

struct ReplicaId {
  Int replicaNumGlobal
  Int replicaNumGlobalOutOf
  Int blockNum
  Int replicaNumInBlock
  Int randomSeed
}

struct ReplicaInfo {
  ReplicaId replicaId
  ModelInfo modelInfo

  File        tpeds_tar_gz

  Boolean succeeded
  Float durationSeconds
}

task compute_normalization_values {
  meta {
    description: "Compute CMS2 normalization values"
    email: "ilya_shl@alum.mit.edu"
  }
  input {
    Array[File] ihs_out
    Array[File] nsl_out
    Array[File] ihh12_out

    Int threads
    Int mem_base_gb
    Int mem_per_thread_gb
    Int local_disk_gb
    String docker
  }

  command <<<
    norm --ihs --files @~{write_lines(ihs_out)} --save-bins norm_bins_ihs.dat --only-save-bins
    norm --nsl --files @~{write_lines(nsl_out)} --save-bins norm_bins_nsl.dat --only-save-bins
    norm --ihh12 --files @~{write_lines(ihh12_out)} --save-bins norm_bins_ihh12.dat --only-save-bins
  >>>

  output {
    File norm_bins_ihs = "norm_bins_ihs.dat"
    File norm_bins_nsl = "norm_bins_nsl.dat"
    File norm_bins_ihh12 = "norm_bins_nsl.dat"
  }

  runtime {
    docker: docker
    memory: (mem_base_gb  +  threads * mem_per_thread_gb) + " GB"
    cpu: threads
    disks: "local-disk " + local_disk_gb + " LOCAL"
  }
}


task compute_normed_scores {
  meta {
    description: "Compute CMS2 normed scores"
    email: "ilya_shl@alum.mit.edu"
  }
  input {
    Array[File] ihs_raw
    File ihs_bins

    Array[File] nsl_raw
    File nsl_bins

    Array[File] ihh12_raw
    File ihh12_bins

    Int threads
    Int mem_base_gb
    Int mem_per_thread_gb
    Int local_disk_gb
    String docker
  }

  String ihs_bins_log = ihs_bins + ".log"
  String nsl_bins_log = nsl_bins + ".log"
  String ihh12_bins_log = ihh12_bins + ".log"

  command <<<
    cp ~{write_lines(ihs_raw)} ihs_raw_files.list.txt
    norm --ihs --files @ihs_raw_files.list.txt --load-bins ~{ihs_bins} --save-bins norm_bins_used_ihs.dat --log ~{ihs_bins_log}
    cat ihs_raw_files.list.txt | xargs -I YYY -- sh -c 'mv YYY.100bins.normed normed_$(basename YYY)'

    cp ~{write_lines(nsl_raw)} nsl_raw_files.list.txt
    norm --nsl --files @nsl_raw_files.list.txt --load-bins ~{nsl_bins} --save-bins norm_bins_used_nsl.dat --log ~{nsl_bins_log}
    cat nsl_raw_files.list.txt | xargs -I YYY -- sh -c 'mv YYY.100bins.normed normed_$(basename YYY)'

    cp ~{write_lines(ihh12_raw)} ihh12_raw_files.list.txt
    norm --ihh12 --files @ihh12_raw_files.list.txt --load-bins ~{ihh12_bins} --save-bins norm_bins_used_ihh12.dat --log ~{ihh12_bins_log}
    cat ihh12_raw_files.list.txt | xargs -I YYY -- sh -c 'mv YYY.normed normed_$(basename YYY)'
  >>>

  output {
    File norm_bins_ihs = "norm_bins_used_ihs.dat"
    Array[File] normed_ihs_out = prefix("normed_", ihs_raw)
    File norm_bins_ihs_log = ihs_bins_log
    File norm_bins_nsl = "norm_bins_used_nsl.dat"
    Array[File] normed_nsl_out = prefix("normed_", nsl_raw)
    File norm_bins_nsl_log = nsl_bins_log
    File norm_bins_ihh12 = "norm_bins_used_ihh12.dat"
    Array[File] normed_ihh12_out = prefix("normed_", ihh12_raw)
    File norm_bins_ihh12_log = ihh12_bins_log
  }

  runtime {
    docker: docker
    memory: (mem_base_gb  +  threads * mem_per_thread_gb) + " GB"
    cpu: threads
    disks: "local-disk " + local_disk_gb + " LOCAL"
  }
}


task compute_cms2_components_for_one_replica {
  meta {
    description: "Compute CMS2 component scores"
    email: "ilya_shl@alum.mit.edu"
  }
  input {
#    ReplicaInfo replicaInfo
    File replica_output
    Int sel_pop
    File script
    File? ihs_bins
    File? nsl_bins
    File? ihh12_bins

    Int threads
    Int mem_base_gb
    Int mem_per_thread_gb
    Int local_disk_gb
    String docker
  }
#  String modelId = replicaInfo.modelInfo.modelId
#  Int replicaNumGlobal = replicaInfo.replicaId.replicaNumGlobal
#  String replica_id_string = "model_" + modelId + "__rep_" + replicaNumGlobal + "__selpop_" + sel_pop
  String replica_id_string = basename(replica_output)
  String script_used_name = "script-used." + basename(script)
  String ihs_out_fname = replica_id_string + ".ihs.out"
  String ihs_normed_out_fname = replica_id_string + ".ihs.out.100bins.norm"
  String ihs_normed_out_log_fname = ihs_normed_out_fname + ".log"
  String nsl_normed_out_fname = replica_id_string + ".nsl.out.100bins.norm"
  String nsl_normed_out_log_fname = nsl_normed_out_fname + ".log"
  String ihh12_normed_out_fname = replica_id_string + ".ihh12.out.norm"
  String ihh12_normed_out_log_fname = ihh12_normed_out_fname + ".log"

  command <<<
    tar xvfz ~{replica_output}

    cp ~{script} ~{script_used_name}
    python3 ~{script} --replica-info *.replicaInfo.json --replica-id-string ~{replica_id_string} --sel-pop ~{sel_pop} --threads ~{threads} ~{"--ihs-bins " + ihs_bins} ~{"--nsl-bins " + nsl_bins} ~{"--ihh12-bins " + ihh12_bins}
  >>>

  output {
    Object replicaInfo = read_json(replica_id_string + ".replica_info.json")
    File ihh12 = replica_id_string + ".ihh12.out"
    File ihs = ihs_out_fname
    File ihs_normed = ihs_normed_out_fname
    File ihs_normed_log = ihs_normed_out_log_fname
    File nsl = replica_id_string + ".nsl.out"
    File nsl_normed = nsl_normed_out_fname
    File nsl_normed_log = nsl_normed_out_log_fname
    File ihh12_normed = ihh12_normed_out_fname
    File ihh12_normed_log = ihh12_normed_out_log_fname
    Array[File] xpehh = glob("*.xpehh.out")
    Int threads_used = threads
    File script_used = script_used_name
  }

  runtime {
    docker: docker
    memory: (mem_base_gb  +  threads * mem_per_thread_gb) + " GB"
    cpu: threads
    disks: "local-disk " + local_disk_gb + " LOCAL"
  }
}

workflow compute_cms2_components {
  input {
    Array[File] replica_outputs
    Array[File] neutral_replica_outputs
    Int sel_pop
    File script

    Int n_bins = 100
    Int threads = 1
    Int mem_base_gb = 0
    Int mem_per_thread_gb = 1
    Int local_disk_gb = 50
    String docker = "quay.io/broadinstitute/cms2@sha256:0684c85ee72e6614cb3643292e79081c0b1eb6001a8264c446c3696a3a1dda97"
  }

  scatter(neutral_replica_output in neutral_replica_outputs) {
    call compute_cms2_components_for_one_replica as compute_components_for_neutral {
      input:
      replica_output=neutral_replica_output,
      sel_pop=sel_pop,
      script=script,
      threads=threads,
      mem_base_gb=mem_base_gb,
      mem_per_thread_gb=mem_per_thread_gb,
      local_disk_gb=local_disk_gb,
      docker=docker
    }
  }

  call compute_normalization_values {
    input:
    ihs_out=compute_components_for_neutral.ihs,
    nsl_out=compute_components_for_neutral.nsl,
    ihh12_out=compute_components_for_neutral.ihh12,
    threads=1,
    mem_base_gb=64,
    mem_per_thread_gb=0,
    local_disk_gb=local_disk_gb,
    docker=docker
  }

  scatter(replica_output in replica_outputs) {
    call compute_cms2_components_for_one_replica {
      input:
      replica_output=replica_output,
      sel_pop=sel_pop,
      ihs_bins=compute_normalization_values.norm_bins_ihs,
      nsl_bins=compute_normalization_values.norm_bins_nsl,
      ihh12_bins=compute_normalization_values.norm_bins_ihh12,
      script=script,
      threads=threads,
      mem_base_gb=mem_base_gb,
      mem_per_thread_gb=mem_per_thread_gb,
      local_disk_gb=local_disk_gb,
      docker=docker
    }
  }

  output {
    Array[Object] replicaInfo_out = compute_cms2_components_for_one_replica.replicaInfo
    Array[File] ihh12out = compute_cms2_components_for_one_replica.ihh12
    Array[File] ihsout = compute_cms2_components_for_one_replica.ihs
    Array[File] ihsnormedout = compute_cms2_components_for_one_replica.ihs_normed
    Array[File] nslout = compute_cms2_components_for_one_replica.nsl
    Array[File] nslnormedout = compute_cms2_components_for_one_replica.nsl_normed
    Array[File] ihh12normedout = compute_cms2_components_for_one_replica.ihh12_normed
    Array[Array[File]] xpehhout = compute_cms2_components_for_one_replica.xpehh
    Int threads_used=threads
    Array[File] script_used = compute_cms2_components_for_one_replica.script_used
  }
}

version 1.0

#
# WDL workflows for running population genetics simulations using cosi2
#

#
# TODO:
#
#   include metadata including selection start/stop/pop in workflow output as table
#   and muation age
#
#   figure out how to enable result caching without 
#

struct ReplicaInfo {
  String modelId
  String blockNum
  Float duration
  Int replicaNum
  Int succeeded
  Int         randomSeed
  File        tpeds_tar_gz
  Int  selPop
  Float selGen
  Int selBegPop
  Float selBegGen
  Float selCoeff
  Float selFreq
}

task cosi2_run_one_sim_block {
  meta {
    description: "Run one block of cosi2 simulations for one demographic model."
    email: "ilya_shl@alum.mit.edu"
  }

  parameter_meta {
    # Inputs
    ## required
    paramFile: "parts cosi2 parameter file (concatenated to form the parameter file)"
    recombFile: "recombination map"
    simBlockId: "an ID of this simulation block (e.g. block number in a list of blocks)."

    ## optional
    numRepsPerBlock: "number of simulations in this block"
    maxAttempts: "max number of attempts to simulate forward frequency trajectory before failing"

    # Outputs
    replicaInfos: "array of replica infos"
  }

  input {
    File         paramFileCommon
    File         paramFile
    File         recombFile
    String       simBlockId
    String       modelId
    Int          blockNum
    Int          numBlocks
    Int          numRepsPerBlock = 1
    Int          numCpusPerBlock = numRepsPerBlock
    Int          maxAttempts = 10000000
    Int          repTimeoutSeconds = 300
    String       cosi2_docker = "quay.io/ilya_broad/dockstore-tool-cosi2@sha256:11df3a646c563c39b6cbf71490ec5cd90c1025006102e301e62b9d0794061e6a"
    String       memoryPerBlock = "3 GB"
    File         taskScript
  }

  String tpedPrefix = "tpeds_${simBlockId}_tar_gz_"

  command <<<
    python3 ~{taskScript} --paramFileCommon ~{paramFileCommon} --paramFile ~{paramFile} --recombFile ~{recombFile} \
      --simBlockId ~{simBlockId} --modelId ~{modelId} --blockNum ~{blockNum} --numRepsPerBlock ~{numRepsPerBlock} --maxAttempts ~{maxAttempts} --repTimeoutSeconds ~{repTimeoutSeconds} --outTsv replicaInfos.tsv --tpedPrefix ~{tpedPrefix}
  >>>

  output {
    Array[ReplicaInfo] replicaInfos = read_objects("replicaInfos.tsv")
    Array[File] tpeds_tar_gz = prefix(tpedPrefix, range(numBlocks))

#    String      cosi2_docker_used = ""
  }
  runtime {
#    docker: "quay.io/ilya_broad/cms-dev:2.0.1-15-gd48e1db-is-cms2-new"
    docker: cosi2_docker
    memory: memoryPerBlock
    cpu: numCpusPerBlock
    dx_instance_type: "mem1_ssd1_v2_x4"
    volatile: true  # FIXME: not volatile if random seeds specified
  }
}


workflow run_sims_cosi2 {
    meta {
      description: "Run a set of cosi2 simulations for one or more demographic models."
      author: "Ilya Shlyakhter"
      email: "ilya_shl@alum.mit.edu"
    }

    parameter_meta {
      paramFiles: "cosi2 parameter files specifying the demographic model (paramFileCommon is prepended to each)"
      recombFile: "Recombination map from which map of each simulated region is sampled"
      nreps: "Number of replicates for _each_ file in paramFiles"
    }

    input {
      String experimentId = 'default'
      File paramFileCommon
      String modelId = basename(paramFileCommon, ".par")
      Array[File] paramFiles
      File recombFile
      Int nreps = 1
      Int maxAttempts = 10000000
      Int numRepsPerBlock = 1
      Int numCpusPerBlock = numRepsPerBlock
      Int repTimeoutSeconds = 600
      String       memoryPerBlock = "3 GB"
      String       cosi2_docker = "quay.io/ilya_broad/dockstore-tool-cosi2@sha256:11df3a646c563c39b6cbf71490ec5cd90c1025006102e301e62b9d0794061e6a"
      File         taskScript
    }
    Int numBlocks = nreps / numRepsPerBlock
    #Array[String] paramFileCommonLines = read_lines(paramFileCommonLines)

    scatter(paramFile_blockNum in cross(paramFiles, range(numBlocks))) {
      call cosi2_run_one_sim_block {
        input:
        paramFileCommon = paramFileCommon,
        paramFile = paramFile_blockNum.left,
	recombFile=recombFile,
        modelId=modelId,
	blockNum=paramFile_blockNum.right,
	simBlockId=modelId+"_"+paramFile_blockNum.right,
	numBlocks=numBlocks,
	maxAttempts=maxAttempts,
	repTimeoutSeconds=repTimeoutSeconds,
	numRepsPerBlock=numRepsPerBlock,
	numCpusPerBlock=numCpusPerBlock,
	memoryPerBlock=memoryPerBlock,
	cosi2_docker=cosi2_docker,
	taskScript=taskScript
	
      }
    }

    output {
      Array[Pair[ReplicaInfo,File]] replicaInfos = zip(flatten(cosi2_run_one_sim_block.replicaInfos), flatten(cosi2_run_one_sim_block.tpeds_tar_gz))
    }
}


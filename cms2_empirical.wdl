version 1.0

import "https://raw.githubusercontent.com/notestaff/cms2-staging/staging-srong-2022-08-06-01--08dc71e26a3f60921d287d2c5d24d97570f7c0a0/structs.wdl"
import "https://raw.githubusercontent.com/notestaff/cms2-staging/staging-srong-2022-08-06-01--08dc71e26a3f60921d287d2c5d24d97570f7c0a0/tasks.wdl"
import "https://raw.githubusercontent.com/notestaff/cms2-staging/staging-srong-2022-08-06-01--08dc71e26a3f60921d287d2c5d24d97570f7c0a0/fetch_empirical_hapsets.wdl"
import "https://raw.githubusercontent.com/notestaff/cms2-staging/staging-srong-2022-08-06-01--08dc71e26a3f60921d287d2c5d24d97570f7c0a0/compute_cms2_components.wdl"

workflow cms2_empirical {
  input {
    EmpiricalHapsetsDef empirical_hapsets_def
  }

  call fetch_empirical_hapsets.fetch_empirical_hapsets_wf {
    input:
    empirical_hapsets_def=empirical_hapsets_def
  }
  call compute_cms2_components.compute_cms2_components_wf {
    input:
    hapsets_bundle=fetch_empirical_hapsets_wf.hapsets_bundle
  }
  output {
    PopsInfo pops_info = fetch_empirical_hapsets_wf.hapsets_bundle.pops_info
    Array[File] all_hapsets_component_stats_h5_blocks = compute_cms2_components_wf.all_hapsets_component_stats_h5_blocks
  }
}



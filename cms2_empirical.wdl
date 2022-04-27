version 1.0

import "https://raw.githubusercontent.com/notestaff/cms2-staging/staging-is-220413-1556-replace-nre--2ef328aff52b5b8d1132d7375b057d8c7e3a87fa/structs.wdl"
import "https://raw.githubusercontent.com/notestaff/cms2-staging/staging-is-220413-1556-replace-nre--2ef328aff52b5b8d1132d7375b057d8c7e3a87fa/tasks.wdl"
import "https://raw.githubusercontent.com/notestaff/cms2-staging/staging-is-220413-1556-replace-nre--2ef328aff52b5b8d1132d7375b057d8c7e3a87fa/fetch_empirical_hapsets.wdl"
import "https://raw.githubusercontent.com/notestaff/cms2-staging/staging-is-220413-1556-replace-nre--2ef328aff52b5b8d1132d7375b057d8c7e3a87fa/compute_cms2_components.wdl"

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



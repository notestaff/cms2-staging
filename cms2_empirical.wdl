version 1.0

import "https://raw.githubusercontent.com/notestaff/cms2-staging/staging-srong-220802-test-branch-2--2ff4b3bb095c6556e3ccdee8ea6c9bfac746300f/structs.wdl"
import "https://raw.githubusercontent.com/notestaff/cms2-staging/staging-srong-220802-test-branch-2--2ff4b3bb095c6556e3ccdee8ea6c9bfac746300f/tasks.wdl"
import "https://raw.githubusercontent.com/notestaff/cms2-staging/staging-srong-220802-test-branch-2--2ff4b3bb095c6556e3ccdee8ea6c9bfac746300f/fetch_empirical_hapsets.wdl"
import "https://raw.githubusercontent.com/notestaff/cms2-staging/staging-srong-220802-test-branch-2--2ff4b3bb095c6556e3ccdee8ea6c9bfac746300f/compute_cms2_components.wdl"

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



version 1.0

import "https://raw.githubusercontent.com/notestaff/cms2-staging/staging-is-211222-test-isafe-with-orig-model--7b049005325ede5c93c12f00b3f809ed29248ca7/structs.wdl"
import "https://raw.githubusercontent.com/notestaff/cms2-staging/staging-is-211222-test-isafe-with-orig-model--7b049005325ede5c93c12f00b3f809ed29248ca7/tasks.wdl"
import "https://raw.githubusercontent.com/notestaff/cms2-staging/staging-is-211222-test-isafe-with-orig-model--7b049005325ede5c93c12f00b3f809ed29248ca7/fetch_empirical_hapsets.wdl"
import "https://raw.githubusercontent.com/notestaff/cms2-staging/staging-is-211222-test-isafe-with-orig-model--7b049005325ede5c93c12f00b3f809ed29248ca7/compute_cms2_components.wdl"

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



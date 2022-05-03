version 1.0

import "https://raw.githubusercontent.com/notestaff/cms2-staging/staging-is-220413-1556-replace-nre--9bdc06d8772de46520b813f6469cf4234d2c9912/structs.wdl"
import "https://raw.githubusercontent.com/notestaff/cms2-staging/staging-is-220413-1556-replace-nre--9bdc06d8772de46520b813f6469cf4234d2c9912/tasks.wdl"
import "https://raw.githubusercontent.com/notestaff/cms2-staging/staging-is-220413-1556-replace-nre--9bdc06d8772de46520b813f6469cf4234d2c9912/fetch_empirical_hapsets.wdl"
import "https://raw.githubusercontent.com/notestaff/cms2-staging/staging-is-220413-1556-replace-nre--9bdc06d8772de46520b813f6469cf4234d2c9912/compute_cms2_components.wdl"

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



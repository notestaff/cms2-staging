version 1.0

import "https://raw.githubusercontent.com/notestaff/cms2-staging/staging-is-220211-1454-relatedness-params-WIP--79b72acbcf6daa4ca164e393dcdbf90e0b86a916/structs.wdl"
import "https://raw.githubusercontent.com/notestaff/cms2-staging/staging-is-220211-1454-relatedness-params-WIP--79b72acbcf6daa4ca164e393dcdbf90e0b86a916/tasks.wdl"

workflow cms2_test_fetch {
  input {
    String url
    String sha256
  }

  call tasks.fetch_file_from_url {
    input:
    url=url, sha256=sha256
  }
  output {
    File out_file = fetch_file_from_url.file
  }
}

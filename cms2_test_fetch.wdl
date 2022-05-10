version 1.0

import "https://raw.githubusercontent.com/notestaff/cms2-staging/staging-is-220510-1344-update-miniconda--e625499d4c2a0ab3552aa9246f3ace23230a68a1/structs.wdl"
import "https://raw.githubusercontent.com/notestaff/cms2-staging/staging-is-220510-1344-update-miniconda--e625499d4c2a0ab3552aa9246f3ace23230a68a1/tasks.wdl"

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

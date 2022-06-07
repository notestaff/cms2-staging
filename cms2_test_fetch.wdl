version 1.0

import "https://raw.githubusercontent.com/notestaff/cms2-staging/staging-is-220607-1621-try-neutralome--b62b96d76702f982f74562be407a728f27fa5c4c/structs.wdl"
import "https://raw.githubusercontent.com/notestaff/cms2-staging/staging-is-220607-1621-try-neutralome--b62b96d76702f982f74562be407a728f27fa5c4c/tasks.wdl"

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

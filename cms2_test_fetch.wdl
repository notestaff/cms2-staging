version 1.0

import "https://raw.githubusercontent.com/notestaff/cms2-staging/staging-srong-test-02--f8d0d4cfe35cb510a3595f43359ab142d8b689dc/structs.wdl"
import "https://raw.githubusercontent.com/notestaff/cms2-staging/staging-srong-test-02--f8d0d4cfe35cb510a3595f43359ab142d8b689dc/tasks.wdl"

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

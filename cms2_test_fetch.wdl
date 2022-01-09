version 1.0

import "https://raw.githubusercontent.com/notestaff/cms2-staging/staging-is-211222-test-isafe-with-orig-model--1cda171ece91d0ed51e6c61f74f308b6f75d6dc8/structs.wdl"
import "https://raw.githubusercontent.com/notestaff/cms2-staging/staging-is-211222-test-isafe-with-orig-model--1cda171ece91d0ed51e6c61f74f308b6f75d6dc8/tasks.wdl"

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

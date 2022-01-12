version 1.0

import "https://raw.githubusercontent.com/notestaff/cms2-staging/staging-is-211222-test-isafe-with-orig-model--8a6db5ffbdca216eb0dccb2b2b5c75d0d2ca1289/structs.wdl"
import "https://raw.githubusercontent.com/notestaff/cms2-staging/staging-is-211222-test-isafe-with-orig-model--8a6db5ffbdca216eb0dccb2b2b5c75d0d2ca1289/tasks.wdl"

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

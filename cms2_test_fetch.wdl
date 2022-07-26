version 1.0

import "https://raw.githubusercontent.com/notestaff/cms2-staging/staging-stephen-new-test-branch--9a34a2965c0d3640a66531edca78a80b868f1305/structs.wdl"
import "https://raw.githubusercontent.com/notestaff/cms2-staging/staging-stephen-new-test-branch--9a34a2965c0d3640a66531edca78a80b868f1305/tasks.wdl"

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

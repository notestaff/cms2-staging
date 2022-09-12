version 1.0

import "https://raw.githubusercontent.com/notestaff/cms2-staging/staging-srong-2022-08-06-01--2e9b5358f1b2180c7868d8f202c21de5aec9dd3d/structs.wdl"
import "https://raw.githubusercontent.com/notestaff/cms2-staging/staging-srong-2022-08-06-01--2e9b5358f1b2180c7868d8f202c21de5aec9dd3d/tasks.wdl"

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

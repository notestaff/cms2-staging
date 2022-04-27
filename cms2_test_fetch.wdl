version 1.0

import "https://raw.githubusercontent.com/notestaff/cms2-staging/staging-is-220413-1556-replace-nre--2ef328aff52b5b8d1132d7375b057d8c7e3a87fa/structs.wdl"
import "https://raw.githubusercontent.com/notestaff/cms2-staging/staging-is-220413-1556-replace-nre--2ef328aff52b5b8d1132d7375b057d8c7e3a87fa/tasks.wdl"

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

version 1.0

import "https://raw.githubusercontent.com/notestaff/cms2-staging/staging-is-220413-1556-replace-nre--90e47f274123721080a9806430ee0dd66cb8fc4c/structs.wdl"
import "https://raw.githubusercontent.com/notestaff/cms2-staging/staging-is-220413-1556-replace-nre--90e47f274123721080a9806430ee0dd66cb8fc4c/tasks.wdl"

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

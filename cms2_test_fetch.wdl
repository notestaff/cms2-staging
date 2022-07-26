version 1.0

import "https://raw.githubusercontent.com/notestaff/cms2-staging/staging-srong-220627-initial-test-branch--51e879723cfb6416743309f1309210f0dd16f7c8/structs.wdl"
import "https://raw.githubusercontent.com/notestaff/cms2-staging/staging-srong-220627-initial-test-branch--51e879723cfb6416743309f1309210f0dd16f7c8/tasks.wdl"

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

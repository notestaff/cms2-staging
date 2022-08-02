version 1.0

import "https://raw.githubusercontent.com/notestaff/cms2-staging/staging-srong-220802-test-branch-3--261acd55f21dc3d0de8d588cc00da58c362bf73e/structs.wdl"
import "https://raw.githubusercontent.com/notestaff/cms2-staging/staging-srong-220802-test-branch-3--261acd55f21dc3d0de8d588cc00da58c362bf73e/tasks.wdl"

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

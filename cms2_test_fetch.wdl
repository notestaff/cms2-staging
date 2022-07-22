version 1.0

import "https://raw.githubusercontent.com/notestaff/cms2-staging/staging-srong-test-02--75f13585ff9112c7f84b172b62f3c1b63ce4a1a7/structs.wdl"
import "https://raw.githubusercontent.com/notestaff/cms2-staging/staging-srong-test-02--75f13585ff9112c7f84b172b62f3c1b63ce4a1a7/tasks.wdl"

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

version 1.0

import "https://raw.githubusercontent.com/notestaff/cms2-staging/staging-is-220819-1337-neutralome-with-margins--8a137ce8658c6c4923215f5d22c8eee9184ddb0c/structs.wdl"
import "https://raw.githubusercontent.com/notestaff/cms2-staging/staging-is-220819-1337-neutralome-with-margins--8a137ce8658c6c4923215f5d22c8eee9184ddb0c/tasks.wdl"

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

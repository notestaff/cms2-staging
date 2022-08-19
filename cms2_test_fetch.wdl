version 1.0

import "https://raw.githubusercontent.com/notestaff/cms2-staging/staging-is-220819-1337-neutralome-with-margins--12d9b8de5151426b143d6bcc3b115958e80ed570/structs.wdl"
import "https://raw.githubusercontent.com/notestaff/cms2-staging/staging-is-220819-1337-neutralome-with-margins--12d9b8de5151426b143d6bcc3b115958e80ed570/tasks.wdl"

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

version 1.0

import "https://raw.githubusercontent.com/notestaff/cms2-staging/staging-is-220311-1537-refactor-avoid-glob--4f08f11c63cfd65f4b120cfda91e1c90ab47d678/structs.wdl"
import "https://raw.githubusercontent.com/notestaff/cms2-staging/staging-is-220311-1537-refactor-avoid-glob--4f08f11c63cfd65f4b120cfda91e1c90ab47d678/tasks.wdl"

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

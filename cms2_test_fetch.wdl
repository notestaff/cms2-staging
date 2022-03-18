version 1.0

import "https://raw.githubusercontent.com/notestaff/cms2-staging/staging-is-220311-1537-refactor-avoid-glob--517712c572671cc101555575aa085929336fcfb0/structs.wdl"
import "https://raw.githubusercontent.com/notestaff/cms2-staging/staging-is-220311-1537-refactor-avoid-glob--517712c572671cc101555575aa085929336fcfb0/tasks.wdl"

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

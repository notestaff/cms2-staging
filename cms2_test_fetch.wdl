version 1.0

import "https://raw.githubusercontent.com/notestaff/cms2-staging/staging-is-220607-1621-try-neutralome--044eee8568ca34baa879ffe344e9099baed93950/structs.wdl"
import "https://raw.githubusercontent.com/notestaff/cms2-staging/staging-is-220607-1621-try-neutralome--044eee8568ca34baa879ffe344e9099baed93950/tasks.wdl"

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

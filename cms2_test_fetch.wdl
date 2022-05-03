version 1.0

import "https://raw.githubusercontent.com/notestaff/cms2-staging/staging-is-220413-1556-replace-nre--9bdc06d8772de46520b813f6469cf4234d2c9912/structs.wdl"
import "https://raw.githubusercontent.com/notestaff/cms2-staging/staging-is-220413-1556-replace-nre--9bdc06d8772de46520b813f6469cf4234d2c9912/tasks.wdl"

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

version 1.0

import "https://raw.githubusercontent.com/notestaff/cms2-staging/staging-is-220311-1537-refactor-avoid-glob--c6808d6635d0b5f6a1b3200dd4162d7359cb8667/structs.wdl"
import "https://raw.githubusercontent.com/notestaff/cms2-staging/staging-is-220311-1537-refactor-avoid-glob--c6808d6635d0b5f6a1b3200dd4162d7359cb8667/tasks.wdl"

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

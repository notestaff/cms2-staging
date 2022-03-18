version 1.0

import "https://raw.githubusercontent.com/notestaff/cms2-staging/staging-is-220311-1537-refactor-avoid-glob--d622c0a2309a6f8d2410b3c5ab7efeaad7fb7a4f/structs.wdl"
import "https://raw.githubusercontent.com/notestaff/cms2-staging/staging-is-220311-1537-refactor-avoid-glob--d622c0a2309a6f8d2410b3c5ab7efeaad7fb7a4f/tasks.wdl"

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

version 1.0

import "https://raw.githubusercontent.com/notestaff/cms2-staging/staging-srong-2022-08-06-01--74081f6352aed14e8e6cce125eb75d5aa4211368/structs.wdl"
import "https://raw.githubusercontent.com/notestaff/cms2-staging/staging-srong-2022-08-06-01--74081f6352aed14e8e6cce125eb75d5aa4211368/tasks.wdl"

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

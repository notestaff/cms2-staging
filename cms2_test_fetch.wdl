version 1.0

import "https://raw.githubusercontent.com/notestaff/cms2-staging/staging-is-220211-1632-make-minimal-sim-train-data--b20e91cc8fa7f9b93181174a1cf90962deed327e/structs.wdl"
import "https://raw.githubusercontent.com/notestaff/cms2-staging/staging-is-220211-1632-make-minimal-sim-train-data--b20e91cc8fa7f9b93181174a1cf90962deed327e/tasks.wdl"

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

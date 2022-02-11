version 1.0

import "https://raw.githubusercontent.com/notestaff/cms2-staging/staging-is-220211-1632-make-minimal-sim-train-data--bf8257c536deaa902d4bacd17833348b8f505d91/structs.wdl"
import "https://raw.githubusercontent.com/notestaff/cms2-staging/staging-is-220211-1632-make-minimal-sim-train-data--bf8257c536deaa902d4bacd17833348b8f505d91/tasks.wdl"

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

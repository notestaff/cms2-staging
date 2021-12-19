version 1.0

import "https://raw.githubusercontent.com/notestaff/cms2-staging/staging-is-211214-replace-nre--be54b68a90048501d39ffc741d2665c38f291dfb/structs.wdl"
import "https://raw.githubusercontent.com/notestaff/cms2-staging/staging-is-211214-replace-nre--be54b68a90048501d39ffc741d2665c38f291dfb/tasks.wdl"

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

version 1.0

import "https://raw.githubusercontent.com/notestaff/cms2-staging/staging-is-211013-1315-add-isafe--ced0f4c65c98290ddaa7a0c12c0f5b4638d2b21f/structs.wdl"
import "https://raw.githubusercontent.com/notestaff/cms2-staging/staging-is-211013-1315-add-isafe--ced0f4c65c98290ddaa7a0c12c0f5b4638d2b21f/tasks.wdl"

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

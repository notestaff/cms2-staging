version 1.0

import "https://raw.githubusercontent.com/notestaff/cms2-staging/staging-is-220607-1656-bestmodel4x--87ae42d708fcaab8ca17b80797b1c8d549d0bb19/structs.wdl"
import "https://raw.githubusercontent.com/notestaff/cms2-staging/staging-is-220607-1656-bestmodel4x--87ae42d708fcaab8ca17b80797b1c8d549d0bb19/tasks.wdl"

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

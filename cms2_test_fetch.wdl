version 1.0

import "https://raw.githubusercontent.com/notestaff/cms2-staging/staging-is-220510-1344-update-miniconda--362342445be0e78bb82ffdfaad8c8072948e5bdb/structs.wdl"
import "https://raw.githubusercontent.com/notestaff/cms2-staging/staging-is-220510-1344-update-miniconda--362342445be0e78bb82ffdfaad8c8072948e5bdb/tasks.wdl"

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

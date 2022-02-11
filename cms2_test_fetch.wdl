version 1.0

import "https://raw.githubusercontent.com/notestaff/cms2-staging/staging-master--f06ab6faaf4c92a42e93c0b453f0a4aaf73eebb7/structs.wdl"
import "https://raw.githubusercontent.com/notestaff/cms2-staging/staging-master--f06ab6faaf4c92a42e93c0b453f0a4aaf73eebb7/tasks.wdl"

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

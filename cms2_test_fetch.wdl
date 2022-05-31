version 1.0

import "https://raw.githubusercontent.com/notestaff/cms2-staging/staging-is-220524-1640-fix-travis--cf2470be2ab080e6fcc129aac3fe4cf6237224bc/structs.wdl"
import "https://raw.githubusercontent.com/notestaff/cms2-staging/staging-is-220524-1640-fix-travis--cf2470be2ab080e6fcc129aac3fe4cf6237224bc/tasks.wdl"

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

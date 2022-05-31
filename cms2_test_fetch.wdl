version 1.0

import "https://raw.githubusercontent.com/notestaff/cms2-staging/staging-is-220524-1640-fix-travis--60862c7ff081e3098ddabb5039bd9d705df6d27a/structs.wdl"
import "https://raw.githubusercontent.com/notestaff/cms2-staging/staging-is-220524-1640-fix-travis--60862c7ff081e3098ddabb5039bd9d705df6d27a/tasks.wdl"

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

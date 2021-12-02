version 1.0

import "https://raw.githubusercontent.com/notestaff/cms2-staging/staging-is-211013-1315-add-isafe--66158e22cd8aad55b45f3b4d8cde868e92cb90d1/structs.wdl"
import "https://raw.githubusercontent.com/notestaff/cms2-staging/staging-is-211013-1315-add-isafe--66158e22cd8aad55b45f3b4d8cde868e92cb90d1/tasks.wdl"

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

version 1.0

import "https://raw.githubusercontent.com/notestaff/cms2-staging/staging-is-211214-replace-nre--5711ffaa9dfdb3ca2b9cd69ea113364dcc74616c/structs.wdl"
import "https://raw.githubusercontent.com/notestaff/cms2-staging/staging-is-211214-replace-nre--5711ffaa9dfdb3ca2b9cd69ea113364dcc74616c/tasks.wdl"

workflow construct_empirical_neutral_regions {
  input {
    Int chrom_end_margins_bp = 1000000
  }
  String chrom_sizes_url = "https://hgdownload.soe.ucsc.edu/goldenPath/hg19/bigZips/hg19.chrom.sizes"
  String gencode_human_gff3_url = "https://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_39/GRCh37_mapping/gencode.v39lift37.annotation.gff3.gz"
  String gap_url = "https://hgdownload.soe.ucsc.edu/goldenPath/hg19/database/gap.txt.gz"

  call tasks.fetch_file_from_url as fetch_chrom_sizes { input: url=chrom_sizes_url }
  call tasks.fetch_file_from_url as fetch_gencode_human_gff3 { input: url=gencode_human_gff3_url }
  call tasks.fetch_file_from_url as fetch_gaps { input: url=gap_url }

  call tasks.construct_neutral_regions_list {
    input:
    chrom_sizes=fetch_chrom_sizes.file,
    chrom_end_margins_bp=chrom_end_margins_bp,
    genes_gff3=fetch_gencode_human_gff3.file,
    
  }  

  output {
    File empirical_neutral_regions_bed=construct_neutral_regions_list.neutral_regions_bed
  }
}

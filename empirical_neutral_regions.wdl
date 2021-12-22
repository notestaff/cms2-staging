version 1.0

import "https://raw.githubusercontent.com/notestaff/cms2-staging/staging-is-211214-replace-nre--56cc6d7e00ffbe3c7df8a78ee8b690eed0c9a2f5/structs.wdl"
import "https://raw.githubusercontent.com/notestaff/cms2-staging/staging-is-211214-replace-nre--56cc6d7e00ffbe3c7df8a78ee8b690eed0c9a2f5/tasks.wdl"

workflow construct_empirical_neutral_regions {
  input {
    EmpiricalNeutralRegionsParams empirical_neutral_regions_params = object {
      genes_pad_bp: 1000,
      telomeres_pad_bp: 1000000,
      min_region_len_bp: 200000
    }
  }

  call tasks.fetch_file_from_url as fetch_chrom_sizes {
     input: url="https://hgdownload.soe.ucsc.edu/goldenPath/hg19/bigZips/hg19.chrom.sizes"
  }

  call tasks.fetch_file_from_url as fetch_gencode_annots { 
    input: url="https://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_39/GRCh37_mapping/gencode.v39lift37.annotation.gff3.gz"
  }

  call tasks.fetch_file_from_url as fetch_ucsc_gap_track { 
    input: url="https://hgdownload.soe.ucsc.edu/goldenPath/hg19/database/gap.txt.gz"
  }

  call tasks.fetch_file_from_url as fetch_pophumanscan_coords { 
    input: url="https://pophumanscan.uab.cat/data/files/pophumanscanCoordinates.tab"
  }

  call tasks.construct_neutral_regions_list {
    input:
    empirical_neutral_regions_params=empirical_neutral_regions_params,
    genomic_features_for_finding_empirical_neutral_regions=object {  # struct GenomicFeaturesForFindingEmpiricalNeutralRegions
      chrom_sizes: fetch_chrom_sizes.file,
      gencode_annots: fetch_gencode_annots.file,
      ucsc_gap_track: fetch_ucsc_gap_track.file,
      pophumanscan_coords: fetch_pophumanscan_coords.file
    }
  }
  
  call tasks.compute_intervals_stats {
    input:
    intervals_files=flatten([[construct_neutral_regions_list.neutral_regions_bed], construct_neutral_regions_list.aux_beds]),
    metadata_json=construct_neutral_regions_list.empirical_neutral_regions_params_used_json
  }

  output {
    File empirical_neutral_regions_bed=construct_neutral_regions_list.neutral_regions_bed
    File empirical_neutral_regions_report_html=compute_intervals_stats.intervals_report_html
  }
}

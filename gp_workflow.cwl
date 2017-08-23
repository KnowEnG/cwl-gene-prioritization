class: Workflow
cwlVersion: v1.0
label: ProGENI
doc: network-guided gene prioritization method implementation by KnowEnG that ranks gene measurements by their correlation to observed phenotypes

requirements:
  - class: StepInputExpressionRequirement

inputs:
  - id: genomic_spreadsheet_file
    label: Genomic Spreadsheet
    doc: the genomic spreadsheet input for the pipeline
    type: File
  - id: phenotypic_spreadsheet_file
    label: Phenotypic Spreadsheet
    doc: spreadsheet of phenotypic data with samples as rows and phenotypes as columns
    type: File
  - id: correlation_measure
    label: Correlation Measure
    doc: "keyword for correlation metric, one of either ['t_test', 'pearson']"
    type: string
  - id: num_bootstraps
    label: Number of bootstraps
    doc: number of types to sample the data and repeat the analysis
    type: int
    default: 0
  - id: use_network
    label: Use Network Flag
    doc: whether or not to use a network for ProGENI
    type: boolean
    default: true
  - id: edge_type
    label: Subnetwork Edge Type
    doc: the edge type keyword for the subnetwork of interest
    type: string
    default: STRING_experimental
  - id: network_type
    label: Subnetwork Class
    doc: the type of subnetwork
    type: string
    default: Gene
  - id: taxonid
    label: Species TaxonID
    doc: taxon id of species related to genomic spreadsheet
    type: ["null", string]
    default: '9606'
  - id: redis_host
    label: RedisDB host URL
    doc: url of Redis db
    type: ["null", string]
    default: knowredis.knoweng.org
  - id: redis_port
    label: RedisDB Port
    doc: port for Redis db
    type: ["null", int]
    default: 6379
  - id: redis_pass
    label: RedisDB AuthStr
    doc: password for Redis db
    type: ["null", string]
    default: KnowEnG

steps:
  - id: kn_fetcher
    run: kn_fetcher.cwl
    in:
      - { id: get_network, source: "#use_network" }
      - { id: network_type, source: "#network_type" }
      - { id: taxonid, source: "#taxonid" }
      - { id: edge_type, source: "#edge_type" }
    out:
      - { id: network_edge_file }
      - { id: cmd_log_file }
      - { id: node_map_file }
      - { id: network_metadata_file }

  - id: data_cleaning
    run: data_cleaning.cwl
    in:
      - { id: pipeline_type, valueFrom: "gene_prioritization_pipeline" }
      - { id: genomic_spreadsheet_file, source: "#genomic_spreadsheet_file" }
      - { id: taxonid, source: "#taxonid" }
      - { id: phenotypic_spreadsheet_file, source: "#phenotypic_spreadsheet_file" }
      - { id: gene_prioritization_corr_measure, source: "#correlation_measure" }
      - { id: redis_host, source: "#redis_host" }
      - { id: redis_port, source: "#redis_port" }
      - { id: redis_pass, source: "#redis_pass" }
    out:
      - { id: cleaning_log_file }
      - { id: gene_map_file }
      - { id: gene_unmap_file }
      - { id: cleaning_yml_file }
      - { id: clean_genomic_file }
      - { id: clean_phenotypic_file }

  - id: gp_runner
    run: gp_runner.cwl
    in:
      - { id: use_network, source: "#use_network" }
      - { id: genomic_file, source: "#data_cleaning/clean_genomic_file" }
      - { id: phenotypic_file, source: "#data_cleaning/clean_phenotypic_file" }
      - { id: correlation_measure, source: "#correlation_measure" }
      - { id: network_file, source: "#kn_fetcher/network_edge_file" }
      - { id: num_bootstraps, source: "#num_bootstraps" }
    out:
      - { id: top100_genes_matrix }
      - { id: top_ranked_genes }
      - { id: ranked_genes_file }
      - { id: params_yml }

outputs:
  - id: network_edge_file
    label: Subnetwork Edge File
    doc: 4 column format for subnetwork for single edge type and species
    type: File
    outputSource: "#kn_fetcher/network_edge_file"
  - id: fetch_cmd_log_file
    label: Fetch Command Log File
    doc: Fetch Command Log File
    type: File
    outputSource: "#kn_fetcher/cmd_log_file"
  - id: cleaning_log_file
    label: Cleaning Log File
    doc: information on souce of errors for cleaning pipeline
    type: ["null", File]
    outputSource: "#data_cleaning/cleaning_log_file"
  - id: clean_genomic_file
    label: Clean Genomic Spreadsheet
    doc: matrix with gene names mapped and data cleaned
    type: ["null", File]
    outputSource: "#data_cleaning/clean_genomic_file"
  - id: clean_phenotypic_file
    label: Clean Phenotypic Spreadsheet
    doc: phenotype file prepared for pipeline
    type: ["null", File]
    outputSource: "#data_cleaning/clean_phenotypic_file"
  - id: gene_map_file
    label: Genomic Spreadsheet Map
    doc: two columns for internal gene ids and original gene ids
    type: ["null", File]
    outputSource: "#data_cleaning/gene_map_file"
  - id: gene_unmap_file
    label: Genomic Spreadsheet Unmapped Genes
    doc: two columns for original gene ids and unmapped reason code
    type: ["null", File]
    outputSource: "#data_cleaning/gene_unmap_file"
  - id: cleaning_yml_file
    label: Cleanup Parameter File
    doc: data cleaning parameters in yaml format
    type: ["null", File]
    outputSource: "#data_cleaning/cleaning_yml_file"
  - id: top100_genes_matrix
    label: top100 Genes File
    doc: Membership spreadsheet with phenotype columns and gene rows
    type: File
    outputSource: "#gp_runner/top100_genes_matrix"
  - id: top_ranked_genes
    label: Lists of Top Genes
    doc: Lists of Top Genes
    type: File
    outputSource: "#gp_runner/top_ranked_genes"
  - id: ranked_genes_file
    label: Ranked Genes File
    doc: Ranked Genes File
    type: File
    outputSource: "#gp_runner/ranked_genes_file"
  - id: params_yml
    label: Configuration Parameter File
    doc: contains the values used in analysis
    type: File
    outputSource: "#gp_runner/params_yml"

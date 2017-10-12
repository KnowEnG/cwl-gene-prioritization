class: CommandLineTool
cwlVersion: v1.0
id: data_cleaning
label: Pipeline Preprocessing
doc: checks the inputs of a pipeline for potential sources of errors

requirements:
  - class: InlineJavascriptRequirement
  - class: ShellCommandRequirement

hints:
  - class: DockerRequirement
    dockerPull: knowengdev/data_cleanup_pipeline:07_26_2017
  - class: ResourceRequirement
    coresMin: 1
    ramMin: 5000 #MB
    outdirMin: 512000

inputs:
  - id: pipeline_type
    label: Name of Pipeline
    doc: "keywork name of pipeline from following list ['gene_prioritization_pipeline', 'samples_clustering_pipeline', 'geneset_characterization_pipeline']"
    type: string
  - id: genomic_spreadsheet_file
    label: Genomic Spreadsheet
    doc: the genomic spreadsheet input for the pipeline
    type: File
  - id: taxonid
    label: Species TaxonID
    doc: taxon id of species related to genomic spreadsheet
    type: ["null", string]
    default: '9606'
  - id: phenotypic_spreadsheet_file
    label: Phenotypic Spreadsheet
    doc: "the phenotypic spreadsheet input for the pipeline [may be optional]"
    type: ["null", File]
    default:
      class: File
      location: /bin/sh
  - id: gene_prioritization_corr_measure
    label: GP correlation measure
    doc: "if pipeline_type=='gene_prioritization_pipeline', then must be one of either ['t_test', 'pearson']"
    type: ["null", string]
    default: missing
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
  - id: source_hint
    label: ID Source Hint
    doc: suggestion for ID source database used to resolve ambiguities in mapping
    type: ["null", string]
    default: ''

baseCommand: []
arguments:
  - shellQuote: false
    valueFrom: |-
      echo "
      pipeline_type: $(inputs.pipeline_type)
      spreadsheet_name_full_path: $(inputs.genomic_spreadsheet_file.path)
      taxonid: '$(inputs.taxonid)'
      redis_credential:
        host: $(inputs.redis_host)
        password: $(inputs.redis_pass)
        port: $(inputs.redis_port)
      source_hint: '$(inputs.source_hint)'
      results_directory: ./
      " > run_cleanup.yml && \
      if [ "$(inputs.phenotypic_spreadsheet_file.nameroot)" != "sh" ]; then \
        echo "phenotype_name_full_path: $(inputs.phenotypic_spreadsheet_file.path)" >> run_cleanup.yml; fi && \
      if [ "$(inputs.pipeline_type)" = "gene_prioritization_pipeline" ]; then \
        echo "correlation_measure: $(inputs.gene_prioritization_corr_measure)" >> run_cleanup.yml; fi && \
      date && python3 /home/src/data_cleanup.py -run_directory ./ -run_file run_cleanup.yml && date

outputs:
  - id: cleaning_log_file
    label: Cleaning Log File
    doc: information on souce of errors for cleaning pipeline
    type: ["null", File]
    outputBinding:
      glob: "log_*_pipeline.yml"
  - id: clean_genomic_file
    label: Clean Genomic Spreadsheet
    doc: matrix with gene names mapped and data cleaned
    type: ["null", File]
    outputBinding:
      glob: "$(inputs.genomic_spreadsheet_file.nameroot)_ETL.tsv"
  - id: clean_phenotypic_file
    label: Clean Phenotypic Spreadsheet
    doc: phenotype file prepared for pipeline
    type: ["null", File]
    outputBinding:
      glob: "$(inputs.phenotypic_spreadsheet_file.nameroot)_ETL.tsv"
  - id: gene_map_file
    label: Genomic Spreadsheet Map
    doc: two columns for internal gene ids and original gene ids
    type: ["null", File]
    outputBinding:
      glob: "*_MAP.tsv"
  - id: gene_unmap_file
    label: Genomic Spreadsheet Unmapped Genes
    doc: two columns for original gene ids and unmapped reason code
    type: ["null", File]
    outputBinding:
      glob: "*_UNMAPPED.tsv"
  - id: cleaning_yml_file
    label: Cleanup Parameter File
    doc: data cleaning parameters in yaml format
    type: ["null", File]
    outputBinding:
      glob: "run_cleanup.yml"

class: CommandLineTool
cwlVersion: v1.0
label: ProGENI
doc: network-guided gene prioritization method implementation by KnowEnG that ranks gene measurements by their correlation to observed phenotypes

requirements:
  - class: InlineJavascriptRequirement
  - class: ShellCommandRequirement

hints:
  - class: DockerRequirement
    dockerPull: knowengdev/gene_prioritization_pipeline:07_26_2017
  - class: ResourceRequirement
    coresMin: 1
    ramMin: 5000 #MB
    outdirMin: 512000

inputs:
  - id: genomic_file
    label: Genomic Spreadsheet File
    doc: spreadsheet of genomic data with samples as columns and genes as rows
    type: File
  - id: phenotypic_file
    label: Phenotypic File
    doc: spreadsheet of phenotypic data with samples as rows and phenotypes as columns
    type: File
  - id: correlation_measure
    label: Correlation Measure
    doc: keyword for correlation metric, i.e. t_test or pearson
    type: string
  - id: use_network
    label: Use Network Flag
    doc: whether or not to use a network for ProGENI
    type: boolean
    default: true
  - id: network_file
    label: Network File
    doc: "gene-gene network of interactions in edge format [optional]"
    type: ["null", File]
    default:
      class: File
      location: /bin/sh
  - id: num_bootstraps
    label: Number of bootstraps
    doc: number of types to sample the data and repeat the analysis
    type: int
    default: 0

baseCommand: []
arguments:
  - shellQuote: false
    valueFrom: |-
      echo "
      spreadsheet_name_full_path: $(inputs.genomic_file.path)
      phenotype_name_full_path: $(inputs.phenotypic_file.path)
      correlation_measure: $(inputs.correlation_measure)
      results_directory: ./
      top_beta_of_sort: 100
      drop_method: drop_NA
      " > run_params.yml && \
      if [ "$(inputs.use_network)" = "true" ]; then \
        echo "gg_network_name_full_path: $(inputs.network_file.path)" >> run_params.yml; \
        echo "rwr_convergence_tolerence: 0.0001" >> run_params.yml; \
        echo "rwr_max_iterations: 100" >> run_params.yml; \
        echo "rwr_restart_probability: 0.5" >> run_params.yml; \
      fi && \
      if [ $(inputs.num_bootstraps) -ne 0 ]; then \
        echo "number_of_bootstraps: $(inputs.num_bootstraps)" >> run_params.yml; \
        echo "cols_sampling_fraction: 0.8" >> run_params.yml; \
        echo "rows_sampling_fraction: 1.0" >> run_params.yml; \
      fi && \
      if [ "$(inputs.use_network)" = "true" ] && [ $(inputs.num_bootstraps) -ne 0 ]; then \
        echo "method: bootstrap_net_correlation" >> run_params.yml; \
      elif [ "$(inputs.use_network)" = "true" ] && [ $(inputs.num_bootstraps) -eq 0 ]; then \
        echo "method: net_correlation" >> run_params.yml; \
      elif [ "$(inputs.use_network)" = "false" ] && [ $(inputs.num_bootstraps) -ne 0 ]; then \
        echo "method: bootstrap_correlation" >> run_params.yml; \
      elif [ "$(inputs.use_network)" = "false" ] && [ $(inputs.num_bootstraps) -eq 0 ]; then \
        echo "method: correlation" >> run_params.yml; \
      fi && \
      date && python3 /home/src/gene_prioritization.py -run_directory ./ -run_file run_params.yml && cat *_viz.tsv > combo_results.txt && mv ranked_genes*.tsv ranked_genes_download.tsv && mv top_genes*.tsv top_genes_download.tsv && date

outputs:
  - id: top100_genes_matrix
    label: top100 Genes File
    doc: Membership spreadsheet with phenotype columns and gene rows
    type: File
    outputBinding:
      glob: "top_genes*.tsv"
  - id: top_ranked_genes
    label: Lists of Top Genes
    doc: Lists of Top Genes
    type: File
    outputBinding:
      glob: "ranked_genes*.tsv"
  - id: ranked_genes_file
    label: Ranked Genes File
    doc: Ranked Genes File
    type: File
    outputBinding:
      glob: "combo_results.txt"
  - id: params_yml
    label: Configuration Parameter File
    doc: contains the values used in analysis
    type: File
    outputBinding:
      glob: run_params.yml

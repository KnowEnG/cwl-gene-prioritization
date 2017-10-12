class: CommandLineTool
cwlVersion: v1.0
id: kn_fetcher
label: Knowledge Network Fetcher
doc: Retrieve appropriate subnetwork from KnowEnG Knowledge Network from AWS S3 storage

requirements:
  - class: InlineJavascriptRequirement
  - class: ShellCommandRequirement

hints:
  - class: DockerRequirement
    dockerPull: quay.io/cblatti3/kn_fetcher:latest
  - class: ResourceRequirement
    coresMin: 1
    ramMin: 2000 #the process requires at least 1G of RAM
    outdirMin: 512000

inputs:
  - id: get_network
    label: Get Network Flag
    doc: whether or not to get the network
    type: boolean
    default: true
  - id: bucket
    label: AWS S3 Bucket Name
    doc: the aws s3 bucket
    type: string
    default: KnowNets/KN-20rep-1706/userKN-20rep-1706
  - id: network_type
    label: Subnetwork Class
    doc: the type of subnetwork
    type: string
    default: Gene
  - id: taxonid
    label: Subnetwork Species ID
    doc: the taxonomic id for the species of interest
    type: string
    default: '9606'
  - id: edge_type
    label: Subnetwork Edge Type
    doc: the edge type keyword for the subnetwork of interest
    type: string
    default: PPI_physical_association

baseCommand: []
arguments:
  - shellQuote: false
    valueFrom: |-
      MYCMD="date && if [ \"$(inputs.get_network)\" = \"true\" ]; then /home/kn_fetcher.sh $(inputs.bucket) $(inputs.network_type) $(inputs.taxonid) $(inputs.edge_type); else touch empty.edge; fi && date" && echo $MYCMD > run_fetch.cmd && eval $MYCMD

outputs:
  - id: network_edge_file
    label: Subnetwork Edge File
    doc: 4 column format for subnetwork for single edge type and species
    type: ["null", File]
    outputBinding:
      glob: "*.edge"
  - id: cmd_log_file
    label: Command Log File
    doc: log of fetch command
    type: ["null", File]
    outputBinding:
      glob: "run_fetch.cmd"
  - id: node_map_file
    label: Node Map File
    doc: "5 column node map with [original_node_id, mapped_node_id, node_type, node_alias, node_description]"
    type: ["null", File]
    outputBinding:
      glob: "*.node_map"
  - id: network_metadata_file
    label: Network Metadata File
    doc: yaml format describing network contents
    type: ["null", File]
    outputBinding:
      glob: "*.metadata"

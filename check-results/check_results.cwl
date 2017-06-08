class: CommandLineTool
cwlVersion: v1.0
id: check_results
label: Check Results
doc: Check the results of the tool run

requirements: []

hints:
  - class: DockerRequirement
    dockerPull: mepsteindr/check_results:0.1
  - class: ResourceRequirement
    coresMin: 1
    ramMin: 2000 #the process requires at least 1G of RAM
    outdirMin: 512000

inputs:
  - id: sums_file
    label: Sums File
    doc: Sums File
    type: File
    inputBinding:
      position: 1
      prefix: -s
  - id: ranked_genes_file
    label: Ranked Genes File
    doc: Ranked Genes File
    type: File
    inputBinding:
      position: 2
      prefix: -r
  - id: top_genes_file
    label: Top Genes File
    doc: Top Genes File
    type: File
    inputBinding:
      position: 3
      prefix: -t
  - id: combo_results_file
    label: Combo Results File
    doc: Combo Results File
    type: File
    inputBinding:
      position: 4
      prefix: -c
  - id: edge_file
    label: Edge File
    doc: Edge File
    type: File
    inputBinding:
      position: 5
      prefix: -e

baseCommand: [/home/check_results.py]
arguments: []

outputs:
  - id: results_json
    label: results.json
    doc: results.json
    type: File
    outputBinding:
      glob: "results.json"
  - id: log_txt
    label: log.txt
    doc: log.txt
    type: File
    outputBinding:
      glob: "log.txt"

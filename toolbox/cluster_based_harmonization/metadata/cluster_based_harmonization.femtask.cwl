cwlVersion: v1.2
class: FEMTask

id: cluster_based_harmonization
label: Cluster-based Radiomics Harmonization
doc: >-
  Performs ComBat radiomics harmonization on clustered groups instead of predefined batches.
  Designed for large and heterogeneous datasets to reduce the risk of over-harmonization.
  The workflow uses Agglomerative Clustering on radiomics features prior to ComBat harmonization.

requirements:
  - class: DockerRequirement
    dockerPull: harbor.eucaim.cancerimage.eu/processing-tools/cluster_based_harmonization:1.1.0
  
  - class: ResourceRequirement
    coresMin: 4
    ramMin: 8192

baseCommand: [python, /app/clustering_harmonization.py]

inputs:
  - id: file_path
    type: string
    doc: >-
      Absolute path to the input data file inside the container (e.g., /input/data.xlsx or /input/data.csv).
    required: true
    hidden: false
    source: user
    inputBinding:
      position: 1
      prefix: --file_path
      separate: true

  - id: identifier
    type: string
    doc: >-
      Column name for the sample identifier (e.g., patient_id).
    required: true
    hidden: false
    source: user
    inputBinding:
      position: 2
      prefix: --identifier
      separate: true

  - id: start_col
    type: string
    doc: >-
      Column name of the first radiomics variable.
    required: true
    hidden: false
    source: user
    inputBinding:
      position: 3
      prefix: --start_col
      separate: true

  - id: end_col
    type: string
    doc: >-
      Column name of the last radiomics variable.
    required: true
    hidden: false
    source: user
    inputBinding:
      position: 4
      prefix: --end_col
      separate: true

  - id: batch_col
    type: string
    doc: >-
      Column name of the batch variable to harmonize on.
    required: true
    hidden: false
    source: user
    inputBinding:
      position: 5
      prefix: --batch_col
      separate: true

  - id: output_dir
    type: string
    doc: >-
      Output directory inside the container for results and logs.
    required: false
    default: '/output'
    hidden: false
    source: user
    inputBinding:
      position: 6
      prefix: --output_dir
      separate: true

  - id: min_clusters
    type: int
    doc: >-
      Minimum number of clusters for the iterative search.
    required: false
    default: 2
    hidden: false
    source: user
    inputBinding:
      position: 7
      prefix: --min_clusters
      separate: true

  - id: max_clusters
    type: int
    doc: >-
      Maximum number of clusters for the iterative search.
    required: false
    default: 100
    hidden: false
    source: user
    inputBinding:
      position: 8
      prefix: --max_clusters
      separate: true

  - id: results
    type: string
    doc: >-
      Results output level (none, metrics, or full).
    required: false
    default: 'none'
    hidden: false
    source: user
    constraints:
      enum: ["none", "metrics", "full"]
    inputBinding:
      position: 9
      prefix: --results
      separate: true

  - id: approach
    type: string
    doc: >-
      Selection on the clustering intensity (soft or aggressive).
    required: false
    default: 'soft'
    hidden: false
    source: user
    constraints:
      enum: ["soft", "aggressive"]
    inputBinding:
      position: 10
      prefix: --approach
      separate: true

  - id: small_groups
    type: string
    doc: >-
      Control of small groups (<3 data) via removal (drop) or grouping to nearest neighbors (merge).
    required: false
    default: 'merge'
    hidden: false
    source: user
    constraints:
      enum: ["merge", "drop"]
    inputBinding:
      position: 11
      prefix: --small_groups
      separate: true

outputs:
  - id: harmonization_results
    type: Directory
    doc: >-
      Final output directory containing ComBat harmonized files, cluster-based harmonized files, figures (if requested), and log_files folder.
    outputBinding:
      glob: /output

expectedExitCode: 0

metadata:
  author: Aikaterini Vraka / Luis Martí-Bonmatí / GIBI230
  version: "1.1.0"
  orchestrator:
    network: overlay
    additional_metadata:
      runtime_mounts:
        - /input
        - /output
      notes: >-
        This task expects the container runtime to mount the input and output
        folders at /input and /output.
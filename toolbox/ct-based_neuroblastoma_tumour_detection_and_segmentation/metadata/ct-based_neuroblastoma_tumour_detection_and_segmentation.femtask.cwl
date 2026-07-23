cwlVersion: v1.2
class: FEMTask

id: ct-based_neuroblastoma_tumour_detection_and_segmentation
label: CT-based neuroblastoma tumour detection and segmentation
doc: >-
  Automated detection and segmentation of neuroblastoma lesions in contrast-enhanced
  CT (CE-CT) images using deep learning (alfaSUNet 3D). Processes DICOM or NIfTI
  inputs and outputs DICOM SEG and/or NIfTI masks. Requires GPU for inference.

requirements:
  - class: DockerRequirement
    dockerPull: harbor.eucaim.cancerimage.eu/processing-tools/ct-based_neuroblastoma_tumour_detection_and_segmentation:2.0.0
  
  - class: ResourceRequirement
    coresMin: 8
    ramMin: 16384

  - class: CUDARequirement
    cudaVersionMin: "11.2"
    cudaComputeCapability: "3.5"
    cudaDeviceCountMin: 1

baseCommand: [python, /app/alfasnet_ct_neuroblastoma_inference_pipeline.py]

inputs:
  - id: series_csv
    type: string
    doc: >-
      DICOM mode: Path to CSV with series to segment (e.g., /output/config/series_to_segment.csv).
    required: false
    default: null
    hidden: false
    source: user
    inputBinding:
      position: 1
      prefix: --series_csv
      separate: true

  - id: input_dir
    type: string
    doc: >-
      NIfTI mode: Path to folder containing raw NIfTI test cases (e.g., /input/nifti).
    required: false
    default: null
    hidden: false
    source: user
    inputBinding:
      position: 2
      prefix: --input_dir
      separate: true

  - id: output_dir
    type: string
    doc: >-
      Output directory for DICOM SEG, NIfTI masks, and logs.
    required: false
    default: '/output'
    hidden: false
    source: user
    inputBinding:
      position: 3
      prefix: --output_dir
      separate: true

  - id: emit_config
    type: string
    doc: >-
      Write execution_config.json and resolved_series_selection.csv (true/false).
    required: false
    default: 'true'
    hidden: false
    source: user
    inputBinding:
      position: 4
      prefix: --emit_config
      separate: true

  - id: emit_log
    type: string
    doc: >-
      Write processing_log.csv with metadata headers (true/false).
    required: false
    default: 'true'
    hidden: false
    source: user
    inputBinding:
      position: 5
      prefix: --emit_log
      separate: true

  - id: keep_intermediates
    type: string
    doc: >-
      Keep intermediate_files/ for debugging (true/false).
    required: false
    default: 'false'
    hidden: false
    source: user
    inputBinding:
      position: 6
      prefix: --keep_intermediates
      separate: true

outputs:
  - id: pipeline_results
    type: Directory
    doc: >-
      Final output directory containing DICOM_SEG, nifti masks, config files and logs.
    outputBinding:
      glob: /output

expectedExitCode: 0

metadata:
  author: GIBI230 / IIS La Fe
  version: "2.0.0"
  orchestrator:
    network: overlay
    additional_metadata:
      notes: >-
        Runtime/deployment must provide /input and /output mounts. The tool
        requires GPU acceleration to run the alfaSUNet model optimally.
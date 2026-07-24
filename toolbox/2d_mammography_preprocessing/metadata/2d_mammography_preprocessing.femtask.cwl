cwlVersion: v1.2
class: FEMTask

id: 2d_digital_mammography_harmonization
label: Digital Mammography DICOM Preprocessing Tool
doc: >-
  Preprocesses and enhances 2D digital mammography (MG) DICOM images.
  Applies configurable pipelines including z-score normalization, multiple
  denoising methods (adaptive median, gaussian, anisotropic, wavelet, cascade),
  and CLAHE contrast enhancement.

requirements:
  - class: DockerRequirement
    dockerPull: harbor.eucaim.cancerimage.eu/processing-tools/2d_digital_mammography_harmonization:1.2.0
  
  - class: ResourceRequirement
    coresMin: 4
    ramMin: 8192

baseCommand: [/app/entrypoint.sh]

inputs:
  - id: input_directory
    type: string
    doc: >-
      Directory name within the /input volume. Use "." to process the root of the input mount.
    required: false
    default: '.'
    hidden: false
    source: user
    inputBinding:
      position: 1
      prefix: --input_directory
      separate: true

  - id: output_directory
    type: string
    doc: >-
      Directory name within the /output volume. Use "." to save at the root of the output mount.
    required: false
    default: '.'
    hidden: false
    source: user
    inputBinding:
      position: 2
      prefix: --output_directory
      separate: true

  - id: num_workers
    type: int
    doc: >-
      Number of parallel patient workers for processing.
    required: false
    default: 4
    hidden: false
    source: user
    inputBinding:
      position: 3
      prefix: --num_workers
      separate: true

  - id: zscore_enabled
    type: string
    doc: >-
      Enable/disable z-score normalization.
    required: true
    default: 'true'
    hidden: false
    source: user
    constraints:
      enum: ["true", "false"]
    inputBinding:
      position: 4
      prefix: --zscore_enabled
      separate: true

  - id: zscore_p_low
    type: float
    doc: >-
      Lower percentile for clipping (e.g., 1.0).
    required: true
    default: 1.0
    hidden: false
    source: user
    inputBinding:
      position: 5
      prefix: --zscore_p_low
      separate: true

  - id: zscore_p_high
    type: float
    doc: >-
      Upper percentile for clipping (e.g., 99.0).
    required: true
    default: 99.0
    hidden: false
    source: user
    inputBinding:
      position: 6
      prefix: --zscore_p_high
      separate: true

  - id: denoise_method
    type: string
    doc: >-
      Denoise algorithm to apply.
    required: true
    default: 'cascade'
    hidden: false
    source: user
    constraints:
      enum: ["none", "adaptive_median", "gaussian", "anisotropic", "wavelet", "cascade"]
    inputBinding:
      position: 7
      prefix: --denoise_method
      separate: true

  - id: clahe_enabled
    type: string
    doc: >-
      Enable/disable CLAHE (Contrast Limited Adaptive Histogram Equalization).
    required: true
    default: 'true'
    hidden: false
    source: user
    constraints:
      enum: ["true", "false"]
    inputBinding:
      position: 8
      prefix: --clahe_enabled
      separate: true

  - id: clahe_clip_limit
    type: float
    doc: >-
      CLAHE clip limit (typically between 0.005 and 0.02).
    required: true
    default: 0.01
    hidden: false
    source: user
    inputBinding:
      position: 9
      prefix: --clahe_clip_limit
      separate: true

  - id: series_description_suffix
    type: string
    doc: >-
      Suffix appended to SeriesDescription to distinguish processed images.
    required: false
    default: '_preprocessed'
    hidden: false
    source: user
    inputBinding:
      position: 10
      prefix: --series_description_suffix
      separate: true

outputs:
  - id: preprocessed_dicoms
    type: Directory
    doc: >-
      Final output directory containing the preprocessed DICOM files maintaining the original structure.
    outputBinding:
      glob: /output

expectedExitCode: 0

metadata:
  author: Manuel Marfil-Trujillo / Pedro Miguel Martínez-Gironés / Luis Marti-Bonmati / GIBI230
  version: "1.2.0"
  orchestrator:
    network: overlay
    additional_metadata:
      runtime_mounts:
        - /input
        - /output
      notes: >-
        This task expects the container runtime to mount the input and output
        folders at /input and /output.
        CPU-bound task. Scales well with multiple cores by processing patients in parallel.
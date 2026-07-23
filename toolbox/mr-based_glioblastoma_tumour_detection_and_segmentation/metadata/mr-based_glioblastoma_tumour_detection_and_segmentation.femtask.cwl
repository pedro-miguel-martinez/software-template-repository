cwlVersion: v1.2
class: FEMTask

id: mr-based-glioblastoma-tumour-detection-and-segmentation
label: MR-based glioblastoma tumour detection and segmentation
doc: >-
  GBM segmentation that accepts one of several input modes (CSV file, JSON payload,
  inline series arguments, or wildcard discovery) and writes the segmentation
  outputs into an output directory.

requirements:
  - class: DockerRequirement
    dockerPull: harbor.eucaim.cancerimage.eu/processing-tools/mr-based_glioblastoma_tumour_detection_and_segmentation:2.1.1

  - class: ResourceRequirement
    coresMin: 4
    ramMin: 16384

  - class: CUDARequirement
    cudaVersionMin: "11.8"
    cudaComputeCapability: "6.0"
    cudaDeviceCountMin: 1

baseCommand: [python, /app/gbm_inference_pipeline.py]

inputs:
  mode:
    type: string
    doc: Processing mode for the segmentation run. Options are dicom-seg or nifti-only.
    required: false
    default: dicom-seg
    hidden: false
    source: user
    inputBinding:
      position: 1
      prefix: --mode
      separate: true

  target:
    type: string
    doc: Segmentation target to run. Options are necrosis, enhancing, edema, or total.
    required: false
    default: total
    hidden: false
    source: user
    inputBinding:
      position: 2
      prefix: --target
      separate: true

  series_list:
    type: string
    doc: JSON string with the series list describing the data to segment.
    required: false
    default: null
    hidden: false
    source: user
    inputBinding:
      position: 6
      prefix: --series-list
      separate: true

  series_selector:
    type: File
    doc: CSV file containing the series definitions to process.
    required: false
    default: null
    hidden: false
    source: user
    inputBinding:
      position: 5
      prefix: --series-selector
      separate: true

  series_args:
    type: string[]
    doc: Inline series rows passed as repeated arguments.
    required: false
    default: []
    hidden: false
    source: user
    inputBinding:
      position: 7
      prefix: --series-args
      separate: true
      itemSeparator: " "

  t1ce_pattern:
    type: string
    doc: Wildcard pattern used to discover T1ce series folders.
    required: false
    default: null
    hidden: false
    source: user
    inputBinding:
      position: 8
      prefix: --t1ce-pattern
      separate: true

  t2w_pattern:
    type: string
    doc: Wildcard pattern used to discover T2w series folders.
    required: false
    default: null
    hidden: false
    source: user
    inputBinding:
      position: 9
      prefix: --t2w-pattern
      separate: true

  flair_pattern:
    type: string
    doc: Wildcard pattern used to discover FLAIR series folders.
    required: false
    default: null
    hidden: false
    source: user
    inputBinding:
      position: 10
      prefix: --flair-pattern
      separate: true

  match_case:
    type: boolean
    doc: Enable case-sensitive wildcard matching.
    required: false
    default: false
    hidden: false
    source: user
    inputBinding:
      position: 11
      prefix: --match-case
      separate: true

  nifti_input_root:
    type: string
    doc: Root directory used when running in nifti-only mode.
    required: false
    default: /input/BBDD
    hidden: false
    source: user
    inputBinding:
      position: 12
      prefix: --nifti-input-root
      separate: true

  nifti_output_root:
    type: string
    doc: Output root for NIfTI masks in nifti-only mode.
    required: false
    default: /output/BBDD_result
    hidden: false
    source: user
    inputBinding:
      position: 13
      prefix: --nifti-output-root
      separate: true

  bet_frac:
    type: float
    doc: BET fractional intensity threshold.
    required: false
    default: 0.5
    hidden: false
    source: user
    inputBinding:
      position: 14
      prefix: --bet-frac
      separate: true

  keep_intermediates:
    type: boolean
    doc: Preserve intermediate preprocessing outputs.
    required: false
    default: false
    hidden: false
    source: user
    inputBinding:
      position: 18
      prefix: --keep-intermediates
      separate: true

  keep_submodels:
    type: boolean
    doc: Export the individual submodels in addition to the fused result.
    required: false
    default: true
    hidden: false
    source: user
    inputBinding:
      position: 19
      prefix: --keep-submodels
      separate: true

  emit_config:
    type: boolean
    doc: Write the resolved series selection and processing configuration.
    required: false
    default: true
    hidden: false
    source: user
    inputBinding:
      position: 20
      prefix: --emit-config
      separate: true

  seg_series_number:
    type: int
    doc: Optional series number used for export metadata.
    required: false
    default: null
    hidden: false
    source: user
    inputBinding:
      position: 17
      prefix: --seg-series-number
      separate: true

  postprocess:
    type: boolean
    doc: Enable post-processing after segmentation.
    required: false
    default: true
    hidden: false
    source: user
    inputBinding:
      position: 15
      prefix: --postprocess
      separate: true

outputs:
  results:
    type: Directory
    doc: Directory tree containing the generated segmentation outputs.
    outputBinding:
      glob: $(inputs.output_root)

expectedExitCode: 0

metadata:
  author: GIBI230 / IIS La Fe
  version: "2.1.1"
  orchestrator:
    network: overlay
    additional_metadata:
      notes: >-
        This task expects the container runtime to mount the input and output
        folders at /input and /output.

cwlVersion: v1.2
class: FEMTask

id: harmonization-tool
label: Denoising and Inhomogeneity Correction Tool
doc: >-
  Applies MR denoising and optional N4 bias field correction to DICOM series,
  preserving input folder structure in the harmonized output.

requirements:
  - class: DockerRequirement
    dockerPull: harbor.eucaim.cancerimage.eu/processing-tools/denoising_inhomogeneity_correction_tool:1.1.1

  - class: ResourceRequirement
    coresMin: 2
    ramMin: 8192

baseCommand: [python, /app/main.py]

inputs:
  config_file:
    type: string
    doc: >-
      Optional JSON configuration file path mounted in the container,
      e.g. /config/parameter_configuration.json. If omitted, paths must be
      provided and the configuration is built from CLI arguments.
    required: false
    default: null
    hidden: false
    source: user
    inputBinding:
      position: 1
      prefix: --config
      separate: true

  paths:
    type: string[]
    doc: >-
      List of input DICOM folders, e.g. /input/Patient1/Study1/T1W.
      Required when config_file is not provided.
    required: false
    default: null
    hidden: false
    source: user
    inputBinding:
      position: 2
      prefix: --paths
      separate: true

  output:
    type: string
    doc: Base output directory for harmonized DICOM files.
    required: false
    default: /output
    hidden: false
    source: user
    inputBinding:
      position: 3
      prefix: --output
      separate: true

  series_number:
    type: int
    doc: Absolute SeriesNumber for harmonized series.
    required: false
    default: null
    hidden: false
    source: user
    inputBinding:
      position: 4
      prefix: --series_number
      separate: true

  series_description_suffix:
    type: string
    doc: Suffix appended to SeriesDescription.
    required: false
    default: _harmonized
    hidden: false
    source: user
    inputBinding:
      position: 5
      prefix: --series_description_suffix
      separate: true

  denoising:
    type: string
    doc: Denoising filter to apply.
    required: false
    default: null
    hidden: false
    source: user
    constraints:
      enum: [adf, cff, bilateral, nlm, susan]
    inputBinding:
      position: 6
      prefix: --denoising
      separate: true

  conductance:
    type: float
    doc: Conductance parameter for ADF filter.
    required: false
    default: 0.5
    hidden: false
    source: user
    inputBinding:
      position: 7
      prefix: --conductance
      separate: true

  iterations:
    type: int
    doc: Number of iterations for ADF or CFF filter.
    required: false
    default: 3
    hidden: false
    source: user
    inputBinding:
      position: 8
      prefix: --iterations
      separate: true

  time_step:
    type: float
    doc: Time step for ADF or CFF filter.
    required: false
    default: 0.0625
    hidden: false
    source: user
    inputBinding:
      position: 9
      prefix: --time_step
      separate: true

  domain_sigma:
    type: float
    doc: Domain sigma for bilateral filter.
    required: false
    default: 1.5
    hidden: false
    source: user
    inputBinding:
      position: 10
      prefix: --domain_sigma
      separate: true

  range_sigma:
    type: float
    doc: Range sigma for bilateral filter.
    required: false
    default: 50.0
    hidden: false
    source: user
    inputBinding:
      position: 11
      prefix: --range_sigma
      separate: true

  sigma:
    type: float
    doc: Sigma for NLM filter.
    required: false
    default: 1.0
    hidden: false
    source: user
    inputBinding:
      position: 12
      prefix: --sigma
      separate: true

  patch_radius:
    type: int
    doc: Patch radius for NLM filter.
    required: false
    default: 1
    hidden: false
    source: user
    inputBinding:
      position: 13
      prefix: --patch_radius
      separate: true

  block_radius:
    type: int
    doc: Block radius for NLM filter.
    required: false
    default: 5
    hidden: false
    source: user
    inputBinding:
      position: 14
      prefix: --block_radius
      separate: true

  brightness_threshold:
    type: float
    doc: Brightness threshold for SUSAN filter.
    required: false
    default: 0.75
    hidden: false
    source: user
    inputBinding:
      position: 15
      prefix: --brightness_threshold
      separate: true

  fwhm:
    type: float
    doc: FWHM for SUSAN filter.
    required: false
    default: 3.0
    hidden: false
    source: user
    inputBinding:
      position: 16
      prefix: --fwhm
      separate: true

  n4:
    type: boolean
    doc: Enables N4 bias field correction.
    required: false
    default: false
    hidden: false
    source: user
    inputBinding:
      position: 17
      prefix: --n4

  bspline_size:
    type: int
    doc: BSpline size for N4 correction.
    required: false
    default: 50
    hidden: false
    source: user
    inputBinding:
      position: 18
      prefix: --bspline_size
      separate: true

  n4_iterations:
    type: int[]
    doc: Iterations for N4 correction.
    required: false
    default: [50, 30]
    hidden: false
    source: user
    inputBinding:
      position: 19
      prefix: --n4_iterations
      separate: true

  shrink_factor:
    type: int
    doc: Shrink factor for N4 correction.
    required: false
    default: 2
    hidden: false
    source: user
    inputBinding:
      position: 20
      prefix: --shrink_factor
      separate: true

outputs:
  harmonized_dicom_output:
    type: Directory
    doc: Harmonized DICOM output tree generated by the tool.
    outputBinding:
      glob: /output

expectedExitCode: 0

metadata:
  author: GIBI230 / IIS La Fe
  version: "1.1.1"
  orchestrator:
    network: overlay
    additional_metadata:
      notes: "Runtime/deployment must provide /input, /output and (for config mode) /config mounts."

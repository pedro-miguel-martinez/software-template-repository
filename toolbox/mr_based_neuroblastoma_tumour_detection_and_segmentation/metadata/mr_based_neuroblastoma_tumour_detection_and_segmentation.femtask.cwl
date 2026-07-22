cwlVersion: v1.2
class: FEMTask

id: mr-based-neuroblastoma-tumour-detection-and-segmentation
label: MR-based Neuroblastoma Tumour Detection and Segmentation
doc: >-
  Runs nnU-Net inference for neuroblastoma tumour segmentation on T2-weighted
  MR data in DICOM or NIfTI mode and exports DICOM SEG objects for downstream
  federated workflows.

requirements:
  - class: DockerRequirement
    dockerPull: harbor.eucaim.cancerimage.eu/processing-tools/mr_based_neuroblastoma_tumour_detection_and_segmentation:2.0.0

  - class: ResourceRequirement
    coresMin: 8
    ramMin: 16384
 
  - class: CUDARequirement
    cudaVersionMin: "11.2"
    cudaComputeCapability: "3.5"
    cudaDeviceCountMin: 1

baseCommand: [python, /app/nnunet_nb_segmentation/entrypoint.py]

inputs:
  mode:
    type: string
    doc: >-
      Processing mode. Use dicom-seg for DICOM input and DICOM SEG export,
      or nifti-only for NIfTI input.
    required: true
    default: dicom-seg
    hidden: false
    source: user
    inputBinding:
      position: 1
      prefix: --mode
      separate: true

  series_selector:
    type: File
    doc: >-
      Optional CSV file listing the DICOM series to process. Required for
      DICOM mode when the series are not discovered automatically.
    required: false
    default: null
    hidden: false
    source: user
    inputBinding:
      position: 2
      prefix: --series-selector
      separate: true

  series_description_regex:
    type: string
    doc: >-
      Optional regex used to select DICOM series by SeriesDescription.
    required: false
    default: null
    hidden: false
    source: user
    inputBinding:
      position: 3
      prefix: --series-description-regex
      separate: true

  keep_nifti:
    type: string
    doc: >-
      Legacy compatibility flag. If set to true, the tool preserves temporary
      intermediate files in the same way as keep_intermediates and keeps the
      generated NIfTI and resampled outputs available.
    required: false
    default: "false"
    hidden: false
    source: user
    inputBinding:
      position: 4
      prefix: --keep-nifti
      separate: true

  keep_intermediates:
    type: string
    doc: >-
      Preferred flag for keeping temporary processing artifacts. When set to
      true, the tool preserves the temporary NIfTI, mask, resampled and JSON
      files generated during execution; when false, it removes them and leaves
      only the final DICOM SEG outputs.
    required: false
    default: "false"
    hidden: false
    source: user
    inputBinding:
      position: 5
      prefix: --keep-intermediates
      separate: true

  segments_config:
    type: File
    doc: >-
      Optional JSON file with custom segment metadata for the DICOM SEG export.
    required: false
    default: null
    hidden: false
    source: user
    inputBinding:
      position: 6
      prefix: --segments-config
      separate: true

  nifti_input_root:
    type: Directory
    doc: >-
      Input directory containing NIfTI files when running in nifti-only mode.
    required: false
    default: /input/BBDD
    hidden: true
    source: user
    inputBinding:
      position: 7
      prefix: --nifti-input-root
      separate: true

  nifti_output_root:
    type: Directory
    doc: >-
      Output directory for NIfTI segmentation masks in nifti-only mode.
    required: false
    default: /output/BBDD_result
    hidden: true
    source: user
    inputBinding:
      position: 8
      prefix: --nifti-output-root
      separate: true

  seg_series_number:
    type: int
    doc: >-
      SeriesNumber used in the generated DICOM SEG objects.
    required: false
    default: 2302001
    hidden: false
    source: user
    inputBinding:
      position: 9
      prefix: --seg-series-number
      separate: true

  seg_algorithm_name:
    type: string
    doc: >-
      Algorithm name embedded in the DICOM SEG metadata.
    required: false
    default: nnUNet_Neuroblastoma_Primage_training
    hidden: false
    source: user
    inputBinding:
      position: 10
      prefix: --seg-algorithm-name
      separate: true

  seg_content_creator:
    type: string
    doc: >-
      ContentCreatorName stored in the DICOM SEG metadata.
    required: false
    default: MR-based neuroblastoma detection AI
    hidden: false
    source: user
    inputBinding:
      position: 11
      prefix: --seg-content-creator
      separate: true

  seg_coordinating_center:
    type: string
    doc: >-
      ClinicalTrialCoordinatingCenterName stored in the DICOM SEG metadata.
    required: false
    default: Unknown
    hidden: false
    source: user
    inputBinding:
      position: 12
      prefix: --seg-coordinating-center
      separate: true

  seg_trial_id:
    type: string
    doc: >-
      ClinicalTrialSeriesID stored in the DICOM SEG metadata.
    required: false
    default: nnUNet_neuroblastoma_segmentation
    hidden: false
    source: user
    inputBinding:
      position: 13
      prefix: --seg-trial-id
      separate: true

outputs:
  dicom_seg_results:
    type: Directory
    doc: >-
      Final DICOM Segmentation outputs written under the DICOM_SEG folder.
    outputBinding:
      glob: DICOM_SEG

  nifti_results:
    type: Directory
    doc: >-
      NIfTI segmentation masks written under the BBDD_result folder for
      nifti-only mode.
    outputBinding:
      glob: BBDD_result

expectedExitCode: 0

metadata:
  author: IIS La Fe / GIBI230
  version: "2.0.0"
  orchestrator:
    network: overlay
    additional_metadata:
      runtime_mounts:
        - /input
        - /output
      notes: >-
        This task expects the container runtime to mount the input and output
        folders at /input and /output.

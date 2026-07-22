cwlVersion: v1.2
class: FEMTask

id: ml-model-for-mr-series-categorisation
label: ML Model for MR Series Categorisation
doc: >-
  Classifies MRI DICOM series into standardized sequence and quality tags,
  producing a structured JSON report for federated execution.

requirements:
  - class: DockerRequirement
    dockerPull: harbor.eucaim.cancerimage.eu/processing-tools/ml_model_for_mr_series_categorisation:1.1.0

  - class: ResourceRequirement
    coresMin: 2
    ramMin: 4096

baseCommand: [/app/entrypoint.sh]

outputs:
  results_json:
    type: File
    doc: Structured classification results in JSON format.
    outputBinding:
      glob: results.json

expectedExitCode: 0

metadata:
  author: GIBI230 / IIS La Fe
  version: "1.1.0"
  orchestrator:
    network: overlay
    additional_metadata:
      notes: "Entrypoint expects /input and /output mounts and writes the report to /output/results.json."

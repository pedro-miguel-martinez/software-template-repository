# CT-based Neuroblastoma Tumour Detection and Segmentation

**Biotools ID**: `biotools:ct-based_neuroblastoma_tumour_detection_and_segmentation`  
**EUCAIM Tool ID**: EUCAIM-SW-022_T-01-02-005  
**Version**: 2.0.0  
**License**: Custom (CC-BY-NC-ND-4.0 inspired, with additional restrictions)

---

## Overview

Automated detection and segmentation of neuroblastoma lesions in contrast-enhanced CT (CE-CT) images using deep learning. The tool employs a alfaSUNet 3D model (U-Net architecture with residual operations, atrous dilated convolutions, and specialized batch generators) to produce binary tumour masks.

**Key Features:**
- **Input formats**: DICOM series (via CSV selector) or NIfTI volumes
- **Output formats**: DICOM Segmentation Object (DICOM SEG) and/or NIfTI masks
- **Preprocessing**: RAS canonicalization, resampling (512×512×512, 1mm spacing), z-score normalization, patch-based processing (128×128×128 with 50% overlap)
- **Postprocessing**: Morphological refinement (detach largest component + closing operations)
- **Containerized**: Docker images for local/proxy deployment and EUCAIM processing-tools registry

**Clinical Application**: Automated analysis of paediatric neuroblastoma cases in CE-CT imaging studies.

---

## License and Usage Restrictions

**IMPORTANT**: This software is licensed for **academic and research use only** within the scope of the **EUCAIM project** and future European public research infrastructures (including EDIC entities).

### Key Restrictions:
- ❌ **No commercial use** or revenue-generating activities
- ❌ **No redistribution** or integration into other products/services
- ❌ **No modification** or creation of derivative works
- ❌ **No reverse engineering** or code extraction
- ✅ Academic research use in EUCAIM context (with attribution and prior notification)

**License Type**: Custom non-transferable restricted-use license, inspired by CC-BY-NC-ND-4.0  
**Full License Agreement**: See [Terms of Use](https://drive.google.com/file/d/1mvGl_fexQIqBR7njGl73V81VdZ7ycPBs/view?usp=drive_link)

For permissions, licensing inquiries, or questions, contact: **gibi230@iislafe.es**

---

## Features

- Single CE-CT segmentation target (binary mask)
- DICOM ingestion via CSV; optional NIfTI input
- Patch-based preprocessing (128×128×128) with overlap; z-score normalization and resampling
- Post-processing (detach + morphological curation) and DICOM SEG export (dcmqi/itkimage2segimage)
- Docker images for local/proxy use and EUCAIM-compatible processing-tools image

## Quick Start (Docker)

### Build (local/proxy Dockerfile)
```bash
docker build -t harbor.eucaim.cancerimage.eu/processing-tools/ct-based_neuroblastoma_tumour_detection_and_segmentation:2.0.0 -f Dockerfile .
```

### Build (EUCAIM processing-tools)
```bash
docker build -t harbor.eucaim.cancerimage.eu/processing-tools/ct-based_neuroblastoma_tumour_detection_and_segmentation:2.0.0 -f Dockerfile.processing-tools .
```

### Run (DICOM via CSV)
```bash
docker run --rm --gpus all \
	-v /path/to/input:/input \
	-v /path/to/output:/output \
	harbor.eucaim.cancerimage.eu/processing-tools/ct-based_neuroblastoma_tumour_detection_and_segmentation:2.0.0 \
	--series_csv /output/config/series_to_segment.csv \
	--output_dir /output
```

### Run (NIfTI folder)
```bash
docker run --rm --gpus all \
	-v /path/to/input:/input \
	-v /path/to/output:/output \
	harbor.eucaim.cancerimage.eu/processing-tools/ct-based_neuroblastoma_tumour_detection_and_segmentation:2.0.0 \
	--input_dir /input/nifti \
	--output_dir /output
```

---

## Input Specification (DICOM)

Use a CSV with one row per CT series:
```csv
dataset_id,patient_id,study_id,sequence_type,series_path
DS001,PAT001,STUDY001,CE-CT,/input/DICOM/DS001/PAT001/STUDY001/SERIES
```

Place the CSV in `/output/config/series_to_segment.csv` so the container can resolve series paths.

---

## Output Structure

```
/output/
├── DICOM_SEG/                                    # Final DICOM segmentation outputs
│   └── <dataset>/<patient>/<study>/<series_number>_<model>_<segment>/
│       └── <sop_uid>.SEG.dcm
├── intermediate_files/                           # Temporary processing files (cleaned by default)
│   └── <dataset>/<patient>/<study>/<series>/
│       ├── raw_nifti/                           # DICOM→NIfTI conversion
│       ├── work/                                # Preprocessing artifacts
│       └── temp_masks/                          # Inference masks
├── execution_config.json                        # Execution metadata and parameters
├── processing_log.csv                           # Processing results per series
└── resolved_series_selection.csv               # Resolved series paths (audit trail)
```

### Output Files

- **DICOM SEG**: Final segmentation in DICOM format at `DICOM_SEG/<hierarchy>/<series_number>_<model>_<segment>/`
- **NIfTI masks**: Available in `intermediate_files/` when `--keep_intermediates true`
- **Logs**: Execution config, processing log, and resolved series selection at output root

### Cleanup Behavior

- By default (`--keep_intermediates false`): `intermediate_files/` is removed after processing
- Only `DICOM_SEG/`, logs, and config files remain visible
- Use `--keep_intermediates true` to preserve NIfTI masks and preprocessing artifacts for debugging

---

## Technical Specifications

### Model Architecture
- **Type**: alfaSUNet (3D U-Net with residual operations and atrous dilated convolutions)
- **Model file**: `./models/alfasnet_CT_neuroblastoma_model_005.hdf5`
- **Patch size**: 128×128×128 (50% overlap during inference)
- **Target volume**: 512×512×512 voxels at 1.0mm isotropic spacing

### Processing Pipeline
1. **Preprocessing**: DICOM→NIfTI conversion, RAS canonicalization, CT floor clamp (-1024), shift (+1024), resampling, z-score normalization
2. **Inference**: Patch-based prediction with overlap reconstruction
3. **Postprocessing**: Detach largest component + morphological closing (`hybrid_curation_detach_base_close`)

### Fixed Configuration (Hardcoded)
Segment metadata is loaded from `config/segments_info.json` and hardcoded in the pipeline:
- **Algorithm name**: `alfaSUNet_CT_Neuroblastoma_IIS`
- **Content creator**: `CT-based neuroblastoma detection AI`
- **Coordinating center**: `HULAFE - IIS La Fe - GIBI230`
- **Trial ID**: `alfaSUNet_ct_neuroblastoma_segmentation`
- **Segment key**: `neuroblastoma_cect`
- **Model name**: `AI_model_alfasUnet_HULAFE`

---

## CLI Summary

Required (choose one input mode):
- `--series_csv PATH`  (DICOM mode)
- `--input_dir PATH`   (NIfTI mode)

Common options:
- `--output_dir PATH` (default `/output/pipeline_results`)
- `--emit_config {true,false}` (default true) writes execution_config.json and resolved_series_selection.csv
- `--emit_log {true,false}` (default true) writes processing_log.csv with metadata headers
- `--keep_intermediates {true,false}` (default false) keep intermediate_files/ for debugging; when false, only DICOM_SEG/ and logs remain

---

## Config Examples

- `config/series_to_segment_example.csv`: sample DICOM selector.
- `config/segments_info.json`: minimal segment metadata (label, color) for DICOM SEG.

---

## Requirements

- Docker 20.10+, NVIDIA Docker for GPU support
- Inside image: TensorFlow 2.12.0, TensorFlow Addons 0.21.0, SimpleITK, nibabel, pydicom, dcm2niix, dcmqi v1.3.1 (for SEG export)

---

## Credits and Contact

### Development Team
**Biomedical Imaging Research Group (GIBI230)**  
La Fe Health Research Institute (IIS La Fe)  
Avenida Fernando Abril Martorell, València, 46026, Spain

**Developers:**
- **Pedro-Miguel Martinez-Girones** (Primary contact, Developer, Support)  
  📧 pedromiguel_martinez@iislafe.es | [ORCID](https://orcid.org/0000-0002-9506-9451)
  
- **Adrian Galiana-Bordera** (Developer)  
  📧 adrian_galiana@iislafe.es | [ORCID](https://orcid.org/0000-0002-8324-8284)

**Support:**
- **Carina Soler-Pons**  
  📧 carina_soler@iislafe.es | [ORCID](https://orcid.org/0009-0000-2991-1391)

**Principal Investigator:**
- **Luis Marti-Bonmati**  
  📧 luis_marti@iislafe.es | [ORCID](https://orcid.org/0000-0002-8234-010X)

### Institutional Contact
- **General inquiries**: gibi230@iislafe.es
- **Homepage**: [ACIM - IIS La Fe](https://www.acim.lafe.san.gva.es/acim/?page_id=675&lang=es)
- **Institute**: [IIS La Fe](https://www.iislafe.es/en/)
- **LinkedIn**: [GIBI230](https://www.linkedin.com/company/grupo-de-investigaci%C3%B3n-biom%C3%A9dica-en-imagen/)

### Funding and Context
This tool was developed within the **EUCAIM Project** (European Cancer Image Platform).  
🌐 [EUCAIM - Cancer Image Europe](https://cancerimage.eu/)

---

## Version and License Information

**Current Version**: 2.0.0  
**Release Date**: December 22, 2025  
**License**: Custom non-transferable restricted-use license (CC-BY-NC-ND-4.0 inspired)  
**Biotools Registry**: [biotools:ct-based_neuroblastoma_tumour_detection_and_segmentation](https://bio.tools/ct-based_neuroblastoma_tumour_detection_and_segmentation)

© IIS La Fe, Valencia, Spain (HULAFE) – All rights reserved

---

## Disclaimer

**AS IS WARRANTY**: This software is provided "AS IS" and "AS-AVAILABLE" without any warranties, express or implied, including but not limited to merchantability, fitness for a particular purpose, or non-infringement.

**LIABILITY**: HULAFE and its developers assume no liability for indirect, incidental, special, or consequential damages arising from the use of this software, including data loss, system errors, or misuse.

**USER RESPONSIBILITY**: Full responsibility for legal and ethical handling of processed data lies solely with the end-user (Data Holder and Data User). The tool is optional and intended to assist, not replace, manual validation of imaging data quality and integrity.

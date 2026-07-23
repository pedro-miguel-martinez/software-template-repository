# MR-based Diffuse Midline Glioma (DIPG) Tumour Detection and Segmentation

Automated detection and segmentation of Diffuse Intrinsic Pontine Glioma (DIPG) tumours in pediatric brainstem MR images using alfaSUNet deep learning approach.

## Features
- Dual-channel alfaSUNet (T1w + T2w/FLAIR)
- DICOM → DICOM SEG export (dcmqi) and NIfTI-only mode
- Flexible input: CSV selector, JSON arguments, inline args, wildcard filtering
- GPU-ready Docker images (local and EUCAIM processing-tools)

## Quick Start

Optional: pull from registry:
```bash
docker login harbor.eucaim.cancerimage.eu -u <user> -p <token>
docker pull harbor.eucaim.cancerimage.eu/processing-tools/mr-based_dipg_tumour_detection_and_segmentation:latest
```

Recommended run (CSV, dicom-seg by default):
```bash
docker run --rm --gpus all \
  -v /path/to/input:/input \
  -v /path/to/output:/output \
  harbor.eucaim.cancerimage.eu/processing-tools/mr-based_dipg_tumour_detection_and_segmentation:latest \
  --csv-file /output/config/series_to_segment.csv \
  --output-dir /output \
  --emit-config
```

NIfTI-only run (CSV with NIfTI paths, no DICOM SEG export):
```bash
docker run --rm --gpus all \
  -v /path/to/input:/input -v /path/to/output:/output \
  harbor.eucaim.cancerimage.eu/processing-tools/mr-based_dipg_tumour_detection_and_segmentation:latest \
  --mode nifti-only \
  --csv-file /output/config/series_to_segment.csv \
  --output-dir /output
```

Custom threshold (more conservative segmentation):
```bash
docker run --rm --gpus all \
  -v /path/to/input:/input -v /path/to/output:/output \
  harbor.eucaim.cancerimage.eu/processing-tools/mr-based_dipg_tumour_detection_and_segmentation:latest \
  --csv-file /output/config/series_to_segment.csv \
  --output-dir /output \
  --threshold 0.6
```

Single study (JSON inline):
```bash
docker run --rm --gpus all \
  -v /path/to/input:/input -v /path/to/output:/output \
  harbor.eucaim.cancerimage.eu/processing-tools/mr-based_dipg_tumour_detection_and_segmentation:latest \
  --json-args '{"dataset_id":"DS1","patient_id":"P1","study_id":"S1","sequences":{"T1w":"/input/DICOM/DS1/P1/S1/T1","T2w":"/input/DICOM/DS1/P1/S1/T2"}}' \
  --output-dir /output
```

Single study (JSON with FLAIR instead of T2w):
```bash
docker run --rm --gpus all \
  -v /path/to/input:/input -v /path/to/output:/output \
  harbor.eucaim.cancerimage.eu/processing-tools/mr-based_dipg_tumour_detection_and_segmentation:latest \
  --json-args '{"dataset_id":"DS1","patient_id":"P1","study_id":"S1","sequences":{"T1w":"/input/DICOM/DS1/P1/S1/T1","FLAIR":"/input/DICOM/DS1/P1/S1/FLAIR"}}' \
  --output-dir /output
```

Wildcard discovery (by folder name):
```bash
docker run --rm --gpus all \
  -v /path/to/input:/input -v /path/to/output:/output \
  harbor.eucaim.cancerimage.eu/processing-tools/mr-based_dipg_tumour_detection_and_segmentation:latest \
  --wildcard-dir /input/DICOM \
  --t1w-pattern "*T1*" \
  --t2w-pattern "*T2*" \
  --output-dir /output \
  --emit-config
```

Inline CSV rows (no files):
```bash
docker run --rm --gpus all \
  -v /path/to/input:/input -v /path/to/output:/output \
  harbor.eucaim.cancerimage.eu/processing-tools/mr-based_dipg_tumour_detection_and_segmentation:latest \
  --series-args "DS1,P1,S1,T1w,/input/DICOM/DS1/P1/S1/T1" "DS1,P1,S1,T2w,/input/DICOM/DS1/P1/S1/T2" \
  --output-dir /output
```

## Segmentation Target
- DIPG Tumor: Diffuse Intrinsic Pontine Glioma automatic segmentation
  - SeriesNumber: 2302201
  - Model name (ContentLabel/ManufacturerModelName): automatic_dipg_segmentation_tumor_mask
  - Segment label: automatic
  - RGB: [255, 0, 0]

## Input Specification
Provide series via one of: `--json-args`, `--csv-file`, `--series-args`, or wildcard patterns. Paths must be absolute inside the container. In EUCAIM setups, prefer placing the CSV under `/output/config/` (write permissions are usually granted there). Wildcards are intended for DICOM input.

Accepted sequence types: `T1w` (mandatory), `T2w`, `FLAIR`.
- Requirement: T1w is mandatory, and the second channel can be T2w or, if T2w is unavailable, FLAIR.

CSV format (example):
```csv
dataset_id,patient_id,study_id,sequence_type,series_path
DS1,P1,S1,T1w,/input/DICOM/DS1/P1/S1/T1
DS1,P1,S1,T2w,/input/DICOM/DS1/P1/S1/T2
# Or, if T2w is not available, use FLAIR instead of T2w:
DS1,P1,S1,FLAIR,/input/DICOM/DS1/P1/S1/FLAIR
```

## Output
- dicom-seg mode: `/output/{dataset}/{patient}/{study}/2302201_automatic_dipg_segmentation_tumor_mask/`
  - `{SOPInstanceUID}.SEG.dcm` (DICOM SEG)
- nifti-only mode: `/output/{dataset}/{patient}/{study}/`
  - `segmentation_native.nii.gz` (mask in preprocessed space)
- If `--keep-intermediates`: `/output/intermediates/{patient}/{study}/{series_id}/`
  - `T1w_denoised.nii.gz`, `T2w_denoised.nii.gz`
  - `N4_corrected_T1w.nii.gz`, `N4_corrected_T2w.nii.gz`
  - `mask_native.nii.gz`, `mask_resampled.nii.gz`
  - `seg_metadata.json`
- `processing_log.csv` and `resolved_series_selection.csv` (if `--emit-config`)

## Processing Pipeline
1. DICOM → NIfTI (dcm2niix)
2. **Register T2w/FLAIR to T1w** (rigid registration on original images using Mutual Information metric)
3. Denoising (anisotropic T1w; bilateral T2w/FLAIR)
4. N4 Bias Field Correction (SimpleITK)
5. Resampling using original voxel spacing as zoom factor (DIPG original method)
6. Z-score normalization
7. Patchify (64×64×64 with 50% overlap), per-channel separately
8. Model inference (alfaSUNet) - predictions scaled by factor 2
9. Merge overlapping patches by averaging
10. **Morphology post-process** (3D connectivity-aware):
    - Thresholding at probability > 0.5
    - Binary closing with ball radius=1
    - Remove small objects (min 100 voxels) using 3D connectivity
    - Keep only largest connected component (3D connectivity)
11. Inverse rescale to original size (using 1/voxel_spacing)
12. Resample to DICOM geometry
13. Export DICOM SEG (dcmqi itkimage2segimage)

**Key Design Decision:** Registration is performed on **original images** (not after denoising/N4) because:
- Mutual Information metric is robust to noise
- Preserves original anatomical features for alignment
- Standard approach in neuroimaging pipelines (FSL, SPM, BraTS)
- Reduces processing artifacts that could affect registration quality

## Key Parameters

### Configurable
- **`--threshold`**: Probability threshold for binarization (default: 0.5, range: 0.0-1.0)
  - Controls which voxels from probability map become segmentation (prob > threshold → 1, else → 0)
  - Example: `--threshold 0.6` for more conservative segmentation
  - Validated default: 0.5 (based on 63-patient DIPG cohort)

### Fixed
- Resampling: Uses original voxel spacing as zoom factor (not fixed 1mm isotropic)
- **Post-processing morphology (fixed)**: 
  - Min object size: 100 voxels
  - Morphological closing radius: 1
  - 3D connectivity for component detection
  - Keeps only largest connected component
- Patch size: 64×64×64
- Patch overlap: 0.5 (step=32)
- Normalization: Z-score
- Prediction scaling: Model output multiplied by 2
- Model path (inside container): `/models/DIPG_model.hdf5`

## Requirements
- Docker 20.10+ and NVIDIA Docker (for GPU support)
- CUDA-compatible GPU (recommended)
- Dependencies pinned in `requirements.txt`

## Scientific Validation
This tool implements the approach described in:

Fernández-Patón M, Montoya-Filardi A, Galiana-Bordera A, Martínez-Gironés PM, Veiga-Canuto D, Martínez de las Heras B, Cerdá-Alberich L, Martí-Bonmatí L. Deep Learning Auto-segmentation of Diffuse Midline Glioma on Multimodal Magnetic Resonance Images. Journal of Imaging Informatics in Medicine. 2025. DOI: 10.1007/s10278-025-01557-9.

- Input sequences: T1w + T2w (2 channels)
- Preprocessing: Resampling using voxel spacing as zoom factor; Z-score normalization
- Patch-based inference: 64×64×64 with overlap
- Patient cohort: 63 pediatric DIPG cases (median age 9 years)

## Contact
eucaim_project@iislafe.es (Support); matias_fernandez@iislafe.es (Developing issues); pedromiguel_martinez@iislafe.es (Support); adrian_galiana@iislafe.es (Developing issues); carina_soler@iislafe.es (Support); luis_marti@iislafe.es

## License
See LICENSE

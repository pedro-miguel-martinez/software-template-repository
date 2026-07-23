# MR-based Glioblastoma Tumour Detection and Segmentation

Automated detection and segmentation of glioblastoma tumours in MR images using alfaSUNet deep learning multi-pourpose approach.

## Features

- **4 specialized models**: necrosis, edema, enhancing tumor, total tumor
- **Model fusion**: Combine necrosis+edema+enhancing for total tumor segmentation
- **Batch processing**: Process multiple patients/studies/series automatically
- **DICOM SEG export**: Standard DICOM Segmentation objects with full metadata
- **Flexible input**: CSV selector, JSON arguments, or regex filtering

## Quick Start

### Docker Registry Access

First, log in to the EUCAIM Harbor registry using your user credentials (retrieved from your user profile in the registry):

```bash
docker login harbor.eucaim.cancerimage.eu -u <your_user> -p <your_token>
```

### Pull Docker Image from Registry

To use the pre-built image from the registry:

```bash
docker pull harbor.eucaim.cancerimage.eu/processing-tools/mr-based_glioblastoma_tumour_detection_and_segmentation:latest
```

### Run Basic Segmentation (Recommended Configuration)

```bash
docker run --rm --gpus all \
  -v /path/to/input:/input \
  -v /path/to/output:/output \
  harbor.eucaim.cancerimage.eu/processing-tools/mr-based_glioblastoma_tumour_detection_and_segmentation:latest \
  --target total-fused \
  --emit-config true
```

**Why `total-fused`?** The developers recommend using `total-fused` for total tumor segmentation as it produces better results than the single `total` model by combining specialized subregion models (necrosis + edema + enhancing tumor).

## Segmentation Targets

- `necrosis`: Intratumoral necrotic core
- `edema`: Peritumoral vasogenic edema  
- `enhancing`: Contrast-enhancing tumor region
- `total`: Total tumor (single model)
- `total-fused`: **Total tumor (fusion of necrosis+edema+enhancing) - RECOMMENDED**

**Performance Comparison for Total Tumor:**

| Target | Method | Performance |
|--------|--------|-------------|
| `total-fused` | Fusion of 3 specialized models | **Better** - Recommended by developers |
| `total` | Single unified model | Good, but lower performance than fused approach |

**Recommendation:** For total tumor segmentation, use `--target total-fused`. This approach combines the specialized necrosis, edema, and enhancing-tumor models, producing superior results compared to the single `total` model. The fused method leverages the strengths of each subregion-specific model for optimal performance.

## Total-Fused Submodels Export

When using `--target total-fused`, the tool **automatically runs all 3 submodels** (necrosis, edema, enhancing) to generate the fused result. By default, it also exports individual DICOM SEG files for each submodel along with the fused result.

### Control Submodel Export with `--keep-submodels`

| Setting | Behavior | Use Case |
|---------|----------|----------|
| `--keep-submodels true` (default) | Exports 4 SEG: necrosis, edema, enhancing, fused | Detailed analysis with subregions |
| `--keep-submodels false` | Exports 1 SEG: fused only | Clean output, final tumor only |

**Example: Export only the fused result**
```bash
docker run --rm --gpus all \
  -v /path/to/input:/input \
  -v /path/to/output:/output \
  harbor.eucaim.cancerimage.eu/processing-tools/mr-based_glioblastoma_tumour_detection_and_segmentation:latest \
  --series-list '[{"patient_id":"PAT001","study_id":"ST001","series_path":"/input/DICOM/..."}]' \
  --target total-fused \
  --keep-submodels false \
  --emit-config true
```

**Output Structure (with `--keep-submodels true`, default):**
```
/output/
└── {dataset}/{patient}/{study}/
    ├── 2302111_AI_model_alfasUnet_necrosis/
    │   └── {SOPInstanceUID}.SEG.dcm
    ├── 2302109_AI_model_alfasUnet_edema/
    │   └── {SOPInstanceUID}.SEG.dcm
    ├── 2302110_AI_model_alfasUnet_enhanced_tumor/
    │   └── {SOPInstanceUID}.SEG.dcm
    └── 2302108_AI_model_alfasUnet_total_tumor_fused/
        └── {SOPInstanceUID}.SEG.dcm
```

**Output Structure (with `--keep-submodels false`):**
```
/output/
└── {dataset}/{patient}/{study}/
    └── 2302108_AI_model_alfasUnet_total_tumor_fused/
        └── {SOPInstanceUID}.SEG.dcm
```

## Input Specification

**REQUIRED:** You must specify series information using ONE of the four methods below. The tool will NOT auto-discover or make assumptions about series types.

### Option 1: JSON Argument (no files needed)

```bash
docker run --rm --gpus all \
  -v /path/to/input:/input \
  -v /path/to/output:/output \
  harbor.eucaim.cancerimage.eu/processing-tools/mr-based_glioblastoma_tumour_detection_and_segmentation:latest \
  --series-list '[{"dataset_id":"DS001","patient_id":"PAT001","study_id":"ST001","series_path":"/input/DICOM/DS001/PAT001/ST001/T1_POST"}]' \
  --target total-fused \
  --emit-config true
```

Multiple series:
```bash
docker run --rm --gpus all \
  -v /path/to/input:/input \
  -v /path/to/output:/output \
  harbor.eucaim.cancerimage.eu/processing-tools/mr-based_glioblastoma_tumour_detection_and_segmentation:latest \
  --series-list '[{"dataset_id":"DS001","patient_id":"PAT001","study_id":"ST001","series_path":"/input/DICOM/DS001/PAT001/ST001/T1_POST"},{"dataset_id":"DS002","patient_id":"PAT002","study_id":"ST001","series_path":"/input/DICOM/DS002/PAT002/ST001/T2_FLAIR"}]' \
  --target necrosis \
  --emit-config true
```

**Note:** `series_path` must be the **full absolute path** inside the container. `dataset_id` is optional and informative only.

### Option 2: CSV File (Multi-Sequence Support)

Create `series_to_segment.csv` with `sequence_type` to enable multi-sequence processing:
```csv
dataset_id,patient_id,study_id,sequence_type,series_path
DS001,PAT001,STUDY001,T1ce,/input/DICOM/DS001/PAT001/STUDY001/T1_POST_CONTRAST
DS001,PAT001,STUDY001,T2w,/input/DICOM/DS001/PAT001/STUDY001/T2_WEIGHTED
DS001,PAT001,STUDY001,FLAIR,/input/DICOM/DS001/PAT001/STUDY001/T2_FLAIR
DS002,PAT002,STUDY001,T1ce,/input/DICOM/DS002/PAT002/STUDY001/T1_POST_CONTRAST
DS002,PAT002,STUDY001,FLAIR,/input/DICOM/DS002/PAT002/STUDY001/T2_FLAIR
```

Run:
```bash
docker run --rm --gpus all \
  -v /path/to/input:/input \
  -v /path/to/output:/output \
  harbor.eucaim.cancerimage.eu/processing-tools/mr-based_glioblastoma_tumour_detection_and_segmentation:latest \
  --series-selector /input/config/series.csv \
  --target total \
  --emit-config true
```

**Sequence Types:** `T1ce` (T1 post-contrast), `T2w` (T2-weighted), `FLAIR` (FLAIR)

**Multi-Sequence Behavior:**
- Series are grouped by `patient_id` + `study_id`
- For **necrosis/enhancing**: only `T1ce` required (1 channel)
- For **edema**: `T2w + FLAIR` required (2 channels, no T1ce)
- For **total**: `T1ce + T2w + FLAIR` required (3 channels)
- **Fallback:** For edema: T2w↔FLAIR mutual fallback; for total: T1ce mandatory, T2w↔FLAIR mutual fallback

**Note:** `series_path` must be the **full absolute path** inside the container. `dataset_id` is optional and informative only.

### Option 3: CSV via Arguments (fileless environments)

Use `--series-args` to pass rows inline when you cannot mount config files:

```bash
docker run --rm --gpus all \
  -v /path/to/input:/input \
  -v /path/to/output:/output \
  harbor.eucaim.cancerimage.eu/processing-tools/mr-based_glioblastoma_tumour_detection_and_segmentation:latest \
  --series-args "PAT001,STUDY001,T1ce,/input/DICOM/DS001/PAT001/STUDY001/T1_POST_CONTRAST" "PAT001,STUDY001,T2w,/input/DICOM/DS001/PAT001/STUDY001/T2_WEIGHTED" "PAT001,STUDY001,FLAIR,/input/DICOM/DS001/PAT001/STUDY001/T2_FLAIR" \
  --target total \
  --emit-config true
```

Accepted formats per arg:
- `dataset_id,patient_id,study_id,sequence_type,series_path` (5 fields)
- `patient_id,study_id,sequence_type,series_path` (4 fields, no dataset)

Tip: quote each arg to avoid shell splitting.

### Option 4: Auto-Discovery with Wildcard Patterns

Use wildcard patterns to automatically discover and label series by **folder name**. The tool expects users to organize series folders with consistent naming:

```bash
docker run --rm --gpus all \
  -v /path/to/input:/input \
  -v /path/to/output:/output \
  harbor.eucaim.cancerimage.eu/processing-tools/mr-based_glioblastoma_tumour_detection_and_segmentation:latest \
  --t1ce-pattern "*_T1_POST_*" \
  --t2w-pattern "*_T2_*" \
  --flair-pattern "*_FLAIR_*" \
  --target total \
  --emit-config true
```

**How it works:**
- Scans `/input/DICOM/[dataset]/[patient]/[study]/[series]` structure
- Matches series **folder names** against wildcard patterns (not SeriesDescription)
- If folder name matches `--t1ce-pattern` → labels as `T1ce`
- If folder name matches `--t2w-pattern` → labels as `T2w`
- If folder name matches `--flair-pattern` → labels as `FLAIR`
- Groups by patient+study and processes with fallback logic

**Example folder structure:**
```
/input/DICOM/
└── DS001/
    └── PAT001/
        └── STUDY001/
            ├── 001_T1_POST_GAD/     ← matches *_T1_POST_*
            ├── 002_T2_TSE/          ← matches *_T2_*
            └── 003_T2_FLAIR/        ← matches *_FLAIR_*
```

**Wildcard syntax:**
- `*` = matches any characters
- `?` = matches single character
- `*_T1_*` = matches "001_T1_POST", "AX_T1_GAD", etc.
- `*T1*POST*` = matches "T1_POST", "T1cePOST", etc.

**Case sensitivity:**
```bash
# Case-insensitive (default) - matches "t1_post", "T1_POST", "T1_Post"
--t1ce-pattern "*_t1_post_*" --match-case false

# Case-sensitive - only matches exact case
--t1ce-pattern "*_T1_POST_*" --match-case true
```

**Tip:** 
- You can specify 1, 2, or all 3 sequence types
- User responsibility: ensure folder names follow consistent patterns
- Alternative: use CSV/JSON to specify exact paths for each series

## Directory Structure

### Input (DICOM mode)
```
/input/DICOM/
└── [dataset_id]/
    └── [patient_id]/
        └── [study_id]/
            └── [series_id]/
                └── *.dcm
```

### Output
```
/output/
├── [dataset_id]/                    # Optional, if provided in input
│   └── [patient_id]/
│       └── [study_id]/
│           └── {series_number}_{series_description}/
│               └── {SOPInstanceUID}.SEG.dcm
├── processing_log.csv               # Processing status with target and models info
└── resolved_series_selection.csv   # Resolved input mapping (if --emit-config true)
```

**Notes:**
- For `total-fused` with `--keep-submodels true` (default): creates 4 separate series folders (necrosis, edema, enhancing, fused)
- For `total-fused` with `--keep-submodels false`: creates only 1 series folder (fused)
- For single targets (necrosis, edema, enhancing, total): creates 1 series folder
- SeriesNumber values: see [DICOM SEG Metadata](#dicom-seg-metadata) table

## Processing Logs

### Automatic Processing Log

Every run generates `/output/processing_log.csv` with columns:
- `dataset_id`, `patient_id`, `study_id`
- `sequences_available`: comma-separated list (e.g., "FLAIR,T1ce,T2w")
- `target`: segmentation target used (necrosis, edema, enhancing, total, total-fused)
- `models_segmented`: models executed (e.g., "necrosis+edema+enhancing→fused" for total-fused, or "necrosis" for single target)
- `status`: SUCCESS or FAILED
- `reason`: "Completed successfully" or error description

**Use this log to:**
- Quickly identify which patients were processed successfully
- See exactly which models/targets were segmented for each case
- Troubleshoot failed cases (missing T1ce, processing errors)
- Re-run only failed patients by filtering the log

### Terminal Summary Report

At the end of each run, a summary is printed:
```
Processing Summary
======================================================================
Total patient/study groups: 10
Successfully processed:     8
Failed/Skipped:             2
======================================================================

FAILED/SKIPPED CASES:
----------------------------------------------------------------------
  [DS002] PAT005/STUDY001
    Sequences: FLAIR,T2w
    Reason: T1ce sequence is required but not available. Cannot process this patient/study.

  [DS003] PAT007/STUDY001
    Sequences: T1ce,T2w
    Reason: Processing error: Invalid DICOM geometry
```

### Emit Resolved Config (Audit)

Write the final selection to a CSV in output for auditing or re-runs:

```bash
docker run --rm --gpus all \
  -v /path/to/input:/input \
  -v /path/to/output:/output \
  harbor.eucaim.cancerimage.eu/processing-tools/mr-based_glioblastoma_tumour_detection_and_segmentation:latest \
  --series-description-regex "(?i)T1.*CE" \
  --target necrosis \
  --emit-config true
```
The resolved selection CSV is always written to `/output/resolved_series_selection.csv`.

## Sequence Recommendations

### Input Channels per Target (Beser‑Robles et al., 2024)

| Target | Channels | Sequences | Fallback |
|--------|----------|-----------|----------|
| **Necrosis** | 1 | T1ce only | None |
| **Enhancing** | 1 | T1ce only | None |
| **Edema** | 2 | T2w + FLAIR | T2w↔FLAIR mutual |
| **Total** | 3 | T1ce + T2w + FLAIR | See rules below |

### Fallback Rules for Multi-Channel Models

**For Edema (2-channel model: T2w + FLAIR):**
1. **T2w (channel 1)**:
   - If T2w available → use T2w
   - If T2w missing but FLAIR available → use FLAIR
   - If both missing → **skip patient/study**
2. **FLAIR (channel 2)**:
   - If FLAIR available → use FLAIR
   - If FLAIR missing but T2w available → use T2w
   - If both missing → **skip patient/study**

**For Total (3-channel model: T1ce + T2w + FLAIR):**
1. **T1ce (channel 1)**: Always required. If missing → **skip patient/study**
2. **T2w (channel 2)**:
   - If T2w available → use T2w
   - If T2w missing but FLAIR available → use FLAIR
   - If both missing → use T1ce
3. **FLAIR (channel 3)**:
   - If FLAIR available → use FLAIR
   - If FLAIR missing but T2w available → use T2w
   - If both missing → use T1ce

**Example scenarios:**
- **Edema** - Available: T2w + FLAIR → [T2w, FLAIR]
- **Edema** - Available: FLAIR only → [FLAIR, FLAIR]
- **Edema** - Available: T2w only → [T2w, T2w]
- **Edema** - Available: T1ce + T2w (no FLAIR) → [T2w, T2w]
- **Edema** - Available: T1ce + FLAIR (no T2w) → [FLAIR, FLAIR]
- **Edema** - Available: T1ce only (no T2w/FLAIR) → Skipped
- **Total** - Available: T1ce + T2w + FLAIR → [T1ce, T2w, FLAIR]
- **Total** - Available: T1ce + FLAIR → [T1ce, FLAIR, FLAIR]
- **Total** - Available: T1ce + T2w → [T1ce, T2w, T2w]
- **Total** - Available: T1ce only → [T1ce, T1ce, T1ce]
- **Total** - Available: T2w + FLAIR (no T1ce) → Skipped

### Acquisition Guidelines

- Preferred acquisition plane: axial when available.
- If T1w‑ce is missing or severely artifacted, FLAIR/T2w‑based results (edema/total) may still be usable; expect reduced performance for enhancing/necrosis.
- Other sequences: non‑contrast T1 or T2 may be accepted, but performance can degrade; ensure full tumor coverage and minimal artifacts.

Notes:
- Ensure the field of view covers the entire tumor region.
- Verify spacing and orientation consistency within the series; mixed spacing can lead to poor geometry alignment.
- Avoid heavily motion-corrupted series.

## Image Registration

### Multi-Sequence Alignment (SimpleITK Rigid Registration)

When processing multi-sequence studies (2 or more sequences), the tool automatically registers all sequences to **T1ce as the anatomical reference**:

**Why T1ce as reference?**
- T1ce is the gold standard for brain tumor segmentation (high anatomical detail, contrast enhancement)
- Used for skull stripping (BET), which establishes the anatomical coordinate system
- All models were trained using T1ce as the primary reference sequence

**Registration process:**
1. **Skull stripping on T1ce only** → BET creates brain mask from T1ce
2. **Apply T1ce mask to other sequences** (after registration)
3. **Rigid registration**: T2w and FLAIR are registered to T1ce using SimpleITK
   - Transformation: Euler 3D rigid (rotation + translation, no scaling/shearing)
   - Similarity metric: Mattes Mutual Information
   - Optimization: Gradient Descent with physical shift scaling
   - Interpolation: Linear (B-spline for final resampling)
   - Multi-resolution: 3 levels (shrink factors 4, 2, 1)
4. **Post-registration**: All sequences now share identical geometry and coordinate system

**Multi-sequence behavior:**
- **2-channel input (Edema only)**: T2w + FLAIR registered to T1ce
- **3-channel input (Total)**: T2w + FLAIR registered to T1ce
- **Single-channel (Necrosis/Enhancing)**: T1ce only, no registration needed

**Notes on registration:**
- Registration failures (e.g., severe motion artifacts) are handled gracefully with fallback to original geometry
- Log messages indicate registration success/failure: `Registration complete` or `Registration failed, using original image`
- Ensure consistent acquisition parameters (spacing, FOV) across sequences to improve registration quality

## Troubleshooting

### Error: "MISSING SERIES SPECIFICATION"

**Problem:** You did not specify how to find or label series.

**Solution:** Use ONE of these methods to provide series information:

1. **Explicit JSON** – Pass series with full path and sequence type:
   ```bash
   --series-list '[{"patient_id":"PAT001","study_id":"ST001","series_path":"/input/DICOM/...","sequence_type":"T1ce"}]'
   ```

2. **CSV file** – Create a CSV with dataset_id, patient_id, study_id, sequence_type, series_path

3. **Inline arguments** – Use `--series-args` to pass CSV rows directly

4. **Wildcard patterns** – If series folders follow consistent naming (e.g., `*_T1_*`, `*_T2_*`, `*_FLAIR_*`):
   ```bash
   --t1ce-pattern "*_T1_POST_*" --t2w-pattern "*_T2_*" --flair-pattern "*_FLAIR_*"
   ```

**Important:** Patterns only work if series folder names are consistently labeled. If names are inconsistent or unlabeled, you MUST use explicit config (CSV, JSON, or args).

### Series Skipped with "T1ce sequence is required but not available"

**Problem:** A patient/study group is missing T1ce sequence.

**Why it matters:** T1ce is mandatory for skull stripping and all models (even edema uses it for reference registration).

**Solution:** 
- Ensure all series are provided in your config/args/CSV
- Use correct sequence type labels (T1ce, T2w, FLAIR)
- Check that T1ce series is actually in `/input/DICOM/` structure

### Registration Failed Warnings

**Problem:** Log shows `Registration failed, using original image`

**Cause:** SimpleITK registration did not converge (e.g., severe motion, geometry mismatch)

**Impact:** Tool continues with unregistered sequences; results may be less accurate

**Solution:**
- Verify all sequences have similar FOV and minimal motion artifacts
- Check acquisition spacing is consistent across sequences
- Re-acquire if possible, or accept reduced performance

## GPU Acceleration

```bash
# Use all GPUs (recommended if available)
docker run --rm --gpus all \
  -v /path/to/input:/input \
  -v /path/to/output:/output \
  harbor.eucaim.cancerimage.eu/processing-tools/mr-based_glioblastoma_tumour_detection_and_segmentation:latest \
  --target total-fused

# Specific GPU
docker run --rm --gpus '"device=0"' \
  -v /path/to/input:/input \
  -v /path/to/output:/output \
  harbor.eucaim.cancerimage.eu/processing-tools/mr-based_glioblastoma_tumour_detection_and_segmentation:latest \
  --target necrosis
```

## Key Arguments

| Argument | Description | Default |
|----------|-------------|---------||
| `--target` | Segmentation target | `total` |
| `--mode` | Processing mode (`dicom-seg` or `nifti-only`) | `dicom-seg` |
| `--input-root` | Input root directory | `/input` |
| `--output-root` | Output root directory | `/output` |
| `--series-list` | JSON string with series info | - |
| `--series-selector` | CSV file path | - |
| `--series-args` | Inline CSV rows | - |
| `--t1ce-pattern` | Wildcard for T1ce series folder names | - |
| `--t2w-pattern` | Wildcard for T2w series folder names | - |
| `--flair-pattern` | Wildcard for FLAIR series folder names | - |
| `--match-case` | Case sensitive pattern matching (`true`/`false`) | `false` |
| `--nifti-input-root` | Root for NIfTI input when `mode=nifti-only` | `/input/BBDD` |
| `--nifti-output-root` | Output root for NIfTI masks | `/output/BBDD_result` |
| `--bet-frac` | BET threshold (0-1) | `0.5` (recommended) |
| `--keep-intermediates` | Keep intermediate files | `false` |
| `--keep-submodels` | When using `total-fused`: export individual submodel DICOM SEGs (necrosis, edema, enhancing) in addition to fused result (`true`/`false`) | `true` |
| `--emit-config` | Write resolved config CSV (`true`/`false`) | `true` (writes `/output/resolved_series_selection.csv`) |
| `--seg-series-number` | Override DICOM SEG `SeriesNumber` | - |
| `--postprocess` | Apply morphology post-processing (closing + remove small objects + largest component) | `true` |

**Fixed defaults (not user-configurable):**
- Target size: `240 240 155`
- Patch size: `128 128 128`
- Patch step: `64`
- Model directory: `/models`
- DICOM SEG metadata: `seg_model_name=AI_model_alfasUnet_HULAFE`, `seg_algorithm_name=alfaSUNet_Glioblastoma_IIS`, `seg_content_creator=MR-based glioblastoma detection AI`, `seg_coordinating_center=HULAFE - IIS La Fe - GIBI230`, `seg_trial_id=alfaSUNet_glioblastoma_segmentation`

## Scientific Validation

This tool implements the approach described in:

Beser‑Robles, M., Castellá‑Malonda, J., Martínez‑Gironés, P.M., Galiana‑Bordera, A., Ferrer‑Lozano, J., Ribas‑Despuig, G., Teruel‑Coll, R., Cerdá‑Alberich, L., Martí‑Bonmatí, L. (2024). Deep learning automatic semantic segmentation of glioblastoma multiforme regions on multimodal magnetic resonance images. International Journal of Computer Assisted Radiology and Surgery. https://doi.org/10.1007/s11548-024-03205-z

- Architecture: 3D U‑Net with residual blocks (alfaSUNet), subregion‑specific models merged into a unified mask.
- Sequences per subregion: T1w‑ce for enhancing and necrosis; T1w‑ce + T2w + FLAIR for edema and total tumor.
- Datasets:
  - BraTS2021 (open): 1,251 cases; split: train 800, val 200, internal test 251.
  - In‑house PerProGlio: 50 Glioblastoma patients (pre‑treatment, 24–72 h pre‑surgery), GE 1.5T/3T; manually segmented by experts.
- Metrics reported (mean ± SD): Dice, Precision, Sensitivity.
- Limitations noted: lower performance on necrotic core; in‑house cohort slightly lower than internal test given heterogeneity and size.

## Datasets

- Training & internal validation: BraTS2021 (public, preoperative Glioblastoma/LGG): 1,251 cases; manual multi‑expert labels; used for training/validation/internal testing (train 800, val 200, test 251).
- External Validation: PerProGlio dataset at La Fe Hospital with 50 Glioblastoma patients, pre‑treatment MR; inclusion: surgery candidates, MR 24–72 h prior to surgery; sequences: T1w‑ce, T2w, FLAIR; 1.5T/3T; expert manual segmentation.

## Metrics

Reported performance (mean Dice ± SD) per subregion:

| Cohort | Necrosis | Enhancing | Edema | Total |
|--------|----------|-----------|-------|-------|
| Training | 0.90 ± 0.26 | 0.90 ± 0.20 | 0.88 ± 0.20 | 0.92 ± 0.05 |
| Validation | 0.79 ± 0.35 | 0.81 ± 0.23 | 0.71 ± 0.21 | 0.77 ± 0.10 |
| Internal test | 0.60 ± 0.40 | 0.79 ± 0.27 | 0.75 ± 0.23 | 0.89 ± 0.13 |
| In‑house test | 0.59 ± 0.37 | 0.71 ± 0.28 | 0.64 ± 0.29 | 0.75 ± 0.22 |

Precision (mean ± SD):

| Cohort | Necrosis | Enhancing | Edema | Total |
|--------|----------|-----------|-------|-------|
| Training | 0.93 ± 0.15 | 0.93 ± 0.10 | 0.92 ± 0.13 | 0.96 ± 0.03 |
| Validation | 0.92 ± 0.20 | 0.89 ± 0.13 | 0.86 ± 0.19 | 0.95 ± 0.04 |
| Internal test | 0.79 ± 0.27 | 0.86 ± 0.22 | 0.76 ± 0.25 | 0.94 ± 0.07 |
| In‑house test | 0.69 ± 0.26 | 0.79 ± 0.22 | 0.69 ± 0.30 | 0.79 ± 0.20 |

Sensitivity (mean ± SD):

| Cohort | Necrosis | Enhancing | Edema | Total |
|--------|----------|-----------|-------|-------|
| Training | 0.90 ± 0.27 | 0.93 ± 0.27 | 0.91 ± 0.27 | 0.95 ± 0.27 |
| Validation | 0.79 ± 0.27 | 0.92 ± 0.27 | 0.87 ± 0.27 | 0.90 ± 0.27 |
| Internal test | 0.60 ± 0.40 | 0.78 ± 0.28 | 0.79 ± 0.22 | 0.88 ± 0.16 |
| In‑house test | 0.59 ± 0.37 | 0.71 ± 0.28 | 0.64 ± 0.30 | 0.75 ± 0.23 |

## Model Files Required

Place in `models/` directory before building:
- `necrosis_3D_unet3d_best_model.h5`
- `edema_3D_unet3d_best_model.h5`
- `enhancing_3D_unet3d_best_model.h5`
- `total_3D_unet3d_best_model.h5`

## Processing Pipeline

1. DICOM → NIfTI conversion (dcm2niix)
2. Skull stripping (FSL BET) - **run only on T1ce**
3. **Image Registration (SimpleITK)** - register all other sequences to T1ce reference
   - T1ce is the fixed (reference) image (used for BET and anatomical alignment)
   - T2w and FLAIR are registered to T1ce using rigid transformation with Mutual Information
   - All sequences now share the same geometry and coordinate system
4. Resize to 240×240×155
5. Z-score normalization
6. Patchify (128×128×128 patches, step=64, overlapping) - **per-channel separately**
7. Model inference (TensorFlow/Keras)
8. Merge overlapping patches by averaging
9. Morphology post-process (closing, small-object removal, keep largest component)
10. Rescale to original size
11. Resample to DICOM geometry
12. Export DICOM SEG (dcmqi)

### BET skull-stripping guidance

- Purpose: `--bet-frac` controls skull stripping on T1ce; higher values remove more skull/soft tissue.
- Recommended: keep the default `--bet-frac 0.5` for general use.
- If the tumor mask looks cropped because the tumor touches the skull, rerun lowering BET to `--bet-frac 0.3`; in extreme cases go down to `--bet-frac 0.25`, which usually fixes tight cases.

## DICOM SEG Metadata

| Target | Code | RGB | SeriesNumber |
|--------|------|-----|--------------|
| Total (single model) | CLIN1000143 | [255,0,0] | 2302107 |
| Total (fused) | CLIN1000143 | [255,0,0] | 2302108 |
| Edema | CLIN1051008 | [140,224,228] | 2302109 |
| Enhanced | IMG1016513 | [255,165,0] | 2302110 |
| Necrosis | CLIN1051010 | [216,191,216] | 2302111 |

## Execution Traceability & Replicability

Every execution generates metadata files for full traceability and replication of results.

### Output Metadata Files

1. **execution_config.json** 
   - Records all parameters used and their status (default/personalized)
   - Execution timestamp and script version (from VERSION file)
   - Complete preprocessing and DICOM SEG configuration

2. **processing_log.csv**
   - Processing results for each patient/study
   - Header comments with non-default parameters and timestamp
   - Can identify which settings were customized

3. **resolved_series_selection.csv**
   - Full paths to series that were processed
   - Can be re-used as input to `--series-selector` for reproducibility

### Configurable Parameters with Defaults

| Parameter | Default | Purpose |
|-----------|---------|---------|
| `--bet-frac` | 0.5 | Brain extraction threshold (0-1) |
| `--postprocess` | true | Apply morphological post-processing |
| `--keep-submodels` | true | Export individual models in total-fused mode |
| `--keep-intermediates` | false | Keep intermediate NIfTI files |
| `--emit-config` | true | Write metadata files |

### Example: Reproduce a Previous Run

```bash
docker run --rm --gpus all \
  -v /path/to/input:/input \
  -v /path/to/new_output:/output \
  harbor.eucaim.cancerimage.eu/processing-tools/mr-based_glioblastoma_tumour_detection_and_segmentation:latest \
  --series-selector /path/to/previous_output/resolved_series_selection.csv \
  --target total-fused
```

The CSV output will show which parameters differ from defaults with a `[personalized]` marker.

## Requirements

- Docker 20.10+
- NVIDIA Docker (for GPU support)
- 8GB+ RAM (16GB recommended)

## Contact

**Maintainer-Developers**: pedromiguel_martinez@iislafe.es; maria_beser@iislafe.es; carina_soler@iislafe.es; adrian_galiana@iislafe.es; gibi230@iislafe.es; luis_marti@iislafe.es
**Institution**: HULAFE (IIS La Fe - GIBI230)

## Acknowledgements & Citation

This tool was developed for glioblastoma tumour detection and segmentation within the EUCAIM project context. It is designed to work within federated imaging infrastructures and produce DICOM SEG objects suitable for training and evaluation workflows.

If you use this tool, please cite:

- Beser‑Robles, M., Castellá‑Malonda, J., Martínez‑Gironés, P.M., Galiana‑Bordera, A., Ferrer‑Lozano, J., Ribas‑Despuig, G., Teruel‑Coll, R., Cerdá‑Alberich, L., Martí‑Bonmatí, L. (2024). Deep learning automatic semantic segmentation of glioblastoma multiforme regions on multimodal magnetic resonance images. International Journal of Computer Assisted Radiology and Surgery. https://doi.org/10.1007/s11548-024-03205-z

Frameworks/libraries:
- dcmqi toolkit: https://github.com/QIICR/dcmqi
- SimpleITK: https://simpleitk.org/

# **MR-based Neuroblastoma Tumour Detection and Segmentation**

This tool is specifically designed and validated for automated detection and segmentation of neuroblastic tumours in **T2-weighted magnetic resonance images (T2-MR)** using deep learning. Only T2 sequences are supported and recommended, as per the multicentric validation in [Veiga-Canuto et al., Cancers 2023]. It processes DICOM or NIfTI input data and outputs DICOM Segmentation objects (DICOM SEG) suitable for federated learning and AI model training in the EUCAIM project.

**Technical Framework:** Built on the nnU-Net self-configuring framework (Isensee et al., 2021) with a model trained and validated specifically for neuroblastoma tumour segmentation (Task004_Neuroblastoma) in T2-MR images, within the PRIMAGE project context and as described in [Veiga-Canuto et al., Cancers 2023].
## Sequence Requirements

**Important:** This tool is only validated for **T2-weighted MR sequences**. Do not use with other MR sequences (T1, FLAIR, etc.), as performance and reliability are not guaranteed. See the referenced publication for details on inclusion criteria and multicentric validation.

## Image Requirements

The following criteria were used in the multicentric validation study:

- **Sequence type:** T2-weighted MR only
- **Field of view (FOV):** Must include the entire tumor
- **Magnetic field strength:** 1.5T or 3T
- **Slice thickness:** 3–5 mm
- **Pixel spacing:** 0.5–1.5 mm
- **Acquisition plane:** Axial preferred; coronal/sagittal accepted if tumor is fully covered
- **Tumor location:** Abdomen, thorax, neck, pelvis (as per study cohort)

Images not meeting these criteria (e.g., other sequences, incomplete coverage, severe artifacts) were excluded from validation.

## Scientific Validation

This tool and its underlying model were validated in a multicentric study:

> Veiga-Canuto D., Cerdá-Alberich L., Jiménez-Pastor A., Carot Sierra J.M., Gomis-Maya A., Sangüesa-Nebot C., Fernández-Patón M., Martínez de las Heras B., Taschner-Mandl S., Düster V., Pötschger U., Simon T., Neri E., Alberich-Bayarri A., Cañete A., Hero B., Ladenstein R., Martí-Bonmatí L. (2023). Independent Validation of a Deep Learning nnU-Net Tool for Neuroblastoma Detection and Segmentation in MR Images. *Cancers* 15(5):1622. https://doi.org/10.3390/cancers15051622

- **Population:** 151 patients, 7 European centers, exclusively T2-weighted MR images.
- **Validation:** Multicentric, independent, comparing manual and automatic segmentation.
- **Results:** High agreement between nnU-Net and expert manual segmentations (Dice coefficient, Hausdorff distance, etc.).
- **Limitations:** Only T2-MR sequences; not validated for other modalities or tumor types.
- **Recommendation:** Cite this article when using the tool in research or clinical workflows.


The main functionalities are:

- **DICOM to DICOM SEG workflow**: Converts DICOM series to NIfTI, runs nnU-Net inference, and exports results as DICOM Segmentation objects.
- **NIfTI-only mode**: Direct processing of NIfTI images for research workflows.
- **Automatic geometry alignment**: Resamples predicted masks to match reference DICOM geometry using SimpleITK.
- **Flexible series selection**: Target specific series via CSV or SeriesDescription regex filters.
- **Configurable metadata**: All DICOM SEG metadata (SeriesNumber, algorithm name, creator, etc.) configurable via CLI flags.
- **Temporary file cleanup**: Optional retention of intermediate NIfTI files for debugging.

Optional functionalities are:

- Custom segment configuration via JSON files.
- Support for nested patient/study/series DICOM structures and flat layouts.
- Parallel processing capabilities (inherited from nnU-Net).

## Configuration File Handling

- Series selection can be provided via CSV (`series_to_segment.csv`) with columns: `dataset_id,patient_id,study_id,series_relpath`.
- Segment metadata can be customized via `segments_info.json` (default provided for neuroblastoma).
- All DICOM SEG metadata fields are configurable via command-line flags.

**Example segment configuration:**
```json
{
  "SEGMENTS": {
    "neuroblastoma_tumor": {
      "series_number": 2302001,
      "rgb": [255, 0, 0],
      "desc": "Neuroblastoma primary tumor region detected and segmented from MR imaging",
      "code_value": "CLIN1049513",
      "segment_label": "Neuroblastoma Tumor"
    }
  }
}
```

## **Installation**

### For EUCAIM Users:

1. Make sure you have Docker installed (version 25 or higher).  
2. Log in to the EUCAIM Harbor registry using your user credentials (retrieved from your user profile in the registry):

    ```bash
    docker login harbor.eucaim.cancerimage.eu -u <your_user> -p <your_token>
    ```

3. Pull the prebuilt Docker image from the EUCAIM registry:

    ```bash
    docker pull harbor.eucaim.cancerimage.eu/processing-tools/mr_based_neuroblastoma_tumour_detection_and_segmentation:2.0.0
    ```

4. Run the Docker container as explained in the **Usage** section below.

  **Note:** You do **not** need to build the Docker image locally. The image is already available and ready to use from the EUCAIM Harbor registry.

## Folder Structure Overview

This is the expected folder structure for running the MR-based Neuroblastoma Detection tool:

```
input_folder/
├── DICOM/                           # DICOM dataset root (for DICOM mode)
│   └── [dataset_id]/[patient]/[study]/[series]/*.dcm
├── BBDD/                            # NIfTI dataset root (for NIfTI-only mode)
│   └── [patient]/[study]/*_0000.nii.gz
└── config/                          # Optional configuration files
    ├── series_to_segment.csv        # Series selection for DICOM mode
    └── segments_info.json           # Custom segment metadata

output_folder/
├── DICOM_SEG/                       # DICOM Segmentation objects (DICOM mode)
│   └── [patient]/[study]/[series]/seg.dcm
└── BBDD_result/                     # NIfTI masks (if --keep-nifti true)
    └── [patient]/[study]/*.nii.gz
```

#### Notes:
- **DICOM mode**: Requires proper DICOM series structure. Use `--series-selector` CSV to target specific series.
- **NIfTI mode**: Input files must end with `_0000.nii.gz` (nnU-Net single-channel convention).
- The tool automatically creates output directory structure mirroring input organization.

---

## **Usage**

### DICOM to DICOM SEG (Recommended)

1. Prepare your DICOM dataset in `/input`
2. Create a series selector CSV at `/input/config/series_to_segment.csv`:
   ```csv
   dataset_id,patient_id,study_id,series_relpath
   dataset123,pat001,study001,DICOM/dataset123/pat001/study001/series05
   ```
3. Set up output folder
4. Run the container:

    ```bash
    docker run --rm \
      -v "<input_path>:/input" \
      -v "<output_path>:/output" \
      --gpus all \
      harbor.eucaim.cancerimage.eu/processing-tools/mr_based_neuroblastoma_tumour_detection_and_segmentation:2.0.0 \
      --mode dicom-seg \
      --series-selector /input/config/series_to_segment.csv \
      --seg-series-number 2302001 \
      --seg-algorithm-name "nnUNet_Neuroblastoma_Primage_training" \
      --seg-coordinating-center "EUCAIM Consortium" \
      --keep-nifti false
    ```

### NIfTI-only Mode

```bash
docker run --rm \
  -v "<input_path>:/input" \
  -v "<output_path>:/output" \
  --gpus all \
  harbor.eucaim.cancerimage.eu/processing-tools/mr_based_neuroblastoma_tumour_detection_and_segmentation:2.0.0 \
  --mode nifti-only \
  --nifti-input-root /input/BBDD \
  --nifti-output-root /output/BBDD_result \
  --keep-nifti true
```

## GPU Acceleration (Optional)

- The image supports NVIDIA GPUs via CUDA (PyTorch runtime). Using a GPU significantly speeds up inference but is optional.
- Requirements: NVIDIA drivers and NVIDIA Container Toolkit installed on the host.

Examples:

```bash
# Use all available GPUs
docker run --rm \
  --gpus all \
  -v "<input_path>:/input" \
  -v "<output_path>:/output" \
  harbor.eucaim.cancerimage.eu/processing-tools/mr_based_neuroblastoma_tumour_detection_and_segmentation:2.0.0 \
  --mode dicom-seg \
  --series-selector /input/config/series_to_segment.csv \
  --keep-nifti false

# Use specific GPU(s), e.g., GPU 0 only
docker run --rm \
  --gpus '"device=0"' \
  -v "<input_path>:/input" \
  -v "<output_path>:/output" \
  harbor.eucaim.cancerimage.eu/processing-tools/mr_based_neuroblastoma_tumour_detection_and_segmentation:2.0.0 \
  --mode dicom-seg \
  --series-selector /input/config/series_to_segment.csv \
  --keep-nifti false
```

If no GPU is available or `--gpus` is omitted, inference runs on CPU (slower).

### **Command-Line Arguments Reference**

#### General Parameters:
- `--mode`: Processing mode. Options: `dicom-seg` (default) | `nifti-only`
- `--series-selector`: Path to CSV listing target series (DICOM mode). Columns: `dataset_id,patient_id,study_id,series_relpath`
- `--series-description-regex`: Regex filter for SeriesDescription (alternative to CSV)
- `--keep-nifti`: Retain intermediate NIfTI files. Options: `true` | `false` (default)
- `--keep-intermediates`: Keep all intermediate artifacts (NIfTI conversions, predicted masks, resampled masks, JSON metadata). Options: `true` | `false` (default: intermediates are deleted). Note: runtime cache `nnunet_models_cache` is always deleted.
- `--segments-config`: Path to custom segment metadata JSON (optional)

#### NIfTI Mode Parameters:
- `--nifti-input-root`: Input directory for NIfTI files (default: `/input/BBDD`)
- `--nifti-output-root`: Output directory for masks (default: `/output/BBDD_result`)

#### DICOM SEG Metadata Configuration:
- `--seg-series-number`: SeriesNumber for output DICOM SEG (default: 2302001)
- `--seg-algorithm-name`: SegmentAlgorithmName (default: `nnUNet_Neuroblastoma_Primage_training`)
- `--seg-content-creator`: ContentCreatorName (default: `MR-based neuroblastoma detection AI`)
- `--seg-coordinating-center`: ClinicalTrialCoordinatingCenterName (default: `Unknown`)
- `--seg-trial-id`: ClinicalTrialSeriesID (default: `nnUNet_neuroblastoma_segmentation`)

### **Complete Example with Custom Metadata**

```bash
docker run --rm \
  -v "<input_path>:/input" \
  -v "<output_path>:/output" \
  harbor.eucaim.cancerimage.eu/processing-tools/mr_based_neuroblastoma_tumour_detection_and_segmentation:2.0.0 \
  --mode dicom-seg \
  --series-selector /input/config/series_to_segment.csv \
  --seg-series-number 2302001 \
  --seg-algorithm-name "nnUNet_Neuroblastoma_Primage_training" \
  --seg-content-creator "Hospital XYZ AI Lab" \
  --seg-coordinating-center "EUCAIM Consortium" \
  --seg-trial-id "EUCAIM_Neuroblastoma_Study" \
  --keep-nifti false
```

---

## **Functionality**

### DICOM to DICOM SEG Workflow

The tool performs the following steps for DICOM input:

1. **Series Selection** → Reads target series from CSV or applies SeriesDescription regex filter
2. **DICOM → NIfTI Conversion** → Uses dcm2niix for robust conversion with proper orientation/spacing preservation
3. **nnU-Net Inference** → Runs Task004_Neuroblastoma model (3d_fullres, nnUNetPlansv2.1)
4. **Metadata Extraction** → Extracts SeriesInstanceUID, SeriesNumber, and SOP UIDs from reference DICOM
5. **Geometry Alignment** → Resamples predicted mask to match reference DICOM grid using SimpleITK nearest-neighbor interpolation
6. **JSON Generation** → Creates dcmqi-compatible metadata JSON with segment attributes and references
7. **DICOM SEG Export** → Uses dcmqi (itkimage2segimage) to generate DICOM Segmentation object
8. **Cleanup** → Removes temporary files if `--keep-nifti false`

### NIfTI-only Workflow

For NIfTI input (research mode):

1. **File Discovery** → Scans input root for `*_0000.nii.gz` files organized by patient/study
2. **nnU-Net Inference** → Processes each study folder
3. **Output** → Writes segmentation masks to mirrored output structure

**Notes**:
- nnU-Net requires single-channel input with `_0000` suffix
- DICOM SEG mode always runs geometry alignment to ensure pixel-perfect correspondence
- All DICOM metadata is preserved and enriched with segmentation provenance

---

## **Acknowledgements & Citation**

This tool was developed for neuroblastoma tumour detection and segmentation in the EUCAIM project context. It is designed to work within federated learning infrastructures and imaging data federations.

**Framework Citation:**
This project builds on `nnU-Net` for model inference. If you use this tool or its Docker image in academic work, please cite:

- Isensee, F., Jaeger, P.F., Kohl, S.A.A., Petersen, J., Maier-Hein, K.H. (2021). nnU-Net: a self-configuring method for deep learning-based biomedical image segmentation. *Nature Methods* 18, 203–211. https://doi.org/10.1038/s41592-020-01008-z
- Preprint: Isensee, F. et al. Automated Design of Deep Learning Methods for Biomedical Image Segmentation. arXiv:1904.08128

**Model Training & Validation:**
The neuroblastoma segmentation model (Task004_Neuroblastoma) was trained and validated within the PRIMAGE project framework. If you use this segmentation model, please also cite:

- Veiga-Canuto D., Cerdá-Alberich L., Sangüesa Nebot C., Martínez de las Heras B., Pötschger U., Gabelloni M., Carot Sierra J.M., Taschner-Mandl S., Düster V., Cañete A., Ladenstein R., Neri E., Martí-Bonmatí L. (2022). Comparative Multicentric Evaluation of Inter-Observer Variability in Manual and Automatic Segmentation of Neuroblastic Tumors in Magnetic Resonance Images. *Cancers* 14(15):3648. https://doi.org/10.3390/cancers14153648

- Veiga-Canuto D., Cerdá-Alberich L., Jiménez-Pastor A., Carot Sierra J.M., Gomis-Maya A., Sangüesa-Nebot C., Fernández-Patón M., Martínez de las Heras B., Taschner-Mandl S., Düster V., Pötschger U., Simon T., Neri E., Alberich-Bayarri A., Cañete A., Hero B., Ladenstein R., Martí-Bonmatí L. (2023). Independent Validation of a Deep Learning nnU-Net Tool for Neuroblastoma Detection and Segmentation in MR Images. *Cancers* 15(5):1622. https://doi.org/10.3390/cancers15051622

**Training and Validation Cohorts:**

*Initial Development (Veiga-Canuto et al., 2022):*
- **Training set**: 106 patients with 5-fold cross-validation (median DSC: 0.965 ± 0.018 IQR)
- **Internal validation**: 26 independent patients (median DSC: 0.918 ± 0.067 IQR)
- Sources: La Fe Hospital (Spain), SIOPEN HR-NBL1 and LINES trials, St. Anna Children's Cancer Research Institute (Austria), Pisa University Hospital (Italy)
- Mean age: 37.6 ± 39.3 months
- Median tumor volume: 116,518 mm³

*External Validation (Veiga-Canuto et al., 2023):*
- **External validation cohort**: 300 patients (535 T2-weighted MR sequences) - completely independent dataset
  - 486 sequences at diagnosis
  - 49 sequences post-chemotherapy
- **Performance**: Median DSC 0.997 (0.944-1.000), successful detection in 94% of cases
- Sources: 12 European countries (HR-NBL1/SIOPEN: 119 patients, LINES/SIOPEN: 107 patients, German Neuroblastoma Registry: 62 patients, others: 12 patients)
- Mean age: 18 ± 32 months
- Heterogeneous acquisition: 1.5T (435), 3T (100); vendors: Siemens (318), Philips (109), GE (105), Canon (3)

**Important for Users:**
**Do not use this tool on data from the training/internal validation cohorts** (132 patients from 2002-2021 collected at La Fe, Austria SIOPEN centers, and Pisa). The model should only be applied to **new, unseen neuroblastoma cases** to ensure unbiased performance evaluation. The external validation demonstrated excellent generalization to new patients from diverse institutions and acquisition protocols.

**Developers:**
Leonor Cerdá Alberich, Diana Veiga Canuto, Matías Fernández Patón, Pedro Miguel Martínez-Gironés (adaptation to DICOM inputs and DICOM SEG outputs)
**GIBI230 Research Group**
**La Fe Health Research Institute (IIS La Fe)**
Valencia, Spain

---

## **License**

This software is provided under a limited-use license for academic and research purposes within the EUCAIM project.

**Key restrictions**:
- Use is permitted exclusively for EUCAIM project activities and related European public research infrastructures.
- Commercial use, redistribution, or integration into products/services requires prior written authorization.
- Attribution to IIS La Fe and the GIBI230 Research Group must be preserved.
- `nnU-Net` is licensed under Apache License 2.0 by the authors at DKFZ. When redistributing images containing `nnU-Net` and/or its pretrained weights, keep their license terms. See: https://github.com/MIC-DKFZ/nnUNet

**Disclaimer**:
- The software is provided "as-is" without warranty of any kind.
- The developers assume no responsibility for data handling, configuration errors, or results obtained.
- Users are responsible for ensuring compliance with applicable data protection and ethics regulations.

For full license terms, see `LICENSE` file. For permissions or questions, contact: **gibi230@iislafe.es**

**Contact**: https://www.iislafe.es/en/ | https://www.acim.lafe.san.gva.es/acim | https://cancerimage.eu/

# **ML model for MR series categorisation**

This is a Python-based machine learning tool that automatically categorizes DICOM series from MRI studies. It combines header-based pattern matching with trained ML models to generate standardized tags for sequence type, weighting, orientation, fat suppression, and quality flags (junk, derived, analysis series).

The tool reads DICOM files (`.dcm`) from an input directory, extracts relevant metadata, applies categorization logic, and outputs a structured JSON file with results and summary statistics.

## Main Functionalities

- **Automatic DICOM header extraction** using `pydicom` library
- **Pattern-based classification** for derived, analysis, and junk series
- **ML-powered categorization** using three trained CatBoost models:
  - Main sequence weighting classifier (T1W, T2W, STIR, etc.)
  - Junk detector
  - Chemical shift detector
- **Post-processing rules** to standardize output (e.g., GR + T2W → T2*W)
- **Orientation detection** (Coronal, Sagittal, Transversal/Axial)
- **Fat suppression identification** (FS, FAT, Chemical Shift)
- **Structured JSON output** with per-series results and summary statistics

## Execution

Run the tool with Docker by mounting input/output folders. Use the processing-tools image:

```bash
docker run -it --rm --name my-container \
  -v "<input_path>:/input" \
  -v "<output_path>:/output" \
  harbor.eucaim.cancerimage.eu/processing-tools/ml_model_for_mr_series_categorisation:<version> \
  --config-string "{'output_name': 'results.json'}"
```
Please pass the entrypoint and configuration as shown above.

## 📁 Folder Structure Overview

This is the expected folder structure for running the ML Series Classifier:

```
input_folder/
└── /input/                           # Input DICOM files (can be any structure)
    └── [flexible structure]          # Can include nested patient/study/series/.dcm or flat layout

output_folder/
└── /output/
    └── results.json                  # Generated classification results (or custom name via config)
```

#### Notes:
- The **`/input/` folder can have any internal structure**, including mixed, nested, or flat layouts
- DICOM files must have `.dcm` or `.DCM` extension
- The tool automatically organizes findings by StudyInstanceUID and SeriesInstanceUID
- **Output JSON** contains structured results with categorization per series and summary statistics

## **Usage**

1. Set up a folder where your input DICOM data is located **(<input_path>)**
2. Set up a folder where you want to save the output JSON results **(<output_path>)**
3. (Optional) Provide configuration via `--config-string` parameter:
   - `output_name`: Custom name for the output JSON file (default: `results.json`)

4. Run the Docker container with the appropriate image depending on your execution environment (see sections above)

### **Optional Configuration Parameters**

When using `--config-string`, you can provide a Python dictionary string (use single quotes for keys/values):

- `output_name`: (optional) Custom filename for the output JSON. Default: `results.json`. (string)

Example:
```bash
--config-string "{'output_name': 'my_classification_results.json'}"
```

## **Output JSON Format**

The tool generates a structured JSON file with the following format:

```json
{
  "tool": "ml-series-classifier",
  "version": "1.1.0",
  "timestamp": "2025-11-26T10:30:00Z",
  "input_path": "/input",
  "results": [
    {
      "study_id": "1.2.840.113619.2.55.3...",
      "series_id": "1.2.840.113619.2.55.3.12...",
      "series_description": "T2 FLAIR AX",
      "file_path": "/input/patient001/study123/series456",
      "tags": ["Transversal", "SE - IR / STIR / FS"],
      "categorization": {
        "sequence": "SE - IR",
        "weighting": "STIR",
        "suppression": "FS",
        "orientation": "Transversal",
        "is_junk": false,
        "is_derived": false,
        "is_analysis": false
      }
    }
  ],
  "summary": {
    "total_series": 45,
    "categorized": 42,
    "junk": 3,
    "derived": 2,
    "analysis": 1
  }
}
```

### Output Fields Description

- **results**: Array of series-level classifications
  - `study_id`: DICOM StudyInstanceUID
  - `series_id`: DICOM SeriesInstanceUID
  - `series_description`: Original series description from DICOM
  - `file_path`: Full path to the directory containing the series DICOM files
  - `tags`: List of assigned tags (orientation, combined sequence info)
  - `categorization`: Detailed breakdown
    - `sequence`: Scanning sequence (SE, GR, IR, EP, RM or combinations)
    - `weighting`: Image weighting (T1W, T2W, T2*W, STIR, FLAIR, etc.)
    - `suppression`: Fat suppression type (FS, FAT, Chs if chemical shift)
    - `orientation`: Image plane (Coronal, Sagittal, Transversal)
    - `is_junk`: Boolean flag for screen saves and acquisition artifacts
    - `is_derived`: Boolean flag for secondary/derived images (ADC maps, etc.)
    - `is_analysis`: Boolean flag for post-processed analysis series

- **summary**: Overall statistics
  - `total_series`: Total number of series processed
  - `categorized`: Number of series successfully categorized
  - `junk`: Count of junk series detected
  - `derived`: Count of derived series
  - `analysis`: Count of analysis series

## **Architecture and ML Models**

### Internal Processing Pipeline

1. **DICOM Header Extraction**: Scans input directory recursively for `.dcm` files, reads metadata with `pydicom`
2. **Pattern Matching**: Rule-based classification for derived, analysis, and junk series
3. **Preprocessing**: Feature engineering from DICOM tags (44+ features extracted)
4. **ML Inference**: Three CatBoost models predict:
   - Main categorization (sequence weighting)
   - Junk detection
   - Chemical shift detection
5. **Post-processing**: Business rules refine outputs (e.g., GR+T2W→T2*W, IR→SE-IR for STIR)
6. **Tag Generation**: Structured tags combining orientation, sequence, weighting, and suppression

### Pre-trained Models

Located in `inference_lib/models/`:
- `dicom_categorization_model.pickle`: Main weighting classifier
- `dicom_junk_model.pickle`: Junk series detector
- `dicom_chs_model.pickle`: Chemical shift detector

Each model pickle contains:
- `model`: Trained CatBoost estimator
- `features`: List of required input features
- `encoders`: LabelEncoders for categorical features and target classes

### Key Dependencies

- **pydicom**: DICOM file reading
- **pandas / numpy**: Data manipulation
- **scikit-learn**: Preprocessing and encoding
- **catboost**: ML models
- **joblib**: Model serialization
- **tqdm**: Progress tracking

## **Acknowledgements**

This tool was developed at IIS La Fe (GIBI230-IISLAFE), Valencia, Spain, as part of the PRIMAGE project. It implements the methodology and models described in the published research paper:

**Gomis-Maya A. et al.** "A pragmatic approach to harmonize MRI sequence categories across heterogeneous datasets for federated analytics." *Journal of Big Data*. 2025. DOI: 10.1186/s40537-025-01086-w.

This work addresses the challenge of harmonizing heterogeneous MRI sequences across multiple institutions for analytics, combining pattern matching with machine learning models trained on multi-institutional datasets.

## **Legal Information**

| Software Registry           | Details                      |
|-----------------------------|------------------------------|
| **Tool Name**               | ML model for MR series categorisation         |
| **Version**                 | 1.1.0                        |
| **License**                 | CC-BY-NC-ND-4.0            |
| **Authors**                 | Armando Gomis-Maya, Leonor Cerdá-Alberich, Diana Veiga-Canuto, Matias Fernandez & Luis Marti-Bonmati                |
| **Institution**             | Biomedical Imaging Research Group GIBI230 at La Fe Health Research Institute (GIBI230-IISLAFE)      |
| **Contact**                 | gibi230@iislafe.es |
| **EUCAIM Project**          | This tool is part of the European Cancer Image Platform (EUCAIM) |

### Citation

If you use this tool in your research, please cite:

Gomis-Maya A. et al. "A pragmatic approach to harmonize MRI sequence categories across heterogeneous datasets for federated analytics." Journal of Big Data. 2025. DOI: 10.1186/s40537-025-01086-w. Available at: https://link.springer.com/article/10.1186/s40537-025-01086-w

### Disclaimer

This tool is provided "as is" for research and validation purposes within the EUCAIM project. Results should be reviewed by qualified personnel before clinical use.

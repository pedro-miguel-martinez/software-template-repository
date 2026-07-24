# **DIGITAL MAMMOGRAPHY DICOM PREPROCESSING**

This is a Python tool that performs preprocessing and quality enhancement on DICOM digital mammography images. It applies configurable image processing pipelines including denoising, contrast enhancement (CLAHE), and normalization.

The output is a processed dataset of DICOM files maintaining the original structure and metadata, with enhanced image quality suitable for federated learning and AI model training in the EUCAIM project.

The main functionalities are:

- Selection and processing of **2D digital mammography (MG) DICOM files only**.
- **Z-score normalization** with percentile-based clipping to standardize intensity ranges.
- **Multiple denoising methods**: adaptive median, gaussian blur, anisotropic diffusion, wavelet denoising, and cascade (unsharp mask + gaussian).
- **CLAHE (Contrast Limited Adaptive Histogram Equalization)** for contrast enhancement.
- **Parallel processing** by patient folders for large datasets.
- **DICOM integrity preservation**: maintains original metadata, applies proper Modality LUT, and saves with correct pixel encoding.
- **Flexible configuration** through JSON files for different preprocessing pipelines.

Optional functionalities are:

- Configurable number of parallel workers for performance optimization.
- Multiple denoising algorithms with customizable parameters.
- Adjustable CLAHE clip limits for different contrast requirements.
- Support for both nested patient/study/series structures and flat file layouts.

## Configuration File Handling

- The configuration file (`config.json`) can be placed in either the `config` or `output` volume.
- All preprocessing parameters are configurable: z-score normalization, denoising method and parameters, CLAHE settings, and parallel processing workers.
- The tool supports flexible input/output directory names within the mounted volumes.

**Example configuration:**
```json
{
  "preprocessing": {
    "input_directory": "INPUT",
    "output_directory": "OUTPUT",
    "num_workers": 4,
    "zscore": {
      "enabled": true,
      "percentiles": [1.0, 99.0]
    },
    "denoise": {
      "method": "cascade",
      "params": {
        "cascade": {
          "unsharp_amount": 1.5,
          "unsharp_sigma": 1.0,
          "gaussian_sigma": 0.8
        }
      }
    },
    "clahe": {
      "enabled": true,
      "clip_limit": 0.01
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
    docker pull harbor.eucaim.cancerimage.eu/processing-tools/mammography_preprocessing:1.1.0
    ```

4. Run the Docker container as explained in the **Usage** section below.

  📝 **Note:** You do **not** need to build the Docker image locally. The image is already available and ready to use from the EUCAIM Harbor registry.

## 📁 Folder Structure Overview

This is the expected folder structure for running the Digital Mammography Preprocessing tool:

```
input_folder/
└── INPUT/                           # Dataset folder (can contain any nested or flat structure)
    └── [flexible structure]          # No fixed requirement: can include patients/studies/series/.dcm files in any layout

output_folder/
└── OUTPUT/                          # Processed DICOMs, organized in same structure as input
    └── [same structure as input]     # Processed DICOM files with enhanced quality

config/
└── config.json                      # Main configuration file (required)
```

#### Notes:
- The **`INPUT/` folder can have any internal structure**, including mixed or flat layouts.
- The **`OUTPUT/` folder mirrors the input structure** with processed DICOM files.
- Patient folders at first level enable parallel processing for better performance.

---


## **Usage**
1. Set up a folder where your input data is **(<input_path>)**
2. Set up a folder where you want to save the output processed images **(<output_path>)**
3. Create a directory for the configuration **(<config_path>)** and place your `config.json` file there with the preprocessing parameters.
4. Be sure that config file is edited as you desire. See configuration examples below.
5. Run the Docker container with the built image (choose config file or CLI arguments):

    ```bash
    docker run -it --rm --name mammography-preprocessing \
      -v "<input_path>:/input" \
      -v "<output_path>:/output" \
      -v "<config_path>:/config" \
      harbor.eucaim.cancerimage.eu/processing-tools/2d_mammography_preprocessing:1.1.0
    ```
### **Alternative: Run With Command-Line Arguments (No config.json)**

You can skip the configuration file and pass all mandatory parameters via CLI. Below are complete examples for each denoise method.

Example: Adaptive Median
```bash
docker run -it --rm --name mammography-preprocessing \
  -v "<input_path>:/input" \
  -v "<output_path>:/output" \
  harbor.eucaim.cancerimage.eu/processing-tools/2d_mammography_preprocessing:1.1.0 \
  --input_directory INPUT --output_directory OUTPUT --num_workers 4 \
  --series_number 2301101 --series_description_suffix _harmonized \
  --zscore_enabled true --zscore_p_low 1.0 --zscore_p_high 99.0 \
  --denoise_method adaptive_median --adaptive_median_ksize 3 \
  --clahe_enabled true --clahe_clip_limit 0.01
```

Example: Gaussian
```bash
docker run -it --rm --name mammography-preprocessing \
  -v "<input_path>:/input" \
  -v "<output_path>:/output" \
  harbor.eucaim.cancerimage.eu/ingestion-tools/mammography_preprocessing:1.0.0 \
  --input_directory INPUT --output_directory OUTPUT --num_workers 4 \
  --series_number 2301101 --series_description_suffix _harmonized \
  --zscore_enabled true --zscore_p_low 1.0 --zscore_p_high 99.0 \
  --denoise_method gaussian --gaussian_ksize 3 --gaussian_sigma 0.8 \
  --clahe_enabled true --clahe_clip_limit 0.01
```

Example: Anisotropic Diffusion
```bash
docker run -it --rm --name mammography-preprocessing \
  -v "<input_path>:/input" \
  -v "<output_path>:/output" \
  harbor.eucaim.cancerimage.eu/ingestion-tools/mammography_preprocessing:1.0.0 \
  --input_directory INPUT --output_directory OUTPUT --num_workers 4 \
  --series_number 2301101 --series_description_suffix _harmonized \
  --zscore_enabled true --zscore_p_low 1.0 --zscore_p_high 99.0 \
  --denoise_method anisotropic --anisotropic_niter 10 --anisotropic_kappa 50 --anisotropic_gamma 0.1 --anisotropic_option 1 \
  --clahe_enabled true --clahe_clip_limit 0.01
```

Example: Wavelet
```bash
docker run -it --rm --name mammography-preprocessing \
  -v "<input_path>:/input" \
  -v "<output_path>:/output" \
  harbor.eucaim.cancerimage.eu/ingestion-tools/mammography_preprocessing:1.0.0 \
  --input_directory INPUT --output_directory OUTPUT --num_workers 4 \
  --series_number 2301101 --series_description_suffix _harmonized \
  --zscore_enabled true --zscore_p_low 1.0 --zscore_p_high 99.0 \
  --denoise_method wavelet --wavelet_wavelet db1 --wavelet_level 2 \
  --clahe_enabled true --clahe_clip_limit 0.01
```

Example: Cascade (Unsharp + Gaussian) - Complete with all parameters
```bash
docker run -it --rm --name mammography-preprocessing \
  -v "<input_path>:/input" \
  -v "<output_path>:/output" \
  harbor.eucaim.cancerimage.eu/ingestion-tools/mammography_preprocessing:1.0.0 \
  --input_directory INPUT \
  --output_directory OUTPUT \
  --num_workers 4 \
  --series_number 2301101 \
  --series_description_suffix _harmonized \
  --zscore_enabled true \
  --zscore_p_low 1.0 \
  --zscore_p_high 99.0 \
  --denoise_method cascade \
  --cascade_unsharp_amount 1.5 \
  --cascade_unsharp_sigma 1.0 \
  --cascade_gaussian_sigma 0.8 \
  --clahe_enabled true \
  --clahe_clip_limit 0.01
```

### **CLI Argument Reference**
- `--config /path/to/config.json`: Explicit config file path inside container.
- If `--config` is omitted, CLI-only mode is used; provide all mandatory groups.
- `--input_directory`, `--output_directory`: Override directory names inside volumes.
- `--num_workers`: Parallel patient workers.
- `--series_number`: Exact SeriesNumber for processed series.
- `--series_description_suffix`: Suffix appended to original SeriesDescription.
- `--zscore_enabled true|false`: Enable/disable z-score normalization.
- `--zscore_p_low`, `--zscore_p_high`: Percentile clipping range.
- `--denoise_method`: Denoise algorithm.
- `--denoise_params_json`: JSON string with method-specific parameters.
- `--clahe_enabled true|false`: Enable/disable CLAHE.
- `--clahe_clip_limit`: CLAHE clip limit value.

#### Per-Method Denoise Parameter Flags (override JSON if both provided)
- Adaptive Median: `--adaptive_median_ksize`
- Gaussian: `--gaussian_ksize`, `--gaussian_sigma`
- Anisotropic: `--anisotropic_niter`, `--anisotropic_kappa`, `--anisotropic_gamma`, `--anisotropic_option`
- Wavelet: `--wavelet_wavelet`, `--wavelet_level`
- Cascade: `--cascade_unsharp_amount`, `--cascade_unsharp_sigma`, `--cascade_gaussian_sigma`

Example using per-method flags (no JSON):
```bash
docker run -it --rm -v "<input_path>:/input" -v "<output_path>:/output" \
  harbor.eucaim.cancerimage.eu/ingestion-tools/mammography_preprocessing:1.0.0 \
  --input_directory INPUT \
  --output_directory OUTPUT \
  --zscore_enabled true --zscore_p_low 1.0 --zscore_p_high 99.0 \
  --denoise_method anisotropic --anisotropic_niter 10 --anisotropic_kappa 50 --anisotropic_gamma 0.1 --anisotropic_option 1 \
  --clahe_enabled true --clahe_clip_limit 0.01 --series_number 9000 --series_description_suffix _harmonized
```


If both config and CLI flags are provided, CLI values override those in the config file.

This will run the preprocessing script within the Docker container using the specified volumes. Note that in the above example, the `-it` option is used for an interactive session, and the `--rm` option is used to remove the container after execution.

### **Mandatory parameters in configuration JSON file:**

All parameters under the `"preprocessing"` key are mandatory:

- `zscore`: (mandatory) Z-score normalization settings (object)
  - `enabled`: (mandatory) Enable/disable z-score normalization (boolean)
  - `percentiles`: (mandatory) Array `[low, high]` for percentile clipping. Example: `[1.0, 99.0]` (array of floats)

- `denoise`: (mandatory) Denoising settings (object)
  - `method`: (mandatory) Denoising method. Options: `"none"`, `"adaptive_median"`, `"gaussian"`, `"anisotropic"`, `"wavelet"`, `"cascade"` (string)
  - `params`: (mandatory) Method-specific parameters (object, see examples below)

- `clahe`: (mandatory) CLAHE settings (object)
  - `enabled`: (mandatory) Enable/disable CLAHE (boolean)
  - `clip_limit`: (mandatory) Contrast clip limit, typically between `0.005` and `0.02`. Default: `0.01` (float)

### **Optional parameters in configuration JSON file:**

- `input_directory`: (optional) Directory name within the `/input` volume where patient images are located. Default: `"INPUT"` (string)
- `output_directory`: (optional) Directory name within the `/output` volume where processed images will be saved. Default: `"OUTPUT"` (string)
- `num_workers`: (optional) Number of parallel patient workers for processing. Default: `1`. Use up to your CPU count for better performance (int)
- `series_number`: (optional) Exact SeriesNumber value for preprocessed series. Default: original + 1000. Example: `9000` assigns all processed images to series 9000 (int)
- `series_description_suffix`: (optional) Suffix appended to SeriesDescription for preprocessed images. Default: `" - Preprocessed"`. Helps distinguish processed series in DICOM viewers (string)

### **Denoising Methods and Parameters:**

#### No Denoising:
```json
"denoise": {
  "method": "none",
  "params": {}
}
```

#### Adaptive Median Filter (requires opencv-python):
```json
"denoise": {
  "method": "adaptive_median",
  "params": {
    "adaptive_median": {
      "ksize": 3
    }
  }
}
```

#### Gaussian Blur (requires opencv-python):
```json
"denoise": {
  "method": "gaussian",
  "params": {
    "gaussian": {
      "ksize": 3,
      "sigma": 0.0
    }
  }
}
```

#### Anisotropic Diffusion:
```json
"denoise": {
  "method": "anisotropic",
  "params": {
    "anisotropic": {
      "niter": 10,
      "kappa": 50.0,
      "gamma": 0.1,
      "option": 1
    }
  }
}
```

#### Wavelet Denoising:
```json
"denoise": {
  "method": "wavelet",
  "params": {
    "wavelet": {
      "wavelet": "db1",
      "level": 2
    }
  }
}
```

#### Cascade (Unsharp Mask + Gaussian) - **Recommended**:
```json
"denoise": {
  "method": "cascade",
  "params": {
    "cascade": {
      "unsharp_amount": 1.5,
      "unsharp_sigma": 1.0,
      "gaussian_sigma": 0.8
    }
  }
}
```

---

## **Functionality**

### Mammogram Selection (Filter)
A DICOM file is processed **only if ALL** of the following are true:
1. `Modality == "MG"` (mammography, case-insensitive).  
2. `NumberOfFrames == 1` (single frame, not tomosynthesis).  
3. `SamplesPerPixel == 1` (grayscale, not color).  
4. `PhotometricInterpretation ∈ {"MONOCHROME1", "MONOCHROME2"}`.  
5. `Rows` and `Columns` are present and valid.  
6. Pixel data decodes successfully and results in a **2D array** (H×W).

**Skipped files**: RTSTRUCT, SEG, SC, CT, MR, tomosynthesis (multi-frame), color images, and any non-MG modality.

**Output format**: Same filenames and relative paths as input. Transfer Syntax set to **Explicit VR Little Endian**. Pixel data is replaced with processed values; header fields are updated accordingly. Photometric interpretation is preserved.

**DICOM Metadata for Derived Series**: To prevent DICOM viewers from confusing or overwriting preprocessed images with originals, the following metadata is automatically modified:
- **SeriesInstanceUID** → New UID generated deterministically from original series UID. All images from the same original series will share the same new SeriesInstanceUID, so they group together as one preprocessed series in the viewer.
- **SOPInstanceUID** → New unique UID for each processed instance (file)
- **SeriesNumber** → Set to configured value (default: original + 1000, configurable via `series_number`)
- **SeriesDescription** → Appends suffix (default " - Preprocessed", configurable via `series_description_suffix`)
- **DerivationDescription** → Documents processing steps applied (z-score, denoising method, CLAHE)
- **StudyInstanceUID** → Preserved (unchanged) to maintain study grouping
- **PatientID/Name/StudyDate** → Preserved for identification

**Example**: If original Series A has 50 images with SeriesInstanceUID=1.2.3.4, all 50 preprocessed images will have the same new SeriesInstanceUID (e.g., 2.25.12345...), but each will have a unique SOPInstanceUID. The viewer will display them as a single preprocessed series with 50 images.

### Processing Pipeline (per image)
The tool applies the following steps to each valid mammography DICOM file:

1. **Load DICOM** → Read pixel data and apply Modality LUT (Rescale Slope/Intercept to get physical intensity values).
2. **Z-Score Normalization** (optional) → Percentile-based clipping and standardization to normalize intensity ranges.
3. **Denoising** (optional) → Apply selected denoising method (adaptive median, gaussian, anisotropic diffusion, wavelet, or cascade).
4. **CLAHE** (optional) → Contrast-limited adaptive histogram equalization for local contrast enhancement.
5. **Rescale** → Map processed values back to the original physical intensity range.
6. **Re-encode** → Convert to stored pixel values using the original Rescale Slope/Intercept.
7. **Generate new metadata** → Create new SeriesInstanceUID, SOPInstanceUID, update SeriesNumber/Description, and add DerivationDescription.
8. **Save DICOM** → Write as DICOM file with updated pixel data and metadata. Windowing tags (WindowCenter, WindowWidth, VOILUTSequence) are removed to avoid stale values.

**Notes**:
- Z-score normalization standardizes the input for consistent denoising and CLAHE application.
- The final rescaling ensures the output maintains the original intensity scale.
- CLAHE internally works in [0,1] range; the tool automatically maps to/from the original dynamic range.
- All processing preserves DICOM metadata and structure.

---

## **Acknowledgements**

This tool was developed for digital mammography quality enhancement and standardization in the EUCAIM project context. It is designed to work within federated learning infrastructures and imaging data federations.

Developed by Manuel Marfil-Trujillo, Pedro Miguel Martínez-Gironés (adaptation), Luis Marti-Bonmati (supervision) at **GIBI230 Research Group**, **La Fe Health Research Institute (IIS La Fe)**, Valencia, Spain.

---

## **License**

This software is provided under a limited-use license for academic and research purposes within the EUCAIM project.

**Key restrictions**:
- Use is permitted exclusively for EUCAIM project activities and related European public research infrastructures.
- Commercial use, redistribution, or integration into products/services requires prior written authorization.
- Attribution to IIS La Fe and the GIBI230 Research Group must be preserved.

**Disclaimer**:
- The software is provided "as-is" without warranty of any kind.
- The developers assume no responsibility for data handling, configuration errors, or results obtained.
- Users are responsible for ensuring compliance with applicable data protection and ethics regulations.

For full license terms, see `LICENSE.txt`. For permissions or questions, contact: **gibi230@iislafe.es**

**Contact**: https://www.iislafe.es/en/ | https://www.acim.lafe.san.gva.es/acim | https://cancerimage.eu/
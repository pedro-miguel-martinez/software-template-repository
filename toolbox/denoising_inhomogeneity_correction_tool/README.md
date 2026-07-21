# Denoising-Inhomogeneity Correction Tool

## Reference

Please cite the [following paper](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC8554919/) when using this tool:

	Fernández Patón M, Cerdá Alberich L, Sangüesa Nebot C, Martínez de Las Heras B, Veiga Canuto D, Cañete Nieto A, Martí-Bonmatí L. MR Denoising Increases Radiomic Biomarker Precision and Reproducibility in Oncologic Imaging. J Digit Imaging. 2021 Oct;34(5):1134-1145. doi: 10.1007/s10278-021-00512-8. Epub 2021 Sep 10. PMID: 34505958; PMCID: PMC8554919.	

And [the following one](https://pubmed.ncbi.nlm.nih.gov/32246291/):

    Martí-Bonmatí L, Alberich-Bayarri Á, Ladenstein R, Blanquer I, Segrelles JD, Cerdá-Alberich L, Gkontra P, Hero B, García-Aznar JM, Keim D, Jentner W, Seymour K, Jiménez-Pastor A, González-Valverde I, Martínez de Las Heras B, Essiaf S, Walker D, Rochette M, Bubak M, Mestres J, Viceconti M, Martí-Besa G, Cañete A, Richmond P, Wertheim KY, Gubala T, Kasztelnik M, Meizner J, Nowakowski P, Gilpérez S, Suárez A, Aznar M, Restante G, Neri E. PRIMAGE project: predictive in silico multiscale analytics to support childhood cancer personalised evaluation empowered by imaging biomarkers. Eur Radiol Exp. 2020 Apr 3;4(1):22. doi: 10.1186/s41747-020-00150-9. PMID: 32246291; PMCID: PMC7125275.


## Tool Description
The tool is designed to perform a customisable image pre-processing to reduce noise and inhomogeneity field effect, thus improving image quality and reproducibility of radiomics features. This tool consists of two independent steps: one for denoising using one of the 5 integrated filters (Bilateral Filter, Anisotropic Diffusion Filter (ADF), Curvature Flow Filter (CFF), SUSAN and Non Local Means (NLM)), and another for the ANTs N4 and another for the ANT's N4 bias correction filter. The parameter configuration of this tool has been optimised for TW1, T2W, DWI and DCE sequences in neuroblastoma (NB) and paediatric brain tumours, but it can also be configured with some of their parameters using a JSON parameter configuration file.


## Methodology:

The tool consists in two steps that can be run independently or together:

- **Denoising**: in this stage one of the following filters is applied:
	- Bilateral filter from SimpleITK library
	- Anisotropic Diffusion filter from SimpleITK library
	- Curvature Flow Filter from SimpleITK library
	- SUSAN from FSL library
	- Non-Local Means from DIPY library
- **Bias field correction**: in this stage N4 bias field correction filter of ANTs is applied.

---

## Folder Structure

The tool reads DICOM images from an **input** folder and writes harmonized DICOM images to an **output** folder, preserving the original directory structure.

### Example Structure

```
input_folder/
└── Dataset/
    ├── Patient_1/
    │   └── Study/
    │       ├── T1W_Sequence/
    │       │   ├── image001.dcm
    │       │   └── ...
    │       └── T2W_Sequence/
    │           └── ...
    └── Patient_2/
        └── ...

output_folder/
└── Dataset/
    ├── Patient_1/
    │   └── Study/
    │       ├── T1W_Sequence/
    │       │   ├── harmonized_001.dcm
    │       │   └── ...
    │       └── T2W_Sequence/
    │           └── ...
    └── Patient_2/
        └── ...

config_folder/ (optional)
└── parameter_configuration.json
```

![Input/(black/)-output/(red/) structure](images/Structure.png)

The second volume refers to the parameter_config.json folder. This file contains a list of parameters for running the tools. 

---

## Usage

### Option 1: Using JSON Configuration File

Create a `parameter_configuration.json` file with the following structure:

```json
{ 
  "Paths": [
    "/input/Dataset/Patient_1/Study/T1W_Sequence",
    "/input/Dataset/Patient_1/Study/T2W_Sequence",
    "/input/Dataset/Patient_2/Study/DWI_Sequence"
  ],
  
  "_comment": "Optional: Uncomment to override defaults",
  "_series_number": 2000,
  "_series_description_suffix": " - Harmonized",
  
  "Denoising_adf": [{
    "Conductance": 0.5,
    "Iterations": 3,
    "Time_step": 0.0625
  }],
  
  "N4": [{
    "BSpline_size": 50,
    "Iterations": [50, 30],
    "Shrink_factor": 2
  }]
}
```

**Behavior:**
- Without `series_number`: Original SeriesNumber + 1000 (e.g., 5 → 1005) ✅ **Recommended**
- With `series_number: 2000`: SeriesNumber = 2000 (absolute value)



## Docker Image Access

The Docker image for this tool is available in a remote registry. First, log in to the registry using your credentials:

```bash
docker login harbor.eucaim.cancerimage.eu -u <your_user> -p <your_token>
```

### 1. Environment for Data Holders

This environment is designed for data holders who validate datasets before its ingestion into EUCAIM.

#### Docker Image for Data Holders:

```bash
docker pull harbor.eucaim.cancerimage.eu/processing-tools/denoising_inhomogeneity_correction_tool:1.1.0
```

---


**Run with Docker:**

```bash
docker run --rm \
  -v <input_path>:/input \
  -v <output_path>:/output \
  -v <config_path>:/config \
  harbor.eucaim.cancerimage.eu/processing-tools/denoising_inhomogeneity_correction_tool:1.1.0 \
  --config /config/parameter_configuration.json
```

---

### Option 2: Using Command-Line Arguments

Run the tool directly with command-line arguments:

```bash
docker run --rm \
  -v <input_path>:/input \
  -v <output_path>:/output \
  harbor.eucaim.cancerimage.eu/processing-tools/denoising_inhomogeneity_correction_tool:1.1.0 \
  --paths /input/Dataset/Patient_1/Study/T1W /input/Dataset/Patient_2/Study/T2W \
  --output /output \
  --series_number 2000 \
  --series_description_suffix " - Harmonized" \
  --denoising adf \
  --conductance 0.5 \
  --iterations 3 \
  --time_step 0.0625 \
  --n4 \
  --bspline_size 50 \
  --n4_iterations 50 30 \
  --shrink_factor 2
```

---

## Configuration Parameters

### Paths (Required)

- **`Paths`**: List of DICOM folder paths relative to `/input` volume

### Output Directory (Optional)

- **`--output`** or **`Output` in config**: Base directory where harmonized DICOM files are saved
  - Default: `/output`
  - Command-line: `--output /path/to/output`
  - Config file: `"Output": "/path/to/output"`
  - **Note**: The tool preserves the original directory structure under this base path

### Series Metadata (Optional)

Control how the harmonized series appears in DICOM viewers:

- **`series_number`** (optional): **Absolute** SeriesNumber for harmonized series
  - If **not specified** (recommended): Original SeriesNumber + 1000
  - If **specified**: Uses exact value provided
  - Example: Original series 5 → Harmonized series 1005 (default) or 2000 (if configured)
  - **Note**: Default behavior (+1000) is recommended to avoid conflicts

- **`series_description_suffix`** (optional): Text appended to original SeriesDescription
  - Default: `"_harmonized"`
  - Example: `"series_description_suffix": " - Harmonized"`

**Note:** The tool automatically generates:
- **SeriesInstanceUID**: Deterministic UID (same input always produces same UID)
- **SOPInstanceUID**: Unique for each DICOM slice
- **DerivationDescription**: Documents applied filters (e.g., "Denoising: ADF; N4 Bias Field Correction")

### Denoising Filters (Optional)

Choose **one** of the following:

#### Anisotropic Diffusion Filter (ADF)
```json
"Denoising_adf": [{
  "Conductance": 0.5,
  "Iterations": 3,
  "Time_step": 0.0625
}]
```

**CLI arguments:**
- `--denoising adf`
- `--conductance <value>` (default: 0.5)
- `--iterations <value>` (default: 3)
- `--time_step <value>` (default: 0.0625)

#### Curvature Flow Filter (CFF)
```json
"Denoising_cff": [{
  "Iterations": 3,
  "Time_step": 0.0625
}]
```

**CLI arguments:**
- `--denoising cff`
- `--iterations <value>` (default: 3)
- `--time_step <value>` (default: 0.0625)

#### Bilateral Filter
```json
"Denoising_bilateral": [{
  "DomainSigma": 1.5,
  "RangeSigma": 50.0
}]
```

**CLI arguments:**
- `--denoising bilateral`
- `--domain_sigma <value>` (default: 1.5)
- `--range_sigma <value>` (default: 50.0)

#### SUSAN Filter
```json
"Denoising_susan": [{
  "brightness_threshold": 0.75,
  "fwhm": 3.0
}]
```

**CLI arguments:**
- `--denoising susan`
- `--brightness_threshold <value>` (default: 0.75, multiplier of Otsu threshold)
- `--fwhm <value>` (default: 3.0)

#### Non-Local Means (NLM)
```json
"Denoising_nlm": [{
  "Sigma": 1.0,
  "Patch_radius": 1,
  "Block_radius": 5
}]
```

**CLI arguments:**
- `--denoising nlm`
- `--sigma <value>` (default: 1.0)
- `--patch_radius <value>` (default: 1)
- `--block_radius <value>` (default: 5)

### N4 Bias Field Correction (Optional)

```json
"N4": [{
  "BSpline_size": 50,
  "Iterations": [50, 30],
  "Shrink_factor": 2
}]
```

**CLI arguments:**
- `--n4` (flag to enable)
- `--bspline_size <value>` (default: 50)
- `--n4_iterations <values...>` (default: 50 30)
- `--shrink_factor <value>` (default: 2)

---

## Optimal Parameters

Optimized configurations for different tumor types and sequences:

The optimised parameter configuration for each tumour and sequence is shown in the table below:

![Optimal parameters](images/Table.png)




## Examples

### Example 1: ADF Denoising + N4 Correction (JSON config)

**parameter_configuration.json:**
```json
{
  "Paths": [
    "/input/Patients/Patient_1/Study/T1W_Sequence"
  ],
  "Denoising_adf": [{
    "Conductance": 0.5,
    "Iterations": 3,
    "Time_step": 0.0625
  }],
  "N4": [{
    "BSpline_size": 50,
    "Iterations": [50, 30],
    "Shrink_factor": 2
  }]
}
```

**Command:**
```bash
docker run --rm \
  -v /data/input:/input \
  -v /data/output:/output \
  -v /data/config:/config \
  harbor.eucaim.cancerimage.eu/processing-tools/denoising_inhomogeneity_correction_tool:1.1.0 \
  --config /config/parameter_configuration.json
```

### Example 2: NLM Denoising Only (CLI)

```bash
docker run --rm \
  -v /data/input:/input \
  -v /data/output:/output \
  harbor.eucaim.cancerimage.eu/processing-tools/denoising_inhomogeneity_correction_tool:1.1.0 \
  --paths /input/Patient_1/DWI /input/Patient_2/DWI \
  --denoising nlm \
  --sigma 1.0 \
  --patch_radius 1 \
  --block_radius 5
```

### Example 3: N4 Correction Only (CLI)

```bash
docker run --rm \
  -v /data/input:/input \
  -v /data/output:/output \
  harbor.eucaim.cancerimage.eu/processing-tools/denoising_inhomogeneity_correction_tool:1.1.0 \
  --paths /input/Patient_1/T1W \
  --n4 \
  --bspline_size 50 \
  --n4_iterations 50 30 \
  --shrink_factor 2
```

---

## DICOM Metadata and UIDs

The tool generates harmonized DICOM files with properly structured metadata following DICOM standards:

### Generated UIDs

- **SeriesInstanceUID**: Deterministically generated using SHA256 hash
  - Same original series always produces the same harmonized SeriesInstanceUID
  - Format: `2.25.{hash_integer}` (UUID-derived UID standard)
  - All slices in a harmonized series share this UID

- **SOPInstanceUID**: Unique identifier for each DICOM instance
  - Generated using `pydicom.uid.generate_uid()`
  - Ensures each slice has a globally unique identifier

### Series Metadata

- **SeriesNumber**: Configurable via `series_number` parameter
  - Default: Original SeriesNumber + 1000
  - Example: Original series 5 → Harmonized series 1005 (or 2000 if configured)

- **SeriesDescription**: Original description + configurable suffix
  - Default suffix: `"_harmonized"`
  - Example: `"T1W_MPRAGE"` → `"T1W_MPRAGE_harmonized"`
  - Or with custom suffix: `"T1W_MPRAGE - Harmonized"`

- **DerivationDescription**: Automatically documents processing steps
  - Lists applied filters in order
  - Example: `"Denoising: ADF; N4 Bias Field Correction"`

## Dependencies and Licenses

This tool uses the following third-party software:

- **ANTs (Advanced Normalization Tools)**: N4 bias field correction
  - License: Apache 2.0 / BSD-style
  - Citation required when using N4 correction
  - [ANTs GitHub](https://github.com/ANTsX/ANTs)

- **Convert3D (c3d)**: NIFTI volume manipulation
  - License: GPL
  - [Convert3D Official Site](http://www.itksnap.org/pmwiki/pmwiki.php?n=Convert3D.Convert3D)

- **dcm2niix**: DICOM to NIFTI conversion
  - License: BSD-2-Clause
  - [dcm2niix GitHub](https://github.com/rordenlab/dcm2niix)

- **FSL (FMRIB Software Library)**: SUSAN filter
  - License: Custom FSL license (free for academic use)
  - [FSL License](https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/Licence)

- **SimpleITK**: Image filtering (ADF, CFF, Bilateral)
  - License: Apache 2.0

- **DIPY**: Non-Local Means denoising
  - License: BSD

When publishing results obtained with this tool, please cite the appropriate references for the filters and methods used.

---

## Acknowledgements

This tool was developed by **Matías Fernández Patón** in collaboration with the **GIBI230 Research Group** at **La Fe Health Research Institute (IIS La Fe)**, Valencia, Spain.
Extended information is provided via Biotools at https://bio.tools/denoising-inhomogeneity_correction_tool

### Maintainers

- **Matías Fernández-Patón** - Lead Developer
- **Pedro Miguel Martínez-Gironés** - Technical Support & Maintenance
- **Carina Soler** - Technical Support & Maintenance
- **Luis Martí-Bonmatí** - Principal Investigator

This work has been developed in the context of the **EUCAIM (European Cancer Image Platform)** project to support standardized imaging workflows for cancer research.

---

## Legal Information

**License:** See `LICENSE` file for terms and conditions.

This software is provided as part of the EUCAIM project under a limited-use license agreement. Commercial use requires prior authorization.

**Contact:**
- General inquiries: gibi230@iislafe.es, luis_marti@iislafe.es
- Technical support: matias_fernandez@iislafe.es, pedromiguel_martinez@iislafe.es, carina_soler@iislafe.es

---

## Version

Current version: 1.1.1

For updates and additional information, please contact the maintainers or visit the project repository.

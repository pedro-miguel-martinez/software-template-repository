# Cluster-based Radiomics Harmonization

## Usage
This tool performs **ComBat radiomics harmonization** on **clustered groups** instead of predefined batches.  
It is designed for large and heterogeneous datasets to reduce the risk of over-harmonization.  

The workflow first identifies groups of batches that share similar characteristics using **Agglomerative Clustering** on radiomics features, and then applies **ComBat harmonization**.

---
### Main functionalities:
- **ComBat radiomics harmonization** on the radiomics data
- **Cluster-based ComBat radiomics harmonization** on the radiomics data

### Optional:
- Selection on the clustering intensity (_soft/aggressive_)
- Control of small groups (<3 data) via removal or grouping to nearest neighbors
- Combat vs cluster based harmonization comparison (via figures and quantification metrics)

---
## Clustering process
The main steps of the clustering process are the following:
- PCA for dimensionality reduction (only for the clustering process)
- Small group handling:
    - Merged with the nearest large group (based on centroid distances)
    - Dropped from the analysis (depending on configuration)
- Agglomerative Clustering with Ward Linkage
- Definition of best cluster number based on configuration (_approach=aggressive_: clusters that maximize Dunn index, _approach=soft_: knee point)
---
## Evaluation metrics
Evaluation process is optional and serves as a quantification tool of the batch effect removal and the radiomics component preservation. 

### Quantification metrics
Logged in results if _metrics_ is selected for _results_ parameter.
- R² values to measure batch effect removal
- Concordance Correlation Coefficient (CCC) to measure radiomics preservation

Outputed if _full_ is selected for _results_.
- CCC distribution histograms
- CCC vs R² scatter plots
- Batch effect removal bar charts
---

## Requirements:
### Input:
- A `.csv` or `.xlsx` file with radiomics features, series identifier and the batch variable. Note: The radiomics features should be in successive columns and the batch variables should be categorical or categorical encoded.
- A `.json` file (see **JSON configuration**)
### Output:
- Two output files in the same format as the input with the following columns **1. ComBat harmonized features and the identifier 2. Cluster-based ComBat harmonized features, identifier and clusters.**
- Two or three log files tracking 1. process 2. results 3. errors (if any)
- If _results_ variable is set to full, figures on CCC and R² are also provided as outputs (see **JSON configuration**).

_Note: for "results" log file, if results variable is set to metrics, percentage of batch effect removal (as R²) and percentage of radiomics preservation (as CCC) for both ComBat and cluster-based ComBat harmonization are shown._

---
Before starting, we need to have or create a project folder, where the file with the radiomics needs to be found and where all results will be stored after successful execution. The python, requirements and Dockerfile do  not necessarily have to be found there.
## JSON configuration json
Inside the project folder, there must be a JSON file named configuration.json. This file can include the following parameters

### Mandatory
- `/project/file_path`: route inside the project folder where your radiomics file is found, should start with "/project".
- `identifier`:  column name of the identifier (could be patient_id or something similar). 
- `start_col, end_col`: column names of the first and last radiomics variables; the radiomics variables should occupy consecutive columns in the file. 
- `batch_col`: column name of the batch variable to harmonize on. 
- `/project/output_dir`: directory inside the project folder where all log files and results will be saved; should start with "/project". 

### Optional
- `min_clusters, max_clusters`: minimum and maximum number of clusters for the iterative search. Default numbers are 2 and maximum groups of batch variable, respectively.  
- `results`: _none/metrics/full_.  If _none_, no results are calculated. If _metrics_, quantitative results are logged. If _full_, figures are also provided. 
- `approach`: _soft/aggressive_. If _soft_, the last knee point is used during cluster number optimization, representing a good balance between cluster quality and number of clusters. With the _aggressive_ option, the Dunn index is maximized, maximizing cluster separation. Default option is _soft_. 
- `small_groups`: _merge/drop_. With "merge" option, individual small-data clusters that cannot be clustered based on centroids are forced to cluster by their closest clusters. With _drop_ option, these data are removed. _merge_ is the default option. 
---

### Example config file
```json
{
    "file_path": "/input/example.xlsx",
    "identifier": "patient_id",
    "start_col": "original_shape_Elongation",
    "end_col": "lbp-3D-k_ngtdm_Strength",
    "batch_col": "software_versions",
    "min_clusters": 1,
    "max_clusters": 100,
    "output_dir": "/output/results",
    "results": "full",
    "approach": "soft",
    "small_groups": "drop"
}
```

---

## Docker Image Access

The Docker image for this tool is available in a remote registry. First, log in to the registry using your credentials:

```bash
docker login <registry_url> -u <your_user> -p <your_token>
```

### Pull the Docker Image
```bash
docker pull <registry>/<repository>:<version>
```

Replace `<registry>/<repository>:<version>` with the actual image location.

---

## 📁 Folder Structure Overview

This is the expected folder structure for running the Cluster-based Radiomics Harmonization tool:

```
input_folder/
└── data.xlsx or data.csv          # Input radiomics file

output_folder/
├── harmonized_original_ComBat.xlsx/csv      # ComBat harmonized output
├── harmonized_clustered_ComBat.xlsx/csv     # Cluster-based ComBat harmonized output
└── log_files/
    ├── process_log.txt             # Process execution log
    ├── results_log.txt             # Results and metrics log
    └── error_log.txt               # Error log (if any)

config/
└── config.json                     # Configuration file (optional if using command-line args)
```

---

## Usage

### 1. Set up your folders
- **`<input_path>`**: Folder containing your radiomics data file (`.csv` or `.xlsx`)
- **`<output_path>`**: Folder where results and logs will be saved
- **`<config_path>`** (optional): Folder containing your `config.json` file

### 2. Prepare your configuration
You can either:
- Create a `config.json` file with your parameters (see example above), or
- Use command-line arguments directly

### 3. Run the Docker container

#### Option A: Using a configuration JSON file
```bash
docker run --rm \
  -v "<input_path>:/input" \
  -v "<output_path>:/output" \
  -v "<config_path>:/config" \
  <registry>/<repository>:<version> \
  --config /config/config.json
```

**Parameters:**
- **`<input_path>`**: Absolute path to folder with your input data file
- **`<output_path>`**: Absolute path to folder where results will be saved
- **`<config_path>`**: Absolute path to folder containing `config.json`
- **`<registry>/<repository>:<version>`**: Docker image reference

#### Option B: Using command-line arguments
```bash
docker run --rm \
  -v "<input_path>:/input" \
  -v "<output_path>:/output" \
  <registry>/<repository>:<version> \
  --file_path /input/data.xlsx \
  --identifier patient_id \
  --start_col original_shape_Elongation \
  --end_col lbp-3D-k_ngtdm_Strength \
  --batch_col software_versions \
  --output_dir /output/results \
  --min_clusters 2 \
  --max_clusters 100 \
  --results full \
  --approach soft \
  --small_groups merge
```

**Mandatory arguments:**
- `--file_path`: Path to input file inside container (e.g., `/input/data.xlsx`)
- `--identifier`: Column name for sample identifier
- `--start_col`: First radiomics feature column name
- `--end_col`: Last radiomics feature column name
- `--batch_col`: Batch/center column name
- `--output_dir`: Output directory inside container (e.g., `/output/results`)

**Optional arguments:**
- `--min_clusters`: Minimum number of clusters (default: 2)
- `--max_clusters`: Maximum number of clusters (default: 100)
- `--results`: Results level - `none`, `metrics`, or `full` (default: `none`)
- `--approach`: Clustering approach - `soft` or `aggressive` (default: `soft`)
- `--small_groups`: Small groups handling - `merge` or `drop` (default: `merge`)

---

## Notes

- **CPU allocation**: The script automatically detects available CPUs. If you need to limit resources, use Docker's `--cpus` flag:
  ```bash
  docker run --rm --cpus 30 -v ...
  ```
- **File paths**: All paths inside arguments must use container paths (e.g., `/input/`, `/output/`, `/config/`)
- **Output**: Results are saved in the `<output_path>` folder specified in the volume mount

---

## Acknowledgements

This tool was developed by [Aikaterini Vraka] and [Luis Martí-Bonmatí]. All done at [GIBI230] Research Group Environment, at [La Fe Health Research Institute - LA FE HOSPITAL VALENCIA].

---

## Legal Information

| **Author**                 | Aikaterini Vraka                |
| **Participants**           | Luis Martí-Bonmatí              |

**License:** See `license.txt` for full terms and conditions.

**Contact:** 
- General inquiries: gibi230@iislafe.es, luis_marti@iislafe.es
- Technical support: aikaterini_vraka@iislafe.es, pedromiguel_martinez@iislafe.es, carina_soler@iislafe.es








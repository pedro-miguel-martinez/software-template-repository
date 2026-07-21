# **DICOM FILE INTEGRITY CHECKER**

This is a Python script that selects DICOM files of specific sequences from an input directory based on a configuration file and copies them into a new directory, performing several data preprocessing and quality assurance.

The output is the processed dataset and a report containing information about the selected sequences, corrupted files, missing files, timepoints (studies) found, and merged sequences if applicable.

The main functionalities are:

- Identification of missing and corrupted files.
- Selection of sequences according to a previous list of sequences by manufacturer and sequence type (T2, DWI, DCE, T1w, etc.) compiled in a catalogue.
    - You can adapt the **catalogue file** (in this repository is as an example **`catalogue.xlsx`**, but it can have another name if specified in *catalogue_file* in the configuration parameters) to the sequence names you know in your specific project/machine/institution. It can be provided either in .xlsx or .json format. As an example, the one for Prostate Cancer imaging at HULAFE is provided.
    - Dear user: if you find new sequence names for this use case, please add it to the file and commit the changes, also provide other configuration files that you adapt to other use cases.
- Merging sequences that are separated into several ones and should not be, i.e., multivolume sequences (especially dynamic ones such as DCE) that are sometimes separated by temporal instances.
- Identification of diffusion sequences by different B values in the same sequence (low and high, commonly 0 & 1000 or 0 & 1500).
- Reporting useful information from the dataset and the QA process performed.
- Parallelization of the process to speed up the execution.

Optional functionalities are:

- Analysis of the dataset and generation of the report file without copying any dcm file (faster).
- Select the format of the generated report (options: xlsx, json and html) and its name
- Extraction of the patient code / pseudo-anonymized code from the input folder for cases in which patientID and patientName DICOM tags are empty.
- Adjustment of the minimum number of sequences needed for understanding as a multivolume one separated that must be merged.
- Matching of the SeriesDescription in DICOM file with the one in the list of the **catalogue file**. By default only try to find a string between the other one.
- Change of the SeriesDescription tag of the files to a generic one if needed (e.g., change "GE_axial_t2W_con_contraste" to "T2").
- Change of the Series folder name of the files to a generic one if needed (e.g., change "GE_axial_t2W_con_contraste" to "T2").
- Introduction of the B values of a diffusion sequence into the sequence name (in seriesDescription tag or series folder name depending on the option chosen with the other arguments).
- Introduction of preferences about the desired diffusion sequence depending on the B values. Example: I prefer 1st 0-1000, if not found choose 0-800, and if not the one nearest the 1st option.
- Selection of how choosing the possible dwi: from catalogue names, from b_values preferences indicated or addressing both cases. Example: in the catalogue you can have several options for the prostate adquired in several B fields but you do not want sequences centered in ganglia (so they are not in te catalogue) and you prefer a b_value preference selected in the list given in the json of optional_parameters.

## Execution Environments: Data Holders vs Data Users

The DICOM File Integrity Checker is executed differently depending on your EUCAIM user role. 

First, you have to log in to the EUCAIM Harbor registry using your user credentials (retrieved from your user profile in the registry):

```bash
docker login harbor.eucaim.cancerimage.eu -u <your_user> -p <your_token>
```

### 1. Environment for Data Holders

This environment is designed for data holders who validate datasets before its ingestion into EUCAIM.

#### Docker Image for Data Holders:

```bash
docker pull harbor.eucaim.cancerimage.eu/ingestion-tools/dicom_file_integrity_checker:<version>
```

#### Execution Options for Data Holders

A. Using configuration files (config.json + catalogue):
```bash
docker run -it --rm --name my-container \
  -v "<input_path>:/input" \
  -v "<output_path>:/output" \
  -v "<config_path>:/config" \
  harbor.eucaim.cancerimage.eu/ingestion-tools/dicom_file_integrity_checker:<version>
```

B. Providing configuration as string (example of --config-string):
```bash
docker run -it --rm --name my-container \
  -v "<input_path>:/input" \
  -v "<output_path>:/output" \
  harbor.eucaim.cancerimage.eu/ingestion-tools/dicom_file_integrity_checker:<version> \
  --config-string "{'QA': {'sequence_selection': ['ALL'], 'modality_selection': ['ALL'], 'input_directory': 'dataset_id'}}" # Pass configuration directly as a string argument (only single quotes are allowed for keys/values, but double quotes must be used to encompass all the string)
```

### 2. Environment for Data Users (FEM)

This environment is used inside the EUCAIM Federated Executor Manager (FEM) to process DICOM datasets in a federated/distributed manner.

#### Docker Image for Data Users:

```bash
docker pull harbor.eucaim.cancerimage.eu/processing-tools/dicom_file_integrity_checker:<version>
```

#### Execution Format Required by FEM
```bash
docker run -it --rm --name my-container \
  -v "<input_path>:/input" \
  -v "<output_path>:/output" \
  harbor.eucaim.cancerimage.eu/processing-tools/dicom_file_integrity_checker:<version> \
  /app/entrypoint.sh --config-string "{'QA': {'sequence_selection': ['ALL'], 'modality_selection': ['ALL'], 'input_directory': 'dataset_id'}}" # Pass configuration directly as a string argument (only single quotes are allowed for keys/values, but double quotes must be used to encompass all the string)
```
Please note that you must pass the entrypoint and configuration in the command line. In addition, FEM administrators must configure an environment variable that will be provided by developers.


## 📁 Folder Structure Overview

This is the expected folder structure for running the DICOM File Integrity Checker:

```
input_folder/
└── INPUT/                           # Dataset folder (can contain any nested or flat structure)
    └── [flexible structure]          # No fixed requirement: can include patients/studies/series/.dcm files in any layout

output_folder/
├── OUTPUT/                           # Output DICOMs, organized in nested structure:
│   └── PATIENT_ID/
│       └── STUDY/
│           └── SERIES/
│               └── *.dcm            # Selected and renamed DICOM files
├── reports_dicom_file_integrity_checker/
│   └── report_*.xlsx/json/html      # Generated reports
└── logs_dicom_file_integrity_checker/
    └── debug_log_*.txt              # Optional debug logs (if enabled)

config/
├── config.json                       # Main configuration file (required if --config-string is not passed)
└── catalogue.xlsx                    # Sequence catalogue (or `catalogue.json`) (required)
```

#### Notes:
- The **`INPUT/` folder can have any internal structure**, including mixed or flat layouts.
- The **`OUTPUT/` folder is automatically structured** by patient, study, and series to reflect the selected and processed DICOM content.
- Reports and logs are saved separately for traceability.


## **Usage**
1. Set up a folder where your input data is **(<input_path>)**
2. Set up a folder where you want to save the output reports, logs and optionally the output processed images **(<output_path>)**
3. Create a directory for the configurations **(<config_path>)** and inside it fill the file with the configuration parameters file (with the mandatory name: **`config.json`**) and the catalogue file editing it if necessary (e.g., **`catalogue.xlsx`**) or use the one provided in this repository (this file is mandatory). You can also use a json file for the catalogue (e.g., **`catalogue.json`**) but Excel is structured easier, be sure of this structure.
    3.1. Introduce new sequence names into the list or edit. You can add rows maintaining the format, also columns for new sequence types.
    3.2. Change the titles of the sequence columns if you desire another, like DIFUSION or DW or DWI. Change accordingly to the **sequence_selection** in **`config.json`**.
    3.3. Choose **`"sequence_selection": ["ALL"]`** if you want to let pass every sequence from the input to the output folder. Or choose only the types you want (so exclude the others).
    3.4. Choose **`"modality_selection": ["ALL"]`** if you want to let pass every modality from the input to the output folder. Or choose only the types you want (so exclude the others).
4. Be sure that config file is edited as you desire, if it is empty it will take the default values.
5. Run the Docker container with the built image as indicated above, depending on your execution environment

### **Mandatory parameters in configuration JSON file:**
- `catalogue_file`: (mandatory) name of the file with the sequence catalogue. It can be an .xlsx or a .json. By default it is *catalogue.xlsx*. (string)
- `sequence_selection`: (mandatory) name of the sequences to be selected, according to the columns of the catalogue in excel format or to the sections of the catalogue in json format. If you want to select all of them, you must write: "ALL". By default: *["ALL"]*. (list of strings)
- `modality_selection`: (mandatory) name of the modalities to be selected, according to the rows of the catalogue in excel format or to the sections of the catalogue in json format. If you want to select all of them, you must write: "ALL". By default: *["ALL"]*. (list of strings)

### **Optional parameters in configuration JSON file:**
- `input_directory`: (optional) directory name within the input folder where the patient images you want to use as input are located. By default, if nothing is specified, it will be the "INPUT" folder. (string)
- `output_directory`: (optional) directory name within the output folder where you want to save the selected sequences. By default, if nothing is specified, it will be overwritten in the "OUTPUT" folder. (string)
- `only_report`: (optional) if set to True, only a report will be generated instead of the output directory with the dicom files included and the report. By default: False. (boolean)
- `report_type`: (optional) parameter to specify the format of the generated reports. Options: "xlsx", "json" and "html". By default: "xlsx".
- `report_name`: (optional) parameter that allows to specify a different name for the reports. The default name will be *report_dicom_studies_qa_{now}.{report_type}*, but can be changed to *{report_name}_{now}.{report_type}*.
- `id_from_folder`: (optional) if True, take Patient ID from folder (for cases where PatientID dicom tag is generic or anonymized)(files must be by hierarchy *'patient/study/series/.dcm*). By default: *False*. (boolean)
- `num_min_dyn_seq`: (optional) The minimum number of dynamic sequences that must be found to consider an image series as relevant. The default value is 3. (int)
- `force_sequence_name`: (optional) If set to True, sequences will be forced to have specific names instead of generic names. By default: True. (boolean)
- `change_header_names`: (optional) If set to True, generic names will be used for sequences. By default: True. (boolean)
- `change_folder_names`: (optional) If set to True, generic names will be used for the folders containing the sequences. By default: True. (boolean)
- `b_values_in_name`: (optional) If set to True, b values will be included in sequence names. By default: True. (boolean)
- `b_value_choices`: (optional) A list of b values to search for in sequence names. (list of int)
- `dwi_selection_source`: (optional) 3 options to select which is the source for the possible diffusion series: "catalogue", "b_value_choices" or "both". (string)
- `generic_diffusion_name`: (optional) generic name that is assigned to the selected diffusion series. (string)
- `modalities_to_avoid_exclusion_corrupt_files`: (optional) Name all modalities which are not able to open with pydicom library, but you know they are not corrupt files. Ex.: "RTSTRUCT", "RTDOSE" or "RTPLAN". (list of strings) 
- `modalities_to_include_everything`: (optional) Name all modalities you want to include complete because series_descriptions do not follow a pattern (list of strings)
- `dwi_quantity`: (optional) Number of diffusion sequences to be selected. Options 1 to any number or "all" for letting pass anyone. By default: 1. (int)
- `debug`: (optional) If set to True, debug mode will be enabled. This includes redirecting stdout and stderr to a text file within the reports directory, making it easier to review log messages and errors during the script's execution. The default name of the file will be debug_log_report_dicom_studies_qa_{current_date}.txt, but it can be changed if a different name is specified in the `report_name`. (boolean)
- `threads_percentage`: (optional) Percentage of threads to be used in the parallelization of the process. Example: 50 means that 50% of the total amount of threads will be used. By default: 100 = all threads. (int)

All arguments have default values if not provided.

## **Functionality**

The **`select_scope_sequences`** function performs the following steps:

1. Loads the configuration file and extracts the selected sequences based on the user's input.
2. Initializes several worksheets in an Excel file using the **`xlsxwriter`** package.
3. Loops over all DICOM files in the input directory, reads their metadata using the **`pydicom`** package, and organizes them based on the patient, study, and series.
4. Filters the series based on the selected sequences and copies the DICOM files for the selected series to the output directory.
5. Detect diffusion sequences by different B values in the same sequence (low and high, commonly 0 & 1000 or 0 & 1500) and include them.
6. Merges sequences that are separated into several ones and should not be, i.e., multivolume sequences (especially dynamic ones such as DCE) that are sometimes separated by temporal instances.
7. Generates a report containing information about the selected sequences, corrupted files, missing files, and timepoints.

## **Acknowledgements**

This script was developed and continuously improved with new features by [Pedro Miguel Martinez & Adrian Galiana]. Reviewed and adapted to Airflow pipelines by [Carina Soler]. All done at [GIBI230] Research Group Environment, at [La Fe Health Research Institute - LA FE HOSPITAL VALENCIA].

## **Legal information**
| IISLAFE Software Registry           | Details    |
|-----------------------|---------------------------|
| **Registry Number** | R149-2023-2381          |
| **Registry Date**  | 19 october 2023    |
| **Author**              | Pedro Miguel Martínez Gironés |
| **Participants**      | Adrián Galiana, Carina Soler, Luis Martí-Bonmatí  |
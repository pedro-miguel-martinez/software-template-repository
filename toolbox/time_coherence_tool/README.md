# **Time Coherence Tool**

This is a Python-based visualization tool that generates interactive medical timelines from patient data in Excel format. It enables visual verification of the chronological order and logical consistency of dates associated with a patient's medical history, helping to identify potential data quality issues before clinical analysis or data federation.

The tool reads Excel files with patient event data, applies configurable validation rules, and outputs timeline visualizations in SVG, PNG, and PDF formats with problem highlighting and customizable icons.

## Main Functionalities

- **Automatic timeline generation** from Excel patient data
- **Multi-format output**: SVG, PNG (high-resolution), and PDF
- **Visual event representation** with customizable medical icons
- **Medical period/era visualization** with shaded regions
- **Rule-based validation** with visual problem highlighting (red markers)
- **Flexible event positioning** (upper/lower timeline placement)
- **Configurable appearance** (resolution, width, colors)
- **Batch processing** for multiple patients

## Building the Docker Image

To build the Docker image locally:

```bash
docker build -t harbor.eucaim.cancerimage.eu/processing-tools/time_coherence_tool:1.1.0 .
```

## Execution

Run the tool with Docker by mounting input/output folders:

```bash
docker run -it --rm --name my-container \
  -v "<input_path>:/input" \
  -v "<output_path>:/output" \
  harbor.eucaim.cancerimage.eu/processing-tools/time_coherence_tool:1.1.0 \
  --config-string "{'data_file': 'my_data.xlsx', 'generate_pdf': 'true'}"
```

## 📁 Folder Structure Overview

This is the expected folder structure for running the Time Coherence Tool:

### **Standard Mode** (with your own data)

```
input_folder/
└── /input/                           # Input data (READ-ONLY in EUCAIM)
    └── your_data.xlsx                # Your patient data (Excel or CSV)
                                      # NOTE: You can also place data in /output/ instead

output_folder/
└── /output/                          # Output and editable configuration
    ├── config/                       # Configuration files (EDITABLE)
    │   ├── image_configuration.xlsx  # Icon mapping (edit to match your columns)
    │   ├── label_configuration.xlsx  # Display labels (optional)
    │   ├── event_configuration.xlsx  # Event positioning (edit to match your columns)
    │   └── rules_configuration.xlsx  # Validation rules (edit for your logic)
    ├── icons/                        # Medical event icons (EDITABLE)
    │   ├── surgery.png
    │   ├── diagnosis.png
    │   └── ...
    ├── svg/                          # Generated SVG timelines
    │   ├── Patient_001.svg
    │   └── ...
    ├── png/                          # Generated PNG timelines (high resolution)
    │   ├── Patient_001.png
    │   └── ...
    └── pdf/                          # Generated PDF timelines
        ├── Patient_001.pdf
        └── ...
```

### **Test/Demo Mode** (--test flag)

```
output_folder/
└── /output/
    └── test/                         # All test/demo outputs in this folder
        ├── input/                    # Example data for reference
        │   └── data_source.xlsx      # See this to understand expected format!
        ├── config/                   # Example configuration files
        │   ├── image_configuration.xlsx
        │   ├── label_configuration.xlsx
        │   ├── event_configuration.xlsx
        │   └── rules_configuration.xlsx
        ├── icons/                    # Default medical icons
        │   ├── surgery.png
        │   ├── diagnosis.png
        │   └── ...
        ├── svg/                      # Example timeline outputs
        ├── png/
        └── pdf/
```

#### Notes:
- **Test mode** is recommended for first-time users - no input folder needed!
- **Data file flexibility**: Can be in `/input/` (EUCAIM standard) OR `/output/` (development)
- **Supported formats**: Excel (`.xlsx`, `.xls`) and CSV (`.csv`)
- **First run**: Configuration files and icons are **automatically copied** from defaults if not present
- **Subsequent runs**: Edit files in `/output/config/` and `/output/icons/` to customize behavior
- The tool automatically creates all necessary subdirectories

## **Usage**

### 🚀 Quick Start (Recommended for First-Time Users)

#### **Step 1: Run in Test/Demo Mode**

**RECOMMENDED**: Before using your own data, run the tool in **test mode** to see how it works with example data:

```bash
docker run -it --rm \
  -v "<output_path>:/output" \
  harbor.eucaim.cancerimage.eu/processing-tools/time_coherence_tool:1.1.0 \
  --test
```

**What happens in test mode:**
- ✅ Uses **built-in example patient data** (no input folder needed!)
- ✅ Creates `/output/test/input/` with the **example data file** for your reference
- ✅ Creates `/output/test/config/` with **example configuration files**
- ✅ Creates `/output/test/icons/` with **default medical icons**
- ✅ Generates timelines in `/output/test/svg/`, `/output/test/png/`, `/output/test/pdf/`

**After test run, examine:**
- `/output/test/input/data_source.xlsx` - See the expected **data format** (Excel columns, date formats)
- `/output/test/config/*.xlsx` - See how **configuration files** map columns to events/icons/rules
- `/output/test/svg/*.svg` - See the **resulting timelines** with icons and validation

#### **Step 2: Prepare Your Own Data**

Now that you understand the format, prepare your clinical data:

1. **Input data file** (Excel or CSV):
   - Can be placed in `/input/` (read-only, EUCAIM standard) OR `/output/` (read-write)
   - Supported formats: `.xlsx`, `.xls`, `.csv`
   - Must contain patient data with **date columns** (e.g., diagnosis_date, surgery_date)
   
2. **Customize configuration files** in `/output/config/`:
   - Copy and edit the example files from `/output/test/config/`
   - Update column names to match YOUR data
   - Adjust validation rules for YOUR clinical logic

#### **Step 3: Run With Your Data**

**Option A**: Data file in `/input/` (read-only, recommended for EUCAIM):
```bash
docker run -it --rm \
  -v "<input_path>:/input" \
  -v "<output_path>:/output" \
  harbor.eucaim.cancerimage.eu/processing-tools/time_coherence_tool:1.1.0 \
  --config-string "{'data_file_path': '/input/my_data.xlsx'}"
```

**Option B**: Data file in `/output/` (read-write, useful during development):
```bash
docker run -it --rm \
  -v "<output_path>:/output" \
  harbor.eucaim.cancerimage.eu/processing-tools/time_coherence_tool:1.1.0 \
  --config-string "{'data_file_path': '/output/my_data.csv'}"
```

**Option C**: Legacy mode (data file in `/input/` with default name):
```bash
docker run -it --rm \
  -v "<input_path>:/input" \
  -v "<output_path>:/output" \
  harbor.eucaim.cancerimage.eu/processing-tools/time_coherence_tool:1.1.0 \
  --config-string "{'data_file': 'my_data.xlsx'}"
```

#### **Step 4: Review and Iterate**

1. **Check generated timelines** in `/output/svg/`, `/output/png/`, `/output/pdf/`
2. **Look for RED markers** - these indicate validation rule failures
3. **Adjust configuration** in `/output/config/` as needed
4. **Re-run** the container to regenerate with updated settings

### 📝 Important Notes

⚠️ **Default configuration files are EXAMPLES only** - they demonstrate the format but use placeholder column names. You **must edit them** to match your actual data structure.

⚠️ **Events violating validation rules appear in RED** on timelines - this helps identify potential data quality issues.

⚠️ **CSV support**: The tool automatically detects `.csv` files and reads them correctly. Use CSV if your clinical data is already in this format.

⚠️ **Flexible data location**: Use `data_file_path` to specify the full path to your data file (e.g., `/input/data.xlsx` or `/output/mydata.csv`). This gives you flexibility in where you store your input data.

### Advanced Usage

```bash
# Test mode - see example data and outputs
docker run -it --rm \
  -v "<output_path>:/output" \
  harbor.eucaim.cancerimage.eu/processing-tools/time_coherence_tool:1.1.0 \
  --test

# With data file in /input (EUCAIM standard)
docker run -it --rm \
  -v "<input_path>:/input" \
  -v "<output_path>:/output" \
  harbor.eucaim.cancerimage.eu/processing-tools/time_coherence_tool:1.1.0 \
  --config-string "{'data_file_path': '/input/patients.xlsx'}"

# With data file in /output (useful for development)
docker run -it --rm \
  -v "<output_path>:/output" \
  harbor.eucaim.cancerimage.eu/processing-tools/time_coherence_tool:1.1.0 \
  --config-string "{'data_file_path': '/output/my_data.csv'}"

# With CSV input file
docker run -it --rm \
  -v "<input_path>:/input" \
  -v "<output_path>:/output" \
  harbor.eucaim.cancerimage.eu/processing-tools/time_coherence_tool:1.1.0 \
  --config-string "{'data_file_path': '/input/clinical_data.csv'}"

# With custom output settings
docker run -it --rm \
  -v "<input_path>:/input" \
  -v "<output_path>:/output" \
  harbor.eucaim.cancerimage.eu/processing-tools/time_coherence_tool:1.1.0 \
  --config-string "{'data_file_path': '/input/data.xlsx', 'generate_pdf': 'false', 'png_dpi': '1500'}"

# With custom config file names
docker run -it --rm \
  -v "<input_path>:/input" \
  -v "<output_path>:/output" \
  harbor.eucaim.cancerimage.eu/processing-tools/time_coherence_tool:1.1.0 \
  --config-string "{'data_file_path': '/input/data.xlsx', 'img_config_file': 'my_icons.xlsx', 'event_config_file': 'my_events.xlsx'}"
```

### **Configuration Parameters**

When using `--config-string`, you can provide a Python dictionary string (use single quotes for keys/values):

- `data_file_path`: (optional) **Full path** to input data file. Can be `/input/file.xlsx`, `/output/file.csv`, etc. Supports `.xlsx`, `.xls`, and `.csv` formats. (string)
- `data_file`: (optional) **Legacy option** - filename only, assumes `/input/` directory. Default: `data_source.xlsx`. (string)
- `img_config_file`: (optional) Icon mapping configuration file. Default: `image_configuration.xlsx`. (string)
- `label_config_file`: (optional) Display label mapping file. Default: `label_configuration.xlsx`. (string)
- `event_config_file`: (optional) Event positioning configuration. Default: `event_configuration.xlsx`. (string)
- `rules_config_file`: (optional) Validation rules file. Default: `rules_configuration.xlsx`. (string)
- `generate_svg`: (optional) Generate SVG output. Default: `true`. (string: `true`/`false`)
- `generate_png`: (optional) Generate PNG output. Default: `true`. (string: `true`/`false`)
- `generate_pdf`: (optional) Generate PDF output. Default: `true`. (string: `true`/`false`)
- `png_dpi`: (optional) PNG resolution in DPI. Default: `2000`. (integer)
- `timeline_width`: (optional) Timeline width in pixels. Default: `700`. (integer)

**Priority**: If both `data_file_path` and `data_file` are specified, `data_file_path` takes precedence.

Example:
```bash
--config-string "{'data_file_path': '/output/my_patient_data.csv', 'generate_pdf': 'true', 'png_dpi': '1500', 'timeline_width': '800'}"
```

## **Input Data Format**

### Main Data File Structure

The main data file should be an Excel file (`.xlsx`) with the following structure:

- **First column**: Patient/record identifier
- **Subsequent columns**: Date columns containing timeline events
- **Column names**: Will be used as event labels (can be customized via label configuration)

Example:
```
patient_id | diagnosis_date | surgery_date | treatment_start | treatment_end | follow_up_date
PAT001     | 2023-01-15     | 2023-02-01   | 2023-02-15      | 2023-04-01    | 2023-05-01
PAT002     | 2023-01-20     | 2023-02-05   | 2023-02-20      | 2023-04-05    | 2023-05-10
```

### Configuration Files

#### 1. Image Configuration (`image_configuration.xlsx`)

Maps event names to icon files:

| palabra/word              | imagen/image          |
|---------------------------|-----------------------|
| diagnosis,diagnostic      | diagnosis.png         |
| surgery,operation         | surgery.png           |
| radiotherapy,radiation    | radiotherapy.png      |

- **Column 1**: Event name patterns (comma-separated for multiple matches)
- **Column 2**: Icon filename (must exist in `/input/icons/` directory)

#### 2. Label Configuration (`label_configuration.xlsx`)

Maps internal column names to display labels:

| palabra/word      | label                    |
|-------------------|--------------------------|
| diagnosis_date    | Initial Diagnosis        |
| surgery_date      | Surgical Intervention    |
| treatment_start   | Treatment Begin          |

#### 3. Events Configuration (`event_configuration.xlsx`)

Defines event placement on timeline:

| upper_timeline_events | lower_timeline_events | period_events                     |
|-----------------------|-----------------------|-----------------------------------|
| diagnosis_date        | lab_test_1            | treatment_start,treatment_end     |
| surgery_date          | lab_test_2            | hospitalization_in,hospitalization_out |

- `upper_timeline_events`: Events shown above the timeline
- `lower_timeline_events`: Events shown below the timeline
- `period_events`: Period/era events (format: `start_event,end_event`)

#### 4. Rules Configuration (`rules_configuration.xlsx`)

Validation rules for highlighting problematic data (events violating rules appear in red):

| reglas/rules                                              |
|-----------------------------------------------------------|
| surgery_date > diagnosis_date                             |
| treatment_end > treatment_start                           |
| follow_up_date > treatment_end                            |

- Rules are Python expressions evaluated for each patient
- Failed validations result in red-colored event markers

## **Output Format**

The tool generates three types of output files for each patient:

### 1. SVG Files (`/output/svg/`)
- Vector format, scalable without quality loss
- Can be edited in vector graphics software
- Viewable directly in web browsers

### 2. PNG Files (`/output/png/`)
- High-resolution raster images (configurable DPI)
- Default: 2000 DPI for publication quality
- Suitable for inclusion in documents and presentations

### 3. PDF Files (`/output/pdf/`)
- Portable document format
- Preserves vector quality
- Ideal for printing and archival

### Timeline Visualization Elements

Each generated timeline includes:
- **Patient identifier** as title
- **Horizontal timeline** with date scale
- **Event markers** with icons (if configured)
- **Event labels** with dates
- **Period/era shading** (blue-tinted regions)
- **Validation indicators** (red markers for rule violations)
- **Upper and lower event rows** for organized display

## **Architecture and Processing Pipeline**

### Internal Processing Steps

1. **Data Loading**: Reads Excel file with patient data using pandas
2. **Configuration Loading**: Loads all configuration files (icons, labels, events, rules)
3. **Icon Mapping**: Associates event columns with icon files
4. **Patient Processing**: For each patient record:
   - Extracts valid date columns
   - Filters out empty/zero values
   - Calculates timeline boundaries
   - Evaluates validation rules
   - Assigns events to upper/lower positions
   - Processes period/era events
5. **Timeline Generation**: Creates SVG timeline using svgwrite library
6. **Format Conversion**: Uses Inkscape to convert SVG to PNG/PDF
7. **Output Saving**: Writes files to respective output directories

### Key Dependencies

- **pandas**: Excel file reading and data manipulation
- **openpyxl**: Excel file format support
- **svgwrite**: SVG timeline generation
- **pendulum**: Date/time parsing and handling
- **matplotlib**: Color handling
- **loguru**: Logging
- **inkscape**: SVG to PNG/PDF conversion (system dependency)
- **xvfb**: Virtual display for headless rendering

### Technical Requirements

- Python 3.12
- Inkscape (installed in Docker image)
- Xvfb for headless X11 server
- TK/TCL libraries for GUI components
- Linux-compatible fonts (Liberation, DejaVu)

## **Acknowledgements**

This tool was developed at IIS La Fe (GIBI230-IISLAFE), Valencia, Spain, as part of the EUCAIM project. It provides essential data quality verification capabilities for medical datasets by enabling visual inspection of temporal coherence and logical consistency of clinical dates.

The tool facilitates the identification of data entry errors, chronological inconsistencies, and logical impossibilities in patient timelines before data federation or analysis.

## **Legal Information**

| Software Registry           | Details                      |
|-----------------------------|------------------------------|
| **Tool Name**               | Time Coherence Tool          |
| **Version**                 | 1.1.0                        |
| **License**                 | CC-BY-NC-ND-4.0 (Custom restrictions) |
| **Authors**                 | Adrian Galiana-Bordera, Pedro Miguel Martinez-Girones |
| **Institution**             | Biomedical Imaging Research Group GIBI230 at La Fe Health Research Institute (GIBI230-IISLAFE) |
| **Contact**                 | gibi230@iislafe.es           |
| **EUCAIM Project**          | This tool is part of the European Cancer Image Platform (EUCAIM) |

### Citation

If you use this tool in your research, please cite:

```
Galiana-Bordera, A., Martinez-Girones, P.M., et al. (2025). 
Time Coherence Tool: Visual verification of chronological consistency in medical data.
IIS La Fe, Valencia, Spain. Part of the EUCAIM project.
```

### Disclaimer

This tool is provided "as is" for research and validation purposes within the EUCAIM project. It is intended to assist—not replace—manual validation and clinical decision-making. Results should be reviewed by qualified personnel. HULAFE assumes no responsibility for the legal or ethical handling of data processed with this tool.

Full responsibility lies with the Data Holder (end-user). The developers are not responsible for configuration errors, incompatibility with local datasets, or failures arising from incorrect usage.

### License Details

See [LICENSE.txt](LICENSE.txt) for complete license terms and conditions.

Key restrictions:
- **Non-commercial use only** within EUCAIM project scope
- No redistribution or commercial integration without written consent
- No modification or reverse engineering
- Attribution required for any use in European public research infrastructures

For permissions, licensing inquiries, or questions, contact:
- Email: gibi230@iislafe.es
- Additional contacts: pedromiguel_martinez@iislafe.es, adrian_galiana@iislafe.es, carina_soler@iislafe.es, luis_marti@iislafe.es
- Website: https://www.iislafe.es/en/
- ACIM: https://www.acim.lafe.san.gva.es/acim
- EUCAIM: https://cancerimage.eu/

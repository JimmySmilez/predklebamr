# PredKlebAMR: Predictive Model for Antimicrobial Resistance in *Klebsiella pneumoniae* using Artificial Intelligence and Machine Learning

## 🎗️Background
*Klebsiella*, a gram-negative bacterium, belonging to the family Enterobacteriaceae and order Enterobacterales was listed on the 2024 World Health Organization (WHO) bacterial priority pathogen list (BPPL) as a critical priority pathogen which requires urgent intervention. The third-generation cephalosporin-resistant and carbapenem-resistant Enterobacterales are listed on the BPPL because of their potential to have, inherit, and transfer resistance genes, the severity of infections and/or diseases they cause, and the significance of the global health burden caused by these infections/diseases especially in low to medium income communities (LMIC) (WHO Bacterial Priority Pathogens List, 2024).

## ⚕️Problem
The rise of antimicrobial resistance (AMR) in *Klebsiella pneumoniae*, especially to meropenem, poses a critical threat to public health globally. Researchers and healthcare practitioners are constantly on the move to combat AMR in infectious diseases especially those that have been listed as critical by WHO and are in the group of pathogens tagged ESKAPE (*Enterococcus faecium*, *Staphylococcus aureus*, *Klebsiella pneumoniae*, *Acinetobacter baumannii*, *Pseudomonas aeruginosa*, and *Enterobacter* species).

## 🧬PredKlebAMR: Klebsiella Phenotype Predictor 
PredKlebAMR is a machine-learning-powered pipeline designed to predict carbapenem resistance phenotypes in *Klebsiella pneumoniae* using whole-genome sequencing (WGS) data. By integrating `Kleborate` for genomic screening and a `Random Forest (Ranger)` model for phenotypic inference, the tool provides rapid, evidence-based phenotypic inferences and a visual dashboard for genomic surveillance.

### ✨Features
- **Automated Pipeline:** Single-script execution from raw FASTA file to phenotypic prediction.
- **ML-Driven Inference:** Uses a Random Forest model trained on 117 features to predict resistance with high confidence.
- **Interactive Dashboard:** A Shiny-based web interface for visualizing MLST, resistance genes, and OMP mutations.
- **Reproducible Environment:** Conda-based dependency management ensures the tool runs identically on any system.

## 📊Data Source and Training
The underlying model was trained using a high-quality dataset of *Klebsiella pneumoniae* isolates retrieved from the Bacterial and Viral Bioinformatics Resource Center (BV-BRC).
- **Isolates:** Selected based on matched WGS data and AST results for Meropenem. Details of these selected isolates and how they were selected can be found here [Metadata](https://github.com/omicscodeathon/klebamrmod/blob/bd94105f426780a09c5a1eaa4d7954c5a0c7631a/data/metadata_final_6000.csv), [Data Acquisition Workflow](https://github.com/omicscodeathon/klebamrmod/blob/f723ec6439fbd17c92fb20077ffa4082eefc7063/data/Data%20Acquisition%20Flowchart.png).
- **Features:** The model analyzes 117 genomic markers including MLST, acquired carbapenemases (blaKPC, blaNDM, etc.), and porin alterations (OmpK35/36), as annotated by `Kleborate`. [Kleborate Workflow](https://github.com/omicscodeathon/klebamrmod/blob/30483d0a2ae947793bbf7ccf191873f02ffdcf70/data/Galaxy-Workflow-PredKlebAMR_Kleborate_Workflow_v1.ga)

## 🧾Workflow (Methodology)
The detailed description of the entire process of data acquisition, training and testing of the model is presented in the workflow below:
![image alt](https://github.com/omicscodeathon/klebamrmod/blob/main/workflow/klebAMRmod%20Workflow.png?raw=true)

## 🚀Installation and Setup
### 🔗Live Demo: [Access the Web-based Dashboard here](https://github.com/omicscodeathon/klebamrmod)  

## 🖥️How to Run the Tool (PredKlebAMR) locally
**1. Clone the Repository**
```bash
git clone https://github.com/omicscodeathon/klebamrmod.git
cd PredKlebAMR
```
**2. Create the Conda Environment**
Ensure you have [Miniconda](https://www.anaconda.com/docs/getting-started/miniconda/main) installed.
```bash
conda env create -f environment.yml
```
**3. Run the Analysis**
The master script handles environment activation, Kleborate execution, and dashboard launching:
```bash
chmod +x PredKlebAMR_app.sh
./PredKlebAMR_app.sh
```
## 💻Usage
1. When prompted by the script, enter the full path to your assembly file (e.g., `/home/user/data/isolate_01.fasta`).
2. The script will perform genomic screening and save results to `kleb_output.txt/`.
3. The dashboard will attempt to open automatically. If it does not, manually navigate to:
     **URL:** `http://127.0.0.1:8888`

## 🛠️Technical Requirements 
- **OS:** Linux (Ubuntu recommended), macOS, or Windows (via WSL2).
- **Dependencies:** R (>= 4.3.1), Python (3.9), Kleborate (3.2.4), Ranger, Shiny, Tidyverse.
- **Browser:** Modern browser (Chrome, Firefox, or Edge). For WSL2 users, wslu is recommended for automatic browser launching.

## 📚Citations
If you use this tool, please acknowledge the foundational resources:
- **BV-BRC:** Olson RD, et al. (2023). "BV-BRC: The Bacterial and Viral Bioinformatics Resource Center." Nucleic Acids Research, 51(D1).
- **Kleborate:** Lam MMC, et al. (2021). "A genomic surveillance framework and tool for Klebsiella pneumoniae and its complex." Nature Communications, 12(1).
- **Ranger:** Wright MN, Ziegler A. (2017). "ranger: A Fast Implementation of Random Forests." Journal of Statistical Software, 77(1).

## 🤝Acknowledgement
This project was supported by:
- Institute for Genomic Medicine Research (IGMR) https://www.igmr.org
- African Society for Bioinformatics and Computational Biology (ASBCB) https://www.asbcb.org
- National Institutes of Health (NIH) Office of Data Science Strategy (ODSS) https://datascience.nih.gov/about/odss 

## ⚖️License
This project is open-source and available under the [MIT License](https://github.com/omicscodeathon/klebamrmod?tab=MIT-1-ov-file#readme).

## 📞Contact
For questions, contributions, or collaborations, please open an [issue](https://github.com/omicscodeathon/klebamrmod/issues) or contact the project lead at [Abiola Babajide](https://github.com/3880132) or the project co-lead at [James Mordecai](https://github.com/JimmySmilez)

## 👨‍👩‍👧‍👦Team
1. [Abiola Babajide](https://github.com/3880132) - **Microbiology | Data Science** - *Writer (Manuscript, GitHub), AL & ML enthusiast* - **University of the Western Cape, South Africa**
2. [James Mordecai](https://github.com/JimmySmilez) - **Microbiology | Bioinformatics** - *Microbial Bioinformatician, Bash scripter, Statistical (R) analyst, Bio-illustrator, Writer* - **King Fahd University of Petroleum and Minerals (KFUPM), Saudi Arabia**
3. [Jamilu Garba](https://github.com/Jamilu192) - **Microbiology | Vetinary Microbiology** - *Writer (Manuscript)* - **Usmanu Danfodiyo University, Nigeria**
4. [Kweku Gyasi](https://github.com/KwekuFohGyasi) - **Biochemistry** - **Kwame Nkrumah University of Science and Technology, Ghana**
5. [Maryam Iqbal](https://github.com/maryamzafar1462-maker) - **Biotechnology | Computational Vaccine Design** - **Lahore College for Women University, Pakistan**
6. [Serge Sougue](https://github.com/Sessou23) - **Molecular Biology | Molecular Genetics | Microbiology** - **Joseph KI-ZERBO University, Ouagadougou, Burkina Faso**
7. [Olaitan I. Awe](https://github.com/laitanawe) - *Member* - **Institute of Genomic Medical Research (IGMR), United States**



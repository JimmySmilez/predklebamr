# PredKlebAMR: Predictive Model for Antimicrobial Resistance in *Klebsiella pneumoniae* using Artificial Intelligence and Machine Learning

## 🎗️Background
*Klebsiella*, a gram-negative bacterium, belonging to the family Enterobacteriaceae and order Enterobacterales was listed on the 2024 World Health Organization (WHO) bacterial priority pathogen list (BPPL) as a critical priority pathogen which requires urgent intervention. The third-generation cephalosporin-resistant and carbapenem-resistant Enterobacterales are listed on the BPPL because of their potential to have, inherit, and transfer resistance genes, the severity of infections and/or diseases they cause, and the significance of the global health burden caused by these infections/diseases especially in low to medium income communities (LMIC) (WHO Bacterial Priority Pathogens List, 2024).

## ⚕️Problem
The rise of antimicrobial resistance (AMR) in *Klebsiella pneumoniae*, especially to meropenem, poses a critical threat to public health globally. Researchers and healthcare practitioners are constantly on the move to combat AMR in infectious diseases especially those that have been listed as critical by WHO and are in the group of pathogens tagged ESKAPE (*Enterococcus faecium*, *Staphylococcus aureus*, *Klebsiella pneumoniae*, *Acinetobacter baumannii*, *Pseudomonas aeruginosa*, and *Enterobacter* species).

## 🧬PredKlebAMR: Klebsiella Phenotype Predictor 
PredKlebAMR is a machine-learning-powered pipeline designed to predict meropenem-resistant phenotypes in *Klebsiella pneumoniae* using whole-genome sequencing (WGS) data. By integrating `Kleborate` for genomic screening and a `Random Forest (Ranger)` model for phenotypic inference, the tool provides rapid, evidence-based phenotypic inferences and a visual dashboard for genomic surveillance.

### ✨Features
- **Ease of Use:** The web-based version of the tool has an intuitive and user-friendly interface.
- **Automated Pipeline:** The CL-version utilizes a single-script execution from raw FASTA file to phenotypic prediction.
- **ML-Driven Inference:** Uses a Random Forest model trained on 38 features to predict resistance with high confidence.
- **Interactive Dashboard:** A Shiny-based web interface for visualizing MLST, resistance genes, and OMP mutations.
- **Reproducible Environment:** Conda-based dependency management ensures the tool runs identically on any system.

## 🚀Installation and Setup
PredKlebAMR offers users two (2) options:
1. A Web-based Dashboard, where users simply click and upload their genomic files.
2. A Command-line interface, where users can run the tool locally on their PCs. 

## 🔗Web-based Version: 
### [Access the Web-based Dashboard here](https://jimmysmilez-predklebamr.hf.space)  


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
 

## 📊Data Source and Training
The underlying model was trained using a high-quality dataset of *Klebsiella pneumoniae* isolates retrieved from the Bacterial and Viral Bioinformatics Resource Center (BV-BRC). The model analyzes 38 genomic markers including MLST, acquired carbapenemases (blaKPC, blaNDM, etc.), and porin alterations (OmpK35/36), as annotated by `Kleborate`. 

## 📚Citations
If you use this tool, please acknowledge the foundational resources:
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
For questions, contributions, or collaborations, please open an [issue](https://github.com/omicscodeathon/klebamrmod/issues) 

## 👨‍👩‍👧‍👦Team
1. [James Mordecai](https://github.com/JimmySmilez) - **Microbiology | Bioinformatics** - *Microbial Bioinformatician, Bash scripter, Statistical (R) analyst, Bio-illustrator, Writer* - **King Fahd University of Petroleum and Minerals (KFUPM), Saudi Arabia**
2. [Abiola Babajide](https://github.com/3880132) - **Microbiology | Data Science** - *Writer (Manuscript, GitHub), AL & ML enthusiast* - **University of the Western Cape, South Africa**
3. [Kweku Gyasi](https://github.com/KwekuFohGyasi) - **Biochemistry** - *Writer (Manuscript), Bio-illustrator* - **Kwame Nkrumah University of Science and Technology, Ghana**
4. [Jamilu Garba](https://github.com/Jamilu192) - **Microbiology | Vetinary Microbiology** - *Member* - **Usmanu Danfodiyo University, Nigeria**
5. [Serge Sougue](https://github.com/Sessou23) - **Molecular Biology | Molecular Genetics | Microbiology** - *Member* - **Joseph KI-ZERBO University, Ouagadougou, Burkina Faso**
6. [Olaitan I. Awe](https://github.com/laitanawe) - *Member* - **Institute of Genomic Medical Research (IGMR), United States**



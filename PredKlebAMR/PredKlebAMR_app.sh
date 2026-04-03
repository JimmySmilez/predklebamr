#!/bin/bash

# 1. Ensure we are in the script's directory
cd "$(dirname "$0")"

# 2. Set the environment name
ENV_NAME="amr_vision_env"

# 3. INITIALIZE CONDA FOR THIS SCRIPT (The "Missing Link")
# This finds where conda is installed and loads its functions
CONDA_BASE=$(conda info --base)
source "$CONDA_BASE/etc/profile.d/conda.sh"

# 4. Create environment if it doesn't exist
if { conda env list | grep "$ENV_NAME"; } >/dev/null 2>&1; then
    echo "[*] Environment '$ENV_NAME' already exists."
else
    echo "[*] Environment not found. Creating from environment.yml..."
    if [ ! -f "environment.yml" ]; then
        echo "Error: environment.yml not found in $(pwd)"
        exit 1
    fi
    conda env create -f environment.yml
fi

# 5. ACTIVATE THE ENVIRONMENT
# Now that we've sourced the conda.sh file above, this will work
echo "[*] Activating $ENV_NAME..."
conda activate "$ENV_NAME"

# 6. Verify tools are available
if ! command -v kleborate &> /dev/null; then
    echo "Error: Kleborate not found even after activation. Check your environment.yml."
    exit 1
fi

# 7. RUN THE PIPELINE
read -p "Enter path to FASTA file: " FASTA
if [ ! -f "$FASTA" ]; then
    echo "Error: FASTA file not found at $FASTA"
    exit 1
fi

echo "[*] Running Kleborate..."
TERM=dumb kleborate --preset kpsc -a "$FASTA" -o kleb_output.txt

# 4. Dashboard Phase
echo "[*] Launching Dashboard..."
echo "[*] If a browser does not open, manually go to: http://127.0.0.1:8888"

# The Browser Fix: we set options(browser) inside the R call to
# use 'xdg-open', which 'wslview' handles perfectly.
Rscript -e "options(browser = 'xdg-open'); shiny::runApp('.', launch.browser = TRUE, port = 8888)"


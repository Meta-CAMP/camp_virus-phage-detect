#!/bin/bash

# This script sets up the environment for CAMP Virus-Phage Detect by configuring databases and Conda environments.
# It performs the following tasks:
# 1. Displays a welcome message.
# 2. Asks the user if each required database is already installed or needs to be installed.
# 3. Installs the databases if needed.
# 4. Sets up the working directory.
# 5. Checks if the required Conda environments are already installed and installs them if necessary.
# 6. Generates configuration files for parameters and test data input CSV.

# Functions:
# - show_welcome: Displays a welcome message with ASCII art and setup information.
# - ask_database: Prompts the user to provide the path to an existing database or installs the database if not available.
# - install_database: Downloads and installs the specified database in the given directory.
# - check_conda_env: Checks if a specific Conda environment is already installed.

# Variables:
# - MODULE_WORK_DIR: The working directory of the module.
# - USER_WORK_DIR: The user-specified working directory.
# - SETUP_WORK_DIR: The resolved working directory.
# - DB_SUBDIRS: An associative array mapping database variable names to their subdirectory paths.
# - DATABASE_PATHS: An associative array storing the paths to the databases.
# - DEFAULT_CONDA_ENV_DIR: The default directory for Conda environments.
# - PARAMS_FILE: The path to the parameters configuration file.
# - INPUT_CSV: The path to the test data input CSV file.

# The script concludes by generating the necessary configuration files and test data input CSV, and provides instructions for testing the workflow.

# --- Functions ---

show_welcome() {
    clear  # Clear the screen for a clean look

    echo ""
    sleep 0.2
    echo " _   _      _ _          ____    _    __  __ ____           _ "
    sleep 0.2
    echo "| | | | ___| | | ___    / ___|  / \  |  \/  |  _ \ ___ _ __| |"
    sleep 0.2
    echo "| |_| |/ _ \ | |/ _ \  | |     / _ \ | |\/| | |_) / _ \ '__| |"
    sleep 0.2
    echo "|  _  |  __/ | | (_) | | |___ / ___ \| |  | |  __/  __/ |  |_|"
    sleep 0.2
    echo "|_| |_|\___|_|_|\___/   \____/_/   \_\_|  |_|_|   \___|_|  (_)"
    sleep 0.5

    echo ""
    echo "🌲🏕️  WELCOME TO CAMP SETUP! 🏕️🌲"
    echo "===================================================="
    echo ""
    echo "   🏕️  Configuring Databases & Conda Environments"
    echo "       for CAMP Virus-Phage Detection"
    echo ""
    echo "   🔥 Let's get everything set up properly!"
    echo ""
    echo "===================================================="
    echo ""

}

# Check to see if the base CAMP environment has already been installed 
find_install_camp_env() {
    if conda env list | grep -q "$DEFAULT_CONDA_ENV_DIR/camp"; then 
        echo "✅ The main CAMP environment is already installed in $DEFAULT_CONDA_ENV_DIR."
    else
        echo "🚀 Installing the main CAMP environment in $DEFAULT_CONDA_ENV_DIR/..."
        conda create --prefix "$DEFAULT_CONDA_ENV_DIR/camp" -c conda-forge -c bioconda biopython blast bowtie2 bumpversion click click-default-group cookiecutter jupyter matplotlib numpy pandas samtools scikit-learn scipy seaborn snakemake=7.32.4 umap-learn upsetplot
        echo "✅ The main CAMP environment has been installed successfully!"
    fi
}

# Check to see if the required conda environments have already been installed 
find_install_conda_env() {
    if conda env list | grep -q "$DEFAULT_CONDA_ENV_DIR/$1"; then
        echo "✅ The $1 environment is already installed in $DEFAULT_CONDA_ENV_DIR."
    else
        echo "🚀 Installing $1 in $DEFAULT_CONDA_ENV_DIR/$1..."
        if [ $1 = 'virsorter' ]; then
            conda create --prefix $DEFAULT_CONDA_ENV_DIR/virsorter -c conda-forge -c bioconda virsorter=2.2.3 last ncbi-genome-download prodigal=2.6 python=3.8 screed=1 hmmer!=3.3.1 scikit-learn=0.22.1 imbalanced-learn pandas=1.2 seaborn numpy<1.24
        elif [ $1 = 'deepvirfinder' ]; then
            conda create --prefix $DEFAULT_CONDA_ENV_DIR/deepvirfinder python=3.6 numpy theano=1.0.3 keras=2.2.4 scikit-learn Biopython h5py=2.10.0
            cd $MODULE_WORK_DIR/workflow/ext/
            git clone https://github.com/jessieren/DeepVirFinder
            cd $MODULE_WORK_DIR
        else
            conda create --prefix $DEFAULT_CONDA_ENV_DIR/$1 -c conda-forge -c bioconda $1
        fi
        echo "✅ $1 installed successfully!"
    fi
}

# Ask user if each database is already installed or needs to be installed
ask_database() {
    local DB_NAME="$1"
    local DB_VAR_NAME="$2"
    local DB_HINT="$3"
    local DB_PATH=""

    echo "🛠️  Checking for $DB_NAME database..."

    while true; do
        read -p "❓ Do you already have the $DB_NAME database installed? (y/n): " RESPONSE
        case "$RESPONSE" in
            [Yy]* )
                while true; do
                    read -p "📂 Enter the path to your existing $DB_NAME database (eg. $DB_HINT): " DB_PATH
                    if [[ -d "$DB_PATH" || -f "$DB_PATH" ]]; then
                        DATABASE_PATHS[$DB_VAR_NAME]="$DB_PATH"
                        echo "✅ $DB_NAME path set to: $DB_PATH"
                        return  # Exit the function immediately after successful input
                    else
                        echo "⚠️ The provided path does not exist or is empty. Please check and try again."
                        read -p "Do you want to re-enter the path (r) or install $DB_NAME instead (i)? (r/i): " RETRY
                        if [[ "$RETRY" == "i" ]]; then
                            break  # Exit outer loop to start installation
                        fi
                    fi
                done
                ;;
            [Nn]* )
                break # Exit outer loop to start installation
                ;; 
            * ) echo "⚠️ Please enter 'y(es)' or 'n(o)'.";;
        esac
    done
    read -p "📂 Enter the directory where you want to install the $DB_NAME database: " DB_PATH
    install_database "$DB_NAME" "$DB_VAR_NAME" "$DB_PATH"
}

# Install databases in the specified directory
install_database() {
    local DB_NAME="$1"
    local DB_VAR_NAME="$2"
    local INSTALL_DIR="$3"
    local FINAL_DB_PATH="$INSTALL_DIR/${DB_SUBDIRS[$DB_VAR_NAME]}"

    echo "🚀 Installing $DB_NAME database in: $FINAL_DB_PATH"    

    case "$DB_VAR_NAME" in
        "VIBRANT_PATH")
            conda activate vibrant
            download-db.sh $INSTALL_DIR
            mv $INSTALL_DIR/databases $FINAL_DB_PATH
            echo "✅ VIBRANT databases installed successfully!"
            conda deactivate
            ;;
        "VIRSORTER2_PATH")
            conda activate virsorter
            cd $INSTALL_DIR
            wget https://osf.io/v46sc/download
            tar -xzf $INSTALL_DIR/download
            mv $INSTALL_DIR/db $FINAL_DB_PATH
            rm $INSTALL_DIR/download
            virsorter config --init-source --db-dir=$FINAL_DB_PATH
            echo "✅ VirSorter2 database installed successfully!"
            conda deactivate
            ;;
         "GENOMAD_PATH")
            conda activate genomad
            genomad download-database $INSTALL_DIR
            echo "✅ VirSorter2 database installed successfully!"
            conda deactivate
            ;;
          "CHECKV_PATH")
            conda activate checkv
            checkv download_database $INSTALL_DIR
            echo "✅ CheckV database installed successfully!"
            conda deactivate
            ;;       
        *)
            echo "⚠️ Unknown database: $DB_NAME"
            ;;
    esac

    DATABASE_PATHS[$DB_VAR_NAME]="$FINAL_DB_PATH"
}

# --- Initialize setup ---

show_welcome

# Set working directories
MODULE_WORK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
read -p "Enter the working directory (Press Enter for default: $MODULE_WORK_DIR): " USER_WORK_DIR
SETUP_WORK_DIR="$(realpath "${USER_WORK_DIR:-$MODULE_WORK_DIR}")"
echo "Working directory set to: $SETUP_WORK_DIR"

# --- Install conda environments ---

cd $MODULE_WORK_DIR
DEFAULT_CONDA_ENV_DIR=$(conda info --base)/envs

# Find or install...

# ...module environment
find_install_camp_env

# ...auxiliary environments
MODULE_PKGS=('spades' 'vibrant' 'virsorter' 'genomad' 'checkv') # Add any additional conda packages here
for m in "${MODULE_PKGS[@]}"; do
    find_install_conda_env "$m"
done

# --- Download databases ---

# Default database locations relative to $INSTALL_DIR
declare -A DB_SUBDIRS=(
    ["VIBRANT_PATH"]="VIBRANT_db"
    ["VIRSORTER2_PATH"]="virsorter2_db"
    ["GENOMAD_PATH"]="genomad_db"
    ["CHECKV_PATH"]="checkv-db-v1.5"
)

# Absolute database paths (to be set in install_database)
declare -A DATABASE_PATHS

# Ask for all required databases
ask_database "VIBRANT" "VIBRANT_PATH" "/path/to/databases/VIBRANT_dbs"
ask_database "VirSorter2" "VIRSORTER2_PATH" "/path/to/databases/virsorter2_db/"
ask_database "geNomad" "GENOMAD_PATH" "/path/to/databases/genomad_db/"
ask_database "CheckV" "CHECKV_PATH" "/path/to/databases/checkv-db-v1.5"

echo "✅ Database and environment setup complete!"

# --- Generate parameter configs ---

# Create test_data/parameters.yaml
PARAMS_FILE="$MODULE_WORK_DIR/test_data/parameters.yaml" 

echo "🚀 Generating test_data/parameters.yaml in $PARAMS_FILE ..."

# Default values for analysis parameters
EXT_PATH="$MODULE_WORK_DIR/workflow/ext"  # Assuming extensions are in workflow/ext

# Use existing paths from DATABASE_PATHS
VIBRANT_DB="${DATABASE_PATHS[VIBRANT_PATH]}"
VIRSORTER2_DB="${DATABASE_PATHS[VIRSORTER2_PATH]}"
GENOMAD_DB="${DATABASE_PATHS[GENOMAD_PATH]}"
CHECKV_DB="${DATABASE_PATHS[CHECKV_PATH]}"

# Create test_data/parameters.yaml
cat <<EOL > "$PARAMS_FILE"
#'''Parameters config.'''#


# --- general --- #

ext: '$EXT_PATH'
conda_prefix:   '$DEFAULT_CONDA_ENV_DIR'


# --- vibrant --- #

vibrant_db: '$VIBRANT_DB'


# --- virsorter2 --- #

virsorter2_db: '$VIRSORTER2_DB'


# --- genomad --- #

genomad_db: '$GENOMAD_DB'


# --- checkv --- #

checkv_db: '$CHECKV_DB'
EOL

echo "✅ Test data configuration file created at: $PARAMS_FILE"
 
# Create configs/parameters.yaml 
PARAMS_FILE="$MODULE_WORK_DIR/configs/parameters.yaml"

cat <<EOL > "$PARAMS_FILE"
# --- general --- #

ext: '$EXT_PATH'
conda_prefix:   '$DEFAULT_CONDA_ENV_DIR'


# --- vibrant --- #

vibrant_db: '$VIBRANT_DB'


# --- virsorter2 --- #

virsorter2_db: '$VIRSORTER2_DB'


# --- genomad --- #

genomad_db: '$GENOMAD_DB'


# --- checkv --- #

checkv_db: '$CHECKV_DB'
EOL

echo "✅ Default configuration file created at: $PARAMS_FILE"

# --- Generate test data input CSV ---

# Create test_data/samples.csv
INPUT_CSV="$MODULE_WORK_DIR/test_data/samples.csv" 

echo "🚀 Generating test_data/samples.csv in $INPUT_CSV ..."

cat <<EOL > "$INPUT_CSV"
sample_name,illumina_fwd,illumina_rev
commA,$MODULE_WORK_DIR/test_data/commA_1.fastq.gz,$MODULE_WORK_DIR/test_data/commA_2.fastq.gz

EOL

echo "✅ Test data input CSV created at: $INPUT_CSV"

echo "🎯 Setup complete! You can now test the workflow using \`python $MODULE_WORK_DIR/workflow/virus_phage_detect.py test\`"


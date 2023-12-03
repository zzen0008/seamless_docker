#!/bin/bash

# Function to download a model file and place it in the appropriate subfolder
download_model() {
    local url=$1
    local folder=$2
    local file_name=$(basename "$url")

    # Check if the file already exists
    if [ -f "models/$folder/$file_name" ]; then
        echo "File $file_name already exists in models/$folder."
    else
        echo "Downloading $file_name..."
        mkdir -p "models/$folder"
        wget -q --show-progress "$url" -O "models/$folder/$file_name"
    fi
}

# Function to read YAML file and download models
download_models_from_yaml() {
    local yaml_file=$1

    # Get the number of model entries
    local num_entries=$(yq e '.model_files | length' "$yaml_file")
    # Read ignore folders from the YAML file
    local ignore_folders=($(yq e '.ignore_folders[]' "$yaml_file"))

    echo "Number of Files: $num_entries"

    # Download each model, skipping ignored folders
    for ((i = 0; i < num_entries; i++)); do
        local url=$(yq e ".model_files[$i].url" "$yaml_file")
        local folder=$(yq e ".model_files[$i].folder" "$yaml_file")

        # Check if the folder is null or not set
        if [[ -z "$folder" || "$folder" == "null" ]]; then
            echo "Error: Folder name for URL $url is not set in the YAML file."
            continue
        fi
        
        # Check if the folder is in the ignore list
        if [[ " ${ignore_folders[*]} " =~ " ${folder} " ]]; then
            echo "Skipping download for $folder as it is in the ignore list."
            continue
        fi

        download_model "$url" "$folder"
    done
}



# Function to extract and place signed up models
extract_signed_up_models() {
    local tar_file=$1
    echo "Extracting models from $tar_file..."

    # Create directories
    mkdir -p "models/seamless_expressivity"
    mkdir -p "models/vocoder_pretssel_16khz"
    mkdir -p "models/vocoder_pretssel"

    # Extract specific files to their respective directories
    tar -xvf "$tar_file" -C "models/seamless_expressivity" --strip-components=1 SeamlessExpressive/m2m_expressive_unity.pt
    tar -xvf "$tar_file" -C "models/vocoder_pretssel_16khz" --strip-components=1 SeamlessExpressive/pretssel_melhifigan_wm-16khz.pt
    tar -xvf "$tar_file" -C "models/vocoder_pretssel" --strip-components=1 SeamlessExpressive/pretssel_melhifigan_wm.pt
}


# Initialize variables for argument values
model_yaml=""
model_tar=""

# Function to print usage
print_usage() {
    echo "Usage: $0 --model_yaml path/to/model_spec.yaml [--model_tar path/to/SeamlessExpressive.tar.tar]"
}

# Parse command-line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --model_yaml) model_yaml="$2"; shift ;;
        --model_tar) model_tar="$2"; shift ;;
        *) echo "Unknown parameter passed: $1"; print_usage; exit 1 ;;
    esac
    shift
done

# Check if model_spec was provided
if [[ -z "$model_yaml" ]]; then
    echo "Error: --model_yaml is required."
    print_usage
    exit 1
fi


# Base directory for models
mkdir -p models

# Read and download models from the YAML file
download_models_from_yaml "$model_yaml"

# Check if the user provided the path to the tar file
if [ -n "$model_tar" ]; then
    # Extract and place signed up models
    extract_signed_up_models "$model_tar"

else
    # Instructions for models that require signing up
    echo "To download the 'seamless_expressivity', 'vocoder_pretssel', and 'vocoder_pretssel_16khz' models, please follow these steps:"
    echo "1. Visit https://ai.meta.com/resources/models-and-libraries/seamless-downloads/"
    echo "2. Sign up with your details."
    echo "3. You will receive an email with a link to download the 'SeamlessExpressive.tar.tar' file."
    echo "4. Download the file and extract it using 'tar -xvf SeamlessExpressive.tar.tar'."
    echo "5. Move the extracted files to the 'models/seamless_expressivity', 'models/vocoder_pretssel', and 'models/vocoder_pretssel_16khz' directories respectively."
fi
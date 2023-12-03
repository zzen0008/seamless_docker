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

# Base directory for models
mkdir -p models

# Downloading the model files
download_model "https://dl.fbaipublicfiles.com/seamless/datasets/mexpresso_text/mexpresso_text.tar" "memexpresso_text"
download_model "https://dl.fbaipublicfiles.com/nllb/NLLB-200_TWL/nllb-200_twl.zip" "mintox"
download_model "https://huggingface.co/facebook/seamless-m4t-medium/resolve/main/tokenizer.model" "mintox"
download_model "https://huggingface.co/facebook/seamless-streaming/resolve/main/spm_char_lang38_tc.model" "nar_t2u_aligner"
download_model "https://dl.fbaipublicfiles.com/seamless/models/unity2_aligner.pt" "nar_t2u_aligner"
download_model "https://huggingface.co/facebook/seamless-m4t-large/resolve/main/multitask_unity_large.pt" "seamlessM4T_large"
download_model "https://huggingface.co/facebook/seamless-m4t-medium/resolve/main/multitask_unity_medium.pt" "seamlessM4T_medium"
download_model "https://huggingface.co/facebook/seamless-m4t-v2-large/resolve/main/spm_char_lang38_tc.model" "seamlessM4T_v2_large"
download_model "https://huggingface.co/facebook/seamless-m4t-v2-large/resolve/main/seamlessM4T_v2_large.pt" "seamlessM4T_v2_large"
download_model "https://huggingface.co/facebook/seamless-streaming/resolve/main/spm_char_lang38_tc.model" "seamless_expressivity"
download_model "https://huggingface.co/facebook/seamless-streaming/resolve/main/seamless_streaming_monotonic_decoder.pt" "seamless_streaming_monotonic_decoder"
download_model "https://huggingface.co/facebook/seamless-streaming/resolve/main/spm_char_lang38_tc.model" "seamless_streaming_unity"
download_model "https://huggingface.co/facebook/seamless-streaming/resolve/main/seamless_streaming_unity.pt" "seamless_streaming_unity"
download_model "https://huggingface.co/facebook/seamless-m4t-large/resolve/main/tokenizer.model" "unity_nllb-100"
download_model "https://huggingface.co/facebook/seamless-m4t-medium/resolve/main/tokenizer.model" "unity_nllb-200"
download_model "https://huggingface.co/facebook/seamless-m4t-vocoder/resolve/main/vocoder_36langs.pt" "vocoder_36langs"
download_model "https://dl.fbaipublicfiles.com/seamless/models/vocoder_v2.pt" "vocoder_v2"
download_model "https://dl.fbaipublicfiles.com/seamlessM4T/models/unit_extraction/xlsr2_1b_v2.pt" "xlsr2_1b_v2"
download_model "https://huggingface.co/spaces/facebook/seamless-streaming/blob/main/seamless_server/models/Seamless/vad_s2st_sc_24khz_main.yaml" "Seamless"
download_model "https://huggingface.co/spaces/facebook/seamless-streaming/blob/main/seamless_server/models/SeamlessStreaming/vad_s2st_sc_main.yaml" "SeamlessStreaming"

# Check if the user provided the path to the tar file
if [ "$#" -eq 1 ]; then
    # Extract and place signed up models
    extract_signed_up_models "$1"
else
    # Instructions for models that require signing up
    echo "To download the 'seamless_expressivity', 'vocoder_pretssel', and 'vocoder_pretssel_16khz' models, please follow these steps:"
    echo "1. Visit https://ai.meta.com/resources/models-and-libraries/seamless-downloads/"
    echo "2. Sign up with your details."
    echo "3. You will receive an email with a link to download the 'SeamlessExpressive.tar.tar' file."
    echo "4. Download the file and extract it using 'tar -xvf SeamlessExpressive.tar.tar'."
    echo "5. Move the extracted files to the 'models/seamless_expressivity', 'models/vocoder_pretssel', and 'models/vocoder_pretssel_16khz' directories respectively."
fi
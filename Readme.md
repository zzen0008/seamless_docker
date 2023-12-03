# Seamless Streaming Project README

## Overview

The Seamless Streaming Project is designed to provide a minimal Docker build setup for running the Seamless model without requiring an internet connection after the initial setup. This project is particularly useful for environments with restricted internet access or where consistent connectivity cannot be guaranteed.

The provided scripts and configuration files facilitate the downloading and organization of necessary model files, which are then used by the Docker container to run the Seamless model locally.

## Prerequisites

Before proceeding with the setup, ensure that the following tools are installed on your system:

- Docker
- Git
- Git Large File Storage (LFS)
- Wget
- yq (YAML processor) - Installation instructions can be found at [yq GitHub repository](https://github.com/mikefarah/yq)

Additionally, you will need to download the `seamless-streaming` repository from Hugging Face into the project directory. It is crucial to clone the repository without downloading the large files, as they will be managed separately by the `get_seamless_model_files.sh` script.

To clone the repository without large files, use the following command:

```bash
GIT_LFS_SKIP_SMUDGE=1 git clone https://huggingface.co/spaces/facebook/seamless-streaming
```

## Setup Instructions

1. Clone the `seamless-streaming` repository from Hugging Face using the command provided in the prerequisites section.

2. Install all the required tools mentioned in the prerequisites.

3. Run the `get_seamless_model_files.sh` script to download the necessary model files as specified in the `model_files_spec.yaml`. This script will handle the downloading and organization of model files into the appropriate directories.

   ```bash
   ./get_seamless_model_files.sh --model_yaml path/to/model_files_spec.yaml [--model_tar path/to/SeamlessExpressive.tar.tar]
   ```

   If you have a tar file containing signed-up models (e.g., `SeamlessExpressive.tar.tar`), you can provide its path to the script using the `--model_tar` option.

4. Once all model files are downloaded and placed in their respective folders, you can build the Docker image using the provided `Dockerfile` and `docker-compose.yml`.

   ```bash
   docker-compose build
   ```

5. After the Docker image is built, you can run the container using the following command:

   ```bash
   docker-compose up
   ```

   The service will be available on port `7860` of your host machine.

## Notes

- The `docker-compose.yml` file is configured to mount the `models` directory from the host machine to the Docker container. Ensure that the `SEAMLESS_MODEL_PATH` environment variable in the `docker-compose.yml` file points to the correct path where the model files are stored on your host machine.

- The `ignore_folders` section in the `model_files_spec.yaml` allows you to specify any folders that should be ignored during the download process. Adjust this list as needed based on your requirements.

- The `get_seamless_model_files.sh` script includes functionality to handle downloading models, checking for existing files, and extracting signed-up models from a tar file. It also provides helpful usage instructions and error messages to guide you through the process.

By following these instructions, you should be able to set up and run the Seamless Streaming Project locally without requiring an internet connection for model operations.
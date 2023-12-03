# build frontend with node
FROM node:20-alpine AS frontend
RUN apk add --no-cache libc6-compat
WORKDIR /app

COPY seamless-streaming/streaming-react-app .
RUN \
    if [ -f yarn.lock ]; then yarn --frozen-lockfile; \
    elif [ -f package-lock.json ]; then npm ci; \
    elif [ -f pnpm-lock.yaml ]; then yarn global add pnpm && pnpm i --frozen-lockfile; \
    else echo "Lockfile not found." && exit 1; \
    fi

RUN npm run build

# build backend on CUDA 
# TODO: This base image is large (alpine will work fine)
FROM nvidia/cuda:11.8.0-cudnn8-devel-ubuntu22.04 AS backend
WORKDIR /app

ENV DEBIAN_FRONTEND=noninteractive
ENV NODE_MAJOR=20

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
    git \
    git-lfs \
    wget \
    curl \
    # python build dependencies \
    build-essential \
    libssl-dev \
    zlib1g-dev \
    libbz2-dev \
    libreadline-dev \
    libsqlite3-dev \
    libncursesw5-dev \
    xz-utils \
    tk-dev \
    libxml2-dev \
    libxmlsec1-dev \
    libffi-dev \
    liblzma-dev \
    sox libsox-fmt-all \
    # gradio dependencies \
    ffmpeg \
    # fairseq2 dependencies \
    libsndfile-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN useradd -m -u 1000 user
USER user
ENV HOME=/home/user \
    PATH=/home/user/.local/bin:$PATH
WORKDIR $HOME/app

RUN curl https://pyenv.run | bash
ENV PATH=$HOME/.pyenv/shims:$HOME/.pyenv/bin:$PATH
ARG PYTHON_VERSION=3.10.12
RUN pyenv install $PYTHON_VERSION && \
    pyenv global $PYTHON_VERSION && \
    pyenv rehash && \
    pip install --no-cache-dir -U pip setuptools wheel

COPY --chown=user:user seamless-streaming/seamless_server ./seamless_server
# change dir since pip needs to seed whl folder
# Remove the line that is looking for seamless_communication in requirements.txt
# TODO: should not need a nightly build of fairseq to run this
RUN cd seamless_server && \
    sed -i '/^-e git+https:\/\/github.com\/facebookresearch\/seamless_communication.git/d' requirements.txt && \
    pip install fairseq2 --pre --extra-index-url https://fair.pkg.atmeta.com/fairseq2/whl/nightly/pt2.1.1/cu118 && \
    pip install --no-cache-dir --upgrade -r requirements.txt
COPY --from=frontend /app/dist ./streaming-react-app/dist


## Install Local seamless_communication here
## run the patches on the cards
ENV SEAMLESS_MODEL_PATH="file:///home/user/app/seamless_server/models" 
WORKDIR $HOME/app
RUN git clone https://github.com/facebookresearch/seamless_communication.git 
RUN cd seamless_communication/src/seamless_communication/cards && \
    sed -i "/uri:/c\uri: \"${SEAMLESS_MODEL_PATH}/memexpresso_text/mexpresso_text.tar\"" mexpresso_text.yaml && \
    sed -i "/etox_dataset:/c\etox_dataset: \"${SEAMLESS_MODEL_PATH}/mintox/nllb-200_twl.zip\"" mintox.yaml && \
    sed -i "/sp_model:/c\sp_model: \"${SEAMLESS_MODEL_PATH}/mintox/tokenizer.model\"" mintox.yaml && \
    sed -i "/char_tokenizer:/c\char_tokenizer: \"${SEAMLESS_MODEL_PATH}/nar_t2u_aligner/spm_char_lang38_tc.model\"" nar_t2u_aligner.yaml && \
    sed -i "/checkpoint:/c\checkpoint: \"${SEAMLESS_MODEL_PATH}/nar_t2u_aligner/unity2_aligner.pt\"" nar_t2u_aligner.yaml && \
    sed -i "/char_tokenizer:/c\char_tokenizer: \"${SEAMLESS_MODEL_PATH}/seamless_expressivity/spm_char_lang38_tc.model\"" seamless_expressivity.yaml && \
    sed -i "/checkpoint:/c\checkpoint: \"${SEAMLESS_MODEL_PATH}/seamless_expressivity/m2m_expressive_unity.pt\"" seamless_expressivity.yaml && \
    sed -i "/checkpoint:/c\checkpoint: \"${SEAMLESS_MODEL_PATH}/seamless_streaming_monotonic_decoder/seamless_streaming_monotonic_decoder.pt\"" seamless_streaming_monotonic_decoder.yaml && \
    sed -i "/char_tokenizer:/c\char_tokenizer: \"${SEAMLESS_MODEL_PATH}/seamless_streaming_unity/spm_char_lang38_tc.model\"" seamless_streaming_unity.yaml && \
    sed -i "/checkpoint:/c\checkpoint: \"${SEAMLESS_MODEL_PATH}/seamless_streaming_unity/seamless_streaming_unity.pt\"" seamless_streaming_unity.yaml && \
    sed -i "/checkpoint:/c\checkpoint: \"${SEAMLESS_MODEL_PATH}/seamlessM4T_large/multitask_unity_large.pt\"" seamlessM4T_large.yaml && \
    sed -i "/checkpoint:/c\checkpoint: \"${SEAMLESS_MODEL_PATH}/seamlessM4T_medium/multitask_unity_medium.pt\"" seamlessM4T_medium.yaml && \
    sed -i "/char_tokenizer:/c\char_tokenizer: \"${SEAMLESS_MODEL_PATH}/seamlessM4T_v2_large/spm_char_lang38_tc.model\"" seamlessM4T_v2_large.yaml && \
    sed -i "/checkpoint:/c\checkpoint: \"${SEAMLESS_MODEL_PATH}/seamlessM4T_v2_large/seamlessM4T_v2_large.pt\"" seamlessM4T_v2_large.yaml && \
    sed -i "/tokenizer:/c\tokenizer: \"${SEAMLESS_MODEL_PATH}/unity_nllb-100/tokenizer.model\"" unity_nllb-100.yaml && \
    sed -i "/checkpoint:/c\checkpoint: \"${SEAMLESS_MODEL_PATH}/vocoder_36langs/vocoder_36langs.pt\"" vocoder_36langs.yaml && \
    sed -i "/checkpoint:/c\checkpoint: \"${SEAMLESS_MODEL_PATH}/vocoder_pretssel_16khz/pretssel_melhifigan_wm-16khz.pt\"" vocoder_pretssel_16khz.yaml && \
    sed -i "/checkpoint:/c\checkpoint: \"${SEAMLESS_MODEL_PATH}/vocoder_pretssel/pretssel_melhifigan_wm.pt\"" vocoder_pretssel.yaml && \
    sed -i "/checkpoint:/c\checkpoint: \"${SEAMLESS_MODEL_PATH}/vocoder_v2/vocoder_v2.pt\"" vocoder_v2.yaml && \
    sed -i "/checkpoint:/c\checkpoint: \"${SEAMLESS_MODEL_PATH}/xlsr2_1b_v2/xlsr2_1b_v2.pt\"" xlsr2_1b_v2.yaml 
RUN pip install $HOME/app/seamless_communication
    

WORKDIR $HOME/app/seamless_server

USER root
RUN ln -s /usr/lib/x86_64-linux-gnu/libsox.so.3 /usr/lib/x86_64-linux-gnu/libsox.so
USER user
RUN ["chmod", "+x", "./run_docker.sh"]
CMD ./run_docker.sh



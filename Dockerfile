FROM nvidia/opengl:1.2-glvnd-runtime-ubuntu20.04

SHELL ["/bin/bash", "-c"]

ENV LANG=C.UTF-8 LC_ALL=C.UTF-8 DEBIAN_FRONTEND=noninteractive TZ=Asia/Tokyo

RUN apt update -q -qq -y && \
    apt install -q -qq -y tzdata && \
    apt clean && \
    rm -rf /var/lib/apt/lists/

COPY code_1.57.1-1623937013_amd64.deb /tmp
COPY node-v14.17.3-linux-x64.tar.xz   /tmp

RUN cd /tmp && \
    apt update -q -qq -y && \
    apt install -q -qq -y gdebi && \
    apt install -q -qq -y apt-utils less emacs && \
    gdebi -n -q code_1.57.1-1623937013_amd64.deb && \
    apt clean && \
    rm -rf /var/lib/apt/lists/

RUN  (cd /tmp && mkdir -p /opt/node && tar xf node-v14.17.3-linux-x64.tar.xz --strip-components 1 -C /opt/node )

ENV PATH=$PATH:/opt/node/bin LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/node/lib

RUN npm init -y && \
    npm install -g @google/clasp && \
    npm install -g typescript && \
    npm install -g tslint

## for creating clasp.json
## clasp login --no-localhost

## cd gas_src ## root of project source directories
## npm install @types/google-apps-script --save-dev
## folder_id (yohei.kakiuchi / test) : 1JuVu1finFyw2z2NQEv2ThR8A4j--LqO1
## clasp create --title clasp-sample-project --parentId {GoogleDriveのフォルダID} --rootDir  ./clasp_sample
## clasp clone --rootDir ./src スクリプトID

## code --user-data-dir=/userdir/vscode_dir proj

## clasp pull clasp_sample
## clasp pull 
## clasp open

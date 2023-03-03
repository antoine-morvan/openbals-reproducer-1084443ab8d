#!/bin/bash -eu

[ -f $HOME/.proxy_vars.sh ] && source $HOME/.proxy_vars.sh
mkdir -p $HOME/Downloads
CACHE_DIR=$HOME/Downloads

# from https://developer.nvidia.com/nvidia-hpc-sdk-downloads
NVHPC_VERSION=${1:-22.9}

case $NVHPC_VERSION in
    22.5)
        NVHPC_LONGVERSION=2022_227
        CUDA_VERSION=11.7
        ;;
    22.7)
        NVHPC_LONGVERSION=2022_227
        CUDA_VERSION=11.7
        ;;
    22.9)
        NVHPC_LONGVERSION=2022_229
        CUDA_VERSION=11.7
        ;;
    22.11)
        NVHPC_LONGVERSION=2022_2211
        CUDA_VERSION=11.8
        ;;
    23.1)
        NVHPC_LONGVERSION=2023_231
        CUDA_VERSION=12.0
        ;;
    *) echo "Error: unsupported nvhpc version: '$NVHPC_VERSION'" && exit 1 ;;
esac

UNAMES=$(uname -s)
UNAMEM=$(uname -m)

SCRIPT_DIR=$(dirname $(readlink -f $0))

DEST=${DEST:-${SCRIPT_DIR}/../../${UNAMES}/${UNAMEM}/default/nvhpc-${NVHPC_VERSION}}
mkdir -p ${DEST}
DIR=$(readlink -f ${DEST})

PREFIX=${DIR}/prefix
mkdir -p ${PREFIX}/bin/
mkdir -p ${PREFIX}/lib/
export LD_LIBRARY_PATH=${PREFIX}/lib:${LD_LIBRARY_PATH:-}
export PATH=${PREFIX}/bin/:$PATH

NVHPC_FOLDER=nvhpc_${NVHPC_LONGVERSION}_Linux_${UNAMEM}_cuda_${CUDA_VERSION}
NVHPC_ARCHIVE=${NVHPC_FOLDER}.tar.gz
NVHPC_URL=https://developer.download.nvidia.com/hpc-sdk/${NVHPC_VERSION}/${NVHPC_ARCHIVE}
NVHPC_CACHE=${CACHE_DIR}/${NVHPC_ARCHIVE}

##########################
### NVHPC
##########################

if [ ! -f ${PREFIX}/${UNAMES}_${UNAMEM}/22.9/compilers/bin/nvc ]; then
    if [ ! -d ${DIR}/${NVHPC_FOLDER} ]; then
        if [ ! -f ${DIR}/${NVHPC_ARCHIVE} ]; then
            [ ! -f ${NVHPC_CACHE} ] && \
                echo " -- download archive $NVHPC_ARCHIVE" && \
                wget -c ${NVHPC_URL} -O ${NVHPC_CACHE}
            cp ${NVHPC_CACHE} ${DIR}/${NVHPC_ARCHIVE}
        fi
        echo " -- extract archive to folder $DIR"
        (cd ${DIR} && tar xf ${DIR}/${NVHPC_ARCHIVE})
    fi
    
    export NVHPC_SILENT=true
    export NVHPC_INSTALL_TYPE=single
    export NVHPC_INSTALL_DIR=${PREFIX}

    echo " -- setup"
    ${DIR}/${NVHPC_FOLDER}/install
else
    echo " -- Skip NVHPC ${NVHPC_VERSION}"
fi

########################
### Cleanup
########################

rm -rf ${DIR}/${NVHPC_ARCHIVE} ${DIR}/${NVHPC_FOLDER}

########################
### Setvars Script
########################

SETVARS_SCRIPT=${DIR}/setvars.sh
cat > ${SETVARS_SCRIPT} << EOF
#!/usr/bin/env bash

NVARCH=\$(uname -s)_\$(uname -m); export NVARCH
echo " -- Loading NVHPC ${NVHPC_VERSION} for \${NVARCH}"

NVCOMPILERS=${PREFIX}; export NVCOMPILERS
MANPATH=\$MANPATH:\$NVCOMPILERS/\$NVARCH/${NVHPC_VERSION}/compilers/man; export MANPATH
PATH=\$NVCOMPILERS/\$NVARCH/${NVHPC_VERSION}/compilers/bin:\$PATH; export PATH

export PATH=\$NVCOMPILERS/\$NVARCH/${NVHPC_VERSION}/comm_libs/mpi/bin:\$PATH
export MANPATH=\$MANPATH:\$NVCOMPILERS/\$NVARCH/${NVHPC_VERSION}/comm_libs/mpi/man
EOF

chmod +x ${SETVARS_SCRIPT}
echo "Done: source '${SETVARS_SCRIPT}'"
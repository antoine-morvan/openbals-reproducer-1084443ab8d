#!/bin/bash -eu

[ -f $HOME/.proxy_vars.sh ] && source $HOME/.proxy_vars.sh
mkdir -p $HOME/Downloads
CACHE_DIR=$HOME/Downloads

## Visit:
## Base Toolkit: https://www.intel.com/content/www/us/en/developer/tools/oneapi/base-toolkit-download.html
## HPC Toolkit: https://www.intel.com/content/www/us/en/developer/tools/oneapi/hpc-toolkit-download.html

SHORT_VERSION=${1:-2022.3.0}

case $SHORT_VERSION in
    2022.3.0)
        BASE_VERSION=2022.3.0.8767
        HPC_VERSION=2022.3.0.8751
        ;;
    2023.0.0)
        BASE_VERSION=2023.0.0.25537
        HPC_VERSION=2023.0.0.25400
        ;;
    *) echo "ERROR: unsupported version $SHORT_VERSION" && exit 1;;
esac

UNAMES=$(uname -s)
UNAMEM=$(uname -m)

SCRIPT_DIR=$(dirname $(readlink -f $0))

DEST=${DEST:-${SCRIPT_DIR}/../../${UNAMES}/${UNAMEM}/default/oneapi-${SHORT_VERSION}}
mkdir -p ${DEST}
DIR=$(readlink -f ${DEST})

PREFIX=${DIR}/prefix
mkdir -p ${PREFIX}

BASE_FOLDER=l_BaseKit_p_${BASE_VERSION}_offline
BASE_ARCHIVE=${BASE_FOLDER}.sh
BASE_URL=https://registrationcenter-download.intel.com/akdlm/irc_nas/18852/${BASE_ARCHIVE}
BASE_CACHE=${CACHE_DIR}/${BASE_ARCHIVE}

HPC_FOLDER=l_HPCKit_p_${HPC_VERSION}_offline
HPC_ARCHIVE=${HPC_FOLDER}.sh
HPC_URL=https://registrationcenter-download.intel.com/akdlm/irc_nas/18679/${HPC_ARCHIVE}
HPC_CACHE=${CACHE_DIR}/${HPC_ARCHIVE}

if [ ! -x ${PREFIX}/compiler/latest/linux/bin/icx ]; then
    echo "Install Base toolkit"
    if [ ! -d ${DIR}/${BASE_FOLDER} ]; then
        if [ ! -f ${DIR}/${BASE_ARCHIVE} ]; then
            [ ! -f ${BASE_CACHE} ] && wget -c ${BASE_URL} -O ${BASE_CACHE}
            cp ${BASE_CACHE} ${DIR}/${BASE_ARCHIVE}
        fi
        bash ${DIR}/${BASE_ARCHIVE} --extract-folder ${DIR}/ -x -r no
    fi
    (cd ${DIR}/${BASE_FOLDER} && ./install.sh \
        --action install \
        --silent \
        --ignore-errors \
        --eula accept \
        --install-dir ${PREFIX})
else
    echo "Skip Base toolkit"
fi

if [ ! -x ${PREFIX}/compiler/latest/linux/bin/intel64/icc ]; then
    echo "Install HPC toolkit (classic + fortran compiler)"
    if [ ! -d ${DIR}/${HPC_FOLDER} ]; then
        if [ ! -f ${DIR}/${HPC_ARCHIVE} ]; then
            [ ! -f ${HPC_CACHE} ] && wget -c ${HPC_URL} -O ${HPC_CACHE}
            cp ${HPC_CACHE} ${DIR}/${HPC_ARCHIVE}
        fi
        bash ${DIR}/${HPC_ARCHIVE} --extract-folder ${DIR}/ -x -r no
    fi
    (cd ${DIR}/${HPC_FOLDER} && ./install.sh \
        --action install \
        --silent \
        --ignore-errors \
        --eula accept \
        --install-dir ${PREFIX})

    (cd ${PREFIX} && ./modulefiles-setup.sh)
else
    echo "Skip HPC toolkit (classic + fortran compiler)"
fi

########################
### Cleanup
########################

rm -rf ${DIR}/${HPC_ARCHIVE} ${DIR}/${HPC_FOLDER}
rm -rf ${DIR}/${BASE_ARCHIVE} ${DIR}/${BASE_FOLDER}

########################
### Setvars Script
########################

SETVARS_SCRIPT=${DIR}/setvars.sh
cat > ${SETVARS_SCRIPT} << EOF
#!/usr/bin/env bash

source ${PREFIX}/setvars.sh

EOF

chmod +x ${SETVARS_SCRIPT}
echo "Done: source '${SETVARS_SCRIPT}'"
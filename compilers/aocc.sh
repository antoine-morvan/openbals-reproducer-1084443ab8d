#!/bin/bash -eu

[ -f $HOME/.proxy_vars.sh ] && source $HOME/.proxy_vars.sh
mkdir -p $HOME/Downloads
CACHE_DIR=$HOME/Downloads

AOCC_VERSION=${1:-3.2.0}

UNAMES=$(uname -s)
UNAMEM=$(uname -m)

SCRIPT_DIR=$(dirname $(readlink -f $0))

DEST=${DEST:-${SCRIPT_DIR}/../../${UNAMES}/${UNAMEM}/default/aocc-${AOCC_VERSION}}
mkdir -p ${DEST}
DIR=$(readlink -f ${DEST})

cat > ${DIR}/VERSIONS << EOF
AOCC ${AOCC_VERSION}
EOF
cat ${DIR}/VERSIONS

AOCC_FOLDER=aocc-compiler-${AOCC_VERSION}
AOCC_ARCHIVE=${AOCC_FOLDER}.tar
# AOCC_URL=https://developer.amd.com/amd-aocc/#downloads
AOCC_CACHE=${CACHE_DIR}/${AOCC_ARCHIVE}

##########################
### AOCC
##########################

if [ ! -f ${DIR}/setenv_AOCC.sh ]; then
    if [ ! -d ${DIR}/${AOCC_FOLDER} ]; then
        # no automatic download: manually fetch the archive in the cache folder
        [ ! -f ${AOCC_CACHE} ] && echo -e "\nERROR: missing '${AOCC_CACHE}'\nERROR: This file needs to be downloaded manually because of license agreement.\n" && exit 1

        [ ! -f ${DIR}/${AOCC_ARCHIVE} ] && cp ${AOCC_CACHE} ${DIR}/${AOCC_ARCHIVE}
        (cd ${DIR} && tar xf ${DIR}/${AOCC_ARCHIVE})
    fi

    (cd ${DIR}/${AOCC_FOLDER} && ./install.sh)
else
    echo " -- Skip AOCC ${AOCC_VERSION}"
fi

########################
### Cleanup
########################

rm -rf ${DIR}/${AOCC_ARCHIVE}

########################
### Setvars Script
########################

SETVARS_SCRIPT=${DIR}/setvars.sh
cat > ${SETVARS_SCRIPT} << EOF
#!/usr/bin/env bash

echo " -- Loading AOCC ${AOCC_VERSION}"

# hack to avoid undefined variable errors when sourcing following script...
export LIBRARY_PATH=${LIBRARY_PATH:-}
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH:-}
export C_INCLUDE_PATH=${C_INCLUDE_PATH:-}
export CPLUS_INCLUDE_PATH=${CPLUS_INCLUDE_PATH:-}

source ${DIR}/setenv_AOCC.sh

EOF

chmod +x ${SETVARS_SCRIPT}
echo "Done: source '${SETVARS_SCRIPT}'"
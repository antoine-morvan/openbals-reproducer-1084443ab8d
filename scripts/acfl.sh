#!/bin/bash -eu

[ -f $HOME/.proxy_vars.sh ] && source $HOME/.proxy_vars.sh
mkdir -p $HOME/Downloads
CACHE_DIR=$HOME/Downloads

ARMCLANG_VERSION=${1:-22.1}
ARMPL_VERSION=${ARMCLANG_VERSION}.0

UNAMES=$(uname -s)
UNAMEM=$(uname -m)

case $UNAMEM in
    aarch64) ;;
    *) echo "Unsupported machine $UNAMEM" && exit 1 ;;
esac

SCRIPT_DIR=$(dirname $(readlink -f $0))

DEST=${DEST:-${SCRIPT_DIR}/../../${UNAMES}/${UNAMEM}/default/acfl-${ARMCLANG_VERSION}}
mkdir -p ${DEST}
DIR=$(readlink -f ${DEST})

PREFIX=${DIR}/prefix
mkdir -p ${PREFIX}/bin/
mkdir -p ${PREFIX}/lib/
export LD_LIBRARY_PATH=${PREFIX}/lib:${LD_LIBRARY_PATH:-}
export PATH=${PREFIX}/bin/:$PATH

cat > ${DIR}/VERSIONS << EOF
ARM Compiler $ARMCLANG_VERSION
EOF
cat ${DIR}/VERSIONS

DISTRO_NAME=$(lsb_release -a |& grep -v "No LSB modules are available." |  grep Distributor | cut -d':' -f2 | xargs)
DISTRO_VERSION=$(lsb_release -a |& grep -v "No LSB modules are available." |  grep Release | cut -d':' -f2 | xargs)

case $DISTRO_NAME in
    RedHatEnterprise)
        case $DISTRO_VERSION in
            8*)
                SUFFIX=RHEL-8
                ;;
            7*)
                SUFFIX=RHEL-7
                ;;
            *) echo "Unsupported $DISTRO_NAME version: '$DISTRO_VERSION'" && exit 1 ;;
        esac
        ;;
    Ubuntu)
        case $DISTRO_VERSION in
            20.04) ;;
            18.04) ;;
            *) echo "Unsupported $DISTRO_NAME version: '$DISTRO_VERSION'" && exit 1 ;;
        esac
        SUFFIX=${DISTRO_NAME}-${DISTRO_VERSION}
        ;;
    *) echo "Unsupported distribution: '$DISTRO_NAME'" && exit 1 ;;
esac

ARMCLANG_FOLDER=arm-compiler-for-linux_${ARMCLANG_VERSION}_${SUFFIX}
ARMCLANG_ARCHIVE=${ARMCLANG_FOLDER}_${UNAMEM}.tar
ARMCLANG_URL=https://developer.arm.com/-/media/Files/downloads/hpc/arm-compiler-for-linux/${ARMCLANG_VERSION/./-}/${ARMCLANG_ARCHIVE}
ARMCLANG_CACHE=${CACHE_DIR}/${ARMCLANG_ARCHIVE}

##########################
### ARM Compiler & ARMPL
##########################

if [ ! -f ${PREFIX}/arm-linux-compiler-${ARMCLANG_VERSION}_Generic-AArch64_RHEL-8_aarch64-linux/llvm-bin/clang ]; then
    if [ ! -d ${DIR}/${ARMCLANG_FOLDER} ]; then
        if [ ! -f ${DIR}/${ARMCLANG_ARCHIVE} ]; then
            [ ! -f ${ARMCLANG_CACHE} ] && wget -c ${ARMCLANG_URL} -O ${ARMCLANG_CACHE}
            cp ${ARMCLANG_CACHE} ${DIR}/${ARMCLANG_ARCHIVE}
        fi
        (cd ${DIR} && tar xf ${DIR}/${ARMCLANG_ARCHIVE})
    fi
    (cd ${DIR}/${ARMCLANG_FOLDER} && ./${ARMCLANG_FOLDER}.sh --accept --force --install-to ${PREFIX})
else
    echo " -- Skip armclang ${ARMCLANG_VERSION}"
fi

########################
### Cleanup
########################

rm -rf ${DIR}/${ARMCLANG_ARCHIVE} ${DIR}/${ARMCLANG_FOLDER}

########################
### Setvars Script
########################

SETVARS_SCRIPT=${DIR}/setvars.sh
cat > ${SETVARS_SCRIPT} << EOF
#!/usr/bin/env bash

echo " -- Loading ARM Compiler ${ARMCLANG_VERSION}"
module use ${PREFIX}/modulefiles
module load acfl/${ARMCLANG_VERSION}

echo " -- Loading ARMPL ${ARMPL_VERSION}"
module use ${PREFIX}/moduledeps/acfl/${ARMCLANG_VERSION}/
module load armpl/${ARMPL_VERSION}

EOF

chmod +x ${SETVARS_SCRIPT}
echo "Done: source '${SETVARS_SCRIPT}'"
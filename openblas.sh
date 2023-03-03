#!/bin/bash -eu

SCRIPT_DIR=$(dirname $(readlink -f $0))

[ -f $HOME/.proxy_vars.sh ] && source $HOME/.proxy_vars.sh
CACHE_DIR=${SCRIPT_DIR}/cache
mkdir -p $CACHE_DIR

# OPENBLAS_VERSION=0.3.21
OPENBLAS_HASH=9feaaa3f395ef2ad654df9f34d2e335d2a1816c0

UNAMES=$(uname -s)
UNAMEM=$(uname -m)

COMPILER=$1
case ${COMPILER} in
    llvm-flang*|aocc*)
        source ${SCRIPT_DIR}/$UNAMES/$UNAMEM/$COMPILER/setvars.sh
        export CC=clang
        export FC=flang
        export CXX=clang++
        ;;
    llvm-*)
        source ${SCRIPT_DIR}/$UNAMES/$UNAMEM/$COMPILER/setvars.sh
        export CC=clang
        export FC=flang-new
        export CXX=clang++
        export FCFLAGS="-flang-experimental-exec"
        ;;
    acfl*)
        source ${SCRIPT_DIR}/$UNAMES/$UNAMEM/$COMPILER/setvars.sh
        export CC=armclang
        export FC=armflang
        export CXX=armclang++
        ;;
    gcc*)
        source ${SCRIPT_DIR}/$UNAMES/$UNAMEM/$COMPILER/setvars.sh
        export CC=gcc
        export FC=gfortran
        export CXX=g++
        ;;
    nvhpc*)
        source ${SCRIPT_DIR}/$UNAMES/$UNAMEM/$COMPILER/setvars.sh
        export CC=nvc
        export CXX=nvc++
        export FC=nvfortran
        ;;
    oneapi*)
        source ${SCRIPT_DIR}/$UNAMES/$UNAMEM/$COMPILER/setvars.sh
        export CC=icx
        export FC=ifx
        export CXX=icpx
        ;;
    *) echo "unsupported" && exit 1;;
esac


if [ "${OPENBLAS_VERSION:-}" == "" ]; then
    # use HASH (git commmit) instead
    OPENBLAS_VERSION=${OPENBLAS_HASH:0:7}
fi
DIR=${SCRIPT_DIR}/${UNAMES}/${UNAMEM}/openblas-${OPENBLAS_VERSION}_${COMPILER}
mkdir -p $DIR
PREFIX=${DIR}/prefix

########################
### OpenBLAS
########################


if [ "${OPENBLAS_HASH:-}" != "" ]; then
    # use HASH (git commmit) instead
    OPENBLAS_DIR=OpenBLAS-${OPENBLAS_HASH}
    OPENBLAS_ARCHIVE=OpenBLAS-${OPENBLAS_HASH}.tar.gz
    OPENBLAS_URL=https://github.com/xianyi/OpenBLAS/archive/${OPENBLAS_HASH}.tar.gz
else
    OPENBLAS_DIR=OpenBLAS-${OPENBLAS_VERSION}
    OPENBLAS_ARCHIVE=${OPENBLAS_DIR}.tar.gz
    OPENBLAS_URL=https://github.com/xianyi/OpenBLAS/releases/download/v${OPENBLAS_VERSION}/${OPENBLAS_ARCHIVE}
fi
OPENBLAS_CACHE=${CACHE_DIR}/${OPENBLAS_ARCHIVE}

echo "Extract & Build OpenBLAS"
if [ ! -d ${DIR}/${OPENBLAS_DIR} ]; then
    if [ ! -f ${DIR}/${OPENBLAS_ARCHIVE} ]; then
        [ ! -f ${OPENBLAS_CACHE} ] && wget -c ${OPENBLAS_URL} -O ${OPENBLAS_CACHE}
        cp ${OPENBLAS_CACHE} ${DIR}/${OPENBLAS_ARCHIVE}
    fi
    (cd ${DIR} && tar xf ${DIR}/${OPENBLAS_ARCHIVE})
fi

BUILDIR=${DIR}/build/

rm -rf ${BUILDIR}
mkdir -p ${BUILDIR}

(cd ${BUILDIR} && cmake \
    -DCMAKE_C_FLAGS="-Wno-int-conversion" \
    ${DIR}/${OPENBLAS_DIR} )

(cd ${BUILDIR} && make -j $(nproc))


echo ""
echo " -- ulimit -s unlimited"
ulimit -s unlimited
echo ""

(cd ${BUILDIR} && make -j $(nproc) test)

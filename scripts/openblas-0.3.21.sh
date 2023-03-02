#!/bin/bash -eu

SCRIPT_DIR=$(dirname $(readlink -f $0))

[ -f $HOME/.proxy_vars.sh ] && source $HOME/.proxy_vars.sh
CACHE_DIR=${SCRIPT_DIR}/cache
mkdir -p $CACHE_DIR

OPENBLAS_VERSION=0.3.21

UNAMES=$(uname -s)
UNAMEM=$(uname -m)

COMPILER=$1
case ${COMPILER} in
    llvm-*)
        source ${SCRIPT_DIR}/$UNAMES/$UNAMEM/$COMPILER/setvars.sh
        export CC=clang
        export FC=flang
        export CXX=clang++
        ;;
    *) echo "unsupported" && exit 1;;
esac

DIR=${SCRIPT_DIR}/${UNAMES}/${UNAMEM}/openblas-${OPENBLAS_VERSION}_${COMPILER}
mkdir -p $DIR
PREFIX=${DIR}/prefix

########################
### OpenBLAS
########################

OPENBLAS_DIR=OpenBLAS-${OPENBLAS_VERSION}
OPENBLAS_ARCHIVE=${OPENBLAS_DIR}.tar.gz
OPENBLAS_URL=https://github.com/xianyi/OpenBLAS/releases/download/v${OPENBLAS_VERSION}/${OPENBLAS_ARCHIVE}
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
    -DNO_LAPACKE=ON \
    ${DIR}/${OPENBLAS_DIR} )

set +eu
(cd ${BUILDIR} && make -j $(nproc))
set -eu
(cd ${BUILDIR} && make)
(cd ${BUILDIR} && make -j $(nproc) test)
# (cd ${BUILDIR} && make -j $(nproc) install PREFIX=$PREFIX)
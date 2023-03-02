#!/bin/bash -eu



COMPILER=${1:-llvm-flang:15x}

COMPILER_NAME=$(echo $COMPILER | cut -d':' -f1)
COMPILER_VERSION=$(echo $COMPILER | cut -d':' -f2)

# install compiler if not present
DEST=$(uname -s)/$(uname -m)/${COMPILER_NAME}-${COMPILER_VERSION} ./compilers/${COMPILER_NAME}.sh ${COMPILER_VERSION} |& tee ${COMPILER_NAME}-${COMPILER_VERSION}_$(uname -m)_01-compiler.log

# reproduce cmake build & test
DEST=$(uname -s)/$(uname -m)/openblas_${COMPILER_NAME}-${COMPILER_VERSION} ./openblas-0.3.21.sh ${COMPILER_NAME}-${COMPILER_VERSION} |& tee ${COMPILER_NAME}-${COMPILER_VERSION}_$(uname -m)_02-openblas.log
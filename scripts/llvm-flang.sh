#!/bin/bash -eu

[ -f $HOME/.proxy_vars.sh ] && source $HOME/.proxy_vars.sh
mkdir -p $HOME/Downloads
CACHE_DIR=$HOME/Downloads

LLVM_VERSION=${1:-15x}
# alwasy take latest version of the frontend
FLANG_VERSION=20221103

UNAMES=$(uname -s)
UNAMEM=$(uname -m)

SCRIPT_DIR=$(dirname $(readlink -f $0))

DEST=${DEST:-${SCRIPT_DIR}/../../${UNAMES}/${UNAMEM}/default/llvm-flang-${LLVM_VERSION}}
mkdir -p ${DEST}
DIR=$(readlink -f ${DEST})

PREFIX=${DIR}/prefix
mkdir -p ${PREFIX}/bin/
mkdir -p ${PREFIX}/lib/
export LD_LIBRARY_PATH=${PREFIX}/lib:${LD_LIBRARY_PATH:-}
export PATH=${PREFIX}/bin/:$PATH

function nproc_mem() {
    # 2048 MB allocated per job
    MAX_MB_BUILD_JOB=${1:-2048}
    FREE_MEM_MB=$(free --mega | grep Mem | xargs | cut -d' ' -f4)
    MAX_JOBS=$((FREE_MEM_MB / MAX_MB_BUILD_JOB))
    MAX_JOBS=$(echo -e "$MAX_JOBS\n$(nproc)" | sort -n | head -n 1)
    [ $MAX_JOBS == 0 ] && MAX_JOBS=1
    echo $MAX_JOBS
}

## READ
## https://github.com/flang-compiler/flang/wiki/Building-Flang

########################
## LLVM FLANG
########################

LLVM_FLANG_VERSION=${LLVM_VERSION}
LLVM_FLANG_FOLDER=classic-flang-llvm-project-release_${LLVM_FLANG_VERSION}
LLVM_FLANG_ARCHIVE=release_${LLVM_FLANG_VERSION}.tar.gz
LLVM_FLANG_URL=https://github.com/flang-compiler/classic-flang-llvm-project/archive/refs/heads/${LLVM_FLANG_ARCHIVE}
LLVM_FLANG_CACHE=${CACHE_DIR}/${LLVM_FLANG_ARCHIVE}

BUILD_DIR_LLVM_FLANG=${DIR}/build_llvm_flang
BUILD_DIR_LIBPGMATH=${DIR}/build_libpgmath
BUILD_DIR_FLANG=${DIR}/build_flang

if [ ! -f ${PREFIX}/bin/clang ]; then
    echo "Extract & Build LLVM FLANG"
    if [ ! -d ${DIR}/${LLVM_FLANG_FOLDER} ]; then
        if [ ! -f ${DIR}/${LLVM_FLANG_ARCHIVE} ]; then
            [ ! -f ${LLVM_FLANG_CACHE} ] && wget -c ${LLVM_FLANG_URL} -O ${LLVM_FLANG_CACHE}
            echo " -- copy"
            cp ${LLVM_FLANG_CACHE} ${DIR}/${LLVM_FLANG_ARCHIVE}
        fi
        echo " -- extract"
        (cd ${DIR} && tar xf ${DIR}/${LLVM_FLANG_ARCHIVE})
    fi
    mkdir -p ${BUILD_DIR_LLVM_FLANG}
        
    [ ! -f ${BUILD_DIR_LLVM_FLANG}/Makefile ] && (cd ${BUILD_DIR_LLVM_FLANG} && cmake \
        -DLLVM_INSTALL_UTILS=ON \
        -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
        -DCMAKE_CXX_STANDARD=17 \
        -DCMAKE_CXX_LINK_FLAGS="-Wl,-rpath,$LD_LIBRARY_PATH" \
        -DLLVM_ENABLE_ASSERTIONS=ON \
        -DLLVM_TARGETS_TO_BUILD=host \
        -DLLVM_LIT_ARGS=-v \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=${PREFIX} \
        -DLLVM_ENABLE_PROJECTS="clang;openmp" \
        -DLLVM_ENABLE_CLASSIC_FLANG=ON \
        -G "Unix Makefiles" ${DIR}/${LLVM_FLANG_FOLDER}/llvm)
    (cd ${BUILD_DIR_LLVM_FLANG} && make -j $(nproc_mem) )
    (cd ${BUILD_DIR_LLVM_FLANG} && make -j $(nproc_mem) install)
else
    echo "Skip LLVM FLANG"
fi

########################
## FLANG
########################

FLANG_FOLDER=flang-flang_${FLANG_VERSION}
FLANG_ARCHIVE=flang_${FLANG_VERSION}.tar.gz
FLANG_URL=https://github.com/flang-compiler/flang/archive/refs/tags/${FLANG_ARCHIVE}
FLANG_CACHE=${CACHE_DIR}/${FLANG_ARCHIVE}


if [ ! -f ${PREFIX}/bin/flang2 ]; then
    echo "Extract & Build FLANG"
    if [ ! -d ${DIR}/${FLANG_FOLDER} ]; then
        if [ ! -f ${DIR}/${FLANG_ARCHIVE} ]; then
            [ ! -f ${FLANG_CACHE} ] && wget -c ${FLANG_URL} -O ${FLANG_CACHE}
            echo " -- copy"
            cp ${FLANG_CACHE} ${DIR}/${FLANG_ARCHIVE}
        fi
        echo " -- extract to '$DIR'"
        (cd ${DIR} && tar xf ${DIR}/${FLANG_ARCHIVE})
    fi

    if [ ! -f ${PREFIX}/lib/libpgmath.so ]; then
        echo "Build libpgmath"
        mkdir -p ${BUILD_DIR_LIBPGMATH}
        [ ! -f ${BUILD_DIR_LIBPGMATH}/Makefile ] && (cd ${BUILD_DIR_LIBPGMATH} && cmake \
                -DCMAKE_INSTALL_PREFIX=${PREFIX} \
                -DCMAKE_CXX_COMPILER=${PREFIX}/bin/clang++ \
                -DCMAKE_C_COMPILER=${PREFIX}/bin/clang \
            ${DIR}/${FLANG_FOLDER}/runtime/libpgmath)
        (cd ${BUILD_DIR_LIBPGMATH} && make -j $(nproc_mem))
        (cd ${BUILD_DIR_LIBPGMATH} && make -j $(nproc_mem) install)
    else
        echo "Skip libpgmath"
    fi
    
    mkdir -p ${BUILD_DIR_FLANG}
    export CXXFLAGS="-O2 -w"
    export CFLAGS=$CXXFLAGS
    [ ! -f ${BUILD_DIR_FLANG}/Makefile ] && (cd ${BUILD_DIR_FLANG} && cmake \
            -DCMAKE_INSTALL_PREFIX=${PREFIX} \
        -DCMAKE_BUILD_TYPE="None" \
        -DCMAKE_CXX_FLAGS="$CXXFLAGS" \
        -DCMAKE_C_FLAGS="$CFLAGS" \
            -DLLVM_CONFIG=${PREFIX}/bin/llvm-config \
            -DCMAKE_CXX_COMPILER=${PREFIX}/bin/clang++ \
            -DCMAKE_C_COMPILER=${PREFIX}/bin/clang \
            -DCMAKE_Fortran_COMPILER=${PREFIX}/bin/flang \
            -DCMAKE_Fortran_COMPILER_ID=Flang \
            -DLLVM_TARGETS_TO_BUILD=host \
         ${DIR}/${FLANG_FOLDER})
    (cd ${BUILD_DIR_FLANG} && make -j $(nproc_mem))
    (cd ${BUILD_DIR_FLANG} && make -j $(nproc_mem) install) 
else
    echo "Skip FLANG"
fi

########################
### Cleanup
########################

rm -rf ${DIR}/${LLVM_FLANG_ARCHIVE} ${DIR}/${LLVM_FLANG_FOLDER}
rm -rf ${DIR}/${FLANG_ARCHIVE} ${DIR}/${FLANG_FOLDER}
rm -rf ${BUILD_DIR_FLANG} ${BUILD_DIR_LIBPGMATH} ${BUILD_DIR_LLVM_FLANG}

########################
### Setvars Script
########################

SETVARS_SCRIPT=${DIR}/setvars.sh
cat > ${SETVARS_SCRIPT} << EOF
#!/usr/bin/env bash

echo " -- Loading LLVM Flang $LLVM_VERSION"

export LLVM_HOME=${PREFIX}

export PATH=\${LLVM_HOME}/bin:\${LLVM_HOME}/libexec:\$PATH
export LD_LIBRARY_PATH=\${LLVM_HOME}/lib:\${LLVM_HOME}/libexec:\${LD_LIBRARY_PATH:-}
EOF

chmod +x ${SETVARS_SCRIPT}
echo "Done: source '${SETVARS_SCRIPT}'"
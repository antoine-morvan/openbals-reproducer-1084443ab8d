#!/bin/bash -eu

SCRIPT_DIR=$(dirname $(readlink -f $0))

[ -f $HOME/.proxy_vars.sh ] && source $HOME/.proxy_vars.sh
CACHE_DIR=${SCRIPT_DIR}/cache
mkdir -p $CACHE_DIR

LLVM_VERSION=${1:-15.0.3}

UNAMES=$(uname -s)
UNAMEM=$(uname -m)

DIR=${SCRIPT_DIR}/${UNAMES}/${UNAMEM}/llvm-${LLVM_VERSION}
mkdir -p $DIR

PREFIX=${DIR}/prefix
mkdir -p ${PREFIX}/bin/
mkdir -p ${PREFIX}/lib/
export LD_LIBRARY_PATH=${PREFIX}/lib:${LD_LIBRARY_PATH:-}
export PATH=${PREFIX}/bin/:$PATH

MAX_MB_BUILD_JOB=2048
FREE_MEM_MB=$(free --mega | grep Mem | xargs | cut -d' ' -f4)
MAX_JOBS=$((FREE_MEM_MB / MAX_MB_BUILD_JOB))
MAX_JOBS=$(echo -e "$MAX_JOBS\n$(nproc)" | sort -n | head -n 1)

########################
### LLVM
########################

LLVM_FOLDER=llvm-project-${LLVM_VERSION}.src
LLVM_ARCHIVE=${LLVM_FOLDER}.tar.xz
LLVM_URL=https://github.com/llvm/llvm-project/releases/download/llvmorg-${LLVM_VERSION}/${LLVM_ARCHIVE}
LLVM_CACHE=${CACHE_DIR}/${LLVM_ARCHIVE}

if [ ! -f ${PREFIX}/bin/clang ]; then
    echo "Extract & Build LLVM"
    if [ ! -d ${DIR}/${LLVM_FOLDER} ]; then
        if [ ! -f ${DIR}/${LLVM_ARCHIVE} ]; then
            [ ! -f ${LLVM_CACHE} ] && wget -c ${LLVM_URL} -O ${LLVM_CACHE}
            echo " -- copy"
            cp ${LLVM_CACHE} ${DIR}/${LLVM_ARCHIVE}
        fi
        echo " -- extract"
        set -x
        (cd ${DIR} && tar xf ${DIR}/${LLVM_ARCHIVE})
    fi
    BUILD_DIR=${DIR}/build
    rm -rf ${BUILD_DIR}
    mkdir -p ${BUILD_DIR}
    
    [ ! -f ${BUILD_DIR}/Makefile ] && (cd ${BUILD_DIR} && cmake \
        -DLLVM_INSTALL_UTILS=ON \
        -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
        -DCMAKE_CXX_STANDARD=17 \
        -DCMAKE_CXX_LINK_FLAGS="-Wl,-rpath,$LD_LIBRARY_PATH" \
        -DFLANG_ENABLE_WERROR=OFF \
        -DLLVM_ENABLE_ASSERTIONS=ON \
        -DLLVM_TARGETS_TO_BUILD=host \
        -DLLVM_LIT_ARGS=-v \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=${PREFIX} \
        -DLLVM_ENABLE_ASSERTIONS=ON \
        -DLLVM_ENABLE_PROJECTS="clang;openmp" \
        -DLLVM_ENABLE_RUNTIMES="compiler-rt" \
        -G "Unix Makefiles" ${DIR}/${LLVM_FOLDER}/llvm)
        
    (cd ${BUILD_DIR} && make -j ${MAX_JOBS} )
    (cd ${BUILD_DIR} && make -j ${MAX_JOBS} install)
else
    echo "Skip LLVM"
fi

########################
### Setvars Script
########################

SETVARS_SCRIPT=${DIR}/setvars.sh
cat > ${SETVARS_SCRIPT} << EOF
#!/usr/bin/env bash

echo " -- Loading LLVM $LLVM_VERSION"

export LLVM_HOME=${PREFIX}

export PATH=\${LLVM_HOME}/bin:\$PATH
export LD_LIBRARY_PATH=\${LLVM_HOME}/lib:\${LLVM_HOME}/lib64:\${LD_LIBRARY_PATH:-}
EOF

chmod +x ${SETVARS_SCRIPT}
echo "Done: source '${SETVARS_SCRIPT}'"
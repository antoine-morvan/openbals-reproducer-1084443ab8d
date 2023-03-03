#!/bin/bash -eu

[ -f $HOME/.proxy_vars.sh ] && source $HOME/.proxy_vars.sh
mkdir -p $HOME/Downloads
CACHE_DIR=$HOME/Downloads

GCC_VERSION=${1:-12.2.0}

UNAMES=$(uname -s)
UNAMEM=$(uname -m)

BUILD_HOST=$(gcc -dumpmachine)
SCRIPT_DIR=$(dirname $(readlink -f $0))

DEST=${DEST:-${SCRIPT_DIR}/../../${UNAMES}/${UNAMEM}/default/gcc-${GCC_VERSION}}
mkdir -p ${DEST}
DIR=$(readlink -f ${DEST})

PREFIX=${DIR}/prefix
mkdir -p ${PREFIX}/bin/
mkdir -p ${PREFIX}/lib/
export LD_LIBRARY_PATH=${PREFIX}/lib:${LD_LIBRARY_PATH:-}
export PATH=${PREFIX}/bin/:$PATH

case $UNAMEM in
    x86_64)
        TARGET="x86_64-pc-linux-gnu"
        ;;
    aarch64)
        TARGET="aarch64-pc-linux-gnu"
        ;;
    *)
        echo "ERROR: unsupported machine $UNAMEM"
        exit 1
        ;;
esac

cat > ${DIR}/VERSIONS << EOF
Target: ${UNAMEM}
GCC ${GCC_VERSION}
EOF
cat ${DIR}/VERSIONS

# BINUTILS_VERSION=2.39
# BINUTILS_FOLDER=binutils-${BINUTILS_VERSION}
# BINUTILS_ARCHIVE=${BINUTILS_FOLDER}.tar.xz
# BINUTILS_URL=https://ftp.gnu.org/gnu/binutils/${BINUTILS_ARCHIVE}
# BINUTILS_CACHE=${CACHE_DIR}/${BINUTILS_ARCHIVE}

BINUTILS_VERSION=2.40
BINUTILS_FOLDER=binutils-${BINUTILS_VERSION}
BINUTILS_ARCHIVE=${BINUTILS_FOLDER}.tar.xz
BINUTILS_URL=https://mirror.ibcp.fr/pub/gnu/binutils/${BINUTILS_ARCHIVE}
BINUTILS_CACHE=${CACHE_DIR}/${BINUTILS_ARCHIVE}


TEXINFO_VERSION=6.7
TEXINFO_FOLDER=texinfo-${TEXINFO_VERSION}
TEXINFO_ARCHIVE=${TEXINFO_FOLDER}.tar.xz
TEXINFO_URL=https://ftp.gnu.org/gnu/texinfo/${TEXINFO_ARCHIVE}
TEXINFO_CACHE=${CACHE_DIR}/${TEXINFO_ARCHIVE}

GMP_VERSION=6.2.1
GMP_FOLDER=gmp-${GMP_VERSION}
GMP_ARCHIVE=${GMP_FOLDER}.tar.xz
GMP_URL=https://gmplib.org/download/gmp/${GMP_ARCHIVE}
GMP_CACHE=${CACHE_DIR}/${GMP_ARCHIVE}

MPFR_VERSION=4.1.0
MPFR_FOLDER=mpfr-${MPFR_VERSION}
MPFR_ARCHIVE=${MPFR_FOLDER}.tar.xz
MPFR_URL=https://www.mpfr.org/mpfr-current/${MPFR_ARCHIVE}
MPFR_CACHE=${CACHE_DIR}/${MPFR_ARCHIVE}

MPC_VERSION=1.2.0
MPC_FOLDER=mpc-${MPC_VERSION}
MPC_ARCHIVE=${MPC_FOLDER}.tar.gz
MPC_URL=https://ftp.gnu.org/gnu/mpc/${MPC_ARCHIVE}
MPC_CACHE=${CACHE_DIR}/${MPC_ARCHIVE}

GCC_FOLDER=gcc-${GCC_VERSION}
GCC_ARCHIVE=${GCC_FOLDER}.tar.gz
GCC_URL=https://ftp.gnu.org/gnu/gcc/${GCC_FOLDER}/${GCC_ARCHIVE}
GCC_CACHE=${CACHE_DIR}/${GCC_ARCHIVE}

#cleanup
# (cd ${DIR} && rm -rf ${PREFIX} ${BINUTILS_FOLDER} ${TEXINFO_FOLDER} ${GMP_FOLDER} ${MPFR_FOLDER} ${MPC_FOLDER} ${GCC_FOLDER} ${OPENBLAS_DIR} ${OPENMPI_FOLDER})
# exit


########################
### BinUtils
########################

########################
### GCC - deps (GMP, MPC, MPFR)
########################

if [ ! -f ${PREFIX}/bin/texi2pdf ]; then
    echo "Extract & Build TexInfo"
    if [ ! -d ${DIR}/${TEXINFO_FOLDER} ]; then
        if [ ! -f ${DIR}/${TEXINFO_ARCHIVE} ]; then
            [ ! -f ${TEXINFO_CACHE} ] && wget -c ${TEXINFO_URL} -O ${TEXINFO_CACHE}
            cp ${TEXINFO_CACHE} ${DIR}/${TEXINFO_ARCHIVE}
        fi
        (cd ${DIR} && tar xf ${DIR}/${TEXINFO_ARCHIVE})
    fi
    [ ! -f ${DIR}/${TEXINFO_FOLDER}/Makefile ] && (cd ${DIR}/${TEXINFO_FOLDER} && \
        ./configure \
            --prefix=${PREFIX})
    (cd ${DIR}/${TEXINFO_FOLDER} && make -j $(nproc))
    (cd ${DIR}/${TEXINFO_FOLDER} && make -j $(nproc) install)
else
    echo "Skip TexInfo"
fi

if [ ! -f ${PREFIX}/lib/libgmp.so.10.4.1 ]; then
    echo "Extract & Build GMP"
    if [ ! -d ${DIR}/${GMP_FOLDER} ]; then
        if [ ! -f ${DIR}/${GMP_ARCHIVE} ]; then
            [ ! -f ${GMP_CACHE} ] && wget -c ${GMP_URL} -O ${GMP_CACHE}
            cp ${GMP_CACHE} ${DIR}/${GMP_ARCHIVE}
        fi
        (cd ${DIR} && tar xf ${DIR}/${GMP_ARCHIVE})
    fi
    [ ! -f ${DIR}/${GMP_FOLDER}/Makefile ] && (cd ${DIR}/${GMP_FOLDER} && \
        ./configure \
            --target=${UNAMEM}-pc-linux-gnu \
            --build=${UNAMEM}-pc-linux-gnu \
            --host=${UNAMEM}-pc-linux-gnu \
            --prefix=${PREFIX})
    (cd ${DIR}/${GMP_FOLDER} && make -j $(nproc))
    (cd ${DIR}/${GMP_FOLDER} && make -j $(nproc) install)
else
    echo "Skip GMP"
fi
if [ ! -f ${PREFIX}/lib/libmpfr.so.6.1.0 ]; then
    echo "Extract & Build MPFR"
    if [ ! -d ${DIR}/${MPFR_FOLDER} ]; then
        if [ ! -f ${DIR}/${MPFR_ARCHIVE} ]; then
            [ ! -f ${MPFR_CACHE} ] && wget -c ${MPFR_URL} -O ${MPFR_CACHE}
            cp ${MPFR_CACHE} ${DIR}/${MPFR_ARCHIVE}
        fi
        (cd ${DIR} && tar xf ${DIR}/${MPFR_ARCHIVE})
    fi
    [ ! -f ${DIR}/${MPFR_FOLDER}/Makefile ] && (cd ${DIR}/${MPFR_FOLDER} && \
        ./configure \
            --target=${UNAMEM}-pc-linux-gnu \
            --build=${UNAMEM}-pc-linux-gnu \
            --host=${UNAMEM}-pc-linux-gnu \
            --with-gmp=${PREFIX} \
            --prefix=${PREFIX})
    (cd ${DIR}/${MPFR_FOLDER} && make -j $(nproc))
    (cd ${DIR}/${MPFR_FOLDER} && make -j $(nproc) install)
else
    echo "Skip MPFR"
fi


if [ ! -f ${PREFIX}/lib/libmpc.so.3.2.0 ]; then
    echo "Extract & Build MPC"
    if [ ! -d ${DIR}/${MPC_FOLDER} ]; then
        if [ ! -f ${DIR}/${MPC_ARCHIVE} ]; then
            [ ! -f ${MPC_CACHE} ] && wget -c ${MPC_URL} -O ${MPC_CACHE}
            cp ${MPC_CACHE} ${DIR}/${MPC_ARCHIVE}
        fi
        (cd ${DIR} && tar xf ${DIR}/${MPC_ARCHIVE})
    fi
    [ ! -f ${DIR}/${MPC_FOLDER}/Makefile ] && (cd ${DIR}/${MPC_FOLDER} && \
        ./configure \
            --target=${UNAMEM}-pc-linux-gnu \
            --build=${UNAMEM}-pc-linux-gnu \
            --host=${UNAMEM}-pc-linux-gnu \
            --with-gmp=${PREFIX} \
            --with-mpfr=${PREFIX} \
            --prefix=${PREFIX})
    (cd ${DIR}/${MPC_FOLDER} && make -j $(nproc))
    (cd ${DIR}/${MPC_FOLDER} && make -j $(nproc) install)
else
    echo "Skip MPC"
fi


if [ ! -f ${PREFIX}/bin/ar ]; then
    echo "Extract & Build BinUtils"
    if [ ! -d ${DIR}/${BINUTILS_FOLDER} ]; then
        if [ ! -f ${DIR}/${BINUTILS_ARCHIVE} ]; then
            [ ! -f ${BINUTILS_CACHE} ] && wget -c ${BINUTILS_URL} -O ${BINUTILS_CACHE}
            cp ${BINUTILS_CACHE} ${DIR}/${BINUTILS_ARCHIVE}
        fi
        (cd ${DIR} && tar xf ${DIR}/${BINUTILS_ARCHIVE})
    fi
    [ ! -f ${DIR}/${BINUTILS_FOLDER}/Makefile ] && (cd ${DIR}/${BINUTILS_FOLDER} && \
        ./configure \
            --target=${UNAMEM}-pc-linux-gnu \
            --build=${UNAMEM}-pc-linux-gnu \
            --host=${UNAMEM}-pc-linux-gnu \
            --prefix=${PREFIX})
    (cd ${DIR}/${BINUTILS_FOLDER} && make -j $(nproc))
    (cd ${DIR}/${BINUTILS_FOLDER} && make -j $(nproc) install)
else
    echo "Skip BinUtils"
fi


########################
### GCC
########################

if [ ! -f ${PREFIX}/bin/gcc ]; then
    echo "Extract & Build GCC"
    if [ ! -d ${DIR}/${GCC_FOLDER} ]; then
        if [ ! -f ${DIR}/${GCC_ARCHIVE} ]; then
            [ ! -f ${GCC_CACHE} ] && wget -c ${GCC_URL} -O ${GCC_CACHE}
            cp ${GCC_CACHE} ${DIR}/${GCC_ARCHIVE}
        fi
        (cd ${DIR} && tar xf ${DIR}/${GCC_ARCHIVE})
    fi
    [ ! -f ${DIR}/${GCC_FOLDER}/Makefile ] && (cd ${DIR}/${GCC_FOLDER} && \
        ./configure \
           --host=${UNAMEM}-pc-linux-gnu \
           --build=${UNAMEM}-pc-linux-gnu \
           --target=${UNAMEM}-pc-linux-gnu \
            --disable-multilib \
            --with-gmp=${PREFIX} \
            --with-mpfr=${PREFIX} \
            --with-mpc=${PREFIX} \
            --prefix=${PREFIX})
    (cd ${DIR}/${GCC_FOLDER} && make -j $(nproc))
    (cd ${DIR}/${GCC_FOLDER} && make -j $(nproc) install)
else
    echo "Skip GCC"
fi
########################
### Cleanup
########################

rm -rf ${DIR}/${BINUTILS_ARCHIVE} ${DIR}/${BINUTILS_FOLDER}
rm -rf ${DIR}/${GCC_ARCHIVE} ${DIR}/${GCC_FOLDER}
rm -rf ${DIR}/${MPFR_ARCHIVE} ${DIR}/${MPFR_FOLDER}
rm -rf ${DIR}/${MPC_ARCHIVE} ${DIR}/${MPC_FOLDER}
rm -rf ${DIR}/${BINUTILS_ARCHIVE} ${DIR}/${BINUTILS_FOLDER}
rm -rf ${DIR}/${TEXINFO_ARCHIVE} ${DIR}/${TEXINFO_FOLDER}
rm -rf ${DIR}/${GMP_ARCHIVE} ${DIR}/${GMP_FOLDER}

########################
### Setvars Script
########################

SETVARS_SCRIPT=${DIR}/setvars.sh
cat > ${SETVARS_SCRIPT} << EOF
#!/usr/bin/env bash

echo " -- Loading GCC ${GCC_VERSION}"

export PATH=${PREFIX}/bin:\$PATH
export LD_LIBRARY_PATH=${PREFIX}/lib:${PREFIX}/lib64:\${LD_LIBRARY_PATH:-}

EOF

chmod +x ${SETVARS_SCRIPT}
echo "Done: source '${SETVARS_SCRIPT}'"
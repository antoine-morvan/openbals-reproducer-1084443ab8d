#!/bin/bash -eu


SCRIPT_DIR=$(dirname $(readlink -f $0))
SUMMARY_FILE=${SCRIPT_DIR}/summary.md

LOG_FILES=$(find -maxdepth 1 -iname "*openblas.log")



cat > ${SUMMARY_FILE} << EOF

# OpenBLAS Experiments Summary

| ARCH | Compiler | Version | Test Failures | Test time |
| ---- | -------- | ------- | ------------- | --------- |
EOF

for LOG_FILE in ${LOG_FILES}; do
    echo ${LOG_FILE}
    
    BASE_NAME=$(basename ${LOG_FILE})

    ARCH=$(echo ${BASE_NAME} | cut -d':' -f1)
    COMPILER=$(echo ${BASE_NAME} | cut -d'_' -f2)
    COMPILER_NAME=$(echo ${BASE_NAME} | cut -d':' -f2)
    COMPILER_VERSION=$(echo ${BASE_NAME} | cut -d':' -f3)

    echo "| $ARCH | $COMPILER_NAME | $COMPILER_VERSION | X | X |" >> ${SUMMARY_FILE}
done


cat ${SUMMARY_FILE}
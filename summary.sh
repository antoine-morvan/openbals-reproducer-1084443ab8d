#!/bin/bash -eu


SCRIPT_DIR=$(dirname $(readlink -f $0))
SUMMARY_FILE=${SCRIPT_DIR}/summary.md

LOG_FILES=$(find -maxdepth 1 -iname "*openblas.log")



cat > ${SUMMARY_FILE} << EOF

# OpenBLAS Experiments Summary

| ARCH | Compiler | Version | Test Success Rate | Test Count | Test Failures | Test time | OpenBLAS Version |
| ---- | -------- | ------- | ----------------- | ---------- | ------------- | --------- | ---------------- |
EOF

for LOG_FILE in ${LOG_FILES}; do
    echo ${LOG_FILE}
    
    BASE_NAME=$(basename ${LOG_FILE})

    OPENBLAS_VERSION=$(cat ${LOG_FILE} | grep "OpenBLAS Version" | cut -d':' -f2 | xargs)

    ARCH=$(echo ${BASE_NAME} | cut -d':' -f1)
    COMPILER=$(echo ${BASE_NAME} | cut -d'_' -f2)
    COMPILER_NAME=$(echo ${BASE_NAME} | cut -d':' -f2)
    COMPILER_VERSION=$(echo ${BASE_NAME} | cut -d':' -f3)

    TEST_EXEC_TIME=$(cat ${LOG_FILE} | grep "Total Test time" | cut -d'=' -f2 | xargs)
    if [ "$TEST_EXEC_TIME" == "" ]; then
        TEST_EXEC_TIME=":x:"
        TEST_SUCCESS_RATE=":x:"
        TEST_COUNT=":x:"
        TEST_FAILURES=":x:"
    else
        TEST_SUCCESS_RATE=$(cat ${LOG_FILE} | grep "tests passed" | xargs | cut -d' ' -f1)
        if [ "$TEST_SUCCESS_RATE" == "100%" ]; then
            TEST_SUCCESS_RATE=":white_check_mark: ($TEST_SUCCESS_RATE)"
        else
            TEST_SUCCESS_RATE=":x: ($TEST_SUCCESS_RATE)"
        fi

        TEST_COUNT=$(cat ${LOG_FILE} | grep "tests passed" | rev | cut -d' ' -f1 | rev)
        TEST_FAILURES=$(cat ${LOG_FILE} | grep "tests passed" | cut -d',' -f2 | xargs | cut -d' ' -f1)
    fi

    echo "| $ARCH | $COMPILER_NAME | $COMPILER_VERSION | $TEST_SUCCESS_RATE | $TEST_COUNT | $TEST_FAILURES | $TEST_EXEC_TIME | $OPENBLAS_VERSION |" >> ${SUMMARY_FILE}
done


cat ${SUMMARY_FILE}
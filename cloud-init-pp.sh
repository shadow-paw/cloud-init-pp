#!/bin/bash -e

INFILE=
OUTFILE=

case $(uname -a) in
*Darwin\ Kernel* )
    BASE64CMD="base64"
    ;;
*Linux* )
    BASE64CMD="base64 --warp=0"
    ;;
* )
    BASE64CMD="base64 --warp=0"
    ;;
esac


function main {
    echo "=== cloud-init preprocessor ==="
    if ! parse_arg $@; then exit 1; fi
    echo "[I] INFILE : $INFILE"
    echo "[I] OUTFILE: $OUTFILE"
    if [ -f "$OUTFILE" ]; then
        echo
        read -p "This will overwrite $OUTFILE, are you sure? [Y/n]" -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then exit 1; fi
        rm -f "$OUTFILE"
    fi
    preprocessor
}

function parse_arg {
    for arg in "$@"
    do
        case $arg in
        -i=*|--infile=*)
            INFILE="${arg#*=}"
            shift
            ;;
        -o=*|--outfile=*)
            OUTFILE="${arg#*=}"
            shift
            ;;
        esac
    done
    if [ "$INFILE" == "" ]; then
        INFILE="cloud-init.in"
    fi
    if [ "$OUTFILE" == "" ]; then
        OUTFILE="cloud-init.txt"
    fi
    if [ ! -f "$INFILE" ]; then
        echo "[!] File not found: $INFILE"
        return 1
    fi
    return 0
}

function preprocessor {
    local INDIR=$(cd $(dirname "$INFILE") && pwd)
    while IFS='' read -r line || [[ -n "$line" ]]; do
        if [[ $line =~ ^(\ *)content:(\ *)@(.*)$ ]]; then
            local INDENT="${BASH_REMATCH[1]}"
            local IMPORT_FILE="${BASH_REMATCH[3]}"
            if [ ! -f "${INDIR}/${IMPORT_FILE}" ]; then
                echo "[!] Import file not found: ${IMPORT_FILE}"
                exit 1
            fi
            local BASE64=`${BASE64CMD} "${INDIR}/${IMPORT_FILE}"`
            echo "[ ] Import: ${IMPORT_FILE}"
            echo "${INDENT}encoding: b64" >> "$OUTFILE"
            echo "${INDENT}content: ${BASE64}" >> "$OUTFILE"
        else
            echo "${line}" >> "$OUTFILE"
        fi
    done < "$INFILE"
    echo "[ ] OK"
}

main $@

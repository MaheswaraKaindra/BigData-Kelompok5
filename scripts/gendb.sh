#!/usr/bin/env bash

# Wrapper script for generating TPC-H data.
# If no arguments given, it calls gendb1gb.sh (scale factor 1).
# If -s <scale> is provided, it will build dbgen if needed and run with that scale.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
GENDB1GB="${SCRIPT_DIR}/gendb1gb.sh"
DBGEN_DIR="${ROOT_DIR}/tpch-dbgen"
# If tpch-dbgen contains a nested tpch-dbgen-master folder, prefer it
if [ -d "${ROOT_DIR}/tpch-dbgen/tpch-dbgen-master" ]; then
  DBGEN_DIR="${ROOT_DIR}/tpch-dbgen/tpch-dbgen-master"
fi
OUTPUT_DIR="${ROOT_DIR}/tpch-data"

usage() {
  cat <<EOF
Usage: $(basename "$0") [-s SCALE]

  -s SCALE   Scale factor for dbgen (e.g. 1 for 1GB). If omitted, runs gendb1gb.sh
EOF
  exit 1
}

SCALE=""
while getopts ":s:h" opt; do
  case $opt in
    s) SCALE="$OPTARG" ;;
    h) usage ;;
    :) echo "Option -$OPTARG requires an argument."; usage ;;
    *) usage ;;
  esac
done

if [ -z "$SCALE" ]; then
  if [ -x "$GENDB1GB" ]; then
    exec "$GENDB1GB"
  else
    echo "gendb1gb.sh not found or not executable; please run with -s SCALE" >&2
    exit 1
  fi
fi

# Ensure dbgen exists (build if necessary)
if [ ! -f "$DBGEN_DIR/dbgen" ]; then
  echo "Building dbgen..."
  cd "$DBGEN_DIR"
  if ! command -v make &> /dev/null; then
    echo "Error: 'make' not found. Please install build tools." >&2
    exit 1
  fi
  make clean 2>/dev/null || true
  make
  if [ ! -f "$DBGEN_DIR/dbgen" ]; then
    echo "Error: Failed to build dbgen" >&2
    exit 1
  fi
  cd - > /dev/null
fi

mkdir -p "$OUTPUT_DIR"
echo "Generating TPC-H data (Scale Factor=$SCALE) into $OUTPUT_DIR"

# Run dbgen from its source directory so it can find distribution files
cd "$DBGEN_DIR"
DSS_PATH="$DBGEN_DIR" ./dbgen -s "$SCALE" -f

# Move generated files to output directory
mkdir -p "$OUTPUT_DIR"
mv -v *.tbl "$OUTPUT_DIR"/ 2>/dev/null || true

if [ $? -ne 0 ]; then
  echo "dbgen failed" >&2
  exit 1
fi

echo "Generation complete. Generated files:"
ls -lh *.tbl 2>/dev/null || true

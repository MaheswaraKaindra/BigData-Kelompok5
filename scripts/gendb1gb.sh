#!/bin/bash

# Generate 1GB TPC-H data using dbgen
# Output: tpch-data/*.tbl files

set -e

echo "=========================================="
echo "TPC-H Data Generation (1GB - Scale Factor 1)"
echo "=========================================="
echo ""

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DBGEN_DIR="$PROJECT_ROOT/tpch-dbgen"
OUTPUT_DIR="$PROJECT_ROOT/tpch-data"

# Check if dbgen exists and is executable
if [ ! -f "$DBGEN_DIR/dbgen" ]; then
    echo "Building dbgen..."
    cd "$DBGEN_DIR"
    
    # Check for make
    if ! command -v make &> /dev/null; then
        echo "Error: 'make' not found. Please install build tools:"
        echo "  macOS: brew install make"
        echo "  Ubuntu/Debian: sudo apt-get install build-essential"
        exit 1
    fi
    
    # Build dbgen
    make clean 2>/dev/null || true
    make
    
    if [ ! -f "$DBGEN_DIR/dbgen" ]; then
        echo "Error: Failed to build dbgen"
        exit 1
    fi
    
    echo "✓ dbgen built successfully"
    cd - > /dev/null
fi

echo ""
echo "Generating 1GB TPC-H data (Scale Factor = 1)..."
echo "  Output directory: $OUTPUT_DIR"
echo ""

# Generate data with scale factor 1 (1GB)
cd "$OUTPUT_DIR"

# Run dbgen with -s 1 (1 GB)
# -s: scale factor (size in GB)
# Pipe through gzip for disk space efficiency
"$DBGEN_DIR/dbgen" -s 1 -f

if [ $? -eq 0 ]; then
    echo ""
    echo "=========================================="
    echo "Data Generation Complete!"
    echo "=========================================="
    echo ""
    
    # Show generated files
    echo "Generated files:"
    ls -lh *.tbl 2>/dev/null | awk '{print "  " $9 " (" $5 ")"}'
    
    TOTAL_SIZE=$(du -sh . | awk '{print $1}')
    echo ""
    echo "Total size: $TOTAL_SIZE"
    echo ""
    echo "Next steps:"
    echo "  1. Start Docker services:"
    echo "     docker compose up -d"
    echo ""
    echo "  2. Convert .tbl to CSV:"
    echo "     python code/convert_tbl_to_csv.py"
    echo ""
    echo "  3. Run full pipeline:"
    echo "     python code/ingest_tpch_to_iceberg.py"
    echo ""
else
    echo "Error: Failed to generate TPC-H data"
    exit 1
fi

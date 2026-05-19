#!/bin/bash

# Cleanup script untuk reset project dari awal
# Menghapus semua generated data dan temporary files

set -e

echo "=========================================="
echo "TPC-H Iceberg Project - Cleanup Script"
echo "=========================================="
echo ""

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_ROOT"

# 1. Stop Docker containers
echo "1. Stopping Docker containers..."
if command -v docker-compose &> /dev/null; then
    docker-compose down -v 2>/dev/null || true
elif command -v docker &> /dev/null; then
    docker compose down -v 2>/dev/null || true
fi
echo "   ✓ Docker containers stopped"
echo ""

# 2. Clean up generated CSV files
echo "2. Cleaning up generated CSV files..."
if [ -d "data/csv" ]; then
    rm -rf data/csv/*
    echo "   ✓ Removed: data/csv/*"
fi
echo ""

# 3. Clean up generated .tbl files (keep .tbl.gz)
echo "3. Cleaning up generated .tbl files..."
if [ -d "tpch-data" ]; then
    find tpch-data -maxdepth 1 -name "*.tbl" -type f -delete
    echo "   ✓ Removed: tpch-data/*.tbl"
fi
echo ""

# 4. Clean up Python cache
echo "4. Cleaning up Python cache..."
find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
find . -type f -name "*.pyc" -delete 2>/dev/null || true
find . -type d -name ".pytest_cache" -exec rm -rf {} + 2>/dev/null || true
echo "   ✓ Removed: Python cache files"
echo ""

# 5. Info about what's kept
echo "=========================================="
echo "Cleanup Complete!"
echo "=========================================="
echo ""
echo "Kept:"
echo "  ✓ tpch-data/*.tbl.gz (compressed source data)"
echo "  ✓ tpch-dbgen/ (generator source code)"
echo "  ✓ code/ (all Python scripts)"
echo "  ✓ README.md and configuration files"
echo ""
echo "Removed:"
echo "  ✗ data/csv/ (generated CSV files)"
echo "  ✗ tpch-data/*.tbl (extracted TPC-H data)"
echo "  ✗ Docker containers and volumes"
echo ""
echo "Next steps:"
echo "  1. Generate fresh 1GB TPC-H data:"
echo "     ./scripts/gendb.sh"
echo ""
echo "  2. Start services:"
echo "     docker compose up -d"
echo ""
echo "  3. Run full pipeline:"
echo "     python code/ingest_tpch_to_iceberg.py"
echo ""

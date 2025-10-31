#!/bin/bash

# ============================================
# SDVN Test Diagnostics Script
# ============================================

echo "╔════════════════════════════════════════════════════════════╗"
echo "║  SDVN Test Diagnostics                                    ║"
echo "╔════════════════════════════════════════════════════════════╗"
echo ""

# Check if we're in the right directory
echo "1. Checking working directory..."
if [ -f "waf" ]; then
    echo "   ✓ Found waf build system"
else
    echo "   ✗ waf not found! Are you in ns-3.35 directory?"
    echo "   Current directory: $(pwd)"
    exit 1
fi

# Check if routing program is compiled
echo ""
echo "2. Checking if 'routing' program is compiled..."
if [ -f "build/scratch/routing" ] || [ -f "build/src/routing/routing" ]; then
    echo "   ✓ routing program found"
else
    echo "   ✗ routing program not compiled!"
    echo "   Please run: ./waf configure && ./waf"
    exit 1
fi

# Try running a simple test
echo ""
echo "3. Running quick baseline test (10 seconds)..."
echo "   Command: ./waf --run 'routing --simTime=10 --N_Vehicles=5 --N_RSUs=2'"
echo ""

./waf --run "routing --simTime=10 --N_Vehicles=5 --N_RSUs=2 \
    --present_wormhole_attack_nodes=false \
    --present_blackhole_attack_nodes=false \
    --present_sybil_attack_nodes=false" 2>&1 | tee diagnostic_output.txt

EXIT_CODE=$?

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Diagnostic Results"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Exit code: $EXIT_CODE"
echo ""

if [ $EXIT_CODE -eq 0 ]; then
    echo "✓ Simulation ran successfully!"
    echo ""
    
    # Check for CSV output
    if [ -f "performance_metrics.csv" ]; then
        echo "✓ performance_metrics.csv generated"
        echo ""
        echo "CSV file contents (first 10 lines):"
        head -10 performance_metrics.csv
    else
        echo "⚠ No performance_metrics.csv generated"
        echo ""
        echo "This means your routing.cc doesn't output CSV metrics."
        echo "You need to add CSV output code to routing.cc"
        echo ""
        echo "Checking what files were created:"
        ls -lt *.csv 2>/dev/null || echo "  No CSV files found"
        ls -lt *.txt 2>/dev/null | head -5
    fi
else
    echo "✗ Simulation failed!"
    echo ""
    echo "Common issues:"
    echo "  1. Missing command-line arguments in routing.cc"
    echo "  2. Compilation errors"
    echo "  3. Runtime errors in the code"
    echo ""
    echo "Last 30 lines of output:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    tail -30 diagnostic_output.txt
fi

echo ""
echo "Full output saved to: diagnostic_output.txt"
echo "To view: cat diagnostic_output.txt"

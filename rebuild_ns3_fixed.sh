#!/bin/bash

# Quick Rebuild and Test Script
# After fixing next hop loop iterations (lines 132880, 132905)
# Generated: November 11, 2025

echo "=========================================="
echo "REBUILDING NS-3 WITH NEXT HOP FIXES"
echo "=========================================="
echo ""

# Navigate to NS-3 directory
cd ~/ns-allinone-3.35/ns-3.35 || { echo "Error: NS-3 directory not found!"; exit 1; }

echo "Current directory: $(pwd)"
echo ""

# Show current build timestamp
echo "Previous build timestamp:"
ls -lh build/scratch/routing
echo ""

# Rebuild
echo "Starting rebuild..."
echo ""
./waf build

if [ $? -ne 0 ]; then
    echo ""
    echo "❌ BUILD FAILED!"
    exit 1
fi

echo ""
echo "✅ BUILD SUCCESSFUL!"
echo ""

# Show new build timestamp
echo "New build timestamp:"
ls -lh build/scratch/routing
echo ""

# Verify fixes are present
echo "=========================================="
echo "VERIFYING FIXES IN SOURCE CODE"
echo "=========================================="
echo ""

echo "Checking for 'actual_total_nodes' in loops..."
grep -n "for.*actual_total_nodes" scratch/routing.cc | head -10
echo ""

echo "Checking if any 'for.*ns3::total_size' remain in critical section (lines 132800-133000)..."
sed -n '132800,133000p' scratch/routing.cc | grep -n "for.*ns3::total_size"
if [ $? -ne 0 ]; then
    echo "✅ No ns3::total_size found in critical section (good!)"
else
    echo "⚠️ Still has ns3::total_size in critical section"
fi
echo ""

echo "=========================================="
echo "REBUILD COMPLETE!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Navigate to your routing copy directory"
echo "2. Run: ./test_wormhole_focused.sh"
echo "3. Monitor: tail -f wormhole_evaluation_*/test01_baseline/simulation.log"
echo ""
echo "Expected results:"
echo "✓ No 'next hop' IDs >= 70"
echo "✓ Simulation completes past 29 seconds"
echo "✓ Test finishes successfully at ~60 seconds"
echo "✓ Metrics collected in metrics_summary.csv"
echo ""

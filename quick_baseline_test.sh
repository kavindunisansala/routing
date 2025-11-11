#!/bin/bash

################################################################################
# Quick Baseline Test
# Purpose: Run minimal baseline to verify simulation works
# Usage: bash quick_baseline_test.sh
################################################################################

echo "================================================================================"
echo "QUICK BASELINE TEST"
echo "================================================================================"
echo ""
echo "Testing: 5 vehicles + 5 RSUs, 10s simulation, no attacks"
echo ""

# Clean up any previous CSV files
rm -f *.csv 2>/dev/null

# Run baseline
echo "Running simulation..."
./waf --run "scratch/routing \
  --N_Vehicles=5 \
  --N_RSUs=5 \
  --simTime=10 \
  --architecture=0 \
  --routing_test=false \
  --random_seed=12345" 2>&1 | tee baseline_output.log

EXIT_CODE=$?

echo ""
echo "================================================================================"
echo "RESULTS"
echo "================================================================================"
echo "Exit Code: $EXIT_CODE"

if [ $EXIT_CODE -eq 0 ]; then
    echo "✓ Simulation completed successfully!"
else
    echo "✗ Simulation failed!"
fi

echo ""
echo "CSV Files Generated:"
ls -lh *.csv 2>/dev/null | awk '{print "  " $9 " (" $5 ")"}'

echo ""
echo "Key Metrics:"
grep "packet delivery ratio is" baseline_output.log | tail -1
grep "average_latency" baseline_output.log | tail -1
grep "DSRC uti" baseline_output.log | tail -1

echo ""
echo "V2V Traffic:"
AODV_COUNT=$(grep -c "AODV-DATA-PLANE" baseline_output.log)
echo "  AODV destinations scheduled: $AODV_COUNT"

echo ""
echo "Full log saved to: baseline_output.log"
echo ""

if [ $EXIT_CODE -ne 0 ]; then
    echo "ERROR DETAILS:"
    grep -i "error\|abort\|segmentation\|assertion" baseline_output.log | head -10
fi

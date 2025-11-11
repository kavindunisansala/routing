#!/bin/bash

# Rebuild and test script after fixing array bounds issues
# Usage: ./rebuild_and_test.sh

echo "========================================="
echo "Rebuilding NS-3 with array bounds fixes..."
echo "========================================="
./waf build

if [ $? -ne 0 ]; then
    echo "ERROR: Build failed!"
    exit 1
fi

echo ""
echo "========================================="
echo "Running baseline diagnostic test..."
echo "========================================="
./waf --run "scratch/routing \
    --N_Vehicles=5 \
    --N_RSUs=5 \
    --simTime=10 \
    --architecture=0 \
    --routing_test=false \
    --random_seed=12345"

echo ""
echo "========================================="
echo "Test complete. Check for:"
echo "1. No SIGSEGV errors"
echo "2. Simulation completes full 10 seconds"
echo "3. No RSU index warnings"
echo "========================================="

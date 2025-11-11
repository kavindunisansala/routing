#!/bin/bash

echo "Testing with minimal simulation time to isolate crash..."
cd /home/eie/ns-allinone-3.35/ns-3.35

# Try with simTime=1 to see if it crashes earlier
echo ""
echo "Test 1: simTime=1"
./waf --run "scratch/routing --architecture=0 --N_Vehicles=5 --N_RSUs=1 --simTime=1" 2>&1 | grep -E "(SDN-HYBRID|DSRC|Simulator|ERROR|Segmentation|assert|terminate)"

echo ""
echo "If that worked, try with more nodes..."

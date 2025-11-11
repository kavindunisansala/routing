#!/bin/bash

# Ultra-minimal test - just check if it runs without crashing

echo "Building..."
cd /home/eie/ns-allinone-3.35/ns-3.35
./waf build 2>&1 | tail -5

echo ""
echo "Running test..."
./waf --run "scratch/routing --architecture=0 --N_Vehicles=20 --N_RSUs=2 --simTime=10" 2>&1 | head -100

if [ $? -eq 0 ]; then
    echo ""
    echo "SUCCESS! No crash."
    
    # Quick check for peer-to-peer flows
    if [ -f "packet-delivery-analysis.csv" ]; then
        peer_count=$(awk -F',' 'NR>1 && $1!="SourceNode" && $1!~"^(0|1)$" && $2!~"^(0|1)$" {print $1"-"$2}' packet-delivery-analysis.csv | sort -u | wc -l)
        echo "Peer-to-peer flows: $peer_count"
    fi
else
    echo ""
    echo "FAILED - check errors above"
fi

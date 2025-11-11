#!/bin/bash

# Quick test for new SDN architecture
# Just rebuild and run one simple test

echo "=========================================="
echo " Quick SDN Architecture Test"
echo "=========================================="
echo ""

echo "Step 1: Rebuilding NS-3..."
./waf build 2>&1 | grep -E "(Build|error|Compiling|Finished)"

if [ $? -ne 0 ]; then
    echo "Build failed! Check errors above."
    exit 1
fi

echo ""
echo "Step 2: Running baseline test (no attacks)..."
./waf --run "scratch/routing --architecture=0 --N_Vehicles=20 --N_RSUs=2 --simTime=10"

if [ $? -eq 0 ]; then
    echo ""
    echo "=========================================="
    echo " ✓ TEST PASSED!"
    echo "=========================================="
    echo ""
    echo "Checking results..."
    
    if [ -f "packet-delivery-analysis.csv" ]; then
        echo ""
        echo "Peer-to-peer flows (data plane):"
        awk -F',' 'NR>1 && $1!="SourceNode" && $1!~"^(0|1)$" && $2!~"^(0|1)$" {print $1"-"$2}' packet-delivery-analysis.csv | sort -u | head -5
        
        peer_count=$(awk -F',' 'NR>1 && $1!="SourceNode" && $1!~"^(0|1)$" && $2!~"^(0|1)$" {print $1"-"$2}' packet-delivery-analysis.csv | sort -u | wc -l)
        echo ""
        echo "Total peer-to-peer flows: $peer_count"
        
        if [ $peer_count -gt 0 ]; then
            echo ""
            echo "✓ DATA PLANE IS WORKING!"
            echo "  Nodes are using AODV routing for peer-to-peer communication"
        else
            echo ""
            echo "⚠ Warning: No peer-to-peer flows detected"
            echo "  All traffic still going through controller"
        fi
    fi
else
    echo ""
    echo "=========================================="
    echo " ✗ TEST FAILED"
    echo "=========================================="
    exit 1
fi

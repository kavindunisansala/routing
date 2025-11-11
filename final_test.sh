#!/bin/bash
echo "============================================"
echo " Testing Fixed SDN Architecture"  
echo "============================================"
echo ""
cd /home/eie/ns-allinone-3.35/ns-3.35
./waf build 2>&1 | tail -3
echo ""
echo "Running simulation..."
echo ""
./waf --run "scratch/routing --architecture=0 --N_Vehicles=20 --N_RSUs=2 --simTime=10" 2>&1 | tee test_output.txt

if [ ${PIPESTATUS[0]} -eq 0 ]; then
    echo ""
    echo "============================================"
    echo " ✓ SIMULATION COMPLETED SUCCESSFULLY!"
    echo "============================================"
    echo ""
    
    # Check for data plane activity
    if [ -f "packet-delivery-analysis.csv" ]; then
        echo "Analyzing results..."
        peer_flows=$(awk -F',' 'NR>1 && $1!="SourceNode" && $1!~"^(0|1)$" && $2!~"^(0|1)$" {print $1"->"$2}' packet-delivery-analysis.csv | sort -u | wc -l)
        controller_flows=$(awk -F',' 'NR>1 && ($1=="0" || $1=="1" || $2=="0" || $2=="1") {print $1"->"$2}' packet-delivery-analysis.csv | sort -u | wc -l)
        
        echo ""
        echo "Traffic Analysis:"
        echo "  Peer-to-peer flows (data plane): $peer_flows"
        echo "  Controller flows (control plane): $controller_flows"
        echo ""
        
        if [ $peer_flows -gt 0 ]; then
            echo "✓ DATA PLANE IS WORKING!"
            echo "  AODV routing + DSRC broadcasts are functional"
            echo ""
            echo "Sample peer-to-peer flows:"
            awk -F',' 'NR>1 && $1!="SourceNode" && $1!~"^(0|1)$" && $2!~"^(0|1)$" {print "  "$1" -> "$2}' packet-delivery-analysis.csv | sort -u | head -10
        else
            echo "⚠ Warning: No peer-to-peer flows detected"
        fi
    fi
else
    echo ""
    echo "============================================"
    echo " ✗ SIMULATION FAILED"
    echo "============================================"
    echo ""
    echo "Check test_output.txt for details"
fi

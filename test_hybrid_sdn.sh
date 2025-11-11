#!/bin/bash

################################################################################
# HYBRID SDN ARCHITECTURE TEST
# Verifies: Static routing for infrastructure + AODV for mobile vehicles
################################################################################

echo "════════════════════════════════════════════════════════════════"
echo "  HYBRID SDN ARCHITECTURE TEST"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "Architecture 0 Design:"
echo "  • RSU Backbone: Static routing (stable infrastructure)"
echo "  • Controller/Management: Static routing"
echo "  • Vehicles: AODV routing (mobile peer-to-peer)"
echo "  • Control Plane: LTE (metadata to controller)"
echo "  • Data Plane: DSRC + AODV (V2V communication)"
echo ""
echo "════════════════════════════════════════════════════════════════"
echo ""

cd /home/eie/ns-allinone-3.35/ns-3.35

echo "Step 1: Building NS-3..."
./waf build 2>&1 | grep -E "(Compiling|Linking|finished)" | tail -5

if [ ${PIPESTATUS[0]} -ne 0 ]; then
    echo "❌ Build failed!"
    exit 1
fi

echo ""
echo "Step 2: Running baseline test (no attacks)..."
echo "  Command: --architecture=0 --N_Vehicles=20 --N_RSUs=2 --simTime=10"
echo ""

./waf --run "scratch/routing --architecture=0 --N_Vehicles=20 --N_RSUs=2 --simTime=10" 2>&1 | tee /tmp/sdn_test.log

if [ ${PIPESTATUS[0]} -eq 0 ]; then
    echo ""
    echo "════════════════════════════════════════════════════════════════"
    echo "  ✅ SIMULATION COMPLETED SUCCESSFULLY"
    echo "════════════════════════════════════════════════════════════════"
    echo ""
    
    # Check for expected output messages
    if grep -q "SDN-HYBRID.*static routing on infrastructure" /tmp/sdn_test.log; then
        echo "✓ Static routing installed on infrastructure (RSUs + controller)"
    fi
    
    if grep -q "SDN-HYBRID.*AODV.*Vehicles" /tmp/sdn_test.log; then
        echo "✓ AODV routing installed on vehicles"
    fi
    
    if grep -q "Populated static routing tables" /tmp/sdn_test.log; then
        echo "✓ Static routing tables populated for infrastructure"
    fi
    
    if grep -q "DSRC data Broadcasting" /tmp/sdn_test.log; then
        echo "✓ DSRC broadcasts active on data plane"
    fi
    
    echo ""
    
    # Analyze packet delivery
    if [ -f "packet-delivery-analysis.csv" ]; then
        echo "Analyzing traffic patterns..."
        
        # Count peer-to-peer flows (excluding controller nodes 0,1)
        peer_flows=$(awk -F',' 'NR>1 && $1!="SourceNode" && $1!~"^(0|1)$" && $2!~"^(0|1)$" {print $1"->"$2}' packet-delivery-analysis.csv | sort -u | wc -l)
        
        # Count controller flows
        controller_flows=$(awk -F',' 'NR>1 && ($1=="0" || $1=="1" || $2=="0" || $2=="1") {print $1"->"$2}' packet-delivery-analysis.csv | sort -u | wc -l)
        
        echo ""
        echo "Traffic Distribution:"
        echo "  Peer-to-peer flows (V2V data plane): $peer_flows"
        echo "  Controller flows (control plane): $controller_flows"
        echo ""
        
        if [ $peer_flows -gt 0 ]; then
            echo "✅ DATA PLANE IS WORKING!"
            echo "   Vehicles are using AODV + DSRC for peer-to-peer communication"
            echo ""
            echo "Sample peer-to-peer flows:"
            awk -F',' 'NR>1 && $1!="SourceNode" && $1!~"^(0|1)$" && $2!~"^(0|1)$" {print "   "$1" → "$2}' packet-delivery-analysis.csv | sort -u | head -8
            echo ""
            
            # Check if RSU backbone is being used
            rsu_flows=$(awk -F',' 'NR>1 && $1!="SourceNode" && $1>=2 && $1<10 && $2>=2 && $2<10 {print $1"->"$2}' packet-delivery-analysis.csv | sort -u | wc -l)
            if [ $rsu_flows -gt 0 ]; then
                echo "✓ RSU backbone is active (static routing)"
            fi
        else
            echo "⚠️  Warning: No peer-to-peer flows detected"
            echo "   Data plane may not be working as expected"
        fi
        
        echo ""
        echo "════════════════════════════════════════════════════════════════"
        echo "  NEXT STEPS"
        echo "════════════════════════════════════════════════════════════════"
        echo ""
        echo "1. Test wormhole attack:"
        echo "   ./waf --run \"scratch/routing --architecture=0 --present_wormhole_attack_nodes=1 --N_Vehicles=20 --N_RSUs=2 --simTime=10 --attack_percentage=0.2\""
        echo ""
        echo "2. Check wormhole statistics:"
        echo "   cat wormhole-attack-statistics.csv"
        echo "   Expected: PacketsTunneled > 0"
        echo ""
        echo "3. Run full verification:"
        echo "   bash \"d:/routing copy/verify_new_architecture.sh\""
        echo ""
    else
        echo "⚠️  packet-delivery-analysis.csv not found"
    fi
    
else
    echo ""
    echo "════════════════════════════════════════════════════════════════"
    echo "  ❌ SIMULATION FAILED"
    echo "════════════════════════════════════════════════════════════════"
    echo ""
    echo "Check /tmp/sdn_test.log for details"
    tail -20 /tmp/sdn_test.log
    exit 1
fi

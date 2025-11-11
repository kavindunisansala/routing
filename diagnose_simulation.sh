#!/bin/bash

################################################################################
# Simulation Diagnostic Script
# Purpose: Identify why tests are failing (crashes, incomplete execution, etc.)
# Usage: bash diagnose_simulation.sh
################################################################################

set +e  # Don't exit on error - we want to capture failures

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo "================================================================================"
echo "SIMULATION DIAGNOSTIC TOOL"
echo "================================================================================"
echo ""

# Test 1: Minimal baseline (most important!)
echo -e "${BLUE}TEST 1: Minimal Baseline (5 vehicles, 5 RSUs, 10s, no attacks)${NC}"
echo "Command: ./waf --run \"scratch/routing --N_Vehicles=5 --N_RSUs=5 --simTime=10 --architecture=0 --routing_test=false\""
echo ""

./waf --run "scratch/routing --N_Vehicles=5 --N_RSUs=5 --simTime=10 --architecture=0 --routing_test=false --random_seed=12345" > diagnostic_baseline.log 2>&1

EXIT_CODE=$?
echo ""
echo -e "${YELLOW}Exit Code: $EXIT_CODE${NC}"

if [ $EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}✓ Simulation completed successfully!${NC}"
else
    echo -e "${RED}✗ Simulation failed with exit code $EXIT_CODE${NC}"
fi

echo ""
echo "Checking for CSV files..."
CSV_COUNT=$(find . -maxdepth 1 -name "*.csv" -type f | wc -l)
if [ $CSV_COUNT -gt 0 ]; then
    echo -e "${GREEN}✓ Found $CSV_COUNT CSV file(s):${NC}"
    ls -lh *.csv | awk '{print "  " $9 " - " $5}'
else
    echo -e "${RED}✗ No CSV files generated${NC}"
fi

echo ""
echo "Checking simulation log for critical information..."

# Check for completion indicators
if grep -q "packet delivery ratio is" diagnostic_baseline.log; then
    PDR=$(grep "packet delivery ratio is" diagnostic_baseline.log | tail -1 | awk '{print $NF}')
    echo -e "${GREEN}✓ Metrics calculated: PDR = $PDR${NC}"
else
    echo -e "${YELLOW}⚠ No PDR metrics found (simulation may not have completed)${NC}"
fi

if grep -q "AODV-DATA-PLANE" diagnostic_baseline.log; then
    AODV_COUNT=$(grep -c "AODV-DATA-PLANE" diagnostic_baseline.log)
    echo -e "${GREEN}✓ V2V unicast traffic active: $AODV_COUNT AODV destinations scheduled${NC}"
else
    echo -e "${RED}✗ No V2V unicast traffic (AODV not triggered)${NC}"
fi

# Check for errors
ERROR_COUNT=$(grep -ci "error\|segmentation\|assertion\|abort\|failed" diagnostic_baseline.log)
if [ $ERROR_COUNT -gt 0 ]; then
    echo -e "${RED}⚠ Found $ERROR_COUNT potential error messages:${NC}"
    grep -i "error\|segmentation\|assertion\|abort\|failed" diagnostic_baseline.log | head -5 | sed 's/^/  /'
else
    echo -e "${GREEN}✓ No obvious error messages${NC}"
fi

echo ""
echo "================================================================================"

# Test 2: Wormhole attack (if baseline worked)
if [ $EXIT_CODE -eq 0 ] && [ $CSV_COUNT -gt 0 ]; then
    echo ""
    echo -e "${BLUE}TEST 2: Wormhole Attack (20% attackers, no mitigation)${NC}"
    echo "Command: ./waf --run \"scratch/routing --N_Vehicles=5 --N_RSUs=5 --simTime=10 --architecture=0 --routing_test=false --present_wormhole_attack_nodes=true\""
    echo ""
    
    # Clean up previous CSV files
    rm -f *.csv
    
    ./waf --run "scratch/routing --N_Vehicles=5 --N_RSUs=5 --simTime=10 --architecture=0 --routing_test=false --random_seed=12345 --present_wormhole_attack_nodes=true --use_enhanced_wormhole=true --attack_percentage=0.2 --wormhole_tunnel_data=true --wormhole_tunnel_routing=true --wormhole_enable_verification_flows=true" > diagnostic_wormhole.log 2>&1
    
    EXIT_CODE2=$?
    echo ""
    echo -e "${YELLOW}Exit Code: $EXIT_CODE2${NC}"
    
    if [ $EXIT_CODE2 -eq 0 ]; then
        echo -e "${GREEN}✓ Wormhole simulation completed!${NC}"
    else
        echo -e "${RED}✗ Wormhole simulation failed with exit code $EXIT_CODE2${NC}"
    fi
    
    echo ""
    echo "Checking wormhole-specific metrics..."
    
    if [ -f "wormhole-attack-results.csv" ]; then
        echo -e "${GREEN}✓ wormhole-attack-results.csv found${NC}"
        
        # Check if PacketsTunneled > 0
        TUNNELED=$(grep "PacketsTunneled" wormhole-attack-results.csv 2>/dev/null | tail -1 | awk -F',' '{print $NF}')
        if [ -n "$TUNNELED" ] && [ "$TUNNELED" -gt 0 ] 2>/dev/null; then
            echo -e "${GREEN}✓ PacketsTunneled = $TUNNELED (wormhole is working!)${NC}"
        else
            echo -e "${RED}✗ PacketsTunneled = 0 or not found (wormhole not intercepting)${NC}"
        fi
    else
        echo -e "${RED}✗ wormhole-attack-results.csv not found${NC}"
    fi
    
    # Check for AODV packets on port 654
    if grep -q "port 654\|AODV" diagnostic_wormhole.log; then
        echo -e "${GREEN}✓ AODV packets detected (port 654 active)${NC}"
    else
        echo -e "${RED}✗ No AODV packets on port 654${NC}"
    fi
    
    # Check for wormhole activity
    if grep -qi "wormhole.*intercept\|tunnel" diagnostic_wormhole.log; then
        echo -e "${GREEN}✓ Wormhole interception/tunneling logged${NC}"
    else
        echo -e "${YELLOW}⚠ No wormhole interception logs found${NC}"
    fi
    
    echo ""
    echo "================================================================================"
fi

# Summary
echo ""
echo -e "${CYAN}DIAGNOSTIC SUMMARY${NC}"
echo "==================="
echo ""

if [ $EXIT_CODE -eq 0 ] && [ $CSV_COUNT -gt 0 ]; then
    echo -e "${GREEN}✓ BASELINE WORKS${NC}"
    echo "  Next step: Test each attack individually"
    echo "  Recommended: bash test_wormhole_focused.sh"
    echo ""
    
    if [ -n "$EXIT_CODE2" ] && [ $EXIT_CODE2 -eq 0 ]; then
        if [ -f "wormhole-attack-results.csv" ] && [ -n "$TUNNELED" ] && [ "$TUNNELED" -gt 0 ] 2>/dev/null; then
            echo -e "${GREEN}✓ WORMHOLE ATTACK WORKS${NC}"
            echo "  PacketsTunneled = $TUNNELED"
            echo "  Next step: Test detection and mitigation"
        else
            echo -e "${YELLOW}⚠ WORMHOLE RUNS BUT NOT INTERCEPTING${NC}"
            echo "  Issue: PacketsTunneled = 0"
            echo "  Check: AODV route discovery, port 654 monitoring"
        fi
    fi
else
    echo -e "${RED}✗ BASELINE FAILED - FIX THIS FIRST!${NC}"
    echo ""
    echo "Possible causes:"
    echo "  1. Segmentation fault in routing.cc"
    echo "  2. Array bounds violation (ns3::total_size)"
    echo "  3. Null pointer dereference"
    echo "  4. CSV writing logic not executing"
    echo ""
    echo "Debug steps:"
    echo "  1. Review diagnostic_baseline.log for errors"
    echo "  2. Check last 50 lines: tail -50 diagnostic_baseline.log"
    echo "  3. Search for errors: grep -i error diagnostic_baseline.log"
    echo "  4. Run with gdb: gdb --args ./build/scratch/ns3-dev-routing-debug [params]"
fi

echo ""
echo "Logs saved:"
echo "  - diagnostic_baseline.log (baseline test)"
if [ -f "diagnostic_wormhole.log" ]; then
    echo "  - diagnostic_wormhole.log (wormhole test)"
fi
echo ""

# Cleanup
echo "Cleaning up CSV files..."
rm -f *.csv

echo "Diagnostic complete!"

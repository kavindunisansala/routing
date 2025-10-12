#!/bin/bash
# wormhole_test_suite.sh
# Comprehensive testing suite for wormhole attack implementation

echo "╔════════════════════════════════════════════════════════════╗"
echo "║  VANET Wormhole Attack Test Suite                         ║"
echo "║  Testing Enhanced Wormhole Implementation                 ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Configuration
RESULTS_DIR="wormhole_test_results"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
TEST_DIR="${RESULTS_DIR}/${TIMESTAMP}"

# Create results directory
mkdir -p ${TEST_DIR}

echo "Results will be saved to: ${TEST_DIR}"
echo ""

# Test 1: Basic Wormhole Attack
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test 1: Basic Wormhole Attack (10% malicious nodes)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
./waf --run "routing --use_enhanced_wormhole=true \
              --attack_percentage=0.1 \
              --simTime=100 \
              --N_Vehicles=50 \
              --N_RSUs=20" \
    > ${TEST_DIR}/test1_basic_output.txt 2>&1

if [ -f "wormhole-attack-results.csv" ]; then
    mv wormhole-attack-results.csv ${TEST_DIR}/test1_statistics.csv
    echo "✓ Test 1 completed successfully"
else
    echo "✗ Test 1 failed - no statistics generated"
fi
echo ""

# Test 2: High Attack Intensity
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test 2: High Attack Intensity (30% malicious nodes)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
./waf --run "routing --use_enhanced_wormhole=true \
              --attack_percentage=0.3 \
              --simTime=100 \
              --N_Vehicles=50 \
              --N_RSUs=20" \
    > ${TEST_DIR}/test2_high_intensity_output.txt 2>&1

if [ -f "wormhole-attack-results.csv" ]; then
    mv wormhole-attack-results.csv ${TEST_DIR}/test2_statistics.csv
    echo "✓ Test 2 completed successfully"
else
    echo "✗ Test 2 failed"
fi
echo ""

# Test 3: Drop Packets Mode
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test 3: Drop Packets Mode (20% malicious, drop all)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
./waf --run "routing --use_enhanced_wormhole=true \
              --attack_percentage=0.2 \
              --wormhole_drop_packets=true \
              --simTime=100 \
              --N_Vehicles=50 \
              --N_RSUs=20" \
    > ${TEST_DIR}/test3_drop_mode_output.txt 2>&1

if [ -f "wormhole-attack-results.csv" ]; then
    mv wormhole-attack-results.csv ${TEST_DIR}/test3_statistics.csv
    echo "✓ Test 3 completed successfully"
else
    echo "✗ Test 3 failed"
fi
echo ""

# Test 4: Selective Tunneling - Routing Only
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test 4: Selective Tunneling (routing packets only)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
./waf --run "routing --use_enhanced_wormhole=true \
              --attack_percentage=0.15 \
              --wormhole_tunnel_routing=true \
              --wormhole_tunnel_data=false \
              --simTime=100 \
              --N_Vehicles=50 \
              --N_RSUs=20" \
    > ${TEST_DIR}/test4_routing_only_output.txt 2>&1

if [ -f "wormhole-attack-results.csv" ]; then
    mv wormhole-attack-results.csv ${TEST_DIR}/test4_statistics.csv
    echo "✓ Test 4 completed successfully"
else
    echo "✗ Test 4 failed"
fi
echo ""

# Test 5: Delayed Attack
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test 5: Delayed Attack (starts at 30s, stops at 80s)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
./waf --run "routing --use_enhanced_wormhole=true \
              --attack_percentage=0.2 \
              --wormhole_start_time=30.0 \
              --wormhole_stop_time=80.0 \
              --simTime=100 \
              --N_Vehicles=50 \
              --N_RSUs=20" \
    > ${TEST_DIR}/test5_delayed_output.txt 2>&1

if [ -f "wormhole-attack-results.csv" ]; then
    mv wormhole-attack-results.csv ${TEST_DIR}/test5_statistics.csv
    echo "✓ Test 5 completed successfully"
else
    echo "✗ Test 5 failed"
fi
echo ""

# Test 6: Variable Tunnel Bandwidth
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test 6: Low Bandwidth Tunnel (10Mbps instead of 1000Mbps)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
./waf --run "routing --use_enhanced_wormhole=true \
              --attack_percentage=0.1 \
              --wormhole_bandwidth=10Mbps \
              --wormhole_delay_us=1000 \
              --simTime=100 \
              --N_Vehicles=50 \
              --N_RSUs=20" \
    > ${TEST_DIR}/test6_low_bandwidth_output.txt 2>&1

if [ -f "wormhole-attack-results.csv" ]; then
    mv wormhole-attack-results.csv ${TEST_DIR}/test6_statistics.csv
    echo "✓ Test 6 completed successfully"
else
    echo "✗ Test 6 failed"
fi
echo ""

# Test 7: Sequential Pairing
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test 7: Sequential Node Pairing (vs random)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
./waf --run "routing --use_enhanced_wormhole=true \
              --attack_percentage=0.2 \
              --wormhole_random_pairing=false \
              --simTime=100 \
              --N_Vehicles=50 \
              --N_RSUs=20" \
    > ${TEST_DIR}/test7_sequential_output.txt 2>&1

if [ -f "wormhole-attack-results.csv" ]; then
    mv wormhole-attack-results.csv ${TEST_DIR}/test7_statistics.csv
    echo "✓ Test 7 completed successfully"
else
    echo "✗ Test 7 failed"
fi
echo ""

# Test 8: Standalone Example
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test 8: Standalone Wormhole Example"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
./waf --run "wormhole_example --nNodes=30 --simTime=50 --attackPercentage=0.25" \
    > ${TEST_DIR}/test8_standalone_output.txt 2>&1

if [ -f "wormhole-attack-results.csv" ]; then
    mv wormhole-attack-results.csv ${TEST_DIR}/test8_statistics.csv
    echo "✓ Test 8 completed successfully"
else
    echo "✗ Test 8 failed"
fi

if [ -f "wormhole-attack-animation.xml" ]; then
    mv wormhole-attack-animation.xml ${TEST_DIR}/test8_animation.xml
fi
echo ""

# Generate Summary Report
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Generating Summary Report"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

SUMMARY_FILE="${TEST_DIR}/test_summary.txt"

cat > ${SUMMARY_FILE} << EOF
═══════════════════════════════════════════════════════════════
  WORMHOLE ATTACK TEST SUITE SUMMARY
  Date: $(date)
═══════════════════════════════════════════════════════════════

Test Results:
EOF

for i in {1..8}; do
    if [ -f "${TEST_DIR}/test${i}_statistics.csv" ]; then
        echo "  Test ${i}: ✓ PASS" >> ${SUMMARY_FILE}
    else
        echo "  Test ${i}: ✗ FAIL" >> ${SUMMARY_FILE}
    fi
done

cat >> ${SUMMARY_FILE} << EOF

───────────────────────────────────────────────────────────────
Test Descriptions:
───────────────────────────────────────────────────────────────
1. Basic Wormhole Attack (10% malicious)
2. High Attack Intensity (30% malicious)
3. Drop Packets Mode (packets dropped instead of tunneled)
4. Selective Tunneling (only routing packets affected)
5. Delayed Attack (attack starts mid-simulation)
6. Low Bandwidth Tunnel (realistic tunnel constraints)
7. Sequential Pairing (deterministic pairing)
8. Standalone Example (minimal test case)

───────────────────────────────────────────────────────────────
Files Generated:
───────────────────────────────────────────────────────────────
EOF

ls -lh ${TEST_DIR} >> ${SUMMARY_FILE}

cat >> ${SUMMARY_FILE} << EOF

═══════════════════════════════════════════════════════════════
End of Report
═══════════════════════════════════════════════════════════════
EOF

cat ${SUMMARY_FILE}

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  Test Suite Complete!                                      ║"
echo "║  Results saved to: ${TEST_DIR}                             ║"
echo "╚════════════════════════════════════════════════════════════╝"

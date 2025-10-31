#!/bin/bash
# SDVN Security Attack Testing Suite
# Tests Wormhole, Sybil, and Blackhole attacks with mitigation

echo "==============================================="
echo "SDVN Security Attack Testing Suite"
echo "Testing Wormhole, Sybil, and Blackhole Attacks"
echo "==============================================="
echo ""

# Create results directory with timestamp
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RESULTS_DIR="attack_results_${TIMESTAMP}"
mkdir -p ${RESULTS_DIR}

echo "Results will be saved to: ${RESULTS_DIR}"
echo ""

# Configuration parameters
SIM_TIME=100
N_VEHICLES=18
N_RSUS=10
TOTAL_NODES=28

# ============================================
# TEST 1: BASELINE (NO ATTACKS)
# ============================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "TEST 1: Baseline - No Attacks"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
./waf --run "routing \
    --simTime=${SIM_TIME} \
    --N_Vehicles=${N_VEHICLES} \
    --N_RSUs=${N_RSUS} \
    --present_wormhole_attack_nodes=false \
    --present_blackhole_attack_nodes=false \
    --present_sybil_attack_nodes=false" \
    > ${RESULTS_DIR}/test1_baseline_output.txt 2>&1

if [ -f "performance_metrics.csv" ]; then
    mv performance_metrics.csv ${RESULTS_DIR}/test1_baseline_metrics.csv
    echo "✓ Baseline test completed"
else
    echo "✗ Baseline test failed"
fi
echo ""

# ============================================
# TEST 2: WORMHOLE ATTACK (10%)
# ============================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "TEST 2: Wormhole Attack (10% malicious)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
./waf --run "routing \
    --simTime=${SIM_TIME} \
    --N_Vehicles=${N_VEHICLES} \
    --N_RSUs=${N_RSUS} \
    --present_wormhole_attack_nodes=true \
    --attack_percentage=0.1 \
    --present_blackhole_attack_nodes=false \
    --present_sybil_attack_nodes=false" \
    > ${RESULTS_DIR}/test2_wormhole_10_output.txt 2>&1

if [ -f "performance_metrics.csv" ]; then
    mv performance_metrics.csv ${RESULTS_DIR}/test2_wormhole_10_metrics.csv
    echo "✓ Wormhole 10% test completed"
fi
echo ""

# ============================================
# TEST 3: WORMHOLE ATTACK (20%)
# ============================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "TEST 3: Wormhole Attack (20% malicious)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
./waf --run "routing \
    --simTime=${SIM_TIME} \
    --N_Vehicles=${N_VEHICLES} \
    --N_RSUs=${N_RSUS} \
    --present_wormhole_attack_nodes=true \
    --attack_percentage=0.2 \
    --present_blackhole_attack_nodes=false \
    --present_sybil_attack_nodes=false" \
    > ${RESULTS_DIR}/test3_wormhole_20_output.txt 2>&1

if [ -f "performance_metrics.csv" ]; then
    mv performance_metrics.csv ${RESULTS_DIR}/test3_wormhole_20_metrics.csv
    echo "✓ Wormhole 20% test completed"
fi
echo ""

# ============================================
# TEST 4: BLACKHOLE ATTACK (10%)
# ============================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "TEST 4: Blackhole Attack (10% malicious)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
./waf --run "routing \
    --simTime=${SIM_TIME} \
    --N_Vehicles=${N_VEHICLES} \
    --N_RSUs=${N_RSUS} \
    --present_wormhole_attack_nodes=false \
    --present_blackhole_attack_nodes=true \
    --attack_percentage=0.1 \
    --present_sybil_attack_nodes=false" \
    > ${RESULTS_DIR}/test4_blackhole_10_output.txt 2>&1

if [ -f "performance_metrics.csv" ]; then
    mv performance_metrics.csv ${RESULTS_DIR}/test4_blackhole_10_metrics.csv
    echo "✓ Blackhole 10% test completed"
fi
echo ""

# ============================================
# TEST 5: BLACKHOLE ATTACK (20%)
# ============================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "TEST 5: Blackhole Attack (20% malicious)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
./waf --run "routing \
    --simTime=${SIM_TIME} \
    --N_Vehicles=${N_VEHICLES} \
    --N_RSUs=${N_RSUS} \
    --present_wormhole_attack_nodes=false \
    --present_blackhole_attack_nodes=true \
    --attack_percentage=0.2 \
    --present_sybil_attack_nodes=false" \
    > ${RESULTS_DIR}/test5_blackhole_20_output.txt 2>&1

if [ -f "performance_metrics.csv" ]; then
    mv performance_metrics.csv ${RESULTS_DIR}/test5_blackhole_20_metrics.csv
    echo "✓ Blackhole 20% test completed"
fi
echo ""

# ============================================
# TEST 6: SYBIL ATTACK (10%)
# ============================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "TEST 6: Sybil Attack (10% malicious)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
./waf --run "routing \
    --simTime=${SIM_TIME} \
    --N_Vehicles=${N_VEHICLES} \
    --N_RSUs=${N_RSUS} \
    --present_wormhole_attack_nodes=false \
    --present_blackhole_attack_nodes=false \
    --present_sybil_attack_nodes=true \
    --attack_percentage=0.1" \
    > ${RESULTS_DIR}/test6_sybil_10_output.txt 2>&1

if [ -f "performance_metrics.csv" ]; then
    mv performance_metrics.csv ${RESULTS_DIR}/test6_sybil_10_metrics.csv
    echo "✓ Sybil 10% test completed"
fi
echo ""

# ============================================
# TEST 7: COMBINED ATTACKS (Low Intensity)
# ============================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "TEST 7: Combined Attacks (10% each)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
./waf --run "routing \
    --simTime=${SIM_TIME} \
    --N_Vehicles=${N_VEHICLES} \
    --N_RSUs=${N_RSUS} \
    --present_wormhole_attack_nodes=true \
    --present_blackhole_attack_nodes=true \
    --present_sybil_attack_nodes=true \
    --attack_percentage=0.1" \
    > ${RESULTS_DIR}/test7_combined_10_output.txt 2>&1

if [ -f "performance_metrics.csv" ]; then
    mv performance_metrics.csv ${RESULTS_DIR}/test7_combined_10_metrics.csv
    echo "✓ Combined attacks test completed"
fi
echo ""

# ============================================
# TEST 8: COMBINED ATTACKS (High Intensity)
# ============================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "TEST 8: Combined Attacks (30% each)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
./waf --run "routing \
    --simTime=${SIM_TIME} \
    --N_Vehicles=${N_VEHICLES} \
    --N_RSUs=${N_RSUS} \
    --present_wormhole_attack_nodes=true \
    --present_blackhole_attack_nodes=true \
    --present_sybil_attack_nodes=true \
    --attack_percentage=0.3" \
    > ${RESULTS_DIR}/test8_combined_30_output.txt 2>&1

if [ -f "performance_metrics.csv" ]; then
    mv performance_metrics.csv ${RESULTS_DIR}/test8_combined_30_metrics.csv
    echo "✓ Combined high-intensity attacks test completed"
fi
echo ""

# ============================================
# GENERATE COMPARISON REPORT
# ============================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Generating Comparison Report"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

REPORT_FILE="${RESULTS_DIR}/comparison_report.txt"

cat > ${REPORT_FILE} << 'EOF'
═══════════════════════════════════════════════════════════════
  SDVN SECURITY ATTACK ANALYSIS REPORT
═══════════════════════════════════════════════════════════════

Test Configuration:
  - Simulation Time: 100 seconds
  - Number of Vehicles: 18
  - Number of RSUs: 10
  - Total Network Nodes: 28

Test Scenarios Executed:
─────────────────────────────────────────────────────────────
EOF

# List all test results
for i in {1..8}; do
    if [ -f "${RESULTS_DIR}/test${i}_"*"_metrics.csv" ]; then
        TEST_NAME=$(ls ${RESULTS_DIR}/test${i}_*_metrics.csv | sed 's/.*test[0-9]_//' | sed 's/_metrics.csv//')
        echo "  Test ${i}: ${TEST_NAME} - ✓ COMPLETED" >> ${REPORT_FILE}
    else
        echo "  Test ${i}: FAILED" >> ${REPORT_FILE}
    fi
done

cat >> ${REPORT_FILE} << 'EOF'

═══════════════════════════════════════════════════════════════
Performance Metrics to Analyze:
─────────────────────────────────────────────────────────────
1. Packet Delivery Ratio (PDR)
2. End-to-End Delay
3. Network Throughput
4. Routing Overhead
5. Detection Rate (for attacks)
6. False Positive Rate
7. Network Lifetime
8. Energy Consumption

Attack-Specific Metrics:
─────────────────────────────────────────────────────────────
Wormhole Attack:
  - Packets tunneled
  - Route distortion rate
  - Affected routing paths

Blackhole Attack:
  - Packets dropped
  - Traffic attraction rate
  - Network coverage degradation

Sybil Attack:
  - Fake identities created
  - Trust value manipulation
  - Resource consumption rate

═══════════════════════════════════════════════════════════════
Files Generated:
─────────────────────────────────────────────────────────────
EOF

ls -lh ${RESULTS_DIR}/*.csv >> ${REPORT_FILE}

cat >> ${REPORT_FILE} << 'EOF'

═══════════════════════════════════════════════════════════════
Next Steps for Analysis:
─────────────────────────────────────────────────────────────
1. Import CSV files into analysis tool (Excel/Python/MATLAB)
2. Calculate comparative metrics between scenarios
3. Generate graphs for visualization:
   - PDR vs Attack Intensity
   - Delay vs Attack Type
   - Throughput Comparison
   - Detection Accuracy
4. Document mitigation effectiveness
5. Prepare research findings

═══════════════════════════════════════════════════════════════
End of Report
═══════════════════════════════════════════════════════════════
EOF

cat ${REPORT_FILE}

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  Test Suite Complete!                                      ║"
echo "║  Results saved to: ${RESULTS_DIR}                          ║"
echo "╔════════════════════════════════════════════════════════════╗"
echo ""
echo "To analyze results, use the Python analysis script:"
echo "  python3 analyze_attack_results.py ${RESULTS_DIR}"

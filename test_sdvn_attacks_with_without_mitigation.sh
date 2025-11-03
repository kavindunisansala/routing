#!/bin/bash
# ============================================================================
# SDVN Attack Testing Suite: WITH and WITHOUT Mitigation
# Tests each attack in two modes:
#   1. Attack WITHOUT mitigation (baseline attack impact)
#   2. Attack WITH mitigation (solution effectiveness)
# ============================================================================

echo "=========================================================================="
echo "SDVN Attack Testing: WITH and WITHOUT Mitigation Solutions"
echo "=========================================================================="
echo ""
echo "This suite tests each attack type twice:"
echo "  - WITHOUT mitigation: Shows raw attack impact"
echo "  - WITH mitigation: Shows solution effectiveness"
echo ""

# Create results directory with timestamp
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RESULTS_DIR="sdvn_mitigation_comparison_${TIMESTAMP}"
mkdir -p ${RESULTS_DIR}

echo "Results will be saved to: ${RESULTS_DIR}"
echo ""

# Configuration parameters
SIM_TIME=100
N_VEHICLES=18
N_RSUS=10
ARCHITECTURE=0  # 0=centralized SDVN

# Function to collect CSV files after a test
collect_csv_files() {
    local test_prefix=$1
    local test_name=$2
    local csv_count=0
    
    # Create subdirectory for this test
    local test_dir="${RESULTS_DIR}/${test_prefix}"
    mkdir -p ${test_dir}
    
    # List of possible CSV files
    local csv_files=(
        "packet-delivery-analysis.csv"
        "blackhole-attack-results.csv"
        "sybil-attack-results.csv"
        "sybil-detection-results.csv"
        "sybil-mitigation-results.csv"
        "replay-attack-results.csv"
        "replay-detection-results.csv"
        "replay-mitigation-results.csv"
        "trusted-certification-results.csv"
        "rssi-detection-results.csv"
        "resource-testing-results.csv"
        "incentive-scheme-results.csv"
        "wormhole-detection-results.csv"
        "wormhole-mitigation-results.csv"
        "blackhole-detection-results.csv"
        "blackhole-mitigation-results.csv"
    )
    
    for csv in "${csv_files[@]}"; do
        if [ -f "$csv" ]; then
            cp "$csv" "${test_dir}/${csv}"
            ((csv_count++))
        fi
    done
    
    if [ $csv_count -gt 0 ]; then
        echo "✓ ${test_name} completed - collected ${csv_count} file(s) to ${test_dir}/"
        return 0
    else
        echo "⚠ ${test_name} ran but no result files generated"
        return 1
    fi
}

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                   TEST SEQUENCE OVERVIEW                       ║"
echo "╠════════════════════════════════════════════════════════════════╣"
echo "║  1. Baseline (No Attacks)                                      ║"
echo "║  2. Wormhole WITHOUT Mitigation (10%)                          ║"
echo "║  3. Wormhole WITH Mitigation (10%)                             ║"
echo "║  4. Wormhole WITHOUT Mitigation (20%)                          ║"
echo "║  5. Wormhole WITH Mitigation (20%)                             ║"
echo "║  6. Blackhole WITHOUT Mitigation (10%)                         ║"
echo "║  7. Blackhole WITH Mitigation (10%)                            ║"
echo "║  8. Blackhole WITHOUT Mitigation (20%)                         ║"
echo "║  9. Blackhole WITH Mitigation (20%)                            ║"
echo "║ 10. Sybil WITHOUT Mitigation (10%)                             ║"
echo "║ 11. Sybil WITH Mitigation (10%)                                ║"
echo "║ 12. Combined Attacks WITHOUT Mitigation (10%)                  ║"
echo "║ 13. Combined Attacks WITH Mitigation (10%)                     ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
read -p "Press Enter to start testing (or Ctrl+C to cancel)..."
echo ""

# ============================================
# TEST 1: BASELINE (NO ATTACKS)
# ============================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "TEST 1: Baseline - No Attacks"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
./waf --run "routing \
    --simTime=${SIM_TIME} \
    --N_Vehicles=${N_VEHICLES} \
    --N_RSUs=${N_RSUS} \
    --architecture=${ARCHITECTURE} \
    --enable_packet_tracking=true" \
    > ${RESULTS_DIR}/test01_baseline_output.txt 2>&1

if [ $? -eq 0 ]; then
    collect_csv_files "test01_baseline" "Baseline"
else
    echo "✗ Baseline test failed"
fi
echo ""

# ============================================
# TEST 2: WORMHOLE WITHOUT MITIGATION (10%)
# ============================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "TEST 2: Wormhole Attack WITHOUT Mitigation (10%)"
echo "Purpose: Measure raw attack impact without any defense"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
./waf --run "routing \
    --simTime=${SIM_TIME} \
    --N_Vehicles=${N_VEHICLES} \
    --N_RSUs=${N_RSUS} \
    --architecture=${ARCHITECTURE} \
    --enable_packet_tracking=true \
    --present_wormhole_attack_nodes=true \
    --use_enhanced_wormhole=true \
    --attack_percentage=0.1 \
    --enable_wormhole_detection=false \
    --enable_wormhole_mitigation=false" \
    > ${RESULTS_DIR}/test02_wormhole_10_no_mitigation_output.txt 2>&1

if [ $? -eq 0 ]; then
    collect_csv_files "test02_wormhole_10_no_mitigation" "Wormhole 10% (No Mitigation)"
else
    echo "✗ Wormhole 10% without mitigation test failed"
fi
echo ""

# ============================================
# TEST 3: WORMHOLE WITH MITIGATION (10%)
# ============================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "TEST 3: Wormhole Attack WITH Mitigation (10%)"
echo "Purpose: Measure solution effectiveness"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
./waf --run "routing \
    --simTime=${SIM_TIME} \
    --N_Vehicles=${N_VEHICLES} \
    --N_RSUs=${N_RSUS} \
    --architecture=${ARCHITECTURE} \
    --enable_packet_tracking=true \
    --present_wormhole_attack_nodes=true \
    --use_enhanced_wormhole=true \
    --attack_percentage=0.1 \
    --enable_wormhole_detection=true \
    --enable_wormhole_mitigation=true" \
    > ${RESULTS_DIR}/test03_wormhole_10_with_mitigation_output.txt 2>&1

if [ $? -eq 0 ]; then
    collect_csv_files "test03_wormhole_10_with_mitigation" "Wormhole 10% (With Mitigation)"
else
    echo "✗ Wormhole 10% with mitigation test failed"
fi
echo ""

# ============================================
# TEST 4: WORMHOLE WITHOUT MITIGATION (20%)
# ============================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "TEST 4: Wormhole Attack WITHOUT Mitigation (20%)"
echo "Purpose: Measure increased attack severity"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
./waf --run "routing \
    --simTime=${SIM_TIME} \
    --N_Vehicles=${N_VEHICLES} \
    --N_RSUs=${N_RSUS} \
    --architecture=${ARCHITECTURE} \
    --enable_packet_tracking=true \
    --present_wormhole_attack_nodes=true \
    --use_enhanced_wormhole=true \
    --attack_percentage=0.2 \
    --enable_wormhole_detection=false \
    --enable_wormhole_mitigation=false" \
    > ${RESULTS_DIR}/test04_wormhole_20_no_mitigation_output.txt 2>&1

if [ $? -eq 0 ]; then
    collect_csv_files "test04_wormhole_20_no_mitigation" "Wormhole 20% (No Mitigation)"
else
    echo "✗ Wormhole 20% without mitigation test failed"
fi
echo ""

# ============================================
# TEST 5: WORMHOLE WITH MITIGATION (20%)
# ============================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "TEST 5: Wormhole Attack WITH Mitigation (20%)"
echo "Purpose: Test solution scalability"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
./waf --run "routing \
    --simTime=${SIM_TIME} \
    --N_Vehicles=${N_VEHICLES} \
    --N_RSUs=${N_RSUS} \
    --architecture=${ARCHITECTURE} \
    --enable_packet_tracking=true \
    --present_wormhole_attack_nodes=true \
    --use_enhanced_wormhole=true \
    --attack_percentage=0.2 \
    --enable_wormhole_detection=true \
    --enable_wormhole_mitigation=true" \
    > ${RESULTS_DIR}/test05_wormhole_20_with_mitigation_output.txt 2>&1

if [ $? -eq 0 ]; then
    collect_csv_files "test05_wormhole_20_with_mitigation" "Wormhole 20% (With Mitigation)"
else
    echo "✗ Wormhole 20% with mitigation test failed"
fi
echo ""

# ============================================
# TEST 6: BLACKHOLE WITHOUT MITIGATION (10%)
# ============================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "TEST 6: Blackhole Attack WITHOUT Mitigation (10%)"
echo "Purpose: Measure raw attack impact"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
./waf --run "routing \
    --simTime=${SIM_TIME} \
    --N_Vehicles=${N_VEHICLES} \
    --N_RSUs=${N_RSUS} \
    --architecture=${ARCHITECTURE} \
    --enable_packet_tracking=true \
    --present_blackhole_attack_nodes=true \
    --enable_blackhole_attack=true \
    --blackhole_attack_percentage=0.1 \
    --blackhole_advertise_fake_routes=true \
    --enable_blackhole_detection=false \
    --enable_blackhole_mitigation=false" \
    > ${RESULTS_DIR}/test06_blackhole_10_no_mitigation_output.txt 2>&1

if [ $? -eq 0 ]; then
    collect_csv_files "test06_blackhole_10_no_mitigation" "Blackhole 10% (No Mitigation)"
else
    echo "✗ Blackhole 10% without mitigation test failed"
fi
echo ""

# ============================================
# TEST 7: BLACKHOLE WITH MITIGATION (10%)
# ============================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "TEST 7: Blackhole Attack WITH Mitigation (10%)"
echo "Purpose: Measure solution effectiveness"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
./waf --run "routing \
    --simTime=${SIM_TIME} \
    --N_Vehicles=${N_VEHICLES} \
    --N_RSUs=${N_RSUS} \
    --architecture=${ARCHITECTURE} \
    --enable_packet_tracking=true \
    --present_blackhole_attack_nodes=true \
    --enable_blackhole_attack=true \
    --blackhole_attack_percentage=0.1 \
    --blackhole_advertise_fake_routes=true \
    --enable_blackhole_detection=true \
    --enable_blackhole_mitigation=true" \
    > ${RESULTS_DIR}/test07_blackhole_10_with_mitigation_output.txt 2>&1

if [ $? -eq 0 ]; then
    collect_csv_files "test07_blackhole_10_with_mitigation" "Blackhole 10% (With Mitigation)"
else
    echo "✗ Blackhole 10% with mitigation test failed"
fi
echo ""

# ============================================
# TEST 8: BLACKHOLE WITHOUT MITIGATION (20%)
# ============================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "TEST 8: Blackhole Attack WITHOUT Mitigation (20%)"
echo "Purpose: Measure increased attack severity"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
./waf --run "routing \
    --simTime=${SIM_TIME} \
    --N_Vehicles=${N_VEHICLES} \
    --N_RSUs=${N_RSUS} \
    --architecture=${ARCHITECTURE} \
    --enable_packet_tracking=true \
    --present_blackhole_attack_nodes=true \
    --enable_blackhole_attack=true \
    --blackhole_attack_percentage=0.2 \
    --blackhole_advertise_fake_routes=true \
    --enable_blackhole_detection=false \
    --enable_blackhole_mitigation=false" \
    > ${RESULTS_DIR}/test08_blackhole_20_no_mitigation_output.txt 2>&1

if [ $? -eq 0 ]; then
    collect_csv_files "test08_blackhole_20_no_mitigation" "Blackhole 20% (No Mitigation)"
else
    echo "✗ Blackhole 20% without mitigation test failed"
fi
echo ""

# ============================================
# TEST 9: BLACKHOLE WITH MITIGATION (20%)
# ============================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "TEST 9: Blackhole Attack WITH Mitigation (20%)"
echo "Purpose: Test solution scalability"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
./waf --run "routing \
    --simTime=${SIM_TIME} \
    --N_Vehicles=${N_VEHICLES} \
    --N_RSUs=${N_RSUS} \
    --architecture=${ARCHITECTURE} \
    --enable_packet_tracking=true \
    --present_blackhole_attack_nodes=true \
    --enable_blackhole_attack=true \
    --blackhole_attack_percentage=0.2 \
    --blackhole_advertise_fake_routes=true \
    --enable_blackhole_detection=true \
    --enable_blackhole_mitigation=true" \
    > ${RESULTS_DIR}/test09_blackhole_20_with_mitigation_output.txt 2>&1

if [ $? -eq 0 ]; then
    collect_csv_files "test09_blackhole_20_with_mitigation" "Blackhole 20% (With Mitigation)"
else
    echo "✗ Blackhole 20% with mitigation test failed"
fi
echo ""

# ============================================
# TEST 10: SYBIL WITHOUT MITIGATION (10%)
# ============================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "TEST 10: Sybil Attack WITHOUT Mitigation (10%)"
echo "Purpose: Measure raw attack impact"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
./waf --run "routing \
    --simTime=${SIM_TIME} \
    --N_Vehicles=${N_VEHICLES} \
    --N_RSUs=${N_RSUS} \
    --architecture=${ARCHITECTURE} \
    --enable_packet_tracking=true \
    --present_sybil_attack_nodes=true \
    --enable_sybil_attack=true \
    --sybil_attack_percentage=0.1 \
    --sybil_advertise_fake_routes=true \
    --sybil_clone_legitimate_nodes=true \
    --enable_sybil_detection=false \
    --enable_sybil_mitigation=false" \
    > ${RESULTS_DIR}/test10_sybil_10_no_mitigation_output.txt 2>&1

if [ $? -eq 0 ]; then
    collect_csv_files "test10_sybil_10_no_mitigation" "Sybil 10% (No Mitigation)"
else
    echo "✗ Sybil 10% without mitigation test failed"
fi
echo ""

# ============================================
# TEST 11: SYBIL WITH MITIGATION (10%)
# ============================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "TEST 11: Sybil Attack WITH Mitigation (10%)"
echo "Purpose: Measure solution effectiveness"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
./waf --run "routing \
    --simTime=${SIM_TIME} \
    --N_Vehicles=${N_VEHICLES} \
    --N_RSUs=${N_RSUS} \
    --architecture=${ARCHITECTURE} \
    --enable_packet_tracking=true \
    --present_sybil_attack_nodes=true \
    --enable_sybil_attack=true \
    --sybil_attack_percentage=0.1 \
    --sybil_advertise_fake_routes=true \
    --sybil_clone_legitimate_nodes=true \
    --enable_sybil_detection=true \
    --enable_sybil_mitigation=true \
    --enable_sybil_mitigation_advanced=true \
    --use_trusted_certification=true \
    --use_rssi_detection=true" \
    > ${RESULTS_DIR}/test11_sybil_10_with_mitigation_output.txt 2>&1

if [ $? -eq 0 ]; then
    collect_csv_files "test11_sybil_10_with_mitigation" "Sybil 10% (With Mitigation)"
else
    echo "✗ Sybil 10% with mitigation test failed"
fi
echo ""

# ============================================
# TEST 12: COMBINED WITHOUT MITIGATION (10%)
# ============================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "TEST 12: Combined Attacks WITHOUT Mitigation (10%)"
echo "Purpose: Measure worst-case attack impact"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
./waf --run "routing \
    --simTime=${SIM_TIME} \
    --N_Vehicles=${N_VEHICLES} \
    --N_RSUs=${N_RSUS} \
    --architecture=${ARCHITECTURE} \
    --enable_packet_tracking=true \
    --present_wormhole_attack_nodes=true \
    --present_blackhole_attack_nodes=true \
    --present_sybil_attack_nodes=true \
    --use_enhanced_wormhole=true \
    --attack_percentage=0.1 \
    --enable_blackhole_attack=true \
    --blackhole_attack_percentage=0.1 \
    --blackhole_advertise_fake_routes=true \
    --enable_sybil_attack=true \
    --sybil_attack_percentage=0.1 \
    --sybil_advertise_fake_routes=true \
    --sybil_clone_legitimate_nodes=true \
    --enable_wormhole_detection=false \
    --enable_wormhole_mitigation=false \
    --enable_blackhole_detection=false \
    --enable_blackhole_mitigation=false \
    --enable_sybil_detection=false \
    --enable_sybil_mitigation=false" \
    > ${RESULTS_DIR}/test12_combined_10_no_mitigation_output.txt 2>&1

if [ $? -eq 0 ]; then
    collect_csv_files "test12_combined_10_no_mitigation" "Combined 10% (No Mitigation)"
else
    echo "✗ Combined 10% without mitigation test failed"
fi
echo ""

# ============================================
# TEST 13: COMBINED WITH MITIGATION (10%)
# ============================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "TEST 13: Combined Attacks WITH Mitigation (10%)"
echo "Purpose: Test comprehensive solution effectiveness"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
./waf --run "routing \
    --simTime=${SIM_TIME} \
    --N_Vehicles=${N_VEHICLES} \
    --N_RSUs=${N_RSUS} \
    --architecture=${ARCHITECTURE} \
    --enable_packet_tracking=true \
    --present_wormhole_attack_nodes=true \
    --present_blackhole_attack_nodes=true \
    --present_sybil_attack_nodes=true \
    --use_enhanced_wormhole=true \
    --attack_percentage=0.1 \
    --enable_blackhole_attack=true \
    --blackhole_attack_percentage=0.1 \
    --blackhole_advertise_fake_routes=true \
    --enable_sybil_attack=true \
    --sybil_attack_percentage=0.1 \
    --sybil_advertise_fake_routes=true \
    --sybil_clone_legitimate_nodes=true \
    --enable_wormhole_detection=true \
    --enable_wormhole_mitigation=true \
    --enable_blackhole_detection=true \
    --enable_blackhole_mitigation=true \
    --enable_sybil_detection=true \
    --enable_sybil_mitigation=true \
    --enable_sybil_mitigation_advanced=true \
    --use_trusted_certification=true \
    --use_rssi_detection=true" \
    > ${RESULTS_DIR}/test13_combined_10_with_mitigation_output.txt 2>&1

if [ $? -eq 0 ]; then
    collect_csv_files "test13_combined_10_with_mitigation" "Combined 10% (With Mitigation)"
else
    echo "✗ Combined 10% with mitigation test failed"
fi
echo ""

# ============================================
# GENERATE SUMMARY
# ============================================
echo "=========================================================================="
echo "ALL TESTS COMPLETED"
echo "=========================================================================="
echo ""
echo "Results saved to: ${RESULTS_DIR}/"
echo ""
echo "Test Summary:"
echo "  01. Baseline (no attacks)"
echo "  02-03. Wormhole 10% (without/with mitigation)"
echo "  04-05. Wormhole 20% (without/with mitigation)"
echo "  06-07. Blackhole 10% (without/with mitigation)"
echo "  08-09. Blackhole 20% (without/with mitigation)"
echo "  10-11. Sybil 10% (without/with mitigation)"
echo "  12-13. Combined 10% (without/with mitigation)"
echo ""
echo "Next Steps:"
echo "  1. Analyze results:"
echo "     python analyze_mitigation_comparison.py ${RESULTS_DIR}"
echo ""
echo "  2. View individual test logs:"
echo "     cat ${RESULTS_DIR}/test*_output.txt | grep -i 'attack\|detection\|mitigation'"
echo ""
echo "  3. Compare CSV files:"
echo "     diff ${RESULTS_DIR}/test02_wormhole_10_no_mitigation/packet-delivery-analysis.csv \\"
echo "          ${RESULTS_DIR}/test03_wormhole_10_with_mitigation/packet-delivery-analysis.csv"
echo ""
echo "=========================================================================="

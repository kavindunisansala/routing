#!/bin/bash
# ============================================================================
# SDVN Complete Security Evaluation Script
# Tests all attacks with and without mitigation solutions
# Generates comprehensive performance comparison
# ============================================================================

set -u  # Exit on undefined variables

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Print functions
print_header() {
    echo ""
    echo "================================================================"
    echo "$1"
    echo "================================================================"
    echo ""
}

print_section() {
    echo ""
    echo -e "${MAGENTA}────────────────────────────────────────────────────────────────${NC}"
    echo -e "${MAGENTA}$1${NC}"
    echo -e "${MAGENTA}────────────────────────────────────────────────────────────────${NC}"
    echo ""
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_header "SDVN COMPLETE SECURITY EVALUATION"
print_info "Testing all data plane attacks with and without mitigation"
print_info "Generating comprehensive performance analysis"

# Configuration
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RESULTS_DIR="./sdvn_evaluation_${TIMESTAMP}"
ROUTING_SCRIPT="routing"
SIM_TIME=100
TOTAL_NODES=70  # Total nodes in network
VEHICLES=$((TOTAL_NODES - 10))  # Vehicles = Total - RSUs
RSUS=10
ARCHITECTURE=0  # 0=centralized SDVN

# Attack percentages to test
ATTACK_PERCENTAGES=(0.2 0.4 0.6 0.8 1.0)
ATTACK_PERCENTAGE_LABELS=("20" "40" "60" "80" "100")

# Test counter
TOTAL_TESTS=0  # Will be calculated dynamically
PASSED_TESTS=0
FAILED_TESTS=0

print_info "Results will be saved to: $RESULTS_DIR"
print_info "Configuration: Total Nodes=$TOTAL_NODES (Vehicles=$VEHICLES, RSUs=$RSUS)"
print_info "Attack Percentages: ${ATTACK_PERCENTAGE_LABELS[@]}%"
print_info "Total Tests: 1 baseline + 5 attack types × 5 percentages × 3 scenarios = 76 tests"
mkdir -p "$RESULTS_DIR"

# Calculate total tests
TOTAL_TESTS=76  # 1 baseline + 5 attacks × 5 percentages × 3 scenarios (no miti, detection, full miti)

# ============================================================================
# Helper: Run simulation and check results
# ============================================================================
run_simulation() {
    local test_name=$1
    local test_id=$2
    local params=$3
    local output_dir="$RESULTS_DIR/${test_id}"
    
    mkdir -p "$output_dir"
    
    print_info "Running: $test_name"
    print_info "Parameters: $params"
    
    ./waf --run "scratch/$ROUTING_SCRIPT \
        --simTime=$SIM_TIME \
        --routing_test=false \
        --N_Vehicles=$VEHICLES \
        --N_RSUs=$RSUS \
        --architecture=$ARCHITECTURE \
        --enable_packet_tracking=true \
        $params" \
        > "$output_dir/simulation.log" 2>&1
    
    local exit_code=$?
    
    # Copy any CSV files from current directory to output directory
    # (routing.cc writes CSVs to current directory, not output_dir)
    find . -maxdepth 1 -name "*.csv" -type f -exec cp {} "$output_dir/" \; 2>/dev/null
    
    # Count CSV files in output directory
    local csv_count=$(find "$output_dir" -name "*.csv" 2>/dev/null | wc -l)
    
    if [ $exit_code -eq 0 ]; then
        print_success "$test_name completed successfully (exit: $exit_code, CSV files: $csv_count)"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        
        # Clean up CSV files from current directory after copying
        find . -maxdepth 1 -name "*.csv" -type f -delete 2>/dev/null
        return 0
    else
        print_error "$test_name failed (exit code: $exit_code, CSV files: $csv_count)"
        print_error "Check log: $output_dir/simulation.log"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        return 1
    fi
}

# ============================================================================
# PHASE 1: BASELINE
# ============================================================================
print_section "PHASE 1: BASELINE PERFORMANCE (1 test)"

run_simulation \
    "Baseline - No Attacks" \
    "test01_baseline" \
    ""

# ============================================================================
# PHASE 2: WORMHOLE ATTACK
# ============================================================================
print_section "PHASE 2: WORMHOLE ATTACK (15 tests: 5 percentages × 3 scenarios)"

for i in "${!ATTACK_PERCENTAGES[@]}"; do
    PERCENTAGE="${ATTACK_PERCENTAGES[$i]}"
    LABEL="${ATTACK_PERCENTAGE_LABELS[$i]}"
    
    print_info "Testing Wormhole with ${LABEL}% attack percentage"
    
    run_simulation \
        "Wormhole Attack ${LABEL}% (No Mitigation)" \
        "test02_wormhole_${LABEL}_no_mitigation" \
        "--present_wormhole_attack_nodes=true --use_enhanced_wormhole=true --attack_percentage=$PERCENTAGE --wormhole_bandwidth=1000Mbps --wormhole_delay_us=50000 --wormhole_random_pairing=true --wormhole_tunnel_routing=true --wormhole_tunnel_data=true --wormhole_enable_verification_flows=true"

    run_simulation \
        "Wormhole Attack ${LABEL}% (With Detection)" \
        "test03_wormhole_${LABEL}_with_detection" \
        "--present_wormhole_attack_nodes=true --use_enhanced_wormhole=true --attack_percentage=$PERCENTAGE --wormhole_bandwidth=1000Mbps --wormhole_delay_us=50000 --wormhole_tunnel_routing=true --wormhole_tunnel_data=true --enable_wormhole_detection=true --wormhole_enable_verification_flows=true"

    run_simulation \
        "Wormhole Attack ${LABEL}% (With Full Mitigation)" \
        "test04_wormhole_${LABEL}_with_mitigation" \
        "--present_wormhole_attack_nodes=true --use_enhanced_wormhole=true --attack_percentage=$PERCENTAGE --wormhole_bandwidth=1000Mbps --wormhole_delay_us=50000 --wormhole_tunnel_routing=true --wormhole_tunnel_data=true --enable_wormhole_detection=true --enable_wormhole_mitigation=true --wormhole_enable_verification_flows=true"
done

# ============================================================================
# PHASE 3: BLACKHOLE ATTACK
# ============================================================================
print_section "PHASE 3: BLACKHOLE ATTACK (15 tests: 5 percentages × 3 scenarios)"

for i in "${!ATTACK_PERCENTAGES[@]}"; do
    PERCENTAGE="${ATTACK_PERCENTAGES[$i]}"
    LABEL="${ATTACK_PERCENTAGE_LABELS[$i]}"
    
    print_info "Testing Blackhole with ${LABEL}% attack percentage"
    
    run_simulation \
        "Blackhole Attack ${LABEL}% (No Mitigation)" \
        "test05_blackhole_${LABEL}_no_mitigation" \
        "--present_blackhole_attack_nodes=true --attack_percentage=$PERCENTAGE --enable_blackhole_attack=true --blackhole_attack_percentage=$PERCENTAGE --blackhole_advertise_fake_routes=true"

    run_simulation \
        "Blackhole Attack ${LABEL}% (With Detection)" \
        "test06_blackhole_${LABEL}_with_detection" \
        "--present_blackhole_attack_nodes=true --attack_percentage=$PERCENTAGE --enable_blackhole_attack=true --blackhole_attack_percentage=$PERCENTAGE --blackhole_advertise_fake_routes=true --enable_blackhole_mitigation=true --blackhole_pdr_threshold=0.99"

    run_simulation \
        "Blackhole Attack ${LABEL}% (With Full Mitigation)" \
        "test07_blackhole_${LABEL}_with_mitigation" \
        "--present_blackhole_attack_nodes=true --attack_percentage=$PERCENTAGE --enable_blackhole_attack=true --blackhole_attack_percentage=$PERCENTAGE --blackhole_advertise_fake_routes=true --enable_blackhole_mitigation=true"
done

# ============================================================================
# PHASE 4: SYBIL ATTACK
# ============================================================================
print_section "PHASE 4: SYBIL ATTACK (15 tests: 5 percentages × 3 scenarios)"

for i in "${!ATTACK_PERCENTAGES[@]}"; do
    PERCENTAGE="${ATTACK_PERCENTAGES[$i]}"
    LABEL="${ATTACK_PERCENTAGE_LABELS[$i]}"
    
    print_info "Testing Sybil with ${LABEL}% attack percentage"
    
    run_simulation \
        "Sybil Attack ${LABEL}% (No Mitigation)" \
        "test08_sybil_${LABEL}_no_mitigation" \
        "--present_sybil_attack_nodes=true --attack_percentage=$PERCENTAGE --enable_sybil_attack=true --sybil_attack_percentage=$PERCENTAGE --sybil_identities_per_node=3 --sybil_advertise_fake_routes=true --sybil_clone_legitimate_nodes=true --sybil_inject_fake_packets=true --sybil_broadcast_interval=2.0"

    run_simulation \
        "Sybil Attack ${LABEL}% (With Detection)" \
        "test09_sybil_${LABEL}_with_detection" \
        "--present_sybil_attack_nodes=true --attack_percentage=$PERCENTAGE --enable_sybil_attack=true --sybil_attack_percentage=$PERCENTAGE --sybil_identities_per_node=3 --sybil_advertise_fake_routes=true --sybil_clone_legitimate_nodes=true --sybil_inject_fake_packets=true --enable_sybil_detection=true --use_trusted_certification=true --use_rssi_detection=true"

    run_simulation \
        "Sybil Attack ${LABEL}% (With Full Mitigation)" \
        "test10_sybil_${LABEL}_with_mitigation" \
        "--present_sybil_attack_nodes=true --attack_percentage=$PERCENTAGE --enable_sybil_attack=true --sybil_attack_percentage=$PERCENTAGE --sybil_identities_per_node=3 --sybil_advertise_fake_routes=true --sybil_clone_legitimate_nodes=true --sybil_inject_fake_packets=true --enable_sybil_detection=true --enable_sybil_mitigation=true --enable_sybil_mitigation_advanced=true --use_trusted_certification=true --use_rssi_detection=true"
done

# ============================================================================
# PHASE 5: REPLAY ATTACK
# ============================================================================
print_section "PHASE 5: REPLAY ATTACK (15 tests: 5 percentages × 3 scenarios)"

for i in "${!ATTACK_PERCENTAGES[@]}"; do
    PERCENTAGE="${ATTACK_PERCENTAGES[$i]}"
    LABEL="${ATTACK_PERCENTAGE_LABELS[$i]}"
    
    print_info "Testing Replay with ${LABEL}% attack percentage"
    
    run_simulation \
        "Replay Attack ${LABEL}% (No Mitigation)" \
        "test11_replay_${LABEL}_no_mitigation" \
        "--enable_replay_attack=true --replay_attack_percentage=$PERCENTAGE --replay_start_time=1.0 --replay_interval=0.25 --replay_count_per_node=20 --replay_max_captured_packets=500"

    run_simulation \
        "Replay Attack ${LABEL}% (With Detection - Bloom Filters)" \
        "test12_replay_${LABEL}_with_detection" \
        "--enable_replay_attack=true --replay_attack_percentage=$PERCENTAGE --replay_start_time=1.0 --replay_interval=0.25 --replay_count_per_node=20 --replay_max_captured_packets=500 --enable_replay_detection=true"

    run_simulation \
        "Replay Attack ${LABEL}% (With Full Mitigation)" \
        "test13_replay_${LABEL}_with_mitigation" \
        "--enable_replay_attack=true --replay_attack_percentage=$PERCENTAGE --replay_start_time=1.0 --replay_interval=0.25 --replay_count_per_node=20 --replay_max_captured_packets=500 --enable_replay_detection=true --enable_replay_mitigation=true"
done

# ============================================================================
# PHASE 6: RTP ATTACK (Routing Table Poisoning)
# ============================================================================
print_section "PHASE 6: RTP ATTACK - ROUTING TABLE POISONING (15 tests: 5 percentages × 3 scenarios)"

for i in "${!ATTACK_PERCENTAGES[@]}"; do
    PERCENTAGE="${ATTACK_PERCENTAGES[$i]}"
    LABEL="${ATTACK_PERCENTAGE_LABELS[$i]}"
    
    print_info "Testing RTP with ${LABEL}% attack percentage"
    
    run_simulation \
        "RTP Attack ${LABEL}% (No Mitigation)" \
        "test14_rtp_${LABEL}_no_mitigation" \
        "--enable_rtp_attack=true --rtp_attack_percentage=$PERCENTAGE --rtp_start_time=10.0 --rtp_inject_fake_routes=true --rtp_fabricate_mhls=true"

    run_simulation \
        "RTP Attack ${LABEL}% (With Hybrid-Shield Detection)" \
        "test15_rtp_${LABEL}_with_detection" \
        "--enable_rtp_attack=true --rtp_attack_percentage=$PERCENTAGE --rtp_start_time=10.0 --rtp_inject_fake_routes=true --rtp_fabricate_mhls=true --enable_hybrid_shield_detection=true"

    run_simulation \
        "RTP Attack ${LABEL}% (With Hybrid-Shield Full Mitigation)" \
        "test16_rtp_${LABEL}_with_mitigation" \
        "--enable_rtp_attack=true --rtp_attack_percentage=$PERCENTAGE --rtp_start_time=10.0 --rtp_inject_fake_routes=true --rtp_fabricate_mhls=true --enable_hybrid_shield_detection=true --enable_hybrid_shield_mitigation=true"
done

# ============================================================================
# PHASE 7: COMBINED ATTACK
# ============================================================================
print_section "PHASE 7: COMBINED ATTACK (5 tests: 5 percentages with all mitigations)"

for i in "${!ATTACK_PERCENTAGES[@]}"; do
    PERCENTAGE="${ATTACK_PERCENTAGES[$i]}"
    LABEL="${ATTACK_PERCENTAGE_LABELS[$i]}"
    
    print_info "Testing Combined Attack with ${LABEL}% attack percentage"
    
    run_simulation \
        "Combined Attack ${LABEL}% (All Attacks + All Mitigations)" \
        "test17_combined_${LABEL}_with_all_mitigations" \
        "--present_wormhole_attack_nodes=true --present_blackhole_attack_nodes=true --present_sybil_attack_nodes=true --use_enhanced_wormhole=true --attack_percentage=$PERCENTAGE --wormhole_bandwidth=1000Mbps --wormhole_delay_us=50000 --wormhole_tunnel_routing=true --wormhole_tunnel_data=true --enable_wormhole_detection=true --enable_wormhole_mitigation=true --wormhole_enable_verification_flows=true --enable_blackhole_attack=true --blackhole_attack_percentage=$PERCENTAGE --enable_blackhole_mitigation=true --enable_sybil_attack=true --sybil_attack_percentage=$PERCENTAGE --sybil_identities_per_node=3 --sybil_inject_fake_packets=true --enable_sybil_detection=true --enable_sybil_mitigation=true --enable_replay_attack=true --replay_attack_percentage=$PERCENTAGE --replay_start_time=1.0 --replay_interval=0.25 --replay_count_per_node=20 --replay_max_captured_packets=500 --enable_replay_detection=true --enable_replay_mitigation=true --enable_rtp_attack=true --rtp_attack_percentage=$PERCENTAGE --rtp_inject_fake_routes=true --rtp_fabricate_mhls=true --enable_hybrid_shield_detection=true --enable_hybrid_shield_mitigation=true"
done

# ============================================================================
# GENERATE SUMMARY
# ============================================================================
print_header "GENERATING TEST SUMMARY"

# Create summary file
SUMMARY_FILE="$RESULTS_DIR/evaluation_summary.txt"

cat > "$SUMMARY_FILE" << EOF
SDVN COMPLETE SECURITY EVALUATION SUMMARY
═══════════════════════════════════════════════════════════════

Test Date: $(date)
Results Directory: $RESULTS_DIR

Configuration:
  - Architecture: SDVN Centralized (architecture=0)
  - Simulation Time: ${SIM_TIME}s
  - Total Nodes: $TOTAL_NODES
  - Vehicles: $VEHICLES
  - RSUs: $RSUS
  - Attack Percentages: ${ATTACK_PERCENTAGE_LABELS[@]}%

Test Results:
─────────────────────────────────────────────────────────────

PHASE 1: BASELINE (1 test)
$([ -d "$RESULTS_DIR/test01_baseline" ] && echo "  ✓ Test 1: Baseline" || echo "  ✗ Test 1: Baseline")

PHASE 2: WORMHOLE ATTACK (15 tests)
$(for label in "${ATTACK_PERCENTAGE_LABELS[@]}"; do
    echo "  Attack Percentage: ${label}%"
    [ -d "$RESULTS_DIR/test02_wormhole_${label}_no_mitigation" ] && echo "    ✓ No Mitigation" || echo "    ✗ No Mitigation"
    [ -d "$RESULTS_DIR/test03_wormhole_${label}_with_detection" ] && echo "    ✓ With Detection" || echo "    ✗ With Detection"
    [ -d "$RESULTS_DIR/test04_wormhole_${label}_with_mitigation" ] && echo "    ✓ Full Mitigation" || echo "    ✗ Full Mitigation"
done)

PHASE 3: BLACKHOLE ATTACK (15 tests)
$(for label in "${ATTACK_PERCENTAGE_LABELS[@]}"; do
    echo "  Attack Percentage: ${label}%"
    [ -d "$RESULTS_DIR/test05_blackhole_${label}_no_mitigation" ] && echo "    ✓ No Mitigation" || echo "    ✗ No Mitigation"
    [ -d "$RESULTS_DIR/test06_blackhole_${label}_with_detection" ] && echo "    ✓ With Detection" || echo "    ✗ With Detection"
    [ -d "$RESULTS_DIR/test07_blackhole_${label}_with_mitigation" ] && echo "    ✓ Full Mitigation" || echo "    ✗ Full Mitigation"
done)

PHASE 4: SYBIL ATTACK (15 tests)
$(for label in "${ATTACK_PERCENTAGE_LABELS[@]}"; do
    echo "  Attack Percentage: ${label}%"
    [ -d "$RESULTS_DIR/test08_sybil_${label}_no_mitigation" ] && echo "    ✓ No Mitigation" || echo "    ✗ No Mitigation"
    [ -d "$RESULTS_DIR/test09_sybil_${label}_with_detection" ] && echo "    ✓ With Detection" || echo "    ✗ With Detection"
    [ -d "$RESULTS_DIR/test10_sybil_${label}_with_mitigation" ] && echo "    ✓ Full Mitigation" || echo "    ✗ Full Mitigation"
done)

PHASE 5: REPLAY ATTACK (15 tests)
$(for label in "${ATTACK_PERCENTAGE_LABELS[@]}"; do
    echo "  Attack Percentage: ${label}%"
    [ -d "$RESULTS_DIR/test11_replay_${label}_no_mitigation" ] && echo "    ✓ No Mitigation" || echo "    ✗ No Mitigation"
    [ -d "$RESULTS_DIR/test12_replay_${label}_with_detection" ] && echo "    ✓ With Detection" || echo "    ✗ With Detection"
    [ -d "$RESULTS_DIR/test13_replay_${label}_with_mitigation" ] && echo "    ✓ Full Mitigation" || echo "    ✗ Full Mitigation"
done)

PHASE 6: RTP ATTACK (15 tests)
$(for label in "${ATTACK_PERCENTAGE_LABELS[@]}"; do
    echo "  Attack Percentage: ${label}%"
    [ -d "$RESULTS_DIR/test14_rtp_${label}_no_mitigation" ] && echo "    ✓ No Mitigation" || echo "    ✗ No Mitigation"
    [ -d "$RESULTS_DIR/test15_rtp_${label}_with_detection" ] && echo "    ✓ With Detection" || echo "    ✗ With Detection"
    [ -d "$RESULTS_DIR/test16_rtp_${label}_with_mitigation" ] && echo "    ✓ Full Mitigation" || echo "    ✗ Full Mitigation"
done)

PHASE 7: COMBINED ATTACK (5 tests)
$(for label in "${ATTACK_PERCENTAGE_LABELS[@]}"; do
    [ -d "$RESULTS_DIR/test17_combined_${label}_with_all_mitigations" ] && echo "  ✓ Combined ${label}% (All Mitigations)" || echo "  ✗ Combined ${label}% (All Mitigations)"
done)

Statistics:
─────────────────────────────────────────────────────────────
  Total Tests: $TOTAL_TESTS
  Passed: $PASSED_TESTS
  Failed: $FAILED_TESTS
  Success Rate: $(awk "BEGIN {printf \"%.1f\", ($PASSED_TESTS/$TOTAL_TESTS)*100}")%

Attack Percentages Tested:
─────────────────────────────────────────────────────────────
  - 20% (14 attacker nodes out of $TOTAL_NODES)
  - 40% (28 attacker nodes out of $TOTAL_NODES)
  - 60% (42 attacker nodes out of $TOTAL_NODES)
  - 80% (56 attacker nodes out of $TOTAL_NODES)
  - 100% (70 attacker nodes out of $TOTAL_NODES)

Mitigation Solutions Tested:
─────────────────────────────────────────────────────────────
  1. Wormhole: RTT-based detection + route isolation
  2. Blackhole: Traffic pattern analysis + node isolation
  3. Sybil: Identity verification + MAC validation
  4. Replay: Bloom Filter sequence tracking + packet rejection
  5. RTP: Hybrid-Shield topology verification + route validation

Next Steps:
─────────────────────────────────────────────────────────────
  1. Run analysis script:
     python3 analyze_sdvn_complete_evaluation.py $RESULTS_DIR

  2. Review performance metrics:
     - Packet Delivery Ratio (PDR)
     - End-to-End Delay
     - Throughput
     - Attack Detection Rate
     - Mitigation Effectiveness
     - Scalability with increasing attack percentages

  3. Generate comparative visualizations:
     - Before vs After mitigation
     - Attack impact analysis
     - Mitigation overhead assessment
     - Attack percentage vs PDR curves

═══════════════════════════════════════════════════════════════
EOF

# Display summary
cat "$SUMMARY_FILE"

# ============================================================================
# FINAL REPORT
# ============================================================================
print_header "EVALUATION COMPLETE"

if [ $FAILED_TESTS -eq 0 ]; then
    print_success "All $TOTAL_TESTS tests passed!"
else
    print_warning "$FAILED_TESTS out of $TOTAL_TESTS tests failed"
fi

print_info "Results saved to: $RESULTS_DIR"
print_info "Summary file: $SUMMARY_FILE"
print_info ""
print_info "To analyze results, run:"
print_info "  python3 analyze_sdvn_complete_evaluation.py $RESULTS_DIR"

exit 0

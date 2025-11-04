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
VEHICLES=18
RSUS=10
ARCHITECTURE=0  # 0=centralized SDVN

# Test counter
TOTAL_TESTS=17
PASSED_TESTS=0
FAILED_TESTS=0

print_info "Results will be saved to: $RESULTS_DIR"
mkdir -p "$RESULTS_DIR"

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
print_section "PHASE 2: WORMHOLE ATTACK (3 tests)"

run_simulation \
    "Wormhole Attack 10% (No Mitigation)" \
    "test02_wormhole_10_no_mitigation" \
    "--present_wormhole_attack_nodes=true --use_enhanced_wormhole=true --attack_percentage=0.1"

run_simulation \
    "Wormhole Attack 10% (With Detection)" \
    "test03_wormhole_10_with_detection" \
    "--present_wormhole_attack_nodes=true --use_enhanced_wormhole=true --attack_percentage=0.1 --enable_wormhole_detection=true"

run_simulation \
    "Wormhole Attack 10% (With Full Mitigation)" \
    "test04_wormhole_10_with_mitigation" \
    "--present_wormhole_attack_nodes=true --use_enhanced_wormhole=true --attack_percentage=0.1 --enable_wormhole_detection=true --enable_wormhole_mitigation=true"

# ============================================================================
# PHASE 3: BLACKHOLE ATTACK
# ============================================================================
print_section "PHASE 3: BLACKHOLE ATTACK (3 tests)"

run_simulation \
    "Blackhole Attack 10% (No Mitigation)" \
    "test05_blackhole_10_no_mitigation" \
    "--present_blackhole_attack_nodes=true --attack_percentage=0.1 --enable_blackhole_attack=true --blackhole_attack_percentage=0.1 --blackhole_advertise_fake_routes=true"

run_simulation \
    "Blackhole Attack 10% (With Detection)" \
    "test06_blackhole_10_with_detection" \
    "--present_blackhole_attack_nodes=true --attack_percentage=0.1 --enable_blackhole_attack=true --blackhole_attack_percentage=0.1 --blackhole_advertise_fake_routes=true --enable_blackhole_detection=true"

run_simulation \
    "Blackhole Attack 10% (With Full Mitigation)" \
    "test07_blackhole_10_with_mitigation" \
    "--present_blackhole_attack_nodes=true --attack_percentage=0.1 --enable_blackhole_attack=true --blackhole_attack_percentage=0.1 --blackhole_advertise_fake_routes=true --enable_blackhole_mitigation=true"

# ============================================================================
# PHASE 4: SYBIL ATTACK
# ============================================================================
print_section "PHASE 4: SYBIL ATTACK (3 tests)"

run_simulation \
    "Sybil Attack 10% (No Mitigation)" \
    "test08_sybil_10_no_mitigation" \
    "--present_sybil_attack_nodes=true --attack_percentage=0.1 --enable_sybil_attack=true --sybil_attack_percentage=0.1 --sybil_advertise_fake_routes=true --sybil_clone_legitimate_nodes=true"

run_simulation \
    "Sybil Attack 10% (With Detection)" \
    "test09_sybil_10_with_detection" \
    "--present_sybil_attack_nodes=true --attack_percentage=0.1 --enable_sybil_attack=true --sybil_attack_percentage=0.1 --sybil_advertise_fake_routes=true --sybil_clone_legitimate_nodes=true --enable_sybil_detection=true --use_trusted_certification=true --use_rssi_detection=true"

run_simulation \
    "Sybil Attack 10% (With Full Mitigation)" \
    "test10_sybil_10_with_mitigation" \
    "--present_sybil_attack_nodes=true --attack_percentage=0.1 --enable_sybil_attack=true --sybil_attack_percentage=0.1 --sybil_advertise_fake_routes=true --sybil_clone_legitimate_nodes=true --enable_sybil_detection=true --enable_sybil_mitigation=true --enable_sybil_mitigation_advanced=true --use_trusted_certification=true --use_rssi_detection=true"

# ============================================================================
# PHASE 5: REPLAY ATTACK
# ============================================================================
print_section "PHASE 5: REPLAY ATTACK (3 tests)"

run_simulation \
    "Replay Attack 10% (No Mitigation)" \
    "test11_replay_10_no_mitigation" \
    "--present_replay_attack_nodes=true --enable_replay_attack=true --replay_attack_percentage=0.1 --replay_start_time=10.0"

run_simulation \
    "Replay Attack 10% (With Detection - Bloom Filters)" \
    "test12_replay_10_with_detection" \
    "--present_replay_attack_nodes=true --enable_replay_attack=true --replay_attack_percentage=0.1 --replay_start_time=10.0 --enable_replay_detection=true"

run_simulation \
    "Replay Attack 10% (With Full Mitigation)" \
    "test13_replay_10_with_mitigation" \
    "--present_replay_attack_nodes=true --enable_replay_attack=true --replay_attack_percentage=0.1 --replay_start_time=10.0 --enable_replay_detection=true --enable_replay_mitigation=true"

# ============================================================================
# PHASE 6: RTP ATTACK (Routing Table Poisoning)
# ============================================================================
print_section "PHASE 6: RTP ATTACK - ROUTING TABLE POISONING (3 tests)"

run_simulation \
    "RTP Attack 10% (No Mitigation)" \
    "test14_rtp_10_no_mitigation" \
    "--enable_rtp_attack=true --rtp_attack_percentage=0.1 --rtp_start_time=10.0"

run_simulation \
    "RTP Attack 10% (With Hybrid-Shield Detection)" \
    "test15_rtp_10_with_detection" \
    "--enable_rtp_attack=true --rtp_attack_percentage=0.1 --rtp_start_time=10.0 --enable_hybrid_shield_detection=true"

run_simulation \
    "RTP Attack 10% (With Hybrid-Shield Full Mitigation)" \
    "test16_rtp_10_with_mitigation" \
    "--enable_rtp_attack=true --rtp_attack_percentage=0.1 --rtp_start_time=10.0 --enable_hybrid_shield_detection=true --enable_hybrid_shield_mitigation=true"

# ============================================================================
# PHASE 7: COMBINED ATTACK
# ============================================================================
print_section "PHASE 7: COMBINED ATTACK (1 test)"

run_simulation \
    "Combined Attack 10% (All Attacks + All Mitigations)" \
    "test17_combined_10_with_all_mitigations" \
    "--present_wormhole_attack_nodes=true --present_blackhole_attack_nodes=true --present_sybil_attack_nodes=true --present_replay_attack_nodes=true --use_enhanced_wormhole=true --attack_percentage=0.1 --enable_wormhole_detection=true --enable_wormhole_mitigation=true --enable_blackhole_attack=true --blackhole_attack_percentage=0.1 --enable_blackhole_mitigation=true --enable_sybil_attack=true --sybil_attack_percentage=0.1 --enable_sybil_detection=true --enable_sybil_mitigation=true --enable_replay_attack=true --replay_attack_percentage=0.1 --enable_replay_detection=true --enable_replay_mitigation=true --enable_rtp_attack=true --rtp_attack_percentage=0.1 --enable_hybrid_shield_detection=true --enable_hybrid_shield_mitigation=true"

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
  - Vehicles: $VEHICLES
  - RSUs: $RSUS
  - Attack Percentage: 10%

Test Results:
─────────────────────────────────────────────────────────────

PHASE 1: BASELINE
$([ -d "$RESULTS_DIR/test01_baseline" ] && echo "  ✓ Test 1: Baseline" || echo "  ✗ Test 1: Baseline")

PHASE 2: WORMHOLE ATTACK
$([ -d "$RESULTS_DIR/test02_wormhole_10_no_mitigation" ] && echo "  ✓ Test 2: Wormhole 10% (No Mitigation)" || echo "  ✗ Test 2: Wormhole 10% (No Mitigation)")
$([ -d "$RESULTS_DIR/test03_wormhole_10_with_detection" ] && echo "  ✓ Test 3: Wormhole 10% (With Detection)" || echo "  ✗ Test 3: Wormhole 10% (With Detection)")
$([ -d "$RESULTS_DIR/test04_wormhole_10_with_mitigation" ] && echo "  ✓ Test 4: Wormhole 10% (Full Mitigation)" || echo "  ✗ Test 4: Wormhole 10% (Full Mitigation)")

PHASE 3: BLACKHOLE ATTACK
$([ -d "$RESULTS_DIR/test05_blackhole_10_no_mitigation" ] && echo "  ✓ Test 5: Blackhole 10% (No Mitigation)" || echo "  ✗ Test 5: Blackhole 10% (No Mitigation)")
$([ -d "$RESULTS_DIR/test06_blackhole_10_with_detection" ] && echo "  ✓ Test 6: Blackhole 10% (With Detection)" || echo "  ✗ Test 6: Blackhole 10% (With Detection)")
$([ -d "$RESULTS_DIR/test07_blackhole_10_with_mitigation" ] && echo "  ✓ Test 7: Blackhole 10% (Full Mitigation)" || echo "  ✗ Test 7: Blackhole 10% (Full Mitigation)")

PHASE 4: SYBIL ATTACK
$([ -d "$RESULTS_DIR/test08_sybil_10_no_mitigation" ] && echo "  ✓ Test 8: Sybil 10% (No Mitigation)" || echo "  ✗ Test 8: Sybil 10% (No Mitigation)")
$([ -d "$RESULTS_DIR/test09_sybil_10_with_detection" ] && echo "  ✓ Test 9: Sybil 10% (With Detection)" || echo "  ✗ Test 9: Sybil 10% (With Detection)")
$([ -d "$RESULTS_DIR/test10_sybil_10_with_mitigation" ] && echo "  ✓ Test 10: Sybil 10% (Full Mitigation)" || echo "  ✗ Test 10: Sybil 10% (Full Mitigation)")

PHASE 5: REPLAY ATTACK
$([ -d "$RESULTS_DIR/test11_replay_10_no_mitigation" ] && echo "  ✓ Test 11: Replay 10% (No Mitigation)" || echo "  ✗ Test 11: Replay 10% (No Mitigation)")
$([ -d "$RESULTS_DIR/test12_replay_10_with_detection" ] && echo "  ✓ Test 12: Replay 10% (Bloom Filter Detection)" || echo "  ✗ Test 12: Replay 10% (Bloom Filter Detection)")
$([ -d "$RESULTS_DIR/test13_replay_10_with_mitigation" ] && echo "  ✓ Test 13: Replay 10% (Full Mitigation)" || echo "  ✗ Test 13: Replay 10% (Full Mitigation)")

PHASE 6: RTP ATTACK
$([ -d "$RESULTS_DIR/test14_rtp_10_no_mitigation" ] && echo "  ✓ Test 14: RTP 10% (No Mitigation)" || echo "  ✗ Test 14: RTP 10% (No Mitigation)")
$([ -d "$RESULTS_DIR/test15_rtp_10_with_detection" ] && echo "  ✓ Test 15: RTP 10% (Hybrid-Shield Detection)" || echo "  ✗ Test 15: RTP 10% (Hybrid-Shield Detection)")
$([ -d "$RESULTS_DIR/test16_rtp_10_with_mitigation" ] && echo "  ✓ Test 16: RTP 10% (Hybrid-Shield Mitigation)" || echo "  ✗ Test 16: RTP 10% (Hybrid-Shield Mitigation)")

PHASE 7: COMBINED ATTACK
$([ -d "$RESULTS_DIR/test17_combined_10_with_all_mitigations" ] && echo "  ✓ Test 17: Combined Attack with All Mitigations" || echo "  ✗ Test 17: Combined Attack with All Mitigations")

Statistics:
─────────────────────────────────────────────────────────────
  Total Tests: $TOTAL_TESTS
  Passed: $PASSED_TESTS
  Failed: $FAILED_TESTS
  Success Rate: $(awk "BEGIN {printf \"%.1f\", ($PASSED_TESTS/$TOTAL_TESTS)*100}")%

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

  3. Generate comparative visualizations:
     - Before vs After mitigation
     - Attack impact analysis
     - Mitigation overhead assessment

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

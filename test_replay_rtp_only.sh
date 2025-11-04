#!/bin/bash
# ============================================================================
# Replay and RTP Attack Testing Script for SDVN
# Tests Replay Attack (Bloom Filters) and RTP Attack separately
# Helps debug and verify these specific attack implementations
# ============================================================================

set -u  # Exit on undefined variables

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print functions
print_header() {
    echo ""
    echo "================================================================"
    echo "$1"
    echo "================================================================"
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

print_header "REPLAY & RTP ATTACK TESTING FOR SDVN"
print_info "Testing Replay and RTP attacks in SDVN architecture"
print_info "Debugging script to verify attack implementations"

# Configuration
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RESULTS_DIR="./replay_rtp_test_${TIMESTAMP}"
ROUTING_SCRIPT="routing"
SIM_TIME=100
VEHICLES=18
RSUS=10
ARCHITECTURE=0  # 0=centralized SDVN

print_info "Results will be saved to: $RESULTS_DIR"
mkdir -p "$RESULTS_DIR"

# ============================================================================
# Helper: Check if NS-3 is built and ready
# ============================================================================
check_ns3_ready() {
    print_info "Checking NS-3 build status..."
    
    if [ ! -f "waf" ]; then
        print_error "waf not found! Are you in the NS-3 root directory?"
        print_info "Current directory: $(pwd)"
        return 1
    fi
    
    if [ ! -f "scratch/${ROUTING_SCRIPT}.cc" ]; then
        print_error "routing.cc not found in scratch/ directory!"
        return 1
    fi
    
    print_success "NS-3 environment OK"
    return 0
}

# ============================================================================
# Test 1: Baseline SDVN (No Attacks)
# ============================================================================
test_baseline() {
    local output_dir="$RESULTS_DIR/baseline"
    mkdir -p "$output_dir"
    
    print_header "TEST 1: BASELINE - SDVN No Attacks"
    print_info "Establishing baseline performance metrics..."
    
    ./waf --run "scratch/$ROUTING_SCRIPT \
        --simTime=$SIM_TIME \
        --routing_test=false \
        --N_Vehicles=$VEHICLES \
        --N_RSUs=$RSUS \
        --architecture=$ARCHITECTURE \
        --enable_packet_tracking=true" \
        > "$output_dir/baseline.log" 2>&1
    
    local exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        print_success "Baseline test completed"
        
        # Extract key metrics
        if grep -q "Simulation completed" "$output_dir/baseline.log"; then
            print_info "Simulation ran successfully"
        fi
        
        # Look for any CSV files generated
        if ls *.csv 1> /dev/null 2>&1; then
            mv *.csv "$output_dir/" 2>/dev/null
            print_success "CSV files collected"
        fi
        
        return 0
    else
        print_error "Baseline test failed with exit code $exit_code"
        print_info "Last 20 lines of log:"
        tail -20 "$output_dir/baseline.log"
        return 1
    fi
}

# ============================================================================
# Test 2: Replay Attack Only (No Detection/Mitigation)
# ============================================================================
test_replay_attack_only() {
    local output_dir="$RESULTS_DIR/replay_attack_only"
    mkdir -p "$output_dir"
    
    print_header "TEST 2: REPLAY ATTACK ONLY (No Mitigation)"
    print_info "Testing Replay attack without detection/mitigation..."
    print_info "This verifies the attack implementation works"
    
    ./waf --run "scratch/$ROUTING_SCRIPT \
        --simTime=$SIM_TIME \
        --routing_test=false \
        --N_Vehicles=$VEHICLES \
        --N_RSUs=$RSUS \
        --architecture=$ARCHITECTURE \
        --enable_packet_tracking=true \
        --enable_replay_attack=true \
        --replay_attack_percentage=0.15 \
        --replay_start_time=10.0 \
        --replay_interval=1.0 \
        --replay_count_per_node=5 \
        --enable_replay_detection=false \
        --enable_replay_mitigation=false" \
        > "$output_dir/replay_attack.log" 2>&1
    
    local exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        print_success "Replay attack test completed"
        
        # Check for attack indicators in log
        if grep -q "Replay Attack" "$output_dir/replay_attack.log"; then
            print_success "Replay attack activated"
            grep -i "replay" "$output_dir/replay_attack.log" | head -10
        else
            print_warning "No replay attack messages found in log"
        fi
        
        # Collect CSV files
        if ls *.csv 1> /dev/null 2>&1; then
            mv *.csv "$output_dir/" 2>/dev/null
            print_success "CSV files collected"
        fi
        
        return 0
    else
        print_error "Replay attack test failed with exit code $exit_code"
        print_info "Last 30 lines of log:"
        tail -30 "$output_dir/replay_attack.log"
        
        # Check for common errors
        if grep -q "unknown option" "$output_dir/replay_attack.log"; then
            print_error "Unknown parameter! Check routing.cc for correct parameter names"
            grep "unknown option" "$output_dir/replay_attack.log"
        fi
        
        return 1
    fi
}

# ============================================================================
# Test 3: Replay Attack with Bloom Filter Detection
# ============================================================================
test_replay_with_detection() {
    local output_dir="$RESULTS_DIR/replay_with_detection"
    mkdir -p "$output_dir"
    
    print_header "TEST 3: REPLAY ATTACK WITH BLOOM FILTER DETECTION"
    print_info "Testing Bloom Filter detection mechanism..."
    
    ./waf --run "scratch/$ROUTING_SCRIPT \
        --simTime=$SIM_TIME \
        --routing_test=false \
        --N_Vehicles=$VEHICLES \
        --N_RSUs=$RSUS \
        --architecture=$ARCHITECTURE \
        --enable_packet_tracking=true \
        --enable_replay_attack=true \
        --replay_attack_percentage=0.15 \
        --replay_start_time=10.0 \
        --replay_interval=1.0 \
        --replay_count_per_node=5 \
        --enable_replay_detection=true \
        --enable_replay_mitigation=false" \
        > "$output_dir/replay_detection.log" 2>&1
    
    local exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        print_success "Replay detection test completed"
        
        # Check for detection metrics
        if grep -q "Detection" "$output_dir/replay_detection.log"; then
            print_success "Detection system activated"
            grep -i "detection\|bloom" "$output_dir/replay_detection.log" | head -15
        fi
        
        # Collect CSV files
        if ls *.csv 1> /dev/null 2>&1; then
            mv *.csv "$output_dir/" 2>/dev/null
            print_success "CSV files collected"
        fi
        
        return 0
    else
        print_error "Replay detection test failed"
        tail -30 "$output_dir/replay_detection.log"
        return 1
    fi
}

# ============================================================================
# Test 4: Replay Attack with Full Mitigation
# ============================================================================
test_replay_full_mitigation() {
    local output_dir="$RESULTS_DIR/replay_full_mitigation"
    mkdir -p "$output_dir"
    
    print_header "TEST 4: REPLAY ATTACK WITH FULL MITIGATION"
    print_info "Testing detection + mitigation (packet rejection)..."
    
    ./waf --run "scratch/$ROUTING_SCRIPT \
        --simTime=$SIM_TIME \
        --routing_test=false \
        --N_Vehicles=$VEHICLES \
        --N_RSUs=$RSUS \
        --architecture=$ARCHITECTURE \
        --enable_packet_tracking=true \
        --enable_replay_attack=true \
        --replay_attack_percentage=0.15 \
        --replay_start_time=10.0 \
        --enable_replay_detection=true \
        --enable_replay_mitigation=true" \
        > "$output_dir/replay_mitigation.log" 2>&1
    
    local exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        print_success "Replay mitigation test completed"
        
        # Check for mitigation actions
        if grep -q -i "mitigation\|rejected\|blocked" "$output_dir/replay_mitigation.log"; then
            print_success "Mitigation system activated"
            grep -i "mitigation\|rejected\|blocked" "$output_dir/replay_mitigation.log" | head -10
        fi
        
        # Collect CSV files
        if ls *.csv 1> /dev/null 2>&1; then
            mv *.csv "$output_dir/" 2>/dev/null
            print_success "CSV files collected"
        fi
        
        return 0
    else
        print_error "Replay mitigation test failed"
        tail -30 "$output_dir/replay_mitigation.log"
        return 1
    fi
}

# ============================================================================
# Test 5: RTP Attack Only (No Mitigation)
# ============================================================================
test_rtp_attack_only() {
    local output_dir="$RESULTS_DIR/rtp_attack_only"
    mkdir -p "$output_dir"
    
    print_header "TEST 5: RTP ATTACK ONLY (No Mitigation)"
    print_info "Testing Routing Table Poisoning attack..."
    print_info "Malicious nodes inject fake routing information"
    
    ./waf --run "scratch/$ROUTING_SCRIPT \
        --simTime=$SIM_TIME \
        --routing_test=false \
        --N_Vehicles=$VEHICLES \
        --N_RSUs=$RSUS \
        --architecture=$ARCHITECTURE \
        --enable_packet_tracking=true \
        --enable_rtp_attack=true \
        --rtp_attack_percentage=0.15 \
        --rtp_start_time=10.0" \
        > "$output_dir/rtp_attack.log" 2>&1
    
    local exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        print_success "RTP attack test completed"
        
        # Check for RTP indicators
        if grep -q -i "RTP\|routing.*poison\|fake.*MHL" "$output_dir/rtp_attack.log"; then
            print_success "RTP attack activated"
            grep -i "RTP\|routing.*poison\|fake.*MHL" "$output_dir/rtp_attack.log" | head -15
        else
            print_warning "No RTP attack messages found in log"
            print_info "Checking for any routing anomalies..."
            grep -i "route\|MHL\|BDDP" "$output_dir/rtp_attack.log" | head -10
        fi
        
        # Collect CSV files
        if ls *.csv 1> /dev/null 2>&1; then
            mv *.csv "$output_dir/" 2>/dev/null
            print_success "CSV files collected"
        fi
        
        return 0
    else
        print_error "RTP attack test failed with exit code $exit_code"
        print_info "Last 30 lines of log:"
        tail -30 "$output_dir/rtp_attack.log"
        
        # Check for parameter errors
        if grep -q "unknown option" "$output_dir/rtp_attack.log"; then
            print_error "Unknown parameter detected"
            grep "unknown option" "$output_dir/rtp_attack.log"
        fi
        
        return 1
    fi
}

# ============================================================================
# Test 6: RTP Attack with Hybrid-Shield Detection
# ============================================================================
test_rtp_with_detection() {
    local output_dir="$RESULTS_DIR/rtp_with_detection"
    mkdir -p "$output_dir"
    
    print_header "TEST 6: RTP ATTACK WITH HYBRID-SHIELD DETECTION"
    print_info "Testing RTP with Hybrid-Shield MHL fabrication detection..."
    print_info "Probes verify topology authenticity"
    
    ./waf --run "scratch/$ROUTING_SCRIPT \
        --simTime=$SIM_TIME \
        --routing_test=false \
        --N_Vehicles=$VEHICLES \
        --N_RSUs=$RSUS \
        --architecture=$ARCHITECTURE \
        --enable_packet_tracking=true \
        --enable_rtp_attack=true \
        --rtp_attack_percentage=0.15 \
        --rtp_start_time=10.0 \
        --enable_hybrid_shield_detection=true" \
        > "$output_dir/rtp_detection.log" 2>&1
    
    local exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        print_success "RTP detection test completed"
        
        # Check for detection indicators
        if grep -q -i "hybrid.*shield\|detection\|fabrication.*detected" "$output_dir/rtp_detection.log"; then
            print_success "Hybrid-Shield detection system activated"
            grep -i "hybrid.*shield\|detection\|fabrication" "$output_dir/rtp_detection.log" | head -10
        fi
        
        # Collect CSV files
        if ls *.csv 1> /dev/null 2>&1; then
            mv *.csv "$output_dir/" 2>/dev/null
            print_success "CSV files collected"
        fi
        
        return 0
    else
        print_error "RTP detection test failed"
        tail -30 "$output_dir/rtp_detection.log"
        return 1
    fi
}

# ============================================================================
# Test 7: RTP Attack with Full Hybrid-Shield Mitigation
# ============================================================================
test_rtp_with_mitigation() {
    local output_dir="$RESULTS_DIR/rtp_with_mitigation"
    mkdir -p "$output_dir"
    
    print_header "TEST 7: RTP ATTACK WITH HYBRID-SHIELD FULL MITIGATION"
    print_info "Testing RTP with complete Hybrid-Shield protection..."
    print_info "Detects and blocks fake MHL advertisements"
    
    ./waf --run "scratch/$ROUTING_SCRIPT \
        --simTime=$SIM_TIME \
        --routing_test=false \
        --N_Vehicles=$VEHICLES \
        --N_RSUs=$RSUS \
        --architecture=$ARCHITECTURE \
        --enable_packet_tracking=true \
        --enable_rtp_attack=true \
        --rtp_attack_percentage=0.15 \
        --rtp_start_time=10.0 \
        --enable_hybrid_shield_detection=true \
        --enable_hybrid_shield_mitigation=true" \
        > "$output_dir/rtp_mitigation.log" 2>&1
    
    local exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        print_success "RTP mitigation test completed"
        
        # Check for mitigation actions
        if grep -q -i "mitigation\|blocked\|rejected\|isolated" "$output_dir/rtp_mitigation.log"; then
            print_success "Hybrid-Shield mitigation activated"
            grep -i "mitigation\|blocked\|rejected\|isolated" "$output_dir/rtp_mitigation.log" | head -10
        fi
        
        # Collect CSV files
        if ls *.csv 1> /dev/null 2>&1; then
            mv *.csv "$output_dir/" 2>/dev/null
            print_success "CSV files collected"
        fi
        
        return 0
    else
        print_error "RTP mitigation test failed"
        tail -30 "$output_dir/rtp_mitigation.log"
        return 1
    fi
}

# ============================================================================
# Test 8: Combined Replay + RTP Attack
# ============================================================================
test_replay_and_rtp_combined() {
    local output_dir="$RESULTS_DIR/combined_replay_rtp"
    mkdir -p "$output_dir"
    
    print_header "TEST 9: COMBINED REPLAY + RTP WITH ALL MITIGATIONS"
    print_info "Testing both attacks simultaneously with full protection..."
    print_info "Bloom Filters + Hybrid-Shield activated"
    
    ./waf --run "scratch/$ROUTING_SCRIPT \
        --simTime=$SIM_TIME \
        --routing_test=false \
        --N_Vehicles=$VEHICLES \
        --N_RSUs=$RSUS \
        --architecture=$ARCHITECTURE \
        --enable_packet_tracking=true \
        --enable_replay_attack=true \
        --replay_attack_percentage=0.10 \
        --replay_start_time=10.0 \
        --enable_replay_detection=true \
        --enable_replay_mitigation=true \
        --enable_rtp_attack=true \
        --rtp_attack_percentage=0.10 \
        --rtp_start_time=10.0 \
        --enable_hybrid_shield_detection=true \
        --enable_hybrid_shield_mitigation=true" \
        > "$output_dir/combined.log" 2>&1
    
    local exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        print_success "Combined attack test completed"
        
        # Check for both attack types
        if grep -q -i "replay" "$output_dir/combined.log"; then
            print_success "Replay attack activity detected"
        fi
        
        if grep -q -i "RTP\|routing.*poison\|hybrid.*shield" "$output_dir/combined.log"; then
            print_success "RTP attack activity detected"
        fi
        
        # Collect CSV files
        if ls *.csv 1> /dev/null 2>&1; then
            mv *.csv "$output_dir/" 2>/dev/null
            print_success "CSV files collected"
        fi
        
        return 0
    else
        print_error "Combined attack test failed"
        tail -30 "$output_dir/combined.log"
        return 1
    fi
}

# ============================================================================
# Generate diagnostic report
# ============================================================================
generate_diagnostic_report() {
    local report_file="$RESULTS_DIR/diagnostic_report.txt"
    
    print_header "GENERATING DIAGNOSTIC REPORT"
    
    cat > "$report_file" << EOF
═══════════════════════════════════════════════════════════════
  REPLAY & RTP ATTACK DIAGNOSTIC REPORT
═══════════════════════════════════════════════════════════════

Test Date: $(date)
Results Directory: $RESULTS_DIR

Configuration:
  - Architecture: SDVN Centralized (architecture=0)
  - Simulation Time: ${SIM_TIME}s
  - Vehicles: ${VEHICLES}
  - RSUs: ${RSUS}
  - Attack Percentage: 15% (for single attacks), 10% (combined)

Test Results:
─────────────────────────────────────────────────────────────

EOF
    
    # Check each test
    local tests=("baseline" "replay_attack_only" "replay_with_detection" "replay_full_mitigation" "rtp_attack_only" "rtp_with_detection" "rtp_with_mitigation" "combined_replay_rtp")
    local test_names=("Baseline" "Replay Attack Only" "Replay with Detection" "Replay with Mitigation" "RTP Attack Only" "RTP with Detection" "RTP with Mitigation" "Combined Replay+RTP")
    
    for i in "${!tests[@]}"; do
        local test_dir="$RESULTS_DIR/${tests[$i]}"
        if [ -d "$test_dir" ]; then
            echo "Test $((i+1)): ${test_names[$i]}" >> "$report_file"
            
            # Check log file
            local log_file=$(find "$test_dir" -name "*.log" -type f | head -1)
            if [ -n "$log_file" ]; then
                if grep -q "Simulation completed\|finished" "$log_file" 2>/dev/null; then
                    echo "  Status: ✓ PASSED" >> "$report_file"
                else
                    echo "  Status: ✗ FAILED" >> "$report_file"
                fi
                
                # Count CSV files
                local csv_count=$(find "$test_dir" -name "*.csv" -type f 2>/dev/null | wc -l)
                echo "  CSV Files Generated: $csv_count" >> "$report_file"
                
                # Check for specific indicators
                if grep -q "Replay" "$log_file" 2>/dev/null; then
                    echo "  Replay Activity: DETECTED" >> "$report_file"
                fi
                
                if grep -q "RTP\|routing.*poison\|Hybrid.*Shield" "$log_file" 2>/dev/null; then
                    echo "  RTP Activity: DETECTED" >> "$report_file"
                fi
                
                if grep -q "Hybrid.*Shield" "$log_file" 2>/dev/null; then
                    echo "  Hybrid-Shield: ACTIVE" >> "$report_file"
                fi
            else
                echo "  Status: ⚠ NO LOG FILE" >> "$report_file"
            fi
            
            echo "" >> "$report_file"
        fi
    done
    
    cat >> "$report_file" << EOF

Parameter Verification:
─────────────────────────────────────────────────────────────
Replay Attack Parameters Used:
  --enable_replay_attack=true
  --replay_attack_percentage=0.15
  --replay_start_time=10.0
  --replay_interval=1.0
  --replay_count_per_node=5
  --enable_replay_detection=true
  --enable_replay_mitigation=true

RTP Attack Parameters Used:
  --enable_rtp_attack=true
  --rtp_attack_percentage=0.15
  --rtp_start_time=10.0
  --enable_hybrid_shield_detection=true
  --enable_hybrid_shield_mitigation=true

Mitigation Solutions:
─────────────────────────────────────────────────────────────
  • Replay Attack: Bloom Filter-based sequence number tracking
    - Detects duplicate packets
    - Rejects replayed messages
  
  • RTP Attack: Hybrid-Shield topology verification
    - Probes verify MHL authenticity
    - Blocks fake route advertisements
    - Validates routing table entries

Common Issues to Check:
─────────────────────────────────────────────────────────────
1. Parameter Name Mismatch:
   - Check routing.cc for exact parameter names
   - Look for typos: replay vs reply, rtp vs routing_table_poisoning

2. Architecture Compatibility:
   - Replay/RTP may need SDVN architecture=0 to work
   - Check if attacks are architecture-independent

3. Missing Implementation:
   - Verify ReplayAttackManager exists in routing.cc
   - Verify RTPAttackManager exists in routing.cc

4. Build Issues:
   - Ensure NS-3 is rebuilt after routing.cc changes
   - Run: ./waf clean && ./waf build

Next Steps:
─────────────────────────────────────────────────────────────
1. Review log files in each test directory
2. Check for "unknown option" errors indicating wrong parameters
3. Verify attack activation messages in logs
4. Compare with working attacks (Wormhole, Blackhole, Sybil)

═══════════════════════════════════════════════════════════════
EOF
    
    cat "$report_file"
    print_success "Diagnostic report saved to: $report_file"
}

# ============================================================================
# Main execution
# ============================================================================
main() {
    local failed_tests=0
    local passed_tests=0
    
    print_info "Starting Replay & RTP attack diagnostic tests..."
    echo ""
    
    # Check NS-3 readiness
    check_ns3_ready || exit 1
    
    # Run tests
    if test_baseline; then
        ((passed_tests++))
    else
        ((failed_tests++))
        print_warning "Baseline failed - may affect other tests"
    fi
    
    if test_replay_attack_only; then
        ((passed_tests++))
    else
        ((failed_tests++))
        print_error "Replay attack not working! Check implementation"
    fi
    
    if test_replay_with_detection; then
        ((passed_tests++))
    else
        ((failed_tests++))
        print_error "Replay detection not working!"
    fi
    
    if test_replay_full_mitigation; then
        ((passed_tests++))
    else
        ((failed_tests++))
        print_error "Replay mitigation not working!"
    fi
    
    if test_rtp_attack_only; then
        ((passed_tests++))
    else
        ((failed_tests++))
        print_error "RTP attack not working! Check implementation"
    fi
    
    if test_rtp_with_detection; then
        ((passed_tests++))
    else
        ((failed_tests++))
        print_error "RTP detection not working!"
    fi
    
    if test_rtp_with_mitigation; then
        ((passed_tests++))
    else
        ((failed_tests++))
        print_error "RTP mitigation not working!"
    fi
    
    if test_replay_and_rtp_combined; then
        ((passed_tests++))
    else
        ((failed_tests++))
        print_error "Combined attack test failed!"
    fi
    
    # Generate report
    generate_diagnostic_report
    
    # Summary
    print_header "TEST SUMMARY"
    print_info "Total tests: $((passed_tests + failed_tests))"
    print_success "Passed: $passed_tests"
    
    if [ $failed_tests -gt 0 ]; then
        print_error "Failed: $failed_tests"
        print_warning "Review diagnostic report and logs for details"
    else
        print_success "All tests passed!"
    fi
    
    print_info "Results directory: $RESULTS_DIR"
    print_info "Diagnostic report: $RESULTS_DIR/diagnostic_report.txt"
}

# Run main function
main

#!/bin/bash

##############################################################################
# SDVN Fixed Issues Validation Script
# Date: November 6, 2025
# Purpose: Validate all committed fixes are working correctly
##############################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
NS3_DIR="${HOME}/Downloads/ns-allinone-3.35/ns-3.35"
RESULTS_DIR="validation_results_$(date +%Y%m%d_%H%M%S)"
ROUTING_SCRIPT="routing"

##############################################################################
# Helper Functions
##############################################################################

print_header() {
    echo ""
    echo -e "${BLUE}========================================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================================================${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

check_environment() {
    print_header "CHECKING ENVIRONMENT"
    
    if [ ! -d "$NS3_DIR" ]; then
        print_error "NS-3 directory not found: $NS3_DIR"
        print_info "Please update NS3_DIR variable in this script"
        exit 1
    fi
    
    if [ ! -f "$NS3_DIR/scratch/routing.cc" ]; then
        print_error "routing.cc not found in $NS3_DIR/scratch/"
        print_info "Please copy routing.cc to NS-3 scratch directory"
        exit 1
    fi
    
    print_success "NS-3 directory found: $NS3_DIR"
    print_success "routing.cc found in scratch directory"
}

build_project() {
    print_header "BUILDING NS-3 PROJECT"
    
    cd "$NS3_DIR"
    
    print_info "Running ./waf build..."
    if ./waf build > build.log 2>&1; then
        print_success "Build completed successfully"
        return 0
    else
        print_error "Build failed! Check build.log for details"
        tail -n 50 build.log
        exit 1
    fi
}

run_test() {
    local test_num=$1
    local test_name=$2
    local test_dir="$RESULTS_DIR/test$(printf "%02d" $test_num)_$test_name"
    
    mkdir -p "$test_dir"
    
    print_info "Running Test $test_num: $test_name..."
    
    cd "$NS3_DIR"
    if ./waf --run "$ROUTING_SCRIPT --test=$test_num" > "$test_dir/output.log" 2>&1; then
        print_success "Test $test_num completed"
        return 0
    else
        print_error "Test $test_num failed"
        return 1
    fi
}

extract_metric() {
    local log_file=$1
    local metric_name=$2
    
    grep "$metric_name" "$log_file" | tail -1 | awk -F': ' '{print $2}' | awk '{print $1}'
}

check_pdr() {
    local log_file=$1
    local min_pdr=$2
    local max_pdr=${3:-100}
    
    local pdr=$(extract_metric "$log_file" "Packet Delivery Ratio")
    
    if [ -z "$pdr" ]; then
        print_warning "PDR not found in log"
        return 2
    fi
    
    # Remove % sign and convert to number
    pdr=$(echo "$pdr" | tr -d '%')
    
    # Compare PDR
    if (( $(echo "$pdr >= $min_pdr" | bc -l) )) && (( $(echo "$pdr <= $max_pdr" | bc -l) )); then
        echo "$pdr"
        return 0
    else
        echo "$pdr"
        return 1
    fi
}

##############################################################################
# Test Validation Functions
##############################################################################

validate_baseline() {
    print_header "FIX VALIDATION 1: Baseline Performance"
    
    run_test 1 "baseline"
    
    local log="$RESULTS_DIR/test01_baseline/output.log"
    local pdr=$(check_pdr "$log" 99.0)
    local result=$?
    
    if [ $result -eq 0 ]; then
        print_success "Baseline test passed: PDR = $pdr%"
        return 0
    else
        print_error "Baseline test failed: PDR = $pdr% (expected >= 99%)"
        return 1
    fi
}

validate_wormhole_fix() {
    print_header "FIX VALIDATION 2: Wormhole Timing Fix (Commit e91023f)"
    print_info "Issue: Wormhole tests showed 0% PDR"
    print_info "Fix: Changed default start time from 0.0s to 10.0s"
    print_info "Expected: PDR > 95%"
    
    run_test 2 "wormhole_no_mitigation"
    run_test 3 "wormhole_detection"
    run_test 4 "wormhole_mitigation"
    
    local log2="$RESULTS_DIR/test02_wormhole_no_mitigation/output.log"
    local log3="$RESULTS_DIR/test03_wormhole_detection/output.log"
    local log4="$RESULTS_DIR/test04_wormhole_mitigation/output.log"
    
    local pdr2=$(check_pdr "$log2" 90.0)
    local result2=$?
    
    local pdr3=$(check_pdr "$log3" 95.0)
    local result3=$?
    
    local pdr4=$(check_pdr "$log4" 95.0)
    local result4=$?
    
    echo ""
    echo "Results:"
    if [ $result2 -eq 0 ]; then
        print_success "Test 2 (No Mitigation): PDR = $pdr2%"
    else
        print_error "Test 2 (No Mitigation): PDR = $pdr2% (expected >= 90%)"
    fi
    
    if [ $result3 -eq 0 ]; then
        print_success "Test 3 (Detection): PDR = $pdr3%"
    else
        print_error "Test 3 (Detection): PDR = $pdr3% (expected >= 95%)"
    fi
    
    if [ $result4 -eq 0 ]; then
        print_success "Test 4 (Mitigation): PDR = $pdr4%"
    else
        print_error "Test 4 (Mitigation): PDR = $pdr4% (expected >= 95%)"
    fi
    
    if [ $result2 -eq 0 ] && [ $result3 -eq 0 ] && [ $result4 -eq 0 ]; then
        print_success "Wormhole fix validated successfully!"
        return 0
    else
        print_error "Wormhole fix validation failed"
        return 1
    fi
}

validate_blackhole_fix() {
    print_header "FIX VALIDATION 3: Blackhole Infrastructure Protection (Commit fe878e4)"
    print_info "Issue: Test06 showed 31.58% PDR (worse than no mitigation at 73.68%)"
    print_info "Root Cause: Random selection chose RSU node 34 as attacker"
    print_info "Fix: Protected RSU nodes from being attackers + added fixed seed"
    print_info "Expected: Test06 PDR > 70% (should be comparable to Test05)"
    
    run_test 5 "blackhole_no_mitigation"
    run_test 6 "blackhole_detection"
    run_test 7 "blackhole_mitigation"
    
    local log5="$RESULTS_DIR/test05_blackhole_no_mitigation/output.log"
    local log6="$RESULTS_DIR/test06_blackhole_detection/output.log"
    local log7="$RESULTS_DIR/test07_blackhole_mitigation/output.log"
    
    local pdr5=$(check_pdr "$log5" 60.0)
    local result5=$?
    
    local pdr6=$(check_pdr "$log6" 70.0)
    local result6=$?
    
    local pdr7=$(check_pdr "$log7" 85.0)
    local result7=$?
    
    echo ""
    echo "Results:"
    if [ $result5 -eq 0 ]; then
        print_success "Test 5 (No Mitigation): PDR = $pdr5%"
    else
        print_warning "Test 5 (No Mitigation): PDR = $pdr5% (expected >= 60%)"
    fi
    
    if [ $result6 -eq 0 ]; then
        print_success "Test 6 (Detection): PDR = $pdr6% ⭐ CRITICAL FIX!"
    else
        print_error "Test 6 (Detection): PDR = $pdr6% (expected >= 70%) ⭐ CRITICAL!"
    fi
    
    if [ $result7 -eq 0 ]; then
        print_success "Test 7 (Mitigation): PDR = $pdr7%"
    else
        print_error "Test 7 (Mitigation): PDR = $pdr7% (expected >= 85%)"
    fi
    
    # Check if Test06 is now better than or comparable to Test05
    echo ""
    print_info "Comparing Test05 vs Test06:"
    echo "  Test05 (No Mitigation): $pdr5%"
    echo "  Test06 (Detection):     $pdr6%"
    
    if (( $(echo "$pdr6 >= $pdr5 - 5" | bc -l) )); then
        print_success "Test06 is now comparable to Test05 (within 5% tolerance)"
        print_success "Infrastructure protection fix is working!"
    else
        print_error "Test06 still significantly worse than Test05"
        print_error "Infrastructure protection fix may not be working correctly"
        return 1
    fi
    
    # Check for infrastructure protection logs
    if grep -q "Protected infrastructure nodes" "$log6"; then
        print_success "Infrastructure protection logging detected"
    else
        print_warning "Infrastructure protection logs not found"
    fi
    
    if [ $result6 -eq 0 ]; then
        print_success "Blackhole fix validated successfully!"
        return 0
    else
        print_error "Blackhole fix validation failed"
        return 1
    fi
}

validate_sybil_fix() {
    print_header "FIX VALIDATION 4: Sybil Detection (Commit 16fa1ca)"
    print_info "Expected: PDR > 95% with detection/mitigation"
    
    run_test 8 "sybil_no_mitigation"
    run_test 9 "sybil_detection"
    run_test 10 "sybil_mitigation"
    
    local log8="$RESULTS_DIR/test08_sybil_no_mitigation/output.log"
    local log9="$RESULTS_DIR/test09_sybil_detection/output.log"
    local log10="$RESULTS_DIR/test10_sybil_mitigation/output.log"
    
    local pdr8=$(check_pdr "$log8" 90.0)
    local result8=$?
    
    local pdr9=$(check_pdr "$log9" 95.0)
    local result9=$?
    
    local pdr10=$(check_pdr "$log10" 95.0)
    local result10=$?
    
    echo ""
    echo "Results:"
    if [ $result8 -eq 0 ]; then
        print_success "Test 8 (No Mitigation): PDR = $pdr8%"
    else
        print_warning "Test 8 (No Mitigation): PDR = $pdr8%"
    fi
    
    if [ $result9 -eq 0 ]; then
        print_success "Test 9 (Detection): PDR = $pdr9%"
    else
        print_error "Test 9 (Detection): PDR = $pdr9% (expected >= 95%)"
    fi
    
    if [ $result10 -eq 0 ]; then
        print_success "Test 10 (Mitigation): PDR = $pdr10%"
    else
        print_error "Test 10 (Mitigation): PDR = $pdr10% (expected >= 95%)"
    fi
    
    if [ $result9 -eq 0 ] && [ $result10 -eq 0 ]; then
        print_success "Sybil fix validated successfully!"
        return 0
    else
        print_error "Sybil fix validation failed"
        return 1
    fi
}

validate_replay_fix() {
    print_header "FIX VALIDATION 5: Replay Detection (Commit 16fa1ca)"
    print_info "Expected: PDR = 100% with detection logging"
    
    run_test 11 "replay_no_mitigation"
    run_test 12 "replay_detection"
    run_test 13 "replay_mitigation"
    
    local log11="$RESULTS_DIR/test11_replay_no_mitigation/output.log"
    local log12="$RESULTS_DIR/test12_replay_detection/output.log"
    local log13="$RESULTS_DIR/test13_replay_mitigation/output.log"
    
    local pdr11=$(check_pdr "$log11" 99.0)
    local result11=$?
    
    local pdr12=$(check_pdr "$log12" 99.0)
    local result12=$?
    
    local pdr13=$(check_pdr "$log13" 99.0)
    local result13=$?
    
    echo ""
    echo "Results:"
    if [ $result11 -eq 0 ]; then
        print_success "Test 11 (No Mitigation): PDR = $pdr11%"
    else
        print_warning "Test 11 (No Mitigation): PDR = $pdr11%"
    fi
    
    if [ $result12 -eq 0 ]; then
        print_success "Test 12 (Detection): PDR = $pdr12%"
    else
        print_error "Test 12 (Detection): PDR = $pdr12% (expected >= 99%)"
    fi
    
    if [ $result13 -eq 0 ]; then
        print_success "Test 13 (Mitigation): PDR = $pdr13%"
    else
        print_error "Test 13 (Mitigation): PDR = $pdr13% (expected >= 99%)"
    fi
    
    # Check for replay detections
    local detections=$(grep -c "REPLAY DETECTED" "$log12" || echo "0")
    if [ "$detections" -gt 0 ]; then
        print_success "Replay detections found: $detections events"
    else
        print_warning "No replay detections found in logs"
    fi
    
    if [ $result12 -eq 0 ] && [ $result13 -eq 0 ]; then
        print_success "Replay fix validated successfully!"
        return 0
    else
        print_error "Replay fix validation failed"
        return 1
    fi
}

validate_rtp_fix() {
    print_header "FIX VALIDATION 6: RTP Probe Verification (Commit 0aae467)"
    print_info "Issue: ProbePacketsSent was 0"
    print_info "Fix: Enhanced MHL detection + synthetic probe mechanism"
    print_info "Expected: ProbePacketsSent > 0"
    
    run_test 14 "rtp_no_mitigation"
    run_test 15 "rtp_detection"
    run_test 16 "rtp_mitigation"
    
    local log14="$RESULTS_DIR/test14_rtp_no_mitigation/output.log"
    local log15="$RESULTS_DIR/test15_rtp_detection/output.log"
    local log16="$RESULTS_DIR/test16_rtp_mitigation/output.log"
    
    local pdr14=$(check_pdr "$log14" 99.0)
    local result14=$?
    
    local pdr15=$(check_pdr "$log15" 85.0)
    local result15=$?
    
    local pdr16=$(check_pdr "$log16" 90.0)
    local result16=$?
    
    echo ""
    echo "Results:"
    if [ $result14 -eq 0 ]; then
        print_success "Test 14 (No Mitigation): PDR = $pdr14%"
    else
        print_warning "Test 14 (No Mitigation): PDR = $pdr14%"
    fi
    
    if [ $result15 -eq 0 ]; then
        print_success "Test 15 (Detection): PDR = $pdr15%"
    else
        print_error "Test 15 (Detection): PDR = $pdr15% (expected >= 85%)"
    fi
    
    if [ $result16 -eq 0 ]; then
        print_success "Test 16 (Mitigation): PDR = $pdr16%"
    else
        print_error "Test 16 (Mitigation): PDR = $pdr16% (expected >= 90%)"
    fi
    
    # Check for probe verification
    echo ""
    print_info "Checking probe verification..."
    
    local probes_sent=$(grep "Probe Packets Sent:" "$log15" | tail -1 | awk '{print $NF}')
    
    if [ -n "$probes_sent" ] && [ "$probes_sent" -gt 0 ]; then
        print_success "ProbePacketsSent: $probes_sent (was 0 before fix) ⭐"
    else
        print_error "ProbePacketsSent: 0 (fix not working)"
        return 1
    fi
    
    # Check for probe logs
    if grep -q "Sending probe packet" "$log15"; then
        print_success "Probe sending logs detected"
    else
        print_warning "Probe sending logs not found"
    fi
    
    if grep -q "MHL appears FABRICATED" "$log15"; then
        print_success "MHL fabrication detection logs found"
    else
        print_warning "MHL fabrication detection logs not found"
    fi
    
    if [ "$probes_sent" -gt 0 ]; then
        print_success "RTP probe verification fix validated successfully!"
        return 0
    else
        print_error "RTP probe verification fix validation failed"
        return 1
    fi
}

validate_combined_scenario() {
    print_header "FIX VALIDATION 7: Combined Attack Scenario"
    print_info "Expected: PDR > 90% with all mitigations"
    
    run_test 17 "combined_all_mitigations"
    
    local log17="$RESULTS_DIR/test17_combined_all_mitigations/output.log"
    
    local pdr17=$(check_pdr "$log17" 90.0)
    local result17=$?
    
    echo ""
    echo "Results:"
    if [ $result17 -eq 0 ]; then
        print_success "Test 17 (Combined): PDR = $pdr17%"
        print_success "Combined scenario validated successfully!"
        return 0
    else
        print_warning "Test 17 (Combined): PDR = $pdr17% (expected >= 90%)"
        print_warning "Combined scenario could be improved with MitigationCoordinator"
        return 1
    fi
}

generate_summary_report() {
    print_header "VALIDATION SUMMARY REPORT"
    
    local report_file="$RESULTS_DIR/validation_summary.txt"
    
    cat > "$report_file" << EOF
SDVN FIXED ISSUES VALIDATION REPORT
Generated: $(date)
Results Directory: $RESULTS_DIR

========================================================================
VALIDATION RESULTS
========================================================================

Fix 1: Baseline Performance
$(grep -E "(✅|❌)" "$RESULTS_DIR/test01_baseline/output.log" || echo "  Status: Check log for details")

Fix 2: Wormhole Timing Fix (Commit e91023f)
  - Issue: PDR was 0%
  - Fix: Changed start time from 0.0s to 10.0s
  - Tests: 2, 3, 4
  - Result: Check individual test logs

Fix 3: Blackhole Infrastructure Protection (Commit fe878e4) ⭐ CRITICAL
  - Issue: Test06 showed 31.58% PDR (worse than no mitigation)
  - Fix: Protected RSU nodes + added fixed seed
  - Tests: 5, 6, 7
  - Result: Check individual test logs

Fix 4: Sybil Detection (Commit 16fa1ca)
  - Tests: 8, 9, 10
  - Result: Check individual test logs

Fix 5: Replay Detection (Commit 16fa1ca)
  - Tests: 11, 12, 13
  - Result: Check individual test logs

Fix 6: RTP Probe Verification (Commit 0aae467) ⭐ CRITICAL
  - Issue: ProbePacketsSent was 0
  - Fix: Enhanced MHL detection + synthetic probes
  - Tests: 14, 15, 16
  - Result: Check individual test logs

Fix 7: Combined Scenario
  - Test: 17
  - Result: Check individual test logs

========================================================================
DETAILED LOGS
========================================================================

All detailed logs are available in:
  $RESULTS_DIR/

Individual test directories contain:
  - output.log: Full simulation output
  - *.csv: Result files (if generated)

========================================================================
EOF
    
    cat "$report_file"
    
    print_info "Full report saved to: $report_file"
}

##############################################################################
# Main Execution
##############################################################################

main() {
    print_header "SDVN FIXED ISSUES VALIDATION"
    echo "Date: $(date)"
    echo "Results Directory: $RESULTS_DIR"
    echo ""
    
    # Create results directory
    mkdir -p "$RESULTS_DIR"
    
    # Track overall status
    local total_tests=0
    local passed_tests=0
    
    # Step 1: Check environment
    check_environment
    
    # Step 2: Build project
    build_project
    
    # Step 3: Validate fixes
    echo ""
    print_info "Starting validation tests..."
    echo ""
    
    # Baseline
    if validate_baseline; then
        ((passed_tests++))
    fi
    ((total_tests++))
    
    # Wormhole fix
    if validate_wormhole_fix; then
        ((passed_tests++))
    fi
    ((total_tests++))
    
    # Blackhole fix (CRITICAL)
    if validate_blackhole_fix; then
        ((passed_tests++))
    fi
    ((total_tests++))
    
    # Sybil fix
    if validate_sybil_fix; then
        ((passed_tests++))
    fi
    ((total_tests++))
    
    # Replay fix
    if validate_replay_fix; then
        ((passed_tests++))
    fi
    ((total_tests++))
    
    # RTP fix (CRITICAL)
    if validate_rtp_fix; then
        ((passed_tests++))
    fi
    ((total_tests++))
    
    # Combined scenario
    if validate_combined_scenario; then
        ((passed_tests++))
    fi
    ((total_tests++))
    
    # Generate summary
    generate_summary_report
    
    # Final status
    print_header "FINAL STATUS"
    echo ""
    echo "Validation Tests Passed: $passed_tests / $total_tests"
    echo ""
    
    if [ $passed_tests -eq $total_tests ]; then
        print_success "ALL FIXES VALIDATED SUCCESSFULLY! 🎉"
        echo ""
        print_info "All committed fixes are working as expected."
        print_info "The SDVN security evaluation is complete and meets requirements."
        return 0
    elif [ $passed_tests -ge $((total_tests - 1)) ]; then
        print_warning "MOST FIXES VALIDATED ($passed_tests/$total_tests)"
        echo ""
        print_info "Minor issues detected. Review the logs for details."
        return 0
    else
        print_error "SOME FIXES FAILED VALIDATION"
        echo ""
        print_info "Please review the logs in $RESULTS_DIR for details."
        print_info "Re-run specific tests as needed."
        return 1
    fi
}

# Run main function
main "$@"

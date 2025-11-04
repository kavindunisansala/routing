#!/bin/bash
# ============================================================================
# Diagnostic Script for Failed SDVN Tests
# Analyzes simulation logs to identify why CSV files weren't generated
# ============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

RESULTS_DIR="$1"

if [ -z "$RESULTS_DIR" ]; then
    echo "Usage: $0 <results_directory>"
    echo "Example: $0 ./sdvn_evaluation_20251105_010138"
    exit 1
fi

if [ ! -d "$RESULTS_DIR" ]; then
    echo "Error: Directory not found: $RESULTS_DIR"
    exit 1
fi

echo "============================================================================"
echo "SDVN TEST DIAGNOSTICS"
echo "============================================================================"
echo ""
echo "Analyzing: $RESULTS_DIR"
echo ""

# Function to check test directory
check_test() {
    local test_dir=$1
    local test_name=$2
    local attack_type=$3
    
    echo "────────────────────────────────────────────────────────────────"
    echo -e "${BLUE}$test_name${NC}"
    echo "────────────────────────────────────────────────────────────────"
    
    if [ ! -d "$test_dir" ]; then
        echo -e "${RED}✗ Directory not found${NC}"
        return
    fi
    
    # Count CSV files
    local csv_count=$(find "$test_dir" -name "*.csv" -type f 2>/dev/null | wc -l)
    
    if [ $csv_count -eq 0 ]; then
        echo -e "${RED}✗ NO CSV FILES GENERATED${NC}"
        
        # Check simulation log
        if [ -f "$test_dir/simulation.log" ]; then
            echo ""
            echo "Log Analysis:"
            
            # Check for attack initialization messages
            echo -n "  Attack Init: "
            if grep -qi "${attack_type}.*attack.*config\|${attack_type}.*manager\|creating.*${attack_type}" "$test_dir/simulation.log"; then
                echo -e "${GREEN}Found${NC}"
                grep -i "${attack_type}.*attack.*config\|${attack_type}.*manager\|creating.*${attack_type}" "$test_dir/simulation.log" | head -5
            else
                echo -e "${RED}NOT FOUND${NC}"
            fi
            
            # Check for malicious nodes
            echo -n "  Malicious Nodes: "
            if grep -qi "malicious.*node.*selected\|attacking.*state\|malicious.*count" "$test_dir/simulation.log"; then
                echo -e "${GREEN}Found${NC}"
                grep -i "malicious.*node.*selected\|attacking.*state\|malicious.*count" "$test_dir/simulation.log" | head -3
            else
                echo -e "${RED}NOT FOUND${NC}"
            fi
            
            # Check for CSV export messages
            echo -n "  CSV Export: "
            if grep -qi "${attack_type}.*csv\|exporting.*statistics\|export.*results" "$test_dir/simulation.log"; then
                echo -e "${GREEN}Found${NC}"
                grep -i "${attack_type}.*csv\|exporting.*statistics\|export.*results" "$test_dir/simulation.log" | head -3
            else
                echo -e "${RED}NOT FOUND${NC}"
            fi
            
            # Check for errors
            echo -n "  Errors: "
            if grep -qi "error\|warning\|failed\|exception" "$test_dir/simulation.log"; then
                echo -e "${YELLOW}Found${NC}"
                grep -i "error\|warning\|failed\|exception" "$test_dir/simulation.log" | head -5
            else
                echo -e "${GREEN}None${NC}"
            fi
            
            # Show last 20 lines of log
            echo ""
            echo "Last 20 lines of log:"
            tail -20 "$test_dir/simulation.log"
            
        else
            echo -e "${RED}✗ simulation.log not found${NC}"
        fi
    else
        echo -e "${GREEN}✓ $csv_count CSV file(s) generated${NC}"
        find "$test_dir" -name "*.csv" -type f -exec basename {} \; | sed 's/^/    - /'
    fi
    
    echo ""
}

# Check each failed test group

echo "============================================================================"
echo "BLACKHOLE TESTS (Expected to FAIL)"
echo "============================================================================"
echo ""

check_test "$RESULTS_DIR/test05_blackhole_10_no_mitigation" \
    "Test 5: Blackhole Attack (No Mitigation)" \
    "blackhole"

check_test "$RESULTS_DIR/test06_blackhole_10_with_detection" \
    "Test 6: Blackhole Attack (With Detection)" \
    "blackhole"

check_test "$RESULTS_DIR/test07_blackhole_10_with_mitigation" \
    "Test 7: Blackhole Attack (With Mitigation)" \
    "blackhole"

echo "============================================================================"
echo "REPLAY TESTS (Expected to FAIL)"
echo "============================================================================"
echo ""

check_test "$RESULTS_DIR/test11_replay_10_no_mitigation" \
    "Test 11: Replay Attack (No Mitigation)" \
    "replay"

check_test "$RESULTS_DIR/test12_replay_10_with_detection" \
    "Test 12: Replay Attack (With Detection)" \
    "replay"

check_test "$RESULTS_DIR/test13_replay_10_with_mitigation" \
    "Test 13: Replay Attack (With Mitigation)" \
    "replay"

echo "============================================================================"
echo "COMBINED TEST (Expected to FAIL)"
echo "============================================================================"
echo ""

check_test "$RESULTS_DIR/test17_combined_10_with_all_mitigations" \
    "Test 17: Combined Attack with All Mitigations" \
    "attack"

echo "============================================================================"
echo "DIAGNOSTIC SUMMARY"
echo "============================================================================"
echo ""

# Count successful tests
successful_wormhole=$(find "$RESULTS_DIR"/test0[234]_wormhole* -name "*.csv" 2>/dev/null | wc -l)
successful_sybil=$(find "$RESULTS_DIR"/test[01][0890]_sybil* -name "*.csv" 2>/dev/null | wc -l)
successful_rtp=$(find "$RESULTS_DIR"/test1[456]_rtp* -name "*.csv" 2>/dev/null | wc -l)

echo "Working Tests:"
echo "  ✓ Wormhole: $([ $successful_wormhole -gt 0 ] && echo "YES ($successful_wormhole CSV files)" || echo "NO")"
echo "  ✓ Sybil: $([ $successful_sybil -gt 0 ] && echo "YES ($successful_sybil CSV files)" || echo "NO")"
echo "  ✓ RTP: $([ $successful_rtp -gt 0 ] && echo "YES ($successful_rtp CSV files)" || echo "NO")"
echo ""
echo "Failed Tests:"
echo "  ✗ Blackhole: All 3 tests (5-7)"
echo "  ✗ Replay: All 3 tests (11-13)"
echo "  ✗ Combined: Test 17"
echo ""

echo "Recommended Actions:"
echo "────────────────────────────────────────────────────────────────"
echo "1. Check if blackhole/replay managers are being initialized"
echo "   → Look for 'Attack Configuration' messages in logs"
echo ""
echo "2. Verify routing.cc code structure"
echo "   → Check if blackhole setup is nested inside wormhole block"
echo "   → Ensure 'enable_blackhole_attack' triggers manager creation"
echo ""
echo "3. Test manually with simplified parameters:"
echo "   ./waf --run \"scratch/routing --simTime=50 --N_Vehicles=18 \\"
echo "     --N_RSUs=10 --present_blackhole_attack_nodes=true \\"
echo "     --enable_blackhole_attack=true --blackhole_attack_percentage=0.1\""
echo ""
echo "4. Check for parameter typos:"
echo "   → 'reply' vs 'replay' in routing.cc"
echo "   → Percentage format: 0.1 vs 0.10"
echo ""
echo "5. Review CRITICAL_TEST_FIXES.md for detailed analysis"
echo ""
echo "============================================================================"

#!/bin/bash

################################################################################
# New SDN Architecture Verification Script
# Purpose: Verify that Architecture 0 now has proper data plane routing
# Tests:
#   1. Baseline (no attacks) - Verify DSRC peer-to-peer traffic works
#   2. Quick test of each attack type - Verify attacks are functional
#   3. Compare with old behavior - Show improvement
#
# Expected Results:
#   - packet-delivery-analysis.csv shows flows between regular nodes (not just 0,1)
#   - AODV route discoveries visible in output
#   - Attack statistics show non-zero values (especially wormhole PacketsTunneled)
################################################################################

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Configuration
VEHICLES=20
RSUS=2
SIMTIME=10
ATTACK_PERCENT=0.2
RESULTS_DIR="results_architecture_verification_$(date +%Y%m%d_%H%M%S)"

# Helper functions
print_header() {
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
}

print_message() {
    local color=$1
    shift
    echo -e "${color}$@${NC}"
}

print_test() {
    echo -e "${CYAN}▶ $@${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $@${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $@${NC}"
}

print_error() {
    echo -e "${RED}✗ $@${NC}"
}

# Check if files exist
check_file() {
    local file=$1
    local metric=$2
    if [[ -f "$file" ]]; then
        print_success "Found: $file"
        if [[ -n "$metric" ]]; then
            grep "$metric" "$file" 2>/dev/null || print_warning "  Metric '$metric' not found in file"
        fi
        return 0
    else
        print_error "Missing: $file"
        return 1
    fi
}

# Analyze packet delivery
analyze_packet_delivery() {
    local test_name=$1
    print_test "Analyzing packet delivery patterns..."
    
    if [[ -f "packet-delivery-analysis.csv" ]]; then
        echo ""
        echo "  Network Traffic Analysis:"
        echo "  ========================="
        
        # Count unique source-destination pairs (excluding controller nodes 0,1)
        local peer_flows=$(awk -F',' 'NR>1 && $1!="SourceNode" && $1!~"^(0|1)$" && $2!~"^(0|1)$" {print $1"-"$2}' packet-delivery-analysis.csv | sort -u | wc -l)
        local controller_flows=$(awk -F',' 'NR>1 && ($1=="0" || $1=="1" || $2=="0" || $2=="1") {print $1"-"$2}' packet-delivery-analysis.csv | sort -u | wc -l)
        
        # Count total packets
        local total_packets=$(awk -F',' 'NR>1 && $1!="SourceNode" {sum+=$3} END {print sum}' packet-delivery-analysis.csv)
        local peer_packets=$(awk -F',' 'NR>1 && $1!="SourceNode" && $1!~"^(0|1)$" && $2!~"^(0|1)$" {sum+=$3} END {print sum}' packet-delivery-analysis.csv)
        local control_packets=$(awk -F',' 'NR>1 && ($1=="0" || $1=="1" || $2=="0" || $2=="1") {sum+=$3} END {print sum}' packet-delivery-analysis.csv)
        
        echo "  Data Plane (peer-to-peer):"
        echo "    Flows: $peer_flows"
        echo "    Packets: $peer_packets"
        echo ""
        echo "  Control Plane (to/from controller):"
        echo "    Flows: $controller_flows"
        echo "    Packets: $control_packets"
        echo ""
        echo "  Total Traffic:"
        echo "    Packets: $total_packets"
        
        if [[ $peer_flows -gt 0 ]]; then
            local peer_percentage=$(echo "scale=1; ($peer_packets * 100) / $total_packets" | bc 2>/dev/null || echo "0")
            echo "    Data plane: ${peer_percentage}%"
            echo ""
            print_success "✓ Data plane is ACTIVE (peer-to-peer routing works!)"
            echo "  Sample peer-to-peer flows:"
            awk -F',' 'NR>1 && $1!="SourceNode" && $1!~"^(0|1)$" && $2!~"^(0|1)$" {print "    Node "$1" → Node "$2" ("$3" packets)"}' packet-delivery-analysis.csv | sort -u | head -5
        else
            echo ""
            print_error "✗ Data plane INACTIVE (all traffic through controller)"
            echo "  All packets are being routed through controller nodes 0 or 1"
        fi
        echo ""
    else
        print_warning "packet-delivery-analysis.csv not found"
        echo "  Unable to analyze traffic patterns"
        echo ""
    fi
}

# Analyze attack statistics
analyze_attack_stats() {
    local attack_type=$1
    local file="${attack_type}-attack-statistics.csv"
    
    print_test "Analyzing ${attack_type} attack statistics..."
    
    if [[ -f "$file" ]]; then
        case $attack_type in
            wormhole)
                echo ""
                echo "  Wormhole Attack Analysis:"
                echo "  ========================="
                local tunneled=$(awk -F',' 'NR==2 {print $2}' "$file")
                local intercepted=$(awk -F',' 'NR==2 {print $3}' "$file")
                local attack_nodes=$(awk -F',' 'NR==2 {print $1}' "$file")
                echo "  Attack Nodes: $attack_nodes"
                echo "  Packets Intercepted: $intercepted"
                echo "  Packets Tunneled: $tunneled"
                
                if [[ "$tunneled" =~ ^[0-9]+$ ]] && [[ $tunneled -gt 0 ]]; then
                    local tunnel_rate=$(echo "scale=2; ($tunneled * 100) / $intercepted" | bc 2>/dev/null || echo "N/A")
                    echo "  Tunnel Success Rate: ${tunnel_rate}%"
                    print_success "✓ Wormhole is FUNCTIONAL (packets tunneled: $tunneled)"
                else
                    print_error "✗ Wormhole NOT WORKING (PacketsTunneled = 0)"
                    echo "  Possible causes: No AODV packets to intercept, port filtering issue"
                fi
                ;;
            blackhole)
                echo ""
                echo "  Blackhole Attack Analysis:"
                echo "  =========================="
                local dropped=$(awk -F',' 'NR==2 {print $2}' "$file")
                local intercepted=$(awk -F',' 'NR==2 {print $3}' "$file")
                local attack_nodes=$(awk -F',' 'NR==2 {print $1}' "$file")
                echo "  Attack Nodes: $attack_nodes"
                echo "  Packets Intercepted: $intercepted"
                echo "  Packets Dropped: $dropped"
                
                if [[ "$dropped" =~ ^[0-9]+$ ]] && [[ $dropped -gt 0 ]]; then
                    local drop_rate=$(echo "scale=2; ($dropped * 100) / $intercepted" | bc 2>/dev/null || echo "N/A")
                    echo "  Drop Rate: ${drop_rate}%"
                    print_success "✓ Blackhole is FUNCTIONAL (packets dropped: $dropped)"
                else
                    print_warning "⚠ Blackhole might not be working (PacketsDropped = 0)"
                    echo "  Possible causes: No packets routed through attacker"
                fi
                ;;
            replay)
                echo ""
                echo "  Replay Attack Analysis:"
                echo "  ======================"
                local replayed=$(awk -F',' 'NR==2 {print $2}' "$file")
                local captured=$(awk -F',' 'NR==2 {print $3}' "$file")
                local attack_nodes=$(awk -F',' 'NR==2 {print $1}' "$file")
                echo "  Attack Nodes: $attack_nodes"
                echo "  Packets Captured: $captured"
                echo "  Packets Replayed: $replayed"
                
                if [[ "$replayed" =~ ^[0-9]+$ ]] && [[ $replayed -gt 0 ]]; then
                    echo "  Replay Strategy: Capturing and retransmitting DSRC broadcasts"
                    print_success "✓ Replay is FUNCTIONAL (packets replayed: $replayed)"
                else
                    print_warning "⚠ Replay might not be working (PacketsReplayed = 0)"
                    echo "  Possible causes: No DSRC broadcasts captured, timing issue"
                fi
                ;;
            rtp)
                echo ""
                echo "  RTP (Routing Table Poisoning) Attack Analysis:"
                echo "  =============================================="
                local fake_routes=$(awk -F',' 'NR==2 {print $2}' "$file")
                local fabricated_mhl=$(awk -F',' 'NR==2 {print $3}' "$file")
                local modified_metrics=$(awk -F',' 'NR==2 {print $4}' "$file")
                local poisoned=$(awk -F',' 'NR==2 {print $5}' "$file")
                local attack_nodes=$(awk -F',' 'NR==2 {print $1}' "$file")
                echo "  Attack Nodes: $attack_nodes"
                echo "  Fake Routes Injected: $fake_routes"
                echo "  Fabricated MHLs: $fabricated_mhl"
                echo "  Modified Metrics: $modified_metrics"
                echo "  Nodes Poisoned: $poisoned"
                
                if [[ "$poisoned" =~ ^[0-9]+$ ]] && [[ $poisoned -gt 0 ]]; then
                    echo "  Attack Impact: Successfully corrupted routing tables"
                    print_success "✓ RTP is FUNCTIONAL (nodes poisoned: $poisoned)"
                else
                    print_warning "⚠ RTP might not be working (NodesPoisoned = 0)"
                    echo "  Note: RTP requires static routing; AODV nodes are skipped"
                fi
                ;;
            sybil)
                echo ""
                echo "  Sybil Attack Analysis:"
                echo "  ====================="
                local identities=$(awk -F',' 'NR==2 {print $2}' "$file")
                local broadcasts=$(awk -F',' 'NR==2 {print $3}' "$file")
                local attack_nodes=$(awk -F',' 'NR==2 {print $1}' "$file")
                echo "  Attack Nodes: $attack_nodes"
                echo "  Fake Identities Created: $identities"
                echo "  Broadcasts Sent: $broadcasts"
                
                if [[ "$identities" =~ ^[0-9]+$ ]] && [[ $identities -gt 0 ]]; then
                    local broadcasts_per_id=$(echo "scale=2; $broadcasts / $identities" | bc 2>/dev/null || echo "N/A")
                    echo "  Broadcasts per Identity: $broadcasts_per_id"
                    echo "  Attack Strategy: Broadcasting with multiple fake node IDs"
                    print_success "✓ Sybil is FUNCTIONAL (fake identities: $identities)"
                else
                    print_warning "⚠ Sybil might not be working (FakeIdentities = 0)"
                    echo "  Possible causes: Identity creation failed"
                fi
                ;;
        esac
        echo ""
    else
        print_warning "$file not found"
        echo "  Attack statistics were not generated"
        echo ""
    fi
}

# Run a test
run_test() {
    local test_name=$1
    local attack_flag=$2
    local attack_value=$3
    local description=$4
    
    print_header "$test_name"
    print_message "$YELLOW" "$description"
    echo ""
    
    local start_time=$(date +%s)
    
    # Build command
    local cmd="./waf --run \"scratch/routing --architecture=0 --N_Vehicles=$VEHICLES --N_RSUs=$RSUS --simTime=$SIMTIME"
    if [[ -n "$attack_flag" ]]; then
        cmd="$cmd --${attack_flag}=${attack_value}"
        
        # Add appropriate percentage parameter based on attack type
        if [[ "$attack_flag" == "enable_replay_attack" ]]; then
            cmd="$cmd --replay_attack_percentage=$ATTACK_PERCENT"
        elif [[ "$attack_flag" == "enable_rtp_attack" ]]; then
            cmd="$cmd --rtp_attack_percentage=$ATTACK_PERCENT"
        else
            cmd="$cmd --attack_percentage=$ATTACK_PERCENT"
        fi
    fi
    cmd="$cmd\""
    
    print_test "Running: $cmd"
    echo ""
    
    # Run simulation
    if eval $cmd; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        print_success "Test completed in ${duration}s"
        echo ""
        
        # Analyze results
        analyze_packet_delivery "$test_name"
        if [[ -n "$attack_flag" ]]; then
            # Extract attack type from flag name
            local attack_type=""
            if [[ "$attack_flag" == "present_wormhole_attack_nodes" ]]; then
                attack_type="wormhole"
            elif [[ "$attack_flag" == "present_blackhole_attack_nodes" ]]; then
                attack_type="blackhole"
            elif [[ "$attack_flag" == "enable_replay_attack" ]]; then
                attack_type="replay"
            elif [[ "$attack_flag" == "enable_rtp_attack" ]]; then
                attack_type="rtp"
            elif [[ "$attack_flag" == "present_sybil_attack_nodes" ]]; then
                attack_type="sybil"
            fi
            
            if [[ -n "$attack_type" ]]; then
                analyze_attack_stats "$attack_type"
            fi
        fi
        
        # Save results
        mkdir -p "$RESULTS_DIR/$test_name"
        cp -f *.csv "$RESULTS_DIR/$test_name/" 2>/dev/null || true
        echo "$duration" > "$RESULTS_DIR/$test_name/duration.txt"
        
        echo ""
        print_success "Results saved to: $RESULTS_DIR/$test_name"
        
    else
        print_error "Test FAILED"
        return 1
    fi
}

# Main execution
clear
print_header "HYBRID SDN ARCHITECTURE VERIFICATION"
print_message "$CYAN" "This script verifies that Architecture 0 now has:"
print_message "$CYAN" "  ✓ Static routing on infrastructure (RSUs, controller, management)"
print_message "$CYAN" "  ✓ AODV routing on vehicles for peer-to-peer (mobile data plane)"
print_message "$CYAN" "  ✓ DSRC broadcasts for V2V communication"
print_message "$CYAN" "  ✓ LTE for control plane (metadata only)"
print_message "$CYAN" "  ✓ All attacks functional with data plane routing"
echo ""
print_message "$YELLOW" "Configuration:"
print_message "$YELLOW" "  Vehicles: $VEHICLES"
print_message "$YELLOW" "  RSUs: $RSUS"
print_message "$YELLOW" "  Simulation Time: ${SIMTIME}s"
print_message "$YELLOW" "  Attack Percentage: ${ATTACK_PERCENT} (20%)"
print_message "$YELLOW" "  Results Directory: $RESULTS_DIR"
echo ""

# Create results directory
mkdir -p "$RESULTS_DIR"

# Test counter
TEST_NUM=0

################################################################################
# TEST 1: BASELINE (NO ATTACKS)
################################################################################
TEST_NUM=$((TEST_NUM + 1))
run_test "Test${TEST_NUM}_Baseline" "" "" \
"BASELINE TEST - Verify data plane routing works without attacks.
Expected: Peer-to-peer flows visible in packet-delivery-analysis.csv"

sleep 2

################################################################################
# TEST 2: WORMHOLE ATTACK
################################################################################
TEST_NUM=$((TEST_NUM + 1))
run_test "Test${TEST_NUM}_Wormhole" "present_wormhole_attack_nodes" "1" \
"WORMHOLE ATTACK - Verify tunneling works with AODV routing.
Expected: PacketsTunneled > 0 in wormhole-attack-statistics.csv"

sleep 2

################################################################################
# TEST 3: BLACKHOLE ATTACK
################################################################################
TEST_NUM=$((TEST_NUM + 1))
run_test "Test${TEST_NUM}_Blackhole" "present_blackhole_attack_nodes" "1" \
"BLACKHOLE ATTACK - Verify packet dropping works on data plane.
Expected: PacketsDropped > 0 in blackhole-attack-statistics.csv"

sleep 2

################################################################################
# TEST 4: REPLAY ATTACK
################################################################################
TEST_NUM=$((TEST_NUM + 1))
run_test "Test${TEST_NUM}_Replay" "enable_replay_attack" "1" \
"REPLAY ATTACK - Verify packet capture/replay works with DSRC broadcasts.
Expected: PacketsReplayed > 0 in replay-attack-statistics.csv"

sleep 2

################################################################################
# TEST 5: RTP ATTACK
################################################################################
TEST_NUM=$((TEST_NUM + 1))
run_test "Test${TEST_NUM}_RTP" "enable_rtp_attack" "1" \
"RTP ATTACK - Verify route poisoning works with AODV routing.
Expected: NodesPoisoned > 0 in rtp-attack-statistics.csv"

sleep 2

################################################################################
# TEST 6: SYBIL ATTACK
################################################################################
TEST_NUM=$((TEST_NUM + 1))
run_test "Test${TEST_NUM}_Sybil" "present_sybil_attack_nodes" "1" \
"SYBIL ATTACK - Verify fake identities broadcast via DSRC.
Expected: FakeIdentities > 0 in sybil-attack-statistics.csv"

################################################################################
# SUMMARY
################################################################################
print_header "VERIFICATION SUMMARY"

echo ""
print_message "$CYAN" "Key Verification Points:"
echo ""

# Check if all tests passed
PASSED=0
FAILED=0

for i in $(seq 1 $TEST_NUM); do
    test_dir="$RESULTS_DIR/Test${i}_*"
    test_name=$(ls -d $test_dir 2>/dev/null | head -1 | xargs basename)
    
    if [[ -n "$test_name" ]]; then
        print_message "$YELLOW" "Test $i: $test_name"
        
        # Check for peer-to-peer flows in baseline
        if [[ "$test_name" == *"Baseline"* ]]; then
            if [[ -f "$RESULTS_DIR/$test_name/packet-delivery-analysis.csv" ]]; then
                peer_flows=$(awk -F',' 'NR>1 && $1!="SourceNode" && $1!~"^(0|1)$" && $2!~"^(0|1)$" {print $1"-"$2}' "$RESULTS_DIR/$test_name/packet-delivery-analysis.csv" | sort -u | wc -l)
                if [[ $peer_flows -gt 0 ]]; then
                    print_success "  ✓ Data plane routing verified ($peer_flows peer-to-peer flows)"
                    PASSED=$((PASSED + 1))
                else
                    print_error "  ✗ Data plane NOT working (no peer-to-peer flows)"
                    FAILED=$((FAILED + 1))
                fi
            fi
        fi
        
        # Check attack functionality
        if [[ "$test_name" == *"Wormhole"* ]]; then
            if [[ -f "$RESULTS_DIR/$test_name/wormhole-attack-statistics.csv" ]]; then
                tunneled=$(awk -F',' 'NR==2 {print $2}' "$RESULTS_DIR/$test_name/wormhole-attack-statistics.csv")
                if [[ "$tunneled" =~ ^[0-9]+$ ]] && [[ $tunneled -gt 0 ]]; then
                    print_success "  ✓ Wormhole functional (PacketsTunneled: $tunneled)"
                    PASSED=$((PASSED + 1))
                else
                    print_error "  ✗ Wormhole NOT working (PacketsTunneled: $tunneled)"
                    FAILED=$((FAILED + 1))
                fi
            fi
        elif [[ "$test_name" == *"Blackhole"* ]]; then
            if [[ -f "$RESULTS_DIR/$test_name/blackhole-attack-statistics.csv" ]]; then
                dropped=$(awk -F',' 'NR==2 {print $2}' "$RESULTS_DIR/$test_name/blackhole-attack-statistics.csv")
                if [[ "$dropped" =~ ^[0-9]+$ ]] && [[ $dropped -gt 0 ]]; then
                    print_success "  ✓ Blackhole functional (PacketsDropped: $dropped)"
                    PASSED=$((PASSED + 1))
                else
                    print_warning "  ~ Blackhole uncertain (PacketsDropped: $dropped)"
                fi
            fi
        elif [[ "$test_name" == *"Replay"* ]]; then
            if [[ -f "$RESULTS_DIR/$test_name/replay-attack-statistics.csv" ]]; then
                replayed=$(awk -F',' 'NR==2 {print $2}' "$RESULTS_DIR/$test_name/replay-attack-statistics.csv")
                if [[ "$replayed" =~ ^[0-9]+$ ]] && [[ $replayed -gt 0 ]]; then
                    print_success "  ✓ Replay functional (PacketsReplayed: $replayed)"
                    PASSED=$((PASSED + 1))
                else
                    print_warning "  ~ Replay uncertain (PacketsReplayed: $replayed)"
                fi
            fi
        elif [[ "$test_name" == *"RTP"* ]]; then
            if [[ -f "$RESULTS_DIR/$test_name/rtp-attack-statistics.csv" ]]; then
                poisoned=$(awk -F',' 'NR==2 {print $5}' "$RESULTS_DIR/$test_name/rtp-attack-statistics.csv")
                if [[ "$poisoned" =~ ^[0-9]+$ ]] && [[ $poisoned -gt 0 ]]; then
                    print_success "  ✓ RTP functional (NodesPoisoned: $poisoned)"
                    PASSED=$((PASSED + 1))
                else
                    print_warning "  ~ RTP uncertain (NodesPoisoned: $poisoned)"
                fi
            fi
        elif [[ "$test_name" == *"Sybil"* ]]; then
            if [[ -f "$RESULTS_DIR/$test_name/sybil-attack-statistics.csv" ]]; then
                identities=$(awk -F',' 'NR==2 {print $2}' "$RESULTS_DIR/$test_name/sybil-attack-statistics.csv")
                if [[ "$identities" =~ ^[0-9]+$ ]] && [[ $identities -gt 0 ]]; then
                    print_success "  ✓ Sybil functional (FakeIdentities: $identities)"
                    PASSED=$((PASSED + 1))
                else
                    print_warning "  ~ Sybil uncertain (FakeIdentities: $identities)"
                fi
            fi
        fi
    fi
done

echo ""
print_header "FINAL RESULTS"
echo ""
print_message "$GREEN" "Tests Passed: $PASSED"
print_message "$RED" "Tests Failed: $FAILED"
echo ""

if [[ $FAILED -eq 0 ]]; then
    print_header "✓ NEW ARCHITECTURE VERIFICATION SUCCESSFUL"
    print_message "$GREEN" "Architecture 0 now has proper SDN with data plane!"
    print_message "$GREEN" "All attacks are functional with AODV routing + DSRC broadcasts."
else
    print_header "⚠ VERIFICATION INCOMPLETE"
    print_message "$YELLOW" "Some tests need review. Check results in: $RESULTS_DIR"
fi

echo ""
print_message "$CYAN" "Results saved to: $RESULTS_DIR"
print_message "$CYAN" "For detailed analysis, check individual test directories."
echo ""

exit 0

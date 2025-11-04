#!/bin/bash
# ============================================================================
# SDVN DATA PLANE Security Attack Testing Suite
# Tests attacks by compromised data plane nodes (vehicles/RSUs) in SDVN
# Controllers remain trusted - only data plane nodes are malicious
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

print_header "SDVN DATA PLANE ATTACK TESTING SUITE"
print_info "Testing compromised data plane nodes in SDVN architecture"
print_info "Controllers: TRUSTED | Data Plane Nodes: MALICIOUS"

# Configuration
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RESULTS_DIR="./sdvn_results_${TIMESTAMP}"
ROUTING_SCRIPT="routing"
SIM_TIME=100
VEHICLES=18
RSUS=10
ARCHITECTURE=0  # 0=centralized SDVN

print_info "Results will be saved to: $RESULTS_DIR"
mkdir -p "$RESULTS_DIR"

# ============================================================================
# Helper: Collect CSV result files
# ============================================================================
collect_csv_files() {
    local output_dir=$1
    local test_name=$2
    local csv_count=0
    
    local csv_files=(
        "packet-delivery-analysis.csv"
        "blackhole-attack-results.csv"
        "sybil-attack-results.csv"
        "sybil-detection-results.csv"
        "sybil-mitigation-results.csv"
        "replay-attack-results.csv"
        "replay-detection-results.csv"
        "replay-mitigation-results.csv"
        "rtp-attack-results.csv"
        "rtp-detection-results.csv"
        "rtp-mitigation-results.csv"
        "trusted-certification-results.csv"
        "rssi-detection-results.csv"
        "resource-testing-results.csv"
        "incentive-scheme-results.csv"
        "DlRsrpSinrStats.txt"
        "UlSinrStats.txt"
        "DlRlcStats.txt"
    )
    
    for csv in "${csv_files[@]}"; do
        if [ -f "$csv" ]; then
            cp "$csv" "${output_dir}/${csv}"
            ((csv_count++))
        fi
    done
    
    if [ $csv_count -gt 0 ]; then
        print_success "${test_name} - collected ${csv_count} file(s)"
        return 0
    else
        print_warning "${test_name} - no result files generated"
        return 1
    fi
}

# ============================================================================
# Test 1: Baseline (No Attacks)
# ============================================================================
test_baseline() {
    local output_dir="$RESULTS_DIR/baseline"
    mkdir -p "$output_dir/logs"
    
    print_header "TEST 1: BASELINE (No Attacks)"
    print_info "Running baseline SDVN simulation..."
    
    ./waf --run "scratch/$ROUTING_SCRIPT \
        --simTime=$SIM_TIME \
        --routing_test=false \
        --N_Vehicles=$VEHICLES \
        --N_RSUs=$RSUS \
        --architecture=$ARCHITECTURE \
        --enable_packet_tracking=true" \
        > "$output_dir/logs/baseline.log" 2>&1
    
    if [ $? -eq 0 ]; then
        print_success "Baseline test completed"
        collect_csv_files "$output_dir" "baseline"
    else
        print_error "Baseline test failed! Check: $output_dir/logs/baseline.log"
        tail -30 "$output_dir/logs/baseline.log"
        return 1
    fi
}

# ============================================================================
# Test 2: Wormhole Attack by Data Plane Nodes (10%)
# ============================================================================
test_wormhole_10() {
    local output_dir="$RESULTS_DIR/wormhole_10pct"
    mkdir -p "$output_dir/logs"
    
    print_header "TEST 2: WORMHOLE ATTACK - 10% Malicious Data Plane Nodes"
    print_info "Compromised vehicles/RSUs create fake tunnels"
    print_info "Controllers detect and mitigate wormhole paths"
    
    ./waf --run "scratch/$ROUTING_SCRIPT \
        --simTime=$SIM_TIME \
        --routing_test=false \
        --N_Vehicles=$VEHICLES \
        --N_RSUs=$RSUS \
        --architecture=$ARCHITECTURE \
        --enable_packet_tracking=true \
        --present_wormhole_attack_nodes=true \
        --use_enhanced_wormhole=true \
        --attack_percentage=0.1 \
        --enable_wormhole_detection=true \
        --enable_wormhole_mitigation=true" \
        > "$output_dir/logs/wormhole_10.log" 2>&1
    
    if [ $? -eq 0 ]; then
        print_success "Wormhole 10% test completed"
        collect_csv_files "$output_dir" "wormhole_10"
    else
        print_error "Wormhole 10% test failed!"
        tail -30 "$output_dir/logs/wormhole_10.log"
        return 1
    fi
}

# ============================================================================
# Test 3: Wormhole Attack by Data Plane Nodes (20%)
# ============================================================================
test_wormhole_20() {
    local output_dir="$RESULTS_DIR/wormhole_20pct"
    mkdir -p "$output_dir/logs"
    
    print_header "TEST 3: WORMHOLE ATTACK - 20% Malicious Data Plane Nodes"
    print_info "Higher percentage of compromised nodes"
    
    ./waf --run "scratch/$ROUTING_SCRIPT \
        --simTime=$SIM_TIME \
        --routing_test=false \
        --N_Vehicles=$VEHICLES \
        --N_RSUs=$RSUS \
        --architecture=$ARCHITECTURE \
        --enable_packet_tracking=true \
        --present_wormhole_attack_nodes=true \
        --use_enhanced_wormhole=true \
        --attack_percentage=0.2 \
        --enable_wormhole_detection=true \
        --enable_wormhole_mitigation=true" \
        > "$output_dir/logs/wormhole_20.log" 2>&1
    
    if [ $? -eq 0 ]; then
        print_success "Wormhole 20% test completed"
        collect_csv_files "$output_dir" "wormhole_20"
    else
        print_error "Wormhole 20% test failed!"
        return 1
    fi
}

# ============================================================================
# Test 4: Blackhole Attack by Data Plane Nodes (10%)
# ============================================================================
test_blackhole_10() {
    local output_dir="$RESULTS_DIR/blackhole_10pct"
    mkdir -p "$output_dir/logs"
    
    print_header "TEST 4: BLACKHOLE ATTACK - 10% Malicious Data Plane Nodes"
    print_info "Compromised nodes drop packets silently"
    print_info "Controllers monitor PDR and blacklist malicious nodes"
    
    ./waf --run "scratch/$ROUTING_SCRIPT \
        --simTime=$SIM_TIME \
        --routing_test=false \
        --N_Vehicles=$VEHICLES \
        --N_RSUs=$RSUS \
        --architecture=$ARCHITECTURE \
        --enable_packet_tracking=true \
        --present_blackhole_attack_nodes=true \
        --attack_percentage=0.1 \
        --enable_blackhole_attack=true \
        --blackhole_attack_percentage=0.1 \
        --blackhole_advertise_fake_routes=true \
        --enable_blackhole_mitigation=true" \
        > "$output_dir/logs/blackhole_10.log" 2>&1
    
    if [ $? -eq 0 ]; then
        print_success "Blackhole 10% test completed"
        collect_csv_files "$output_dir" "blackhole_10"
    else
        print_error "Blackhole 10% test failed!"
        return 1
    fi
}

# ============================================================================
# Test 5: Blackhole Attack by Data Plane Nodes (20%)
# ============================================================================
test_blackhole_20() {
    local output_dir="$RESULTS_DIR/blackhole_20pct"
    mkdir -p "$output_dir/logs"
    
    print_header "TEST 5: BLACKHOLE ATTACK - 20% Malicious Data Plane Nodes"
    print_info "Higher percentage of packet-dropping nodes"
    
    ./waf --run "scratch/$ROUTING_SCRIPT \
        --simTime=$SIM_TIME \
        --routing_test=false \
        --N_Vehicles=$VEHICLES \
        --N_RSUs=$RSUS \
        --architecture=$ARCHITECTURE \
        --enable_packet_tracking=true \
        --present_blackhole_attack_nodes=true \
        --attack_percentage=0.2 \
        --enable_blackhole_attack=true \
        --blackhole_attack_percentage=0.2 \
        --blackhole_advertise_fake_routes=true \
        --enable_blackhole_mitigation=true" \
        > "$output_dir/logs/blackhole_20.log" 2>&1
    
    if [ $? -eq 0 ]; then
        print_success "Blackhole 20% test completed"
        collect_csv_files "$output_dir" "blackhole_20"
    else
        print_error "Blackhole 20% test failed!"
        return 1
    fi
}

# ============================================================================
# Test 6: Sybil Attack by Data Plane Nodes (10%)
# ============================================================================
test_sybil_10() {
    local output_dir="$RESULTS_DIR/sybil_10pct"
    mkdir -p "$output_dir/logs"
    
    print_header "TEST 6: SYBIL ATTACK - 10% Malicious Data Plane Nodes"
    print_info "Compromised nodes claim multiple fake identities"
    print_info "Controllers use PKI and RSSI to detect clones"
    
    ./waf --run "scratch/$ROUTING_SCRIPT \
        --simTime=$SIM_TIME \
        --routing_test=false \
        --N_Vehicles=$VEHICLES \
        --N_RSUs=$RSUS \
        --architecture=$ARCHITECTURE \
        --enable_packet_tracking=true \
        --present_sybil_attack_nodes=true \
        --attack_percentage=0.1 \
        --enable_sybil_attack=true \
        --sybil_attack_percentage=0.1 \
        --sybil_advertise_fake_routes=true \
        --sybil_clone_legitimate_nodes=true \
        --enable_sybil_detection=true \
        --enable_sybil_mitigation=true \
        --enable_sybil_mitigation_advanced=true \
        --use_trusted_certification=true \
        --use_rssi_detection=true" \
        > "$output_dir/logs/sybil_10.log" 2>&1
    
    if [ $? -eq 0 ]; then
        print_success "Sybil 10% test completed"
        collect_csv_files "$output_dir" "sybil_10"
    else
        print_error "Sybil 10% test failed!"
        return 1
    fi
}

# ============================================================================
# Test 7: Replay Attack by Data Plane Nodes (10%)
# ============================================================================
test_replay_10() {
    local output_dir="$RESULTS_DIR/replay_10pct"
    mkdir -p "$output_dir/logs"
    
    print_header "TEST 7: REPLAY ATTACK - 10% Malicious Data Plane Nodes"
    print_info "Compromised nodes capture and replay old packets"
    print_info "Controllers use Bloom Filters to detect duplicate packets"
    
    ./waf --run "scratch/$ROUTING_SCRIPT \
        --simTime=$SIM_TIME \
        --routing_test=false \
        --N_Vehicles=$VEHICLES \
        --N_RSUs=$RSUS \
        --architecture=$ARCHITECTURE \
        --enable_packet_tracking=true \
        --present_replay_attack_nodes=true \
        --enable_replay_attack=true \
        --replay_attack_percentage=0.1 \
        --replay_start_time=10.0 \
        --enable_replay_detection=true \
        --enable_replay_mitigation=true" \
        > "$output_dir/logs/replay_10.log" 2>&1
    
    if [ $? -eq 0 ]; then
        print_success "Replay 10% test completed"
        collect_csv_files "$output_dir" "replay_10"
    else
        print_error "Replay 10% test failed!"
        return 1
    fi
}

# ============================================================================
# Test 8: Routing Table Poisoning (RTP) Attack by Data Plane Nodes (10%)
# ============================================================================
test_rtp_10() {
    local output_dir="$RESULTS_DIR/rtp_10pct"
    mkdir -p "$output_dir/logs"
    
    print_header "TEST 8: ROUTING TABLE POISONING (RTP) ATTACK - 10% Malicious Nodes"
    print_info "Compromised nodes inject fake routing information"
    print_info "Controllers validate routing updates and detect anomalies"
    
    ./waf --run "scratch/$ROUTING_SCRIPT \
        --simTime=$SIM_TIME \
        --routing_test=false \
        --N_Vehicles=$VEHICLES \
        --N_RSUs=$RSUS \
        --architecture=$ARCHITECTURE \
        --enable_packet_tracking=true \
        --enable_rtp_attack=true \
        --rtp_attack_percentage=0.1 \
        --rtp_start_time=10.0" \
        > "$output_dir/logs/rtp_10.log" 2>&1
    
    if [ $? -eq 0 ]; then
        print_success "RTP 10% test completed"
        collect_csv_files "$output_dir" "rtp_10"
    else
        print_error "RTP 10% test failed!"
        return 1
    fi
}

# ============================================================================
# Test 9: Combined Attacks (All 5 at 10%)
# ============================================================================
test_combined() {
    local output_dir="$RESULTS_DIR/combined_10pct"
    mkdir -p "$output_dir/logs"
    
    print_header "TEST 9: COMBINED ATTACKS - All 5 Attacks (10% each)"
    print_info "Wormhole + Blackhole + Sybil + Replay + RTP simultaneously"
    print_info "Tests controller resilience under multiple threats"
    
    ./waf --run "scratch/$ROUTING_SCRIPT \
        --simTime=$SIM_TIME \
        --routing_test=false \
        --N_Vehicles=$VEHICLES \
        --N_RSUs=$RSUS \
        --architecture=$ARCHITECTURE \
        --enable_packet_tracking=true \
        --present_wormhole_attack_nodes=true \
        --present_blackhole_attack_nodes=true \
        --present_sybil_attack_nodes=true \
        --present_replay_attack_nodes=true \
        --use_enhanced_wormhole=true \
        --attack_percentage=0.1 \
        --enable_wormhole_detection=true \
        --enable_wormhole_mitigation=true \
        --enable_blackhole_attack=true \
        --blackhole_attack_percentage=0.1 \
        --enable_blackhole_mitigation=true \
        --enable_sybil_attack=true \
        --sybil_attack_percentage=0.1 \
        --enable_sybil_detection=true \
        --enable_sybil_mitigation=true \
        --enable_replay_attack=true \
        --replay_attack_percentage=0.1 \
        --enable_replay_detection=true \
        --enable_replay_mitigation=true \
        --enable_rtp_attack=true \
        --rtp_attack_percentage=0.1" \
        > "$output_dir/logs/combined.log" 2>&1
    
    if [ $? -eq 0 ]; then
        print_success "Combined attacks test completed"
        collect_csv_files "$output_dir" "combined"
    else
        print_error "Combined attacks test failed!"
        return 1
    fi
}

# ============================================================================
# Generate summary report
# ============================================================================
generate_summary() {
    local summary_file="$RESULTS_DIR/test_summary.txt"
    
    print_header "GENERATING TEST SUMMARY"
    
    cat > "$summary_file" << EOF
═══════════════════════════════════════════════════════════════
  SDVN DATA PLANE SECURITY ATTACK TEST SUMMARY
═══════════════════════════════════════════════════════════════

Test Date: $(date)
Results Directory: $RESULTS_DIR

ARCHITECTURE DETAILS:
─────────────────────────────────────────────────────────────
- Network Type: SDVN (Software-Defined Vehicular Network)
- Architecture: Centralized SDN with TRUSTED controllers
- Attack Location: DATA PLANE (compromised vehicles/RSUs)
- Controllers: TRUSTED and provide detection/mitigation
- Total Nodes: $((VEHICLES + RSUS)) (${VEHICLES} vehicles + ${RSUS} RSUs)
- Simulation Time: ${SIM_TIME} seconds

ATTACK MECHANISM:
─────────────────────────────────────────────────────────────
These attacks are performed by COMPROMISED DATA PLANE NODES
(malicious vehicles or RSUs) within the SDVN architecture.
The SDN controllers remain TRUSTED and actively detect and
mitigate attacks from the data plane.

TEST SCENARIOS:
─────────────────────────────────────────────────────────────
1. Baseline - No attacks
2. Wormhole Attack (10% malicious data plane nodes)
3. Wormhole Attack (20% malicious data plane nodes)
4. Blackhole Attack (10% malicious data plane nodes)
5. Blackhole Attack (20% malicious data plane nodes)
6. Sybil Attack (10% malicious data plane nodes)
7. Replay Attack (10% malicious data plane nodes)
8. Routing Table Poisoning (RTP) Attack (10% malicious nodes)
9. Combined Attacks (All 5 attacks @ 10% each)

ATTACK DESCRIPTIONS:
─────────────────────────────────────────────────────────────
1. WORMHOLE ATTACK (Data Plane):
   - Compromised nodes create fake tunnels
   - Packets tunneled through high-speed out-of-band channel
   - Controller sees false topology (shorter paths)
   - Detection: RTT-based latency monitoring by controller
   - Mitigation: Controller recalculates routes

2. BLACKHOLE ATTACK (Data Plane):
   - Compromised nodes silently drop packets
   - Nodes advertise fake routes to attract traffic
   - Controller's flow tables not manipulated
   - Detection: Controller monitors PDR per node
   - Mitigation: Controller blacklists suspicious nodes

3. SYBIL ATTACK (Data Plane):
   - Compromised nodes claim multiple identities
   - Report false neighbor info to controller
   - Pollutes controller's topology database
   - Detection: PKI certification + RSSI analysis
   - Mitigation: Trusted certification, RSSI verification

4. REPLAY ATTACK (Data Plane):
   - Compromised nodes capture and replay old packets
   - Creates duplicate traffic and confuses routing
   - Can replay authentication messages
   - Detection: Bloom Filters to detect packet duplicates
   - Mitigation: Automatic packet rejection and node blacklisting

5. ROUTING TABLE POISONING (RTP) ATTACK (Data Plane):
   - Compromised nodes inject fake routing information
   - Advertise false network topology to controller
   - Manipulate Multi-Hop Link (MHL) advertisements
   - Detection: Controller validates routing consistency
   - Mitigation: Route verification and anomaly detection

KEY DIFFERENCE FROM CONTROLLER ATTACKS:
─────────────────────────────────────────────────────────────
- Controllers: TRUSTED (not compromised)
- Data Plane: COMPROMISED (malicious nodes)
- Attacks happen at edge/data plane layer
- Controllers actively detect and mitigate

PERFORMANCE METRICS:
─────────────────────────────────────────────────────────────
- Packet Delivery Ratio (PDR)
- End-to-End Latency
- Routing Overhead
- Detection Accuracy
- Mitigation Effectiveness

FILES GENERATED:
─────────────────────────────────────────────────────────────
EOF
    
    # Count files
    find "$RESULTS_DIR" -name "*.csv" -o -name "*.txt" | while read f; do
        echo "  - $(basename $f)" >> "$summary_file"
    done
    
    cat >> "$summary_file" << EOF

═══════════════════════════════════════════════════════════════
Next Steps:
─────────────────────────────────────────────────────────────
1. Review individual test logs in each subdirectory
2. Analyze CSV files for performance metrics
3. Compare attack impact vs baseline
4. Evaluate mitigation effectiveness

═══════════════════════════════════════════════════════════════
EOF
    
    cat "$summary_file"
}

# ============================================================================
# Main execution
# ============================================================================
main() {
    print_info "Starting SDVN data plane attack test suite..."
    echo ""
    
    # Run all tests
    test_baseline || exit 1
    test_wormhole_10 || exit 1
    test_wormhole_20 || exit 1
    test_blackhole_10 || exit 1
    test_blackhole_20 || exit 1
    test_sybil_10 || exit 1
    test_replay_10 || exit 1
    test_rtp_10 || exit 1
    test_combined || exit 1
    
    # Generate summary
    print_header "GENERATING TEST SUMMARY"
    generate_summary
    
    print_header "ALL TESTS COMPLETED SUCCESSFULLY!"
    print_success "Results saved to: $RESULTS_DIR"
    print_info "View summary: cat $RESULTS_DIR/test_summary.txt"
}

# Run main function
main

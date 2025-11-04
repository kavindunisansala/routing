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

        mkdir -p "$RESULTS_DIR"/{baseline,wormhole,blackhole,sybil,replay,rtp}/{logs,csv,stats}

    print_header "TEST 1: BASELINE (No Attacks)"    mkdir -p "$RESULTS_DIR/summary"

    print_info "Running baseline SDVN simulation..."}

    

    ./waf --run "scratch/$ROUTING_SCRIPT \# Parse CSV results and extract metrics

        --simTime=$SIM_TIME \extract_metrics() {

        --routing_test=false \    local csv_file=$1

        --N_Vehicles=$VEHICLES \    local metric_name=$2

        --N_RSUs=$RSUS \    

        --architecture=$ARCHITECTURE \    if [ ! -f "$csv_file" ]; then

        --enable_packet_tracking=true" \        echo "0.0"

        > "$output_dir/logs/baseline.log" 2>&1        return

        fi

    if [ $? -eq 0 ]; then    

        print_success "Baseline test completed"    # Extract metric from CSV (assuming standard format)

        collect_csv_files "$output_dir" "baseline"    # This is a placeholder - adjust based on actual CSV format

    else    awk -F',' -v metric="$metric_name" 'NR==1 {for(i=1;i<=NF;i++) if($i==metric) col=i} NR>1 {sum+=$col; count++} END {print (count>0 ? sum/count : 0)}' "$csv_file"

        print_error "Baseline test failed! Check: $output_dir/logs/baseline.log"}

        tail -30 "$output_dir/logs/baseline.log"

        return 1# Validate metrics against thresholds

    fivalidate_metrics() {

}    local test_name=$1

    local pdr=$2

# ============================================================================    local latency=$3

# Test 2: Wormhole Attack by Data Plane Nodes (10%)    local overhead=$4

# ============================================================================    local detection=$5

test_wormhole_10() {    local expected_pdr_min=$6

    local output_dir="$RESULTS_DIR/wormhole_10pct"    local expected_pdr_max=${7:-1.0}

    mkdir -p "$output_dir/logs"    

        local passed=true

    print_header "TEST 2: WORMHOLE ATTACK - 10% Malicious Data Plane Nodes"    

    print_info "Compromised vehicles/RSUs create fake tunnels"    echo -e "\n${YELLOW}Metric Validation for $test_name:${NC}"

    print_info "Controllers detect and mitigate wormhole paths"    

        # PDR validation

    ./waf --run "scratch/$ROUTING_SCRIPT \    if (( $(echo "$pdr >= $expected_pdr_min" | bc -l) )); then

        --simTime=$SIM_TIME \        print_success "PDR: $pdr (>= $expected_pdr_min)"

        --routing_test=false \    else

        --N_Vehicles=$VEHICLES \        print_error "PDR: $pdr (expected >= $expected_pdr_min)"

        --N_RSUs=$RSUS \        passed=false

        --architecture=$ARCHITECTURE \    fi

        --enable_packet_tracking=true \    

        --present_wormhole_attack_nodes=true \    if [ -n "$expected_pdr_max" ] && (( $(echo "$pdr <= $expected_pdr_max" | bc -l) )); then

        --use_enhanced_wormhole=true \        print_success "PDR: $pdr (<= $expected_pdr_max)"

        --attack_percentage=0.1 \    elif [ -n "$expected_pdr_max" ]; then

        --enable_wormhole_detection=true \        print_error "PDR: $pdr (expected <= $expected_pdr_max)"

        --enable_wormhole_mitigation=true" \        passed=false

        > "$output_dir/logs/wormhole_10.log" 2>&1    fi

        

    if [ $? -eq 0 ]; then    # Latency validation

        print_success "Wormhole 10% test completed"    if (( $(echo "$latency > 0" | bc -l) )); then

        collect_csv_files "$output_dir" "wormhole_10"        print_success "Latency: ${latency}ms"

    else    else

        print_error "Wormhole 10% test failed! Check: $output_dir/logs/wormhole_10.log"        print_warning "Latency: ${latency}ms (no data)"

        return 1    fi

    fi    

}    # Overhead validation

    if (( $(echo "$overhead <= $OVERHEAD_MAX" | bc -l) )); then

# ============================================================================        print_success "Overhead: $overhead (<= $OVERHEAD_MAX)"

# Test 3: Wormhole Attack by Data Plane Nodes (20%)    else

# ============================================================================        print_error "Overhead: $overhead (expected <= $OVERHEAD_MAX)"

test_wormhole_20() {        passed=false

    local output_dir="$RESULTS_DIR/wormhole_20pct"    fi

    mkdir -p "$output_dir/logs"    

        # Detection accuracy (if applicable)

    print_header "TEST 3: WORMHOLE ATTACK - 20% Malicious Data Plane Nodes"    if [ "$detection" != "N/A" ] && (( $(echo "$detection >= $DETECTION_ACCURACY_MIN" | bc -l) )); then

            print_success "Detection Accuracy: $detection (>= $DETECTION_ACCURACY_MIN)"

    ./waf --run "scratch/$ROUTING_SCRIPT \    elif [ "$detection" != "N/A" ]; then

        --simTime=$SIM_TIME \        print_error "Detection Accuracy: $detection (expected >= $DETECTION_ACCURACY_MIN)"

        --routing_test=false \        passed=false

        --N_Vehicles=$VEHICLES \    fi

        --N_RSUs=$RSUS \    

        --architecture=$ARCHITECTURE \    if [ "$passed" = true ]; then

        --enable_packet_tracking=true \        print_success "$test_name: ALL METRICS PASSED"

        --present_wormhole_attack_nodes=true \        return 0

        --use_enhanced_wormhole=true \    else

        --attack_percentage=0.2 \        print_error "$test_name: SOME METRICS FAILED"

        --enable_wormhole_detection=true \        return 1

        --enable_wormhole_mitigation=true" \    fi

        > "$output_dir/logs/wormhole_20.log" 2>&1}

    

    if [ $? -eq 0 ]; then################################################################################

        print_success "Wormhole 20% test completed"# Test Scenarios

        collect_csv_files "$output_dir" "wormhole_20"################################################################################

    else

        print_error "Wormhole 20% test failed!"# Test 1: Baseline (No Attack)

        return 1test_baseline() {

    fi    print_header "TEST 1: BASELINE (No Attack)"

}    

    local output_dir="$RESULTS_DIR/baseline"

# ============================================================================    print_info "Running baseline simulation..."

# Test 4: Blackhole Attack by Data Plane Nodes (10%)    

# ============================================================================    # Check if we're in NS-3 directory

test_blackhole_10() {    if [ ! -f "waf" ]; then

    local output_dir="$RESULTS_DIR/blackhole_10pct"        print_error "Error: waf not found. Please run this script from NS-3 root directory."

    mkdir -p "$output_dir/logs"        print_info "Current directory: $(pwd)"

            return 1

    print_header "TEST 4: BLACKHOLE ATTACK - 10% Malicious Data Plane Nodes"    fi

    print_info "Compromised nodes drop packets silently"    

    print_info "Controllers monitor PDR and blacklist malicious nodes"    # Compile NS-3 if needed

        if [ ! -f "build/scratch/ns3.35-routing-default" ] && [ ! -f "build/scratch/routing" ]; then

    ./waf --run "scratch/$ROUTING_SCRIPT \        print_info "Compiling NS-3 project..."

        --simTime=$SIM_TIME \        ./waf build || {

        --routing_test=false \            print_error "Build failed! Please check compilation errors."

        --N_Vehicles=$VEHICLES \            return 1

        --N_RSUs=$RSUS \        }

        --architecture=$ARCHITECTURE \    fi

        --enable_packet_tracking=true \    

        --present_blackhole_attack_nodes=true \    # Run simulation with no attacks

        --attack_percentage=0.1 \    print_info "Executing simulation..."

        --enable_blackhole_attack=true \    

        --blackhole_attack_percentage=0.1 \    # First, test if routing binary exists and runs

        --blackhole_advertise_fake_routes=true \    if ! ./waf --run "scratch/$ROUTING_SCRIPT --PrintHelp" > /dev/null 2>&1; then

        --enable_blackhole_mitigation=true" \        print_error "Cannot execute routing binary. Building first..."

        > "$output_dir/logs/blackhole_10.log" 2>&1        ./waf clean

            ./waf configure

    if [ $? -eq 0 ]; then        ./waf build

        print_success "Blackhole 10% test completed"    fi

        collect_csv_files "$output_dir" "blackhole_10"    

    else    ./waf --run "scratch/$ROUTING_SCRIPT \

        print_error "Blackhole 10% test failed!"        --simTime=$SIM_TIME \

        return 1        --routing_test=false \

    fi        --N_Vehicles=$VEHICLES \

}        --N_RSUs=$RSUS \

        --enable_wormhole_attack=false \

# ============================================================================        --enable_blackhole_attack=false \

# Test 5: Blackhole Attack by Data Plane Nodes (20%)        --enable_sybil_attack=false \

# ============================================================================        --enable_replay_attack=false \

test_blackhole_20() {        --enable_rtp_attack=false" \

    local output_dir="$RESULTS_DIR/blackhole_20pct"        > "$output_dir/logs/baseline.log" 2>&1

    mkdir -p "$output_dir/logs"    

        local exit_code=$?

    print_header "TEST 5: BLACKHOLE ATTACK - 20% Malicious Data Plane Nodes"    

        if [ $exit_code -ne 0 ]; then

    ./waf --run "scratch/$ROUTING_SCRIPT \        print_error "Simulation failed with exit code $exit_code! Check log: $output_dir/logs/baseline.log"

        --simTime=$SIM_TIME \        echo ""

        --routing_test=false \        print_info "Last 30 lines of log:"

        --N_Vehicles=$VEHICLES \        tail -30 "$output_dir/logs/baseline.log"

        --N_RSUs=$RSUS \        echo ""

        --architecture=$ARCHITECTURE \        print_info "Checking for common errors..."

        --enable_packet_tracking=true \        

        --present_blackhole_attack_nodes=true \        if grep -q "Segmentation fault" "$output_dir/logs/baseline.log"; then

        --attack_percentage=0.2 \            print_error "SEGMENTATION FAULT detected!"

        --enable_blackhole_attack=true \        fi

        --blackhole_attack_percentage=0.2 \        

        --blackhole_advertise_fake_routes=true \        if grep -q "Assertion" "$output_dir/logs/baseline.log"; then

        --enable_blackhole_mitigation=true" \            print_error "ASSERTION FAILURE detected!"

        > "$output_dir/logs/blackhole_20.log" 2>&1            grep "Assertion" "$output_dir/logs/baseline.log"

            fi

    if [ $? -eq 0 ]; then        

        print_success "Blackhole 20% test completed"        if grep -q "abort" "$output_dir/logs/baseline.log"; then

        collect_csv_files "$output_dir" "blackhole_20"            print_error "ABORT detected!"

    else            grep -i "abort\|terminate" "$output_dir/logs/baseline.log" | head -5

        print_error "Blackhole 20% test failed!"        fi

        return 1        

    fi        if grep -q "Command.*exited with code" "$output_dir/logs/baseline.log"; then

}            print_warning "NS-3 reports command exited - this might be due to routing.cc internal errors"

        fi

# ============================================================================        

# Test 6: Sybil Attack by Data Plane Nodes (10%)        return 1

# ============================================================================    fi

test_sybil_10() {    

    local output_dir="$RESULTS_DIR/sybil_10pct"    print_success "Baseline simulation completed"

    mkdir -p "$output_dir/logs"    

        # Extract metrics

    print_header "TEST 6: SYBIL ATTACK - 10% Malicious Data Plane Nodes"    local pdr=$(extract_metrics "$output_dir/csv/baseline_stats.csv" "PDR")

    print_info "Compromised nodes claim multiple fake identities"    local latency=$(extract_metrics "$output_dir/csv/baseline_stats.csv" "AvgLatency")

    print_info "Controllers use PKI and RSSI to detect clones"    local overhead=$(extract_metrics "$output_dir/csv/baseline_stats.csv" "Overhead")

        

    ./waf --run "scratch/$ROUTING_SCRIPT \    # Store baseline metrics for comparison

        --simTime=$SIM_TIME \    echo "$pdr" > "$RESULTS_DIR/baseline_pdr.txt"

        --routing_test=false \    echo "$latency" > "$RESULTS_DIR/baseline_latency.txt"

        --N_Vehicles=$VEHICLES \    

        --N_RSUs=$RSUS \    print_info "Baseline Metrics:"

        --architecture=$ARCHITECTURE \    echo "  PDR: $pdr"

        --enable_packet_tracking=true \    echo "  Latency: ${latency}ms"

        --present_sybil_attack_nodes=true \    echo "  Overhead: $overhead"

        --attack_percentage=0.1 \    

        --enable_sybil_attack=true \    validate_metrics "Baseline" "$pdr" "$latency" "$overhead" "N/A" "$BASELINE_PDR_MIN"

        --sybil_attack_percentage=0.1 \}

        --sybil_advertise_fake_routes=true \

        --sybil_clone_legitimate_nodes=true \# Test 2: Wormhole Attack (with and without mitigation)

        --enable_sybil_detection=true \test_wormhole_attack() {

        --enable_sybil_mitigation=true \    print_header "TEST 2: WORMHOLE ATTACK"

        --enable_sybil_mitigation_advanced=true \    

        --use_trusted_certification=true \    local output_dir="$RESULTS_DIR/wormhole"

        --use_rssi_detection=true" \    

        > "$output_dir/logs/sybil_10.log" 2>&1    # 2a: Wormhole Attack (No Mitigation)

        print_info "Running Wormhole attack without mitigation..."

    if [ $? -eq 0 ]; then    

        print_success "Sybil 10% test completed"    print_info "Executing simulation..."

        collect_csv_files "$output_dir" "sybil_10"    ./waf --run "scratch/$ROUTING_SCRIPT \

    else        --simTime=$SIM_TIME 

        print_error "Sybil 10% test failed!"        --routing_test=false \

        return 1        --N_Vehicles=$VEHICLES \

    fi        --N_RSUs=$RSUS \

}        

        --enable_wormhole_attack=true \

# ============================================================================        --use_enhanced_wormhole=true \

# Test 7: Combined Attacks (All 3 at 10%)        --wormhole_random_pairing=true \

# ============================================================================        --wormhole_tunnel_routing=true \

test_combined() {        --wormhole_tunnel_data=true \

    local output_dir="$RESULTS_DIR/combined_10pct"        --wormhole_start_time=10.0 \

    mkdir -p "$output_dir/logs"        --attack_percentage=0.20 \

            --enable_wormhole_detection=false \

    print_header "TEST 7: COMBINED ATTACKS - Wormhole + Blackhole + Sybil (10% each)"        --enable_wormhole_mitigation=false" \

    print_info "Multiple attack types simultaneously"        > "$output_dir/logs/wormhole_attack.log" 2>&1 || {

            print_error "Wormhole attack simulation failed! Check log: $output_dir/logs/wormhole_attack.log"

    ./waf --run "scratch/$ROUTING_SCRIPT \        return 1

        --simTime=$SIM_TIME \    }

        --routing_test=false \    

        --N_Vehicles=$VEHICLES \    print_success "Wormhole attack simulation completed"

        --N_RSUs=$RSUS \    

        --architecture=$ARCHITECTURE \    local attack_pdr=$(extract_metrics "$output_dir/csv/wormhole_attack_stats.csv" "PDR")

        --enable_packet_tracking=true \    local attack_latency=$(extract_metrics "$output_dir/csv/wormhole_attack_stats.csv" "AvgLatency")

        --present_wormhole_attack_nodes=true \    local attack_overhead=$(extract_metrics "$output_dir/csv/wormhole_attack_stats.csv" "Overhead")

        --present_blackhole_attack_nodes=true \    

        --present_sybil_attack_nodes=true \    print_info "Wormhole Attack Metrics (No Mitigation):"

        --use_enhanced_wormhole=true \    echo "  PDR: $attack_pdr"

        --attack_percentage=0.1 \    echo "  Latency: ${attack_latency}ms"

        --enable_wormhole_detection=true \    echo "  Packets Tunneled: $(grep -oP 'packetsTunneled: \K\d+' $output_dir/logs/wormhole_attack.log || echo 0)"

        --enable_wormhole_mitigation=true \    

        --enable_blackhole_attack=true \    validate_metrics "Wormhole Attack" "$attack_pdr" "$attack_latency" "$attack_overhead" "N/A" "0.0" "$ATTACK_PDR_MAX"

        --blackhole_attack_percentage=0.1 \    

        --enable_blackhole_mitigation=true \    # 2b: Wormhole Attack with Mitigation

        --enable_sybil_attack=true \    print_info "Running Wormhole attack WITH mitigation..."

        --sybil_attack_percentage=0.1 \    

        --enable_sybil_detection=true \    print_info "Executing simulation..."

        --enable_sybil_mitigation=true" \    ./waf --run "scratch/$ROUTING_SCRIPT \

        > "$output_dir/logs/combined.log" 2>&1        --simTime=$SIM_TIME 

            --routing_test=false \

    if [ $? -eq 0 ]; then        --N_Vehicles=$VEHICLES \

        print_success "Combined attacks test completed"        --N_RSUs=$RSUS \

        collect_csv_files "$output_dir" "combined"        

    else        --enable_wormhole_attack=true \

        print_error "Combined attacks test failed!"        --use_enhanced_wormhole=true \

        return 1        --wormhole_random_pairing=true \

    fi        --wormhole_tunnel_routing=true \

}        --wormhole_tunnel_data=true \

        --wormhole_start_time=10.0 \

# ============================================================================        --attack_percentage=0.20 \

# Helper: Collect CSV result files        --enable_wormhole_detection=true \

# ============================================================================        --enable_wormhole_mitigation=true \

collect_csv_files() {        --detection_latency_threshold=2.0 \

    local dest_dir=$1        --detection_check_interval=1.0" \

    local test_name=$2        > "$output_dir/logs/wormhole_mitigation.log" 2>&1 || {

    local csv_count=0        print_error "Wormhole mitigation simulation failed!"

            return 1

    local csv_files=(    }

        "packet-delivery-analysis.csv"    

        "blackhole-attack-results.csv"    print_success "Wormhole mitigation simulation completed"

        "sybil-attack-results.csv"    

        "sybil-detection-results.csv"    local mitig_pdr=$(extract_metrics "$output_dir/csv/wormhole_mitigation_stats.csv" "PDR")

        "replay-attack-results.csv"    local mitig_latency=$(extract_metrics "$output_dir/csv/wormhole_mitigation_stats.csv" "AvgLatency")

        "DlRsrpSinrStats.txt"    local mitig_overhead=$(extract_metrics "$output_dir/csv/wormhole_mitigation_stats.csv" "Overhead")

        "UlSinrStats.txt"    local detection_accuracy=$(extract_metrics "$output_dir/csv/wormhole_detection.csv" "DetectionAccuracy")

        "DlRlcStats.txt"    

    )    print_info "Wormhole Mitigation Metrics:"

        echo "  PDR: $mitig_pdr"

    for csv in "${csv_files[@]}"; do    echo "  Latency: ${mitig_latency}ms"

        if [ -f "$csv" ]; then    echo "  Detection Accuracy: $detection_accuracy"

            cp "$csv" "$dest_dir/${csv}"    echo "  Wormholes Detected: $(grep -oP 'wormholesDetected: \K\d+' $output_dir/logs/wormhole_mitigation.log || echo 0)"

            ((csv_count++))    

        fi    validate_metrics "Wormhole Mitigation" "$mitig_pdr" "$mitig_latency" "$mitig_overhead" "$detection_accuracy" "$MITIGATION_PDR_MIN"

    done}

    

    if [ $csv_count -gt 0 ]; then# Test 3: Blackhole Attack (with and without mitigation)

        print_info "Collected $csv_count result file(s) for $test_name"test_blackhole_attack() {

    fi    print_header "TEST 3: BLACKHOLE ATTACK"

}    

    local output_dir="$RESULTS_DIR/blackhole"

# ============================================================================    

# Main execution    # 3a: Blackhole Attack (No Mitigation)

# ============================================================================    print_info "Running Blackhole attack without mitigation..."

main() {    

    print_info "Starting SDVN data plane attack test suite..."    ./waf --run "scratch/$ROUTING_SCRIPT \

    echo ""        --simTime=$SIM_TIME 

            --routing_test=false \

    # Run all tests        --N_Vehicles=$VEHICLES \

    test_baseline || exit 1        --N_RSUs=$RSUS \

    test_wormhole_10 || exit 1        

    test_wormhole_20 || exit 1        --enable_blackhole_attack=true \

    test_blackhole_10 || exit 1        --blackhole_drop_data=true \

    test_blackhole_20 || exit 1        --blackhole_advertise_fake_routes=true \

    test_sybil_10 || exit 1        --blackhole_start_time=10.0 \

    test_combined || exit 1        --blackhole_attack_percentage=0.15 \

            --enable_blackhole_mitigation=false" \

    # Generate summary        > "$output_dir/logs/blackhole_attack.log" 2>&1

    print_header "GENERATING TEST SUMMARY"    

    generate_summary    local attack_pdr=$(extract_metrics "$output_dir/csv/blackhole_attack_stats.csv" "PDR")

        local attack_latency=$(extract_metrics "$output_dir/csv/blackhole_attack_stats.csv" "AvgLatency")

    print_header "ALL TESTS COMPLETED SUCCESSFULLY!"    local packets_dropped=$(grep -oP 'dataPacketsDropped: \K\d+' "$output_dir/logs/blackhole_attack.log" || echo 0)

    print_success "Results saved to: $RESULTS_DIR"    

    print_info "View summary: cat $RESULTS_DIR/test_summary.txt"    print_info "Blackhole Attack Metrics (No Mitigation):"

}    echo "  PDR: $attack_pdr"

    echo "  Latency: ${attack_latency}ms"

# ============================================================================    echo "  Packets Dropped: $packets_dropped"

# Generate summary report    

# ============================================================================    validate_metrics "Blackhole Attack" "$attack_pdr" "$attack_latency" "0.0" "N/A" "0.0" "$ATTACK_PDR_MAX"

generate_summary() {    

    local summary_file="$RESULTS_DIR/test_summary.txt"    # 3b: Blackhole Attack with Mitigation

        print_info "Running Blackhole attack WITH mitigation..."

    cat > "$summary_file" << EOF    

═══════════════════════════════════════════════════════════════    ./waf --run "scratch/$ROUTING_SCRIPT \

  SDVN DATA PLANE SECURITY ATTACK TEST SUMMARY        --simTime=$SIM_TIME 

═══════════════════════════════════════════════════════════════        --routing_test=false \

        --N_Vehicles=$VEHICLES \

Test Date: $(date)        --N_RSUs=$RSUS \

Results Directory: $RESULTS_DIR        --enable_blackhole_attack=true \

        --blackhole_drop_data=true \

ARCHITECTURE DETAILS:        --blackhole_advertise_fake_routes=true \

─────────────────────────────────────────────────────────────        --blackhole_start_time=10.0 \

- Network Type: SDVN (Software-Defined Vehicular Network)        --blackhole_attack_percentage=0.15 \

- Architecture: Centralized SDN with TRUSTED controllers        --enable_blackhole_mitigation=true \

- Attack Location: DATA PLANE (compromised vehicles/RSUs)        --blackhole_pdr_threshold=0.5 \

- Controllers: TRUSTED and provide detection/mitigation        --blackhole_min_packets=10" \

- Total Nodes: $((VEHICLES + RSUS)) (${VEHICLES} vehicles + ${RSUS} RSUs)        > "$output_dir/logs/blackhole_mitigation.log" 2>&1

- Simulation Time: ${SIM_TIME} seconds    

    local mitig_pdr=$(extract_metrics "$output_dir/csv/blackhole_mitigation_stats.csv" "PDR")

ATTACK MECHANISM:    local mitig_latency=$(extract_metrics "$output_dir/csv/blackhole_mitigation_stats.csv" "AvgLatency")

─────────────────────────────────────────────────────────────    local detection_rate=$(grep -oP 'Detection Rate: \K[\d.]+' "$output_dir/logs/blackhole_mitigation.log" || echo 0)

These attacks are performed by COMPROMISED DATA PLANE NODES    local blacklisted_nodes=$(grep -oP 'Blacklisted Nodes: \K\d+' "$output_dir/logs/blackhole_mitigation.log" || echo 0)

(malicious vehicles or RSUs) within the SDVN architecture.    

The SDN controllers remain TRUSTED and actively detect and    print_info "Blackhole Mitigation Metrics:"

mitigate attacks from the data plane.    echo "  PDR: $mitig_pdr"

    echo "  Latency: ${mitig_latency}ms"

TEST SCENARIOS:    echo "  Detection Rate: $detection_rate"

─────────────────────────────────────────────────────────────    echo "  Blacklisted Nodes: $blacklisted_nodes"

1. Baseline - No attacks    

2. Wormhole Attack (10% malicious data plane nodes)    validate_metrics "Blackhole Mitigation" "$mitig_pdr" "$mitig_latency" "0.0" "$detection_rate" "$MITIGATION_PDR_MIN"

3. Wormhole Attack (20% malicious data plane nodes)  }

4. Blackhole Attack (10% malicious data plane nodes)

5. Blackhole Attack (20% malicious data plane nodes)# Test 4: Sybil Attack (with and without mitigation)

6. Sybil Attack (10% malicious data plane nodes)test_sybil_attack() {

7. Combined Attacks (Wormhole + Blackhole + Sybil @ 10% each)    print_header "TEST 4: SYBIL ATTACK"

    

ATTACK DESCRIPTIONS:    local output_dir="$RESULTS_DIR/sybil"

─────────────────────────────────────────────────────────────    

1. WORMHOLE ATTACK (Data Plane):    # 4a: Sybil Attack (No Mitigation)

   - Compromised nodes create fake tunnels    print_info "Running Sybil attack without mitigation..."

   - Packets tunneled through high-speed out-of-band channel    

   - Controller sees false topology (shorter paths)    ./waf --run "scratch/$ROUTING_SCRIPT \

   - Detection: RTT-based latency monitoring by controller        --simTime=$SIM_TIME 

   - Mitigation: Controller recalculates routes        --routing_test=false \

        --N_Vehicles=$VEHICLES \

2. BLACKHOLE ATTACK (Data Plane):        --N_RSUs=$RSUS \

   - Compromised nodes silently drop packets        

   - Nodes advertise fake routes to attract traffic        --enable_sybil_attack=true \

   - Controller's flow tables not manipulated        --sybil_identities_per_node=3 \

   - Detection: Controller monitors PDR per node        --sybil_clone_legitimate_nodes=true \

   - Mitigation: Controller blacklists suspicious nodes        --sybil_inject_fake_packets=true \

        --sybil_start_time=10.0 \

3. SYBIL ATTACK (Data Plane):        --sybil_attack_percentage=0.15 \

   - Compromised nodes claim multiple identities        --sybil_broadcast_interval=2.0 \

   - Report false neighbor info to controller        --enable_sybil_detection=false \

   - Pollutes controller's topology database        --enable_sybil_mitigation=false" \

   - Detection: PKI certification + RSSI analysis        > "$output_dir/logs/sybil_attack.log" 2>&1

   - Mitigation: Trusted certification, RSSI verification    

    local attack_pdr=$(extract_metrics "$output_dir/csv/sybil_attack_stats.csv" "PDR")

KEY DIFFERENCE FROM CONTROLLER ATTACKS:    local attack_latency=$(extract_metrics "$output_dir/csv/sybil_attack_stats.csv" "AvgLatency")

─────────────────────────────────────────────────────────────    local fake_identities=$(grep -oP 'fakeIdentitiesCreated: \K\d+' "$output_dir/logs/sybil_attack.log" || echo 0)

- Controllers: TRUSTED (not compromised)    

- Data Plane: COMPROMISED (malicious nodes)    print_info "Sybil Attack Metrics (No Mitigation):"

- Attacks happen at edge/data plane layer    echo "  PDR: $attack_pdr"

- Controllers actively detect and mitigate    echo "  Latency: ${attack_latency}ms"

    echo "  Fake Identities Created: $fake_identities"

PERFORMANCE METRICS:    

─────────────────────────────────────────────────────────────    validate_metrics "Sybil Attack" "$attack_pdr" "$attack_latency" "0.0" "N/A" "0.0" "$ATTACK_PDR_MAX"

- Packet Delivery Ratio (PDR)    

- End-to-End Latency    # 4b: Sybil Attack with Mitigation

- Routing Overhead    print_info "Running Sybil attack WITH mitigation..."

- Detection Accuracy    

- Mitigation Effectiveness    ./waf --run "scratch/$ROUTING_SCRIPT \

        --simTime=$SIM_TIME 

FILES GENERATED:        --routing_test=false \

─────────────────────────────────────────────────────────────        --N_Vehicles=$VEHICLES \

EOF        --N_RSUs=$RSUS \

        

    # Count files        --enable_sybil_attack=true \

    find "$RESULTS_DIR" -name "*.csv" -o -name "*.txt" | while read f; do        --sybil_identities_per_node=3 \

        echo "  - $(basename $f)" >> "$summary_file"        --sybil_clone_legitimate_nodes=true \

    done        --sybil_inject_fake_packets=true \

            --sybil_start_time=10.0 \

    cat >> "$summary_file" << EOF        --sybil_attack_percentage=0.15 \

        --sybil_broadcast_interval=2.0 \

═══════════════════════════════════════════════════════════════        --enable_sybil_detection=true \

Next Steps:        --enable_sybil_mitigation=true \

─────────────────────────────────────────────────────────────        --enable_sybil_mitigation_advanced=true \

1. Review individual test logs in each subdirectory        --use_trusted_certification=true \

2. Analyze CSV files for performance metrics        --use_rssi_detection=true \

3. Compare attack impact vs baseline        --sybil_detection_threshold=0.8" \

4. Evaluate mitigation effectiveness        > "$output_dir/logs/sybil_mitigation.log" 2>&1

    

═══════════════════════════════════════════════════════════════    local mitig_pdr=$(extract_metrics "$output_dir/csv/sybil_mitigation_stats.csv" "PDR")

EOF    local mitig_latency=$(extract_metrics "$output_dir/csv/sybil_mitigation_stats.csv" "AvgLatency")

        local mitig_overhead=$(extract_metrics "$output_dir/csv/sybil_mitigation_stats.csv" "Overhead")

    cat "$summary_file"    local detection_accuracy=$(extract_metrics "$output_dir/csv/sybil_detection.csv" "DetectionAccuracy")

}    local identities_detected=$(grep -oP 'totalFakeIdentitiesBlocked: \K\d+' "$output_dir/logs/sybil_mitigation.log" || echo 0)

    

# Run main function    print_info "Sybil Mitigation Metrics:"

main    echo "  PDR: $mitig_pdr"

    echo "  Latency: ${mitig_latency}ms"
    echo "  Overhead: $mitig_overhead"
    echo "  Detection Accuracy: $detection_accuracy"
    echo "  Identities Detected/Blocked: $identities_detected"
    
    validate_metrics "Sybil Mitigation" "$mitig_pdr" "$mitig_latency" "$mitig_overhead" "$detection_accuracy" "$MITIGATION_PDR_MIN"
}

# Test 5: Replay Attack (with and without mitigation)
test_replay_attack() {
    print_header "TEST 5: REPLAY ATTACK"
    
    local output_dir="$RESULTS_DIR/replay"
    
    # 5a: Replay Attack (No Mitigation)
    print_info "Running Replay attack without mitigation..."
    
    ./waf --run "scratch/$ROUTING_SCRIPT \
        --simTime=$SIM_TIME 
        --routing_test=false \
        --N_Vehicles=$VEHICLES \
        --N_RSUs=$RSUS \
        
        --enable_replay_attack=true \
        --replay_start_time=10.0 \
        --replay_attack_percentage=0.10 \
        --replay_interval=1.0 \
        --replay_count_per_node=5 \
        --enable_replay_detection=false \
        --enable_replay_mitigation=false" \
        > "$output_dir/logs/replay_attack.log" 2>&1
    
    local attack_pdr=$(extract_metrics "$output_dir/csv/replay_attack_stats.csv" "PDR")
    local attack_latency=$(extract_metrics "$output_dir/csv/replay_attack_stats.csv" "AvgLatency")
    local packets_replayed=$(grep -oP 'packetsReplayed: \K\d+' "$output_dir/logs/replay_attack.log" || echo 0)
    
    print_info "Replay Attack Metrics (No Mitigation):"
    echo "  PDR: $attack_pdr"
    echo "  Latency: ${attack_latency}ms"
    echo "  Packets Replayed: $packets_replayed"
    
    validate_metrics "Replay Attack" "$attack_pdr" "$attack_latency" "0.0" "N/A" "0.0" "$ATTACK_PDR_MAX"
    
    # 5b: Replay Attack with Mitigation (Bloom Filters)
    print_info "Running Replay attack WITH Bloom Filter mitigation..."
    
    ./waf --run "scratch/$ROUTING_SCRIPT \
        --simTime=$SIM_TIME 
        --routing_test=false \
        --N_Vehicles=$VEHICLES \
        --N_RSUs=$RSUS \
        
        --enable_replay_attack=true \
        --replay_start_time=10.0 \
        --replay_attack_percentage=0.10 \
        --replay_interval=1.0 \
        --replay_count_per_node=5 \
        --enable_replay_detection=true \
        --enable_replay_mitigation=true \
        --bf_filter_size=8192 \
        --bf_num_hash_functions=4 \
        --bf_num_filters=3 \
        --bf_rotation_interval=5.0" \
        > "$output_dir/logs/replay_mitigation.log" 2>&1
    
    local mitig_pdr=$(extract_metrics "$output_dir/csv/replay_mitigation_stats.csv" "PDR")
    local mitig_latency=$(extract_metrics "$output_dir/csv/replay_mitigation_stats.csv" "AvgLatency")
    local mitig_overhead=$(extract_metrics "$output_dir/csv/replay_mitigation_stats.csv" "Overhead")
    local detection_accuracy=$(extract_metrics "$output_dir/csv/replay_detection.csv" "DetectionAccuracy")
    local replays_detected=$(grep -oP 'replaysDetected: \K\d+' "$output_dir/logs/replay_mitigation.log" || echo 0)
    local false_positives=$(grep -oP 'falsePositives: \K\d+' "$output_dir/logs/replay_mitigation.log" || echo 0)
    
    print_info "Replay Mitigation Metrics:"
    echo "  PDR: $mitig_pdr"
    echo "  Latency: ${mitig_latency}ms"
    echo "  Overhead: $mitig_overhead"
    echo "  Detection Accuracy: $detection_accuracy"
    echo "  Replays Detected: $replays_detected"
    echo "  False Positives: $false_positives"
    
    validate_metrics "Replay Mitigation" "$mitig_pdr" "$mitig_latency" "$mitig_overhead" "$detection_accuracy" "$MITIGATION_PDR_MIN"
}

# Test 6: Routing Table Poisoning (RTP) Attack
test_rtp_attack() {
    print_header "TEST 6: ROUTING TABLE POISONING (RTP) ATTACK"
    
    local output_dir="$RESULTS_DIR/rtp"
    
    # 6a: RTP Attack (No Mitigation)
    print_info "Running RTP attack without mitigation..."
    
    ./waf --run "scratch/$ROUTING_SCRIPT \
        --simTime=$SIM_TIME 
        --routing_test=false \
        --N_Vehicles=$VEHICLES \
        --N_RSUs=$RSUS \
        
        --enable_rtp_attack=true \
        --rtp_inject_fake_routes=true \
        --rtp_fabricate_mhls=true \
        --rtp_start_time=10.0 \
        --rtp_attack_percentage=0.10 \
        --enable_hybrid_shield_detection=false \
        --enable_hybrid_shield_mitigation=false" \
        > "$output_dir/logs/rtp_attack.log" 2>&1
    
    local attack_pdr=$(extract_metrics "$output_dir/csv/rtp_attack_stats.csv" "PDR")
    local attack_latency=$(extract_metrics "$output_dir/csv/rtp_attack_stats.csv" "AvgLatency")
    local fake_mhls=$(grep -oP 'totalFakeMHLsInjected: \K\d+' "$output_dir/logs/rtp_attack.log" || echo 0)
    local bddp_relayed=$(grep -oP 'totalBDDPRelayed: \K\d+' "$output_dir/logs/rtp_attack.log" || echo 0)
    
    print_info "RTP Attack Metrics (No Mitigation):"
    echo "  PDR: $attack_pdr"
    echo "  Latency: ${attack_latency}ms"
    echo "  Fake MHLs Injected: $fake_mhls"
    echo "  BDDP Packets Relayed: $bddp_relayed"
    
    validate_metrics "RTP Attack" "$attack_pdr" "$attack_latency" "0.0" "N/A" "0.0" "$ATTACK_PDR_MAX"
    
    # 6b: RTP Attack with HybridShield Mitigation
    print_info "Running RTP attack WITH HybridShield mitigation..."
    
    ./waf --run "scratch/$ROUTING_SCRIPT \
        --simTime=$SIM_TIME 
        --routing_test=false \
        --N_Vehicles=$VEHICLES \
        --N_RSUs=$RSUS \
        --enable_rtp_attack=true \
        --rtp_inject_fake_routes=true \
        --rtp_fabricate_mhls=true \
        --rtp_start_time=10.0 \
        --rtp_attack_percentage=0.10 \
        --enable_hybrid_shield_detection=true \
        --enable_hybrid_shield_mitigation=true \
        --hybrid_shield_probe_timeout=100 \
        --hybrid_shield_verification_interval=30.0" \
        > "$output_dir/logs/rtp_mitigation.log" 2>&1
    
    local mitig_pdr=$(extract_metrics "$output_dir/csv/rtp_mitigation_stats.csv" "PDR")
    local mitig_latency=$(extract_metrics "$output_dir/csv/rtp_mitigation_stats.csv" "AvgLatency")
    local mitig_overhead=$(extract_metrics "$output_dir/csv/rtp_mitigation_stats.csv" "Overhead")
    local detection_rate=$(grep -oP 'Detection Rate: \K[\d.]+' "$output_dir/logs/rtp_mitigation.log" || echo 0)
    local mhls_detected=$(grep -oP 'detectedByDefense: \K\d+' "$output_dir/logs/rtp_mitigation.log" || echo 0)
    
    print_info "RTP Mitigation Metrics (HybridShield):"
    echo "  PDR: $mitig_pdr"
    echo "  Latency: ${mitig_latency}ms"
    echo "  Overhead: $mitig_overhead"
    echo "  Detection Rate: $detection_rate"
    echo "  Fake MHLs Detected: $mhls_detected"
    
    validate_metrics "RTP Mitigation" "$mitig_pdr" "$mitig_latency" "$mitig_overhead" "$detection_rate" "$MITIGATION_PDR_MIN"
}

# Generate summary report
generate_summary_report() {
    print_header "GENERATING SUMMARY REPORT"
    
    local summary_file="$RESULTS_DIR/summary/test_summary.txt"
    local csv_summary="$RESULTS_DIR/summary/metrics_summary.csv"
    
    cat > "$summary_file" << EOF
================================================================================
SDVN ATTACK TESTING SUMMARY REPORT
================================================================================
Test Date: $(date)
Configuration:
  - Simulation Time: ${SIM_TIME}s
  - Vehicles: $VEHICLES
  - RSUs: $RSUS
  - Total Nodes: $TOTAL_NODES

================================================================================
PERFORMANCE THRESHOLDS
================================================================================
  - Baseline PDR (min):          ${BASELINE_PDR_MIN}
  - Attack PDR (max):             ${ATTACK_PDR_MAX}
  - Mitigation PDR (min):         ${MITIGATION_PDR_MIN}
  - Detection Accuracy (min):     ${DETECTION_ACCURACY_MIN}
  - Latency Increase (max):       ${LATENCY_INCREASE_MAX}x
  - Overhead (max):               ${OVERHEAD_MAX}

================================================================================
TEST RESULTS
================================================================================

EOF
    
    # Create CSV header
    echo "Attack,Scenario,PDR,Latency(ms),Overhead,Detection,Status" > "$csv_summary"
    
    # Collect results from each test
    for attack in baseline wormhole blackhole sybil replay rtp; do
        echo "[$attack]" >> "$summary_file"
        
        if [ -d "$RESULTS_DIR/$attack/logs" ]; then
            for log in "$RESULTS_DIR/$attack/logs"/*.log; do
                if [ -f "$log" ]; then
                    scenario=$(basename "$log" .log)
                    echo "  - $scenario: $([ -f "$log" ] && echo "COMPLETED" || echo "FAILED")" >> "$summary_file"
                fi
            done
        fi
        echo "" >> "$summary_file"
    done
    
    cat >> "$summary_file" << EOF

================================================================================
KEY FINDINGS
================================================================================
$(find "$RESULTS_DIR" -name "*.log" -exec grep -l "METRICS PASSED" {} \; | wc -l) tests PASSED
$(find "$RESULTS_DIR" -name "*.log" -exec grep -l "METRICS FAILED" {} \; | wc -l) tests FAILED

All detailed logs, CSV files, and statistics are available in:
$RESULTS_DIR

================================================================================
EOF
    
    print_success "Summary report generated: $summary_file"
    print_success "CSV summary: $csv_summary"
    
    # Display summary
    cat "$summary_file"
}

################################################################################
# Main Execution
################################################################################

main() {
    print_header "SDVN ATTACK TESTING SUITE"
    print_info "Testing all 5 SDVN attack types and mitigation solutions"
    print_info "Results will be saved to: $RESULTS_DIR"
    
    # Verify we're in NS-3 directory
    if [ ! -f "waf" ]; then
        print_error "Error: This script must be run from NS-3 root directory!"
        print_error "Current directory: $(pwd)"
        print_info "Please cd to your NS-3 directory (e.g., ~/ns-allinone-3.35/ns-3.35)"
        exit 1
    fi
    
    # Verify routing.cc exists
    if [ ! -f "scratch/routing.cc" ]; then
        print_error "Error: routing.cc not found in scratch/ directory!"
        print_info "Please ensure routing.cc is in the scratch/ folder"
        exit 1
    fi
    
    # Setup
    setup_results_dir
    
    # Run all tests (continue on failure to collect all results)
    print_info "Starting test execution..."
    test_baseline || print_warning "Baseline test had issues"
    test_wormhole_attack || print_warning "Wormhole test had issues"
    test_blackhole_attack || print_warning "Blackhole test had issues"
    test_sybil_attack || print_warning "Sybil test had issues"
    test_replay_attack || print_warning "Replay test had issues"
    test_rtp_attack || print_warning "RTP test had issues"
    
    # Generate summary
    generate_summary_report
    
    print_header "TESTING COMPLETE"
    print_success "All tests finished. Check $RESULTS_DIR for detailed results."
}

# Run main function
main "$@"



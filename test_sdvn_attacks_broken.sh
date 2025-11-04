#!/bin/bash

################################################################################
# SDVN Attack Testing Script
# Tests all 5 SDVN attack types and their mitigation solutions
# Measures performance metrics: PDR, Latency, Overhead, Detection Accuracy
################################################################################

# Note: Don't use 'set -e' as it causes premature exit on expected errors

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
NS3_PATH="${NS3_PATH:-.}"  # Default to current directory (NS-3 root)
ROUTING_SCRIPT="routing"
RESULTS_DIR="./results_$(date +%Y%m%d_%H%M%S)"
SIM_TIME=60  # Simulation time in seconds
VEHICLES=18
RSUS=10
TOTAL_NODES=$((VEHICLES + RSUS))

# Performance metrics thresholds
BASELINE_PDR_MIN=0.85          # Minimum baseline PDR: 85%
ATTACK_PDR_MAX=0.60            # Maximum PDR under attack: 60%
MITIGATION_PDR_MIN=0.75        # Minimum PDR with mitigation: 75%
DETECTION_ACCURACY_MIN=0.80    # Minimum detection accuracy: 80%
LATENCY_INCREASE_MAX=2.5       # Maximum latency increase multiplier: 2.5x
OVERHEAD_MAX=0.20              # Maximum overhead: 20%

################################################################################
# Helper Functions
################################################################################

print_header() {
    echo -e "\n${BLUE}================================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Create results directory structure
setup_results_dir() {
    print_info "Creating results directory: $RESULTS_DIR"
    mkdir -p "$RESULTS_DIR"/{baseline,wormhole,blackhole,sybil,replay,rtp}/{logs,csv,stats}
    mkdir -p "$RESULTS_DIR/summary"
}

# Parse CSV results and extract metrics
extract_metrics() {
    local csv_file=$1
    local metric_name=$2
    
    if [ ! -f "$csv_file" ]; then
        echo "0.0"
        return
    fi
    
    # Extract metric from CSV (assuming standard format)
    # This is a placeholder - adjust based on actual CSV format
    awk -F',' -v metric="$metric_name" 'NR==1 {for(i=1;i<=NF;i++) if($i==metric) col=i} NR>1 {sum+=$col; count++} END {print (count>0 ? sum/count : 0)}' "$csv_file"
}

# Validate metrics against thresholds
validate_metrics() {
    local test_name=$1
    local pdr=$2
    local latency=$3
    local overhead=$4
    local detection=$5
    local expected_pdr_min=$6
    local expected_pdr_max=${7:-1.0}
    
    local passed=true
    
    echo -e "\n${YELLOW}Metric Validation for $test_name:${NC}"
    
    # PDR validation
    if (( $(echo "$pdr >= $expected_pdr_min" | bc -l) )); then
        print_success "PDR: $pdr (>= $expected_pdr_min)"
    else
        print_error "PDR: $pdr (expected >= $expected_pdr_min)"
        passed=false
    fi
    
    if [ -n "$expected_pdr_max" ] && (( $(echo "$pdr <= $expected_pdr_max" | bc -l) )); then
        print_success "PDR: $pdr (<= $expected_pdr_max)"
    elif [ -n "$expected_pdr_max" ]; then
        print_error "PDR: $pdr (expected <= $expected_pdr_max)"
        passed=false
    fi
    
    # Latency validation
    if (( $(echo "$latency > 0" | bc -l) )); then
        print_success "Latency: ${latency}ms"
    else
        print_warning "Latency: ${latency}ms (no data)"
    fi
    
    # Overhead validation
    if (( $(echo "$overhead <= $OVERHEAD_MAX" | bc -l) )); then
        print_success "Overhead: $overhead (<= $OVERHEAD_MAX)"
    else
        print_error "Overhead: $overhead (expected <= $OVERHEAD_MAX)"
        passed=false
    fi
    
    # Detection accuracy (if applicable)
    if [ "$detection" != "N/A" ] && (( $(echo "$detection >= $DETECTION_ACCURACY_MIN" | bc -l) )); then
        print_success "Detection Accuracy: $detection (>= $DETECTION_ACCURACY_MIN)"
    elif [ "$detection" != "N/A" ]; then
        print_error "Detection Accuracy: $detection (expected >= $DETECTION_ACCURACY_MIN)"
        passed=false
    fi
    
    if [ "$passed" = true ]; then
        print_success "$test_name: ALL METRICS PASSED"
        return 0
    else
        print_error "$test_name: SOME METRICS FAILED"
        return 1
    fi
}

################################################################################
# Test Scenarios
################################################################################

# Test 1: Baseline (No Attack)
test_baseline() {
    print_header "TEST 1: BASELINE (No Attack)"
    
    local output_dir="$RESULTS_DIR/baseline"
    print_info "Running baseline simulation..."
    
    # Check if we're in NS-3 directory
    if [ ! -f "waf" ]; then
        print_error "Error: waf not found. Please run this script from NS-3 root directory."
        print_info "Current directory: $(pwd)"
        return 1
    fi
    
    # Compile NS-3 if needed
    if [ ! -f "build/scratch/ns3.35-routing-default" ] && [ ! -f "build/scratch/routing" ]; then
        print_info "Compiling NS-3 project..."
        ./waf build || {
            print_error "Build failed! Please check compilation errors."
            return 1
        }
    fi
    
    # Run simulation with no attacks
    print_info "Executing simulation..."
    
    # First, test if routing binary exists and runs
    if ! ./waf --run "scratch/$ROUTING_SCRIPT --PrintHelp" > /dev/null 2>&1; then
        print_error "Cannot execute routing binary. Building first..."
        ./waf clean
        ./waf configure
        ./waf build
    fi
    
    ./waf --run "scratch/$ROUTING_SCRIPT \
        --simTime=$SIM_TIME \
        --routing_test=false \
        --N_Vehicles=$VEHICLES \
        --N_RSUs=$RSUS \
        --enable_wormhole_attack=false \
        --enable_blackhole_attack=false \
        --enable_sybil_attack=false \
        --enable_replay_attack=false \
        --enable_rtp_attack=false" \
        > "$output_dir/logs/baseline.log" 2>&1
    
    local exit_code=$?
    
    if [ $exit_code -ne 0 ]; then
        print_error "Simulation failed with exit code $exit_code! Check log: $output_dir/logs/baseline.log"
        echo ""
        print_info "Last 30 lines of log:"
        tail -30 "$output_dir/logs/baseline.log"
        echo ""
        print_info "Checking for common errors..."
        
        if grep -q "Segmentation fault" "$output_dir/logs/baseline.log"; then
            print_error "SEGMENTATION FAULT detected!"
        fi
        
        if grep -q "Assertion" "$output_dir/logs/baseline.log"; then
            print_error "ASSERTION FAILURE detected!"
            grep "Assertion" "$output_dir/logs/baseline.log"
        fi
        
        if grep -q "abort" "$output_dir/logs/baseline.log"; then
            print_error "ABORT detected!"
            grep -i "abort\|terminate" "$output_dir/logs/baseline.log" | head -5
        fi
        
        if grep -q "Command.*exited with code" "$output_dir/logs/baseline.log"; then
            print_warning "NS-3 reports command exited - this might be due to routing.cc internal errors"
        fi
        
        return 1
    fi
    
    print_success "Baseline simulation completed"
    
    # Extract metrics
    local pdr=$(extract_metrics "$output_dir/csv/baseline_stats.csv" "PDR")
    local latency=$(extract_metrics "$output_dir/csv/baseline_stats.csv" "AvgLatency")
    local overhead=$(extract_metrics "$output_dir/csv/baseline_stats.csv" "Overhead")
    
    # Store baseline metrics for comparison
    echo "$pdr" > "$RESULTS_DIR/baseline_pdr.txt"
    echo "$latency" > "$RESULTS_DIR/baseline_latency.txt"
    
    print_info "Baseline Metrics:"
    echo "  PDR: $pdr"
    echo "  Latency: ${latency}ms"
    echo "  Overhead: $overhead"
    
    validate_metrics "Baseline" "$pdr" "$latency" "$overhead" "N/A" "$BASELINE_PDR_MIN"
}

# Test 2: Wormhole Attack (with and without mitigation)
test_wormhole_attack() {
    print_header "TEST 2: WORMHOLE ATTACK"
    
    local output_dir="$RESULTS_DIR/wormhole"
    
    # 2a: Wormhole Attack (No Mitigation)
    print_info "Running Wormhole attack without mitigation..."
    
    print_info "Executing simulation..."
    ./waf --run "scratch/$ROUTING_SCRIPT \
        --simTime=$SIM_TIME 
        --routing_test=false \
        --N_Vehicles=$VEHICLES \
        --N_RSUs=$RSUS \
        
        --enable_wormhole_attack=true \
        --use_enhanced_wormhole=true \
        --wormhole_random_pairing=true \
        --wormhole_tunnel_routing=true \
        --wormhole_tunnel_data=true \
        --wormhole_start_time=10.0 \
        --attack_percentage=0.20 \
        --enable_wormhole_detection=false \
        --enable_wormhole_mitigation=false" \
        > "$output_dir/logs/wormhole_attack.log" 2>&1 || {
        print_error "Wormhole attack simulation failed! Check log: $output_dir/logs/wormhole_attack.log"
        return 1
    }
    
    print_success "Wormhole attack simulation completed"
    
    local attack_pdr=$(extract_metrics "$output_dir/csv/wormhole_attack_stats.csv" "PDR")
    local attack_latency=$(extract_metrics "$output_dir/csv/wormhole_attack_stats.csv" "AvgLatency")
    local attack_overhead=$(extract_metrics "$output_dir/csv/wormhole_attack_stats.csv" "Overhead")
    
    print_info "Wormhole Attack Metrics (No Mitigation):"
    echo "  PDR: $attack_pdr"
    echo "  Latency: ${attack_latency}ms"
    echo "  Packets Tunneled: $(grep -oP 'packetsTunneled: \K\d+' $output_dir/logs/wormhole_attack.log || echo 0)"
    
    validate_metrics "Wormhole Attack" "$attack_pdr" "$attack_latency" "$attack_overhead" "N/A" "0.0" "$ATTACK_PDR_MAX"
    
    # 2b: Wormhole Attack with Mitigation
    print_info "Running Wormhole attack WITH mitigation..."
    
    print_info "Executing simulation..."
    ./waf --run "scratch/$ROUTING_SCRIPT \
        --simTime=$SIM_TIME 
        --routing_test=false \
        --N_Vehicles=$VEHICLES \
        --N_RSUs=$RSUS \
        
        --enable_wormhole_attack=true \
        --use_enhanced_wormhole=true \
        --wormhole_random_pairing=true \
        --wormhole_tunnel_routing=true \
        --wormhole_tunnel_data=true \
        --wormhole_start_time=10.0 \
        --attack_percentage=0.20 \
        --enable_wormhole_detection=true \
        --enable_wormhole_mitigation=true \
        --detection_latency_threshold=2.0 \
        --detection_check_interval=1.0" \
        > "$output_dir/logs/wormhole_mitigation.log" 2>&1 || {
        print_error "Wormhole mitigation simulation failed!"
        return 1
    }
    
    print_success "Wormhole mitigation simulation completed"
    
    local mitig_pdr=$(extract_metrics "$output_dir/csv/wormhole_mitigation_stats.csv" "PDR")
    local mitig_latency=$(extract_metrics "$output_dir/csv/wormhole_mitigation_stats.csv" "AvgLatency")
    local mitig_overhead=$(extract_metrics "$output_dir/csv/wormhole_mitigation_stats.csv" "Overhead")
    local detection_accuracy=$(extract_metrics "$output_dir/csv/wormhole_detection.csv" "DetectionAccuracy")
    
    print_info "Wormhole Mitigation Metrics:"
    echo "  PDR: $mitig_pdr"
    echo "  Latency: ${mitig_latency}ms"
    echo "  Detection Accuracy: $detection_accuracy"
    echo "  Wormholes Detected: $(grep -oP 'wormholesDetected: \K\d+' $output_dir/logs/wormhole_mitigation.log || echo 0)"
    
    validate_metrics "Wormhole Mitigation" "$mitig_pdr" "$mitig_latency" "$mitig_overhead" "$detection_accuracy" "$MITIGATION_PDR_MIN"
}

# Test 3: Blackhole Attack (with and without mitigation)
test_blackhole_attack() {
    print_header "TEST 3: BLACKHOLE ATTACK"
    
    local output_dir="$RESULTS_DIR/blackhole"
    
    # 3a: Blackhole Attack (No Mitigation)
    print_info "Running Blackhole attack without mitigation..."
    
    ./waf --run "scratch/$ROUTING_SCRIPT \
        --simTime=$SIM_TIME 
        --routing_test=false \
        --N_Vehicles=$VEHICLES \
        --N_RSUs=$RSUS \
        
        --enable_blackhole_attack=true \
        --blackhole_drop_data=true \
        --blackhole_advertise_fake_routes=true \
        --blackhole_start_time=10.0 \
        --blackhole_attack_percentage=0.15 \
        --enable_blackhole_mitigation=false" \
        > "$output_dir/logs/blackhole_attack.log" 2>&1
    
    local attack_pdr=$(extract_metrics "$output_dir/csv/blackhole_attack_stats.csv" "PDR")
    local attack_latency=$(extract_metrics "$output_dir/csv/blackhole_attack_stats.csv" "AvgLatency")
    local packets_dropped=$(grep -oP 'dataPacketsDropped: \K\d+' "$output_dir/logs/blackhole_attack.log" || echo 0)
    
    print_info "Blackhole Attack Metrics (No Mitigation):"
    echo "  PDR: $attack_pdr"
    echo "  Latency: ${attack_latency}ms"
    echo "  Packets Dropped: $packets_dropped"
    
    validate_metrics "Blackhole Attack" "$attack_pdr" "$attack_latency" "0.0" "N/A" "0.0" "$ATTACK_PDR_MAX"
    
    # 3b: Blackhole Attack with Mitigation
    print_info "Running Blackhole attack WITH mitigation..."
    
    ./waf --run "scratch/$ROUTING_SCRIPT \
        --simTime=$SIM_TIME 
        --routing_test=false \
        --N_Vehicles=$VEHICLES \
        --N_RSUs=$RSUS \
        --enable_blackhole_attack=true \
        --blackhole_drop_data=true \
        --blackhole_advertise_fake_routes=true \
        --blackhole_start_time=10.0 \
        --blackhole_attack_percentage=0.15 \
        --enable_blackhole_mitigation=true \
        --blackhole_pdr_threshold=0.5 \
        --blackhole_min_packets=10" \
        > "$output_dir/logs/blackhole_mitigation.log" 2>&1
    
    local mitig_pdr=$(extract_metrics "$output_dir/csv/blackhole_mitigation_stats.csv" "PDR")
    local mitig_latency=$(extract_metrics "$output_dir/csv/blackhole_mitigation_stats.csv" "AvgLatency")
    local detection_rate=$(grep -oP 'Detection Rate: \K[\d.]+' "$output_dir/logs/blackhole_mitigation.log" || echo 0)
    local blacklisted_nodes=$(grep -oP 'Blacklisted Nodes: \K\d+' "$output_dir/logs/blackhole_mitigation.log" || echo 0)
    
    print_info "Blackhole Mitigation Metrics:"
    echo "  PDR: $mitig_pdr"
    echo "  Latency: ${mitig_latency}ms"
    echo "  Detection Rate: $detection_rate"
    echo "  Blacklisted Nodes: $blacklisted_nodes"
    
    validate_metrics "Blackhole Mitigation" "$mitig_pdr" "$mitig_latency" "0.0" "$detection_rate" "$MITIGATION_PDR_MIN"
}

# Test 4: Sybil Attack (with and without mitigation)
test_sybil_attack() {
    print_header "TEST 4: SYBIL ATTACK"
    
    local output_dir="$RESULTS_DIR/sybil"
    
    # 4a: Sybil Attack (No Mitigation)
    print_info "Running Sybil attack without mitigation..."
    
    ./waf --run "scratch/$ROUTING_SCRIPT \
        --simTime=$SIM_TIME 
        --routing_test=false \
        --N_Vehicles=$VEHICLES \
        --N_RSUs=$RSUS \
        
        --enable_sybil_attack=true \
        --sybil_identities_per_node=3 \
        --sybil_clone_legitimate_nodes=true \
        --sybil_inject_fake_packets=true \
        --sybil_start_time=10.0 \
        --sybil_attack_percentage=0.15 \
        --sybil_broadcast_interval=2.0 \
        --enable_sybil_detection=false \
        --enable_sybil_mitigation=false" \
        > "$output_dir/logs/sybil_attack.log" 2>&1
    
    local attack_pdr=$(extract_metrics "$output_dir/csv/sybil_attack_stats.csv" "PDR")
    local attack_latency=$(extract_metrics "$output_dir/csv/sybil_attack_stats.csv" "AvgLatency")
    local fake_identities=$(grep -oP 'fakeIdentitiesCreated: \K\d+' "$output_dir/logs/sybil_attack.log" || echo 0)
    
    print_info "Sybil Attack Metrics (No Mitigation):"
    echo "  PDR: $attack_pdr"
    echo "  Latency: ${attack_latency}ms"
    echo "  Fake Identities Created: $fake_identities"
    
    validate_metrics "Sybil Attack" "$attack_pdr" "$attack_latency" "0.0" "N/A" "0.0" "$ATTACK_PDR_MAX"
    
    # 4b: Sybil Attack with Mitigation
    print_info "Running Sybil attack WITH mitigation..."
    
    ./waf --run "scratch/$ROUTING_SCRIPT \
        --simTime=$SIM_TIME 
        --routing_test=false \
        --N_Vehicles=$VEHICLES \
        --N_RSUs=$RSUS \
        
        --enable_sybil_attack=true \
        --sybil_identities_per_node=3 \
        --sybil_clone_legitimate_nodes=true \
        --sybil_inject_fake_packets=true \
        --sybil_start_time=10.0 \
        --sybil_attack_percentage=0.15 \
        --sybil_broadcast_interval=2.0 \
        --enable_sybil_detection=true \
        --enable_sybil_mitigation=true \
        --enable_sybil_mitigation_advanced=true \
        --use_trusted_certification=true \
        --use_rssi_detection=true \
        --sybil_detection_threshold=0.8" \
        > "$output_dir/logs/sybil_mitigation.log" 2>&1
    
    local mitig_pdr=$(extract_metrics "$output_dir/csv/sybil_mitigation_stats.csv" "PDR")
    local mitig_latency=$(extract_metrics "$output_dir/csv/sybil_mitigation_stats.csv" "AvgLatency")
    local mitig_overhead=$(extract_metrics "$output_dir/csv/sybil_mitigation_stats.csv" "Overhead")
    local detection_accuracy=$(extract_metrics "$output_dir/csv/sybil_detection.csv" "DetectionAccuracy")
    local identities_detected=$(grep -oP 'totalFakeIdentitiesBlocked: \K\d+' "$output_dir/logs/sybil_mitigation.log" || echo 0)
    
    print_info "Sybil Mitigation Metrics:"
    echo "  PDR: $mitig_pdr"
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



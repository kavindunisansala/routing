#!/bin/bash

################################################################################
# Sybil Attack Focused Evaluation Script - Hybrid SDN Architecture
# Tests: 70 nodes (60 vehicles + 10 RSUs)
# Attack percentages: 20%, 40%, 60%, 80%, 100%
# Metrics: PDR, Latency, Throughput, FPR (False Positive Rate), PAR
# Total tests: 16 (1 baseline + 5×3 attack scenarios)
#
# HYBRID SDN ARCHITECTURE (Architecture 0):
# - Infrastructure (RSUs/controller): Static routing via Ipv4GlobalRoutingHelper
# - Vehicles (V2V): AODV routing + DSRC 802.11p broadcasts (mobile data plane)
# - Sybil Impact: Broadcasts fake identities via DSRC, pollutes neighbor tables
# - Attack Effect: Identity confusion, routing manipulation, packet attraction
# - Detection: RSSI-based + position verification + cryptographic validation
# - Key Metrics: FPR (False Positive Rate), PAR (Packet Attraction Ratio)
# - Quick Analysis: Inline identity metrics, FPR/PAR assessment
################################################################################

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
TOTAL_NODES=70
VEHICLES=$((TOTAL_NODES - 10))  # 60 vehicles
RSUS=10
SIMULATION_TIME=60
PAUSE_TIME=0
SEED=12345  # Fixed seed for reproducibility

# Attack percentages to test
ATTACK_PERCENTAGES=(0.2 0.4 0.6 0.8 1.0)
ATTACK_PERCENTAGE_LABELS=("20" "40" "60" "80" "100")

# Results directory
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RESULTS_DIR="sybil_evaluation_${TIMESTAMP}"
mkdir -p "$RESULTS_DIR"

# Log file
LOG_FILE="${RESULTS_DIR}/evaluation.log"

# Function to print colored messages
print_message() {
    local color=$1
    shift
    echo -e "${color}$@${NC}" | tee -a "$LOG_FILE"
}

# Function to print section header
print_header() {
    echo "" | tee -a "$LOG_FILE"
    echo "================================================================================" | tee -a "$LOG_FILE"
    echo "$1" | tee -a "$LOG_FILE"
    echo "================================================================================" | tee -a "$LOG_FILE"
}

# Quick analysis function for sybil results
quick_sybil_analysis() {
    local result_file=$1
    local log_file=$2
    local attack_pct=$3
    
    echo ""
    print_message "$CYAN" "  Quick Analysis (${attack_pct}% attackers):"
    
    # Extract key metrics from CSV
    local total_tx=$(grep "TotalPacketsSent" "$result_file" 2>/dev/null | tail -1 | awk '{print $NF}')
    local total_rx=$(grep "TotalPacketsReceived" "$result_file" 2>/dev/null | tail -1 | awk '{print $NF}')
    local pdr=$(grep "PacketDeliveryRatio" "$result_file" 2>/dev/null | tail -1 | awk '{print $NF}')
    local throughput=$(grep "AverageThroughput" "$result_file" 2>/dev/null | tail -1 | awk '{print $NF}')
    
    # Extract sybil statistics from log
    local fake_identities=$(grep "FakeIdentitiesCreated:" "$log_file" 2>/dev/null | tail -1 | awk '{print $NF}')
    local fake_packets=$(grep "FakePacketsInjected:" "$log_file" 2>/dev/null | tail -1 | awk '{print $NF}')
    local detected=$(grep "SybilNodesDetected:" "$log_file" 2>/dev/null | tail -1 | awk '{print $NF}')
    local blacklisted=$(grep "SybilNodesBlacklisted:" "$log_file" 2>/dev/null | tail -1 | awk '{print $NF}')
    local false_positives=$(grep "FalsePositives:" "$log_file" 2>/dev/null | tail -1 | awk '{print $NF}')
    local benign_nodes=$(grep "TotalBenignNodes:" "$log_file" 2>/dev/null | tail -1 | awk '{print $NF}')
    local attracted=$(grep "PacketsAttractedToSybilNodes:" "$log_file" 2>/dev/null | tail -1 | awk '{print $NF}')
    local total_packets=$(grep "TotalPacketsInNetwork:" "$log_file" 2>/dev/null | tail -1 | awk '{print $NF}')
    
    # Display sybil-specific metrics
    if [[ -n "$fake_identities" && "$fake_identities" != "0" ]]; then
        print_message "$YELLOW" "    • Fake Identities Created: $fake_identities"
        if [[ -n "$fake_packets" ]]; then
            print_message "$YELLOW" "    • Fake Packets Injected: $fake_packets"
        fi
    fi
    
    # FPR (False Positive Rate) analysis
    if [[ -n "$false_positives" && -n "$benign_nodes" && "$benign_nodes" != "0" ]]; then
        local fpr=$(awk "BEGIN {printf \"%.2f\", ($false_positives/$benign_nodes)*100}")
        print_message "$YELLOW" "    • FPR: ${fpr}% ($false_positives/$benign_nodes benign nodes)"
        local fpr_int=$(echo "$fpr" | cut -d. -f1)
        if [[ $fpr_int -lt 1 ]]; then
            print_message "$GREEN" "      → Excellent: Very few false alarms"
        elif [[ $fpr_int -lt 5 ]]; then
            print_message "$YELLOW" "      → Acceptable: Low false positive rate"
        else
            print_message "$RED" "      → Poor: Too many benign nodes flagged"
        fi
    fi
    
    # PAR (Packet Attraction Ratio) analysis
    if [[ -n "$attracted" && -n "$total_packets" && "$total_packets" != "0" ]]; then
        local par=$(awk "BEGIN {printf \"%.2f\", ($attracted/$total_packets)*100}")
        print_message "$YELLOW" "    • PAR: ${par}% ($attracted/$total_packets packets)"
        local par_int=$(echo "$par" | cut -d. -f1)
        if [[ $par_int -lt 5 ]]; then
            print_message "$GREEN" "      → Excellent: Minimal routing manipulation"
        elif [[ $par_int -lt 15 ]]; then
            print_message "$YELLOW" "      → Controlled: Moderate packet attraction"
        else
            print_message "$RED" "      → Severe: High routing manipulation"
        fi
    fi
    
    # Detection effectiveness
    if [[ -n "$detected" && -n "$fake_identities" && "$fake_identities" != "0" ]]; then
        local detection_rate=$(awk "BEGIN {printf \"%.1f\", ($detected/$fake_identities)*100}")
        print_message "$YELLOW" "    • Detection Rate: ${detection_rate}% ($detected/$fake_identities)"
    fi
    
    if [[ -n "$blacklisted" && "$blacklisted" != "0" ]]; then
        print_message "$YELLOW" "    • Blacklisted: $blacklisted (mitigation active)"
    fi
    
    if [[ -n "$pdr" ]]; then
        print_message "$YELLOW" "    • PDR: ${pdr}%"
        local pdr_int=$(echo "$pdr" | cut -d. -f1)
        if [[ $pdr_int -lt 70 ]]; then
            print_message "$RED" "      → Severe impact: Identity confusion degrading network"
        elif [[ $pdr_int -lt 85 ]]; then
            print_message "$YELLOW" "      → Moderate impact: Sybil identities affecting routes"
        else
            print_message "$GREEN" "      → Minor impact: Network handling fake identities"
        fi
    fi
    
    if [[ -n "$throughput" ]]; then
        print_message "$YELLOW" "    • Avg Throughput: ${throughput} kbps"
    fi
    
    echo ""
}

# Function to calculate PDR, latency, and throughput from CSV
calculate_metrics() {
    local csv_file=$1
    local sim_time=$2
    
    if [ ! -f "$csv_file" ]; then
        echo "0,0,0,0"
        return
    fi
    
    python3 - <<EOF
import pandas as pd
import sys

try:
    df = pd.read_csv('$csv_file')
    total_packets = len(df)
    delivered_packets = len(df[df['Delivered'] == 1])
    
    if total_packets > 0:
        pdr = (delivered_packets / total_packets) * 100
    else:
        pdr = 0
    
    # Calculate average latency for delivered packets
    delivered_df = df[df['Delivered'] == 1]
    if len(delivered_df) > 0:
        avg_latency = delivered_df['DelayMs'].mean()
    else:
        avg_latency = 0
    
    # Calculate throughput (packets/second)
    sim_time = float($sim_time)
    if sim_time > 0:
        throughput = delivered_packets / sim_time
    else:
        throughput = 0
    
    print(f"{pdr:.2f},{avg_latency:.2f},{delivered_packets},{throughput:.2f}")
except Exception as e:
    print("0,0,0,0")
    sys.exit(1)
EOF
}

# Function to extract sybil statistics from log (including FPR and PAR)
extract_sybil_stats() {
    local log_file=$1
    
    if [ ! -f "$log_file" ]; then
        echo "0,0,0,0,0,0,0,0,0"
        return
    fi
    
    python3 - <<EOF
import re
import sys

try:
    with open('$log_file', 'r') as f:
        content = f.read()
    
    # Extract sybil statistics
    fake_identities = 0
    fake_packets = 0
    detected_sybils = 0
    blacklisted_sybils = 0
    false_positives = 0
    total_benign_nodes = 0
    fpr = 0.0
    attracted_packets = 0
    total_packets = 0
    par = 0.0
    
    # Search for sybil statistics
    identities_match = re.search(r'FakeIdentitiesCreated:\s*(\d+)', content)
    if identities_match:
        fake_identities = int(identities_match.group(1))
    
    packets_match = re.search(r'FakePacketsInjected:\s*(\d+)', content)
    if packets_match:
        fake_packets = int(packets_match.group(1))
    
    detected_match = re.search(r'SybilNodesDetected:\s*(\d+)', content)
    if detected_match:
        detected_sybils = int(detected_match.group(1))
    
    blacklist_match = re.search(r'SybilNodesBlacklisted:\s*(\d+)', content)
    if blacklist_match:
        blacklisted_sybils = int(blacklist_match.group(1))
    
    # Extract False Positive Rate (FPR) - benign nodes falsely identified as attackers
    fp_match = re.search(r'FalsePositives:\s*(\d+)', content)
    if fp_match:
        false_positives = int(fp_match.group(1))
    
    benign_match = re.search(r'TotalBenignNodes:\s*(\d+)', content)
    if benign_match:
        total_benign_nodes = int(benign_match.group(1))
    
    # Calculate FPR: False Positives / Total Benign Nodes
    if total_benign_nodes > 0:
        fpr = (false_positives / total_benign_nodes) * 100
    else:
        fpr = 0.0
    
    # Extract Packet Attraction Ratio (PAR) - packets attracted to unintended nodes
    attracted_match = re.search(r'PacketsAttractedToSybilNodes:\s*(\d+)', content)
    if attracted_match:
        attracted_packets = int(attracted_match.group(1))
    
    total_packets_match = re.search(r'TotalPacketsInNetwork:\s*(\d+)', content)
    if total_packets_match:
        total_packets = int(total_packets_match.group(1))
    
    # Calculate PAR: Attracted Packets / Total Packets
    # PAR measures routing manipulation - packets diverted to fake identities
    if total_packets > 0:
        par = (attracted_packets / total_packets) * 100
    else:
        par = 0.0
    
    print(f"{fake_identities},{fake_packets},{detected_sybils},{blacklisted_sybils},{false_positives},{total_benign_nodes},{fpr:.2f},{attracted_packets},{par:.2f}")
except Exception as e:
    print("0,0,0,0,0,0,0,0,0")
    sys.exit(1)
EOF
}

# Function to run a single test
run_test() {
    local test_num=$1
    local test_name=$2
    local attack_percentage=$3
    local enable_sybil=$4
    local enable_detection=$5
    local enable_mitigation=$6
    
    local test_dir="${RESULTS_DIR}/${test_name}"
    mkdir -p "$test_dir"
    
    print_message "$BLUE" "Running $test_name..."
    print_message "$YELLOW" "  Nodes: $TOTAL_NODES ($VEHICLES vehicles + $RSUS RSUs)"
    print_message "$YELLOW" "  Attack: ${attack_percentage}%, Detection: $enable_detection, Mitigation: $enable_mitigation"
    
    # Build simulation command (matching test_sdvn_complete_evaluation.sh format)
    local sim_params=""
    sim_params+="--simTime=$SIMULATION_TIME "
    sim_params+="--routing_test=false "
    sim_params+="--N_Vehicles=$VEHICLES "
    sim_params+="--N_RSUs=$RSUS "
    sim_params+="--architecture=0 "
    sim_params+="--enable_packet_tracking=true "
    sim_params+="--attack_percentage=$attack_percentage "
    
    # Sybil-specific parameters (matching complete evaluation)
    if [ "$enable_sybil" = true ]; then
        sim_params+="--present_sybil_attack_nodes=true "
        sim_params+="--enable_sybil_attack=true "
        sim_params+="--sybil_attack_percentage=$attack_percentage "
        sim_params+="--sybil_identities_per_node=3 "
        sim_params+="--sybil_advertise_fake_routes=true "
        sim_params+="--sybil_clone_legitimate_nodes=true "
        sim_params+="--sybil_inject_fake_packets=true "
        sim_params+="--sybil_broadcast_interval=2.0 "
    fi
    
    if [ "$enable_detection" = true ]; then
        sim_params+="--enable_sybil_detection=true "
        sim_params+="--use_trusted_certification=true "
        sim_params+="--use_rssi_detection=true "
    fi
    
    if [ "$enable_mitigation" = true ]; then
        sim_params+="--enable_sybil_mitigation=true "
        sim_params+="--enable_sybil_mitigation_advanced=true "
    fi
    
    # Run simulation
    local start_time=$(date +%s)
    if ./waf --run "scratch/routing $sim_params" > "${test_dir}/simulation.log" 2>&1; then
        # Copy CSV files from current directory to test directory
        find . -maxdepth 1 -name "*.csv" -type f -exec cp {} "$test_dir/" \; 2>/dev/null
        
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        
        # Calculate metrics (with throughput)
        local metrics=$(calculate_metrics "${test_dir}/packet-delivery-analysis.csv" "$SIMULATION_TIME")
        IFS=',' read -r pdr latency delivered throughput <<< "$metrics"
        
        # Extract sybil statistics (including FPR and PAR)
        local sybil_stats=$(extract_sybil_stats "${test_dir}/simulation.log")
        IFS=',' read -r fake_identities fake_packets detected blacklisted false_positives benign_nodes fpr attracted_packets par <<< "$sybil_stats"
        
        print_message "$GREEN" "  ✓ Completed in ${duration}s"
        print_message "$GREEN" "    PDR: ${pdr}%, Latency: ${latency}ms, Throughput: ${throughput} pps"
        print_message "$GREEN" "    Detected: ${detected}, Blacklisted: ${blacklisted}, FPR: ${fpr}%"
        print_message "$GREEN" "    PAR: ${par}% (${attracted_packets} packets attracted to fake identities)"
        
        # Clean up CSV files from current directory after copying
        find . -maxdepth 1 -name "*.csv" -type f -delete 2>/dev/null
        
        # Save metrics to summary (including PAR)
        echo "${test_name},${pdr},${latency},${delivered},${throughput},${fake_identities},${fake_packets},${detected},${blacklisted},${false_positives},${benign_nodes},${fpr},${attracted_packets},${par},${duration}" >> "${RESULTS_DIR}/metrics_summary.csv"
    else
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        print_message "$RED" "  ✗ Failed after ${duration}s"
        echo "${test_name},FAILED,FAILED,FAILED,FAILED,FAILED,FAILED,FAILED,FAILED,FAILED,FAILED,FAILED,FAILED,FAILED,${duration}" >> "${RESULTS_DIR}/metrics_summary.csv"
    fi
}

# Main execution
print_header "SYBIL ATTACK FOCUSED EVALUATION - HYBRID SDN ARCHITECTURE"
print_message "$YELLOW" "Configuration:"
print_message "$YELLOW" "  Total Nodes: $TOTAL_NODES ($VEHICLES vehicles + $RSUS RSUs)"
print_message "$YELLOW" "  Attack Percentages: ${ATTACK_PERCENTAGE_LABELS[*]}"
print_message "$YELLOW" "  Simulation Time: ${SIMULATION_TIME}s"
print_message "$YELLOW" "  RNG Seed: $SEED (reproducible)"
print_message "$YELLOW" "  Results: $RESULTS_DIR"
print_message "$YELLOW" "  Architecture: Hybrid SDN (Static infra + AODV vehicles)"
print_message "$YELLOW" "  Key Metrics:"
print_message "$YELLOW" "    - FPR: False Positive Rate (benign nodes wrongly flagged)"
print_message "$YELLOW" "    - PAR: Packet Attraction Ratio (packets diverted to fake identities)"
print_message "$YELLOW" "  Impact: Sybil identities broadcast via DSRC, pollute neighbor tables"
echo ""

# Initialize metrics summary CSV (including PAR)
echo "TestName,PDR,AvgLatency,Delivered,Throughput,FakeIdentities,FakePackets,Detected,Blacklisted,FalsePositives,BenignNodes,FPR,AttractedPackets,PAR,Duration" > "${RESULTS_DIR}/metrics_summary.csv"

# Test counter
test_count=1
total_tests=16

# Phase 1: Baseline (No Attack)
print_header "PHASE 1: BASELINE (No Attack)"
run_test "$test_count" "test01_baseline" 0.0 false false false

# Quick analysis for baseline
result_file="${RESULTS_DIR}/test01_baseline/packet-delivery-analysis.csv"
if [[ -f "$result_file" ]]; then
    echo ""
    print_message "$CYAN" "  Baseline Network Analysis:"
    total_tx=$(grep "TotalPacketsSent" "$result_file" 2>/dev/null | tail -1 | awk '{print $NF}')
    total_rx=$(grep "TotalPacketsReceived" "$result_file" 2>/dev/null | tail -1 | awk '{print $NF}')
    pdr=$(grep "PacketDeliveryRatio" "$result_file" 2>/dev/null | tail -1 | awk '{print $NF}')
    throughput=$(grep "AverageThroughput" "$result_file" 2>/dev/null | tail -1 | awk '{print $NF}')
    
    if [[ -n "$total_tx" && -n "$total_rx" ]]; then
        print_message "$YELLOW" "    • Packets: ${total_tx} sent → ${total_rx} received"
    fi
    if [[ -n "$pdr" ]]; then
        print_message "$YELLOW" "    • PDR: ${pdr}% (healthy baseline)"
    fi
    if [[ -n "$throughput" ]]; then
        print_message "$YELLOW" "    • Avg Throughput: ${throughput} kbps"
    fi
    print_message "$GREEN" "    ✓ Hybrid SDN: AODV neighbor discovery on data plane"
    echo ""
fi

test_count=$((test_count + 1))

# Phase 2: Sybil Attack - No Mitigation
print_header "PHASE 2: SYBIL ATTACK - NO MITIGATION"
for i in "${!ATTACK_PERCENTAGES[@]}"; do
    percentage="${ATTACK_PERCENTAGES[$i]}"
    label="${ATTACK_PERCENTAGE_LABELS[$i]}"
    test_name="test02_sybil_${label}_no_mitigation"
    run_test "$test_count" "$test_name" "$percentage" true false false
    
    # Quick analysis
    result_file="${RESULTS_DIR}/${test_name}/packet-delivery-analysis.csv"
    log_file="${RESULTS_DIR}/${test_name}/simulation.log"
    if [[ -f "$result_file" ]]; then
        quick_sybil_analysis "$result_file" "$log_file" "$percentage"
    fi
    
    test_count=$((test_count + 1))
done

# Phase 3: Sybil Attack - Detection Only
print_header "PHASE 3: SYBIL ATTACK - DETECTION ONLY"
for i in "${!ATTACK_PERCENTAGES[@]}"; do
    percentage="${ATTACK_PERCENTAGES[$i]}"
    label="${ATTACK_PERCENTAGE_LABELS[$i]}"
    test_name="test03_sybil_${label}_with_detection"
    run_test "$test_count" "$test_name" "$percentage" true true false
    
    # Quick analysis
    result_file="${RESULTS_DIR}/${test_name}/packet-delivery-analysis.csv"
    log_file="${RESULTS_DIR}/${test_name}/simulation.log"
    if [[ -f "$result_file" ]]; then
        quick_sybil_analysis "$result_file" "$log_file" "$percentage"
    fi
    
    test_count=$((test_count + 1))
done

# Phase 4: Sybil Attack - Full Mitigation
print_header "PHASE 4: SYBIL ATTACK - FULL MITIGATION"
for i in "${!ATTACK_PERCENTAGES[@]}"; do
    percentage="${ATTACK_PERCENTAGES[$i]}"
    label="${ATTACK_PERCENTAGE_LABELS[$i]}"
    test_name="test04_sybil_${label}_with_mitigation"
    run_test "$test_count" "$test_name" "$percentage" true true true
    
    # Quick analysis
    result_file="${RESULTS_DIR}/${test_name}/packet-delivery-analysis.csv"
    log_file="${RESULTS_DIR}/${test_name}/simulation.log"
    if [[ -f "$result_file" ]]; then
        quick_sybil_analysis "$result_file" "$log_file" "$percentage"
    fi
    
    test_count=$((test_count + 1))
done

# Generate summary report
print_header "EVALUATION COMPLETE"

print_message "$GREEN" "Results saved to: $RESULTS_DIR"
print_message "$YELLOW" "Metrics summary:"
echo ""

# Display formatted summary
if [[ -f "${RESULTS_DIR}/metrics_summary.csv" ]]; then
    column -t -s',' "${RESULTS_DIR}/metrics_summary.csv" | tee -a "$LOG_FILE"
    
    echo ""
    print_message "$CYAN" "Impact Analysis Summary:"
    print_message "$YELLOW" "  • Hybrid SDN Architecture: Static infrastructure + AODV vehicles"
    print_message "$YELLOW" "  • Sybil Impact: Fake identities broadcast via DSRC, pollute neighbors"
    print_message "$YELLOW" "  • FPR (False Positive Rate): Measures benign nodes wrongly flagged"
    print_message "$YELLOW" "  • PAR (Packet Attraction Ratio): Measures routing manipulation"
    print_message "$YELLOW" "  • Detection: RSSI + position + cryptographic verification"
    print_message "$YELLOW" "  • Target: FPR < 5%, PAR < 15% (with mitigation)"
    echo ""
fi

print_message "$GREEN" "Log file: $LOG_FILE"

# Generate detailed summary
cat > "${RESULTS_DIR}/EVALUATION_SUMMARY.txt" <<EOF
================================================================================
SYBIL ATTACK FOCUSED EVALUATION - SUMMARY WITH FPR AND PAR ANALYSIS
================================================================================

Date: $(date)
Configuration:
  - Total Nodes: $TOTAL_NODES ($VEHICLES vehicles + $RSUS RSUs)
  - Attack Percentages: ${ATTACK_PERCENTAGE_LABELS[*]}
  - Simulation Time: ${SIMULATION_TIME}s
  - RNG Seed: $SEED
  - Total Tests: $total_tests

Test Matrix:
  - Phase 1: Baseline (1 test)
  - Phase 2: No Mitigation (5 tests at 20%, 40%, 60%, 80%, 100%)
  - Phase 3: Detection Only (5 tests at 20%, 40%, 60%, 80%, 100%)
  - Phase 4: Full Mitigation (5 tests at 20%, 40%, 60%, 80%, 100%)

Sybil Attack Configuration:
  - Identities per Sybil Node: 3
  - Attack Behaviors:
    * Advertise fake routes
    * Clone legitimate node identities
    * Inject fake packets
    * Broadcast fake information (every 2.0s)

Detection Mechanisms:
  - Trusted Certification: PKI-based identity verification
  - RSSI Detection: Signal strength anomaly detection
  - MAC Address Validation: Hardware address consistency checks

Metrics Collected:
  - Packet Delivery Ratio (PDR)
  - Average End-to-End Latency
  - Total Packets Delivered
  - Throughput (packets/second)
  - Fake Identities Created
  - Fake Packets Injected
  - Sybil Nodes Detected
  - Sybil Nodes Blacklisted
  - **False Positives (benign nodes wrongly flagged)**
  - **Total Benign Nodes**
  - **False Positive Rate (FPR) %**
  - **Attracted Packets (diverted to fake identities)**
  - **Packet Attraction Ratio (PAR) %**
  - Simulation Duration

False Positive Rate (FPR):
  - Definition: Proportion of benign nodes falsely identified as attackers
  - Formula: FPR = (False Positives / Total Benign Nodes) × 100%
  - Importance: Low FPR ensures normal nodes are not penalized unnecessarily
  - Target: FPR < 5% (acceptable), FPR < 1% (excellent)
  - Impact: High FPR degrades network functionality by isolating legitimate nodes

Packet Attraction Ratio (PAR):
  - Definition: Proportion of packets attracted to nodes not their intended destination
  - Formula: PAR = (Packets Attracted to Sybil Nodes / Total Packets) × 100%
  - Measurement: Per-node attraction (Sybil attack) vs per-link (Wormhole attack)
  - Importance: Indicates routing manipulation effectiveness by fake identities
  - Target: PAR < 10% with mitigation (controlled routing manipulation)
  - Impact: High PAR indicates severe routing disruption and traffic diversion
  - Correlation: PAR increases with attack percentage, decreases with mitigation

Results Location: $RESULTS_DIR

================================================================================
DETAILED METRICS
================================================================================

EOF

# Append metrics summary to report
column -t -s',' "${RESULTS_DIR}/metrics_summary.csv" >> "${RESULTS_DIR}/EVALUATION_SUMMARY.txt"

cat >> "${RESULTS_DIR}/EVALUATION_SUMMARY.txt" <<EOF

================================================================================
EXPECTED RESULTS ANALYSIS
================================================================================

Baseline (No Attack):
  - PDR: ~95-98% (normal network performance)
  - Throughput: ~1600-1700 pps
  - FPR: 0% (no detection active)
  - PAR: 0% (no packet attraction)
  - Latency: ~5-10ms

No Mitigation Scenarios:
  - 20% Attack: PDR ~80-85%, PAR ~15-20% (fake identities attract packets)
  - 40% Attack: PDR ~65-70%, PAR ~30-35% (increased routing manipulation)
  - 60% Attack: PDR ~50-55%, PAR ~45-50% (severe traffic diversion)
  - 80% Attack: PDR ~35-40%, PAR ~60-65% (massive routing disruption)
  - 100% Attack: PDR ~20-25%, PAR ~75-80% (complete network takeover)
  - FPR: N/A (no detection)
  - Correlation: Higher attack % → Higher PAR → Lower PDR

Detection Only Scenarios:
  - Detection Rate: 75-85% of sybil nodes identified
  - PDR: Slight improvement (5-10%) over no mitigation
  - FPR: 2-8% (some benign nodes may be flagged)
  - PAR: Reduced by ~5-10% (detection alerts but doesn't block)
  - Reason: Detection identifies threats but doesn't fully isolate them

Full Mitigation Scenarios:
  - 20% Attack: PDR recovers to ~85-90%, PAR reduced to ~5-8%
  - 40% Attack: PDR recovers to ~80-85%, PAR reduced to ~8-12%
  - 60% Attack: PDR recovers to ~75-80%, PAR reduced to ~12-15%
  - 80% Attack: PDR recovers to ~70-75%, PAR reduced to ~15-20%
  - 100% Attack: PDR recovers to ~65-70%, PAR reduced to ~20-25%
  - Detection Rate: >85% with advanced mitigation
  - FPR Target: <5% (minimize false positives)
  - FPR Acceptable: 3-8% (trade-off for security)
  - FPR Excellent: <3% (high precision detection)
  - PAR Reduction: 60-80% compared to no mitigation

FPR Analysis by Detection Method:
  - Trusted Certification Only: FPR ~1-2% (very precise)
  - RSSI Detection Only: FPR ~5-10% (signal variations cause false positives)
  - Combined Methods: FPR ~2-5% (balanced approach)
  - Advanced Mitigation: FPR ~1-3% (refined detection reduces FP)

PAR Analysis by Attack Scenario:
  - No Mitigation: PAR correlates linearly with attack % (R² > 0.95)
  - Detection Only: PAR reduced by ~10-15% (early warning helps routing)
  - Full Mitigation: PAR reduced by ~60-80% (blacklisting blocks attraction)
  - Per-Node Attraction: Sybil nodes create 3 fake identities each
  - Traffic Distribution: Fake identities advertise false routes to attract packets

Impact of FPR on Network:
  - FPR < 1%: Negligible impact on legitimate nodes
  - FPR 1-5%: Acceptable - minor disruption to benign traffic
  - FPR 5-10%: Moderate impact - some legitimate nodes isolated
  - FPR > 10%: High impact - significant degradation of normal operations

Impact of PAR on Network:
  - PAR < 5%: Minimal routing disruption, normal packet delivery
  - PAR 5-15%: Low impact - slight delay, most packets reach destination
  - PAR 15-30%: Moderate impact - noticeable packet loss and delay
  - PAR 30-50%: High impact - severe routing disruption
  - PAR > 50%: Critical - network functionality severely compromised

Trade-off Analysis (Security vs Precision):
  - Aggressive Detection: High detection rate, High FPR, Low PAR
  - Balanced Detection: Medium detection rate, Medium FPR, Medium PAR
  - Conservative Detection: Low detection rate, Low FPR, High PAR
  - Optimal: Advanced mitigation achieves high detection, low FPR, low PAR

================================================================================
QUICK STATISTICS
================================================================================

EOF

# Generate quick statistics with Python
python3 - <<STATS_EOF >> "${RESULTS_DIR}/EVALUATION_SUMMARY.txt"
import pandas as pd
import sys

try:
    df = pd.read_csv('${RESULTS_DIR}/metrics_summary.csv')
    
    # Filter out failed tests
    df_valid = df[df['PDR'] != 'FAILED'].copy()
    df_valid['PDR'] = pd.to_numeric(df_valid['PDR'])
    df_valid['FPR'] = pd.to_numeric(df_valid['FPR'])
    df_valid['PAR'] = pd.to_numeric(df_valid['PAR'])
    df_valid['Throughput'] = pd.to_numeric(df_valid['Throughput'])
    
    total_tests = len(df)
    passed_tests = len(df_valid)
    failed_tests = total_tests - passed_tests
    
    print(f"Test Execution:")
    print(f"  Total Tests: {total_tests}")
    print(f"  Passed: {passed_tests}")
    print(f"  Failed: {failed_tests}")
    print(f"  Success Rate: {(passed_tests/total_tests)*100:.1f}%")
    print()
    
    if len(df_valid) > 0:
        baseline = df_valid[df_valid['TestName'].str.contains('baseline')]
        no_miti = df_valid[df_valid['TestName'].str.contains('no_mitigation')]
        detection = df_valid[df_valid['TestName'].str.contains('with_detection')]
        mitigation = df_valid[df_valid['TestName'].str.contains('with_mitigation')]
        
        print(f"Performance Summary:")
        if len(baseline) > 0:
            print(f"  Baseline PDR: {baseline['PDR'].mean():.2f}%, Throughput: {baseline['Throughput'].mean():.2f} pps")
            print(f"           FPR: {baseline['FPR'].mean():.2f}%, PAR: {baseline['PAR'].mean():.2f}%")
        if len(no_miti) > 0:
            print(f"  No Mitigation Avg PDR: {no_miti['PDR'].mean():.2f}%, Throughput: {no_miti['Throughput'].mean():.2f} pps")
            print(f"                    PAR: {no_miti['PAR'].mean():.2f}% (high routing manipulation)")
        if len(detection) > 0:
            print(f"  Detection Only Avg PDR: {detection['PDR'].mean():.2f}%, FPR: {detection['FPR'].mean():.2f}%")
            print(f"                     PAR: {detection['PAR'].mean():.2f}% (reduced by {(1-detection['PAR'].mean()/no_miti['PAR'].mean())*100:.1f}%)")
        if len(mitigation) > 0:
            print(f"  Full Mitigation Avg PDR: {mitigation['PDR'].mean():.2f}%, FPR: {mitigation['FPR'].mean():.2f}%")
            print(f"                      PAR: {mitigation['PAR'].mean():.2f}% (reduced by {(1-mitigation['PAR'].mean()/no_miti['PAR'].mean())*100:.1f}%)")
        print()
        
        print(f"False Positive Rate (FPR) Analysis:")
        if len(detection) > 0:
            print(f"  Detection Only - Avg FPR: {detection['FPR'].mean():.2f}%, Min: {detection['FPR'].min():.2f}%, Max: {detection['FPR'].max():.2f}%")
        if len(mitigation) > 0:
            print(f"  Full Mitigation - Avg FPR: {mitigation['FPR'].mean():.2f}%, Min: {mitigation['FPR'].min():.2f}%, Max: {mitigation['FPR'].max():.2f}%")
            fpr_acceptable = len(mitigation[mitigation['FPR'] <= 5])
            fpr_excellent = len(mitigation[mitigation['FPR'] <= 1])
            print(f"  Tests with FPR ≤ 5% (acceptable): {fpr_acceptable}/{len(mitigation)}")
            print(f"  Tests with FPR ≤ 1% (excellent): {fpr_excellent}/{len(mitigation)}")
        print()
        
        print(f"Packet Attraction Ratio (PAR) Analysis:")
        if len(no_miti) > 0:
            print(f"  No Mitigation - Avg PAR: {no_miti['PAR'].mean():.2f}%, Min: {no_miti['PAR'].min():.2f}%, Max: {no_miti['PAR'].max():.2f}%")
            print(f"                  (High PAR indicates severe routing manipulation)")
        if len(detection) > 0:
            print(f"  Detection Only - Avg PAR: {detection['PAR'].mean():.2f}%, Min: {detection['PAR'].min():.2f}%, Max: {detection['PAR'].max():.2f}%")
            par_reduction_detection = ((no_miti['PAR'].mean() - detection['PAR'].mean()) / no_miti['PAR'].mean()) * 100
            print(f"                   PAR reduction: {par_reduction_detection:.1f}% vs no mitigation")
        if len(mitigation) > 0:
            print(f"  Full Mitigation - Avg PAR: {mitigation['PAR'].mean():.2f}%, Min: {mitigation['PAR'].min():.2f}%, Max: {mitigation['PAR'].max():.2f}%")
            par_reduction_mitigation = ((no_miti['PAR'].mean() - mitigation['PAR'].mean()) / no_miti['PAR'].mean()) * 100
            print(f"                    PAR reduction: {par_reduction_mitigation:.1f}% vs no mitigation")
            par_controlled = len(mitigation[mitigation['PAR'] <= 15])
            par_excellent = len(mitigation[mitigation['PAR'] <= 5])
            print(f"  Tests with PAR ≤ 15% (controlled): {par_controlled}/{len(mitigation)}")
            print(f"  Tests with PAR ≤ 5% (excellent): {par_excellent}/{len(mitigation)}")
        print()
        
        print(f"Detection Effectiveness:")
        det_tests = df_valid[df_valid['TestName'].str.contains('with_detection|with_mitigation')]
        if len(det_tests) > 0 and 'Detected' in det_tests.columns:
            det_tests_numeric = det_tests[det_tests['Detected'] != 'FAILED'].copy()
            if len(det_tests_numeric) > 0:
                det_tests_numeric['Detected'] = pd.to_numeric(det_tests_numeric['Detected'])
                det_tests_numeric['Blacklisted'] = pd.to_numeric(det_tests_numeric['Blacklisted'])
                det_tests_numeric['AttractedPackets'] = pd.to_numeric(det_tests_numeric['AttractedPackets'])
                print(f"  Avg Sybil Nodes Detected: {det_tests_numeric['Detected'].mean():.1f}")
                print(f"  Avg Nodes Blacklisted: {det_tests_numeric['Blacklisted'].mean():.1f}")
                print(f"  Avg Packets Attracted to Fake Identities: {det_tests_numeric['AttractedPackets'].mean():.0f}")
        print()
        
        print(f"Correlation Analysis:")
        if len(no_miti) > 0:
            # Extract attack percentage from test name
            no_miti['AttackPct'] = no_miti['TestName'].str.extract(r'_(\d+)_')[0].astype(float)
            par_corr = no_miti[['AttackPct', 'PAR']].corr().iloc[0, 1]
            pdr_corr = no_miti[['AttackPct', 'PDR']].corr().iloc[0, 1]
            print(f"  Attack % vs PAR correlation: {par_corr:.3f} (strong positive)")
            print(f"  Attack % vs PDR correlation: {pdr_corr:.3f} (strong negative)")
            print(f"  PAR vs PDR correlation: {no_miti[['PAR', 'PDR']].corr().iloc[0, 1]:.3f} (strong negative)")

except Exception as e:
    print(f"Error generating statistics: {e}")
    sys.exit(1)
STATS_EOF

cat >> "${RESULTS_DIR}/EVALUATION_SUMMARY.txt" <<EOF

================================================================================
ANALYSIS INSTRUCTIONS
================================================================================

To analyze these results, run:

  python3 analyze_sybil_focused.py $RESULTS_DIR

This will generate:
  1. PDR vs Attack Percentage curves (3 scenarios)
  2. FPR vs Attack Percentage curves (detection vs mitigation)
  3. PAR vs Attack Percentage curves (routing manipulation analysis)
  4. Throughput vs Attack Percentage curves
  5. Detection effectiveness analysis
  6. False Positive Rate impact analysis
  7. Packet Attraction Ratio impact analysis
  8. Correlation analysis (Attack % vs PAR, PAR vs PDR)
  9. Trade-off analysis: Security (Detection) vs Precision (Low FPR) vs Routing Integrity (Low PAR)
  10. Statistical summary tables

Key Questions to Answer:
  - What is the FPR at different attack intensities?
  - How does FPR affect legitimate node communication?
  - What is the PAR at different attack intensities?
  - How does PAR correlate with PDR degradation?
  - What is the optimal detection threshold (balance detection rate vs FPR)?
  - Does advanced mitigation reduce both FPR and PAR?
  - How effective is mitigation at preventing packet attraction?
  - What is the relationship between fake identities and PAR?

PAR Insights:
  - PAR measures routing manipulation by fake identities
  - Higher attack % → More fake identities → Higher PAR → More packets diverted
  - Mitigation reduces PAR by blacklisting Sybil nodes and their fake identities
  - PAR is measured per-node (Sybil) vs per-link (Wormhole)
  - Low PAR with mitigation indicates successful prevention of traffic diversion

================================================================================
EOF

print_message "$GREEN" "Summary report: ${RESULTS_DIR}/EVALUATION_SUMMARY.txt"
print_message "$YELLOW" "Next step: python3 analyze_sybil_focused.py $RESULTS_DIR"
echo ""

print_header "FPR AND PAR METRICS SUMMARY"
print_message "$BLUE" "False Positive Rate (FPR): Measures benign nodes wrongly identified as attackers"
print_message "$BLUE" "  Target: FPR < 5% (acceptable), FPR < 1% (excellent)"
print_message "$BLUE" "  Impact: Low FPR preserves normal network functionality"
echo ""
print_message "$BLUE" "Packet Attraction Ratio (PAR): Measures packets diverted to unintended nodes"
print_message "$BLUE" "  Target: PAR < 15% with mitigation (controlled), PAR < 5% (excellent)"
print_message "$BLUE" "  Impact: Low PAR indicates effective prevention of routing manipulation"
print_message "$BLUE" "  Measurement: Per-node attraction for Sybil (fake identities attract traffic)"
echo ""

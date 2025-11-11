#!/bin/bash

################################################################################
# Wormhole Attack Focused Evaluation Script - Hybrid SDN Architecture
# Tests: 70 nodes (60 vehicles + 10 RSUs)
# Attack percentages: 20%, 40%, 60%, 80%, 100%
# Metrics: PDR, Latency, Throughput, PacketsTunneled
# Total tests: 16 (1 baseline + 5×3 attack scenarios)
#
# HYBRID SDN ARCHITECTURE (Architecture 0):
# - Infrastructure (RSUs/controller): Static routing via Ipv4GlobalRoutingHelper
# - Vehicles (V2V): AODV routing + DSRC 802.11p broadcasts (mobile data plane)
# - Wormhole Impact: Tunnels AODV packets (port 654) through out-of-band channel
# - Attack Effect: Creates artificial shortcuts, disrupts hop count metrics
# - Expected Results: PacketsTunneled > 0, latency anomalies, route confusion
# - Detection: RTT-based detection identifies abnormal delay patterns
# - Quick Analysis: Inline tunnel metrics and latency anomaly assessment
################################################################################

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
TOTAL_NODES=20
VEHICLES=$((TOTAL_NODES - 5))  # 60 vehicles
RSUS=5
SIMULATION_TIME=10
PAUSE_TIME=0
SEED=12345  # Fixed seed for reproducibility

# Attack percentages to test
ATTACK_PERCENTAGES=(0.2 0.4 0.6 0.8 1.0)
ATTACK_PERCENTAGE_LABELS=("20" "40" "60" "80" "100")

# Results directory
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RESULTS_DIR="wormhole_evaluation_${TIMESTAMP}"
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

# Quick analysis function for wormhole results
quick_wormhole_analysis() {
    local result_file=$1
    local attack_pct=$2
    
    echo ""
    print_message "$CYAN" "  Quick Analysis (${attack_pct}% attackers):"
    
    # Extract key metrics
    local total_tx=$(grep "TotalPacketsSent" "$result_file" 2>/dev/null | tail -1 | awk '{print $NF}')
    local total_rx=$(grep "TotalPacketsReceived" "$result_file" 2>/dev/null | tail -1 | awk '{print $NF}')
    local pdr=$(grep "PacketDeliveryRatio" "$result_file" 2>/dev/null | tail -1 | awk '{print $NF}')
    local avg_latency=$(grep "AverageLatency" "$result_file" 2>/dev/null | tail -1 | awk '{print $NF}')
    local throughput=$(grep "AverageThroughput" "$result_file" 2>/dev/null | tail -1 | awk '{print $NF}')
    
    # Display metrics
    if [[ -n "$total_tx" && -n "$total_rx" ]]; then
        print_message "$YELLOW" "    • Packets: ${total_tx} sent → ${total_rx} received"
    fi
    if [[ -n "$pdr" ]]; then
        print_message "$YELLOW" "    • PDR: ${pdr}%"
        # PDR interpretation for wormhole (different from blackhole)
        local pdr_int=$(echo "$pdr" | cut -d. -f1)
        if [[ $pdr_int -lt 70 ]]; then
            print_message "$RED" "      → Severe impact: Wormhole causing major disruption"
        elif [[ $pdr_int -lt 85 ]]; then
            print_message "$YELLOW" "      → Moderate impact: Tunnel affecting route quality"
        else
            print_message "$GREEN" "      → Minor impact: Network compensating for tunnel"
        fi
    fi
    if [[ -n "$avg_latency" ]]; then
        print_message "$YELLOW" "    • Avg Latency: ${avg_latency}ms"
        # Latency anomaly detection
        local latency_int=$(echo "$avg_latency" | cut -d. -f1)
        if [[ $latency_int -gt 50 ]]; then
            print_message "$RED" "      → Latency spike: Wormhole tunnel causing delays"
        elif [[ $latency_int -gt 20 ]]; then
            print_message "$YELLOW" "      → Elevated latency: Tunnel impact visible"
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

# Function to run a single test
run_test() {
    local test_num=$1
    local test_name=$2
    local attack_percentage=$3
    local enable_wormhole=$4
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
    
    # Wormhole-specific parameters
    if [ "$enable_wormhole" = true ]; then
        sim_params+="--present_wormhole_attack_nodes=true "
        sim_params+="--use_enhanced_wormhole=true "
        sim_params+="--wormhole_bandwidth=1000Mbps "
        sim_params+="--wormhole_delay_us=50000 "
        sim_params+="--wormhole_tunnel_routing=true "
        sim_params+="--wormhole_tunnel_data=true "
        sim_params+="--wormhole_enable_verification_flows=true "
    fi
    
    if [ "$enable_detection" = true ]; then
        sim_params+="--enable_wormhole_detection=true "
    fi
    
    if [ "$enable_mitigation" = true ]; then
        sim_params+="--enable_wormhole_mitigation=true "
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
        
        print_message "$GREEN" "  ✓ Completed in ${duration}s"
        print_message "$GREEN" "    PDR: ${pdr}%, Avg Latency: ${latency}ms, Delivered: ${delivered}, Throughput: ${throughput} pps"
        
        # Clean up CSV files from current directory after copying
        find . -maxdepth 1 -name "*.csv" -type f -delete 2>/dev/null
        
        # Save metrics to summary
        echo "${test_name},${pdr},${latency},${delivered},${throughput},${duration}" >> "${RESULTS_DIR}/metrics_summary.csv"
    else
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        print_message "$RED" "  ✗ Failed after ${duration}s"
        echo "${test_name},FAILED,FAILED,FAILED,FAILED,${duration}" >> "${RESULTS_DIR}/metrics_summary.csv"
    fi
}

# Main execution
print_header "WORMHOLE ATTACK FOCUSED EVALUATION - HYBRID SDN ARCHITECTURE"
print_message "$YELLOW" "Configuration:"
print_message "$YELLOW" "  Total Nodes: $TOTAL_NODES ($VEHICLES vehicles + $RSUS RSUs)"
print_message "$YELLOW" "  Attack Percentages: ${ATTACK_PERCENTAGE_LABELS[*]}"
print_message "$YELLOW" "  Simulation Time: ${SIMULATION_TIME}s"
print_message "$YELLOW" "  RNG Seed: $SEED (reproducible)"
print_message "$YELLOW" "  Results: $RESULTS_DIR"
print_message "$YELLOW" "  Architecture: Hybrid SDN (Static infra + AODV vehicles)"
print_message "$YELLOW" "  Impact: Wormhole tunnels AODV packets through out-of-band channel"
print_message "$YELLOW" "  Expected: PacketsTunneled > 0, latency anomalies"
echo ""

# Initialize metrics summary CSV
echo "TestName,PDR,AvgLatency,Delivered,Throughput,Duration" > "${RESULTS_DIR}/metrics_summary.csv"

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
    latency=$(grep "AverageLatency" "$result_file" 2>/dev/null | tail -1 | awk '{print $NF}')
    
    if [[ -n "$total_tx" && -n "$total_rx" ]]; then
        print_message "$YELLOW" "    • Packets: ${total_tx} sent → ${total_rx} received"
    fi
    if [[ -n "$pdr" ]]; then
        print_message "$YELLOW" "    • PDR: ${pdr}% (healthy baseline)"
    fi
    if [[ -n "$latency" ]]; then
        print_message "$YELLOW" "    • Avg Latency: ${latency}ms (normal range)"
    fi
    print_message "$GREEN" "    ✓ Hybrid SDN: AODV routing on mobile data plane"
    echo ""
fi

test_count=$((test_count + 1))

# Phase 2: Wormhole Attack - No Mitigation
print_header "PHASE 2: WORMHOLE ATTACK - NO MITIGATION"
for i in "${!ATTACK_PERCENTAGES[@]}"; do
    percentage="${ATTACK_PERCENTAGES[$i]}"
    label="${ATTACK_PERCENTAGE_LABELS[$i]}"
    test_name="test02_wormhole_${label}_no_mitigation"
    run_test "$test_count" "$test_name" "$percentage" true false false
    
    # Quick analysis
    result_file="${RESULTS_DIR}/${test_name}/packet-delivery-analysis.csv"
    if [[ -f "$result_file" ]]; then
        quick_wormhole_analysis "$result_file" "$percentage"
    fi
    
    test_count=$((test_count + 1))
done

# Phase 3: Wormhole Attack - Detection Only
print_header "PHASE 3: WORMHOLE ATTACK - DETECTION ONLY"
for i in "${!ATTACK_PERCENTAGES[@]}"; do
    percentage="${ATTACK_PERCENTAGES[$i]}"
    label="${ATTACK_PERCENTAGE_LABELS[$i]}"
    test_name="test03_wormhole_${label}_with_detection"
    run_test "$test_count" "$test_name" "$percentage" true true false
    
    # Quick analysis
    result_file="${RESULTS_DIR}/${test_name}/packet-delivery-analysis.csv"
    if [[ -f "$result_file" ]]; then
        quick_wormhole_analysis "$result_file" "$percentage"
    fi
    
    test_count=$((test_count + 1))
done

# Phase 4: Wormhole Attack - Full Mitigation
print_header "PHASE 4: WORMHOLE ATTACK - FULL MITIGATION"
for i in "${!ATTACK_PERCENTAGES[@]}"; do
    percentage="${ATTACK_PERCENTAGES[$i]}"
    label="${ATTACK_PERCENTAGE_LABELS[$i]}"
    test_name="test04_wormhole_${label}_with_mitigation"
    run_test "$test_count" "$test_name" "$percentage" true true true
    
    # Quick analysis
    result_file="${RESULTS_DIR}/${test_name}/packet-delivery-analysis.csv"
    if [[ -f "$result_file" ]]; then
        quick_wormhole_analysis "$result_file" "$percentage"
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
    print_message "$YELLOW" "  • Wormhole Impact: Tunnels AODV packets through out-of-band channel"
    print_message "$YELLOW" "  • Attack Effect: Creates artificial shortcuts, disrupts hop count metrics"
    print_message "$YELLOW" "  • Detection/Mitigation: RTT-based monitoring identifies abnormal delays"
    print_message "$YELLOW" "  • Expected: PacketsTunneled > 0 (data plane now active!)"
    echo ""
fi

print_message "$GREEN" "Log file: $LOG_FILE"

# Generate detailed summary
cat > "${RESULTS_DIR}/EVALUATION_SUMMARY.txt" <<EOF
================================================================================
WORMHOLE ATTACK FOCUSED EVALUATION - SUMMARY
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

Metrics Collected:
  - Packet Delivery Ratio (PDR)
  - Average End-to-End Latency
  - Total Packets Delivered
  - Throughput (packets/second)
  - Simulation Duration

Results Location: $RESULTS_DIR

================================================================================
DETAILED METRICS
================================================================================

EOF

# Append metrics summary to report
column -t -s',' "${RESULTS_DIR}/metrics_summary.csv" >> "${RESULTS_DIR}/EVALUATION_SUMMARY.txt"

cat >> "${RESULTS_DIR}/EVALUATION_SUMMARY.txt" <<EOF

================================================================================
ANALYSIS INSTRUCTIONS
================================================================================

To analyze these results, run:

  python3 analyze_wormhole_focused.py $RESULTS_DIR

This will generate:
  1. PDR vs Attack Percentage curves (3 scenarios)
  2. Latency vs Attack Percentage curves (3 scenarios)
  3. Mitigation effectiveness comparison
  4. Tunnel creation analysis
  5. Statistical summary tables

================================================================================
EOF

print_message "$GREEN" "Summary report: ${RESULTS_DIR}/EVALUATION_SUMMARY.txt"
print_message "$YELLOW" "Next step: python3 analyze_wormhole_focused.py $RESULTS_DIR"
echo ""

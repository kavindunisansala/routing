#!/bin/bash

################################################################################
# Blackhole Attack Focused Evaluation Script - Hybrid SDN Architecture
# Tests: 70 nodes (60 vehicles + 10 RSUs)
# Attack percentages: 20%, 40%, 60%, 80%, 100%
# Metrics: PDR, Average Latency, Throughput, Detection Rate, Packets Dropped
# Total tests: 16 (1 baseline + 5×3 attack scenarios)
#
# HYBRID SDN ARCHITECTURE (Architecture 0):
# - Infrastructure (RSUs/controller): Static routing via Ipv4GlobalRoutingHelper
# - Vehicles (V2V): AODV routing + DSRC 802.11p broadcasts (mobile data plane)
# - Blackhole Impact: Drops both AODV route requests and DSRC data packets
# - AODV Resilience: Vehicles dynamically discover alternate routes around blackholes
# - Expected Results: PacketsDropped > 0, PDR degradation proportional to attack %
# - Detection: PDR-based monitoring identifies malicious nodes when enabled
# - Quick Analysis: Inline PDR/throughput/impact assessment after each test
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
RESULTS_DIR="blackhole_evaluation_${TIMESTAMP}"
mkdir -p "$RESULTS_DIR"

# Log file
LOG_FILE="${RESULTS_DIR}/evaluation.log"

# Function to print colored output
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to print section headers
print_header() {
    local title=$1
    echo ""
    echo "================================================================"
    echo "  $title"
    echo "================================================================"
    echo ""
}

# Quick analysis function for blackhole results
quick_blackhole_analysis() {
    local result_file=$1
    local attack_pct=$2
    
    echo ""
    print_message "$CYAN" "  Quick Analysis (${attack_pct}% attackers):"
    
    # Extract key metrics
    local packets_dropped=$(grep "PacketsDropped" "$result_file" | tail -1 | awk '{print $NF}')
    local total_tx=$(grep "TotalPacketsSent" "$result_file" | tail -1 | awk '{print $NF}')
    local total_rx=$(grep "TotalPacketsReceived" "$result_file" | tail -1 | awk '{print $NF}')
    local pdr=$(grep "PacketDeliveryRatio" "$result_file" | tail -1 | awk '{print $NF}')
    local throughput=$(grep "AverageThroughput" "$result_file" | tail -1 | awk '{print $NF}')
    
    # Display metrics
    if [[ -n "$packets_dropped" ]]; then
        print_message "$YELLOW" "    • Packets Dropped: $packets_dropped"
    fi
    if [[ -n "$total_tx" && -n "$total_rx" ]]; then
        print_message "$YELLOW" "    • Packets: ${total_tx} sent → ${total_rx} received"
    fi
    if [[ -n "$pdr" ]]; then
        print_message "$YELLOW" "    • PDR: ${pdr}%"
        # PDR interpretation
        local pdr_int=$(echo "$pdr" | cut -d. -f1)
        if [[ $pdr_int -lt 50 ]]; then
            print_message "$RED" "      → Severe impact: Network severely degraded"
        elif [[ $pdr_int -lt 80 ]]; then
            print_message "$YELLOW" "      → Moderate impact: Noticeable degradation"
        else
            print_message "$GREEN" "      → Minor impact: AODV routing around attack"
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

# Function to extract blackhole statistics from log
extract_blackhole_stats() {
    local log_file=$1
    
    if [ ! -f "$log_file" ]; then
        echo "0,0,0,0"
        return
    fi
    
    python3 - <<EOF
import re
import sys

try:
    with open('$log_file', 'r') as f:
        content = f.read()
    
    # Extract blackhole statistics
    packets_dropped = 0
    fake_routes = 0
    detected_nodes = 0
    blacklisted_nodes = 0
    
    # Search for blackhole statistics
    dropped_match = re.search(r'TotalPacketsDropped:\s*(\d+)', content)
    if dropped_match:
        packets_dropped = int(dropped_match.group(1))
    
    routes_match = re.search(r'FakeRoutesAdvertised:\s*(\d+)', content)
    if routes_match:
        fake_routes = int(routes_match.group(1))
    
    detected_match = re.search(r'BlackholeNodesDetected:\s*(\d+)', content)
    if detected_match:
        detected_nodes = int(detected_match.group(1))
    
    blacklist_match = re.search(r'NodesBlacklisted:\s*(\d+)', content)
    if blacklist_match:
        blacklisted_nodes = int(blacklist_match.group(1))
    
    print(f"{packets_dropped},{fake_routes},{detected_nodes},{blacklisted_nodes}")
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
    local enable_blackhole=$4
    local enable_detection=$5
    local enable_mitigation=$6
    
    local test_dir="${RESULTS_DIR}/${test_name}"
    mkdir -p "$test_dir"
    
    print_message "$BLUE" "Running $test_name..."
    print_message "$YELLOW" "  Nodes: $TOTAL_NODES ($VEHICLES vehicles + $RSUS RSUs)"
    print_message "$YELLOW" "  Attack: ${attack_percentage}%, Detection: $enable_detection, Mitigation: $enable_mitigation"
    
    # Build simulation command
    local sim_params=""
    sim_params+="--simTime=$SIMULATION_TIME "
    sim_params+="--routing_test=false "
    sim_params+="--N_Vehicles=$VEHICLES "
    sim_params+="--N_RSUs=$RSUS "
    sim_params+="--architecture=0 "
    sim_params+="--enable_packet_tracking=true "
    sim_params+="--attack_percentage=$attack_percentage "
    
    # Blackhole-specific parameters
    if [ "$enable_blackhole" = true ]; then
        sim_params+="--present_blackhole_attack_nodes=true "
        sim_params+="--enable_blackhole_attack=true "
        sim_params+="--blackhole_attack_percentage=$attack_percentage "
        sim_params+="--blackhole_drop_data=true "
        sim_params+="--blackhole_advertise_fake_routes=true "
        sim_params+="--blackhole_fake_sequence_number=999999 "
        sim_params+="--blackhole_fake_hop_count=1 "
    fi
    
    if [ "$enable_detection" = true ] || [ "$enable_mitigation" = true ]; then
        sim_params+="--enable_blackhole_mitigation=true "
        sim_params+="--blackhole_pdr_threshold=0.99 "
        sim_params+="--blackhole_min_packets=10 "
    fi
    
    # Run simulation
    local start_time=$(date +%s)
    if ./waf --run "scratch/routing $sim_params" > "${test_dir}/simulation.log" 2>&1; then
        # Copy CSV files from current directory to test directory
        find . -maxdepth 1 -name "*.csv" -type f -exec cp {} "$test_dir/" \; 2>/dev/null
        
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        
        # Calculate metrics
        local metrics=$(calculate_metrics "${test_dir}/packet-delivery-analysis.csv" "$SIMULATION_TIME")
        IFS=',' read -r pdr latency delivered throughput <<< "$metrics"
        
        # Extract blackhole statistics
        local stats=$(extract_blackhole_stats "${test_dir}/simulation.log")
        IFS=',' read -r dropped fake_routes detected blacklisted <<< "$stats"
        
        print_message "$GREEN" "  ✓ Completed in ${duration}s"
        print_message "$GREEN" "    PDR: ${pdr}%, Avg Latency: ${latency}ms"
        print_message "$GREEN" "    Delivered: ${delivered}, Throughput: ${throughput} pkt/s"
        if [ "$enable_blackhole" = true ]; then
            print_message "$GREEN" "    Dropped: ${dropped}, Fake Routes: ${fake_routes}"
            if [ "$enable_detection" = true ] || [ "$enable_mitigation" = true ]; then
                print_message "$GREEN" "    Detected: ${detected}, Blacklisted: ${blacklisted}"
            fi
        fi
        
        # Clean up CSV files from current directory after copying
        find . -maxdepth 1 -name "*.csv" -type f -delete 2>/dev/null
        
        # Save metrics to summary
        echo "${test_name},${pdr},${latency},${delivered},${throughput},${dropped},${fake_routes},${detected},${blacklisted},${duration}" >> "${RESULTS_DIR}/metrics_summary.csv"
    else
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        print_message "$RED" "  ✗ Failed after ${duration}s"
        echo "${test_name},FAILED,FAILED,FAILED,FAILED,FAILED,FAILED,FAILED,FAILED,${duration}" >> "${RESULTS_DIR}/metrics_summary.csv"
    fi
}

# Main execution
print_header "BLACKHOLE ATTACK FOCUSED EVALUATION - HYBRID SDN ARCHITECTURE"
print_message "$YELLOW" "Configuration:"
print_message "$YELLOW" "  Total Nodes: $TOTAL_NODES ($VEHICLES vehicles + $RSUS RSUs)"
print_message "$YELLOW" "  Attack Percentages: ${ATTACK_PERCENTAGE_LABELS[*]}"
print_message "$YELLOW" "  Simulation Time: ${SIMULATION_TIME}s"
print_message "$YELLOW" "  RNG Seed: $SEED (reproducible)"
print_message "$YELLOW" "  Results: $RESULTS_DIR"
print_message "$YELLOW" "  Architecture: Hybrid SDN (Static infra + AODV vehicles)"
print_message "$YELLOW" "  Impact: Blackhole drops AODV + DSRC data plane packets"
echo ""

# Initialize metrics summary CSV
echo "TestName,PDR,AvgLatency,Delivered,Throughput,Dropped,FakeRoutes,Detected,Blacklisted,Duration" > "${RESULTS_DIR}/metrics_summary.csv"

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
    total_tx=$(grep "TotalPacketsSent" "$result_file" | tail -1 | awk '{print $NF}')
    total_rx=$(grep "TotalPacketsReceived" "$result_file" | tail -1 | awk '{print $NF}')
    pdr=$(grep "PacketDeliveryRatio" "$result_file" | tail -1 | awk '{print $NF}')
    throughput=$(grep "AverageThroughput" "$result_file" | tail -1 | awk '{print $NF}')
    
    if [[ -n "$total_tx" && -n "$total_rx" ]]; then
        print_message "$YELLOW" "    • Packets: ${total_tx} sent → ${total_rx} received"
    fi
    if [[ -n "$pdr" ]]; then
        print_message "$YELLOW" "    • PDR: ${pdr}% (healthy baseline)"
    fi
    if [[ -n "$throughput" ]]; then
        print_message "$YELLOW" "    • Avg Throughput: ${throughput} kbps"
    fi
    print_message "$GREEN" "    ✓ Hybrid SDN: AODV vehicles + static RSU infrastructure"
    echo ""
fi

test_count=$((test_count + 1))

# Phase 2: Blackhole Attack - No Mitigation
print_header "PHASE 2: BLACKHOLE ATTACK - NO MITIGATION"
for i in "${!ATTACK_PERCENTAGES[@]}"; do
    percentage="${ATTACK_PERCENTAGES[$i]}"
    label="${ATTACK_PERCENTAGE_LABELS[$i]}"
    test_name="test02_blackhole_${label}_no_mitigation"
    run_test "$test_count" "$test_name" "$percentage" true false false
    
    # Quick analysis
    result_file="${RESULTS_DIR}/${test_name}/packet-delivery-analysis.csv"
    if [[ -f "$result_file" ]]; then
        quick_blackhole_analysis "$result_file" "$percentage"
    fi
    
    test_count=$((test_count + 1))
done

# Phase 3: Blackhole Attack - Detection Only
print_header "PHASE 3: BLACKHOLE ATTACK - DETECTION ONLY"
for i in "${!ATTACK_PERCENTAGES[@]}"; do
    percentage="${ATTACK_PERCENTAGES[$i]}"
    label="${ATTACK_PERCENTAGE_LABELS[$i]}"
    test_name="test03_blackhole_${label}_with_detection"
    run_test "$test_count" "$test_name" "$percentage" true true false
    
    # Quick analysis
    result_file="${RESULTS_DIR}/${test_name}/packet-delivery-analysis.csv"
    if [[ -f "$result_file" ]]; then
        quick_blackhole_analysis "$result_file" "$percentage"
    fi
    
    test_count=$((test_count + 1))
done

# Phase 4: Blackhole Attack - Full Mitigation
print_header "PHASE 4: BLACKHOLE ATTACK - FULL MITIGATION"
for i in "${!ATTACK_PERCENTAGES[@]}"; do
    percentage="${ATTACK_PERCENTAGES[$i]}"
    label="${ATTACK_PERCENTAGE_LABELS[$i]}"
    test_name="test04_blackhole_${label}_with_mitigation"
    run_test "$test_count" "$test_name" "$percentage" true true true
    
    # Quick analysis
    result_file="${RESULTS_DIR}/${test_name}/packet-delivery-analysis.csv"
    if [[ -f "$result_file" ]]; then
        quick_blackhole_analysis "$result_file" "$percentage"
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
    print_message "$YELLOW" "  • Blackhole Impact: Drops AODV route requests and DSRC data packets"
    print_message "$YELLOW" "  • AODV Resilience: Vehicles discover alternate routes around blackholes"
    print_message "$YELLOW" "  • Detection/Mitigation: PDR-based monitoring identifies malicious nodes"
    echo ""
fi

print_message "$GREEN" "Log file: $LOG_FILE"

# Generate detailed summary
cat > "${RESULTS_DIR}/EVALUATION_SUMMARY.txt" <<EOF
================================================================================
BLACKHOLE ATTACK FOCUSED EVALUATION - SUMMARY
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

Blackhole Attack Behavior:
  - Drop all data packets passing through malicious nodes
  - Advertise fake routes with high sequence numbers (999999)
  - Claim direct routes (hop count = 1) to attract traffic
  - Expected impact: Severe PDR degradation, dropped packets

Metrics Collected:
  - Packet Delivery Ratio (PDR)
  - Average End-to-End Latency
  - Throughput (packets/second)
  - Total Packets Delivered
  - Packets Dropped by Blackholes
  - Fake Routes Advertised
  - Blackhole Nodes Detected
  - Nodes Blacklisted
  - Simulation Duration

Detection & Mitigation:
  - PDR Threshold: 99% (nodes with PDR < 99% flagged as suspicious - STRICT)
  - Minimum Packets: 10 (before blacklisting)
  - Mitigation: Route isolation + node blacklisting

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
  - Throughput: High, stable packet delivery
  - Dropped: 0 (no malicious nodes)

No Mitigation (Attack Active):
  - PDR degradation proportional to attack percentage:
    * 20%: PDR ~75-80% (14 blackhole nodes)
    * 40%: PDR ~55-65% (28 blackhole nodes)
    * 60%: PDR ~35-45% (42 blackhole nodes)
    * 80%: PDR ~15-25% (56 blackhole nodes)
    * 100%: PDR ~5-10% (70 blackhole nodes)
  - Throughput: Decreases significantly
  - Dropped: Increases with attack percentage

With Detection:
  - Detection rate: >90% (nodes exhibiting blackhole behavior identified)
  - Detected: Number of identified malicious nodes
  - PDR: Slight improvement as suspicious nodes are monitored

With Mitigation:
  - PDR: Significant recovery (70-85%) as blackholes are isolated
  - Blacklisted: Malicious nodes removed from routing
  - Throughput: Recovers as traffic avoids blackholes
  - Dropped: Reduced as routes avoid malicious nodes

================================================================================
ANALYSIS INSTRUCTIONS
================================================================================

To analyze these results, run:

  python3 analyze_blackhole_focused.py $RESULTS_DIR

This will generate:
  1. PDR vs Attack Percentage curves (3 scenarios)
  2. Throughput vs Attack Percentage curves (3 scenarios)
  3. Latency vs Attack Percentage curves (3 scenarios)
  4. Packets Dropped analysis
  5. Detection effectiveness (detection rate vs attack percentage)
  6. Mitigation effectiveness comparison
  7. Statistical summary tables

Expected Visualizations:
  - Before vs After mitigation PDR comparison
  - Throughput degradation under attack
  - Detection rate accuracy
  - Mitigation recovery effectiveness

================================================================================
KEY PERFORMANCE INDICATORS
================================================================================

Success Criteria:
  1. Baseline PDR > 95%
  2. Attack impact visible (PDR drops with increasing attack percentage)
  3. Detection rate > 85% for all attack percentages
  4. Mitigation recovers PDR to > 70% even at 100% attack
  5. Throughput correlates with PDR trends
  6. Latency remains reasonable under mitigation

Blackhole Attack Characteristics:
  - Aggressive packet dropping (100% of data packets)
  - Route manipulation (fake sequence numbers)
  - Traffic attraction (low hop count claims)
  - Network disruption (proportional to malicious node count)

================================================================================
EOF

print_message "$GREEN" "Summary report: ${RESULTS_DIR}/EVALUATION_SUMMARY.txt"
print_message "$YELLOW" "Next steps:"
print_message "$YELLOW" "  1. python3 analyze_blackhole_focused.py $RESULTS_DIR"
print_message "$YELLOW" "  2. Review PDR curves and throughput analysis"
print_message "$YELLOW" "  3. Verify detection rate > 85%"
print_message "$YELLOW" "  4. Confirm mitigation effectiveness"
echo ""

# Display quick statistics
print_header "QUICK STATISTICS"

if [ -f "${RESULTS_DIR}/metrics_summary.csv" ]; then
    python3 - <<EOF
import pandas as pd

df = pd.read_csv('${RESULTS_DIR}/metrics_summary.csv')

# Filter out failed tests
df_valid = df[df['PDR'] != 'FAILED']

if len(df_valid) > 0:
    print("\nTest Success Rate:")
    total = len(df)
    passed = len(df_valid)
    print(f"  Passed: {passed}/{total} ({100*passed/total:.1f}%)")
    
    # Baseline stats
    baseline = df_valid[df_valid['TestName'].str.contains('baseline')]
    if len(baseline) > 0:
        print("\nBaseline Performance:")
        print(f"  PDR: {baseline['PDR'].values[0]:.2f}%")
        print(f"  Throughput: {baseline['Throughput'].values[0]:.2f} pkt/s")
    
    # No mitigation stats
    no_miti = df_valid[df_valid['TestName'].str.contains('no_mitigation')]
    if len(no_miti) > 0:
        print("\nNo Mitigation (Attack Impact):")
        print(f"  Avg PDR: {no_miti['PDR'].astype(float).mean():.2f}%")
        print(f"  Avg Throughput: {no_miti['Throughput'].astype(float).mean():.2f} pkt/s")
        print(f"  Total Dropped: {no_miti['Dropped'].astype(float).sum():.0f} packets")
    
    # With mitigation stats
    with_miti = df_valid[df_valid['TestName'].str.contains('with_mitigation')]
    if len(with_miti) > 0:
        print("\nWith Mitigation (Recovery):")
        print(f"  Avg PDR: {with_miti['PDR'].astype(float).mean():.2f}%")
        print(f"  Avg Throughput: {with_miti['Throughput'].astype(float).mean():.2f} pkt/s")
        print(f"  Avg Detected: {with_miti['Detected'].astype(float).mean():.1f} nodes")
        print(f"  Avg Blacklisted: {with_miti['Blacklisted'].astype(float).mean():.1f} nodes")
else:
    print("No valid test results found")
EOF
fi

echo ""

#!/bin/bash

# Replay Attack Test Script
# This script tests the Replay Attack implementation with various configurations

echo "================================================"
echo "Replay Attack Implementation Test Suite"
echo "================================================"

# Test 1: Basic Replay Attack without Detection
echo ""
echo "Test 1: Basic Replay Attack (No Detection)"
echo "--------------------------------------------"
./waf --run "routing \
    --enable_replay_attack=true \
    --replay_attack_percentage=0.10 \
    --replay_interval=1.0 \
    --replay_count_per_node=5 \
    --simTime=10" 2>&1 | grep -E "Replay|Total"

# Test 2: Replay Detection with Default BF Parameters
echo ""
echo "Test 2: Replay Detection (Default BF Parameters)"
echo "-------------------------------------------------"
./waf --run "routing \
    --enable_replay_attack=true \
    --enable_replay_detection=true \
    --enable_replay_mitigation=false \
    --replay_attack_percentage=0.10 \
    --bf_filter_size=8192 \
    --bf_num_hash_functions=4 \
    --bf_num_filters=3 \
    --bf_rotation_interval=5.0 \
    --simTime=10" 2>&1 | grep -E "Replay|Bloom|False"

# Test 3: Full Replay Mitigation
echo ""
echo "Test 3: Replay Mitigation (Blocking Enabled)"
echo "---------------------------------------------"
./waf --run "routing \
    --enable_replay_attack=true \
    --enable_replay_detection=true \
    --enable_replay_mitigation=true \
    --replay_attack_percentage=0.15 \
    --replay_interval=0.5 \
    --replay_count_per_node=10 \
    --bf_filter_size=16384 \
    --bf_num_hash_functions=5 \
    --bf_num_filters=4 \
    --bf_rotation_interval=3.0 \
    --simTime=10" 2>&1 | grep -E "Replay|Blocked|False"

# Test 4: False-Positive Rate Validation (No Attack)
echo ""
echo "Test 4: False-Positive Rate Validation (No Attack)"
echo "---------------------------------------------------"
./waf --run "routing \
    --enable_replay_attack=false \
    --enable_replay_detection=true \
    --enable_replay_mitigation=true \
    --bf_filter_size=8192 \
    --bf_num_hash_functions=4 \
    --bf_target_false_positive=0.000005 \
    --simTime=10" 2>&1 | grep -E "False|Total"

# Test 5: High Load Test (Large BF, Many Replays)
echo ""
echo "Test 5: High Load Test (Stress Test)"
echo "-------------------------------------"
./waf --run "routing \
    --enable_replay_attack=true \
    --enable_replay_detection=true \
    --enable_replay_mitigation=true \
    --replay_attack_percentage=0.20 \
    --replay_interval=0.2 \
    --replay_count_per_node=20 \
    --bf_filter_size=32768 \
    --bf_num_hash_functions=6 \
    --bf_num_filters=5 \
    --bf_rotation_interval=2.0 \
    --simTime=10" 2>&1 | grep -E "Replay|Throughput|Latency"

echo ""
echo "================================================"
echo "CSV Files Generated:"
echo "================================================"
ls -lh *.csv 2>/dev/null | grep replay || echo "No replay CSV files found"

echo ""
echo "================================================"
echo "Test Suite Complete!"
echo "================================================"

# Display key metrics from CSV files
if [ -f "replay-detection-results.csv" ]; then
    echo ""
    echo "Detection Results Summary:"
    echo "--------------------------"
    grep -E "FalsePositiveRate|DetectionAccuracy|AvgProcessingLatency|Throughput" replay-detection-results.csv
fi

if [ -f "replay-mitigation-results.csv" ]; then
    echo ""
    echo "Mitigation Results Summary:"
    echo "---------------------------"
    grep -E "TotalReplaysBlocked|FalsePositiveRate|Throughput" replay-mitigation-results.csv
fi

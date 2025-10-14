# Wormhole Detection Testing Guide

## Quick Start

### 1. Baseline Test (Wormhole Attack Only - No Detection)

This establishes the baseline impact of the wormhole attack without any detection or mitigation.

```bash
cd ~/Downloads/ns-allinone-3.35/ns-3.35
./waf --run "routing --use_enhanced_wormhole=true \
                     --attack_percentage=20.0 \
                     --enable_wormhole_detection=false \
                     --enable_wormhole_mitigation=false \
                     --simTime=30" > baseline_attack.txt 2>&1
```

**Look for in output**:
- `WORMHOLE ATTACK STATISTICS` section
- `Total Packets Tunneled`
- `Total Data Packets Affected`
- `average_latency` value
- `average packet delivery ratio`

### 2. Detection Test (Detection Enabled, No Mitigation)

This tests the detection accuracy without automatic mitigation.

```bash
./waf --run "routing --use_enhanced_wormhole=true \
                     --attack_percentage=20.0 \
                     --enable_wormhole_detection=true \
                     --enable_wormhole_mitigation=false \
                     --detection_latency_threshold=2.0 \
                     --detection_check_interval=1.0 \
                     --simTime=30" > detection_only.txt 2>&1
```

**Look for in output**:
- `[DETECTOR]` initialization messages
- `Wormhole suspected in flow` messages
- `WORMHOLE DETECTION REPORT` section
- Detection accuracy metrics
- Percentage of flows affected

### 3. Full Protection Test (Detection + Mitigation)

This tests the complete system with automatic mitigation enabled.

```bash
./waf --run "routing --use_enhanced_wormhole=true \
                     --attack_percentage=20.0 \
                     --enable_wormhole_detection=true \
                     --enable_wormhole_mitigation=true \
                     --detection_latency_threshold=2.0 \
                     --detection_check_interval=1.0 \
                     --simTime=30" > full_protection.txt 2>&1
```

**Look for in output**:
- `[DETECTOR] Mitigation ENABLED`
- `Triggering route change` messages
- `Nodes blacklisted` count
- Reduced latency compared to baseline
- Improved PDR

### 4. Normal Operation Test (No Attack, Detection Active)

This measures false positive rate during normal operation.

```bash
./waf --run "routing --use_enhanced_wormhole=false \
                     --enable_wormhole_detection=true \
                     --enable_wormhole_mitigation=true \
                     --detection_latency_threshold=2.0 \
                     --simTime=30" > normal_operation.txt 2>&1
```

**Look for in output**:
- Should have ZERO or minimal `Wormhole suspected` messages
- Normal latency values
- High PDR
- No false detections

## Parameter Tuning

### Latency Threshold Tuning

Test different threshold values to find optimal detection:

```bash
# Conservative (fewer false positives, may miss some attacks)
--detection_latency_threshold=3.0

# Balanced (recommended)
--detection_latency_threshold=2.0

# Aggressive (catches more attacks, more false positives)
--detection_latency_threshold=1.5
```

### Attack Percentage Variation

Test different attack intensities:

```bash
# Light attack (10% malicious nodes)
--attack_percentage=10.0

# Medium attack (20% malicious nodes - recommended)
--attack_percentage=20.0

# Heavy attack (30% malicious nodes)
--attack_percentage=30.0
```

## Metrics Extraction

### From WORMHOLE ATTACK STATISTICS

Extract these values from the output:

```bash
grep -A 20 "WORMHOLE ATTACK STATISTICS" baseline_attack.txt
```

Look for:
- `Total Packets Intercepted: XXX`
- `Total Packets Tunneled: XXX`
- `Total Data Packets Affected: XXX`
- `Overall Avg Tunneling Delay: X.XXX s`

### From WORMHOLE DETECTION REPORT

Extract detection metrics:

```bash
grep -A 30 "WORMHOLE DETECTION REPORT" detection_only.txt
```

Look for:
- `Total Flows Monitored: XXX`
- `Flows Affected by Wormhole: XX`
- `Percentage of Flows Affected: XX.X%`
- `Average Normal Flow Latency: X.XX ms`
- `Average Wormhole Flow Latency: XX.XX ms`
- `Average Latency Increase: XXX.X%`
- `Route Changes Triggered: XX`

### From General Statistics

Extract general network metrics:

```bash
grep "average_latency\|average packet delivery ratio\|average jitter" *.txt
```

## Expected Results Comparison

### Scenario Comparison Table

Create a comparison table with your results:

| Metric | Baseline (Attack) | Detection Only | Detection + Mitigation | Normal Operation |
|--------|-------------------|----------------|------------------------|------------------|
| **Packets Tunneled** | 56 (from previous) | ~50-60 | ~20-30 (reduced) | 0 |
| **Flows Affected** | Unknown | ~40-50% | ~20-30% (reduced) | 0% |
| **Avg Latency (ms)** | ~0 (needs fix) | ~X | ~0.5X (improved) | ~baseline |
| **PDR (%)** | ~0 (needs fix) | ~Y | ~Y+10 (improved) | ~95-100 |
| **Flows Detected** | N/A | ~XX | ~XX | 0-2 (false pos) |
| **Detection Accuracy** | N/A | ~90%+ | ~90%+ | N/A |
| **Route Changes** | 0 | 0 | ~XX | 0 |

### Performance Improvement Calculation

Calculate improvement metrics:

1. **Latency Reduction**:
   ```
   Reduction % = ((Baseline_Latency - Mitigated_Latency) / Baseline_Latency) × 100
   ```

2. **PDR Improvement**:
   ```
   Improvement = Mitigated_PDR - Baseline_PDR
   ```

3. **Flows Protected**:
   ```
   Protected % = ((Baseline_Affected - Mitigated_Affected) / Baseline_Affected) × 100
   ```

## Visualization Scripts

### Create Comparison Graphs

Use Python to visualize results:

```python
import matplotlib.pyplot as plt
import numpy as np

scenarios = ['Baseline\n(Attack)', 'Detection\nOnly', 'Detection+\nMitigation', 'Normal\nOperation']
latencies = [50, 48, 25, 15]  # Replace with your values
pdrs = [70, 72, 85, 98]       # Replace with your values
flows_affected = [42, 40, 18, 0]  # Replace with your values

fig, (ax1, ax2, ax3) = plt.subplots(1, 3, figsize=(15, 5))

# Latency comparison
ax1.bar(scenarios, latencies, color=['red', 'orange', 'green', 'blue'])
ax1.set_ylabel('Average Latency (ms)')
ax1.set_title('Latency Comparison')
ax1.grid(axis='y', alpha=0.3)

# PDR comparison
ax2.bar(scenarios, pdrs, color=['red', 'orange', 'green', 'blue'])
ax2.set_ylabel('Packet Delivery Ratio (%)')
ax2.set_title('PDR Comparison')
ax2.grid(axis='y', alpha=0.3)

# Flows affected
ax3.bar(scenarios, flows_affected, color=['red', 'orange', 'green', 'blue'])
ax3.set_ylabel('Flows Affected (%)')
ax3.set_title('Flows Affected by Wormhole')
ax3.grid(axis='y', alpha=0.3)

plt.tight_layout()
plt.savefig('wormhole_detection_comparison.png', dpi=300)
print("Saved comparison graph to wormhole_detection_comparison.png")
```

## Troubleshooting

### Issue: Detection Not Working

**Symptoms**: No `[DETECTOR]` messages in output

**Solutions**:
1. Verify `--enable_wormhole_detection=true` is set
2. Check compilation succeeded without errors
3. Ensure attack is active (`--use_enhanced_wormhole=true`)

### Issue: All Flows Flagged as Suspicious

**Symptoms**: Too many false positives

**Solutions**:
1. Increase threshold: `--detection_latency_threshold=2.5` or `3.0`
2. Check if baseline latency is calculated correctly
3. Increase minimum packet count before detection

### Issue: No Flows Detected

**Symptoms**: Attack is active but no detections

**Solutions**:
1. Decrease threshold: `--detection_latency_threshold=1.5`
2. Check if flows have enough packets (need 3+)
3. Verify wormhole is actually affecting traffic

### Issue: Latency Still Shows 0

**Symptoms**: `average_latency 0 ms` in output

**Solutions**:
1. This is a known issue with the existing code
2. Focus on `Avg Tunneling Delay` from wormhole statistics
3. Use per-flow latency from detection report
4. May need to add proper latency tracking in main simulation

## Automated Test Script

Create a bash script to run all tests:

```bash
#!/bin/bash
# wormhole_detection_tests.sh

NSDIR=~/Downloads/ns-allinone-3.35/ns-3.35
cd $NSDIR

echo "Running Wormhole Detection Test Suite..."
echo "=========================================="

# Test 1: Baseline
echo "[1/4] Running baseline test (attack only)..."
./waf --run "routing --use_enhanced_wormhole=true \
                     --attack_percentage=20.0 \
                     --enable_wormhole_detection=false \
                     --simTime=30" > baseline_attack.txt 2>&1
echo "✓ Baseline complete. Output: baseline_attack.txt"

# Test 2: Detection Only
echo "[2/4] Running detection test..."
./waf --run "routing --use_enhanced_wormhole=true \
                     --attack_percentage=20.0 \
                     --enable_wormhole_detection=true \
                     --enable_wormhole_mitigation=false \
                     --detection_latency_threshold=2.0 \
                     --simTime=30" > detection_only.txt 2>&1
echo "✓ Detection complete. Output: detection_only.txt"

# Test 3: Full Protection
echo "[3/4] Running full protection test..."
./waf --run "routing --use_enhanced_wormhole=true \
                     --attack_percentage=20.0 \
                     --enable_wormhole_detection=true \
                     --enable_wormhole_mitigation=true \
                     --detection_latency_threshold=2.0 \
                     --simTime=30" > full_protection.txt 2>&1
echo "✓ Full protection complete. Output: full_protection.txt"

# Test 4: Normal Operation
echo "[4/4] Running normal operation test..."
./waf --run "routing --use_enhanced_wormhole=false \
                     --enable_wormhole_detection=true \
                     --simTime=30" > normal_operation.txt 2>&1
echo "✓ Normal operation complete. Output: normal_operation.txt"

echo ""
echo "All tests complete!"
echo "===================="
echo "Extracting key metrics..."
echo ""

# Extract metrics
echo "BASELINE ATTACK:"
grep "Total Data Packets Affected" baseline_attack.txt | head -1
grep "Overall Avg Tunneling Delay" baseline_attack.txt | head -1

echo ""
echo "DETECTION ONLY:"
grep "Flows Affected by Wormhole" detection_only.txt | head -1
grep "Percentage of Flows Affected" detection_only.txt | head -1
grep "Average Latency Increase" detection_only.txt | head -1

echo ""
echo "FULL PROTECTION:"
grep "Route Changes Triggered" full_protection.txt | head -1
grep "Nodes Blacklisted" full_protection.txt | head -1

echo ""
echo "Results saved to: baseline_attack.txt, detection_only.txt, full_protection.txt, normal_operation.txt"
```

Make it executable and run:
```bash
chmod +x wormhole_detection_tests.sh
./wormhole_detection_tests.sh
```

## Next Steps

1. ✅ Run all four test scenarios
2. ✅ Extract metrics from outputs
3. ✅ Create comparison table
4. ✅ Calculate improvement percentages
5. ✅ Generate visualization graphs
6. ✅ Document findings in report
7. ✅ Commit results to GitHub

## Expected Outcomes

Based on the research paper:
- **Detection Accuracy**: 85-95%
- **Flows Affected**: Reduced by 50-70% with mitigation
- **Latency Increase**: 100-200% during attack, reduced to 20-50% with mitigation
- **False Positive Rate**: <5% in normal operation
- **Time to Detect**: <2 seconds after attack starts

Your actual results may vary based on:
- Network topology (22 vehicles + 1 RSU)
- Mobility patterns
- Traffic generation model
- Wormhole placement strategy

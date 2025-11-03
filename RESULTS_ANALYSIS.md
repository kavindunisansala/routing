# SDVN Attack Test Results Analysis

## Test Execution Date
**November 2, 2025** - Results from `sdvn_attack_results_20251102_183115/`

---

## 📊 Performance Metrics Summary

| Test Scenario | PDR (%) | Avg Delay (ms) | Throughput (Mbps) | Packet Loss (%) |
|--------------|---------|----------------|-------------------|-----------------|
| **Baseline** | 88.45 | 9.05 | 0.176 | 11.55 |
| Wormhole 10% | 97.83 | 9.68 | 0.190 | 2.17 |
| Wormhole 20% | 97.83 | 9.68 | 0.190 | 2.17 |
| Blackhole 10% | 97.83 | 9.68 | 0.190 | 2.17 |
| Blackhole 20% | 97.83 | 9.68 | 0.190 | 2.17 |
| Sybil 10% | 97.83 | 9.68 | 0.190 | 2.17 |
| **Combined 10%** | **6.38** | **0.05** | **0.012** | **93.62** |

---

## 🔍 Key Observations

### ✅ What's Working

**1. Analysis Script**
- ✅ Successfully extracts metrics from packet-level CSV data
- ✅ Calculates PDR from `Delivered` column
- ✅ Calculates delay from `DelayMs` for delivered packets
- ✅ Estimates throughput based on packet delivery
- ✅ Generates comparison charts and LaTeX tables

**2. Combined Attack (Test 7)**
- ✅ **Severe impact detected**: PDR drops from 88% to 6%
- ✅ Packet loss increases to 93.6%
- ✅ Throughput drops by 93%
- ✅ **Confirms attacks are implemented and working**

**3. Baseline Performance**
- ✅ Reasonable PDR: 88.45%
- ✅ Low latency: 9.05ms average
- ✅ Stable throughput: 0.176 Mbps

---

## ⚠️ Issues Detected

### Issue 1: Individual Attacks Show No Impact

**Problem:**
Tests 2-6 (individual attacks) show **identical metrics** and **better performance than baseline**:
- PDR: 97.8% vs baseline 88.4% (improved?)
- All attack percentages (10%, 20%) show same results

**Evidence:**
```
Wormhole 10%:  PDR=97.83%, Delay=9.68ms
Wormhole 20%:  PDR=97.83%, Delay=9.68ms  (identical)
Blackhole 10%: PDR=97.83%, Delay=9.68ms  (identical)
Blackhole 20%: PDR=97.83%, Delay=9.68ms  (identical)
```

**Possible Causes:**
1. **Mitigation working TOO well**: Controller detects and mitigates attacks instantly
2. **Attack duration too short**: Attacks may need longer to impact the network
3. **Different packet counts**: Individual tests have 4606 packets vs baseline 1316 packets
4. **Timing issues**: Attack start time might be after most packets are sent

### Issue 2: Packet Tracking Columns Not Used

**Problem:**
The CSV columns `WormholeOnPath` and `BlackholeOnPath` are always 0:
```python
WormholeOnPath: 0 packets  # Should show affected packets
BlackholeOnPath: 0 packets  # Should show affected packets
```

**Impact:**
- Cannot identify which specific packets were attacked
- Cannot measure attack propagation
- Cannot verify attack targeting accuracy

**Fix Needed:**
Update `routing.cc` to properly mark packets that:
- Pass through wormhole tunnels
- Are dropped by blackhole nodes
- Are affected by sybil identities

---

## 🎯 Test Configuration Verification

### Architecture
```
Architecture: 0 (Centralized SDVN) ✓
Vehicles: 18
RSUs: 10
Simulation Time: 100s
```

### Attack Activation Confirmed

**Wormhole (Test 2):**
```
✓ 2 wormhole tunnels created
✓ Attack active 0s to 100s
✓ Nodes 11, 12 marked as malicious
✓ Detection system initialized
```

**Combined (Test 7):**
```
✓ All attacks enabled simultaneously
✓ Severe impact: 93.6% packet loss
✓ Proves attacks can work
```

---

## 📈 Analysis Output Files Generated

All files in `sdvn_attack_results_20251102_183115/`:

1. **summary_statistics.csv** - Aggregated metrics per scenario
2. **attack_impact_comparison.csv** - Degradation percentages
3. **performance_comparison.png** - 6-panel comparison chart
4. **attack_impact_comparison.png** - Bar chart of attack effects
5. **results_latex_table.tex** - Publication-ready table

---

## 🔧 Recommended Actions

### Immediate Actions

**1. Investigate Individual Attack Behavior**
```bash
# Check attack logs for timing issues
grep "ATTACK STARTING\|Attack active" test2_sdvn_wormhole_10_output.txt
grep "ATTACK STARTING\|Attack active" test4_sdvn_blackhole_10_output.txt
grep "ATTACK STARTING\|Attack active" test6_sdvn_sybil_10_output.txt
```

**2. Verify Mitigation Timing**
```bash
# Check when mitigation activates
grep -i "mitigation\|detection" test2_sdvn_wormhole_10_output.txt | head -20
```

**3. Compare Packet Counts**
```bash
# Why does baseline have fewer packets?
wc -l test1_sdvn_baseline_packet-delivery-analysis.csv
wc -l test2_sdvn_wormhole_10_packet-delivery-analysis.csv
```

### Code Improvements Needed

**1. Fix Packet Tracking in routing.cc**

Add proper marking when packets encounter attacks:
```cpp
// In packet forwarding logic
if (IsNodeMaliciousWormhole(currentNode)) {
    packet->AddTag<WormholeTag>(); // Mark packet
}

// In CSV output
csvFile << packetId << "," 
        << sourceNode << ","
        << destNode << ","
        << sendTime << ","
        << receiveTime << ","
        << delay << ","
        << delivered << ","
        << (hasWormholeTag ? 1 : 0) << ","  // Actually track this
        << (hasBlackholeTag ? 1 : 0) << endl;
```

**2. Add Attack Start Delay**

Ensure attacks start after network stabilizes:
```cpp
// Current: Attack starts at 0s
// Better: Start attacks at 10s
Simulator::Schedule(Seconds(10.0), &StartWormholeAttacks);
Simulator::Schedule(Seconds(10.0), &StartBlackholeAttacks);
```

**3. Add Detection/Mitigation Metrics to CSV**

Create new CSV files:
- `controller_metrics.csv` - Control overhead, detection times
- `mitigation_results.csv` - When mitigation activated, routes changed
- `detection_accuracy.csv` - True positives, false positives

---

## 📊 Statistical Validity

### Current Data Quality

**✅ Good:**
- Multiple test scenarios (7 tests)
- Consistent packet counts (4606 packets for most tests)
- Complete CSV data with all required columns
- Reproducible results

**⚠️ Concerns:**
- Baseline has only 1316 packets (vs 4606 in other tests)
- Individual attacks show no degradation
- Cannot measure detection/mitigation effectiveness

### For Publication

**Currently Available Metrics:**
- ✅ PDR (Packet Delivery Ratio)
- ✅ End-to-end delay
- ✅ Packet loss rate
- ✅ Throughput estimation

**Missing Metrics:**
- ❌ Detection rate per attack type
- ❌ False positive/negative rates
- ❌ Controller overhead
- ❌ Mitigation response time
- ❌ Network convergence time
- ❌ Attack propagation patterns

---

## 🎓 Interpretation

### Why Combined Attack Works But Individual Don't

**Hypothesis 1: Mitigation is Effective**
- Individual attacks detected and mitigated quickly
- Combined attacks overwhelm mitigation capacity
- PDR actually improves because mitigation reroutes traffic efficiently

**Hypothesis 2: Attack Timing**
- Individual attacks may activate after packet generation completes
- Combined attack creates more persistent threat
- Need to check packet generation timestamps

**Hypothesis 3: Packet Generation Differences**
- Baseline: 1316 packets (different configuration?)
- Attack tests: 4606 packets (more traffic generated)
- Higher packet count might mask attack effects

**Hypothesis 4: Detection is Working TOO Well**
- SDVN controller immediately detects attacks
- Reroutes traffic before significant impact
- Combined attack shows what happens when mitigation overwhelmed

---

## ✅ Conclusion

### Current Status: **PARTIALLY WORKING**

**Working:**
- ✅ Analysis script correctly processes CSV data
- ✅ Combined attack shows severe impact (93% loss)
- ✅ SDVN architecture is operational
- ✅ Attacks are activating (confirmed in logs)

**Issues:**
- ⚠️ Individual attacks show no performance degradation
- ⚠️ Packet tracking columns not populated
- ⚠️ Cannot measure detection/mitigation effectiveness
- ⚠️ Baseline has different packet count

### Next Steps

1. **Investigate why individual attacks don't impact performance**
2. **Fix packet tracking to mark attacked packets**
3. **Add controller metrics CSV output**
4. **Verify attack timing vs packet generation**
5. **Re-run tests with fixes**

---

**Generated:** November 3, 2025  
**Tool Version:** analyze_attack_results.py (updated)  
**Data Source:** sdvn_attack_results_20251102_183115/

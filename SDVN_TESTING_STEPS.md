# SDVN Attack Testing and Performance Evaluation - Complete Guide

## 📋 Overview

This guide provides step-by-step instructions to:
1. Test SDVN attacks (Wormhole, Blackhole, Sybil)
2. Verify attack detection mechanisms
3. Evaluate mitigation solutions
4. Collect performance metrics in CSV format
5. Analyze and compare results

---

## 🚀 Step-by-Step Testing Process

### Step 1: Prepare Your Environment

#### 1.1 Verify Files Are Present
```powershell
# Check all required files exist
cd "d:\routing - Copy"
ls test_sdvn_attacks.sh, analyze_attack_results.py, routing.cc
```

Expected output:
```
✓ test_sdvn_attacks.sh (Test automation script)
✓ analyze_attack_results.py (Analysis tool)
✓ routing.cc (NS-3 simulation)
```

#### 1.2 Ensure Latest Code
```powershell
# Pull latest changes
git pull origin master

# Check current branch
git branch
```

#### 1.3 Clean Previous Build
```powershell
# Clean old build artifacts
./waf clean
```

---

### Step 2: Compile the Simulation

#### 2.1 Build with Optimizations
```powershell
# Build NS-3 with routing module
./waf configure --enable-examples --enable-tests
./waf build
```

#### 2.2 Verify Compilation
```powershell
# Check if routing program exists
ls build/scratch/routing*
```

Expected: `routing.exe` or similar executable

#### 2.3 Test Basic Execution
```powershell
# Quick test run (1 second simulation)
./waf --run "routing --sim_time=1 --architecture=0"
```

Should complete without errors.

---

### Step 3: Run SDVN Attack Tests

#### 3.1 Make Script Executable (if needed)
```bash
# In Git Bash or WSL
chmod +x test_sdvn_attacks.sh
```

#### 3.2 Run Complete Test Suite
```powershell
# Run all 7 SDVN test scenarios
./test_sdvn_attacks.sh
```

This will run:
- **Test 1**: Baseline (no attacks)
- **Test 2**: Wormhole Attack 10%
- **Test 3**: Wormhole Attack 20%
- **Test 4**: Blackhole Attack 10%
- **Test 5**: Blackhole Attack 20%
- **Test 6**: Sybil Attack 10%
- **Test 7**: Combined Attacks 10%

#### 3.3 Monitor Progress
```
Expected output:
==========================================
SDVN-ONLY Security Attack Testing Suite
==========================================
Simulation Parameters:
  Architecture: 0 (Centralized SDVN)
  Vehicles: 18
  RSUs: 10
  Simulation Time: 100s
  
Running Test 1/7: Baseline (No Attacks)...
[Progress indicator]
✓ Test completed in XXs

Running Test 2/7: Wormhole Attack (10%)...
[Progress indicator]
✓ Test completed in XXs
...
```

#### 3.4 Estimated Time
- Each test: ~2-5 minutes
- Total time: ~15-35 minutes (7 tests)

---

### Step 4: Verify Test Outputs

#### 4.1 Check Results Directory
```powershell
# List generated results
ls sdvn_attack_results_*
```

Expected structure:
```
sdvn_attack_results_20251031_HHMMSS/
├── test1_baseline/
│   ├── routing_metrics.csv
│   ├── packet_tracking.csv
│   ├── controller_metrics.csv
│   └── test1_baseline.txt (log)
├── test2_wormhole_10/
│   ├── routing_metrics.csv
│   ├── wormhole_detection.csv
│   ├── wormhole_mitigation.csv
│   ├── controller_metrics.csv
│   └── test2_wormhole_10.txt
├── test3_wormhole_20/
├── test4_blackhole_10/
├── test5_blackhole_20/
├── test6_sybil_10/
└── test7_combined_10/
```

#### 4.2 Verify CSV Files
```powershell
# Check CSV files were created
cd sdvn_attack_results_*/test1_baseline
cat routing_metrics.csv | head -10
```

Expected columns:
```
Time,NodeId,PacketsSent,PacketsReceived,PacketsDropped,Throughput,Delay,PDR
```

---

### Step 5: Analyze Attack Detection

#### 5.1 Check Wormhole Detection
```powershell
# View wormhole detection results
cd sdvn_attack_results_*/test2_wormhole_10
cat wormhole_detection.csv
```

**Key Metrics:**
```
Time,DetectionEvent,MaliciousNode1,MaliciousNode2,TunnelDistance,DetectionMethod
10.5,DETECTED,Node3,Node7,150m,RTT_ANOMALY
15.2,DETECTED,Node5,Node9,200m,TOPOLOGY_VIOLATION
```

**What to Look For:**
- ✅ Detection events appearing after attacks start
- ✅ Correct identification of malicious nodes
- ✅ Detection method (RTT, topology analysis, etc.)
- ✅ Detection time (should be < 10s after attack)

#### 5.2 Check Blackhole Detection
```powershell
# View blackhole detection through mitigation
cd ../test4_blackhole_10
cat controller_metrics.csv | Select-String "blackhole"
```

**Key Metrics:**
```
Time,Event,AffectedNodes,DroppedPackets,MitigationAction
12.3,BLACKHOLE_DETECTED,Node4,45,ROUTE_RECALCULATION
```

**What to Look For:**
- ✅ Increased packet drops at specific nodes
- ✅ Controller detection of abnormal behavior
- ✅ Mitigation triggered automatically

#### 5.3 Check Sybil Detection
```powershell
# View sybil detection results
cd ../test6_sybil_10
cat controller_metrics.csv | Select-String "sybil"
```

**Key Metrics:**
```
Time,Event,MaliciousNode,FakeIdentities,DetectionMethod
8.7,SYBIL_DETECTED,Node6,3,IDENTITY_VERIFICATION
```

**What to Look For:**
- ✅ Multiple identity detection
- ✅ Identity verification failures
- ✅ Network position inconsistencies

---

### Step 6: Analyze Mitigation Effectiveness

#### 6.1 Compare PDR (Packet Delivery Ratio)
```powershell
# Extract PDR from all tests
cd sdvn_attack_results_*
foreach ($dir in ls -Directory) {
    echo "=== $($dir.Name) ==="
    cat "$dir/routing_metrics.csv" | Select-String "PDR" | tail -1
}
```

**Expected Results:**
```
=== test1_baseline ===
Overall_PDR: 0.92 (92%)

=== test2_wormhole_10 ===
Before_Mitigation_PDR: 0.68 (68%)
After_Mitigation_PDR: 0.84 (84%)
Recovery: +16%

=== test3_wormhole_20 ===
Before_Mitigation_PDR: 0.58 (58%)
After_Mitigation_PDR: 0.76 (76%)
Recovery: +18%

=== test4_blackhole_10 ===
Before_Mitigation_PDR: 0.65 (65%)
After_Mitigation_PDR: 0.82 (82%)
Recovery: +17%

=== test5_blackhole_20 ===
Before_Mitigation_PDR: 0.52 (52%)
After_Mitigation_PDR: 0.71 (71%)
Recovery: +19%

=== test6_sybil_10 ===
Before_Mitigation_PDR: 0.72 (72%)
After_Mitigation_PDR: 0.86 (86%)
Recovery: +14%

=== test7_combined_10 ===
Before_Mitigation_PDR: 0.43 (43%)
After_Mitigation_PDR: 0.68 (68%)
Recovery: +25%
```

#### 6.2 Compare Delay
```powershell
# Extract average delay
foreach ($dir in ls -Directory) {
    echo "=== $($dir.Name) ==="
    cat "$dir/routing_metrics.csv" | Select-String "Avg_Delay"
}
```

**Expected Results:**
```
Baseline: 25ms
Wormhole 10%: 45ms → 32ms (mitigation)
Wormhole 20%: 65ms → 40ms (mitigation)
Blackhole 10%: 38ms → 30ms (mitigation)
Blackhole 20%: 52ms → 35ms (mitigation)
Sybil 10%: 42ms → 33ms (mitigation)
Combined 10%: 78ms → 48ms (mitigation)
```

#### 6.3 Compare Throughput
```powershell
# Extract throughput
foreach ($dir in ls -Directory) {
    echo "=== $($dir.Name) ==="
    cat "$dir/routing_metrics.csv" | Select-String "Throughput"
}
```

---

### Step 7: Evaluate Controller Performance

#### 7.1 Check Controller Overhead
```powershell
# Analyze controller metrics
cat test1_baseline/controller_metrics.csv
```

**Key Metrics:**
```
Metric,Value
ControlMessages,1250
ControlOverhead,4.5%
FlowTableUpdates,156
TopologyDiscoveryTime,2.3s
AverageResponseTime,12ms
```

#### 7.2 Check Detection Performance
```powershell
# Check detection accuracy
cat test2_wormhole_10/wormhole_detection.csv
```

**Key Metrics:**
```
Total_Attacks: 10
Detected: 9
False_Positives: 1
Detection_Rate: 90%
False_Positive_Rate: 5%
Average_Detection_Time: 8.5s
```

#### 7.3 Check Mitigation Performance
```powershell
# Check mitigation effectiveness
cat test2_wormhole_10/wormhole_mitigation.csv
```

**Key Metrics:**
```
Metric,Value
MitigationActions,9
RoutesRecalculated,45
FlowRulesUpdated,78
NetworkConvergenceTime,3.2s
PDR_Recovery,+16%
Delay_Recovery,-13ms
```

---

### Step 8: Generate Comprehensive Analysis

#### 8.1 Install Python Dependencies
```powershell
# Install required libraries
pip install pandas matplotlib seaborn
```

#### 8.2 Run Analysis Script
```powershell
# Analyze all results
python analyze_attack_results.py sdvn_attack_results_*/
```

**Expected Output:**
```
Analyzing SDVN Attack Test Results...
Found 7 test scenarios

Performance Comparison:
┌─────────────────┬────────┬──────────┬────────────┬──────────────┐
│ Test            │ PDR    │ Delay    │ Throughput │ Detection    │
├─────────────────┼────────┼──────────┼────────────┼──────────────┤
│ Baseline        │ 92.0%  │ 25ms     │ 450Kbps    │ N/A          │
│ Wormhole 10%    │ 84.0%  │ 32ms     │ 380Kbps    │ 90% (8.5s)   │
│ Wormhole 20%    │ 76.0%  │ 40ms     │ 340Kbps    │ 85% (9.2s)   │
│ Blackhole 10%   │ 82.0%  │ 30ms     │ 370Kbps    │ 88% (7.8s)   │
│ Blackhole 20%   │ 71.0%  │ 35ms     │ 320Kbps    │ 84% (8.5s)   │
│ Sybil 10%       │ 86.0%  │ 33ms     │ 390Kbps    │ 87% (9.0s)   │
│ Combined 10%    │ 68.0%  │ 48ms     │ 310Kbps    │ 82% (10.5s)  │
└─────────────────┴────────┴──────────┴────────────┴──────────────┘

Mitigation Effectiveness:
✓ Average PDR Recovery: +17.8%
✓ Average Delay Reduction: -15ms
✓ Average Detection Rate: 86.6%
✓ Average Detection Time: 8.9s
✓ Controller Overhead: 4.5-6.2%

Generating visualizations...
✓ Created: performance_comparison.png
✓ Created: pdr_recovery.png
✓ Created: detection_accuracy.png
✓ Created: mitigation_timeline.png

Summary saved to: analysis_summary.csv
```

#### 8.3 View Generated Charts
```powershell
# Open visualizations
start performance_comparison.png
start pdr_recovery.png
start detection_accuracy.png
```

---

### Step 9: Extract Performance Metrics CSV

#### 9.1 Create Summary CSV
```powershell
# Run analysis to generate summary
python analyze_attack_results.py sdvn_attack_results_*/ --output summary
```

This creates: **`sdvn_performance_summary.csv`**

#### 9.2 View Summary CSV
```powershell
cat sdvn_performance_summary.csv
```

**Expected Format:**
```csv
Test,AttackType,AttackPercentage,PDR_Before,PDR_After,PDR_Recovery,Delay_Before,Delay_After,Throughput_Before,Throughput_After,Detection_Rate,Detection_Time_Avg,False_Positive_Rate,Mitigation_Time,Controller_Overhead,Network_Convergence_Time
Baseline,None,0,92.0,92.0,0,25,25,450,450,N/A,N/A,N/A,N/A,4.5,N/A
Wormhole_10,Wormhole,10,68.0,84.0,16.0,45,32,320,380,90.0,8.5,5.0,3.2,5.8,3.2
Wormhole_20,Wormhole,20,58.0,76.0,18.0,65,40,280,340,85.0,9.2,6.5,3.8,6.2,3.8
Blackhole_10,Blackhole,10,65.0,82.0,17.0,38,30,340,370,88.0,7.8,4.5,2.9,5.5,2.9
Blackhole_20,Blackhole,20,52.0,71.0,19.0,52,35,300,320,84.0,8.5,5.8,3.5,5.9,3.5
Sybil_10,Sybil,10,72.0,86.0,14.0,42,33,360,390,87.0,9.0,5.2,3.4,5.6,3.4
Combined_10,Combined,10,43.0,68.0,25.0,78,48,280,310,82.0,10.5,7.5,4.2,6.8,4.2
```

---

### Step 10: Verify Attack Implementation

#### 10.1 Check Attack Activation in Logs
```powershell
# Check wormhole activation
cat sdvn_attack_results_*/test2_wormhole_10/test2_wormhole_10.txt | Select-String "wormhole"
```

**Expected Log Entries:**
```
[5.0s] Initializing Wormhole Attack Manager
[5.0s] Selecting 10% of nodes for wormhole attack
[5.0s] Wormhole tunnel created: Node3 <-> Node7
[5.0s] Wormhole tunnel created: Node5 <-> Node9
[10.5s] Controller detected wormhole: Node3-Node7
[10.6s] Initiating mitigation: Removing malicious routes
[11.2s] Flow tables updated on 15 nodes
```

#### 10.2 Check Blackhole Activation
```powershell
# Check blackhole activation
cat sdvn_attack_results_*/test4_blackhole_10/test4_blackhole_10.txt | Select-String "blackhole"
```

**Expected Log Entries:**
```
[5.0s] Initializing Blackhole Attack Manager
[5.0s] Marking Node4 as blackhole attacker
[5.0s] Node4 starting packet dropping
[12.3s] Controller detected abnormal drops at Node4
[12.4s] Blackhole mitigation: Rerouting traffic away from Node4
[13.1s] 25 routes recalculated
```

#### 10.3 Check Sybil Activation
```powershell
# Check sybil activation
cat sdvn_attack_results_*/test6_sybil_10/test6_sybil_10.txt | Select-String "sybil"
```

**Expected Log Entries:**
```
[5.0s] Initializing Sybil Attack Manager
[5.0s] Node6 creating 3 fake identities
[5.0s] Sybil identities: Node6_Fake1, Node6_Fake2, Node6_Fake3
[8.7s] Controller detected identity conflict at Node6
[8.8s] Sybil mitigation: Blacklisting fake identities
[9.2s] Identity verification enforced
```

---

## 📊 Performance Metrics Reference

### Key Performance Indicators (KPIs)

#### 1. Attack Impact Metrics

**PDR (Packet Delivery Ratio)**
```
Formula: (Packets Received / Packets Sent) × 100
Baseline: 90-95%
Under Attack: 40-75%
After Mitigation: 70-90%

✓ Good: PDR recovery > 15%
⚠ Moderate: PDR recovery 10-15%
✗ Poor: PDR recovery < 10%
```

**Delay (End-to-End Latency)**
```
Formula: Average(Packet Arrival Time - Packet Send Time)
Baseline: 20-30ms
Under Attack: 40-80ms
After Mitigation: 25-50ms

✓ Good: Delay reduction > 10ms
⚠ Moderate: Delay reduction 5-10ms
✗ Poor: Delay reduction < 5ms
```

**Throughput**
```
Formula: (Bytes Received / Simulation Time) × 8
Baseline: 400-500 Kbps
Under Attack: 250-400 Kbps
After Mitigation: 300-450 Kbps

✓ Good: Throughput recovery > 50 Kbps
⚠ Moderate: Throughput recovery 25-50 Kbps
✗ Poor: Throughput recovery < 25 Kbps
```

#### 2. Detection Performance Metrics

**Detection Rate**
```
Formula: (True Positives / Total Attacks) × 100
Target: > 85%

✓ Excellent: > 90%
✓ Good: 85-90%
⚠ Moderate: 75-85%
✗ Poor: < 75%
```

**False Positive Rate**
```
Formula: (False Positives / Total Detections) × 100
Target: < 10%

✓ Excellent: < 5%
✓ Good: 5-10%
⚠ Moderate: 10-20%
✗ Poor: > 20%
```

**Detection Time**
```
Formula: Detection Timestamp - Attack Start Time
Target: < 10s

✓ Excellent: < 5s
✓ Good: 5-10s
⚠ Moderate: 10-15s
✗ Poor: > 15s
```

#### 3. Mitigation Performance Metrics

**Mitigation Response Time**
```
Formula: Mitigation Start - Detection Time
Target: < 2s

✓ Excellent: < 1s
✓ Good: 1-2s
⚠ Moderate: 2-5s
✗ Poor: > 5s
```

**Network Convergence Time**
```
Formula: Time for PDR to stabilize after mitigation
Target: < 5s

✓ Excellent: < 3s
✓ Good: 3-5s
⚠ Moderate: 5-10s
✗ Poor: > 10s
```

**Recovery Percentage**
```
Formula: ((PDR_After - PDR_During) / (PDR_Baseline - PDR_During)) × 100
Target: > 70%

✓ Excellent: > 85%
✓ Good: 70-85%
⚠ Moderate: 50-70%
✗ Poor: < 50%
```

#### 4. Controller Performance Metrics

**Control Overhead**
```
Formula: (Control Messages / Total Messages) × 100
Target: < 10%

✓ Excellent: < 5%
✓ Good: 5-10%
⚠ Moderate: 10-15%
✗ Poor: > 15%
```

**Flow Table Update Rate**
```
Formula: Flow Updates / Simulation Time
Target: < 20 updates/s

✓ Good: < 10 updates/s
⚠ Moderate: 10-20 updates/s
✗ Poor: > 20 updates/s
```

---

## 🎯 Expected Results Summary

### SDVN Wormhole Attack Results

**Attack Characteristics:**
- Malicious nodes create false topology
- Packets tunneled through wormhole
- RTT increases significantly
- Controller detects via topology inconsistencies

**Expected Metrics (10% Attack):**
```
PDR Before: 68-72%
PDR After: 82-86%
Detection Rate: 88-92%
Detection Time: 7-10s
Mitigation Time: 2-4s
Controller Overhead: 5.5-6.5%
```

**Expected Metrics (20% Attack):**
```
PDR Before: 58-62%
PDR After: 74-78%
Detection Rate: 82-88%
Detection Time: 8-11s
Mitigation Time: 3-5s
Controller Overhead: 6.0-7.0%
```

### SDVN Blackhole Attack Results

**Attack Characteristics:**
- Malicious nodes drop all packets
- Advertise attractive routes
- Severe packet loss around attackers
- Controller detects via packet drop monitoring

**Expected Metrics (10% Attack):**
```
PDR Before: 63-67%
PDR After: 80-84%
Detection Rate: 85-90%
Detection Time: 6-9s
Mitigation Time: 2-4s
Controller Overhead: 5.2-6.0%
```

**Expected Metrics (20% Attack):**
```
PDR Before: 50-55%
PDR After: 69-73%
Detection Rate: 80-86%
Detection Time: 7-10s
Mitigation Time: 3-5s
Controller Overhead: 5.8-6.8%
```

### SDVN Sybil Attack Results

**Attack Characteristics:**
- Malicious nodes create fake identities
- Impersonate multiple nodes
- Confuse routing decisions
- Controller detects via identity verification

**Expected Metrics (10% Attack):**
```
PDR Before: 70-75%
PDR After: 84-88%
Detection Rate: 85-90%
Detection Time: 8-11s
Mitigation Time: 2-4s
Controller Overhead: 5.3-6.2%
```

### SDVN Combined Attack Results

**Attack Characteristics:**
- All three attacks simultaneously
- Severe network disruption
- Complex attack patterns
- Controller handles multiple threats

**Expected Metrics (10% Each):**
```
PDR Before: 40-48%
PDR After: 65-72%
Detection Rate: 78-85%
Detection Time: 9-12s
Mitigation Time: 3-6s
Controller Overhead: 6.5-8.0%
```

---

## ✅ Verification Checklist

### Before Testing
- [ ] Code compiled successfully (`./waf build`)
- [ ] All CSV output files configured in routing.cc
- [ ] Test script has execute permissions
- [ ] Python dependencies installed

### During Testing
- [ ] All 7 tests complete without errors
- [ ] Progress indicators show advancement
- [ ] No segmentation faults or crashes
- [ ] Estimated time matches expectations

### After Testing
- [ ] Results directory created with timestamp
- [ ] All subdirectories present (test1-test7)
- [ ] CSV files exist in each subdirectory
- [ ] Log files show attack activation
- [ ] Controller metrics captured

### Verification
- [ ] PDR shows attack impact and recovery
- [ ] Delay increases during attacks, decreases after mitigation
- [ ] Detection events logged correctly
- [ ] Mitigation actions recorded
- [ ] Controller overhead within acceptable range

### Analysis
- [ ] Analysis script runs without errors
- [ ] Summary CSV generated
- [ ] Visualizations created
- [ ] Metrics match expected ranges
- [ ] Results scientifically valid

---

## 🐛 Troubleshooting Common Issues

### Issue 1: No CSV Files Generated

**Problem:** Test completes but no CSV files
**Solution:**
```powershell
# Check if CSV output is enabled
./waf --run "routing --help" | Select-String "csv"

# Should see: --enable_csv_output (default: true)
```

### Issue 2: All PDR Values Are Same

**Problem:** PDR doesn't change between tests
**Cause:** Attacks not activating
**Solution:**
```powershell
# Verify attack flags in log
cat test2_wormhole_10.txt | Select-String "attack|Attack|ATTACK"

# Should see attack initialization messages
```

### Issue 3: Detection Rate is 0%

**Problem:** No detections recorded
**Cause:** Detection disabled or timing issue
**Solution:**
```bash
# Check detection flags
grep "enable_wormhole_detection" test_sdvn_attacks.sh
grep "enable_blackhole_detection" test_sdvn_attacks.sh

# Should be: true
```

### Issue 4: Test Takes Too Long

**Problem:** Each test takes > 10 minutes
**Solution:**
```bash
# Reduce simulation time for testing
# Edit test_sdvn_attacks.sh:
SIM_TIME=50  # Instead of 100

# Or reduce vehicle count
N_VEHICLES=10  # Instead of 18
```

### Issue 5: Python Analysis Fails

**Problem:** `analyze_attack_results.py` errors
**Solution:**
```powershell
# Reinstall dependencies
pip install --upgrade pandas matplotlib seaborn numpy

# Check Python version (need 3.7+)
python --version
```

---

## 📈 Using Results for Research

### For Publications

**Include These Metrics:**
1. PDR before/after mitigation (with %)
2. Detection rate and false positive rate
3. Average detection time
4. Network convergence time
5. Controller overhead
6. Comparison with baseline

**Recommended Visualizations:**
1. Bar chart: PDR comparison across scenarios
2. Line graph: PDR over time (attack → detection → mitigation)
3. Box plot: Detection time distribution
4. Heat map: Attack impact on different node positions

### For Reports

**Structure:**
1. **Baseline Performance**: Metrics without attacks
2. **Attack Impact**: Performance degradation per attack type
3. **Detection Performance**: Accuracy and speed
4. **Mitigation Effectiveness**: Recovery metrics
5. **Controller Overhead**: SDVN-specific costs
6. **Comparison**: SDVN vs traditional approaches

### Statistical Analysis

```python
# Calculate confidence intervals (in analyze_attack_results.py)
import scipy.stats as stats

# For PDR recovery
mean_recovery = np.mean(pdr_recoveries)
std_recovery = np.std(pdr_recoveries)
ci_95 = stats.t.interval(0.95, len(pdr_recoveries)-1, 
                         loc=mean_recovery, 
                         scale=std_recovery/np.sqrt(len(pdr_recoveries)))
print(f"PDR Recovery: {mean_recovery:.2f}% ± {ci_95[1]-mean_recovery:.2f}%")
```

---

## 🎓 Understanding the Results

### What Makes SDVN Effective?

**1. Global View**
- Controller sees entire network topology
- Detects anomalies invisible to individual nodes
- Coordinates network-wide response

**2. Centralized Decision Making**
- Single point of control for security
- Consistent security policies
- Rapid mitigation deployment

**3. Programmable Data Plane**
- Dynamic flow rule updates
- Traffic engineering around threats
- Flexible security implementations

### What Are the Limitations?

**1. Controller Overhead**
- 4-8% bandwidth for control messages
- Slightly higher than distributed approaches
- Trade-off for better security

**2. Detection Time**
- 7-12 seconds average detection
- Requires sufficient attack evidence
- Balance between accuracy and speed

**3. Single Point of Failure**
- Controller must remain trusted
- Controller availability critical
- Mitigation: Redundant controllers (not in this test)

---

## 🚀 Next Steps

### 1. Run Your Tests
```powershell
cd "d:\routing - Copy"
./test_sdvn_attacks.sh
```

### 2. Analyze Results
```powershell
python analyze_attack_results.py sdvn_attack_results_*/
```

### 3. Review Metrics
```powershell
cat sdvn_performance_summary.csv
```

### 4. Verify Implementation
Check that:
- ✅ Attacks activate correctly
- ✅ Detection works as expected
- ✅ Mitigation improves performance
- ✅ Metrics are scientifically valid

### 5. Document Findings
Create your research documentation using:
- CSV data from tests
- Generated visualizations
- Performance comparison tables
- This guide as reference

---

## 📝 Quick Reference Commands

```powershell
# Complete Test Workflow
cd "d:\routing - Copy"
./waf clean && ./waf build          # Compile
./test_sdvn_attacks.sh              # Run tests
python analyze_attack_results.py    # Analyze
cat sdvn_performance_summary.csv    # View results

# Individual Test (for debugging)
./waf --run "routing --architecture=0 --present_wormhole_attack_nodes=true --use_enhanced_wormhole=true --attack_percentage=0.1 --enable_wormhole_detection=true --enable_wormhole_mitigation=true --enable_packet_tracking=true --sim_time=100 --n_vehicles=18 --n_rsus=10"

# Check specific attack logs
cat test2_wormhole_10.txt | Select-String "wormhole"
cat test4_blackhole_10.txt | Select-String "blackhole"
cat test6_sybil_10.txt | Select-String "sybil"

# Quick metric check
cat routing_metrics.csv | Select-String "PDR"
cat controller_metrics.csv | Select-String "Detection"
```

---

## ✅ Success Criteria

Your SDVN attack implementation is correct if:

1. **Attacks Activate**: Log files show attack initialization
2. **Performance Degrades**: PDR drops, delay increases during attacks
3. **Detection Works**: Detection events logged with correct nodes
4. **Mitigation Helps**: PDR recovers, delay reduces after mitigation
5. **Metrics Valid**: Values within expected ranges
6. **Controller Overhead Reasonable**: 4-8% control traffic
7. **Results Repeatable**: Similar metrics across multiple runs

If all criteria met: **✅ SDVN attack and mitigation implementation is CORRECT!**

---

**Good luck with your SDVN security testing!** 🚀

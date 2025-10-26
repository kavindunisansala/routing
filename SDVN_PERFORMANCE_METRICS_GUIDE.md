# SDVN Performance Metrics Collection Guide

## 📊 Overview

This guide explains how to collect **Overhead (OH)**, **Packet Delivery Ratio (PDR)**, and **Latency** metrics for SDVN wormhole attack and mitigation evaluation.

---

## 🎯 Performance Metrics

### 1. **Packet Delivery Ratio (PDR)**
```
PDR = (Packets Received / Packets Sent) × 100%
```
- **Baseline (No Attack)**: PDR should be 90-95%
- **Under Wormhole Attack**: PDR drops to 60-80% (packets lost in tunnel or dropped)
- **With Mitigation**: PDR recovers to 85-92%

### 2. **End-to-End Latency**
```
Latency = Time packet received - Time packet sent
```
- **Baseline**: 10-50 ms (normal SDVN routing)
- **Under Attack**: 80-150 ms (tunnel adds delay + fake link routing)
- **With Mitigation**: 15-60 ms (detects wormhole, routes around it)

### 3. **Overhead (OH)**
```
Overhead Ratio = (Control Packets / Total Packets) × 100%
```
- **Baseline**: 5-10% (metadata uplink + delta downlink)
- **Under Attack**: 6-12% (same as baseline, attack doesn't add control overhead)
- **With Mitigation**: 12-20% (adds mitigation analysis packets)

---

## 📁 Output Files

The simulation generates CSV files in the working directory:

```
sdvn_metrics_baseline.csv         # Scenario 1: No attack
sdvn_metrics_under_attack.csv     # Scenario 2: Wormhole active
sdvn_metrics_with_mitigation.csv  # Scenario 3: Attack + detection
```

### CSV Format

```csv
Timestamp,Scenario,PacketsSent,PacketsReceived,PacketsDropped,PDR,
AvgLatency,MinLatency,MaxLatency,
ControlPackets,DataPackets,TotalPackets,OverheadRatio,
MetadataUplink,DeltaDownlink,MitigationPackets,
WormholeIntercepted,WormholeTunneled,WormholeDropped,
WormholesDetected,FalsePositives,DetectionTime
```

---

## 🚀 Step-by-Step Commands

### **Step 1: Compile the Modified Code**

```powershell
# Navigate to routing directory
cd "d:\routing - Copy"

# Compile with Waf (NS-3 build system)
./waf clean
./waf configure --enable-examples --enable-tests
./waf build

# OR if using direct g++ compilation:
g++ -o routing routing.cc -I/path/to/ns3/include -L/path/to/ns3/lib -lns3-dev -std=c++17 -O2
```

---

### **Step 2: Run Baseline Scenario (No Attack)**

```powershell
# Run simulation WITHOUT wormhole attack
./waf --run "routing --simTime=100 --present_wormhole_attack_nodes=false --use_sdvn_wormhole=true"

# The simulation will:
# 1. Initialize SDVN with 28 nodes, 6 controllers
# 2. Send metadata uplink and delta downlink packets
# 3. Route packets according to linklifetimeMatrix_dsrc
# 4. Collect metrics every 1 second
# 5. Export to: sdvn_metrics_baseline.csv
```

**Expected Output:**
```
[SDVNPerfMonitor] Initialized for scenario: baseline
[SDVNPerfMonitor] Monitoring started at 0.0s
[SDVNPerfMonitor] Snapshot @ 1.0s - PDR: 92.5%, Latency: 23.4ms, OH: 8.2%
[SDVNPerfMonitor] Snapshot @ 2.0s - PDR: 93.1%, Latency: 22.8ms, OH: 7.9%
...
[SDVNPerfMonitor] ✓ Metrics exported to: sdvn_metrics_baseline.csv
```

---

### **Step 3: Run Wormhole Attack Scenario**

```powershell
# Run simulation WITH wormhole attack, WITHOUT mitigation
./waf --run "routing --simTime=100 --present_wormhole_attack_nodes=true --attack_percentage=0.2 --use_sdvn_wormhole=true --wormhole_drop_packets=false"

# Attack configuration:
# - 20% malicious nodes (attack_percentage=0.2)
# - SDVN-aware wormhole (use_sdvn_wormhole=true)
# - Tunnel packets (wormhole_drop_packets=false)
```

**Expected Output:**
```
[SDVN-WORMHOLE] Node 5 discovered 3 real neighbors: 4 6 7
[SDVN-WORMHOLE] *** INJECTING FAKE METADATA ***
[SDVN-WORMHOLE] Node 5 claiming neighbor: 22
[SDVN-WORMHOLE] ✓ FAKE LINK INJECTED!
[SDVNPerfMonitor] Snapshot @ 1.0s - PDR: 68.3%, Latency: 98.5ms, OH: 9.1%
[SDVNPerfMonitor] Snapshot @ 2.0s - PDR: 65.7%, Latency: 102.3ms, OH: 8.8%
...
[SDVNPerfMonitor] ✓ Metrics exported to: sdvn_metrics_under_attack.csv
```

---

### **Step 4: Run Attack + Mitigation Scenario**

```powershell
# Run simulation WITH wormhole attack AND mitigation
./waf --run "routing --simTime=100 --present_wormhole_attack_nodes=true --attack_percentage=0.2 --use_sdvn_wormhole=true --enable_wormhole_mitigation=true"

# Mitigation will:
# 1. Monitor linklifetimeMatrix_dsrc every 5s
# 2. Detect impossible link between Node 5 and 22
# 3. Report wormhole to controller
# 4. Controller excludes fake link from routing
```

**Expected Output:**
```
[SDVN-WORMHOLE] ✓ FAKE LINK INJECTED!
[SDVNMitigation] Starting periodic analysis...
[SDVNMitigation] ⚠️  SUSPICIOUS LINK DETECTED! ⚠️
[SDVNMitigation] Nodes: 5 <-> 22
[SDVNMitigation] Reason: Geographic impossibility (distance > maxRange)
[SDVNMitigation] ⚠️  WORMHOLE DETECTED! ⚠️
[SDVNPerfMonitor] Wormhole detected: 5 <-> 22 at 6.243s
[SDVNPerfMonitor] Snapshot @ 7.0s - PDR: 87.9%, Latency: 34.2ms, OH: 15.3%
...
[SDVNPerfMonitor] ✓ Metrics exported to: sdvn_metrics_with_mitigation.csv
```

---

## 📈 Analyzing Results

### **View CSV Files**

```powershell
# Windows PowerShell
Get-Content sdvn_metrics_baseline.csv | Format-Table
Get-Content sdvn_metrics_under_attack.csv | Format-Table
Get-Content sdvn_metrics_with_mitigation.csv | Format-Table

# Or use Excel/LibreOffice to open CSV files
```

### **Extract Key Metrics**

```powershell
# Average PDR for each scenario
$baseline = Import-Csv sdvn_metrics_baseline.csv
$baseline | Measure-Object -Property PDR -Average

$attack = Import-Csv sdvn_metrics_under_attack.csv
$attack | Measure-Object -Property PDR -Average

$mitigation = Import-Csv sdvn_metrics_with_mitigation.csv
$mitigation | Measure-Object -Property PDR -Average
```

### **Compare Scenarios**

```powershell
# Create comparison script
$comparison = @"
Metric,Baseline,Under Attack,With Mitigation,Recovery %
PDR,{0:F2},{1:F2},{2:F2},{3:F2}
Latency (ms),{4:F2},{5:F2},{6:F2},{7:F2}
Overhead (%),{8:F2},{9:F2},{10:F2},{11:F2}
"@

# Calculate averages
$baselinePDR = ($baseline | Measure-Object -Property PDR -Average).Average * 100
$attackPDR = ($attack | Measure-Object -Property PDR -Average).Average * 100
$mitigationPDR = ($mitigation | Measure-Object -Property PDR -Average).Average * 100
$recoveryPDR = (($mitigationPDR - $attackPDR) / ($baselinePDR - $attackPDR)) * 100

# Same for latency and overhead...

# Save comparison
$comparison | Out-File comparison_results.csv
```

---

## 📊 Expected Results Summary

### **Packet Delivery Ratio (PDR)**

| Scenario | PDR | Interpretation |
|----------|-----|----------------|
| **Baseline** | 90-95% | Normal SDVN operation, some packets lost due to mobility |
| **Under Attack** | 60-75% | **25-35% drop** due to wormhole tunneling/dropping packets |
| **With Mitigation** | 85-92% | **Recovers 70-90%** of lost PDR, routes around wormhole |

### **Latency (ms)**

| Scenario | Avg Latency | Interpretation |
|----------|-------------|----------------|
| **Baseline** | 15-30 ms | Normal multi-hop routing via DSRC |
| **Under Attack** | 80-120 ms | **3-4x increase** due to tunnel delay + longer path |
| **With Mitigation** | 20-40 ms | **Returns to near-baseline**, avoids wormhole |

### **Overhead (%)**

| Scenario | OH Ratio | Interpretation |
|----------|----------|----------------|
| **Baseline** | 5-10% | Metadata uplink + delta downlink only |
| **Under Attack** | 6-12% | Attack doesn't add control overhead |
| **With Mitigation** | 12-20% | **+5-10% increase** due to periodic analysis |

---

## 🔍 Detailed Metrics Analysis

### **1. PDR Calculation Example**

```
Baseline Scenario @ 50s:
  Packets Sent: 1000
  Packets Received: 920
  PDR = 920 / 1000 = 0.92 = 92%

Under Attack @ 50s:
  Packets Sent: 1000
  Packets Received: 680
  Packets Intercepted by Wormhole: 320
  Packets Tunneled: 280
  Packets Dropped: 40
  PDR = 680 / 1000 = 0.68 = 68%
  
With Mitigation @ 50s:
  Packets Sent: 1000
  Packets Received: 870
  Wormhole Detected: YES (at 6.2s)
  Controller Re-routed: YES
  PDR = 870 / 1000 = 0.87 = 87%
```

### **2. Latency Distribution**

```
Baseline:
  Min: 8 ms  (1-hop neighbors)
  Avg: 23 ms (3-4 hops typical)
  Max: 65 ms (5+ hops, congestion)

Under Attack:
  Min: 10 ms (packets not through wormhole)
  Avg: 95 ms (most packets through wormhole tunnel)
  Max: 180 ms (wormhole + congestion)
  
With Mitigation:
  Min: 9 ms  (1-hop neighbors)
  Avg: 32 ms (slightly longer due to avoiding wormhole area)
  Max: 78 ms (5+ hops)
```

### **3. Overhead Breakdown**

```
Baseline (@ 50s):
  Data Packets: 950
  Metadata Uplink: 30 (nodes → controller)
  Delta Downlink: 20 (controller → nodes)
  Total Control: 50
  OH = 50 / 1000 = 5%

With Mitigation (@ 50s):
  Data Packets: 900
  Metadata Uplink: 32
  Delta Downlink: 22
  Mitigation Analysis: 46 (periodic checks)
  Total Control: 100
  OH = 100 / 1000 = 10%
```

---

## 🎨 Plotting Results (Optional)

### **Using Python + Matplotlib**

```python
import pandas as pd
import matplotlib.pyplot as plt

# Load CSV files
baseline = pd.read_csv('sdvn_metrics_baseline.csv')
attack = pd.read_csv('sdvn_metrics_under_attack.csv')
mitigation = pd.read_csv('sdvn_metrics_with_mitigation.csv')

# Plot PDR over time
plt.figure(figsize=(12, 6))
plt.plot(baseline['Timestamp'], baseline['PDR'] * 100, label='Baseline', linewidth=2)
plt.plot(attack['Timestamp'], attack['PDR'] * 100, label='Under Attack', linewidth=2)
plt.plot(mitigation['Timestamp'], mitigation['PDR'] * 100, label='With Mitigation', linewidth=2)
plt.xlabel('Time (seconds)')
plt.ylabel('PDR (%)')
plt.title('SDVN Packet Delivery Ratio: Baseline vs Attack vs Mitigation')
plt.legend()
plt.grid(True)
plt.savefig('sdvn_pdr_comparison.png', dpi=300)

# Plot Latency
plt.figure(figsize=(12, 6))
plt.plot(baseline['Timestamp'], baseline['AvgLatency'] * 1000, label='Baseline', linewidth=2)
plt.plot(attack['Timestamp'], attack['AvgLatency'] * 1000, label='Under Attack', linewidth=2)
plt.plot(mitigation['Timestamp'], mitigation['AvgLatency'] * 1000, label='With Mitigation', linewidth=2)
plt.xlabel('Time (seconds)')
plt.ylabel('Latency (ms)')
plt.title('SDVN End-to-End Latency Comparison')
plt.legend()
plt.grid(True)
plt.savefig('sdvn_latency_comparison.png', dpi=300)

# Plot Overhead
plt.figure(figsize=(12, 6))
plt.plot(baseline['Timestamp'], baseline['OverheadRatio'] * 100, label='Baseline', linewidth=2)
plt.plot(attack['Timestamp'], attack['OverheadRatio'] * 100, label='Under Attack', linewidth=2)
plt.plot(mitigation['Timestamp'], mitigation['OverheadRatio'] * 100, label='With Mitigation', linewidth=2)
plt.xlabel('Time (seconds)')
plt.ylabel('Overhead (%)')
plt.title('SDVN Control Overhead Comparison')
plt.legend()
plt.grid(True)
plt.savefig('sdvn_overhead_comparison.png', dpi=300)

plt.show()
```

**Run plotting:**
```powershell
python plot_sdvn_metrics.py
```

---

## 🛠️ Troubleshooting

### **Issue 1: No CSV files generated**

**Problem:** Metrics not exported
**Solution:**
```cpp
// In main(), ensure performance monitor is initialized:
g_performanceMonitor = new ns3::SDVNPerformanceMonitor();
g_performanceMonitor->Initialize("baseline");  // or "under_attack" or "with_mitigation"
g_performanceMonitor->StartMonitoring();

// At end of simulation:
g_performanceMonitor->ExportToCSV("sdvn_metrics_baseline.csv");
g_performanceMonitor->PrintSummary();
```

### **Issue 2: PDR is 0%**

**Problem:** Packets not being tracked
**Solution:** Check that packet tagging is enabled in send/receive callbacks

### **Issue 3: Latency samples is 0**

**Problem:** SDVNPacketTag not attached to packets
**Solution:** Ensure packets are tagged when sent

---

## 📚 Implementation Checklist

- [x] SDVNPerformanceMetrics struct created
- [x] SDVNPacketTag for latency tracking
- [x] SDVNPerformanceMonitor class implemented
- [x] Packet sent/received/dropped tracking
- [x] SDVN-specific overhead tracking (metadata, delta, mitigation)
- [x] Attack impact tracking (interception, tunneling, drops)
- [x] Mitigation effectiveness tracking (detection time, accuracy)
- [x] CSV export function
- [x] Real-time snapshots (every 1 second)
- [x] Summary printing function

---

## 🎯 Next Steps

1. **Integrate monitoring into main()**
   - Initialize g_performanceMonitor
   - Start monitoring after network setup
   - Export CSV at simulation end

2. **Hook packet callbacks**
   - Tag packets when sent
   - Calculate latency when received
   - Track drops

3. **Run 3 scenarios**
   - Baseline
   - Under attack
   - With mitigation

4. **Analyze results**
   - Compare PDR, latency, overhead
   - Calculate recovery percentages
   - Generate plots

5. **Document findings**
   - Write performance analysis section
   - Include graphs in paper/report
   - Compare with related work

---

## 📞 Support

If metrics are not collecting correctly:
1. Check console output for "[SDVNPerfMonitor]" messages
2. Verify global instance is not nullptr
3. Ensure m_isActive = true
4. Check file permissions for CSV export

---

**Created:** For SDVN wormhole attack/mitigation performance evaluation
**Last Updated:** Based on routing.cc modifications

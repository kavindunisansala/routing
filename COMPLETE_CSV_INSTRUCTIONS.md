# Complete Instructions to Generate CSV Files

This guide provides **step-by-step instructions** to compile, run, and generate all CSV files from the VANET routing simulation.

---

## 📋 Prerequisites

1. **ns-3.35** installed at: `/home/kanisa/Downloads/ns-allinone-3.35/ns-3.35/`
2. **routing.cc** file in the scratch directory
3. Terminal access (Linux/Windows PowerShell)

---

## 🔨 Step 1: Compile the Code

### On Linux:
```bash
cd /home/kanisa/Downloads/ns-allinone-3.35/ns-3.35
./waf
```

### On Windows (PowerShell):
```powershell
cd "d:\routing - Copy"
./waf
```

**Expected Output:**
```
Waf: Entering directory `.../ns-3.35/build'
[2835/2885] Compiling scratch/routing.cc
[2885/2885] Linking build/scratch/routing
Waf: Leaving directory `.../ns-3.35/build'
'build' finished successfully (XX.XXXs)
```

✅ **If compilation succeeds, proceed to Step 2**

❌ **If compilation fails:**
- Check the error message
- Verify routing.cc is in the scratch directory
- Ensure all dependencies are installed

---

## 📊 Step 2: Run Simulations to Generate CSV Files

You can generate **5 different CSV files** depending on which features you enable.

---

### 🎯 Scenario 1: All CSV Files (Recommended)

**Generate all 5 CSV files at once:**

```bash
./waf --run "routing \
  --enable_wormhole_attack=true \
  --enable_wormhole_detection=true \
  --enable_wormhole_mitigation=true \
  --enable_blackhole_attack=true \
  --enable_blackhole_mitigation=true \
  --enable_packet_tracking=true \
  --simTime=10"
```

**Windows PowerShell version:**
```powershell
./waf --run "routing --enable_wormhole_attack=true --enable_wormhole_detection=true --enable_wormhole_mitigation=true --enable_blackhole_attack=true --enable_blackhole_mitigation=true --enable_packet_tracking=true --simTime=10"
```

**CSV Files Generated:**
1. ✅ `wormhole-attack-results.csv`
2. ✅ `wormhole-detection-results.csv`
3. ✅ `blackhole-attack-results.csv`
4. ✅ `blackhole-mitigation-results.csv`
5. ✅ `packet-delivery-analysis.csv`

**Console Output at End:**
```
========== CSV FILES GENERATED ==========
  ✓ wormhole-attack-results.csv
  ✓ wormhole-detection-results.csv
  ✓ blackhole-attack-results.csv
  ✓ blackhole-mitigation-results.csv
  ✓ packet-delivery-analysis.csv
=========================================
```

---

### 🎯 Scenario 2: Wormhole Attack Only

**Generate wormhole attack CSV:**

```bash
./waf --run "routing --enable_wormhole_attack=true --simTime=10"
```

**CSV Files Generated:**
- ✅ `wormhole-attack-results.csv`

**Contains:**
- Tunnel information (Node1, Node2)
- Packets tunneled/dropped
- Attack timing

---

### 🎯 Scenario 3: Wormhole Attack + Detection

**Generate wormhole attack and detection CSVs:**

```bash
./waf --run "routing \
  --enable_wormhole_attack=true \
  --enable_wormhole_detection=true \
  --enable_wormhole_mitigation=true \
  --simTime=10"
```

**CSV Files Generated:**
- ✅ `wormhole-attack-results.csv`
- ✅ `wormhole-detection-results.csv`

**Detection CSV Contains:**
- Total flows monitored
- Flows affected by wormhole
- Detection rate
- Latency analysis
- Mitigation actions (route changes, blacklisted nodes)

---

### 🎯 Scenario 4: Blackhole Attack Only

**Generate blackhole attack CSV:**

```bash
./waf --run "routing --enable_blackhole_attack=true --blackhole_attack_percentage=0.15 --simTime=10"
```

**CSV Files Generated:**
- ✅ `blackhole-attack-results.csv`

**Contains:**
- Malicious node IDs
- Packets dropped per node
- Attack timing

---

### 🎯 Scenario 5: Blackhole Attack + Mitigation

**Generate blackhole attack and mitigation CSVs:**

```bash
./waf --run "routing \
  --enable_blackhole_attack=true \
  --enable_blackhole_mitigation=true \
  --blackhole_pdr_threshold=0.5 \
  --simTime=10"
```

**CSV Files Generated:**
- ✅ `blackhole-attack-results.csv`
- ✅ `blackhole-mitigation-results.csv`

**Mitigation CSV Contains:**
- Per-node statistics (packets sent/delivered/dropped)
- Packet Delivery Ratio (PDR)
- Blacklisted nodes
- Blacklist timing

---

### 🎯 Scenario 6: Detailed Packet Tracking

**Generate detailed per-packet analysis:**

```bash
./waf --run "routing --enable_packet_tracking=true --simTime=10"
```

**CSV Files Generated:**
- ✅ `packet-delivery-analysis.csv`

**Contains:**
- PacketID, SourceNode, DestNode
- SendTime, ReceiveTime, DelayMs
- Delivered (0/1)
- WormholeOnPath (0/1)
- BlackholeOnPath (0/1)

---

### 🎯 Scenario 7: Performance Comparison (Recommended for Analysis)

**Run THREE times to compare performance:**

#### 7a. Baseline (No Attack)
```bash
./waf --run "routing --enable_packet_tracking=true --simTime=10"
mv packet-delivery-analysis.csv baseline.csv
```

#### 7b. With Wormhole Attack
```bash
./waf --run "routing --enable_wormhole_attack=true --enable_packet_tracking=true --simTime=10"
mv packet-delivery-analysis.csv wormhole_attack.csv
```

#### 7c. With Attack + Mitigation
```bash
./waf --run "routing --enable_wormhole_attack=true --enable_wormhole_detection=true --enable_wormhole_mitigation=true --enable_packet_tracking=true --simTime=10"
mv packet-delivery-analysis.csv wormhole_mitigated.csv
```

**Now compare:**
- `baseline.csv` vs `wormhole_attack.csv` → Shows attack impact
- `wormhole_attack.csv` vs `wormhole_mitigated.csv` → Shows mitigation effectiveness

---

## 📁 Step 3: Locate the CSV Files

### On Linux:
```bash
cd /home/kanisa/Downloads/ns-allinone-3.35/ns-3.35
ls -lh *.csv
```

### On Windows:
```powershell
cd "d:\routing - Copy"
dir *.csv
```

**Files will be in the simulation directory:**
- `/home/kanisa/Downloads/ns-allinone-3.35/ns-3.35/` (Linux)
- `d:\routing - Copy\` (Windows)

---

## 🔍 Step 4: View CSV Files

### Using Command Line:

**Linux:**
```bash
# View first 10 rows
head -n 10 wormhole-detection-results.csv

# View all rows
cat wormhole-detection-results.csv

# Count rows
wc -l packet-delivery-analysis.csv
```

**Windows PowerShell:**
```powershell
# View first 10 rows
Get-Content wormhole-detection-results.csv -Head 10

# View all rows
Get-Content wormhole-detection-results.csv

# Count rows
(Get-Content packet-delivery-analysis.csv).Length
```

### Using Excel/LibreOffice:
1. Open Excel/LibreOffice Calc
2. File → Open → Select CSV file
3. Choose comma (,) as delimiter
4. Analyze data with charts/pivot tables

### Using Python (Recommended):
```python
import pandas as pd

# Read CSV
df = pd.read_csv('packet-delivery-analysis.csv')

# Display first rows
print(df.head())

# Calculate PDR
pdr = (df['Delivered'].sum() / len(df)) * 100
print(f"Packet Delivery Ratio: {pdr:.2f}%")

# Calculate average delay
avg_delay = df[df['Delivered'] == 1]['DelayMs'].mean()
print(f"Average Delay: {avg_delay:.2f} ms")

# Count wormhole-affected packets
wormhole_packets = df['WormholeOnPath'].sum()
print(f"Wormhole-affected packets: {wormhole_packets}")
```

---

## 📊 Step 5: Analyze the Data

### CSV File Contents:

#### 1. wormhole-attack-results.csv
```csv
TunnelID,Node1,Node2,TunneledPackets,DroppedPackets,PacketsSent,PacketsReceived,TunnelStartTime,TunnelStopTime,Status
```

#### 2. wormhole-detection-results.csv
```csv
Metric,Value
DetectionEnabled,true
MitigationEnabled,true
LatencyThresholdMultiplier,2.0
BaselineLatency_ms,15.5
TotalFlows,100
FlowsAffected,25
FlowsDetected,23
AffectedPercentage,25.0
AvgNormalLatency_ms,15.5
AvgWormholeLatency_ms,75.2
AvgLatencyIncrease_percent,385
RouteChangesTriggered,10
NodesBlacklisted,4
```

#### 3. blackhole-attack-results.csv
```csv
NodeID,PacketsDropped,PacketsTunneled,IsAttacker,AttackStartTime,AttackStopTime
```

#### 4. blackhole-mitigation-results.csv
```csv
NodeID,PacketsSentVia,PacketsDelivered,PacketsDropped,PDR,Blacklisted,BlacklistTime
```

#### 5. packet-delivery-analysis.csv
```csv
PacketID,SourceNode,DestNode,SendTime,ReceiveTime,DelayMs,Delivered,WormholeOnPath,BlackholeOnPath
```

---

## ⚙️ Step 6: Configuration Options

### Key Parameters:

| Parameter | Default | Description |
|-----------|---------|-------------|
| `--simTime` | 10 | Simulation duration (seconds) |
| `--enable_wormhole_attack` | false | Enable wormhole attack |
| `--enable_wormhole_detection` | false | Enable wormhole detection |
| `--enable_wormhole_mitigation` | false | Enable wormhole mitigation |
| `--enable_blackhole_attack` | false | Enable blackhole attack |
| `--enable_blackhole_mitigation` | false | Enable blackhole mitigation |
| `--enable_packet_tracking` | false | Enable packet tracking |
| `--blackhole_attack_percentage` | 0.15 | Percentage of blackhole nodes (15%) |
| `--blackhole_pdr_threshold` | 0.5 | PDR threshold for blacklisting (50%) |
| `--detection_latency_threshold` | 2.0 | Latency multiplier for wormhole detection |

### Example with Custom Parameters:
```bash
./waf --run "routing \
  --simTime=30 \
  --enable_wormhole_attack=true \
  --enable_wormhole_detection=true \
  --detection_latency_threshold=1.5 \
  --enable_blackhole_attack=true \
  --enable_blackhole_mitigation=true \
  --blackhole_pdr_threshold=0.3 \
  --enable_packet_tracking=true"
```

---

## 🐛 Troubleshooting

### Issue 1: No CSV Files Generated

**Possible Causes:**
- Simulation crashed before completion
- Features not enabled
- Insufficient permissions

**Solution:**
```bash
# Check if simulation completed
./waf --run "routing --enable_packet_tracking=true --simTime=5"

# Check current directory
pwd
ls -lh *.csv
```

### Issue 2: Empty CSV Files

**Possible Causes:**
- Simulation time too short
- No traffic generated
- Attack not triggered

**Solution:**
```bash
# Increase simulation time
./waf --run "routing --enable_packet_tracking=true --simTime=30"
```

### Issue 3: Compilation Errors

**Solution:**
```bash
# Clean build
./waf clean
./waf

# If still fails, check routing.cc syntax
./waf -v
```

### Issue 4: Permission Denied

**Solution:**
```bash
# Make waf executable
chmod +x waf

# Check file permissions
ls -la waf
```

---

## 📈 Quick Analysis Commands

### Calculate Metrics:

**PDR (Packet Delivery Ratio):**
```bash
# Using awk
awk -F',' 'NR>1 {sum+=$7; count++} END {print "PDR:", (sum/count)*100 "%"}' packet-delivery-analysis.csv
```

**Average Delay:**
```bash
# Using awk (only delivered packets)
awk -F',' 'NR>1 && $7==1 {sum+=$6; count++} END {print "Avg Delay:", sum/count "ms"}' packet-delivery-analysis.csv
```

**Count Wormhole-Affected Packets:**
```bash
awk -F',' 'NR>1 && $8==1 {count++} END {print "Wormhole packets:", count}' packet-delivery-analysis.csv
```

---

## 🎯 Summary - Quick Start

### Fastest way to get all CSVs:

```bash
# 1. Navigate to ns-3 directory
cd /home/kanisa/Downloads/ns-allinone-3.35/ns-3.35

# 2. Compile
./waf

# 3. Run with all features enabled
./waf --run "routing --enable_wormhole_attack=true --enable_wormhole_detection=true --enable_wormhole_mitigation=true --enable_blackhole_attack=true --enable_blackhole_mitigation=true --enable_packet_tracking=true --simTime=10"

# 4. Check generated files
ls -lh *.csv

# 5. View summary
echo "=== CSV Files Generated ==="
for f in *.csv; do echo "✓ $f"; done
```

**Expected Output:**
```
✓ wormhole-attack-results.csv
✓ wormhole-detection-results.csv
✓ blackhole-attack-results.csv
✓ blackhole-mitigation-results.csv
✓ packet-delivery-analysis.csv
```

---

## 📚 Additional Resources

- **CSV_EXPORTS_GUIDE.md** - Detailed CSV format documentation
- **CSV_QUICK_REFERENCE.md** - Quick reference guide
- **ENHANCED_MITIGATION_GUIDE.md** - Mitigation system guide

---

## ✅ Checklist

Before running:
- [ ] Code compiled successfully
- [ ] ns-3.35 environment ready
- [ ] Enough disk space for CSV files
- [ ] Simulation parameters configured

After running:
- [ ] Check console output for "CSV FILES GENERATED" message
- [ ] Verify CSV files exist in directory
- [ ] Open CSV files to verify data
- [ ] Analyze results

---

**Need Help?** Check the error messages or review the troubleshooting section above.

**Good luck with your VANET security analysis! 🚗🔒**

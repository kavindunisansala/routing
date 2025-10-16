# 📋 CSV Generation Cheat Sheet

## 🎯 ONE-LINER Commands

### Get ALL 5 CSV Files:
```bash
cd /home/kanisa/Downloads/ns-allinone-3.35/ns-3.35 && ./waf && ./waf --run "routing --enable_wormhole_attack=true --enable_wormhole_detection=true --enable_wormhole_mitigation=true --enable_blackhole_attack=true --enable_blackhole_mitigation=true --enable_packet_tracking=true --simTime=10" && ls -lh *.csv
```

---

## 📊 CSV Files Matrix

| Command Flag | CSV Files Generated | Use Case |
|--------------|---------------------|----------|
| `--enable_wormhole_attack=true` | wormhole-attack-results.csv | Track tunnel activity |
| `--enable_wormhole_detection=true` | wormhole-detection-results.csv | Measure detection effectiveness |
| `--enable_blackhole_attack=true` | blackhole-attack-results.csv | Track packet dropping |
| `--enable_blackhole_mitigation=true` | blackhole-mitigation-results.csv | Measure mitigation effectiveness |
| `--enable_packet_tracking=true` | packet-delivery-analysis.csv | Per-packet analysis |

---

## 🚀 Common Scenarios

### Scenario A: Research Paper - All Attacks
```bash
./waf --run "routing --enable_wormhole_attack=true --enable_wormhole_detection=true --enable_blackhole_attack=true --enable_blackhole_mitigation=true --enable_packet_tracking=true --simTime=10"
```
✅ **5 CSV files**

### Scenario B: Wormhole Analysis Only
```bash
./waf --run "routing --enable_wormhole_attack=true --enable_wormhole_detection=true --enable_packet_tracking=true --simTime=10"
```
✅ **3 CSV files**

### Scenario C: Blackhole Analysis Only
```bash
./waf --run "routing --enable_blackhole_attack=true --enable_blackhole_mitigation=true --enable_packet_tracking=true --simTime=10"
```
✅ **3 CSV files**

### Scenario D: Baseline (No Attack)
```bash
./waf --run "routing --enable_packet_tracking=true --simTime=10"
```
✅ **1 CSV file** (for comparison)

---

## 📁 File Locations

**Linux:** `/home/kanisa/Downloads/ns-allinone-3.35/ns-3.35/*.csv`

**Windows:** `d:\routing - Copy\*.csv`

---

## 🔍 Quick View Commands

```bash
# List all CSV files
ls -lh *.csv

# View first 10 rows
head -n 10 packet-delivery-analysis.csv

# Count rows
wc -l *.csv

# Check file sizes
du -sh *.csv
```

---

## 📊 CSV Contents Quick Reference

### 1️⃣ wormhole-attack-results.csv
```
TunnelID, Node1, Node2, TunneledPackets, DroppedPackets, ...
```

### 2️⃣ wormhole-detection-results.csv
```
Metric, Value
TotalFlows, 100
FlowsDetected, 85
DetectionRate, 85%
```

### 3️⃣ blackhole-attack-results.csv
```
NodeID, PacketsDropped, IsAttacker, AttackStartTime, ...
```

### 4️⃣ blackhole-mitigation-results.csv
```
NodeID, PacketsSentVia, PacketsDelivered, PDR, Blacklisted, ...
```

### 5️⃣ packet-delivery-analysis.csv
```
PacketID, SourceNode, DestNode, SendTime, ReceiveTime, DelayMs, Delivered, WormholeOnPath, BlackholeOnPath
```

---

## 🎨 Color-Coded Status

| Status | Meaning |
|--------|---------|
| 🟢 Delivered=1 | Packet reached destination |
| 🔴 Delivered=0 | Packet dropped |
| 🟠 WormholeOnPath=1 | Packet went through wormhole |
| 🟣 BlackholeOnPath=1 | Packet hit blackhole |

---

## ⚙️ Key Parameters

| Parameter | Default | Range |
|-----------|---------|-------|
| `--simTime` | 10 | 5-300 seconds |
| `--blackhole_attack_percentage` | 0.15 | 0.0-1.0 (0-100%) |
| `--blackhole_pdr_threshold` | 0.5 | 0.0-1.0 (0-100%) |
| `--detection_latency_threshold` | 2.0 | 1.0-5.0 (multiplier) |

---

## 🐛 Error Solutions

| Error | Solution |
|-------|----------|
| `No CSV files` | Check simulation finished successfully |
| `Empty CSV` | Increase `--simTime=30` |
| `Compilation failed` | Run `./waf clean && ./waf` |
| `Permission denied` | Run `chmod +x waf` |

---

## 📈 Analysis Tools

### Excel/LibreOffice:
1. Open CSV file
2. Select comma delimiter
3. Create charts/pivot tables

### Python (Quick):
```python
import pandas as pd
df = pd.read_csv('packet-delivery-analysis.csv')
print(f"PDR: {df['Delivered'].mean()*100:.1f}%")
print(f"Delay: {df[df['Delivered']==1]['DelayMs'].mean():.2f}ms")
```

### Command Line (Quick):
```bash
# PDR
awk -F',' 'NR>1 {sum+=$7; count++} END {print "PDR:", (sum/count)*100 "%"}' packet-delivery-analysis.csv

# Avg Delay
awk -F',' 'NR>1 && $7==1 {sum+=$6; count++} END {print "Delay:", sum/count "ms"}' packet-delivery-analysis.csv
```

---

## ✅ Quick Checklist

- [ ] Compiled: `./waf` (no errors)
- [ ] Run simulation with features enabled
- [ ] Check console for "CSV FILES GENERATED"
- [ ] Verify files exist: `ls *.csv`
- [ ] Check file sizes: `du -sh *.csv`
- [ ] Open files to verify data
- [ ] Ready for analysis!

---

## 📞 Help

**Full Guide:** `COMPLETE_CSV_INSTRUCTIONS.md`

**Quick Start:** `QUICKSTART_CSV.md`

**CSV Details:** `CSV_EXPORTS_GUIDE.md`

---

**💡 Pro Tip:** Run with `--simTime=30` for more data, or `--simTime=5` for quick testing!

# 🚀 Quick Start - Generate All CSV Files

## ⚡ 3-Step Process

### Step 1: Navigate & Compile
```bash
cd /home/kanisa/Downloads/ns-allinone-3.35/ns-3.35
./waf
```

### Step 2: Run Simulation (All Features)
```bash
./waf --run "routing --enable_wormhole_detection --enable_wormhole_mitigation --enable_blackhole_attack --enable_blackhole_mitigation --enable_packet_tracking --simTime=10"
```

### Step 3: Check Files
```bash
ls -lh *.csv
```

---

## 📊 Expected Output

### Console:
```
========== CSV FILES GENERATED ==========
  ✓ wormhole-attack-results.csv
  ✓ wormhole-detection-results.csv
  ✓ blackhole-attack-results.csv
  ✓ blackhole-mitigation-results.csv
  ✓ packet-delivery-analysis.csv
=========================================
```

### Files:
```
-rw-r--r-- 1 user user 5.2K wormhole-attack-results.csv
-rw-r--r-- 1 user user 1.8K wormhole-detection-results.csv
-rw-r--r-- 1 user user 3.4K blackhole-attack-results.csv
-rw-r--r-- 1 user user 2.1K blackhole-mitigation-results.csv
-rw-r--r-- 1 user user 125K packet-delivery-analysis.csv
```

---

## 🎯 What Each CSV Contains

| CSV File | What It Shows |
|----------|---------------|
| **wormhole-attack-results.csv** | Tunnel pairs, packets tunneled/dropped |
| **wormhole-detection-results.csv** | Detection rate, latency analysis, blacklisted nodes |
| **blackhole-attack-results.csv** | Malicious nodes, packets dropped |
| **blackhole-mitigation-results.csv** | Per-node PDR, blacklisted suspects |
| **packet-delivery-analysis.csv** | Every packet's delay, delivery status, attack flags |

---

## 🔧 Alternative Scenarios

### Wormhole Only:
```bash
./waf --run "routing --enable_wormhole_detection --enable_packet_tracking --simTime=10"
```
**Generates:** 3 CSV files

### Blackhole Only:
```bash
./waf --run "routing --enable_blackhole_attack --enable_blackhole_mitigation --enable_packet_tracking --simTime=10"
```
**Generates:** 3 CSV files

### Packet Tracking Only (Baseline):
```bash
./waf --run "routing --enable_packet_tracking --simTime=10"
```
**Generates:** 1 CSV file

---

## 📈 Quick Analysis (Python)

```python
import pandas as pd

# Load packet tracking CSV
df = pd.read_csv('packet-delivery-analysis.csv')

# Calculate key metrics
pdr = (df['Delivered'].sum() / len(df)) * 100
avg_delay = df[df['Delivered']==1]['DelayMs'].mean()
wormhole_packets = df['WormholeOnPath'].sum()

print(f"PDR: {pdr:.1f}%")
print(f"Avg Delay: {avg_delay:.2f} ms")
print(f"Wormhole-affected: {wormhole_packets}")
```

---

## 🆘 Troubleshooting

**No CSV files?**
```bash
# Check if simulation finished
tail -n 20 <simulation_output>
# Look for "CSV FILES GENERATED" message
```

**Compilation error?**
```bash
# Clean and rebuild
./waf clean
./waf
```

**Empty CSV files?**
```bash
# Increase simulation time
./waf --run "routing --enable_packet_tracking --simTime=30"
```

---

## 📚 Detailed Documentation

- **COMPLETE_CSV_INSTRUCTIONS.md** - Full step-by-step guide
- **CSV_EXPORTS_GUIDE.md** - CSV format reference
- **CSV_QUICK_REFERENCE.md** - Quick lookup table

---

## ✅ Done!

You now have 5 CSV files ready for analysis in your research paper! 🎓

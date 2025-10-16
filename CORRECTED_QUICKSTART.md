# ✅ CORRECTED - Quick Start Guide for CSV Generation

## ⚡ IMPORTANT: Command Syntax

**Correct format:** Use flags WITHOUT `=true`
```bash
--enable_packet_tracking    ✅ CORRECT
--enable_packet_tracking=true    ❌ WRONG
```

---

## 🚀 Quick Start - 3 Steps

### Step 1: Navigate & Compile
```bash
cd /home/kanisa/Downloads/ns-allinone-3.35/ns-3.35
./waf
```

### Step 2: Run Simulation (All Features)
```bash
./waf --run "routing --enable_wormhole_detection --enable_wormhole_mitigation --enable_blackhole_attack --enable_blackhole_mitigation --enable_packet_tracking --simTime=10"
```

**Note:** Wormhole attack is ENABLED BY DEFAULT (use_enhanced_wormhole=true)

### Step 3: Check Files
```bash
ls -lh *.csv
```

---

## 📊 Expected Output

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

## 🎯 Common Scenarios

### Scenario 1: ALL CSV Files (Wormhole + Blackhole + Tracking)
```bash
./waf --run "routing --enable_wormhole_detection --enable_wormhole_mitigation --enable_blackhole_attack --enable_blackhole_mitigation --enable_packet_tracking --simTime=10"
```
**Generates:** ✅ All 5 CSV files

### Scenario 2: Wormhole Analysis Only
```bash
./waf --run "routing --enable_wormhole_detection --enable_wormhole_mitigation --enable_packet_tracking --simTime=10"
```
**Generates:** 3 CSV files (wormhole-attack, wormhole-detection, packet-delivery-analysis)

### Scenario 3: Blackhole Analysis Only
```bash
./waf --run "routing --use_enhanced_wormhole=false --enable_blackhole_attack --enable_blackhole_mitigation --enable_packet_tracking --simTime=10"
```
**Generates:** 3 CSV files (blackhole-attack, blackhole-mitigation, packet-delivery-analysis)

**Note:** Use `--use_enhanced_wormhole=false` to disable wormhole (it's ON by default)

### Scenario 4: Baseline (No Attacks)
```bash
./waf --run "routing --use_enhanced_wormhole=false --enable_packet_tracking --simTime=10"
```
**Generates:** 1 CSV file (packet-delivery-analysis only)

### Scenario 5: Wormhole Attack WITHOUT Detection
```bash
./waf --run "routing --enable_wormhole_detection=false --enable_wormhole_mitigation=false --enable_packet_tracking --simTime=10"
```
**Generates:** 2 CSV files (wormhole-attack, packet-delivery-analysis)

---

## 📋 Available Flags Reference

| Flag | Default | Description |
|------|---------|-------------|
| `--use_enhanced_wormhole` | **true** | Enable wormhole attack (ON by default!) |
| `--enable_wormhole_detection` | **true** | Enable wormhole detection (ON by default!) |
| `--enable_wormhole_mitigation` | **true** | Enable wormhole mitigation (ON by default!) |
| `--enable_blackhole_attack` | **false** | Enable blackhole attack |
| `--enable_blackhole_mitigation` | **false** | Enable blackhole mitigation |
| `--enable_packet_tracking` | **false** | Enable packet tracking |
| `--simTime` | 10 | Simulation time in seconds |

---

## 🔧 To Disable Wormhole

**If you want NO wormhole attack:**
```bash
./waf --run "routing --use_enhanced_wormhole=false --enable_blackhole_attack --enable_packet_tracking --simTime=10"
```

---

## 📁 CSV Files Generated

| Condition | CSV File |
|-----------|----------|
| Wormhole enabled (default) | `wormhole-attack-results.csv` |
| `--enable_wormhole_detection` | `wormhole-detection-results.csv` |
| `--enable_blackhole_attack` | `blackhole-attack-results.csv` |
| `--enable_blackhole_mitigation` | `blackhole-mitigation-results.csv` |
| `--enable_packet_tracking` | `packet-delivery-analysis.csv` |

---

## 🐛 Troubleshooting

### "Invalid command-line arguments"
**Problem:** Used `=true` syntax
**Solution:** Remove `=true`, just use flag name:
```bash
# ❌ WRONG
--enable_packet_tracking=true

# ✅ CORRECT
--enable_packet_tracking
```

### No CSV files generated
**Problem:** Simulation didn't complete
**Solution:** Check console output for errors

### Empty CSV files
**Problem:** Simulation time too short
**Solution:**
```bash
./waf --run "routing --enable_packet_tracking --simTime=30"
```

---

## 📈 Quick Analysis

### View CSV in terminal:
```bash
# First 10 rows
head -n 10 packet-delivery-analysis.csv

# Count rows
wc -l packet-delivery-analysis.csv

# Search for delivered packets
grep ",1," packet-delivery-analysis.csv | wc -l
```

### Python analysis:
```python
import pandas as pd

df = pd.read_csv('packet-delivery-analysis.csv')
pdr = (df['Delivered'].sum() / len(df)) * 100
avg_delay = df[df['Delivered']==1]['DelayMs'].mean()

print(f"PDR: {pdr:.1f}%")
print(f"Avg Delay: {avg_delay:.2f} ms")
```

---

## ✅ One-Liner (Copy-Paste Ready)

```bash
cd /home/kanisa/Downloads/ns-allinone-3.35/ns-3.35 && ./waf && ./waf --run "routing --enable_wormhole_detection --enable_wormhole_mitigation --enable_blackhole_attack --enable_blackhole_mitigation --enable_packet_tracking --simTime=10" && ls -lh *.csv
```

**This command:**
1. Navigates to ns-3 directory
2. Compiles the code
3. Runs with all features enabled
4. Generates all 5 CSV files
5. Lists the files

---

## 🎓 Ready for Research!

You now have all 5 CSV files for your VANET security analysis paper! 🚗🔒

**Files Generated:**
1. ✅ `wormhole-attack-results.csv` - Tunnel activity
2. ✅ `wormhole-detection-results.csv` - Detection metrics
3. ✅ `blackhole-attack-results.csv` - Packet drops
4. ✅ `blackhole-mitigation-results.csv` - Mitigation effectiveness
5. ✅ `packet-delivery-analysis.csv` - Per-packet details

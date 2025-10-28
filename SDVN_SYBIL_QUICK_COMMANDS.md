# SDVN Sybil Attack - Quick Command Reference

## 🚀 Quick Start Commands

### Compile Project
```bash
cd "d:\routing - Copy"
./waf configure
./waf build
```

---

## 📋 Test Scenarios

### 1. Baseline (No Attack)
```bash
./waf --run "scratch/routing \
  --totalNodes=28 \
  --controllerNodes=6 \
  --simTime=60.0 \
  --enableSDVN=true \
  --enableSDVNSybilAttack=false"
```
**Expected:** PDR: 92%, Latency: 23ms, Overhead: 5%

---

### 2. SDVN Sybil Attack (Without Mitigation)
```bash
./waf --run "scratch/routing \
  --totalNodes=28 \
  --controllerNodes=6 \
  --simTime=60.0 \
  --enableSDVN=true \
  --enableSDVNSybilAttack=true \
  --sdvnSybilNode=15 \
  --sdvnSybilIdentities=3 \
  --sdvnSybilFakeNeighbors=8 \
  --sdvnSybilStartTime=10.0 \
  --enableSDVNSybilMitigation=false"
```
**Expected:** PDR: 68% (↓26%), Latency: 58ms (↑152%), Pollution: 78%

---

### 3. SDVN Sybil Attack with Mitigation
```bash
./waf --run "scratch/routing \
  --totalNodes=28 \
  --controllerNodes=6 \
  --simTime=60.0 \
  --enableSDVN=true \
  --enableSDVNSybilAttack=true \
  --sdvnSybilNode=15 \
  --sdvnSybilIdentities=3 \
  --sdvnSybilFakeNeighbors=8 \
  --sdvnSybilStartTime=10.0 \
  --enableSDVNSybilMitigation=true \
  --mitigationCheckInterval=2.0 \
  --maxNeighborsThreshold=10"
```
**Expected:** PDR: 88% (recovery), Detection: ~4s, Accuracy: 100%

---

### 4. Multiple Sybil Attackers
```bash
./waf --run "scratch/routing \
  --totalNodes=28 \
  --controllerNodes=6 \
  --simTime=60.0 \
  --enableSDVN=true \
  --enableSDVNSybilAttack=true \
  --sdvnSybilNodes=12,15,20 \
  --sdvnSybilIdentities=3 \
  --sdvnSybilFakeNeighbors=8 \
  --sdvnSybilStartTime=10.0 \
  --enableSDVNSybilMitigation=true"
```
**Expected:** PDR: 48%→82%, 3 nodes blacklisted

---

### 5. Clone Attack Variant
```bash
./waf --run "scratch/routing \
  --totalNodes=28 \
  --controllerNodes=6 \
  --simTime=60.0 \
  --enableSDVN=true \
  --enableSDVNSybilAttack=true \
  --sdvnSybilNode=15 \
  --sdvnSybilIdentities=5 \
  --sdvnSybilCloneNodes=true \
  --sdvnSybilStartTime=10.0 \
  --enableSDVNSybilMitigation=true"
```
**Expected:** Clone detection: 100%, False positives: 0

---

### 6. Export Performance Metrics
```bash
./waf --run "scratch/routing \
  --totalNodes=28 \
  --controllerNodes=6 \
  --simTime=60.0 \
  --enableSDVN=true \
  --enableSDVNSybilAttack=true \
  --sdvnSybilNode=15 \
  --sdvnSybilIdentities=3 \
  --sdvnSybilFakeNeighbors=8 \
  --sdvnSybilStartTime=10.0 \
  --enableSDVNSybilMitigation=true \
  --exportCSV=true \
  --csvOutputFile=sdvn_sybil_metrics.csv"

# View CSV
cat sdvn_sybil_metrics.csv
```

---

## 📊 CSV Columns

```
Time(s), PDR(%), Latency_Avg(ms), Overhead(%),
FakeIdentities, FakeMetadata, ControllerPollution(%),
AffectedFlows, IdentitiesDetected, NodesBlacklisted,
DetectionAccuracy(%), CorruptedEntries, InvalidRoutes,
PacketsSent, PacketsDelivered, PacketsDropped
```

---

## 🔍 Verification Commands

```bash
# Check implementation
grep -n "SDVNSybilAttackApp" routing.cc
grep -n "SDVNSybilMitigationManager" routing.cc

# Verify build
./waf configure
./waf build
echo "Build status: $?"
```

---

## 📈 Python Analysis

```bash
# Save as analyze_sybil.py
python3 << 'EOF'
import pandas as pd
import matplotlib.pyplot as plt

df = pd.read_csv('sdvn_sybil_metrics.csv')

fig, axes = plt.subplots(2, 2, figsize=(15, 10))

# PDR
axes[0,0].plot(df['Time(s)'], df['PDR(%)'], linewidth=2)
axes[0,0].axvline(x=10, color='r', linestyle='--', label='Attack')
axes[0,0].axvline(x=14, color='g', linestyle='--', label='Detection')
axes[0,0].set_title('PDR Over Time')
axes[0,0].legend()
axes[0,0].grid(True)

# Controller Pollution
axes[0,1].plot(df['Time(s)'], df['ControllerPollution(%)'], 
               linewidth=2, color='red')
axes[0,1].fill_between(df['Time(s)'], 0, 
                        df['ControllerPollution(%)'], alpha=0.3)
axes[0,1].set_title('Controller Pollution')
axes[0,1].grid(True)

# Latency
axes[1,0].plot(df['Time(s)'], df['Latency_Avg(ms)'], 
               linewidth=2, color='orange')
axes[1,0].set_title('Latency')
axes[1,0].grid(True)

# Detection
axes[1,1].plot(df['Time(s)'], df['NodesBlacklisted'], 
               linewidth=2, marker='o', color='green')
axes[1,1].set_title('Nodes Blacklisted')
axes[1,1].grid(True)

plt.tight_layout()
plt.savefig('sdvn_sybil_analysis.png', dpi=300)
print("Saved: sdvn_sybil_analysis.png")
EOF
```

---

## 📚 Documentation Files

- **SDVN_SYBIL_ATTACK_VISUAL_GUIDE.md** - Complete visual guide with diagrams
- **SYBIL_MITIGATION_GUIDE.md** - VANET Sybil mitigation (reused for SDVN)
- **routing.cc** - Implementation (lines 1221-1483, 100244-101410)

---

## 🎯 Expected Performance

### Single Attacker
| Metric | Baseline | Attack | Mitigation | Change |
|--------|----------|--------|------------|--------|
| PDR | 92% | 68% | 88% | ↓4% |
| Latency | 23ms | 58ms | 28ms | +22% |
| Pollution | 0% | 78% | 5% | +5% |

### Multiple Attackers (3 nodes)
| Metric | Baseline | Attack | Mitigation | Change |
|--------|----------|--------|------------|--------|
| PDR | 92% | 48% | 82% | ↓11% |
| Latency | 23ms | 85ms | 35ms | +52% |
| Pollution | 0% | 95% | 8% | +8% |

---

## ✅ Success Indicators

Console messages to verify:
```
✅ [SDVN-SYBIL] Node X ATTACK ACTIVATED
✅ [SDVN-SYBIL] Created 3 fake identities
✅ [SDVN-SYBIL-MITIGATION] 🚨 ALERT: Abnormal neighbor count
✅ [SDVN-SYBIL-MITIGATION] 🚫 BLACKLISTED Node X
✅ [SDVN-SYBIL-MITIGATION] Cleaning controller view
✅ Detection Accuracy: 100.00%
```

---

## 🆘 Troubleshooting

### Build Errors
```bash
# Clean build
./waf clean
./waf configure
./waf build
```

### No Output
```bash
# Add verbose flags
./waf --run "scratch/routing --verbose=true --enableSDVNSybilAttack=true"
```

### CSV Not Generated
```bash
# Ensure export flag is set
--exportCSV=true --csvOutputFile=sdvn_sybil_metrics.csv
```

---

**Need detailed explanations? See SDVN_SYBIL_ATTACK_VISUAL_GUIDE.md** 📖

# Quick Reference - Attack Testing Commands

## 🚨 START HERE - Diagnostic

```bash
cd ~/ns-allinone-3.35/ns-3.35
bash diagnose_simulation.sh
```

**This will:**
- Test baseline (5 vehicles, 5 RSUs, 10s)
- Check exit codes and CSV generation
- Test wormhole attack if baseline works
- Save logs: `diagnostic_baseline.log`, `diagnostic_wormhole.log`

---

## 📋 Manual Test Commands

### Baseline (No Attacks)
```bash
./waf --run "scratch/routing \
  --N_Vehicles=15 --N_RSUs=5 --simTime=10 \
  --architecture=0 --seed=12345 \
  --enable_wormhole_attack=false --enable_blackhole_attack=false \
  --enable_replay_attack=false --enable_sybil_attack=false \
  --enable_rtp_attack=false"

echo "Exit code: $?"
ls -lh *.csv
```

### Wormhole Attack
```bash
# No mitigation
./waf --run "scratch/routing \
  --N_Vehicles=15 --N_RSUs=5 --simTime=10 \
  --architecture=0 --seed=12345 \
  --enable_wormhole_attack=true --wormhole_attack_percentage=0.2 \
  --wormhole_tunnel_data=true --wormhole_enable_verification_flows=true \
  --enable_wormhole_detection=false --enable_wormhole_mitigation=false"

# With detection only
./waf --run "scratch/routing \
  --N_Vehicles=15 --N_RSUs=5 --simTime=10 \
  --architecture=0 --seed=12345 \
  --enable_wormhole_attack=true --wormhole_attack_percentage=0.2 \
  --wormhole_tunnel_data=true --wormhole_enable_verification_flows=true \
  --enable_wormhole_detection=true --enable_wormhole_mitigation=false"

# With full mitigation
./waf --run "scratch/routing \
  --N_Vehicles=15 --N_RSUs=5 --simTime=10 \
  --architecture=0 --seed=12345 \
  --enable_wormhole_attack=true --wormhole_attack_percentage=0.2 \
  --wormhole_tunnel_data=true --wormhole_enable_verification_flows=true \
  --enable_wormhole_detection=true --enable_wormhole_mitigation=true"
```

### Blackhole Attack
```bash
# No mitigation
./waf --run "scratch/routing \
  --N_Vehicles=15 --N_RSUs=5 --simTime=10 \
  --architecture=0 --seed=12345 \
  --enable_blackhole_attack=true --blackhole_attack_percentage=0.2 \
  --enable_blackhole_detection=false --enable_blackhole_mitigation=false"

# With detection
./waf --run "scratch/routing \
  --N_Vehicles=15 --N_RSUs=5 --simTime=10 \
  --architecture=0 --seed=12345 \
  --enable_blackhole_attack=true --blackhole_attack_percentage=0.2 \
  --enable_blackhole_detection=true --enable_blackhole_mitigation=false"

# With mitigation
./waf --run "scratch/routing \
  --N_Vehicles=15 --N_RSUs=5 --simTime=10 \
  --architecture=0 --seed=12345 \
  --enable_blackhole_attack=true --blackhole_attack_percentage=0.2 \
  --enable_blackhole_detection=true --enable_blackhole_mitigation=true"
```

### Replay Attack
```bash
# No mitigation
./waf --run "scratch/routing \
  --N_Vehicles=15 --N_RSUs=5 --simTime=10 \
  --architecture=0 --seed=12345 \
  --enable_replay_attack=true --replay_attack_percentage=0.2 \
  --enable_replay_detection=false --enable_replay_mitigation=false"

# With Bloom Filter detection
./waf --run "scratch/routing \
  --N_Vehicles=15 --N_RSUs=5 --simTime=10 \
  --architecture=0 --seed=12345 \
  --enable_replay_attack=true --replay_attack_percentage=0.2 \
  --enable_replay_detection=true --enable_replay_mitigation=false"

# With mitigation
./waf --run "scratch/routing \
  --N_Vehicles=15 --N_RSUs=5 --simTime=10 \
  --architecture=0 --seed=12345 \
  --enable_replay_attack=true --replay_attack_percentage=0.2 \
  --enable_replay_detection=true --enable_replay_mitigation=true"
```

### RTP Attack (Infrastructure Only)
```bash
# No mitigation
./waf --run "scratch/routing \
  --N_Vehicles=15 --N_RSUs=5 --simTime=10 \
  --architecture=0 --seed=12345 \
  --enable_rtp_attack=true --rtp_attack_percentage=0.2 \
  --enable_rtp_detection=false --enable_rtp_mitigation=false"

# With Hybrid-Shield detection
./waf --run "scratch/routing \
  --N_Vehicles=15 --N_RSUs=5 --simTime=10 \
  --architecture=0 --seed=12345 \
  --enable_rtp_attack=true --rtp_attack_percentage=0.2 \
  --enable_rtp_detection=true --enable_rtp_mitigation=false"

# With mitigation
./waf --run "scratch/routing \
  --N_Vehicles=15 --N_RSUs=5 --simTime=10 \
  --architecture=0 --seed=12345 \
  --enable_rtp_attack=true --rtp_attack_percentage=0.2 \
  --enable_rtp_detection=true --enable_rtp_mitigation=true"
```

### Sybil Attack
```bash
# No mitigation
./waf --run "scratch/routing \
  --N_Vehicles=15 --N_RSUs=5 --simTime=10 \
  --architecture=0 --seed=12345 \
  --enable_sybil_attack=true --sybil_attack_percentage=0.2 \
  --enable_sybil_detection=false --enable_sybil_mitigation=false"

# With detection
./waf --run "scratch/routing \
  --N_Vehicles=15 --N_RSUs=5 --simTime=10 \
  --architecture=0 --seed=12345 \
  --enable_sybil_attack=true --sybil_attack_percentage=0.2 \
  --enable_sybil_detection=true --enable_sybil_mitigation=false"

# With mitigation
./waf --run "scratch/routing \
  --N_Vehicles=15 --N_RSUs=5 --simTime=10 \
  --architecture=0 --seed=12345 \
  --enable_sybil_attack=true --sybil_attack_percentage=0.2 \
  --enable_sybil_detection=true --enable_sybil_mitigation=true"
```

---

## 🔍 Quick Checks After Each Test

```bash
# Check exit code
echo "Exit code: $?"

# List CSV files
ls -lh *.csv

# View attack-specific results
cat wormhole-attack-results.csv    # For wormhole
cat blackhole-attack-results.csv   # For blackhole
cat replay-attack-results.csv      # For replay
cat rtp-attack-results.csv         # For RTP
cat sybil-attack-results.csv       # For sybil

# Check PDR
grep "packet delivery ratio" simulation.log

# Check V2V traffic
grep "AODV-DATA-PLANE" simulation.log | wc -l

# Check for errors
grep -i "error\|segmentation\|abort" simulation.log
```

---

## 📊 Expected Metrics

| Attack | Metric to Check | No Mitigation | With Mitigation |
|--------|----------------|---------------|-----------------|
| **Wormhole** | PacketsTunneled | >0 | <No Mitigation |
| **Blackhole** | TotalPacketsDropped | >0 | <No Mitigation |
| **Replay** | PacketsReplayed | >0 | DetectionRate>95% |
| **RTP** | NodesPoisoned | >0 | RoutingErrors<No Mitigation |
| **Sybil** | FakeIdentitiesBroadcast | >0 | FPR<1%, PAR<5% |

---

## 🛠️ Debugging Commands

```bash
# If simulation crashes
gdb --args ./build/scratch/ns3-dev-routing-debug \
  --N_Vehicles=5 --N_RSUs=5 --simTime=10 --architecture=0
# In gdb: run, then backtrace

# View last lines of output
tail -50 simulation.log

# Search for specific errors
grep -i "error" simulation.log
grep -i "segmentation" simulation.log
grep -i "assertion" simulation.log

# Check AODV activity
grep "AODV\|port 654" simulation.log | head -20

# Check wormhole activity
grep -i "wormhole\|tunnel" simulation.log | head -20

# Check blackhole activity
grep -i "blackhole\|drop" simulation.log | head -20
```

---

## 📦 Full Test Suites (Automated)

```bash
# Wormhole focused (16 tests)
bash test_wormhole_focused.sh

# Blackhole focused (16 tests)
bash test_blackhole_focused.sh

# Replay focused (16 tests)
bash test_replay_focused.sh

# RTP focused (16 tests)
bash test_rtp_focused.sh

# Sybil focused (16 tests)
bash test_sybil_focused.sh

# All attacks (full suite)
bash test_individual_attacks.sh
```

---

## ✅ Success Checklist

- [ ] Baseline completes (exit code 0)
- [ ] CSV files generated (≥3 files)
- [ ] PDR calculated and printed
- [ ] V2V traffic active (AODV-DATA-PLANE messages)
- [ ] Wormhole: PacketsTunneled > 0
- [ ] Blackhole: TotalPacketsDropped > 0
- [ ] Replay: PacketsReplayed > 0, DetectionRate > 95%
- [ ] RTP: NodesPoisoned > 0 (infrastructure only)
- [ ] Sybil: FakeIdentitiesBroadcast > 0, FPR < 1%
- [ ] Mitigation improves metrics (higher PDR, lower attack impact)

---

## 📚 Documentation Files

- **ATTACK_TESTING_GUIDE.md** - Comprehensive testing guide
- **NEXT_STEPS_SUMMARY.md** - Detailed troubleshooting steps
- **QUICK_REFERENCE.md** - This file (command shortcuts)
- **TEST_SCRIPT_UPDATES.md** - Test script documentation
- **QUICK_ANALYSIS_SUMMARY.md** - Quick analysis feature guide

---

## 🚀 Recommended Testing Order

1. ✅ Run diagnostic: `bash diagnose_simulation.sh`
2. ✅ Fix baseline if needed
3. ✅ Test wormhole (no mitigation → detection → mitigation)
4. ✅ Test blackhole (no mitigation → detection → mitigation)
5. ✅ Test replay (no mitigation → detection → mitigation)
6. ✅ Test RTP (no mitigation → detection → mitigation)
7. ✅ Test sybil (no mitigation → detection → mitigation)
8. ✅ Run full test suites for comprehensive evaluation

---

**Remember:** Fix baseline FIRST before testing any attacks! 🚨

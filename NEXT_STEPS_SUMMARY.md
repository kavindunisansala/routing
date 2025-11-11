# Attack Testing - Next Steps Summary

## Current Situation

### ✅ What's Done
- **V2V unicast traffic added** to Architecture 0 in routing.cc
- **Code compiled successfully** with `./waf build`
- **Test scripts updated** with quick analysis for all attacks
- **Simulations running** but exiting with non-zero codes

### ❌ Current Problem
- **Tests report "Failed"** even though simulations appear to run
- **No CSV files generated** (packet-delivery-analysis.csv, wormhole-attack-results.csv, etc.)
- **Simulation logs incomplete** - stop abruptly without final metrics
- **Exit code non-zero** - causes test scripts to report failure

### 🔍 What We Need to Determine
1. **Is the simulation crashing?** (segfault, assertion failure)
2. **Is the simulation timing out?** (killed by OS/shell)
3. **Is the CSV writing code not executing?** (logic error)
4. **Are metrics calculations completing?** (should print "packet delivery ratio is X")

---

## Immediate Next Steps (Run on Linux Machine)

### Step 1: Diagnose the Root Cause 🚨 PRIORITY

```bash
# On your Linux machine (eie@ist105):
cd ~/ns-allinone-3.35/ns-3.35

# Make scripts executable
chmod +x quick_baseline_test.sh
chmod +x diagnose_simulation.sh

# Run diagnostic (most comprehensive)
bash diagnose_simulation.sh
```

**This will test:**
- ✅ Minimal baseline (5 vehicles, 5 RSUs, 10s, no attacks)
- ✅ Exit code check
- ✅ CSV file generation
- ✅ V2V traffic verification (AODV-DATA-PLANE messages)
- ✅ Wormhole attack (if baseline succeeds)
- ✅ Error detection in logs

**Expected Output:**
- If baseline works: "✓ BASELINE WORKS" → Proceed to attack testing
- If baseline fails: "✗ BASELINE FAILED" → Debug routing.cc first

---

### Step 2A: If Baseline Works → Test Wormhole Attack

```bash
cd ~/ns-allinone-3.35/ns-3.35

# Test wormhole with 20% attackers (no mitigation)
./waf --run "scratch/routing \
  --N_Vehicles=15 \
  --N_RSUs=5 \
  --simTime=10 \
  --pause_time=0 \
  --architecture=0 \
  --seed=12345 \
  --enable_wormhole_attack=true \
  --wormhole_attack_percentage=0.2 \
  --wormhole_tunnel_data=true \
  --wormhole_enable_verification_flows=true \
  --enable_wormhole_detection=false \
  --enable_wormhole_mitigation=false"

# Check exit code
echo "Exit code: $?"

# Check for CSV files
ls -lh *.csv

# Verify wormhole metrics
cat wormhole-attack-results.csv
```

**Success Criteria:**
- ✅ Exit code = 0
- ✅ wormhole-attack-results.csv exists
- ✅ PacketsTunneled > 0
- ✅ PacketsIntercepted > 0

**If PacketsTunneled = 0:**
```bash
# Check if AODV packets exist
grep "AODV\|port 654" simulation.log | head -20

# Check if wormhole is monitoring
grep -i "wormhole" simulation.log | head -20
```

---

### Step 2B: If Baseline Fails → Debug routing.cc

#### Check for Segmentation Faults

```bash
cd ~/ns-allinone-3.35/ns-3.35

# Run with gdb to catch crash location
gdb --args ./build/scratch/ns3-dev-routing-debug \
  --N_Vehicles=5 --N_RSUs=5 --simTime=10 --architecture=0

# In gdb, type:
(gdb) run

# If it crashes:
(gdb) backtrace
(gdb) list
```

#### Check Last Lines of Log

```bash
# See where simulation stops
tail -50 baseline_output.log

# Look for specific errors
grep -i "error\|abort\|segmentation\|assertion\|terminate" baseline_output.log
```

#### Check Array Bounds Issues

The simulation shows `ns3::total_size=80` but `actual_total_nodes=20`. If there's an array indexing bug in the new V2V code, it could crash.

**Potential Issue in routing.cc:**
```cpp
// In Architecture 0 configuration (lines ~152316-152324)
for (double t=1.00; t<simTime-1; t=t+data_transmission_period)
{
    srand(data_transmission_frequency*t);
    uint32_t destination = rand()%(actual_total_nodes - 2);  // ← Could this be wrong?
    cout<<"[AODV-DATA-PLANE] destination id: "<<destination+2<<endl;
    Simulator::Schedule (Seconds (t+0.10), send_distributed_packets, destination);
    ...
}
```

**Check:**
- Is `destination+2` exceeding `actual_total_nodes`?
- Is `send_distributed_packets(destination)` expecting a different index range?

---

### Step 3: Once Baseline Works → Systematic Attack Testing

Use the **ATTACK_TESTING_GUIDE.md** for step-by-step instructions:

#### 3.1 Wormhole Attack (Full Suite)
```bash
cd ~/ns-allinone-3.35/ns-3.35
bash test_wormhole_focused.sh
```

#### 3.2 Blackhole Attack
```bash
bash test_blackhole_focused.sh
```

#### 3.3 Replay Attack
```bash
bash test_replay_focused.sh
```

#### 3.4 RTP Attack (Infrastructure only)
```bash
bash test_rtp_focused.sh
```

#### 3.5 Sybil Attack
```bash
bash test_sybil_focused.sh
```

---

## Common Issues & Fixes

### Issue 1: Simulation Runs But No CSV Files

**Symptom:** Logs show activity but no CSV files generated

**Fix:** Check if CSV writing code is being called:
```bash
grep -i "csv\|writing.*results\|saving" simulation.log
```

If no matches, the metrics calculation/writing functions may not be executing. Check routing.cc for:
- `print_results()` function
- CSV file writing code at simulation end
- Ensure it's called after `Simulator::Run()` and before `Simulator::Destroy()`

### Issue 2: PacketsTunneled = 0 (Wormhole)

**Symptom:** Wormhole attack enabled but no packets intercepted

**Diagnosis:**
```bash
# 1. Check AODV traffic
grep "AODV-DATA-PLANE" simulation.log | wc -l
# Should be > 0 (V2V unicast scheduled)

# 2. Check port 654 packets
grep "port 654\|AODV packet" simulation.log | wc -l
# Should be > 0 (AODV RREQ/RREP)

# 3. Check wormhole monitoring
grep -i "wormhole.*monitor\|intercept\|tunnel" simulation.log | wc -l
# Should be > 0 (wormhole active)
```

**Fix:** If AODV-DATA-PLANE = 0, the V2V traffic isn't being scheduled. Check routing.cc lines ~152316-152324.

### Issue 3: TotalPacketsDropped = 0 (Blackhole)

**Symptom:** Blackhole enabled but no packets dropped

**Diagnosis:**
```bash
# Check if blackhole nodes designated
grep -i "blackhole.*attacker\|node.*blackhole" simulation.log

# Check if packets route through blackholes
grep "route.*blackhole\|forward.*drop" simulation.log
```

**Fix:** Ensure blackhole nodes are in the routing paths. May need to adjust topology or increase attack percentage.

### Issue 4: Exit Code 137 (Killed)

**Symptom:** Simulation killed by OS

**Cause:** Out of memory or timeout

**Fix:**
```bash
# Reduce simulation size
--N_Vehicles=5  # Instead of 60
--simTime=10  # Instead of 60

# Or increase memory limit
ulimit -v unlimited
```

---

## Files Created

### Documentation
- **ATTACK_TESTING_GUIDE.md** - Comprehensive testing guide for all attacks
- **NEXT_STEPS_SUMMARY.md** - This file

### Diagnostic Scripts
- **diagnose_simulation.sh** - Full diagnostic (baseline + wormhole)
- **quick_baseline_test.sh** - Minimal baseline test

### Usage
```bash
# Make executable
chmod +x diagnose_simulation.sh quick_baseline_test.sh

# Run diagnostics
bash diagnose_simulation.sh

# Or quick baseline only
bash quick_baseline_test.sh
```

---

## Expected Timeline

### Phase 1: Diagnose (15 minutes)
1. Run `bash diagnose_simulation.sh`
2. Review output and logs
3. Identify whether baseline works or fails

### Phase 2A: If Baseline Works (2-3 hours)
1. Test wormhole attack (no mitigation)
2. Test wormhole with detection
3. Test wormhole with mitigation
4. Repeat for blackhole, replay, RTP, sybil

### Phase 2B: If Baseline Fails (1-2 hours)
1. Debug routing.cc with gdb
2. Fix segfault/crash
3. Recompile: `./waf build`
4. Retry baseline
5. Once working → Phase 2A

---

## Success Criteria

### Baseline Success ✅
- Exit code: 0
- CSV files: ≥3 files (packet-delivery-analysis.csv, metrics_summary.csv, etc.)
- PDR: >90%
- AODV traffic: >0 destinations scheduled
- No errors in log

### Wormhole Success ✅
- Exit code: 0
- PacketsTunneled: >0
- PacketsIntercepted: >0
- Latency anomalies: detected
- wormhole-attack-results.csv: populated

### Full Test Suite Success ✅
- All 5 attacks tested (wormhole, blackhole, replay, RTP, sybil)
- Each attack: no mitigation → with detection → with mitigation
- All CSV files generated
- Metrics make sense (PDR decreases with attacks, improves with mitigation)

---

## How to Share Results

After running tests, share:

1. **Exit codes**
   ```bash
   echo "Baseline exit code: $?"
   ```

2. **CSV files**
   ```bash
   ls -lh *.csv
   cat wormhole-attack-results.csv
   ```

3. **Key log sections**
   ```bash
   # First 30 lines (config)
   head -30 simulation.log
   
   # Last 30 lines (results)
   tail -30 simulation.log
   
   # AODV traffic
   grep "AODV-DATA-PLANE" simulation.log | head -10
   ```

4. **Metrics**
   ```bash
   grep "packet delivery ratio\|PacketsTunneled\|DetectionRate" simulation.log
   ```

---

## Key Questions to Answer

1. **Does baseline simulation complete successfully?**
   - Exit code 0?
   - CSV files generated?
   - PDR calculated?

2. **Is V2V unicast traffic working?**
   - AODV-DATA-PLANE messages in log?
   - send_distributed_packets called?

3. **For wormhole: Are AODV packets being generated?**
   - Port 654 activity?
   - RREQ/RREP packets?

4. **For wormhole: Is interception happening?**
   - PacketsTunneled > 0?
   - Wormhole logs visible?

---

## Next Actions

### 🚨 IMMEDIATE (Do Now)
```bash
cd ~/ns-allinone-3.35/ns-3.35
bash diagnose_simulation.sh
```

### 📊 AFTER DIAGNOSIS (Based on Results)
- **If baseline works** → Follow ATTACK_TESTING_GUIDE.md Phase 2+
- **If baseline fails** → Debug routing.cc with gdb

### 📝 REPORTING
- Share `diagnose_simulation.sh` output
- Share any error messages
- Share exit codes and CSV file listings

---

Good luck with testing! The diagnostic script will tell us exactly what's working and what needs to be fixed. 🚀

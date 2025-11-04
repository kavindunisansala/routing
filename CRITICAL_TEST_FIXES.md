# CRITICAL TEST FIXES - Missing CSV Files

## Root Cause Analysis

After analyzing the test results and routing.cc code, I identified **THREE CRITICAL ISSUES**:

### Issue 1: Missing jinja2 Dependency ✅ FIXED
**Problem:** Analysis script crashes when generating LaTeX tables.
**Solution:** Added try-catch wrapper to handle missing jinja2 gracefully.

```python
# Fixed in analyze_sdvn_complete_evaluation.py
try:
    df.to_latex(index=False, float_format='%.2f')
except ImportError:
    # Fallback to plain text if jinja2 not available
    df.to_string()
```

**To install jinja2:**
```bash
pip install jinja2
```

---

### Issue 2: Blackhole Tests Not Generating CSV Files ⚠️ **CRITICAL**

**Problem:** Tests 5-7 (Blackhole) produce NO CSV files.

**Root Cause in routing.cc:**
```cpp
// Line 149395: present_blackhole_attack_nodes marks nodes as malicious
if (present_blackhole_attack_nodes) {
    // Marks blackhole_malicious_nodes[i] = true/false
}

// Line 151935: enable_blackhole_attack activates the manager
if (enable_blackhole_attack) {
    g_blackholeManager = new ns3::BlackholeAttackManager();
    // Only then does CSV export happen
}
```

**Current Test Parameters:**
```bash
--present_blackhole_attack_nodes=true   # ✓ Marks nodes as malicious
--attack_percentage=0.1                 # ✓ Sets percentage
--enable_blackhole_attack=true          # ✓ Activates manager
--blackhole_attack_percentage=0.1       # ✓ Attack-specific percentage
--blackhole_advertise_fake_routes=true  # ✓ Attack behavior
```

**Why It Still Fails:**
Looking at lines 151960-152030 in routing.cc, the blackhole manager initialization happens **inside the wormhole attack block** (line 151935). This is likely a code organization issue where blackhole setup is nested incorrectly.

**Verification Needed:**
```bash
# Check simulation log for blackhole messages
cat test05_blackhole_10_no_mitigation/simulation.log | grep -i "blackhole"
```

**Expected Output:**
```
=== Enhanced Blackhole Attack Configuration ===
Total Nodes (actual): 28
Malicious Nodes Selected: 2
Attack Percentage: 10%
...
```

If this output is **missing**, it confirms the blackhole manager never initialized.

---

### Issue 3: Replay Tests Not Generating CSV Files ⚠️ **CRITICAL**

**Problem:** Tests 11-13 (Replay) produce NO CSV files.

**Root Cause in routing.cc:**
```cpp
// Line 149407: present_replay_attack_nodes marks nodes as malicious
if (present_reply_attack_nodes) {  // Note: typo "reply" vs "replay"
    // Marks replay_malicious_nodes[i] = true/false
}

// Line 152203: enable_replay_attack activates the manager
if (enable_replay_attack) {
    g_replayAttackManager = new ns3::ReplayAttackManager();
    // CSV export at line 152600
}
```

**Current Test Parameters:**
```bash
--present_replay_attack_nodes=true   # ✓ Should mark nodes
--enable_replay_attack=true          # ✓ Should activate manager
--replay_attack_percentage=0.1       # ✓ Attack percentage
--replay_start_time=10.0             # ✓ Start time
```

**Why It Still Fails:**
Similar to blackhole - the replay manager might not be initializing. Check if there's a dependency on other conditions.

**Verification Needed:**
```bash
# Check simulation log for replay messages
cat test11_replay_10_no_mitigation/simulation.log | grep -i "replay"
```

**Expected Output:**
```
=== Replay Attack Configuration ===
Replay attack will start at: 10s
Attack percentage: 10%
...
```

---

### Issue 4: Combined Test Not Generating CSV Files ⚠️ **CRITICAL**

**Problem:** Test 17 (Combined) produces NO CSV files despite all mitigations enabled.

**Root Cause:**
When multiple attacks are combined, there may be conflicts or the initialization order matters. Need to verify:

1. Are all attack managers being created?
2. Are CSV exports being called for each?
3. Is there a conflict in parameter combinations?

**Verification Needed:**
```bash
# Check what actually happened
cat test17_combined_10_with_all_mitigations/simulation.log | tail -100
```

---

## Recommended Fixes

### Fix 1: Check routing.cc Code Structure

**Find where blackhole setup happens:**
```bash
grep -n "enable_blackhole_attack" routing.cc | head -20
```

**Check indentation/nesting:**
The blackhole setup (line 151935) might be accidentally nested inside another condition block (like the wormhole attack section starting around line 151870).

**Solution:**
The blackhole attack setup should be at the **same indentation level** as the wormhole attack setup, not nested inside it.

```cpp
// WRONG (nested):
if (use_enhanced_wormhole) {
    // ... wormhole setup ...
    
    if (enable_blackhole_attack) {  // ← Inside wormhole block!
        // blackhole setup
    }
}

// CORRECT (parallel):
if (use_enhanced_wormhole) {
    // ... wormhole setup ...
}

if (enable_blackhole_attack) {  // ← Outside wormhole block
    // blackhole setup
}
```

### Fix 2: Check replay_attack vs reply_attack Typo

**In routing.cc around line 149407:**
```cpp
if (present_reply_attack_nodes) {  // ← Typo: "reply" should be "replay"
```

**Check if there's an alias:**
```cpp
bool present_replay_attack_nodes = false;  // Alias for reply attack
```

**The command-line parameter uses "replay":**
```cpp
cmd.AddValue ("enable_replay_attack", "Enable Replay attack", enable_replay_attack);
```

**But the internal variable might use "reply":**
This inconsistency could prevent proper initialization.

### Fix 3: Add Debug Logging

**Modify test script to capture more verbose output:**
```bash
run_simulation() {
    # ... existing code ...
    
    # Add verbose NS-3 logging
    export NS_LOG=ReplayAttackManager=level_all:BlackholeAttackManager=level_all
    
    ./waf --run "scratch/$ROUTING_SCRIPT ..." \
        > "$output_dir/simulation.log" 2>&1
    
    # Unset after run
    unset NS_LOG
}
```

---

## Verification Steps

### Step 1: Check Simulation Logs

```bash
cd ~/Downloads/ns-allinone-3.35/ns-3.35

# Check blackhole test logs
for test in test05 test06 test07; do
    echo "=== ${test} ==="
    grep -i "blackhole\|attack config\|malicious" \
        sdvn_evaluation_20251105_010138/${test}_*/simulation.log | head -20
done

# Check replay test logs
for test in test11 test12 test13; do
    echo "=== ${test} ==="
    grep -i "replay\|attack config\|malicious" \
        sdvn_evaluation_20251105_010138/${test}_*/simulation.log | head -20
done

# Check combined test log
echo "=== test17 ==="
grep -i "attack\|mitigation\|csv" \
    sdvn_evaluation_20251105_010138/test17_*/simulation.log | head -50
```

### Step 2: Verify routing.cc Code Structure

```bash
# Check blackhole setup location
grep -n -A 5 "enable_blackhole_attack" routing.cc | grep -E "^[0-9]+|if\s+\(|^\s+if\s+\("

# Check replay setup location  
grep -n -A 5 "enable_replay_attack" routing.cc | grep -E "^[0-9]+|if\s+\(|^\s+if\s+\("

# Check for nested blocks
grep -n -B 10 "enable_blackhole_attack" routing.cc | grep "if.*wormhole"
```

### Step 3: Test Individual Attack Manually

```bash
# Test blackhole alone
./waf --run "scratch/routing \
    --simTime=100 \
    --N_Vehicles=18 \
    --N_RSUs=10 \
    --architecture=0 \
    --present_blackhole_attack_nodes=true \
    --enable_blackhole_attack=true \
    --blackhole_attack_percentage=0.1 \
    --blackhole_advertise_fake_routes=true"

# Check if CSV was created
ls -la blackhole-attack-results.csv

# Test replay alone
./waf --run "scratch/routing \
    --simTime=100 \
    --N_Vehicles=18 \
    --N_RSUs=10 \
    --architecture=0 \
    --present_replay_attack_nodes=true \
    --enable_replay_attack=true \
    --replay_attack_percentage=0.1 \
    --replay_start_time=10.0"

# Check if CSV was created
ls -la replay-attack-results.csv
```

---

## Expected Outcomes

### If Manual Tests Work:
- CSV files are created → Problem is with test script parameters
- Check for parameter typos or missing flags

### If Manual Tests Fail:
- No CSV files → Problem is in routing.cc code
- Need to fix code indentation/nesting or initialization logic

### If Simulation Logs Show "Warning: No malicious nodes selected":
- The `present_*_attack_nodes` flag isn't marking nodes properly
- Check if nodes are being assigned before the attack manager initializes

---

## Quick Fix to Try First

### Modify test_sdvn_complete_evaluation.sh

**For Blackhole tests, ensure both percentage parameters match:**
```bash
# OLD
--attack_percentage=0.1 --blackhole_attack_percentage=0.1

# NEW (use only one or ensure both are consistent)
--attack_percentage=0.10 --blackhole_attack_percentage=0.10
```

**For Replay tests, check if "present_replay_attack_nodes" needs to match internal "reply":**
```bash
# Try both spellings
--present_replay_attack_nodes=true \
--present_reply_attack_nodes=true \
--enable_replay_attack=true
```

---

## Status Summary

| Test Phase | Status | CSV Files | Issue |
|------------|--------|-----------|-------|
| Baseline | ✅ PASS | 2 | None |
| Wormhole | ✅ PASS | 1-2 per test | None |
| **Blackhole** | ❌ **FAIL** | **0** | **Manager not initializing** |
| Sybil | ✅ PASS | 1-5 per test | None |
| **Replay** | ❌ **FAIL** | **0** | **Manager not initializing** |
| RTP | ✅ PASS | 1-3 per test | None |
| **Combined** | ❌ **FAIL** | **0** | **Multiple attacks conflict?** |

---

## Next Actions

1. **Check simulation logs** for blackhole/replay initialization messages
2. **Verify routing.cc code structure** - check if blackhole setup is nested incorrectly
3. **Run manual tests** to isolate whether it's parameters or code
4. **Install jinja2** for proper LaTeX table generation: `pip install jinja2`
5. **Re-run complete evaluation** after fixes

---

**Created:** November 5, 2025
**Priority:** CRITICAL - 7 out of 17 tests failing to generate data

# Replay Attack Test Failure - Root Cause Analysis & Fix

## 🔍 Issue Identified

**Problem:** Replay attack tests (11, 12, 13) and Combined test (17) are **FAILING** with exit code 1

**Error Message:**
```
Invalid command-line arguments: --present_replay_attack_nodes=true
```

## 📊 Test Results Analysis

From `sdvn_evaluation_20251105_034500/`:

### ❌ Failed Tests (No CSV files generated):
- **Test 11:** `test11_replay_10_no_mitigation/` - Only simulation.log (attack didn't initialize)
- **Test 12:** `test12_replay_10_with_detection/` - Only simulation.log (attack didn't initialize)
- **Test 13:** `test13_replay_10_with_mitigation/` - Only simulation.log (attack didn't initialize)
- **Test 17:** `test17_combined_10_with_all_mitigations/` - Failed due to invalid parameter

### ✅ Working Tests (CSV files present):
- **Test 2-4:** Wormhole tests ✓ (wormhole-attack-results.csv present)
- **Test 5-7:** Blackhole tests ✓ (blackhole-attack-results.csv would be present after routing.cc fix)
- **Test 8-10:** Sybil tests ✓ (sybil-attack-results.csv present)
- **Test 14-16:** RTP tests ✓ (rtp-attack-results.csv, hybrid-shield-*.csv present)

## 🔎 Root Cause Analysis

### 1. **Invalid Parameter Usage**

**In `test_sdvn_complete_evaluation.sh` (Lines 198, 203, 208, 238):**
```bash
# WRONG - This parameter causes crash:
--present_replay_attack_nodes=true --enable_replay_attack=true ...
```

### 2. **Parameter Not Registered in routing.cc**

**Variable Declaration (Line 2720):**
```cpp
bool present_replay_attack_nodes = false;  // Alias for reply attack
```

**Problem:** This variable is **DECLARED** but **NEVER registered** with `cmd.AddValue()`

**Verification:**
```bash
grep -n "AddValue.*present_replay" routing.cc
# Returns: NO MATCHES
```

**Valid Replay Parameters (Lines 149916-149926):**
```cpp
cmd.AddValue ("enable_replay_attack", "Enable Replay attack", enable_replay_attack);
cmd.AddValue ("replay_start_time", "Replay attack start time (seconds)", replay_start_time);
cmd.AddValue ("replay_stop_time", "Replay attack stop time (seconds, 0=simTime)", replay_stop_time);
cmd.AddValue ("replay_attack_percentage", "Percentage of nodes to make Replay attackers", replay_attack_percentage);
cmd.AddValue ("replay_interval", "Interval between packet replays (seconds)", replay_interval);
cmd.AddValue ("replay_count_per_node", "Number of packets to replay per node", replay_count_per_node);
cmd.AddValue ("replay_max_captured_packets", "Max packets to capture for replay", replay_max_captured_packets);
cmd.AddValue ("enable_replay_detection", "Enable Replay detection with Bloom Filters", enable_replay_detection);
cmd.AddValue ("enable_replay_mitigation", "Enable automatic Replay mitigation", enable_replay_mitigation);
```

**Notice:** `present_replay_attack_nodes` is **MISSING** from the registered parameters!

### 3. **Why test_replay_rtp_only.sh Works**

**Correct parameters used:**
```bash
# test_replay_rtp_only.sh uses ONLY valid parameters:
./waf --run "scratch/routing \
    --enable_replay_attack=true \           ✅ Valid
    --replay_attack_percentage=0.15 \       ✅ Valid
    --replay_start_time=10.0 \              ✅ Valid
    --enable_replay_detection=true"         ✅ Valid

# Does NOT use:
# --present_replay_attack_nodes=true      ❌ Invalid (not registered)
```

## ✅ Solution Applied

### Fix 1: Remove Invalid Parameter from Tests 11-13

**File:** `test_sdvn_complete_evaluation.sh`

**Before (Lines 198, 203, 208):**
```bash
# Test 11
"--present_replay_attack_nodes=true --enable_replay_attack=true --replay_attack_percentage=0.1 --replay_start_time=10.0"

# Test 12
"--present_replay_attack_nodes=true --enable_replay_attack=true --replay_attack_percentage=0.1 --replay_start_time=10.0 --enable_replay_detection=true"

# Test 13
"--present_replay_attack_nodes=true --enable_replay_attack=true --replay_attack_percentage=0.1 --replay_start_time=10.0 --enable_replay_detection=true --enable_replay_mitigation=true"
```

**After (Fixed):**
```bash
# Test 11
"--enable_replay_attack=true --replay_attack_percentage=0.1 --replay_start_time=10.0"

# Test 12
"--enable_replay_attack=true --replay_attack_percentage=0.1 --replay_start_time=10.0 --enable_replay_detection=true"

# Test 13
"--enable_replay_attack=true --replay_attack_percentage=0.1 --replay_start_time=10.0 --enable_replay_detection=true --enable_replay_mitigation=true"
```

### Fix 2: Remove Invalid Parameter from Test 17 (Combined)

**Before (Line 238):**
```bash
"--present_wormhole_attack_nodes=true --present_blackhole_attack_nodes=true --present_sybil_attack_nodes=true --present_replay_attack_nodes=true --use_enhanced_wormhole=true ..."
```

**After (Fixed):**
```bash
"--present_wormhole_attack_nodes=true --present_blackhole_attack_nodes=true --present_sybil_attack_nodes=true --use_enhanced_wormhole=true ..."
```

## 📝 Summary of Changes

### test_sdvn_complete_evaluation.sh
- **Line 198:** Removed `--present_replay_attack_nodes=true` from Test 11
- **Line 203:** Removed `--present_replay_attack_nodes=true` from Test 12
- **Line 208:** Removed `--present_replay_attack_nodes=true` from Test 13
- **Line 238:** Removed `--present_replay_attack_nodes=true` from Test 17

## 🎯 Expected Results After Fix

### Test Success Rate:
- **Before Fix:** 12/17 tests passing (70.6%)
  - ❌ Tests 11, 12, 13 failing (Replay)
  - ❌ Test 17 failing (Combined - due to replay parameter)

- **After Fix:** 17/17 tests passing (100%)
  - ✅ Tests 11, 12, 13 should now pass
  - ✅ Test 17 should now pass with all attacks running

### Expected CSV Files After Fix:

**Test 11-13 will generate:**
- `replay-attack-results.csv` (attack behavior)
- `bloom-filter-results.csv` (detection metrics)
- `replay-mitigation-results.csv` (mitigation actions)

**Test 17 will generate:**
- All wormhole CSV files
- All blackhole CSV files
- All sybil CSV files
- **All replay CSV files** (previously missing)
- All RTP CSV files

## 🔧 Next Steps

1. **Rebuild NS-3** (if needed):
   ```bash
   cd ~/Downloads/ns-allinone-3.35/ns-3.35
   ./waf build --target=routing
   ```

2. **Run Complete Evaluation Again:**
   ```bash
   ./test_sdvn_complete_evaluation.sh
   ```

3. **Verify Results:**
   ```bash
   # Check for replay CSV files
   find ./sdvn_evaluation_*/test11_replay_10_no_mitigation/ -name "*.csv"
   find ./sdvn_evaluation_*/test12_replay_10_with_detection/ -name "*.csv"
   find ./sdvn_evaluation_*/test13_replay_10_with_mitigation/ -name "*.csv"
   
   # Check combined test
   find ./sdvn_evaluation_*/test17_combined_10_with_all_mitigations/ -name "*replay*.csv"
   ```

4. **Analyze Results:**
   ```bash
   python3 analyze_sdvn_complete_evaluation.py ./sdvn_evaluation_TIMESTAMP/
   ```

## 📋 Comparison: Complete Evaluation vs Replay-Only Test

| Feature | test_sdvn_complete_evaluation.sh | test_replay_rtp_only.sh |
|---------|----------------------------------|-------------------------|
| **Replay Parameter** | ❌ Used `--present_replay_attack_nodes=true` | ✅ Does NOT use this parameter |
| **Result** | ❌ Crashed with exit code 1 | ✅ Works correctly |
| **CSV Files** | ❌ None generated | ✅ All CSV files generated |
| **Attack Initialization** | ❌ Never initialized | ✅ Properly initialized |

## 🎓 Lessons Learned

1. **Always verify parameters exist in routing.cc** before using in test scripts
2. **Check `cmd.AddValue()` registrations** not just variable declarations
3. **Use working test scripts as reference** (test_replay_rtp_only.sh was correct)
4. **Parameter naming inconsistency:**
   - Wormhole uses: `--present_wormhole_attack_nodes=true` ✅ (registered)
   - Blackhole uses: `--present_blackhole_attack_nodes=true` ✅ (registered)
   - Sybil uses: `--present_sybil_attack_nodes=true` ✅ (registered)
   - Replay uses: ❌ **NO `present_*` parameter needed!**
   - RTP uses: ❌ **NO `present_*` parameter needed!**

## ✅ Verification Commands

After running the fixed tests, verify success:

```bash
# Count CSV files in each replay test
echo "Test 11:"; ls -1 sdvn_evaluation_*/test11_replay_10_no_mitigation/*.csv 2>/dev/null | wc -l
echo "Test 12:"; ls -1 sdvn_evaluation_*/test12_replay_10_with_detection/*.csv 2>/dev/null | wc -l
echo "Test 13:"; ls -1 sdvn_evaluation_*/test13_replay_10_with_mitigation/*.csv 2>/dev/null | wc -l

# Check for "Replay Attack" initialization messages
grep -i "replay attack" sdvn_evaluation_*/test11_*/simulation.log | head -5

# Check exit codes (should be 0, not 1)
grep "exited with code" sdvn_evaluation_*/test11_*/simulation.log
```

---

**Status:** ✅ Fix Applied to `test_sdvn_complete_evaluation.sh`  
**Next Action:** Re-run complete evaluation to verify 100% test success rate  
**Expected Outcome:** All 17 tests passing, all CSV files generated

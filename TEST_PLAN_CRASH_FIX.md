# Test Plan for Crash Fix (Commit df5402f)

## Overview
This guide helps you test the crash fix that was applied to prevent null pointer dereference at 1.0348s.

## What Was Fixed
Added defensive guards to 4 path-finding functions to prevent crashes when matrices are not initialized:
- `run_stable_path_finding()`
- `update_stable()`
- `update_unstable()`  
- `run_distance_path_finding()`

Plus added CSV file error handling in `read_lifetime_from_csv()`.

---

## Quick Test Procedure

### 1. Pull Latest Code (Linux VM)
```bash
cd ~/Downloads/ns-allinone-3.35/ns-3.35/scratch
wget -O routing.cc https://raw.githubusercontent.com/kavindunisansala/routing/master/routing.cc
```

### 2. Rebuild
```bash
cd ~/Downloads/ns-allinone-3.35/ns-3.35
./waf build 2>&1 | tee build.log
```

### 3. Run 30-Second Test
```bash
./waf --run "routing --use_enhanced_wormhole=true --simTime=30" 2>&1 | tee test-30s.log
```

### 4. Quick Validation
```bash
# Check exit code (should be 0)
echo $?

# Check for crash message (should be none)
grep "dereference zero pointer" test-30s.log

# Check if simulation completed
grep "Simulator finished" test-30s.log

# Check if wormhole CSV created
ls -lh wormhole-attack-results.csv
```

---

## Expected Results

### ✅ SUCCESS - What You Should See:

1. **Build completes successfully**
2. **Simulation runs to completion** (30 seconds)
3. **No crash at 1.0348s** (previous crash point)
4. **CSV file created**: `wormhole-attack-results.csv`
5. **Path-finding messages** like:
   ```
   updating flows - path finding at1.0348
   Routing distance-based: Number of paths from source: X to destination Y is Z at timestamp 1.0348
   ```

### ⚠️ EXPECTED WARNINGS (These Are OK):

You might see warnings like:
```
WARNING: linklifetimeMatrix_dsrc not ready yet (size=0, need 28), skipping path finding for flow 0
```

**This is normal** - it means path-finding was called before CSV files loaded, but the code handled it gracefully instead of crashing.

### ❌ FAILURE - What to Report:

1. **Still crashes** with "Attempted to dereference zero pointer"
2. **Segmentation fault**
3. **Build errors**
4. **Simulation stops prematurely**

---

## Detailed Test Cases

### Test 1: Basic 30s Simulation
```bash
./waf --run "routing --use_enhanced_wormhole=true --simTime=30" 2>&1 | tee test1.log
```
**Goal**: Verify crash is fixed

### Test 2: Extended 60s Simulation
```bash
./waf --run "routing --use_enhanced_wormhole=true --simTime=60" 2>&1 | tee test2.log
```
**Goal**: Verify stability over longer duration

### Test 3: Without Wormhole
```bash
./waf --run "routing --use_enhanced_wormhole=false --simTime=30" 2>&1 | tee test3.log
```
**Goal**: Baseline comparison

### Test 4: Check Matrix Initialization
```bash
./waf --run "routing --simTime=30" 2>&1 | tee test4.log
grep -E "reading lifetime from csv|link lifetime matrix converted" test4.log
```
**Goal**: Verify CSV loading works

---

## Log Analysis Commands

### Find Warnings (Expected)
```bash
grep -i "WARNING" test-30s.log
```

### Find Errors (Should Be None)
```bash
grep -i "ERROR" test-30s.log
```

### Check Path-Finding Calls
```bash
grep "updating flows - path finding" test-30s.log
```

### Check Matrix Status
```bash
grep -E "reading lifetime|matrix converted" test-30s.log
```

### Verify Wormhole Activity
```bash
grep -i "wormhole" test-30s.log | head -20
```

---

## Interpreting Results

### Scenario A: Clean Run (Best Case)
```
✓ Build successful
✓ Simulation completes 30s
✓ No warnings or errors
✓ wormhole-attack-results.csv exists
✓ Path-finding messages in log
```
**Meaning**: Everything working perfectly! CSV files loaded before path-finding.

---

### Scenario B: Warnings But No Crash (Good Case)
```
✓ Build successful
✓ Simulation completes 30s
⚠ Warnings about matrices not ready
✓ wormhole-attack-results.csv exists
✓ Path-finding messages in log
```
**Meaning**: Path-finding called before CSV loaded, but guards prevented crash. Simulation recovered and continued normally.

**Why warnings?**
- Path-finding scheduled at +0.00005s
- CSV reading scheduled at +0.0001s
- First path-finding call happens before data ready
- Guards detect this and return early
- Later calls succeed after CSV loads

**Action**: This is acceptable behavior. If you want to eliminate warnings, you could adjust scheduling times in code.

---

### Scenario C: CSV Missing (Acceptable)
```
✓ Build successful
✓ Simulation completes 30s
⚠ ERROR: Cannot open lifetime CSV file
⚠ Warnings about matrices not ready (persist)
✓ wormhole-attack-results.csv exists
```
**Meaning**: CSV files for path-finding don't exist, but simulation continues safely.

**Why?**
- Code expects files like `link_lifetime_solution.csv` in scratch directory
- If missing, `read_lifetime_from_csv()` prints error and returns
- Guards in path-finding functions detect empty matrices and skip processing
- Wormhole attack still works (doesn't depend on path-finding CSVs)

**Action**: 
1. If path-finding is important, generate/provide CSV files
2. If only testing wormhole, you can ignore these warnings

---

### Scenario D: Still Crashes (Failure)
```
✗ Simulation crashes
✗ "Attempted to dereference zero pointer" error
```
**Meaning**: Bug exists in a code path not covered by guards.

**Action Needed**:
1. Get full error message
2. Run with gdb to get backtrace:
   ```bash
   ./waf --run "routing --simTime=30" --command-template="gdb --args %s"
   # In gdb:
   (gdb) run
   # When it crashes:
   (gdb) backtrace
   (gdb) frame 0
   (gdb) print current_hop
   (gdb) print total_size
   ```
3. Share crash details

---

## Verification Checklist

Before reporting results, verify:

- [x] Pulled latest code (commit df5402f)
- [ ] Build succeeded
- [ ] Simulation ran for full duration
- [ ] No "dereference zero pointer" crash
- [ ] wormhole-attack-results.csv created
- [ ] CSV contains data (not empty)
- [ ] Recorded any warning messages
- [ ] Saved full log output

---

## What the CSV Should Contain

Check wormhole results:
```bash
cat wormhole-attack-results.csv
```

**Expected format** (example):
```
Timestamp,PacketsCaptured,PacketsTunneled,BytesCaptured,BytesTunneled
0.500000,12,10,18000,15000
1.000000,28,23,42000,34500
1.500000,45,36,67500,54000
...
```

**Key indicators**:
- Timestamp increases
- Packet counts increase over time
- Tunneled packets < Captured packets (some selectivity)

---

## Advanced Debugging

### If Warnings Persist Too Long

Check when CSV loading happens:
```bash
grep "reading lifetime from csv at" test-30s.log
```

Check when matrices are ready:
```bash
grep "link lifetime matrix converted" test-30s.log
```

Check timing of path-finding calls:
```bash
grep "updating flows - path finding" test-30s.log | head -10
```

### If CSV Files Are Actually Needed

Check if they exist:
```bash
ls -la ~/Downloads/ns-allinone-3.35/ns-3.35/scratch/link_lifetime_solution*.csv
```

If missing, either:
1. Generate them (if generation tool exists)
2. Use different `routing_algorithm` setting
3. Disable path-finding features

### Performance Validation

Compare wormhole effectiveness:
```bash
# Run baseline (no attack)
./waf --run "routing --use_enhanced_wormhole=false --simTime=30" 2>&1 | tee baseline.log

# Run with attack
./waf --run "routing --use_enhanced_wormhole=true --simTime=30" 2>&1 | tee attack.log

# Compare metrics
grep "packets received" baseline.log attack.log
grep "packets transmitted" baseline.log attack.log
```

---

## Reporting Results

### If Successful:
Report back with:
1. ✅ "Test passed - simulation completed successfully"
2. Whether you saw warnings (and which ones)
3. Content/size of wormhole CSV file
4. Any interesting observations

### If Failed:
Provide:
1. Full build.log
2. Full test output log
3. Exact error message
4. Timestamp when crash occurred
5. gdb backtrace (if possible)

---

## Next Steps After Successful Test

1. **Longer simulations**: Try 60s, 120s
2. **Parameter variation**: 
   - Different attack rates
   - Different numbers of malicious nodes
3. **Metrics analysis**:
   - Compare with/without attack
   - Analyze packet delivery ratio
   - Check latency impact
4. **CSV analysis**:
   - Plot tunneled packets over time
   - Calculate attack effectiveness
5. **Documentation**:
   - Document results
   - Update README with findings

---

## Summary

**Main Goal**: Verify simulation runs to completion without crashing at 1.0348s

**Success Criteria**:
1. Build completes ✅
2. Simulation reaches full duration ✅
3. No "dereference zero pointer" crash ✅
4. Wormhole CSV generated ✅

**Acceptable**: Warnings about matrices not ready (guards working as intended)

**Not Acceptable**: Any crashes, segfaults, or premature termination

---

## Quick Reference Commands

```bash
# Pull, build, test (all-in-one)
cd ~/Downloads/ns-allinone-3.35/ns-3.35/scratch && \
wget -q -O routing.cc https://raw.githubusercontent.com/kavindunisansala/routing/master/routing.cc && \
cd ~/Downloads/ns-allinone-3.35/ns-3.35 && \
./waf build && \
./waf --run "routing --use_enhanced_wormhole=true --simTime=30" 2>&1 | tee test.log && \
echo "Exit code: $?" && \
ls -lh wormhole-attack-results.csv && \
echo "=== Crash Check ===" && \
grep -c "dereference zero pointer" test.log && \
echo "=== Warnings ===" && \
grep "WARNING" test.log | head -5 && \
echo "=== CSV Preview ===" && \
head -5 wormhole-attack-results.csv
```

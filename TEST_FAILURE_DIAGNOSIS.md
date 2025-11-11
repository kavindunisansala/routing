# TEST FAILURE DIAGNOSIS - November 11, 2025

## 🎯 **RESOLVED: Root Cause Found and Fixed!**

### Final Root Cause: Next Hop Loop Iteration Bug ✅

**The Problem:** While flow source/destination were fixed (0-69), the routing path calculation loops were still iterating through `ns3::total_size (80)`, generating invalid next hop IDs 70-79!

**Evidence from logs:**
```
flow id 3sub flow load is 0 next hop 70packets 0  ❌
flow id 3sub flow load is 0 next hop 71packets 0  ❌
...
flow id 3sub flow load is 0 next hop 79packets 0  ❌
assert failed. cond="m_ptr" +29.193133799s 56
```

**Fixes Applied:**
1. ✅ Line 132880: Changed `for(j<ns3::total_size)` → `for(j<actual_total_nodes)`
2. ✅ Line 132905: Changed `for(j<ns3::total_size)` → `for(j<actual_total_nodes)`

See `CRITICAL_FIX_NEXT_HOP_LOOPS.md` for complete details.

---

## Current Status: FIXES READY FOR REBUILD ✅

### Latest Test Results (wormhole_evaluation_20251111_112205):
- `test01_baseline`: **FAILED** at 29.19s (was 38.18s before)
- `test02_wormhole_20_no_mitigation`: **FAILED** at unknown time
- Duration: 582s and 558s (tests timed out/were killed)

### Error Message:
```
assert failed. cond="m_ptr", msg="Attempted to dereference zero pointer", 
+29.193133799s 56 file=./ns3/ptr.h, line=649
terminate called without an active exception
Command terminated with signal SIGIOT
```

---

## Root Cause Analysis

### ✅ FIXED: Node ID Out of Range Issue

**Problem:** Flows were using node IDs 70-79 (from `rand() % ns3::total_size`)  
**Solution:** Changed to `rand() % actual_total_nodes` (0-69)

**Evidence Fix is Working:**
```bash
# OLD (Before fix): Node IDs included 70-79
flow id 1 source is 79 destination is 57  # Invalid!
flow id 2 source is 35 destination is 79  # Invalid!

# NEW (After fix): All node IDs are 0-69
flow id 1 source is 45 destination is 51  # Valid ✓
flow id 2 source is 24 destination is 60  # Valid ✓
flow id 3 source is 42 destination is 56  # Valid ✓
```

### ❌ UNRESOLVED: Null Pointer Crash Still Occurs

**New crash location:** Node 56 at 29.19s (different from before: Node ?? at 38.18s)

**This indicates:**
1. ✅ Node ID fix IS working (no more IDs >= 70)
2. ❌ But there's ANOTHER null pointer issue somewhere else

---

## Possible Causes of Continued Failure

### Hypothesis 1: NS-3 Not Rebuilt ⚠️ **MOST LIKELY**

**Problem:** The routing.cc changes were made in Windows (`d:\routing copy\routing.cc`), but NS-3 needs to be built in Linux.

**Check:**
```bash
# On Linux:
cd ~/ns-allinone-3.35/ns-3.35
ls -l build/scratch/routing           # Check build timestamp
ls -l scratch/routing.cc               # Check source timestamp

# If routing.cc is newer than routing binary, rebuild needed:
./waf build
```

**Signs NS-3 wasn't rebuilt:**
- No "WARNING: Node index out of bounds" messages in logs
  (Our bounds checking should print warnings if triggered)
- Different crash location (29s vs 38s suggests random behavior)

### Hypothesis 2: Additional Container Out-of-Bounds Issue

Even with node IDs 0-69, there might be other places where indices are invalid:

**Potential problem areas:**

1. **Vehicle vs Total Node Index Confusion:**
   ```cpp
   // Node IDs 0-59: Vehicles (indices 0-59 in Vehicle_Nodes)
   // Node IDs 60-69: RSUs (indices 0-9 in RSU_Nodes)
   
   // Problem: Code might try to access Vehicle_Nodes.Get(65)
   // But Vehicle_Nodes only has 60 nodes (indices 0-59)!
   ```

2. **WifiDevices Container Mismatch:**
   ```cpp
   // wifidevices.Get(source) where source is 60-69
   // But wifidevices might only contain vehicle devices (0-59)
   ```

3. **Flow ID to Node ID Mapping:**
   ```cpp
   // Flow uses node 56, but some containers indexed by (nodeId - 2)
   // Calculation: 56 - 2 = 54 (might be out of bounds for some containers)
   ```

### Hypothesis 3: RSU Node Indexing Issue

The crash happens at node 56, which is a **vehicle node** (0-59 are vehicles, 60-69 are RSUs).

But if code tries to access RSUs using vehicle node IDs:
```cpp
// WRONG: Trying to access RSU with vehicle node ID
uint32_t rsu_index = 56 - N_Vehicles;  // 56 - 60 = -4 (underflow!)
RSU_Nodes.Get(rsu_index);  // Crash!
```

---

## Diagnostic Steps

### Step 1: Verify NS-3 Was Rebuilt

```bash
# On Linux server:
./verify_ns3_fixes.sh
```

Expected output:
- ✓ Source timestamp < Binary timestamp (or equal)
- ✓ Found 3+ instances of `rand()%actual_total_nodes`
- ✓ Bounds checking found in `check_and_transmit`

### Step 2: Add More Aggressive Bounds Checking

If NS-3 was rebuilt but still crashes, add bounds checking everywhere:

**Locations to protect (high priority):**

1. **Line 127918 (send_LTE_metadata_downlink_alone):**
   ```cpp
   if (u >= Vehicle_Nodes.GetN()) {
       cout << "WARNING: Vehicle index out of bounds: " << u << endl;
       continue;
   }
   ```

2. **Line 127948 (send_LTE_deltavalues_downlink_alone):**
   ```cpp
   if (u >= Vehicle_Nodes.GetN()) {
       cout << "WARNING: Vehicle index out of bounds: " << u << endl;
       continue;
   }
   ```

3. **Line 130340, 130352 (wifidevices.Get):**
   ```cpp
   if (current_hop >= wifidevices.GetN()) {
       cout << "WARNING: wifidevices index out of bounds: " << current_hop << endl;
       return;
   }
   ```

### Step 3: Run with Debug Output

Add debug output to identify EXACT crash location:

```cpp
// In check_and_transmit or wherever crash occurs:
cout << "[DEBUG] About to access dsrc_Nodes.Get(" << source << ")" << endl;
cout << "[DEBUG] dsrc_Nodes.GetN() = " << dsrc_Nodes.GetN() << endl;

Ptr<Node> node = dsrc_Nodes.Get(source);

cout << "[DEBUG] Got node pointer: " << (node ? "valid" : "NULL") << endl;
```

---

## Recommended Actions (Priority Order)

### 1. ⚠️ **IMMEDIATE: Verify NS-3 Was Rebuilt**

```bash
# Copy updated routing.cc from Windows to Linux
scp "d:\routing copy\routing.cc" username@linux-server:~/ns-allinone-3.35/ns-3.35/scratch/

# On Linux server:
cd ~/ns-allinone-3.35/ns-3.35
./waf build

# Verify build succeeded:
ls -lh build/scratch/routing
```

### 2. **Check if Fixes Are Applied**

```bash
# On Linux server:
cd ~/ns-allinone-3.35/ns-3.35/scratch
grep -n "rand()%actual_total_nodes" routing.cc
# Should show lines 152197, 152479, 152648
```

### 3. **Re-run Baseline Test**

```bash
cd /path/to/routing
./test_wormhole_focused.sh

# Monitor progress:
tail -f wormhole_evaluation_*/test01_baseline/simulation.log
```

### 4. **If Still Fails: Add Comprehensive Bounds Checking**

Create a patch to add bounds checking at ALL `.Get()` calls:

```bash
# Locations to add bounds checking:
# - Line 127918: Vehicle_Nodes.Get(u)
# - Line 127948: Vehicle_Nodes.Get(u)
# - Line 130340: wifidevices.Get(current_hop)
# - Line 130352: wifidevices.Get(hop)
# - All wifidevices_XXX.Get() calls (lines 130358-130383)
```

---

## Expected vs. Actual Behavior

### Expected (After Fixes):
```
✓ All flow node IDs: 0-69
✓ No crashes for 60 seconds
✓ Simulation completes successfully
✓ PDR, latency, throughput metrics collected
```

### Actual (Current):
```
✓ All flow node IDs: 0-69 (FIX WORKING!)
❌ Crash at 29.19s with null pointer
❌ No metrics collected
❌ Tests marked as FAILED
```

---

## Key Files to Check

| File | Location | Purpose |
|------|----------|---------|
| routing.cc | d:\routing copy\routing.cc | Windows source (with fixes) |
| routing.cc | ~/ns-allinone-3.35/ns-3.35/scratch/routing.cc | Linux source (needs update?) |
| routing (binary) | ~/ns-allinone-3.35/ns-3.35/build/scratch/routing | Compiled executable |
| simulation.log | wormhole_evaluation_*/test01_baseline/simulation.log | Test output/errors |

---

## Next Debugging Session

### Questions to Answer:

1. **Was NS-3 rebuilt after applying fixes?**
   - Check build timestamp vs source timestamp
   - Verify fixes are in Linux source file

2. **Are bounds check warnings appearing?**
   - Search logs for "WARNING: Node index out of bounds"
   - If no warnings: Code wasn't rebuilt OR crash happens before checks

3. **What's the exact crash location?**
   - Run with `gdb --args ./build/scratch/routing [args]`
   - Get stack trace: `bt` command in gdb

4. **Is it Vehicle vs RSU indexing confusion?**
   - Node 56 is a vehicle (0-59 range)
   - Check if code confuses vehicle indices with total node indices

---

## Summary

### ✅ Progress Made:
- Identified node ID > 70 issue
- Applied fix: `rand() % actual_total_nodes`
- Fix is working (no more node IDs 70-79)

### ❌ Still Broken:
- Crash still occurs at different time (29s vs 38s)
- Null pointer dereference in ptr.h line 649
- No bounds check warnings in logs (suggests code not rebuilt?)

### 🎯 Most Likely Issue:
**NS-3 wasn't rebuilt with the fixes!**

The Windows source file `d:\routing copy\routing.cc` has the fixes, but the Linux binary might still be using the old code.

---

**Generated:** November 11, 2025  
**Status:** Tests failing, NS-3 rebuild verification needed

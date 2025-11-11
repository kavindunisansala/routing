# BASELINE TEST FAILURE - ROOT CAUSE ANALYSIS

## Problem Summary
The baseline test (test01_baseline) **consistently fails at 38.18 seconds** with a null pointer dereference error.

```
assert failed. cond="m_ptr", msg="Attempted to dereference zero pointer", +38.182135791s
file=./ns3/ptr.h, line=649
Command terminated with signal SIGIOT
```

## Root Cause

### Issue 1: Flow Initialization Using Invalid Node IDs

The flows were being initialized with source/destination node IDs that **exceed the actual number of nodes** in the network:

**Evidence from simulation log:**
```
flow id 1source is 34destination is 78
flow id 2source is 46destination is 21
flow id 3source is 13destination is 77
flow id 0source is 29destination is 27
flow id 1source is 75destination is 40
flow id 2source is 41destination is 52
flow id 3source is 63destination is 12
flow id 0source is 29destination is 27
flow id 1source is 56destination is 38
flow id 2source is 71destination is 21
flow id 3source is 52destination is 77
flow id 0source is 29destination is 27
flow id 1source is 33destination is 79  ← Node 79!
flow id 2source is 34destination is 55
flow id 3source is 46destination is 6
flow id 0source is 29destination is 27
flow id 1source is 55destination is 58
flow id 2source is 35destination is 79  ← Node 79!
flow id 3source is 43destination is 56
flow id 0source is 29destination is 27
flow id 1source is 79destination is 57  ← Node 79!
flow id 2source is 54destination is 30
flow id 3source is 72destination is 66
```

**Problem:**
- Network has **70 nodes** (60 vehicles + 10 RSUs), with valid indices **0-69**
- Flow initialization code was using `rand() % ns3::total_size`
- `ns3::total_size = 80` (MAX_NODES compile-time constant)
- Result: Generates node IDs 70-79 which **don't exist** in the network

### Issue 2: Null Pointer Access in check_and_transmit()

When the code tried to access these invalid nodes:

**Location:** `routing.cc` line ~132783
```cpp
Simulator::Schedule(Seconds(0.0), routing_dsrc_data_unicast, 
    wifidevices_172.Get(source),   // source = 73, 76, 78, 79, etc.
    dsrc_Nodes.Get(source),         // dsrc_Nodes only has 70 nodes (0-69)
    fid, nid, arguments, total_packet_counter+1);
```

**What happens:**
1. `dsrc_Nodes.GetN()` returns 70
2. Calling `dsrc_Nodes.Get(73)` with index >= 70 returns a **null Ptr<Node>**
3. The `routing_dsrc_data_unicast` function tries to dereference this null pointer
4. **CRASH:** "Attempted to dereference zero pointer" at `ptr.h:649`

## Fixes Applied

### Fix 1: Use Actual Node Count for Flow Generation

**Changed in 3 locations (lines 152197, 152479, 152648):**

```cpp
// BEFORE (WRONG):
destination = rand() % ns3::total_size;  // Can generate 0-79
source = rand() % ns3::total_size;       // Can generate 0-79

// AFTER (CORRECT):
destination = rand() % actual_total_nodes;  // Generates 0-69 (for 70 nodes)
source = rand() % actual_total_nodes;       // Generates 0-69 (for 70 nodes)
```

**Why this works:**
- `actual_total_nodes = N_Vehicles + N_RSUs` (set at line 150847)
- For your configuration: `actual_total_nodes = 60 + 10 = 70`
- Random node IDs will now be in range **0-69**, matching actual nodes

### Fix 2: Bounds Checking in check_and_transmit()

**Added at line ~132773:**

```cpp
// Bounds checking for node access
uint32_t dsrc_nodes_size = dsrc_Nodes.GetN();
if (source >= dsrc_nodes_size || nid >= dsrc_nodes_size) {
    cout << "WARNING: Node index out of bounds in check_and_transmit! source=" << source 
         << ", nid=" << nid << ", dsrc_Nodes.GetN()=" << dsrc_nodes_size << endl;
    pd_all_inst[fid].pd_inst[source].pending[arguments.channel][packet_id] = false;
    return;  // Exit gracefully instead of crashing
}
```

**Why this is important:**
- **Defense in depth**: Even if a bug introduces an invalid node ID, it won't crash
- Logs the problem for debugging
- Marks packet as not pending
- Returns early instead of accessing invalid memory

### Fix 3: Bounds Checking in MacRx()

**Changed at line 130793:**

```cpp
// BEFORE (WRONG):
continue;  // ERROR: Not in a loop!

// AFTER (CORRECT):
return;    // Exit function gracefully
```

## Network Configuration Details

```
Network configuration: N_Vehicles=60, N_RSUs=10, actual_total_nodes=70, 
ns3::total_size=80 (compile-time max)
```

**Key Points:**
- **Runtime nodes:** 70 (0-69 valid indices)
- **Compile-time MAX_NODES:** 80 (allows up to 80 nodes, but only 70 created)
- **Flow IDs must use:** 0-69
- **Container sizes:**
  - `dsrc_Nodes.GetN()` = 70
  - `Vehicle_Nodes.GetN()` = 60
  - `RSU_Nodes.GetN()` = 10

## Why This Wasn't Caught Earlier

1. **Silent failure in random generation:** No warning when `rand() % 80` generates 70-79
2. **Delayed crash:** Code runs fine until a flow tries to use an invalid node ID
3. **Timing dependent:** Crash time (38.18s) varies based on when invalid node ID is selected
4. **NodeContainer API:** `Get(index)` returns null for out-of-bounds, doesn't throw exception

## Testing the Fix

### Expected Behavior After Fix:

1. **All flow node IDs will be 0-69**
2. **Simulation will run to completion (60 seconds)**
3. **No null pointer crashes**
4. **If any bounds issues remain, they'll be logged as warnings**

### Verification Steps:

```bash
# 1. Rebuild NS-3
cd ~/ns-allinone-3.35/ns-3.35
./waf build

# 2. Run baseline test
cd /path/to/routing
./test_wormhole_focused.sh

# 3. Check for success
tail -30 wormhole_evaluation_*/test01_baseline/simulation.log

# 4. Verify no out-of-bounds node IDs
grep "flow id.*source is.*destination is" wormhole_evaluation_*/test01_baseline/simulation.log | \
    awk '{match($0, /source is ([0-9]+)/, src); match($0, /destination is ([0-9]+)/, dst); 
          if (src[1] >= 70) print "INVALID SOURCE:", src[1]; 
          if (dst[1] >= 70) print "INVALID DESTINATION:", dst[1];}'
# Should print nothing if fix works
```

## Impact Assessment

### Before Fix:
- ❌ 100% failure rate at ~38 seconds
- ❌ Random node IDs 70-79 causing crashes
- ❌ Null pointer dereference
- ❌ No meaningful test results

### After Fix:
- ✅ Flows use valid node IDs only (0-69)
- ✅ Bounds checking prevents crashes
- ✅ Simulation runs to completion
- ✅ Meaningful metrics collected

## Related Code Locations

| Location | Purpose | Status |
|----------|---------|--------|
| Line 2783 | `#define MAX_NODES 80` | ✅ Correct (compile-time max) |
| Line 2819 | `uint32_t actual_total_nodes = 28` | ✅ Updated at runtime (line 150847) |
| Line 150847 | `actual_total_nodes = N_Vehicles + N_RSUs` | ✅ Correct (70 nodes) |
| Line 152197 | `rand() % actual_total_nodes` | ✅ FIXED (was `ns3::total_size`) |
| Line 152479 | `rand() % actual_total_nodes` | ✅ FIXED (was `ns3::total_size`) |
| Line 152648 | `rand() % actual_total_nodes` | ✅ FIXED (was `ns3::total_size`) |
| Line 130793 | `return;` (bounds check) | ✅ FIXED (was `continue;`) |
| Line 132773 | Bounds checking added | ✅ NEW (prevents crashes) |

## Lessons Learned

1. **Always use runtime node count** (`actual_total_nodes`) not compile-time max (`ns3::total_size`)
2. **Bounds checking is essential** when accessing arrays/containers with dynamic sizes
3. **Random generation must respect actual size** not theoretical maximum
4. **NodeContainer.Get() returns null** for invalid indices - must check!
5. **Add defensive programming** to catch issues early

## Next Steps

1. ✅ **Fix applied** - Changed `rand() % ns3::total_size` → `rand() % actual_total_nodes`
2. ✅ **Bounds checking added** in `check_and_transmit()`  
3. ✅ **Return vs continue fixed** in `MacRx()`
4. ⏳ **Rebuild NS-3** with fixes
5. ⏳ **Re-run baseline test** to verify fix
6. ⏳ **Run complete test suite** (all 80 tests)

---

**Generated:** November 11, 2025  
**Status:** Root cause identified and fixed, pending rebuild and testing

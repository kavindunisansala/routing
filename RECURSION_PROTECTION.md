# Stack Overflow Protection - Final Defense Layer

## The Continuing Problem

Even after fixing the `=` vs `==` bug, you're still experiencing SIGSEGV. This suggests there may be OTHER logic issues causing infinite or very deep recursion that we haven't found yet.

## The Solution: Recursion Depth Limits

Instead of trying to find every possible recursion bug, I've added a **hard limit** on recursion depth that will prevent stack overflow regardless of the underlying logic issues.

## What Was Added (Commit e8f438e)

### 1. Global Recursion Depth Counters

```cpp
// At file scope (line ~115502)
static uint32_t update_stable_depth = 0;
static uint32_t update_unstable_depth = 0;
const uint32_t MAX_RECURSION_DEPTH = 100;  // Safety limit
```

### 2. Depth Tracking in update_stable()

**At function ENTRY:**
```cpp
void update_stable(uint32_t flow_id, uint32_t current_hop)
{
    // Recursion depth protection
    update_stable_depth++;
    if (update_stable_depth > MAX_RECURSION_DEPTH) {
        std::cerr << "ERROR: update_stable recursion depth exceeded " << MAX_RECURSION_DEPTH 
                  << " (flow_id=" << flow_id << ", current_hop=" << current_hop << ")" << std::endl;
        update_stable_depth--;
        return;  // Stop recursion
    }
    
    // All existing safety checks now also decrement on early return
    if (flow_id >= 2*flows) {
        update_stable_depth--;  // ← Decrement before return
        return;
    }
    // ... more checks with decrements
```

**At function EXIT:**
```cpp
    } // end of for loop
    
    // Decrement recursion depth before returning
    update_stable_depth--;
}
```

### 3. Same Protection in update_unstable()

Identical depth tracking added to `update_unstable()` with its own counter.

## How It Works

### Normal Case (Good Recursion):
```
Call 1: update_stable(0, 5)  → depth = 1
  Call 2: update_stable(0, 7)  → depth = 2
    Call 3: update_stable(0, 9)  → depth = 3
    Return from Call 3  → depth = 2
  Return from Call 2  → depth = 1
Return from Call 1  → depth = 0
```

### Protected Case (Runaway Recursion):
```
Call 1: update_stable(0, 5)  → depth = 1
  Call 2: update_stable(0, 7)  → depth = 2
    ... (many calls) ...
      Call 99: update_stable(0, X)  → depth = 99
        Call 100: update_stable(0, Y)  → depth = 100
          Call 101: update_stable(0, Z)  → depth = 101
          ❌ ERROR: "recursion depth exceeded 100"
          ✅ Return immediately (no crash)
        Return from Call 101  → depth = 100
      ... (unwind stack safely) ...
```

## Why This Works

1. **Hard Limit**: No matter what logic bugs exist, recursion cannot exceed 100 levels
2. **Safe Unwinding**: Stack unwinds normally, no overflow
3. **Error Reporting**: Prints which function and parameters caused deep recursion
4. **Graceful Degradation**: Path-finding may be incomplete, but simulation continues
5. **No SIGSEGV**: Stack stays within safe limits

## Benefits Over Bug Hunting

| Approach | Pros | Cons |
|----------|------|------|
| **Find All Bugs** | Perfect solution if found | May take days; easy to miss edge cases |
| **Depth Limiting** | Works immediately; catches ALL recursion issues | May stop valid deep paths |

## Test Instructions

```bash
# Pull latest with recursion protection
cd ~/Downloads/ns-allinone-3.35/ns-3.35/scratch
wget -O routing.cc https://raw.githubusercontent.com/kavindunisansala/routing/master/routing.cc

# Rebuild
cd ~/Downloads/ns-allinone-3.35/ns-3.35
./waf build

# Test - should now complete without SIGSEGV
./waf --run "routing --use_enhanced_wormhole=true --simTime=30" 2>&1 | tee protected-test.log
```

## What to Look For

### ✅ Success (No SIGSEGV):
```
updating flows - path finding at1.0348
DEBUG: flows=2, total_size=28, 2*flows=4
adjacency matrix generated at timestamp 1.0348
Routing distance-based: Number of paths from source: X to destination Y is Z
...
Simulation completes at 30 seconds
```

### ⚠️ Recursion Warnings (OK - Protection Working):
```
ERROR: update_unstable recursion depth exceeded 100 (flow_id=0, current_hop=15)
```
This means:
- Recursion tried to go deeper than 100 levels
- Protection stopped it before stack overflow
- Simulation continues (path-finding incomplete for that flow, but no crash)

### ✅ Wormhole CSV Created:
```bash
ls -lh wormhole-attack-results.csv
cat wormhole-attack-results.csv
```

## Tuning the Limit

If you see recursion warnings but simulation works:

### Increase Limit (if legitimate deep paths):
```cpp
const uint32_t MAX_RECURSION_DEPTH = 200;  // Allow deeper recursion
```

### Decrease Limit (if warnings indicate bugs):
```cpp
const uint32_t MAX_RECURSION_DEPTH = 50;   // Catch bugs earlier
```

For a 28-node network, legitimate path-finding should NEVER need 100 levels of recursion. The theoretical maximum is 28 (visiting each node once). So if you hit 100, there's definitely a logic bug, but at least it won't crash!

## Why 100?

- **28 nodes** in network
- **Worst case path**: Visit all 28 nodes sequentially
- **Safety margin**: 100 is ~3.5x the theoretical maximum
- **Stack safety**: Keeps stack usage under ~1MB (depending on local variables)

## Technical Details

### Stack Frame Size Estimate:
```cpp
void update_stable(uint32_t flow_id, uint32_t current_hop) {
    // Local variables + parameters ≈ 32 bytes per call
    // 100 calls × 32 bytes = 3,200 bytes (very safe)
    // Compare to typical stack size: 1-8 MB
}
```

### Why Static Counters Work:
- These functions are **not thread-safe** anyway (global arrays)
- NS-3 is **single-threaded** simulation
- Static counters = minimal overhead
- Alternative (pass depth as parameter) requires API changes

## Commit History

| Commit | Fix | Result |
|--------|-----|--------|
| efd8d2a | Null pointer checks in mobility models | Fixed crash at 1.0348s |
| 8a57c7c | Fixed `=` to `==` in met[i] checks | Fixed logic bug causing recursion |
| **e8f438e** | **Added recursion depth limits** | **Prevents SIGSEGV regardless of other bugs** |

## Next Steps

1. **Test with protection** - Pull commit e8f438e and run
2. **Check for warnings** - If you see "recursion depth exceeded", note the parameters
3. **Share results** - Tell me if:
   - ✅ Simulation completes (good!)
   - ⚠️ Warnings appear (protection working, but may indicate bug)
   - ❌ Still crashes (different issue, need more info)

## If Still Crashing

If you STILL get SIGSEGV after this, it means the crash is NOT from recursion. Possible causes:

1. **Buffer overflow** in packet handling
2. **Invalid pointer** in wormhole code  
3. **Array out of bounds** somewhere else
4. **Double free** or memory corruption

In that case, run with gdb to get a backtrace:
```bash
./waf --run "routing --use_enhanced_wormhole=true --simTime=30" --gdb
# In gdb:
(gdb) run
# When it crashes:
(gdb) backtrace
(gdb) info locals
```

Share the backtrace and we'll find the exact line.

## Summary

This commit adds a **safety net** that prevents stack overflow from ANY recursion issue, whether we've found the bug or not. It's defensive programming - like a seatbelt that works even if you can't find the car's mechanical problem.

**Commit**: e8f438e  
**Impact**: Should eliminate all SIGSEGV from stack overflow  
**Trade-off**: May stop some path-finding early, but prevents crashes  
**GitHub**: https://github.com/kavindunisansala/routing/commit/e8f438e

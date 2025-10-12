# 🔥 CRITICAL BUG FIXED - Infinite Recursion Causing SIGSEGV

## The New Problem (SIGSEGV at 1.036s)

After fixing the null pointer crash, you got a new error:
```
HandleReadTwo : Received a Packet of size: 1420 at time 1.036
HandleReadTwo : Received a Packet of size: 272 at time 1.036
Command terminated with signal SIGSEGV
```

**SIGSEGV** = Segmentation Fault = Usually stack overflow or invalid memory access

## Deep Analysis - The Root Cause

I found a **CRITICAL TYPO** in the recursive path-finding functions:

### Bug #1: In `update_stable()` at line 115526

**BEFORE (WRONG):**
```cpp
if((proposed_algo2_output_inst[flow_id].met[i] = false) || ...)
//                                              ^ ASSIGNMENT!
```

**AFTER (FIXED):**
```cpp
if((proposed_algo2_output_inst[flow_id].met[i] == false) || ...)
//                                              ^^ COMPARISON!
```

### Bug #2: In `update_unstable()` at line 115614

**BEFORE (WRONG):**
```cpp
if((distance_algo2_output_inst[flow_id].met[i] = false) || ...)
//                                             ^ ASSIGNMENT!
```

**AFTER (FIXED):**
```cpp
if((distance_algo2_output_inst[flow_id].met[i] == false) || ...)
//                                             ^^ COMPARISON!
```

## Why This Caused SIGSEGV

### The Purpose of `met[]` Array:
The `met[i]` (met = "visited") array is supposed to track which nodes have been processed during recursive path-finding to **prevent infinite recursion**.

### What the Bug Did:

1. **Assignment (`=`) instead of Comparison (`==`)**
   ```cpp
   if ((met[i] = false) || other_condition)
   ```
   - Sets `met[i]` to `false`
   - Expression `(met[i] = false)` evaluates to `false`
   - Condition depends entirely on `other_condition`

2. **Recursion Protection Failed**
   - The function marks nodes as visited: `met[current_hop] = true`
   - Then loops through neighbors
   - **Should check**: "if neighbor NOT visited OR better path found"
   - **Actually did**: Always sets `met[i] = false`, then checks second condition
   - Result: **Recursion protection completely broken**

3. **Infinite Recursion Chain**
   ```
   update_stable(flow_id, node_A)
     → met[A] = true
     → loop through neighbors
     → if (met[B] = false) || ...  ← Always sets met[B]=false!
         → update_stable(flow_id, node_B)
           → met[B] = true
           → loop through neighbors
           → if (met[A] = false) || ...  ← Sets met[A]=false again!
               → update_stable(flow_id, node_A)  ← INFINITE LOOP!
   ```

4. **Stack Overflow**
   - Each recursive call adds a stack frame
   - Infinite recursion → stack grows unbounded
   - Eventually exceeds stack limit
   - **SIGSEGV** (Segmentation Fault)

## The Fix (Commit 8a57c7c)

Changed both instances from assignment to comparison:

### File: `routing.cc`

**Line 115526 (update_stable):**
```cpp
// BEFORE:
if((proposed_algo2_output_inst[flow_id].met[i] = false)||(proposed_algo2_output_inst[flow_id].Y[i] >= ...))

// AFTER:
if((proposed_algo2_output_inst[flow_id].met[i] == false)||(proposed_algo2_output_inst[flow_id].Y[i] >= ...))
```

**Line 115614 (update_unstable):**
```cpp
// BEFORE:
if((distance_algo2_output_inst[flow_id].met[i] = false)||(distance_algo2_output_inst[flow_id].D[i] > value))

// AFTER:
if((distance_algo2_output_inst[flow_id].met[i] == false)||(distance_algo2_output_inst[flow_id].D[i] > value))
```

## How It Works Now (Correctly)

1. **Mark Current Node as Visited**
   ```cpp
   met[current_hop] = true;  // Won't process this node again
   ```

2. **Check Neighbors**
   ```cpp
   for (uint32_t i = 0; i < total_size; i++) {
       if (met[i] == false) {  // ← NOW CORRECTLY CHECKS if NOT visited
           // Process unvisited neighbor
           update_stable(flow_id, i);  // Safe - won't recurse to visited nodes
       }
   }
   ```

3. **Recursion Terminates**
   - Each node is only processed once per flow
   - No infinite loops
   - Stack remains bounded
   - No SIGSEGV

## Why This is CRITICAL

This bug would cause:
- ❌ **Stack overflow** within milliseconds of path-finding
- ❌ **SIGSEGV crash** every time routing runs
- ❌ **Incorrect routing** paths (if it somehow didn't crash)
- ❌ **Unpredictable behavior** due to corrupted `met[]` state

## Test Instructions

```bash
# Pull the critical fix (commit 8a57c7c)
cd ~/Downloads/ns-allinone-3.35/ns-3.35/scratch
wget -O routing.cc https://raw.githubusercontent.com/kavindunisansala/routing/master/routing.cc

# Rebuild
cd ~/Downloads/ns-allinone-3.35/ns-3.35
./waf build

# Test - should now complete without SIGSEGV
./waf --run "routing --use_enhanced_wormhole=true --simTime=30" 2>&1 | tee final-test-v2.log
```

## Expected Result

### ✅ Success Indicators:
```
updating flows - path finding at1.0348
DEBUG: flows=2, total_size=28, 2*flows=4
adjacency matrix generated at timestamp 1.0348
DEBUG run_distance_path_finding: Entered with flow_id=0...
Routing distance-based: Number of paths from source: X to destination Y is Z
...
Simulation continues past 1.036s
Simulation completes at 30 seconds
```

### ✅ CSV Output:
```bash
ls -lh wormhole-attack-results.csv
cat wormhole-attack-results.csv
# Should have packet statistics
```

### ❌ Should NOT See:
- ❌ SIGSEGV
- ❌ Stack overflow
- ❌ Simulation hanging/freezing
- ❌ Crash at 1.036s

## Bug History Timeline

| Time | Issue | Fix | Commit |
|------|-------|-----|--------|
| 1.0348s | Null pointer in `calculate_distance_to_each_node()` | Added null checks for mobility models | efd8d2a |
| 1.036s | SIGSEGV from infinite recursion | Fixed `=` to `==` in `met[i]` checks | 8a57c7c |
| **NOW** | **Should work!** | **Test pending** | **← YOU ARE HERE** |

## Technical Details

### C/C++ Assignment in Conditionals

This is a **classic C/C++ pitfall**:

```cpp
// WRONG (always true if x is non-zero):
if (x = 5) { ... }  // Sets x to 5, then checks if 5 is true (always yes)

// CORRECT (compares x with 5):
if (x == 5) { ... }  // Checks if x equals 5
```

Modern compilers warn about this, but the warning was likely ignored or not enabled.

### Why `met[]` is Critical

The `met[]` array implements **visited-node tracking** in graph traversal:
- **DFS/BFS Algorithms**: Must track visited nodes to avoid cycles
- **Dijkstra's Algorithm**: Must mark processed nodes
- **Graph Path-Finding**: Prevents infinite loops in cyclic graphs

Without proper `met[]` checking:
- Paths contain cycles
- Algorithm never terminates
- Stack overflows

## Lessons Learned

1. **Always use `==` for comparison**, never `=` in conditions
2. **Enable compiler warnings** (`-Wall -Wextra`)
3. **Test recursion depth** in graph algorithms
4. **Infinite recursion** manifests as SIGSEGV (stack overflow)
5. **Typos in recursion guards** are catastrophic

## Commit Info

- **Commit**: 8a57c7c
- **Title**: "CRITICAL FIX: Change assignment (=) to comparison (==) in recursion checks"
- **Files Changed**: routing.cc (2 lines)
- **Lines Fixed**: 115526, 115614
- **Impact**: Prevents infinite recursion and stack overflow
- **GitHub**: https://github.com/kavindunisansala/routing/commit/8a57c7c

## Next Steps

1. **Test immediately** with the command above
2. **Verify simulation completes** full 30 seconds
3. **Check wormhole CSV** has data
4. **Share any remaining errors** (hopefully none!)

This was a **2-character fix** (`=` → `==`) but with **MASSIVE impact**. Classic bug! 🐛🔧


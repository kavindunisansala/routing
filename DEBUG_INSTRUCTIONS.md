# Debug Instructions for Null Pointer Crash

## The Problem
You're still getting the crash even after our guards were applied. This means either:
1. The guards aren't being triggered (wrong code path)
2. The pointer dereference is happening somewhere else
3. The values being passed are unexpected

## What I Added
I've added extensive debug output to help us diagnose EXACTLY where and why the crash is happening:

### Debug Output Added:
1. **In `update_flows()`**: Shows values of `flows`, `total_size`, and which flow_ids are being scheduled
2. **In `run_stable_path_finding()`**: Shows entry, flow_id validation, and pointer access attempts
3. **In `run_distance_path_finding()`**: Same debugging as above

## Test Command on Linux VM

```bash
# Pull latest code with debug output
cd ~/Downloads/ns-allinone-3.35/ns-3.35/scratch
wget -O routing.cc https://raw.githubusercontent.com/kavindunisansala/routing/master/routing.cc

# Rebuild
cd ~/Downloads/ns-allinone-3.35/ns-3.35
./waf build

# Run with output captured
./waf --run "routing --use_enhanced_wormhole=true --simTime=30" 2>&1 | tee debug-output.log
```

## What to Look For in the Output

### Expected Debug Messages (if everything is working):
```
updating flows - path finding at1.0348
DEBUG: flows=2, total_size=28, 2*flows=4
DEBUG: Scheduling run_distance_path_finding for flow_id=0
DEBUG: Scheduling run_distance_path_finding for flow_id=1
DEBUG: Scheduling run_distance_path_finding for flow_id=2
DEBUG: Scheduling run_distance_path_finding for flow_id=3
DEBUG run_distance_path_finding: Entered with flow_id=0, flows=2, 2*flows=4
```

### Scenario 1: Matrix Not Ready (Expected)
```
WARNING: linklifetimeMatrix_dsrc not ready yet (size=0, need 28), skipping path finding for flow 0
```
**Meaning**: Our guards are working! The function returned early before crashing.
**Action**: This is GOOD - simulation should continue without crashing.

### Scenario 2: Invalid flow_id
```
ERROR: Invalid flow_id X (max: 3), cannot access demanding_flow_struct_controller_inst
```
**Meaning**: Flow ID is out of bounds, guard caught it before crash.
**Action**: Need to investigate why invalid flow_id was passed.

### Scenario 3: Crash BEFORE Debug Output
If you see:
```
updating flows - path finding at1.0348
assert failed. cond="m_ptr", msg="Attempted to dereference zero pointer"
```
WITHOUT seeing any "DEBUG:" messages, then the crash is happening BEFORE our functions are called, possibly in:
- `generate_adjacency_matrix()` (called before path-finding loop)
- Somewhere in the scheduling mechanism
- A different code path entirely

### Scenario 4: Crash AFTER "About to access"
If you see:
```
DEBUG run_distance_path_finding: About to access demanding_flow_struct_controller_inst[0]
assert failed...
```
Then the issue is that `demanding_flow_struct_controller_inst` pointer itself is NULL or corrupted.

## Analysis Steps

### Step 1: Check Last Debug Message
```bash
grep "DEBUG" debug-output.log | tail -20
```
This will show the last debug message before the crash.

### Step 2: Check for Warnings/Errors
```bash
grep -E "(WARNING|ERROR)" debug-output.log
```

### Step 3: Check What Happened Right Before Crash
```bash
tail -50 debug-output.log
```

### Step 4: Check if generate_adjacency_matrix() is the Problem
```bash
grep "generate_adjacency_matrix" debug-output.log
```

## Share These Results With Me

Please share:
1. **Last 50 lines before crash**:
   ```bash
   tail -50 debug-output.log
   ```

2. **All DEBUG lines**:
   ```bash
   grep "DEBUG" debug-output.log
   ```

3. **All WARNING/ERROR lines**:
   ```bash
   grep -E "(WARNING|ERROR)" debug-output.log
   ```

4. **Any mentions of matrices**:
   ```bash
   grep -i "matrix" debug-output.log | tail -20
   ```

## Expected Outcomes

### Best Case:
You see "WARNING: linklifetimeMatrix_dsrc not ready" and simulation continues without crashing.

### Likely Case:
Crash happens in `generate_adjacency_matrix()` or somewhere we haven't guarded yet.

### What's Next:
Once we see the debug output, we'll know EXACTLY where the crash is and can add guards there.

## Quick Commands Summary

```bash
# On Linux VM - Full test sequence
cd ~/Downloads/ns-allinone-3.35/ns-3.35/scratch && \
wget -q -O routing.cc https://raw.githubusercontent.com/kavindunisansala/routing/master/routing.cc && \
cd ~/Downloads/ns-allinone-3.35/ns-3.35 && \
./waf build && \
./waf --run "routing --use_enhanced_wormhole=true --simTime=30" 2>&1 | tee debug-output.log

# After crash, check the debug output
tail -50 debug-output.log
grep "DEBUG" debug-output.log
grep -E "(WARNING|ERROR)" debug-output.log

# Copy the output and share it
```

## Commit Info
- **Latest commit**: 5a6c71f "Add extensive debug output to diagnose null pointer crash"
- **Previous commit**: df5402f "Add defensive guards to path-finding functions"
- **GitHub**: https://github.com/kavindunisansala/routing/commit/5a6c71f

# Quick Diagnostic Steps

## IMPORTANT: Verify You Have Latest Code

The crash you're experiencing means you might not have pulled the latest fixes. Let me help you verify:

### Step 1: Check Current Commit on Linux

```bash
cd ~/Downloads/ns-allinone-3.35/ns-3.35/scratch
head -20 routing.cc | grep -E "(recursion|MAX_RECURSION_DEPTH)"
```

**Expected output if you have latest code:**
```
// Recursion depth tracking to prevent stack overflow
static uint32_t update_stable_depth = 0;
const uint32_t MAX_RECURSION_DEPTH = 100;
```

**If you see NOTHING**, you don't have the latest code!

### Step 2: Force Update to Latest

```bash
cd ~/Downloads/ns-allinone-3.35/ns-3.35/scratch
rm routing.cc  # Remove old version
wget https://raw.githubusercontent.com/kavindunisansala/routing/master/routing.cc
```

### Step 3: Verify the Fix is Present

```bash
grep "MAX_RECURSION_DEPTH" routing.cc
```

**Expected:**
```
const uint32_t MAX_RECURSION_DEPTH = 100;  // Safety limit
    if (update_stable_depth > MAX_RECURSION_DEPTH) {
        std::cerr << "ERROR: update_stable recursion depth exceeded " << MAX_RECURSION_DEPTH
    if (update_unstable_depth > MAX_RECURSION_DEPTH) {
        std::cerr << "ERROR: update_unstable recursion depth exceeded " << MAX_RECURSION_DEPTH
```

### Step 4: Verify the == Fix is Present

```bash
grep "met\[i\] ==" routing.cc | head -2
```

**Expected:**
```
if((proposed_algo2_output_inst[flow_id].met[i] == false)||...
if((distance_algo2_output_inst[flow_id].met[i] == false)||...
```

### Step 5: Rebuild and Test

```bash
cd ~/Downloads/ns-allinone-3.35/ns-3.35
./waf clean
./waf build
./waf --run "routing --use_enhanced_wormhole=true --simTime=30" 2>&1 | tee test-latest.log
```

## Run with GDB to Get Backtrace

If it still crashes after verifying you have the latest code:

```bash
cd ~/Downloads/ns-allinone-3.35/ns-3.35
./waf --run "routing --use_enhanced_wormhole=true --simTime=30" --command-template="gdb --args %s"
```

In gdb, run these commands:

```gdb
(gdb) run
```

*Wait for crash...*

```gdb
(gdb) backtrace
(gdb) frame 0
(gdb) list
(gdb) info locals
(gdb) print current_hop
(gdb) print flow_id
(gdb) print total_size
(gdb) print update_stable_depth
(gdb) print update_unstable_depth
```

**Copy and paste ALL the output** from the gdb session.

## What Each Fix Does

| Commit | Fix | Line Numbers |
|--------|-----|--------------|
| efd8d2a | Null checks in calculate_distance_to_each_node | ~115307-115418 |
| 8a57c7c | Changed `met[i] = false` to `met[i] == false` | 115552, 115670 |
| e8f438e | Added MAX_RECURSION_DEPTH protection | 115505-115520, recursion tracking throughout |

All three must be present for the simulation to work!

## Alternative: Download Complete File

If grep commands are confusing, just do this:

```bash
cd ~/Downloads/ns-allinone-3.35/ns-3.35/scratch
# Backup current version
cp routing.cc routing.cc.backup
# Download latest
wget -O routing.cc https://raw.githubusercontent.com/kavindunisansala/routing/e8f438e/routing.cc
# Rebuild
cd ~/Downloads/ns-allinone-3.35/ns-3.35
./waf clean && ./waf build
# Test
./waf --run "routing --use_enhanced_wormhole=true --simTime=30"
```

## Quick Test: Check File Size

```bash
cd ~/Downloads/ns-allinone-3.35/ns-3.35/scratch
wc -l routing.cc
```

**Expected line count**: Around 141,176 lines (with all fixes)

If you have significantly fewer lines, you have an old version!

---

**Please verify you have the latest code before continuing with gdb!** The fixes won't work if the file wasn't actually updated on your Linux system.

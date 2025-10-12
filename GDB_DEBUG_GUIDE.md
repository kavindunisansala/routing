# Correct GDB Debug Commands for NS-3

## The Issue
The `--command-template` with gdb doesn't properly pass program arguments. You need to use a different approach.

## Option 1: Run GDB Directly (RECOMMENDED)

```bash
cd ~/Downloads/ns-allinone-3.35/ns-3.35

# Build first
./waf build

# Run gdb on the built executable
gdb ./build/scratch/routing

# Inside gdb, set the arguments:
(gdb) set args --use_enhanced_wormhole=true --simTime=30
(gdb) run

# When it crashes:
(gdb) backtrace
(gdb) info locals
(gdb) list
```

## Option 2: Run Without GDB to See if Latest Fix Works

```bash
cd ~/Downloads/ns-allinone-3.35/ns-3.35/scratch
wget -O routing.cc https://raw.githubusercontent.com/kavindunisansala/routing/master/routing.cc

cd ~/Downloads/ns-allinone-3.35/ns-3.35
./waf build

# Run normally first
./waf --run routing -- --use_enhanced_wormhole=true --simTime=30
```

**Note the `--` before the program arguments!** This separates waf options from program options.

## Option 3: GDB with Waf (Alternative)

```bash
./waf --run routing --command-template="gdb -ex 'set args --use_enhanced_wormhole=true --simTime=30' -ex run --args %s"
```

## What to Do

### Step 1: Try the Latest Fix Without GDB

First, let's see if the recursion protection fixed it:

```bash
cd ~/Downloads/ns-allinone-3.35/ns-3.35/scratch
wget -O routing.cc https://raw.githubusercontent.com/kavindunisansala/routing/master/routing.cc

cd ~/Downloads/ns-allinone-3.35/ns-3.35
./waf build

# Note the -- before program args!
./waf --run routing -- --use_enhanced_wormhole=true --simTime=30 2>&1 | tee test-output.log
```

### Step 2: If It Still Crashes, Use GDB

```bash
cd ~/Downloads/ns-allinone-3.35/ns-3.35
gdb ./build/scratch/routing

# In gdb:
(gdb) set args --use_enhanced_wormhole=true --simTime=30
(gdb) run

# After crash:
(gdb) where
(gdb) backtrace full
(gdb) info locals
(gdb) frame 0
(gdb) list
```

### Step 3: Share the Output

If it crashes, send me:
- Last 100 lines of test-output.log
- Full gdb backtrace
- Any error messages

## Quick Test Commands

```bash
# All-in-one test command
cd ~/Downloads/ns-allinone-3.35/ns-3.35/scratch && \
wget -q -O routing.cc https://raw.githubusercontent.com/kavindunisansala/routing/master/routing.cc && \
cd ~/Downloads/ns-allinone-3.35/ns-3.35 && \
./waf build && \
./waf --run routing -- --use_enhanced_wormhole=true --simTime=30 2>&1 | tee /tmp/routing-test.log && \
echo "=== TEST COMPLETED ===" && \
tail -100 /tmp/routing-test.log
```

## Expected Output (If Fixed)

```
...
updating flows - path finding at1.0348
DEBUG: flows=2, total_size=28, 2*flows=4
adjacency matrix generated at timestamp 1.0348
DEBUG run_distance_path_finding: Entered with flow_id=0, flows=2, 2*flows=4
...
HandleReadTwo : Received a Packet of size: 1420 at time 1.036
HandleReadTwo : Received a Packet of size: 272 at time 1.036
...
Simulation continues to 30 seconds
```

## If You See Recursion Warnings

```
ERROR: update_unstable recursion depth exceeded 100 (flow_id=0, current_hop=15)
```

This is **OK** - it means the protection is working! The simulation should continue.

## Commit to Test

Make sure you're testing commit **e8f438e** which has:
- ✅ Null pointer fixes
- ✅ Assignment/comparison fix (`=` → `==`)
- ✅ Recursion depth protection

You can verify by checking the file:
```bash
grep "MAX_RECURSION_DEPTH" ~/Downloads/ns-allinone-3.35/ns-3.35/scratch/routing.cc
```

Should output:
```
const uint32_t MAX_RECURSION_DEPTH = 100;  // Safety limit
```

If it doesn't, the file wasn't updated properly.

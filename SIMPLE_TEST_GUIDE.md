# Simple Test Commands - No Parameters Needed

## The Issue
The `use_enhanced_wormhole` parameter might not be in the version on Linux. But the good news is: **it defaults to `true`**!

## Simplified Test (RECOMMENDED)

Since wormhole is enabled by default, just run:

```bash
cd ~/Downloads/ns-allinone-3.35/ns-3.35/scratch
wget -O routing.cc https://raw.githubusercontent.com/kavindunisansala/routing/master/routing.cc

cd ~/Downloads/ns-allinone-3.35/ns-3.35
./waf build

# Run with just simTime parameter
./waf --run routing -- --simTime=30
```

## Or Even Simpler - Use Default Simulation Time

If `simTime` also has issues, run with NO parameters:

```bash
./waf --run routing
```

The wormhole attack will run automatically (it's enabled by default in the code).

## Check What Parameters Are Available

To see what command line options the program accepts:

```bash
./waf --run routing -- --PrintHelp
```

This will show all available options.

## Verify Code Was Updated

Check if the latest changes are in the file:

```bash
# Check for recursion protection
grep "MAX_RECURSION_DEPTH" ~/Downloads/ns-allinone-3.35/ns-3.35/scratch/routing.cc

# Should output:
# const uint32_t MAX_RECURSION_DEPTH = 100;  // Safety limit
```

If you don't see that line, the wget didn't work. Try:

```bash
cd ~/Downloads/ns-allinone-3.35/ns-3.35/scratch
rm routing.cc
wget https://raw.githubusercontent.com/kavindunisansala/routing/master/routing.cc
```

## All-in-One Test Command (Simplified)

```bash
cd ~/Downloads/ns-allinone-3.35/ns-3.35/scratch && \
rm -f routing.cc && \
wget https://raw.githubusercontent.com/kavindunisansala/routing/master/routing.cc && \
cd ~/Downloads/ns-allinone-3.35/ns-3.35 && \
./waf build && \
./waf --run routing -- --simTime=30 2>&1 | tee /tmp/routing-test.log && \
tail -50 /tmp/routing-test.log
```

## Check Default Values

The code has these defaults (from line 136):
```cpp
bool use_enhanced_wormhole = true;   // Wormhole ENABLED by default
```

So you don't need to specify it!

## If simTime Parameter Also Fails

Check what the default simTime is:

```bash
grep "simTime" ~/Downloads/ns-allinone-3.35/ns-3.35/scratch/routing.cc | head -20
```

And just run:

```bash
./waf --run routing 2>&1 | tee test.log
```

## Quick Diagnostic

1. **First**, verify the file updated:
   ```bash
   ls -lh ~/Downloads/ns-allinone-3.35/ns-3.35/scratch/routing.cc
   head -20 ~/Downloads/ns-allinone-3.35/ns-3.35/scratch/routing.cc
   ```

2. **Second**, check available options:
   ```bash
   cd ~/Downloads/ns-allinone-3.35/ns-3.35
   ./waf --run routing -- --PrintHelp
   ```

3. **Third**, run with minimal params:
   ```bash
   ./waf --run routing -- --simTime=30
   ```

4. **Fourth**, run with NO params:
   ```bash
   ./waf --run routing
   ```

## Expected Output

If the simulation runs, you should see:
```
...
Starting Enhanced Wormhole Attack
Wormhole endpoints: Node X <-> Node Y
...
updating flows - path finding at1.0348
DEBUG: flows=2, total_size=28, 2*flows=4
...
HandleReadTwo : Received a Packet of size: XXX at time X.XXX
...
```

## What to Report

Tell me:
1. What does `--PrintHelp` show?
2. Does it run with `--simTime=30` only?
3. Does it run with NO parameters?
4. Do you see "MAX_RECURSION_DEPTH" in the file?

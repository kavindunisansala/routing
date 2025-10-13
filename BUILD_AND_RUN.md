# Build and Run Instructions - Wormhole Attack Simulation

## Overview
This guide provides step-by-step instructions for building and running the wormhole attack simulation on Linux using ns-3.35.

---

## Prerequisites

### 1. System Requirements
- **OS**: Linux (Ubuntu 18.04/20.04/22.04 or similar)
- **RAM**: Minimum 4GB
- **Disk Space**: ~2GB for ns-3.35 installation
- **Compiler**: g++ 7.0 or later

### 2. Required Packages
Install dependencies using apt (Ubuntu/Debian):

```bash
sudo apt-get update
sudo apt-get install -y \
    gcc g++ python3 python3-dev \
    cmake make git \
    libsqlite3-dev libxml2 libxml2-dev \
    libc6-dev libc6-dev-i386 \
    mercurial gdb valgrind \
    gsl-bin libgsl-dev libgslcblas0 \
    flex bison tcpdump wireshark \
    qt5-default
```

### 3. Download ns-3.35
If not already installed:

```bash
cd ~/Downloads
wget https://www.nsnam.org/releases/ns-allinone-3.35.tar.bz2
tar -xjf ns-allinone-3.35.tar.bz2
cd ns-allinone-3.35/ns-3.35
```

---

## Installation Steps

### Step 1: Copy routing.cc to ns-3 scratch directory

Assuming your modified `routing.cc` is in `d:\routing - Copy\` (Windows path), first transfer it to Linux:

**Option A: Direct Copy (if on Linux)**
```bash
cp /path/to/routing.cc ~/Downloads/ns-allinone-3.35/ns-3.35/scratch/
```

**Option B: Using WSL (Windows Subsystem for Linux)**
```bash
cp /mnt/d/routing\ -\ Copy/routing.cc ~/Downloads/ns-allinone-3.35/ns-3.35/scratch/
```

**Option C: Using SCP (remote Linux)**
```bash
scp routing.cc user@linux-host:~/Downloads/ns-allinone-3.35/ns-3.35/scratch/
```

### Step 2: Navigate to ns-3 directory

```bash
cd ~/Downloads/ns-allinone-3.35/ns-3.35
```

### Step 3: Configure ns-3 (first time only)

```bash
./waf configure --enable-examples --enable-tests
```

**Expected Output:**
```
---- Summary of optional NS-3 features:
Build profile                 : debug
Build directory               : 
...
Python Bindings               : enabled
...
```

If you encounter errors about missing dependencies, install the required packages and re-run configure.

---

## Building the Simulation

### Step 1: Clean previous builds (optional but recommended)

```bash
./waf clean
```

### Step 2: Build the routing simulation

```bash
./waf
```

**Expected Output:**
```
Waf: Entering directory `/home/user/Downloads/ns-allinone-3.35/ns-3.35/build'
[1/1000] Compiling scratch/routing.cc
...
[1000/1000] Linking build/scratch/routing
Waf: Leaving directory `/home/user/Downloads/ns-allinone-3.35/ns-3.35/build'
Build commands will be stored in build/compile_commands.json
'build' finished successfully (X.XXs)
```

**Compilation Time**: Typically 5-15 minutes depending on system performance.

**Common Build Errors:**

1. **Error: `wormhole_attack.h: No such file or directory`**
   - **Cause**: Old version of routing.cc with external includes
   - **Fix**: Ensure you're using the updated inline version without `#include "wormhole_attack.h"`

2. **Error: `undefined reference to ns3::WormholeAttackManager`**
   - **Cause**: Incomplete inline implementation
   - **Fix**: Verify the entire wormhole implementation is present in routing.cc

3. **Error: `cannot find -lnetanim`**
   - **Cause**: NetAnim module not built
   - **Fix**: Run `./waf configure --enable-examples` and rebuild

---

## Running the Simulation

### Basic Run (Default Parameters)

```bash
./waf --run "routing"
```

### Run with Wormhole Attack Enabled (30 second simulation)

```bash
./waf --run "routing --use_enhanced_wormhole=true --simTime=30" | tee wormhole-test.log
```

**Command Breakdown:**
- `./waf --run` - ns-3 simulation runner
- `"routing"` - name of the simulation script
- `--use_enhanced_wormhole=true` - enable wormhole attack
- `--simTime=30` - run for 30 seconds (simulation time)
- `| tee wormhole-test.log` - save output to file while displaying on console

### Advanced Run with Custom Parameters

```bash
./waf --run "routing \
  --use_enhanced_wormhole=true \
  --simTime=30 \
  --attack_percentage=0.2 \
  --wormhole_bandwidth=1000Mbps \
  --wormhole_delay_us=1 \
  --wormhole_random_pairing=true \
  --wormhole_verification_flow_count=3 \
  --wormhole_verification_packet_rate=40.0 \
  --N_Vehicles=22 \
  --N_RSUs=6" \
  | tee wormhole-custom-test.log
```

---

## Verifying the Simulation

### 1. Check Console Output

Look for these key indicators:

```
=== Enhanced Wormhole Attack Configuration ===
Total Nodes (actual): 28
Malicious Nodes Selected: 6
Attack Percentage: 20%
Tunnel Bandwidth: 1000Mbps
Tunnel Delay: 1 microseconds
Created 3 wormhole tunnels
Attack active from 0s to 30s

=== WORMHOLE ATTACK STARTING on Node 5 (Tunnel 0) ===
Attack Type: AODV Route Poisoning (WAVE-compatible)
Peer Node: 12 @ 100.0.0.2
✓ Tunnel socket created and bound to port 9999
✓ AODV manipulation sockets ready
✓ Route poisoning scheduled (interval: 0.5s)
=== Wormhole attack ACTIVE on node 5 ===

[WORMHOLE] Node 5 intercepted AODV RREQ from 10.1.3.5 (Total intercepted: 1)
[WORMHOLE] Node 5 tunneled RREQ to peer 12 (Total tunneled: 1)
...

========== WORMHOLE ATTACK STATISTICS ==========
Total Tunnels: 3

Tunnel 0 (Node 5 <-> Node 12):
  Packets Intercepted: 47
  Packets Tunneled: 45
  Packets Dropped: 0
  Routing Packets Affected: 47
  Data Packets Affected: 0

AGGREGATE STATISTICS:
  Total Packets Intercepted: 138
  Total Packets Tunneled: 133
  Total Packets Dropped: 0
================================================
```

### 2. Check Generated Files

```bash
ls -lh wormhole-*.{log,csv}
```

**Expected Files:**
- `wormhole-test.log` - Full console output
- `wormhole-attack-results.csv` - Statistics in CSV format

### 3. Examine CSV Statistics

```bash
cat wormhole-attack-results.csv
```

**Expected Format:**
```csv
TunnelID,NodeA,NodeB,PacketsIntercepted,PacketsTunneled,PacketsDropped,RoutingAffected,DataAffected,AvgDelay
0,5,12,47,45,0,47,0,0.000023
1,8,19,52,50,0,52,0,0.000019
2,3,21,39,38,0,39,0,0.000021
TOTAL,ALL,ALL,138,133,0,138,0,0.000021
```

### 4. Verify Attack Activity

```bash
grep "\[WORMHOLE\]" wormhole-test.log | head -20
```

Should show RREQ interception and tunneling events.

---

## Troubleshooting

### Issue: No wormhole output in console

**Possible Causes:**
1. `use_enhanced_wormhole` not set to `true`
2. Simulation time too short (increase `--simTime`)
3. No AODV traffic generated

**Fix:**
```bash
./waf --run "routing --use_enhanced_wormhole=true --simTime=30 --wormhole_verification_flow_count=5"
```

### Issue: "Segmentation fault"

**Possible Causes:**
1. Memory corruption in custom tags (unrelated to wormhole)
2. Array out-of-bounds in `routing.cc`

**Fix:**
```bash
gdb --args ./build/scratch/routing --use_enhanced_wormhole=true --simTime=10
(gdb) run
(gdb) bt  # Get backtrace when crash occurs
```

### Issue: Very low packet counts in statistics

**Possible Causes:**
1. Verification traffic disabled
2. Attack percentage too low

**Fix:**
```bash
./waf --run "routing \
  --use_enhanced_wormhole=true \
  --simTime=60 \
  --attack_percentage=0.3 \
  --wormhole_verification_flow_count=10 \
  --wormhole_verification_packet_rate=100.0"
```

### Issue: "Address already in use" error

**Cause**: Previous simulation didn't clean up sockets properly

**Fix:**
```bash
pkill -9 routing
./waf --run "routing --use_enhanced_wormhole=true --simTime=30"
```

---

## Performance Optimization

### 1. Build in Optimized Mode

```bash
./waf configure --build-profile=optimized
./waf
```

**Speed Improvement**: 3-5x faster than debug mode

### 2. Disable Logging for Large Simulations

```bash
export NS_LOG=""
./waf --run "routing --use_enhanced_wormhole=true --simTime=300"
```

### 3. Reduce Visualization Overhead

If not using NetAnim visualization, comment out animation code in `routing.cc`:
```cpp
// AnimationInterface anim("routing-animation.xml");
```

---

## Command Reference

### Essential Commands

| Command | Description |
|---------|-------------|
| `./waf configure` | Configure ns-3 build system |
| `./waf` | Build all ns-3 modules and simulations |
| `./waf clean` | Remove build artifacts |
| `./waf --run "routing"` | Run the routing simulation with default parameters |
| `./waf --run "routing --help"` | Show all available command-line parameters |

### Useful Flags

| Flag | Type | Default | Description |
|------|------|---------|-------------|
| `--use_enhanced_wormhole` | bool | true | Enable wormhole attack |
| `--simTime` | double | 10 | Simulation duration (seconds) |
| `--attack_percentage` | double | 0.2 | Fraction of malicious nodes |
| `--wormhole_bandwidth` | string | "1000Mbps" | Tunnel bandwidth |
| `--wormhole_delay_us` | uint32 | 1 | Tunnel delay (microseconds) |
| `--wormhole_start_time` | double | 0.0 | Attack start time (seconds) |
| `--wormhole_stop_time` | double | 0.0 | Attack stop time (0=simTime) |
| `--N_Vehicles` | uint32 | 18 | Number of vehicle nodes |
| `--N_RSUs` | uint32 | 10 | Number of RSU nodes |

---

## Example Simulation Scenarios

### Scenario 1: Minimal Wormhole Attack (10 seconds)

```bash
./waf --run "routing \
  --use_enhanced_wormhole=true \
  --simTime=10 \
  --attack_percentage=0.15" \
  | tee minimal-wormhole.log
```

### Scenario 2: Aggressive Attack (50% malicious nodes)

```bash
./waf --run "routing \
  --use_enhanced_wormhole=true \
  --simTime=30 \
  --attack_percentage=0.5 \
  --wormhole_verification_flow_count=10" \
  | tee aggressive-wormhole.log
```

### Scenario 3: Delayed Attack (starts at 10 seconds)

```bash
./waf --run "routing \
  --use_enhanced_wormhole=true \
  --simTime=40 \
  --wormhole_start_time=10.0 \
  --wormhole_stop_time=35.0" \
  | tee delayed-wormhole.log
```

### Scenario 4: Large Network (50 vehicles, 20 RSUs)

```bash
./waf --run "routing \
  --use_enhanced_wormhole=true \
  --simTime=60 \
  --N_Vehicles=50 \
  --N_RSUs=20 \
  --attack_percentage=0.2" \
  | tee large-network-wormhole.log
```

---

## Log Analysis

### Extract Attack Statistics

```bash
# Count RREQ interceptions
grep "intercepted AODV RREQ" wormhole-test.log | wc -l

# Count tunneling events
grep "tunneled RREQ to peer" wormhole-test.log | wc -l

# View attack timeline
grep "WORMHOLE" wormhole-test.log | grep -E "STARTING|STOPPING|intercepted"

# Get final statistics
grep -A 20 "AGGREGATE STATISTICS" wormhole-test.log
```

### Convert CSV to Human-Readable Format

```bash
column -t -s, wormhole-attack-results.csv
```

---

## Visualization (Optional)

### Generate NetAnim XML (if enabled in code)

```bash
./waf --run "routing --use_enhanced_wormhole=true --simTime=30"
# This creates routing-animation.xml

# View in NetAnim
netanim routing-animation.xml
```

**Note**: NetAnim must be installed separately:
```bash
cd ~/Downloads/ns-allinone-3.35/netanim-3.108
qmake NetAnim.pro
make
./NetAnim
```

---

## Cleanup

### Remove Build Artifacts

```bash
cd ~/Downloads/ns-allinone-3.35/ns-3.35
./waf clean
```

### Remove Generated Logs and CSV Files

```bash
rm -f wormhole-*.log wormhole-*.csv routing-animation.xml
```

---

## Quick Reference

### One-Command Test (Copy-Paste Ready)

```bash
cd ~/Downloads/ns-allinone-3.35/ns-3.35 && \
./waf && \
./waf --run "routing --use_enhanced_wormhole=true --simTime=30" | tee wormhole-test.log
```

### Expected Runtime

| Simulation Time | Wall Clock Time (debug) | Wall Clock Time (optimized) |
|-----------------|-------------------------|------------------------------|
| 10 seconds      | ~30 seconds             | ~10 seconds                  |
| 30 seconds      | ~90 seconds             | ~30 seconds                  |
| 60 seconds      | ~180 seconds            | ~60 seconds                  |

---

## Support

For issues specific to:
- **ns-3 installation**: https://www.nsnam.org/docs/installation/html/
- **AODV routing**: https://www.nsnam.org/docs/models/html/aodv.html
- **Wormhole attack code**: See `CHANGELOG.md` for implementation details

---

## Next Steps

1. ✅ Build and run with default parameters
2. ✅ Verify wormhole attack activity in logs
3. ✅ Examine `wormhole-attack-results.csv` statistics
4. 🔍 Experiment with different attack parameters
5. 📊 Analyze impact on network performance
6. 📝 Document findings

---

**Document Version**: 1.0  
**Last Updated**: 2025-10-14  
**ns-3 Version**: 3.35  
**Tested Platforms**: Ubuntu 20.04 LTS, Ubuntu 22.04 LTS

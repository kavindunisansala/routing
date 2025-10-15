# Blackhole Attack - Quick Start Guide

## What is a Blackhole Attack?

A **blackhole attack** is when malicious nodes:
1. **Advertise fake routes** claiming to have the best path to destinations
2. **Attract traffic** to themselves
3. **Drop all received packets** (they disappear into a "black hole")

## Quick Test (3 Commands)

```bash
# 1. Enable blackhole attack in routing.cc (already done!)
# 2. Rebuild
cd "d:\routing - Copy"
./waf clean
./waf build

# 3. Run with blackhole attack
./waf --run "routing --enable_blackhole_attack=true" > blackhole_test.log 2>&1
```

## Check Results

```bash
# See blackhole configuration
grep "Blackhole Attack" blackhole_test.log

# See which nodes are blackholes
grep "\[BLACKHOLE\] Node" blackhole_test.log

# See statistics
grep -A 20 "BLACKHOLE ATTACK STATISTICS" blackhole_test.log

# Or check the CSV file
cat blackhole-attack-results.csv
```

## Expected Output

### During Initialization:
```
=== Enhanced Blackhole Attack Configuration ===
Total Nodes (actual): 23
Malicious Nodes Selected: 3
Attack Percentage: 15%
Drop Data Packets: Yes
Drop Routing Packets: No
Advertise Fake Routes: Yes
Fake Sequence Number: 999999
Fake Hop Count: 1
Configured 3 blackhole nodes
Attack active from 0s to 10s
```

### During Simulation:
```
[BLACKHOLE] Node 5 activated at 0s
[BLACKHOLE] Node 12 activated at 0s
[BLACKHOLE] Node 18 activated at 0s
...
[BLACKHOLE] Node 5 deactivated at 10s
```

### Final Statistics:
```
========== BLACKHOLE ATTACK STATISTICS ==========
Total Blackhole Nodes: 3
AGGREGATE STATISTICS:
  Data Packets Dropped: 342
  Fake RREPs Generated: 28
PER-NODE STATISTICS:
  Node 5: Data Packets Dropped: 124
  Node 12: Data Packets Dropped: 115
  Node 18: Data Packets Dropped: 103
```

## Configuration Options

### Basic Usage (Default Settings)

```bash
# Just enable it - uses 15% of nodes as blackholes
./waf --run "routing --enable_blackhole_attack=true"
```

### More Aggressive Attack

```bash
# 30% of nodes as blackholes, drop routing packets too
./waf --run "routing \
  --enable_blackhole_attack=true \
  --blackhole_attack_percentage=0.3 \
  --blackhole_drop_routing=true"
```

### Delayed Attack

```bash
# Start blackhole attack after 5 seconds
./waf --run "routing \
  --enable_blackhole_attack=true \
  --blackhole_start_time=5 \
  --blackhole_stop_time=15"
```

### Both Wormhole + Blackhole

```bash
# Run both attacks simultaneously
./waf --run "routing \
  --enable_blackhole_attack=true \
  --enable_wormhole_detection=true \
  --enable_wormhole_mitigation=true"
```

## Key Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `enable_blackhole_attack` | false | Turn on/off blackhole attack |
| `blackhole_attack_percentage` | 0.15 | % of nodes (0.15 = 15%) |
| `blackhole_drop_data` | true | Drop data packets |
| `blackhole_drop_routing` | false | Drop routing packets |
| `blackhole_advertise_fake_routes` | true | Send fake RREPs |
| `blackhole_fake_sequence_number` | 999999 | Fake seq number |
| `blackhole_fake_hop_count` | 1 | Fake hop count |
| `blackhole_start_time` | 0.0 | When to start (seconds) |
| `blackhole_stop_time` | 0.0 | When to stop (0 = simTime) |

## Visualization

In NetAnim, blackhole nodes appear:
- **Color**: Black
- **Size**: Larger (4x4)
- **Label**: "BLACKHOLE-X"

## Output Files

- **blackhole-attack-results.csv**: Detailed per-node statistics
- **Console output**: Summary statistics

## What to Look For

### Signs of Successful Attack:

1. ✅ **Blackhole nodes activated**: Should see activation messages
2. ✅ **Packets dropped**: "Data Packets Dropped" > 0
3. ✅ **Fake RREPs sent**: "Fake RREPs Generated" > 0
4. ✅ **Network impact**: Lower packet delivery ratio

### If Nothing Happens:

1. Check `enable_blackhole_attack=true` is set
2. Check blackhole nodes are selected (should see count > 0)
3. Check attack timing (start_time < simTime)
4. Increase attack percentage for more impact

## Compare with Normal Network

```bash
# Run without attack
./waf --run "routing --enable_blackhole_attack=false" > normal.log

# Run with attack
./waf --run "routing --enable_blackhole_attack=true" > attack.log

# Compare packet delivery
grep "PDR\|Delivery" normal.log
grep "PDR\|Delivery" attack.log
```

**Expected:** PDR should be lower with blackhole attack

## Quick Checks (PowerShell)

```powershell
# Check if blackhole is configured
Select-String -Path blackhole_test.log -Pattern "Blackhole Attack Configuration"

# Count how many nodes are blackholes
(Select-String -Path blackhole_test.log -Pattern "Node \d+ activated").Count

# See aggregate statistics
Select-String -Path blackhole_test.log -Pattern "AGGREGATE STATISTICS" -Context 0,5

# Check CSV results
Get-Content blackhole-attack-results.csv
```

## Troubleshooting

### "No blackhole nodes configured"
**Fix:** Set `blackhole_attack_percentage` higher (e.g., 0.2 = 20%)

### "Data Packets Dropped: 0"
**Possible causes:**
- Blackhole nodes not receiving traffic
- Fake routes not being accepted
- Attack timing issue

**Fix:**
- Ensure `blackhole_advertise_fake_routes=true`
- Increase `blackhole_attack_percentage`
- Check attack is active during simulation

### Build Errors
**Fix:**
```bash
./waf clean
./waf configure --enable-examples --enable-tests
./waf build
```

## Next Steps

1. **Test basic blackhole**: Run with default settings
2. **Adjust parameters**: Try different percentages and behaviors
3. **Measure impact**: Compare PDR with/without attack
4. **Combine attacks**: Test wormhole + blackhole together
5. **Develop detection**: Use statistics to build detection system

---

## Success Criteria

✅ You've successfully implemented blackhole attack if you see:
1. "Enhanced Blackhole Attack Configuration" in output
2. Blackhole nodes activated (e.g., "Node 5 activated at 0s")
3. Non-zero packet drops in statistics
4. CSV file created with results

**The blackhole attack is ready to use!** 🎯

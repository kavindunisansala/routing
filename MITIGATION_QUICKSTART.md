# Blackhole Mitigation - Quick Start

## 🚀 Quick Test (5 Commands)

```bash
# 1. Download latest code
cd ~/Downloads/ns-allinone-3.35/ns-3.35/scratch
wget https://raw.githubusercontent.com/kavindunisansala/routing/master/routing.cc -O routing.cc

# 2. Build
cd ~/Downloads/ns-allinone-3.35/ns-3.35
./waf build

# 3. Run with attack + mitigation
./waf --run "routing --enable_blackhole_attack=true --enable_blackhole_mitigation=true --simTime=10" > mitigation_test.log 2>&1

# 4. Check detection events
grep "BLACKLISTED" mitigation_test.log

# 5. View results
cat blackhole-mitigation-results.csv
```

## Expected Output

### Console Detection Messages:
```
[MITIGATION] ⚠️  Node 29 BLACKLISTED at 3.45s (PDR: 8.75%, 292/320 dropped)
[MITIGATION] ⚠️  Node 16 BLACKLISTED at 4.12s (PDR: 15.2%, 78/92 dropped)
[MITIGATION] ⚠️  Node 20 BLACKLISTED at 5.78s (PDR: 22.1%, 134/172 dropped)
```

### Final Statistics:
```
========== BLACKHOLE MITIGATION STATISTICS ==========
Overall PDR: 68.5%
Blacklisted Nodes: 3

BLACKLISTED NODES:
  Node 29: PDR=8.75% (292/320 dropped)
  Node 16: PDR=15.2% (78/92 dropped)
  Node 20: PDR=22.1% (134/172 dropped)
```

### CSV File:
```csv
NodeID,PacketsSentVia,PacketsDelivered,PacketsDropped,PDR,Blacklisted,BlacklistTime
16,92,14,78,15.22,1,4.12
20,172,38,134,22.09,1,5.78
29,320,28,292,8.75,1,3.45
```

## Test Scenarios

### Scenario 1: Default Detection (Balanced)
```bash
./waf --run "routing --enable_blackhole_attack=true --enable_blackhole_mitigation=true"
```
**Expects**: 3-4 nodes blacklisted with 50% PDR threshold

### Scenario 2: Aggressive Detection
```bash
./waf --run "routing --enable_blackhole_attack=true --enable_blackhole_mitigation=true --blackhole_pdr_threshold=0.7"
```
**Expects**: Faster detection, may include false positives

### Scenario 3: Conservative Detection
```bash
./waf --run "routing --enable_blackhole_attack=true --enable_blackhole_mitigation=true --blackhole_pdr_threshold=0.3 --blackhole_min_packets=20"
```
**Expects**: Slower but more accurate detection

## Configuration Cheat Sheet

| What You Want | Configuration |
|---------------|---------------|
| **Faster detection** | `--blackhole_min_packets=5` |
| **More accurate** | `--blackhole_min_packets=20` |
| **Catch more nodes** | `--blackhole_pdr_threshold=0.7` |
| **Fewer false positives** | `--blackhole_pdr_threshold=0.3` |
| **Longer test** | `--simTime=20` |
| **More attackers** | `--blackhole_attack_percentage=0.3` |

## Success Checklist

✅ Build completes without errors  
✅ See `[MITIGATION] Initialized` message  
✅ See `[MITIGATION] ⚠️  Node X BLACKLISTED` messages  
✅ CSV file created with blacklisted nodes  
✅ Blacklisted nodes match blackhole attack nodes  

## Common Issues

### No blacklisting happening?
```bash
# Try more aggressive threshold
--blackhole_pdr_threshold=0.8
```

### Too many false positives?
```bash
# Require more evidence
--blackhole_min_packets=15 --blackhole_pdr_threshold=0.4
```

### Want detailed logs?
```bash
# Run and save full log
./waf --run "routing --enable_blackhole_attack=true --enable_blackhole_mitigation=true" > detailed.log 2>&1

# Then search for key events
grep -E "\[BLACKHOLE\]|\[MITIGATION\]" detailed.log
```

## Full Documentation

For complete details, see:
- `BLACKHOLE_MITIGATION_GUIDE.md` - Full implementation guide
- `MITIGATION_IMPLEMENTATION_COMPLETE.md` - Implementation summary
- `BLACKHOLE_ATTACK_GUIDE.md` - Blackhole attack documentation

## What's Implemented

✅ PDR-based packet monitoring  
✅ Automatic blacklist detection  
✅ Per-node statistics tracking  
✅ CSV export for analysis  
✅ Real-time console alerts  
✅ Configurable thresholds  
✅ Integration with blackhole attack  

## What's NOT Implemented (Future Work)

❌ Route avoidance for blacklisted nodes  
❌ Second-chance white-listing  
❌ Network-wide broadcast alerts  
❌ Adaptive thresholds  
❌ Integration with routing protocol  

---

**Ready to test! Pull, build, and run the commands above.** 🚀

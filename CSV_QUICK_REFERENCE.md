# CSV Export Quick Reference

## ✅ All Mitigation Statistics Now Export to CSV

### 1. Blackhole Mitigation CSV ✅
**File:** `blackhole-mitigation-results.csv`
**Enabled by:** `--enable_blackhole_mitigation=true`

**Columns:**
```
NodeID,PacketsSentVia,PacketsDelivered,PacketsDropped,PDR,Blacklisted,BlacklistTime
```

**Already implemented** - no changes needed!

---

### 2. Wormhole Detection CSV ✅
**File:** `wormhole-detection-results.csv`
**Enabled by:** `--enable_wormhole_detection=true`

**Columns:**
```
Metric,Value
DetectionEnabled,true/false
MitigationEnabled,true/false
LatencyThresholdMultiplier,<value>
BaselineLatency_ms,<ms>
TotalFlows,<count>
FlowsAffected,<count>
FlowsDetected,<count>
AffectedPercentage,<percent>
AvgNormalLatency_ms,<ms>
AvgWormholeLatency_ms,<ms>
AvgLatencyIncrease_percent,<percent>
RouteChangesTriggered,<count>
NodesBlacklisted,<count>
```

**Now exports at cleanup** - enhanced with final export call!

---

### 3. Packet Tracking CSV ✅
**File:** `packet-delivery-analysis.csv`
**Enabled by:** `--enable_packet_tracking=true`

**Columns:**
```
PacketID,SourceNode,DestNode,SendTime,ReceiveTime,DelayMs,Delivered,WormholeOnPath,BlackholeOnPath
```

**Just implemented** - detailed per-packet analysis!

---

## 📊 What Changed

### Before:
- ❌ Wormhole detection only printed to console (no CSV at cleanup)
- ✅ Blackhole mitigation already had CSV export
- ❌ No per-packet tracking

### After:
- ✅ Wormhole detection exports CSV at cleanup
- ✅ Blackhole mitigation CSV export (no change)
- ✅ Per-packet tracking with CSV export
- ✅ Summary of all CSV files printed at end

---

## 🎯 Quick Test Commands

### Test 1: Wormhole Mitigation Statistics
```powershell
./waf --run "routing --enable_wormhole_attack=true --enable_wormhole_detection=true --enable_wormhole_mitigation=true"
# Exports: wormhole-attack-results.csv, wormhole-detection-results.csv
```

### Test 2: Blackhole Mitigation Statistics
```powershell
./waf --run "routing --enable_blackhole_attack=true --enable_blackhole_mitigation=true"
# Exports: blackhole-attack-results.csv, blackhole-mitigation-results.csv
```

### Test 3: All Statistics + Packet Tracking
```powershell
./waf --run "routing --enable_wormhole_attack=true --enable_wormhole_detection=true --enable_blackhole_attack=true --enable_blackhole_mitigation=true --enable_packet_tracking=true"
# Exports: All 5 CSV files!
```

---

## 📈 Expected Console Output at End

```
=== Wormhole Detection Summary ===
Detection Status: ENABLED
Mitigation Status: ENABLED
...
Wormhole detection results exported to wormhole-detection-results.csv

========== CSV FILES GENERATED ==========
  ✓ wormhole-attack-results.csv
  ✓ wormhole-detection-results.csv
  ✓ blackhole-attack-results.csv
  ✓ blackhole-mitigation-results.csv
  ✓ packet-delivery-analysis.csv
=========================================
```

---

## ✅ Summary

**All mitigation statistics now output to CSV files:**

1. ✅ **Blackhole Mitigation** → `blackhole-mitigation-results.csv`
2. ✅ **Wormhole Detection** → `wormhole-detection-results.csv`
3. ✅ **Packet Tracking** → `packet-delivery-analysis.csv`

**Plus attack statistics:**
4. ✅ **Wormhole Attack** → `wormhole-attack-results.csv`
5. ✅ **Blackhole Attack** → `blackhole-attack-results.csv`

**Total: 5 CSV files with comprehensive statistics!** 🎉

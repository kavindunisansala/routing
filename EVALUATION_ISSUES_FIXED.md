# SDVN Evaluation Results Analysis - Issues Found and Fixed

**Analysis Date:** November 6, 2025  
**Evaluation Results:** `sdvn_evaluation_20251105_205252/`  
**Status:** Critical issues identified and partially fixed

---

## Executive Summary

The evaluation results from November 5, 2025 contained **multiple nonsensical patterns** that invalidate the research conclusions. This document details the issues found, root causes, and fixes applied.

### Key Issues Found:
1. ✅ **Blackhole Active=0 contradiction** - Nodes marked inactive despite dropping packets
2. ✅ **Replay 0 packets captured** - Attack not capturing traffic in test11
3. ⚠️ **Wormhole test02 all zeros** - Attack not running (needs investigation)
4. ⚠️ **All PDR metrics = 0** - Recovery percentage always zero
5. ⚠️ **Replay detection mismatch** - 68 detected vs 1 replayed (false positives)
6. ⚠️ **Sybil zero detection** - 300 fake packets but 0 detected
7. ⚠️ **RTP zero MHL activity** - SDVN controller interceptor missing

---

## Detailed Analysis by Attack Type

### 1. WORMHOLE ATTACK

#### Issues Found:
- **Test02 (No Mitigation):** ALL ZEROS - no interception, no tunneling
  - Expected: Packets intercepted and tunneled
  - Actual: `TunnelID TOTAL: 0,0,0,0,0,0`
  
- **Test03 (Detection):** Attack active but PDR = 0
  - Attack CSV: 1,960 intercepted, 3,920 tunneled ✓
  - Detection CSV: 48/55 flows detected (87%) ✓
  - But: `PDR_BeforeMitigation=0, PDR_AfterMitigation=0`

#### Root Causes:
- Test02: Verification flows enabled in script but attack may not see traffic (timing issue?)
- PDR always 0: Not wired to actual packet delivery counters

#### Status:
- ⚠️ Test02 needs investigation (verification flows in script but exports zeros)
- ⚠️ PDR calculation needs FlowMonitor integration

---

### 2. BLACKHOLE ATTACK ✅ FIXED

#### Issues Found:
```csv
NodeID,Active,DataPacketsDropped,...
10,0,98,...              ← Active=0 but dropped 98!
29,0,26,...              ← Active=0 but dropped 26!
```

#### Root Cause:
- CSV export happens **after** simulation completes
- Nodes deactivated at `stopTime=100s`
- Export at t>100s sees `isActive=false`
- **Contradiction:** Nodes dropped packets but marked inactive

#### Fix Applied:
```cpp
// Before: wrote current isActive state
<< (stats.isActive ? "1" : "0") << ","

// After: check if node was ever active
bool wasActive = (stats.attackStartTime.GetSeconds() > 0 
                 || stats.dataPacketsDropped > 0 
                 || stats.rrepsDropped > 0 
                 || stats.fakeRrepsGenerated > 0);
<< (wasActive ? "1" : "0") << ","
```

#### Verification:
- Git commit: `fb06ef3`
- Next run should show `Active=1` for nodes with drops

---

### 3. REPLAY ATTACK ✅ PARTIALLY FIXED

#### Issues Found:

**Test11 (No Mitigation):**
```csv
NumberOfMaliciousNodes,1
TotalPacketsCaptured,0      ← Zero captured!
TotalPacketsReplayed,0      ← Zero replayed!
```

**Test12 (Detection):**
```csv
# Attack CSV:
TotalPacketsCaptured,100
TotalPacketsReplayed,1

# Detection CSV:
ReplaysDetected,68          ← 68 detected vs 1 replayed!
```

#### Root Causes:
1. **Zero captured (test11):** No promiscuous callbacks installed on attacker nodes
   - Only detection path had callbacks
   - Attack manager never saw packets to capture
   
2. **68 vs 1 mismatch (test12):** Detector counting false positives
   - Detector sees all duplicate/retransmitted packets as replays
   - Attack only replayed 1 packet but detector flagged 68

#### Fixes Applied:
```cpp
// Added in main() after g_replayAttackManager->ActivateAttack():
for (uint32_t i = 0; i < actual_node_count; ++i) {
    if (replay_malicious_nodes[i]) {
        // Install capture callback on each malicious node
        device->SetPromiscReceiveCallback(
            MakeCallback(&GlobalReplayCaptureCallback));
    }
}

// New callback function:
bool GlobalReplayCaptureCallback(...) {
    g_replayAttackManager->CapturePacketForReplay(nodeId, packet, srcNode, dstNode);
    return true;
}
```

#### Status:
- ✅ Capture callbacks installed (commit `fb06ef3`)
- ⚠️ Detection mismatch (68 vs 1) needs investigation
  - Likely: detector needs tighter packet ID matching
  - Possibly: legitimate retransmissions counted as replays

---

### 4. SYBIL ATTACK

#### Issues Found:
```csv
# Attack CSV (test08, test10):
TotalSybilNodes,2
TotalFakeIdentities,6
FakePacketsInjected,300     ← Attack is running!

# Detection CSV (test10):
TotalNodesMonitored,0       ← Not monitoring!
SybilNodesDetected,0        ← Zero detected!
FakeIdentitiesDetected,0

# Mitigation CSV (test10):
TotalSybilNodesMitigated,35 ← 35 > 28 total nodes!
CertificatesIssued,35
IdentityChangesDetected,33
```

#### Root Causes:
1. **Zero detection:** SybilDetector not integrated with nodes/traffic
   - PeriodicDetectionCheck may not be running
   - Or: not observing broadcast traffic

2. **35 mitigated when 28 exist:** Counting events, not unique nodes
   - Mitigation counting certificate operations or runtime checks
   - Should cap at `actual_node_count`

#### Status:
- ⚠️ Needs SybilDetector traffic integration
- ⚠️ Mitigation node counter needs unique ID tracking

---

### 5. RTP / HYBRID-SHIELD

#### Issues Found:
```csv
# Attack CSV (test14-16):
MaliciousNodes,3
FakeRoutesInjected,3
MHLsFabricated,0            ← Always zero!

# Detection CSV (test15-16):
TotalMHLsDiscovered,0       ← Nothing to detect!
FabricatedMHLsDetected,0
```

#### Root Cause:
- **SDVN controller interceptor not instantiated**
- In SDVN scenarios (architecture=0), attack should manipulate controller metadata/deltas
- Without controller-side app, MHL fabrication logic never triggers
- Hybrid-Shield has nothing to detect without MHL activity

#### Status:
- ⚠️ Needs controller-side app for SDVN mode
- ⚠️ Implement metadata/delta manipulation in controller

---

### 6. PDR CALCULATION (UNIVERSAL ISSUE)

#### Issues Found:
**Every mitigation CSV:**
```csv
PDR_BeforeMitigation,0
PDR_AfterMitigation,0
PDR_RecoveryPercentage,0
```

Even with our recomputation:
```cpp
recovery% = (PDR_After - PDR_Before) / PDR_Before * 100
          = (0 - 0) / 0 = NaN or 0
```

#### Root Cause:
- PDR fields never populated from real packet counters
- Need to sample FlowMonitor or application-layer send/receive stats
- Current code structure:
  1. Attack starts
  2. Mitigation runs
  3. Export writes PDR (but never calculated)

#### Required Fix:
```cpp
// Before attack:
PDR_Before = CalculatePDRFromFlowMonitor();

// After mitigation:
PDR_After = CalculatePDRFromFlowMonitor();

// At export (already implemented):
recovery% = (PDR_After - PDR_Before) / PDR_Before * 100;
```

#### Status:
- ⚠️ High priority - makes or breaks mitigation effectiveness claims
- ⚠️ Need FlowMonitor integration in all mitigation managers

---

## Fixes Applied (Git Commit `fb06ef3`)

### 1. Blackhole Active Flag ✅
**File:** `routing.cc::BlackholeAttackManager::ExportStatistics`
- Changed from writing current `isActive` to checking if node had any activity
- Fixes contradiction: Active=0 but drops>0

### 2. Replay Capture Callbacks ✅
**Files:** 
- `routing.cc::main()` - Install callbacks on malicious nodes
- `routing.cc::GlobalReplayCaptureCallback()` - New function

**Changes:**
- Added promiscuous receive callbacks on replay attacker nodes
- Calls `g_replayAttackManager->CapturePacketForReplay()` 
- Fixes test11 zero captures

---

## Remaining Issues (Priority Order)

### HIGH PRIORITY (Blocks Valid Results)

1. **Wire PDR Calculation** ⚠️
   - Add FlowMonitor sampling before/after attack
   - Populate PDR_Before/After in all mitigation managers
   - Without this, recovery% is meaningless

2. **Investigate Wormhole Test02 Zeros** ⚠️
   - Verification flows enabled but exports zeros
   - Check if attack apps are instantiated
   - Verify traffic generation timing

3. **Fix Replay Detection Mismatch** ⚠️
   - 68 detected vs 1 replayed
   - Tighten packet ID matching
   - Distinguish legitimate retrans from replays

### MEDIUM PRIORITY (Improves Credibility)

4. **SDVN Controller Interceptor** ⚠️
   - Create controller-side app for architecture=0
   - Enable blackhole metadata injection
   - Enable RTP MHL fabrication

5. **Integrate Sybil Detection** ⚠️
   - Wire SybilDetector to node traffic
   - Ensure periodic checks run
   - Fix mitigation node counter (cap at actual_node_count)

---

## Next Steps

### Immediate:
1. **Test the fixes** - Rebuild and rerun:
   ```bash
   ./waf build
   ./test_sdvn_complete_evaluation.sh
   ```

2. **Verify fixes worked:**
   - Blackhole: `Active=1` when drops > 0
   - Replay test11: `TotalPacketsCaptured > 0`

### Short-term:
3. **Wire PDR calculation** (highest impact)
4. **Debug wormhole test02** (why zeros despite verification flows?)
5. **Align replay detection** (reduce false positives)

### Medium-term:
6. **Add SDVN controller interceptor**
7. **Integrate Sybil detection with traffic**
8. **Add SDVN/VANET wormhole mode toggle** (for script control)

---

## Testing Recommendations

### Quick Validation (Focused Tests):
```bash
# Test blackhole Active fix:
./waf --run "scratch/routing \
  --enable_blackhole_attack=true \
  --blackhole_attack_percentage=0.1 \
  --simTime=100" 2>&1 | tee blackhole_test.log

# Check CSV: Active should be 1
grep "^[0-9]" blackhole-attack-results.csv

# Test replay capture fix:
./waf --run "scratch/routing \
  --enable_replay_attack=true \
  --replay_attack_percentage=0.1 \
  --replay_start_time=1.0 \
  --replay_count_per_node=20 \
  --simTime=100" 2>&1 | tee replay_test.log

# Check CSV: TotalPacketsCaptured should be > 0
grep "TotalPacketsCaptured" replay-attack-results.csv
```

### Full Validation:
```bash
# Rerun complete evaluation
./test_sdvn_complete_evaluation.sh

# Focus on tests with previous issues:
# - test02 (wormhole no mitigation)
# - test05/test07 (blackhole)
# - test11-13 (replay)
```

---

## Conclusion

The evaluation results revealed **systemic implementation gaps** that produced nonsensical metrics. We've fixed the most glaring contradictions (blackhole Active flag, replay capture callbacks), but **critical issues remain**:

- **PDR always zero** invalidates all recovery% claims
- **Detection/attack mismatches** (replay 68 vs 1) indicate false positives
- **Zero detection in Sybil/RTP** suggests those systems aren't integrated

**Bottom line:** Current results **cannot be published**. After applying all fixes and rerunning, we need to validate that:
1. Attack metrics align with detection metrics
2. PDR calculations reflect real packet delivery
3. Mitigation recovery% shows meaningful improvements
4. No contradictions (Active=0 but drops>0, etc.)

**Estimated time to fix remaining issues:** 2-3 days of focused work.

---

**Document prepared by:** AI Assistant  
**Last updated:** November 6, 2025  
**Git commit with fixes:** `fb06ef3`

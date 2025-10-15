# Debug Build - Diagnose Blacklisting Issue

## Problem
Detection is working (43 flows detected), but `Nodes Blacklisted: 0`.

## Debug Changes Added

I've added extensive debug logging to identify the issue:

### 1. Attack Manager Connection Check
```
[DETECTOR] Attempting to connect with attack manager...
[DETECTOR] g_wormholeManager = NOT NULL / NULL
[DETECTOR] GetMaliciousNodeIds() returned X nodes
```

### 2. Malicious Nodes Loading
```
[DETECTOR] SetKnownMaliciousNodes called with X nodes
[DETECTOR]   - Node X marked as malicious
[DETECTOR] Loaded X known malicious nodes for reference
```

### 3. Blacklisting Execution
```
[DETECTOR] IdentifyAndBlacklistSuspiciousNodes called for flow X -> Y
[DETECTOR] m_knownMaliciousNodes.size() = X
[DETECTOR] Using Strategy 1: Blacklisting confirmed malicious nodes
[DETECTOR] MITIGATION: Node X blacklisted (confirmed wormhole endpoint)
```

## How to Test

### Step 1: Rebuild with Debug Logging
```bash
cd "d:\routing - Copy"
./waf clean
./waf build
```

### Step 2: Run with Debug Output
```bash
./waf --run routing > output_debug.log 2>&1
```

### Step 3: Check Debug Messages

#### A. Check if attack manager is connected
```bash
grep "g_wormholeManager" output_debug.log
```
**Expected:** Should show "NOT NULL"
**If shows "NULL":** Attack manager not created before detector

#### B. Check if malicious nodes are loaded
```bash
grep "SetKnownMaliciousNodes called" output_debug.log
```
**Expected:** Should show number of nodes (should be 6-8)
**If not found:** SetKnownMaliciousNodes never called

#### C. Check which nodes are marked malicious
```bash
grep "marked as malicious" output_debug.log
```
**Expected:** Should list nodes like 0, 3, 6, 9, 10, 12, 15, 20
**If empty:** No nodes being loaded

#### D. Check if blacklisting function is called
```bash
grep "IdentifyAndBlacklistSuspiciousNodes called" output_debug.log
```
**Expected:** Should appear 43 times (once per detected flow)
**If not found:** Blacklisting function never executed

#### E. Check m_knownMaliciousNodes size during blacklisting
```bash
grep "m_knownMaliciousNodes.size()" output_debug.log | head -5
```
**Expected:** Should show size > 0 (e.g., "= 8")
**If shows "= 0":** Nodes cleared or not properly stored

#### F. Check if Strategy 1 is used
```bash
grep "Using Strategy 1" output_debug.log
```
**Expected:** Should appear 43 times
**If not found:** Strategy 1 condition failing (empty set)

#### G. Check actual blacklisting
```bash
grep "blacklisted (confirmed wormhole endpoint)" output_debug.log
```
**Expected:** Should show 8 nodes being blacklisted
**If not found:** BlacklistNode() failing or already blacklisted

## Possible Issues and Solutions

### Issue 1: g_wormholeManager is NULL
**Cause:** Detector created before attack manager
**Solution:** Reorder initialization in main()

### Issue 2: GetMaliciousNodeIds() returns 0 nodes
**Cause:** m_maliciousNodes vector empty or all false
**Solution:** Check wormhole attack initialization

### Issue 3: SetKnownMaliciousNodes never called
**Cause:** if condition failing or code not reached
**Solution:** Check simulation flow and conditions

### Issue 4: m_knownMaliciousNodes.size() = 0 during blacklisting
**Cause:** Set cleared or not properly initialized
**Solution:** Check member variable initialization

### Issue 5: BlacklistNode() not executing
**Cause:** Already blacklisted or function issue
**Solution:** Check BlacklistNode() implementation

## Quick Debug Check (One Command)

```bash
cd "d:\routing - Copy" && ./waf clean && ./waf build && ./waf --run routing 2>&1 | tee output_debug.log | grep -E "\[DETECTOR\].*malicious|Nodes Blacklisted"
```

This will:
1. Rebuild
2. Run simulation
3. Save full output to output_debug.log
4. Display only detector messages about malicious nodes

## What to Share

If blacklisting still doesn't work, share these outputs:

```bash
# 1. Manager connection status
grep "g_wormholeManager" output_debug.log

# 2. Nodes loaded
grep "SetKnownMaliciousNodes" output_debug.log

# 3. Blacklisting attempts
grep "IdentifyAndBlacklistSuspiciousNodes called" output_debug.log | wc -l

# 4. Known nodes size
grep "m_knownMaliciousNodes.size()" output_debug.log | head -1

# 5. Actual blacklisting
grep "blacklisted (confirmed wormhole endpoint)" output_debug.log
```

## Expected Complete Debug Flow

If everything works correctly, you should see:

```
[DETECTOR] Attempting to connect with attack manager...
[DETECTOR] g_wormholeManager = NOT NULL
[DETECTOR] GetMaliciousNodeIds() returned 8 nodes
[DETECTOR]   Malicious node: 0
[DETECTOR]   Malicious node: 3
[DETECTOR]   Malicious node: 6
[DETECTOR]   Malicious node: 9
[DETECTOR]   Malicious node: 10
[DETECTOR]   Malicious node: 12
[DETECTOR]   Malicious node: 15
[DETECTOR]   Malicious node: 20
[DETECTOR] SetKnownMaliciousNodes called with 8 nodes
[DETECTOR]   - Node 0 marked as malicious
[DETECTOR]   - Node 3 marked as malicious
[DETECTOR]   - Node 6 marked as malicious
[DETECTOR]   - Node 9 marked as malicious
[DETECTOR]   - Node 10 marked as malicious
[DETECTOR]   - Node 12 marked as malicious
[DETECTOR]   - Node 15 marked as malicious
[DETECTOR]   - Node 20 marked as malicious
[DETECTOR] Loaded 8 known malicious nodes for reference
Detector linked with attack manager: 8 known malicious nodes

... during simulation ...

[DETECTOR] IdentifyAndBlacklistSuspiciousNodes called for flow 10.1.1.7 -> 10.1.1.16
[DETECTOR] m_knownMaliciousNodes.size() = 8
[DETECTOR] Using Strategy 1: Blacklisting confirmed malicious nodes
[DETECTOR] MITIGATION: Node 0 blacklisted (confirmed wormhole endpoint)
[DETECTOR] MITIGATION: Node 3 blacklisted (confirmed wormhole endpoint)
[DETECTOR] MITIGATION: Node 6 blacklisted (confirmed wormhole endpoint)
[DETECTOR] MITIGATION: Node 9 blacklisted (confirmed wormhole endpoint)
[DETECTOR] MITIGATION: Node 10 blacklisted (confirmed wormhole endpoint)
[DETECTOR] MITIGATION: Node 12 blacklisted (confirmed wormhole endpoint)
[DETECTOR] MITIGATION: Node 15 blacklisted (confirmed wormhole endpoint)
[DETECTOR] MITIGATION: Node 20 blacklisted (confirmed wormhole endpoint)

... next detection (already blacklisted) ...

[DETECTOR] IdentifyAndBlacklistSuspiciousNodes called for flow 10.1.1.8 -> 10.1.1.15
[DETECTOR] m_knownMaliciousNodes.size() = 8
[DETECTOR] Using Strategy 1: Blacklisting confirmed malicious nodes
[DETECTOR] Node 0 already blacklisted
[DETECTOR] Node 3 already blacklisted
[DETECTOR] Node 6 already blacklisted
[DETECTOR] Node 9 already blacklisted
[DETECTOR] Node 10 already blacklisted
[DETECTOR] Node 12 already blacklisted
[DETECTOR] Node 15 already blacklisted
[DETECTOR] Node 20 already blacklisted
```

---

**The debug output will tell us exactly where the blacklisting process is failing!**

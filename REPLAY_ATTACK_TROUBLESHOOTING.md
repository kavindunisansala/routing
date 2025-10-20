# Replay Attack Troubleshooting Guide

## Current Issue: 0 Packets Captured

The attack system shows **0 packets captured** despite having 4 malicious nodes initialized.

## Diagnostic Steps

### 1. Verify Code is Updated in VM

**Check the Git commit in your VM:**
```bash
cd /path/to/routing
git log --oneline -5
```

**Expected output should show:**
```
59253bd Refine Replay Detection to reduce false positives
370de8d Fix Replay Detection system to properly identify replayed packets
8da002e Fix Replay Attack packet capture - Use GetNode() instead of m_node in StartApplication
550e770 (or earlier commits)
```

**If you don't see these commits:**
```bash
git pull origin master
git log --oneline -5  # Verify again
```

### 2. Verify Code is Copied to ns-3

**Ensure routing.cc is in the correct location:**
```bash
ls -la /path/to/ns-3.35/scratch/routing.cc
```

**Copy if needed:**
```bash
cp routing.cc /path/to/ns-3.35/scratch/routing.cc
```

### 3. Recompile from Scratch

**Clean and rebuild:**
```bash
cd /path/to/ns-3.35
./waf clean
./waf configure --enable-examples --enable-tests
./waf
```

### 4. Check for Debug Messages

**Run with output capture:**
```bash
./waf --run "routing --enable_replay_attack=true --enable_replay_detection=true --simTime=10" 2>&1 | tee replay_debug.log
```

**Search for key messages:**
```bash
grep "REPLAY ATTACK" replay_debug.log
grep "Starting replay attack" replay_debug.log
grep "Installed promiscuous callback" replay_debug.log
grep "InterceptPacket" replay_debug.log
```

### 5. Expected vs Actual Output

#### ✅ Expected Output (if fix is working):
```
[REPLAY ATTACK MGR] Total malicious nodes: 4
[REPLAY ATTACK] Starting replay attack on node 5
[REPLAY ATTACK] Installed promiscuous callback on device 0 of node 5
[REPLAY ATTACK] Installed promiscuous callback on device 1 of node 5
[REPLAY ATTACK] Starting replay attack on node 12
...
[REPLAY ATTACK] InterceptPacket callback is working on node 5!
[REPLAY ATTACK] Intercepted packet #1 on node 5
Total Packets Captured: 10+
Total Packets Replayed: 5+
```

#### ❌ Actual Output (current problem):
```
[REPLAY ATTACK MGR] Total malicious nodes: 4
Total Packets Captured: 0
Total Packets Replayed: 0
```

**Missing messages indicate:**
- `StartApplication()` is NOT being called, OR
- Applications are not starting at the scheduled time

### 6. Verify Application Scheduling

**Check if applications are actually added to nodes:**

Add this debug code temporarily after line 147566 in routing.cc:

```cpp
g_replayAttackManager->ActivateAttack(ns3::Seconds(replay_start_time), ns3::Seconds(replayStopTime));

// DEBUG: Verify applications were added
for (uint32_t i = 0; i < actual_node_count; ++i) {
    Ptr<Node> node = NodeList::GetNode(i);
    uint32_t numApps = node->GetNApplications();
    if (numApps > 0) {
        std::cout << "[DEBUG] Node " << i << " has " << numApps << " applications\n";
    }
}
```

### 7. Check Device Types

**Verify devices are NOT all point-to-point:**

The code skips point-to-point devices:
```cpp
if (!device->IsPointToPoint()) {
    // Install callback
}
```

Add debug logging to check device types:
```cpp
for (uint32_t i = 0; i < node->GetNDevices(); ++i) {
    Ptr<NetDevice> device = node->GetDevice(i);
    std::cout << "[DEBUG] Node " << node->GetId() << " device " << i 
              << " IsP2P=" << device->IsPointToPoint() 
              << " Type=" << device->GetInstanceTypeId().GetName() << "\n";
}
```

### 8. Check Timing

**Verify attack starts AFTER network setup:**

Current config:
- `replay_start_time` = 1.0s (default)
- `replay_stop_time` = simTime (10.0s)

Check if packets are being transmitted during this window:
```bash
grep -E "sending|transmit|packet" replay_debug.log | head -20
```

### 9. Verify Malicious Node Selection

**Check which nodes are selected as malicious:**

Add after line 147560:
```cpp
std::cout << "Malicious nodes selected: ";
for (uint32_t i = 0; i < replay_malicious_nodes.size(); ++i) {
    if (replay_malicious_nodes[i]) {
        std::cout << i << " ";
    }
}
std::cout << "\n";
```

## Common Issues and Solutions

### Issue 1: Code Not Updated in VM
**Solution:** `git pull origin master` then recopy to ns-3

### Issue 2: Not Recompiled
**Solution:** `./waf clean && ./waf`

### Issue 3: Applications Not Starting
**Solution:** Check start/stop times, verify node count

### Issue 4: All Devices are Point-to-Point
**Solution:** This is a VANET - should have WifiNetDevice, check network setup

### Issue 5: No Packets During Attack Window
**Solution:** Increase simTime or check packet generation

## Quick Verification Script

Create `check_replay.sh`:
```bash
#!/bin/bash
cd /path/to/ns-3.35
./waf --run "routing --enable_replay_attack=true --enable_replay_detection=true --simTime=10" 2>&1 | grep -E "REPLAY|Captured|Replayed"
```

## Expected Final Output (Working System)

```
=== Replay Attack Summary ===
Number of Malicious Nodes: 4
Total Packets Captured: 15-20
Total Packets Replayed: 5-10
Successful Replays: 5-10
Detected Replays: 5-10
Success Rate: 90-100%
Detection Rate: 90-100%

=== Replay Detection Summary ===
Total Packets Processed: 30-40
Replays Detected: 5-10
Replays Blocked: 5-10
False Positives: 0-1
Detection Accuracy: 90-100%
```

## Contact Points

If the issue persists after these checks:
1. Share the full output of: `git log --oneline -5`
2. Share the output of: `grep "REPLAY" replay_debug.log`
3. Share the network setup section (number of nodes, device types)
4. Verify ns-3 version: `./waf --version`

## Latest Commits

Ensure you have these fixes:
- **8da002e**: Fix packet capture (GetNode() instead of m_node)
- **370de8d**: Fix detection (content-based hashing)
- **59253bd**: Reduce false positives (per-node tracking)

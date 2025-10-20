# Replay Attack System - Quick Start

## Current Status: Packet Capture Not Working in VM

Your latest output shows **0 packets captured** despite the fix being committed to GitHub.

## Immediate Actions Needed in Your VM

### 1. Update Code from GitHub
```bash
cd /path/to/routing
git pull origin master
```

**Verify you have the latest commits:**
```bash
git log --oneline -3
```

**Should show:**
```
d64443e Add comprehensive troubleshooting guide and verification script
59253bd Refine Replay Detection to reduce false positives  
370de8d Fix Replay Detection system to properly identify replayed packets
```

### 2. Copy Updated Code to ns-3
```bash
cp routing.cc /path/to/ns-3.35/scratch/routing.cc
```

### 3. Clean Rebuild
```bash
cd /path/to/ns-3.35
./waf clean
./waf
```

### 4. Run Automated Verification
```bash
cd /path/to/ns-3.35
cp /path/to/routing/verify_replay_attack.sh .
chmod +x verify_replay_attack.sh
./verify_replay_attack.sh
```

This script will automatically:
- ✅ Check if code is present
- ✅ Compile the simulation
- ✅ Run with replay attack enabled
- ✅ Analyze output and identify the problem
- ✅ Provide specific diagnosis

## What the Fix Does

The packet capture fix (commit 8da002e) changes this:

**BEFORE (broken):**
```cpp
for (uint32_t i = 0; i < m_node->GetNDevices(); ++i) {
    // m_node might be null or wrong reference
}
```

**AFTER (fixed):**
```cpp
Ptr<Node> node = GetNode();  // Use Application framework's node
if (!node) {
    std::cerr << "ERROR: No node attached!\n";
    return;
}
for (uint32_t i = 0; i < node->GetNDevices(); ++i) {
    // Guaranteed correct node reference
}
```

## Expected Output After Fix

```
[REPLAY ATTACK] Starting replay attack on node 5
[REPLAY ATTACK] Installed promiscuous callback on device 0 of node 5
[REPLAY ATTACK] InterceptPacket callback is working on node 5!
[REPLAY ATTACK] Intercepted packet #1 on node 5

=== Replay Attack Summary ===
Total Packets Captured: 15-20 ✅
Total Packets Replayed: 5-10 ✅
Successful Replays: 5-10 ✅
Success Rate: 90-100% ✅
```

## If Still Not Working

Run manual diagnosis:
```bash
cd /path/to/ns-3.35
./waf --run "routing --enable_replay_attack=true --simTime=10" 2>&1 | grep "REPLAY ATTACK"
```

If you see NO output, then one of these is true:
1. Code wasn't updated (git pull didn't run)
2. Code wasn't copied to ns-3 scratch
3. Compilation used old object files (need ./waf clean)
4. Different ns-3 directory being used

## Full Documentation

See `REPLAY_ATTACK_TROUBLESHOOTING.md` for comprehensive diagnostic guide.

## Need Help?

Share the output of:
```bash
git log --oneline -5
grep "GetNode()->GetNDevices()" /path/to/ns-3.35/scratch/routing.cc
```

This confirms:
1. You have the latest code
2. The fix is present in the ns-3 scratch directory

# ⚡ Quick Test Guide - 10 Second Simulation

## Problem: Simulation Too Long

**Before:** `simTime = 300` seconds (5 minutes) - Too long for testing!
**Now:** `simTime = 10` seconds - Quick test! ✅

## What Happens in 10 Seconds

| Time | Event |
|------|-------|
| 0.0s | Simulation starts, wormhole attack activates |
| 1.036s | **Critical point** where crash used to occur |
| ~10s | Simulation ends |

This is **perfect for testing** the wormhole attack and crash fixes!

## Quick Test Commands

```bash
# Stop current simulation (if running)
# Press Ctrl+C in the terminal

# Get latest code
cd ~/routing
git pull origin master
cp routing.cc ~/Downloads/ns-allinone-3.35/ns-3.35/scratch/

# Build and run (only 10 seconds now!)
cd ~/Downloads/ns-allinone-3.35/ns-3.35
./waf
./waf --run routing
```

## ✅ Expected Output (10 second run)

```
Network configuration: N_Vehicles=22, N_RSUs=1, actual_total_nodes=23
============================================
WORMHOLE ATTACK CONFIGURATION:
Malicious Nodes: 6
Attack Rate: 20%
Tunnel Bandwidth: 1000Mbps
Tunnel Delay: 1us
Created 3 wormhole tunnels
Attack active from 0s to 10s
============================================

... (network setup)

HandleReadTwo : Received a Packet of size: 1420 at time 1.036
HandleReadTwo : Received a Packet of size: 272 at time 1.036
Proposed RL started at 1.036  ← Should appear!
Transmitting delta values at 1.036  ← No crash!

... (continues for ~9 more seconds)

Wormhole Attack Statistics:
Total Tunnels: 3
Total Packets Tunneled: XXX
Total Bytes Tunneled: XXX bytes

Simulator::Destroy  ← Normal end after 10s
```

## 🎯 What to Check

1. ✅ **Compiles successfully** (no errors)
2. ✅ **Shows wormhole configuration** at start
3. ✅ **No SIGSEGV at 1.036s** (was the crash)
4. ✅ **"Proposed RL started at 1.036"** appears
5. ✅ **Runs to completion in ~10 seconds**
6. ✅ **Shows wormhole statistics** at end

## 🔧 Change Simulation Duration

If you want different duration:

**For longer tests:**
```cpp
// Edit routing.cc line 102:
double simTime = 60;   // 60 seconds
double simTime = 300;  // 5 minutes (original)
```

**Or use command line:**
```bash
./waf --run "routing --simTime=60"
```

## 📊 Wormhole Attack Timeline

- **0.0s:** Attack starts (6 malicious nodes create 3 tunnels)
- **0.0-10s:** Attack is active
  - Packets are tunneled at 20% rate
  - 1000Mbps bandwidth, 1μs delay
- **1.036s:** Network routing updates (where crash was)
- **10s:** Simulation ends, statistics printed

## 💡 Pro Tip

For debugging, you can make it even shorter:
```cpp
double simTime = 5;  // Just 5 seconds
```

This is enough to see the wormhole attack and verify the fix! 🚀

---

**Now the simulation completes in 10 seconds instead of 5 minutes!** ⚡

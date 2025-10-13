# 🐛 Wormhole Zero Packets - Root Cause & Fix

## Problem
Wormhole tunnels created but showing **0 packets intercepted**.

## Root Cause
`SetPromiscReceiveCallback` doesn't work on WAVE/WiFi devices in NS-3. The WormholeEndpointApp tries to use:

```cpp
dev->SetPromiscReceiveCallback(
    MakeCallback(&WormholeEndpointApp::ReceivePacket, this)
);
```

But WAVE devices in your simulation **don't support promiscuous callbacks** the same way Ethernet does.

## Evidence
1. ✅ Tunnels created correctly (4 tunnels, right node pairs)
2. ✅ Apps installed and started at 0s
3. ❌ **No debug output:** `!!! ReceivePacket called` never printed
4. ❌ All statistics show zero

## Why Promiscuous Mode Fails
WAVE/WiFi devices in NS-3 3.35 use:
- Different MAC layer (802.11p)
- Different frame capture mechanism
- Promiscuous mode callback may not fire for all packet types

## Solution Options

### Option 1: Use Legacy Wormhole (EASIEST) ✅
The legacy wormhole at line 138859 creates P2P tunnels that physically route packets differently, which **does work**.

**To use:**
```cpp
// routing.cc line 137
bool use_enhanced_wormhole = false;  // Use legacy instead
```

**Pros:**
- Already works
- Packets actually get tunneled (topology change)
- No code changes needed

**Cons:**
- No statistics tracking
- No CSV export

### Option 2: Hook Into AODV Routing (COMPLEX)
Modify AODV routing protocol to redirect packets through wormhole nodes.

**Requires:**
- Accessing AODV routing table
- Injecting false routes
- Deep NS-3 protocol knowledge

**Effort:** High (20+ hours)

### Option 3: Use Monitor Mode Tracing (MEDIUM)
Instead of SetPromiscReceiveCallback, use NS-3's trace sources.

**Changes needed:**
1. Remove `SetPromiscReceiveCallback`
2. Use `TraceConnectWithoutContext` on WiFi PHY
3. Connect to "PhyRxBegin" or "MonitorSnifferRx"

**Code change in wormhole_attack.inc around line 75:**
```cpp
void WormholeEndpointApp::StartApplication(void) {
    Ptr<Node> node = GetNode();
    
    // For WAVE/WiFi devices, use PHY trace instead of promiscuous callback
    for (uint32_t i = 0; i < node->GetNDevices(); ++i) {
        Ptr<NetDevice> dev = node->GetDevice(i);
        Ptr<WifiNetDevice> wifiDev = DynamicCast<WifiNetDevice>(dev);
        
        if (wifiDev) {
            // Connect to PHY receive trace
            Ptr<WifiPhy> phy = wifiDev->GetPhy();
            phy->TraceConnectWithoutContext("MonitorSnifferRx",
                MakeCallback(&WormholeEndpointApp::ReceiveFromPhy, this));
        }
    }
}

// New callback for PHY-level packet capture
void WormholeEndpointApp::ReceiveFromPhy(Ptr<const Packet> packet, 
                                         uint16_t channelFreq,
                                         WifiTxVector txVector,
                                         MpduInfo aMpdu,
                                         SignalNoiseDbm signalNoise) {
    // Extract protocol and call existing logic
    // ...
}
```

**Effort:** Medium (4-6 hours)

## Recommendation

**For Quick Results:** Use Option 1 (legacy wormhole)
- Set `use_enhanced_wormhole = false`
- Rebuild and run
- Packets will be tunneled (no stats, but it works)

**For Statistics:** Use Option 3 (PHY tracing)
- Requires modifying wormhole_attack.inc
- Add PHY trace connection
- Test with WAVE devices

## Testing Commands

```bash
# Test legacy wormhole
./waf --run "routing --use_enhanced_wormhole=false --simTime=30"

# Should see different routing behavior (packets going through wormhole nodes)
```

## Why This Is Hard
VANET simulations use WAVE (IEEE 802.11p) which is **not a traditional Ethernet**. The packet capture mechanisms are different:

| Device Type | Promiscuous Callback | Works? |
|-------------|---------------------|--------|
| CSMA (Ethernet) | ✅ Yes | ✅ Works |
| WiFi (Infrastructure) | ⚠️ Partial | ⚠️ Sometimes |
| WAVE (802.11p) | ❌ Limited | ❌ Often fails |
| LTE | ❌ No | ❌ Different API |

Your simulation uses **WAVE**, which is why the callback isn't firing.

---

**Created:** After analyzing why wormhole shows zero packets despite correct tunnel creation

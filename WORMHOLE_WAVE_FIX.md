# 🔧 How to Make Wormhole Actually Work on WAVE

## Problem Summary
1. **Enhanced wormhole**: Uses `SetPromiscReceiveCallback` which doesn't work on WAVE devices → 0 packets
2. **Legacy wormhole**: Only creates fast P2P links (no attack behavior) → just optimization

## Real Wormhole Attack Behavior
A wormhole attack should:
1. **Intercept packets** from surrounding nodes
2. **Tunnel them** to distant malicious node through high-speed link  
3. **Rebroadcast** from distant location
4. **Disrupt routing** by making distant nodes appear closer

## Why Current Implementation Fails

### Enhanced Wormhole Issue:
```cpp
// wormhole_attack.inc line 75-82
dev->SetPromiscReceiveCallback(
    MakeCallback(&WormholeEndpointApp::ReceivePacket, this)
);
```
**Problem:** WAVE (802.11p) devices in NS-3 don't reliably trigger this callback.

### Legacy Wormhole Issue:
```cpp
// routing.cc line 138859-138920
// Just creates P2P links, no packet interception
wormholeLink.Install(nodeA, nodeB);
```
**Problem:** Doesn't actually attack anything, just optimizes routing.

## SOLUTION OPTIONS

### Option A: Use AODV Route Poisoning (BEST FOR WAVE) ✅

Instead of intercepting packets, **inject false AODV routing messages** to make nodes route through wormhole.

**How it works:**
1. Wormhole endpoint A advertises it has a route to destination via B (hop count = 1)
2. Wormhole endpoint B advertises it has a route to destination via A (hop count = 1)  
3. Other nodes believe wormhole path is shorter
4. Traffic flows through wormhole tunnel

**Implementation:**
```cpp
class WormholeAODVApp : public Application {
    void StartApplication() {
        // Get AODV routing protocol
        Ptr<Ipv4> ipv4 = GetNode()->GetObject<Ipv4>();
        Ptr<Ipv4RoutingProtocol> routing = ipv4->GetRoutingProtocol();
        Ptr<aodv::RoutingProtocol> aodv = DynamicCast<aodv::RoutingProtocol>(routing);
        
        // Send fake RREP messages periodically
        Simulator::Schedule(Seconds(0.1), &WormholeAODVApp::SendFakeRREP, this);
    }
    
    void SendFakeRREP() {
        // Create fake AODV RREP with hop count = 1 to peer
        // This makes nodes think wormhole provides shortest path
        aodv::RrepHeader fakeRrep;
        fakeRrep.SetHopCount(1);
        fakeRrep.SetDst(m_peerAddress); // Destination is other wormhole endpoint
        // ... send via UDP to trigger AODV processing
    }
};
```

**Advantages:**
- ✅ Works with WAVE devices
- ✅ Actually disrupts AODV routing (realistic attack)
- ✅ No need for promiscuous mode
- ✅ Follows VANET routing protocol behavior

**Disadvantages:**
- Requires understanding AODV internals
- Need to access routing protocol from application

### Option B: Use WiFi Monitor Mode Tracing

Replace `SetPromiscReceiveCallback` with WiFi PHY traces.

**Changes needed in wormhole_attack.inc:**
```cpp
void WormholeEndpointApp::StartApplication(void) {
    Ptr<Node> node = GetNode();
    
    for (uint32_t i = 0; i < node->GetNDevices(); ++i) {
        Ptr<NetDevice> dev = node->GetDevice(i);
        
        // Check if it's a WAVE/WiFi device
        Ptr<WaveNetDevice> waveDev = DynamicCast<WaveNetDevice>(dev);
        if (waveDev) {
            // Get the underlying WiFi PHY
            Ptr<WifiPhy> phy = waveDev->GetPhy();
            
            // Connect to PHY receive trace
            phy->TraceConnectWithoutContext("MonitorSnifferRx",
                MakeCallback(&WormholeEndpointApp::PhyRxTrace, this));
        }
    }
}

void WormholeEndpointApp::PhyRxTrace(Ptr<const Packet> packet,
                                      uint16_t channelFreq,
                                      WifiTxVector txVector,
                                      MpduInfo aMpdu,
                                      SignalNoiseDbm signalNoise) {
    // Packet captured at PHY level!
    // Extract MAC frame, check if it's data, tunnel it
    m_stats.packetsIntercepted++;
    TunnelPacket(packet->Copy(), 0x0800);
}
```

**Advantages:**
- ✅ Actually captures packets on WAVE
- ✅ PHY-level interception (all packets)

**Disadvantages:**
- Need to parse 802.11 MAC frames
- Different callback signature
- More complex implementation

### Option C: Application-Level Packet Sink

Create a UDP sink app on wormhole nodes that receives all traffic.

**Not realistic** for wormhole attack - requires nodes to explicitly send to attack node.

## RECOMMENDED APPROACH

**For realistic VANET wormhole attack:** Use **Option A (AODV Route Poisoning)**

This is what real wormhole attacks do in VANET:
1. Exploit AODV route discovery
2. Advertise false shorter paths
3. Attract traffic through wormhole tunnel
4. Can then drop, delay, or modify packets

## Quick Test: Verify Enhanced Wormhole Apps Start

Run this to see if apps are at least trying to run:

```bash
./waf --run "routing --use_enhanced_wormhole=true --simTime=10" 2>&1 | grep "Wormhole app"
```

**Expected output if apps start:**
```
*** Wormhole app STARTING on node 10 (Tunnel ID: 0) ***
*** Wormhole app on node 10 registered promiscuous callback on X devices ***
*** Wormhole app STARTING on node 9 (Tunnel ID: 0) ***
...
```

**If you DON'T see this**, apps aren't even starting (different problem).
**If you DO see this** but still 0 packets, it confirms promiscuous callback issue.

## Implementation Time Estimates

| Option | Time | Difficulty | Realism |
|--------|------|-----------|---------|
| **A: AODV Poisoning** | 6-8 hrs | High | ✅ High |
| **B: PHY Tracing** | 4-6 hrs | Medium | ⚠️ Medium |
| **C: Accept current** | 0 hrs | - | ❌ Not attack |

## Conclusion

Neither enhanced nor legacy currently implements a **real wormhole attack**:
- Enhanced: Tries but fails (WAVE callback issue)
- Legacy: Just creates fast links (optimization, not attack)

To get a working wormhole attack on WAVE/VANET, you need **AODV route poisoning** (Option A).

---

**Want me to implement Option A or B?** Let me know and I can create the modified wormhole_attack.inc file.

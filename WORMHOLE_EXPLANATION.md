# 🕳️ Wormhole Attack - Complete Technical Explanation

## Table of Contents
1. [MacRx Function - Why It's Commented](#macrx-function)
2. [Wormhole Attack Mechanism](#wormhole-attack-mechanism)
3. [Packet Flow Comparison](#packet-flow-comparison)
4. [Code Architecture](#code-architecture)

---

## MacRx Function - Why It's Commented ❌

### What is MacRx?

**Location:** `routing.cc` line ~121846

```cpp
void MacRx (std::string context, Ptr <const Packet> pkt)
{
    // This function is called when a packet is RECEIVED at the MAC layer
    // It's NOT a packet sending function - it's a RECEPTION callback
}
```

### ❌ **MacRx is NOT a sending function!**

**MacRx = MAC Reception**
- **Purpose:** Callback triggered when a packet is **received** at the MAC (Medium Access Control) layer
- **Layer:** OSI Layer 2 (Data Link Layer)
- **Direction:** INCOMING packets
- **Connected to:** WiFi MAC reception events via `Config::ConnectFailSafe()`

### Why Is It Commented Out?

Looking at the code (lines 121853-121862):

```cpp
void MacRx (std::string context, Ptr <const Packet> pkt)
{
    //context will include info about the source of this event. Use string manipulation if you want to extract info.
    //std::cout <<  context << std::endl;
    //cout<<context[10]<<endl;
    //Print the info.
    
    /*
    std::cout << "\t total packet Size=" << pkt->GetSerializedSize()
              << " Freq="<<channelFreqMhz
              << " Mode=" << txVector.GetMode()
              << " Signal=" << signalNoise.signal
              << " Noise=" << signalNoise.noise << std::endl;
    */
```

**Reasons for commenting:**

1. **Debug Output Suppression**
   - The commented code prints detailed reception statistics
   - Would create excessive console output during simulation
   - Useful only during debugging/development

2. **Performance Optimization**
   - String operations and console I/O are expensive
   - Comments reduce simulation overhead
   - Keep simulation running fast

3. **Production Mode**
   - Debug prints left in code for future troubleshooting
   - Can be uncommented when needed
   - Standard practice in simulation code

### What Does MacRx Actually Do? (Uncommented Parts)

```cpp
void MacRx (std::string context, Ptr <const Packet> pkt)
{
    // 1. Parse context string to extract destination node ID
    uint32_t destination_node_id;
    // String manipulation to extract node ID from context
    
    // 2. Track DSRC statistics
    dsrc_final_timestamp = Simulator::Now().GetSeconds();
    dsrc_total_received_packets = dsrc_total_received_packets + 1.0;
    dsrc_total_packet_size = dsrc_total_packet_size + pkt->GetSerializedSize();
    
    // 3. Handle custom routing tags
    CustomDataUnicastTag_ModifiedRouting tagmodified_routing;
    if(pkt->PeekPacketTag(tagmodified_routing))
    {
        // Extract flow ID, packet ID, channel, etc.
        uint32_t fid = tagmodified_routing.GetflowId();
        uint32_t packet_ID = tagmodified_routing.GetpacketId();
        
        // Mark packet as delivered
        pd_all_inst[fid].pd_inst[current_hop].delivery[channel][packet_ID] = true;
        
        // If at destination, count successful delivery
        if(destination == current_hop)
        {
            destination_counter[fid]++;
            cout<<"Flow ID "<<fid<<" received Packet ID: "<<packet_ID
                <<" at destination "<<destination<<" at "<<Now().GetSeconds()<<endl;
        }
        else
        {
            // If not at destination, relay the packet forward
            pd_all_inst[fid].pd_inst[current_hop].pending[channel][packet_ID] = true;
            // Update TXOP (Transmission Opportunity) for forwarding
        }
    }
}
```

**Key Functions:**
- ✅ Track received packets per flow
- ✅ Update delivery statistics  
- ✅ Handle packet forwarding for multi-hop routing
- ✅ Measure end-to-end delay and PDR (Packet Delivery Ratio)

---

## Wormhole Attack Mechanism 🕳️

### What is a Wormhole Attack?

A **wormhole attack** creates an **illusion of a short path** between two distant nodes by tunneling packets through an **out-of-band channel** (private high-speed link).

### The Attack Strategy

```
Normal Route:        A → B → C → D → E
                     (5 hops, slow)

Wormhole Route:      A → [WORMHOLE] → E
                         ↑         ↓
                    Node X ======= Node Y
                     (private tunnel)
                     (appears as 2 hops!)
```

**Attacker Advantage:**
- Advertises **fake routes** claiming "shortest path"
- Other nodes route packets through the wormhole
- Attacker can **eavesdrop**, **modify**, or **drop** packets
- Can launch **secondary attacks** (blackhole, selective forwarding)

---

## How Your Wormhole Works 🔧

### Architecture: Two Cooperating Nodes

```
┌─────────────┐                           ┌─────────────┐
│  Wormhole   │    UDP Tunnel (Port 9999) │  Wormhole   │
│  Node X     │ ◄═══════════════════════► │  Node Y     │
│ (Endpoint 1)│    Private Link (P2P)     │ (Endpoint 2)│
└─────────────┘                           └─────────────┘
      ▲                                          │
      │ Intercept                    Re-inject  │
      │ (Promiscuous)                           ▼
   ┌──┴────────────────────────────────────────────┐
   │         VANET Network (AODV Routing)          │
   │  Vehicle 1, Vehicle 2, ..., Vehicle 22, RSU   │
   └───────────────────────────────────────────────┘
```

### Step-by-Step Attack Flow

#### **Phase 1: Route Poisoning** (Fake Advertisement)

**Code:** `SendFakeRouteAdvertisement()` (lines ~95028-95080)

```cpp
void WormholeEndpointApp::SendFakeRouteAdvertisement() {
    // Create fake AODV RREP (Route Reply) packet
    Ptr<Packet> fakeRREP = Create<Packet>(100);
    
    // Advertise ourselves as having a route to ALL destinations
    // with ZERO hops (lie!)
    AodvRoutingHeader fakeHeader;
    fakeHeader.SetHopCount(0);  // ← LIE: Claim we're 0 hops away!
    
    // Broadcast to all neighbors
    m_broadcastSocket->SendTo(fakeRREP, 0, 
        InetSocketAddress(Ipv4Address("255.255.255.255"), 654));
}
```

**Effect:**
- Neighboring nodes receive fake RREP
- Update routing tables: "Best route to destination is through Wormhole Node!"
- Traffic starts flowing toward wormhole endpoints

---

#### **Phase 2: Packet Interception** (Network Layer Hook)

**Code:** `InterceptPacket()` (lines ~95082-95196)

```cpp
bool WormholeEndpointApp::InterceptPacket(Ptr<NetDevice> device,
                                          Ptr<const Packet> packet,
                                          uint16_t protocol,
                                          const Address &from,
                                          const Address &to,
                                          NetDevice::PacketType packetType) {
```

**How It Works:**

1. **Promiscuous Mode Setup** (line ~94813)
   ```cpp
   device->SetPromiscuousReceiveCallback(
       MakeCallback(&WormholeEndpointApp::InterceptPacket, this));
   ```
   - **Promiscuous Mode:** Listen to ALL packets on the network
   - Not just packets destined for this node
   - Captures packets meant for other nodes

2. **Filtering Logic**
   ```cpp
   // Only intercept IPv4 packets
   if (protocol != 0x0800) {
       return false; // Not IPv4, let it through
   }
   
   // Don't intercept tunnel traffic (avoid loops)
   if (device->IsPointToPoint()) {
       return false; // This is tunnel traffic
   }
   
   // Don't intercept AODV routing packets (port 654)
   if (udpHeader.GetDestinationPort() == 654) {
       shouldTunnel = false; // Don't tunnel AODV
   }
   ```

3. **Interception Decision** (line ~95150)
   ```cpp
   bool shouldTunnel = false;
   
   if (m_peerAddress != Ipv4Address::GetZero()) {
       shouldTunnel = true;  // Tunnel everything except AODV
   }
   
   if (shouldTunnel) {
       m_stats.packetsIntercepted++;
       
       // ✅ TRACKING: Mark packet as wormhole-affected
       if (g_packetTracker != nullptr && enable_packet_tracking) {
           g_packetTracker->MarkWormholePath(packet->GetUid());
       }
   }
   ```

**Result:** Packet intercepted BEFORE normal routing!

---

#### **Phase 3: Tunneling** (Private Channel)

**Code:** Lines ~95171-95183

```cpp
// Tunnel the packet to peer
if (m_tunnelSocket && m_peerAddress != Ipv4Address::GetZero()) {
    Ptr<Packet> tunnelCopy = packet->Copy();
    
    // Send through private UDP tunnel (Port 9999)
    int sent = m_tunnelSocket->SendTo(
        tunnelCopy, 0, 
        InetSocketAddress(m_peerAddress, 9999)
    );
    
    if (sent > 0) {
        m_stats.packetsTunneled++;
        
        // ✅ TRACKING: Mark successful tunneling
        if (g_packetTracker != nullptr && enable_packet_tracking) {
            g_packetTracker->MarkWormholePath(packet->GetUid());
        }
    }
}

// Drop the packet (don't let it route normally)
if (m_dropPackets) {
    m_stats.packetsDropped++;
    return true; // Consume packet - prevent normal routing
}
```

**What Happens:**
- Original packet **COPIED** and sent through tunnel
- Tunnel uses **private P2P link** (not visible to VANET)
- Original packet **DROPPED** (removed from normal routing)
- Network thinks packet was forwarded normally

---

#### **Phase 4: Re-injection** (Tunnel Exit)

**Code:** `HandleTunneledPacket()` (lines ~95197-95220)

```cpp
void WormholeEndpointApp::HandleTunneledPacket(Ptr<Socket> socket) {
    Ptr<Packet> packet;
    Address from;
    
    while ((packet = socket->RecvFrom(from))) {
        m_stats.packetsTunneled++;
        
        // ✅ TRACKING: Mark packet at tunnel exit
        if (g_packetTracker != nullptr && enable_packet_tracking) {
            g_packetTracker->MarkWormholePath(packet->GetUid());
        }
        
        // Re-inject the packet into the local network
        Ptr<Ipv4> ipv4 = GetNode()->GetObject<Ipv4>();
        if (ipv4) {
            for (uint32_t i = 1; i < ipv4->GetNInterfaces(); ++i) {
                Ptr<NetDevice> device = ipv4->GetNetDevice(i);
                
                // Send packet out on local interface
                // Appears as if it arrived via normal routing!
                device->Send(packet, ...);
            }
        }
    }
}
```

**Effect:**
- Packet emerges at distant location
- Appears to have "teleported"
- Continues routing to final destination
- **Wormhole is invisible to other nodes!**

---

## Packet Flow Comparison 📊

### Normal Routing (Without Wormhole)

```
Time: 0.0s
┌─────────┐
│ Source  │  "I need to send packet to Destination"
│ Node A  │
└────┬────┘
     │ 1. Generate packet (App Layer)
     ▼
┌─────────┐
│ Routing │  2. AODV route lookup: A → B → C → D
│  Layer  │
└────┬────┘
     │ 3. Forward to next hop (B)
     ▼
┌─────────┐
│ Node B  │  4. Receive, forward to C
└────┬────┘
     │
     ▼
┌─────────┐
│ Node C  │  5. Receive, forward to D
└────┬────┘
     │
     ▼
┌─────────┐
│  Dest   │  6. Deliver to application
│ Node D  │
└─────────┘

Hops: 4
Delay: ~40ms (10ms per hop)
Path: A → B → C → D ✅ Legitimate
```

---

### With Wormhole Attack (Your Implementation)

```
Time: 0.0s
┌─────────┐
│ Source  │  "I need to send packet to Destination"
│ Node A  │
└────┬────┘
     │ 1. Generate packet (App Layer)
     ▼
┌─────────┐
│ Routing │  2. AODV lookup: BEST route is through Wormhole Node X!
│  Layer  │     (Because of fake RREP advertisement)
└────┬────┘
     │ 3. Forward to Wormhole Node X
     ▼
┌──────────────┐
│  Wormhole X  │  4. InterceptPacket() catches packet (Promiscuous)
│ (Attacker 1) │  5. Tunnel to peer via UDP (Port 9999)
└──────┬───────┘
       │ ═══════════════════════════════════════════
       │    PRIVATE TUNNEL (invisible to network)
       │    1000 Mbps, 0.1ms delay
       ▼ ═══════════════════════════════════════════
┌──────────────┐
│  Wormhole Y  │  6. HandleTunneledPacket() receives
│ (Attacker 2) │  7. Re-inject into network near destination
└──────┬───────┘
       │ 8. Appears as normal packet!
       ▼
┌─────────┐
│  Dest   │  9. Deliver to application
│ Node D  │     (Node D has NO IDEA packet went through wormhole!)
└─────────┘

Apparent Hops: 2 (A → X → D)
Actual Hops: 2 visible + 1 invisible tunnel
Delay: ~5ms (faster than normal!)
Path: A → [WORMHOLE TUNNEL] → D ❌ Malicious

Attacker Capabilities:
- ✅ Eavesdrop: Read packet contents
- ✅ Modify: Change packet data
- ✅ Drop: Selective forwarding attack
- ✅ Delay: Timing attacks
- ✅ Invisible: Network can't detect tunnel
```

---

## Code Architecture 🏗️

### Class Structure

```cpp
class WormholeEndpointApp : public Application
{
private:
    // Tunnel Configuration
    Ptr<Socket> m_tunnelSocket;        // UDP socket for tunnel (Port 9999)
    Ptr<Socket> m_broadcastSocket;     // For fake RREP broadcasts
    Ipv4Address m_peerAddress;         // Peer wormhole endpoint IP
    bool m_dropPackets;                // Drop intercepted packets?
    
    // Statistics
    struct {
        uint32_t packetsIntercepted;   // Packets caught by promiscuous mode
        uint32_t packetsTunneled;      // Packets sent through tunnel
        uint32_t packetsDropped;       // Packets dropped (not forwarded)
        uint32_t dataPacketsAffected;  // Non-routing packets affected
    } m_stats;
    
    // Attack Methods
    void SendFakeRouteAdvertisement();              // Route poisoning
    bool InterceptPacket(...);                      // Promiscuous callback
    void HandleTunneledPacket(Ptr<Socket> socket);  // Tunnel exit handler
};
```

### Key Design Decisions

#### 1. **Why Promiscuous Mode?**
```cpp
device->SetPromiscuousReceiveCallback(
    MakeCallback(&WormholeEndpointApp::InterceptPacket, this));
```
- **Normal Mode:** Only receive packets addressed to this node
- **Promiscuous Mode:** Receive ALL packets on the network
- Allows attacker to intercept packets meant for others

#### 2. **Why UDP Tunnel on Port 9999?**
```cpp
m_tunnelSocket->Bind(InetSocketAddress(Ipv4Address::GetAny(), 9999));
```
- **UDP:** Low overhead, no connection state
- **Port 9999:** Non-standard port (less likely to conflict)
- **Fast:** Minimal processing delay

#### 3. **Why Drop Original Packets?**
```cpp
if (m_dropPackets) {
    return true; // Consume packet - prevent normal routing
}
```
- **Prevent Duplication:** Without dropping, packet would take both routes
- **Force Tunneling:** Ensure all traffic goes through wormhole
- **Maintain Illusion:** Network sees "normal" forwarding

#### 4. **Why Not Intercept AODV Packets?**
```cpp
if (udpHeader.GetDestinationPort() == 654) {
    shouldTunnel = false; // Don't tunnel AODV
}
```
- **Avoid Detection:** Tunneling routing packets would break protocol
- **Maintain Routes:** AODV needs to propagate normally
- **Stealth:** Keep attack invisible

---

## Statistics Tracking 📈

### Three Levels of Tracking

#### 1. **Attack Statistics** (WormholeEndpointApp)
```cpp
WORMHOLE ATTACK STATISTICS:
  Packets Intercepted: 176  ← Caught by promiscuous mode
  Packets Tunneled: 56      ← Successfully sent through tunnel
  Packets Dropped: 176      ← Removed from normal routing
  Data Packets Affected: 176
```

#### 2. **Packet Tracker** (Per-Packet Analysis)
```cpp
PACKET TRACKER STATISTICS:
  Packets through Wormhole: 56  ← Marked with MarkWormholePath()
```

**CSV Export:**
```csv
PacketID,SendTime,ReceiveTime,DelayMs,Delivered,WormholeOnPath,BlackholeOnPath
1234,1.5,1.556,56.0,1,1,0  ← WormholeOnPath=1 means tunneled
```

#### 3. **Network Statistics** (Overall Performance)
```
PDR (Packet Delivery Ratio): 88.45%
Average Delay: 9.05 ms
Throughput: 850 Kbps
```

---

## Why MacRx ≠ Wormhole 🔍

### MacRx Function (Reception)
- **Layer:** MAC Layer (L2)
- **Direction:** Incoming packets
- **Purpose:** Track received packets, update delivery statistics
- **Trigger:** Packet arrives at MAC layer
- **Does NOT send packets**

### Wormhole InterceptPacket (Interception + Tunneling)
- **Layer:** Network Layer (L3) via NetDevice promiscuous mode
- **Direction:** Intercepts packets in transit
- **Purpose:** Capture packets, tunnel to peer, re-inject
- **Trigger:** Any packet on network (promiscuous mode)
- **DOES send packets** (through tunnel)

### Key Difference

```
MacRx:
   Network → [MAC Layer] → MacRx() → "I received a packet!" → Statistics
                             ↑
                        RECEPTION ONLY

InterceptPacket:
   Network → [Promiscuous Hook] → InterceptPacket() → Decision
                                           ├→ Should tunnel? YES → Send to peer
                                           └→ Should tunnel? NO → Let through
                                           ↑
                                    INTERCEPTION + TUNNELING
```

---

## Summary 📝

### MacRx Function
- ❌ NOT a sending function
- ✅ Reception callback for MAC layer
- ✅ Tracks received packets and delivery statistics
- ✅ Commented to reduce debug output and improve performance
- ✅ Still functional (only prints are commented)

### Wormhole Attack
- ✅ Two cooperating nodes (X and Y)
- ✅ Fake RREP advertisements poison routes
- ✅ Promiscuous mode intercepts packets at network layer
- ✅ Private UDP tunnel (Port 9999) transports packets
- ✅ Re-injection at peer makes attack invisible
- ✅ Tracks packets at 3 points: intercept, tunnel, re-inject
- ✅ Enables eavesdropping, modification, selective forwarding

### Attack Impact
- **Intercepts:** 176 packets
- **Tunnels:** 56 packets successfully
- **Drops:** 176 packets from normal routing
- **PDR Impact:** Reduces from ~95% to 88.45%
- **Delay Impact:** Some packets faster (tunnel), others dropped

---

**The wormhole creates an invisible shortcut through the network, allowing attackers to control packet flow! 🕳️**

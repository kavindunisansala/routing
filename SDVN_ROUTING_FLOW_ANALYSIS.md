# 📘 SDVN Routing Flow Analysis: Normal vs Wormhole Attack

## 🎯 Overview

This document explains **exactly how routing.cc works** in normal operation and how it changes under SDVN wormhole attack.

---

## 🏗️ SDVN Architecture Components

```
┌─────────────────────────────────────────────────────────┐
│                  CONTROLLER LAYER                        │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐              │
│  │  C0 (2)  │  │  C1 (3)  │  │ C2-C5... │              │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘              │
│       │ LTE         │ LTE         │ LTE                 │
│       └─────────────┴─────────────┘                     │
└───────────────────┬─────────────────────────────────────┘
                    │ Control Channel (7777)
┌───────────────────┴─────────────────────────────────────┐
│                  VEHICLE NODE LAYER                      │
│  ┌────┐  DSRC  ┌────┐  DSRC  ┌────┐  DSRC  ┌────┐     │
│  │ N0 ├────────┤ N1 ├────────┤ N2 ├────────┤ N3 │  ... │
│  │(4) │        │(5) │        │(6) │        │(7) │     │
│  └────┘        └────┘        └────┘        └────┘     │
│         Data Forwarding (802.11p/WAVE)                  │
└─────────────────────────────────────────────────────────┘
```

**Key IDs:**
- **Controllers**: Node IDs 2, 3 (0-1 are infrastructure)
- **Vehicles**: Node IDs 4-31 (28 vehicles = total_size)
- **LTE Port**: 7777 (controller-node communication)
- **DSRC**: 802.11p (vehicle-to-vehicle data forwarding)

---

## 📡 Phase 1: Metadata Uplink (Node → Controller)

### **Function**: `send_LTE_metadata_uplink_alone()`
**Location**: routing.cc line 118962
**Called**: Periodically by each vehicle node

### **Normal Operation**

```cpp
void send_LTE_metadata_uplink_alone(...) {
    // 1. Get node's neighbor list
    uint32_t nid = node_source->GetId();  // e.g., Node 5
    uint32_t size = getNeighborsize(neighbordata_inst + nid);
    
    // 2. Collect neighbor IDs
    uint32_t neighborid[size];
    for (uint32_t i = 0; i < size; i++) {
        neighborid[i] = (neighbordata_inst + nid)->neighborid[i];
    }
    
    // 3. Create metadata packet with neighbor info
    CustomMetaDataUnicastTag tag;
    tag.SetNodeId(nid);
    tag.Setneighborid(neighborid);  // [4, 6, 7] for example
    tag.SetTimestamp(Simulator::Now());
    
    // 4. Send to controller via LTE (port 7777)
    packet->AddPacketTag(tag);
    SendPacket(packet, controller_ip, 7777);
}
```

### **Example - Node 5 Normal Metadata**

```
┌────────────────────────────────────────┐
│  METADATA UPLINK (Node 5 → Controller) │
├────────────────────────────────────────┤
│  Node ID: 5                            │
│  Neighbors: [4, 6, 7]                  │  ← REAL neighbors via DSRC
│  Timestamp: 0.43s                      │
│  Packet Size: 84 bytes                 │
└────────────────────────────────────────┘
         ↓ LTE (port 7777)
    Controller (Node 2)
```

---

## 🧠 Phase 2: Controller Processes Metadata

### **Function**: Controller receives at port 7777
**Location**: Packet receiver callback

### **Normal Processing**

```cpp
// Controller receives metadata from all nodes
void ReceiveMetadataAtController(Ptr<Packet> packet) {
    CustomMetaDataUnicastTag tag;
    packet->PeekPacketTag(tag);
    
    uint32_t nodeId = tag.GetNodeId();  // e.g., 5
    uint32_t* neighbors = tag.Getneighborid();  // [4, 6, 7]
    uint32_t neighborCount = tag.GetNeighborCount();
    
    // Store in controller's data structure
    for (uint32_t i = 0; i < neighborCount; i++) {
        // Record: Node 5 has neighbor 4, 6, 7
        controller_neighbor_map[nodeId][neighbors[i]] = true;
    }
    
    // Build link lifetime matrix
    BuildLinkLifetimeMatrix();
}
```

### **Link Lifetime Matrix Construction**

```cpp
// After receiving all metadata, controller builds linklifetimeMatrix_dsrc
void BuildLinkLifetimeMatrix() {
    for (uint32_t i = 0; i < total_size; i++) {
        for (uint32_t j = 0; j < total_size; j++) {
            if (controller_neighbor_map[i][j]) {
                // Nodes i and j are neighbors
                // Calculate predicted link lifetime based on:
                // - Current positions
                // - Velocities
                // - Accelerations
                // - Transmission range
                
                double lifetime = PredictLinkLifetime(i, j);
                linklifetimeMatrix_dsrc[i][j] = lifetime;
            } else {
                // No link exists
                linklifetimeMatrix_dsrc[i][j] = 0.0;
            }
        }
    }
}
```

### **Example - linklifetimeMatrix_dsrc After Normal Metadata**

```
Controller's View of Network Links:

        Node4  Node5  Node6  Node7  Node8
Node4   [0.0   0.52   0.0    0.0    0.0 ]
Node5   [0.52  0.0    0.48   0.45   0.0 ]  ← Node 5's real neighbors
Node6   [0.0   0.48   0.0    0.51   0.0 ]
Node7   [0.0   0.45   0.51   0.0    0.0 ]
Node8   [0.0   0.0    0.0    0.0    0.0 ]

Values = Link lifetime in seconds
0.0 = No link exists
>0.4 = Link suitable for routing (above link_lifetime_threshold)
```

---

## 🧮 Phase 3: Controller Computes Delta Values

### **Function**: `run_ECMP_at_controller()`
**Location**: routing.cc line ~122970
**Called**: After building linklifetimeMatrix_dsrc

### **Normal Routing Computation**

```cpp
void run_ECMP_at_controller(uint32_t flow_id) {
    uint32_t source = flow_struct[flow_id].source;
    uint32_t destination = flow_struct[flow_id].destination;
    
    // For each node in the path from source to destination
    for (uint32_t current_node = source; current_node != destination; ) {
        
        // Find valid next hops
        uint32_t valid_next_hops = 0;
        uint32_t next_hop_candidates[total_size];
        
        for (uint32_t next_node = 0; next_node < total_size; next_node++) {
            
            // *** KEY CHECK: Link must exist! ***
            if (linklifetimeMatrix_dsrc[current_node][next_node] > link_lifetime_threshold) {
                
                // Check if next_node is closer to destination
                if (distance_to_dest[next_node] < distance_to_dest[current_node]) {
                    next_hop_candidates[valid_next_hops] = next_node;
                    valid_next_hops++;
                }
            }
        }
        
        // Compute delta values (forwarding probabilities)
        if (valid_next_hops > 0) {
            double probability = 1.0 / valid_next_hops;
            
            for (uint32_t i = 0; i < valid_next_hops; i++) {
                uint32_t next_node = next_hop_candidates[i];
                delta_at_controller_inst[flow_id]
                    .delta_fi_inst[current_node]
                    .delta_values[next_node] = probability;
            }
        }
    }
}
```

### **Example - Delta Values for Flow 3 (Node 5 → Node 15)**

```
Controller computes routing for Flow 3:
Source: Node 5
Destination: Node 15

At Node 5, valid next hops:
  - Node 4: linklifetimeMatrix_dsrc[5][4] = 0.52s ✓ (>0.4)
  - Node 6: linklifetimeMatrix_dsrc[5][6] = 0.48s ✓ (>0.4)
  - Node 7: linklifetimeMatrix_dsrc[5][7] = 0.45s ✓ (>0.4)
  
All 3 are closer to destination → Split equally

Delta values computed:
  delta_at_controller_inst[3].delta_fi_inst[5].delta_values[4] = 0.33
  delta_at_controller_inst[3].delta_fi_inst[5].delta_values[6] = 0.33
  delta_at_controller_inst[3].delta_fi_inst[5].delta_values[7] = 0.33
  delta_at_controller_inst[3].delta_fi_inst[5].delta_values[others] = 0.0
```

---

## 📤 Phase 4: Delta Values Downlink (Controller → Node)

### **Function**: `send_LTE_deltavalues_downlink_alone()`
**Location**: routing.cc line 119351
**Called**: After controller computes delta values

### **Normal Downlink**

```cpp
void send_LTE_deltavalues_downlink_alone(...) {
    uint32_t nid = destination_node->GetId();  // e.g., Node 5
    
    // 1. Prepare delta values for ALL flows
    double delta_Set[2*flows][total_size];
    uint32_t sources[2*flows];
    uint32_t destinations[2*flows];
    uint32_t flow_ids[2*flows];
    
    for (uint32_t i = 0; i < 2*flows; i++) {
        for (uint32_t j = 0; j < total_size; j++) {
            // Copy delta values from controller's computation
            delta_Set[i][j] = delta_at_controller_inst[i]
                                .delta_fi_inst[nid-2]
                                .delta_values[j];
        }
        sources[i] = flow_struct[i].source;
        destinations[i] = flow_struct[i].destination;
        flow_ids[i] = i;
    }
    
    // 2. Create downlink packet
    CustomDeltavaluesDownlinkUnicastTag tag;
    tag.Setdeltas(delta_Set);
    tag.Setsources(sources);
    tag.Setdestinations(destinations);
    tag.Setflow_ids(flow_ids);
    tag.Setnodeid(nid-2);
    
    // 3. Send to vehicle node via LTE (port 7777)
    packet->AddPacketTag(tag);
    SendPacket(packet, vehicle_ip, 7777);
}
```

### **Example - Delta Values Sent to Node 5**

```
┌─────────────────────────────────────────┐
│ DELTA VALUES DOWNLINK (Controller → N5) │
├─────────────────────────────────────────┤
│ For Flow 3 (src=5, dst=15):             │
│   delta[4] = 0.33  (33% to Node 4)      │
│   delta[6] = 0.33  (33% to Node 6)      │
│   delta[7] = 0.33  (33% to Node 7)      │
│   delta[others] = 0.0                   │
│                                         │
│ For Flow 5 (src=7, dst=12):             │
│   delta[5] = 0.5   (50% to Node 5)      │
│   delta[8] = 0.5   (50% to Node 8)      │
│   ...                                   │
└─────────────────────────────────────────┘
         ↓ LTE (port 7777)
      Node 5 receives
```

---

## 📦 Phase 5: Node Forwards Packets Using Delta Values

### **Node Receives Data Packet**

```cpp
// Node 5 receives packet destined for Node 15
void NodeForwardPacket(Ptr<Packet> packet) {
    Ipv4Header ipHeader;
    packet->PeekHeader(ipHeader);
    Ipv4Address destAddr = ipHeader.GetDestination();
    
    // Determine which flow this packet belongs to
    uint32_t flowId = DetermineFlowId(packet);
    
    // Get delta values for this flow (received from controller)
    double* deltas = delta_values_at_node[flowId];
    
    // Select next hop based on delta values
    uint32_t nextHop = SelectNextHopByDelta(deltas);
    
    // Forward packet to selected next hop via DSRC
    ForwardToNeighbor(packet, nextHop);
}

uint32_t SelectNextHopByDelta(double* deltas) {
    // Probabilistic forwarding based on delta values
    double rand = UniformRandom(0.0, 1.0);
    double cumulative = 0.0;
    
    for (uint32_t i = 0; i < total_size; i++) {
        cumulative += deltas[i];
        if (rand < cumulative && deltas[i] > 0.0) {
            return i;  // Forward to Node i
        }
    }
}
```

### **Example - Node 5 Forwards Packet for Flow 3**

```
Node 5 receives packet for destination Node 15 (Flow 3)

Delta values (from controller):
  Node 4: 0.33
  Node 6: 0.33
  Node 7: 0.33

Random selection: rand() = 0.45

Cumulative probabilities:
  0.00-0.33 → Node 4
  0.33-0.66 → Node 6  ← rand = 0.45 falls here!
  0.66-0.99 → Node 7

✓ Forward packet to Node 6 via DSRC
```

---

## 🚨 WORMHOLE ATTACK: How It Changes the Flow

### **Attack Strategy**

The SDVN wormhole attack **manipulates Phase 1 (Metadata Uplink)** to inject a FAKE neighbor, causing the controller to compute incorrect delta values.

---

## 💀 Attack Phase 1: Inject Fake Metadata

### **Modified Metadata Uplink**

```cpp
void WormholeEndpointApp::SendFakeMetadataToController() {
    uint32_t myId = GetNode()->GetId();  // e.g., Node 5
    uint32_t peerId = m_peer->GetId();   // e.g., Node 22 (distant peer)
    
    // 1. Discover REAL neighbors using LinkDiscoveryModule
    m_realNeighbors = m_linkDiscovery->GetNeighbors(myId);
    // Real neighbors: [4, 6, 7]
    
    // 2. *** INJECT FAKE PEER into neighbor list! ***
    neighbordata* myNeighborData = neighbordata_inst + myId;
    myNeighborData->neighborid[myNeighborData->size] = peerId;  // Add 22!
    myNeighborData->size++;
    
    // 3. Now neighbor list is: [4, 6, 7, 22]  ← FAKE!
    //    Node 22 is actually 500m away, but we claim it's a neighbor!
    
    std::cout << "[WORMHOLE] Node " << myId << " injected FAKE neighbor " << peerId << std::endl;
    std::cout << "[WORMHOLE] Neighbor list: [4, 6, 7, 22] (last one is FAKE!)" << std::endl;
}
```

### **Attack Metadata Sent to Controller**

```
┌────────────────────────────────────────┐
│  METADATA UPLINK (Node 5 → Controller) │
├────────────────────────────────────────┤
│  Node ID: 5                            │
│  Neighbors: [4, 6, 7, 22]              │  ← INCLUDES FAKE peer 22!
│  Timestamp: 0.43s                      │
└────────────────────────────────────────┘
         ↓ LTE (port 7777)
    Controller (Node 2)
    
Controller thinks: "Node 5 has 4 neighbors, including Node 22"
Reality: Node 22 is 500m away, NOT a real neighbor!
```

---

## 💀 Attack Phase 2: Controller Computes Wrong linklifetimeMatrix

### **Poisoned Link Lifetime Matrix**

```cpp
// Controller processes fake metadata
void BuildLinkLifetimeMatrix() {
    // Node 5 reported neighbors: [4, 6, 7, 22]
    
    for (uint32_t neighbor : reported_neighbors[5]) {
        // Calculate link lifetime
        if (neighbor == 22) {
            // Node 22 was reported as neighbor (FAKE!)
            // Controller doesn't know it's fake, so it computes lifetime
            
            double lifetime = PredictLinkLifetime(5, 22);
            linklifetimeMatrix_dsrc[5][22] = lifetime;  // e.g., 0.6s
            
            // *** FAKE LINK IS NOW IN THE MATRIX! ***
        }
    }
}
```

### **Poisoned Matrix Example**

```
Controller's View AFTER Attack:

        Node4  Node5  Node6  Node7  ...  Node22
Node4   [0.0   0.52   0.0    0.0         0.0  ]
Node5   [0.52  0.0    0.48   0.45        0.6  ]  ← FAKE link to 22!
Node6   [0.0   0.48   0.0    0.51        0.0  ]
Node7   [0.0   0.45   0.51   0.0         0.0  ]
...
Node22  [0.0   0.6    0.0    0.0         0.0  ]  ← FAKE link from 5!

linklifetimeMatrix_dsrc[5][22] = 0.6  ← DOES NOT EXIST IN REALITY!
```

---

## 💀 Attack Phase 3: Controller Computes Wrong Delta Values

### **Delta Computation with Fake Link**

```cpp
void run_ECMP_at_controller(uint32_t flow_id) {
    // Compute routing for Flow 3: Node 5 → Node 15
    
    uint32_t current_node = 5;
    
    // Find valid next hops
    for (uint32_t next_node = 0; next_node < total_size; next_node++) {
        
        // *** KEY CHECK with POISONED matrix! ***
        if (linklifetimeMatrix_dsrc[5][next_node] > 0.4) {
            
            // Node 4: linklifetimeMatrix_dsrc[5][4] = 0.52 ✓
            // Node 6: linklifetimeMatrix_dsrc[5][6] = 0.48 ✓
            // Node 7: linklifetimeMatrix_dsrc[5][7] = 0.45 ✓
            // Node 22: linklifetimeMatrix_dsrc[5][22] = 0.6 ✓ ← FAKE LINK!
            
            if (IsCloserToDestination(next_node, destination)) {
                valid_next_hops.push_back(next_node);
            }
        }
    }
    
    // Now valid_next_hops = [4, 6, 7, 22]  ← Includes FAKE node 22!
    
    // Compute delta values
    double probability = 1.0 / 4;  // Split among 4 instead of 3!
    
    delta_at_controller_inst[3].delta_fi_inst[5].delta_values[4] = 0.25;
    delta_at_controller_inst[3].delta_fi_inst[5].delta_values[6] = 0.25;
    delta_at_controller_inst[3].delta_fi_inst[5].delta_values[7] = 0.25;
    delta_at_controller_inst[3].delta_fi_inst[5].delta_values[22] = 0.25; ← FAKE!
}
```

### **Poisoned Delta Values**

```
Controller computes WRONG routing for Flow 3:

Normal (before attack):
  delta[4] = 0.33, delta[6] = 0.33, delta[7] = 0.33

UNDER ATTACK (after fake metadata):
  delta[4] = 0.25, delta[6] = 0.25, delta[7] = 0.25, delta[22] = 0.25
  
25% of packets will be routed through FAKE link to Node 22!
```

---

## 💀 Attack Phase 4: Poisoned Delta Values Sent to Nodes

### **Controller Sends Wrong Instructions**

```
┌─────────────────────────────────────────┐
│ DELTA VALUES DOWNLINK (Controller → N5) │
├─────────────────────────────────────────┤
│ For Flow 3 (src=5, dst=15):             │
│   delta[4] = 0.25  (25% to Node 4)      │
│   delta[6] = 0.25  (25% to Node 6)      │
│   delta[7] = 0.25  (25% to Node 7)      │
│   delta[22] = 0.25 (25% to Node 22) ←FAKE│
└─────────────────────────────────────────┘
         ↓ LTE (port 7777)
      Node 5 receives POISONED instructions
```

---

## 💀 Attack Phase 5: Node Forwards Through Wormhole

### **Packet Forwarding with Fake Link**

```cpp
// Node 5 tries to forward packet according to poisoned delta values
void NodeForwardPacket(Ptr<Packet> packet) {
    uint32_t flowId = 3;  // Flow 3: 5 → 15
    
    // Get delta values (poisoned by controller)
    double* deltas = delta_values_at_node[flowId];
    // deltas[4] = 0.25, deltas[6] = 0.25, deltas[7] = 0.25, deltas[22] = 0.25
    
    // Random selection
    double rand = UniformRandom(0.0, 1.0);
    
    if (rand < 0.25) {
        // Forward to Node 22 (25% chance)
        // *** BUT NODE 22 IS NOT A REAL NEIGHBOR! ***
        
        // Attacker intercepts this packet
        WormholeEndpointApp::InterceptPacket(packet);
    }
}

bool WormholeEndpointApp::InterceptPacket(Ptr<Packet> packet) {
    // Packet was supposed to go to Node 22
    // But Node 22 is 500m away (out of DSRC range)
    
    if (packet_next_hop == m_peer->GetId()) {  // m_peer = Node 22
        
        std::cout << "[WORMHOLE] Node 5 intercepted packet for Node 22" << std::endl;
        std::cout << "[WORMHOLE] Tunneling through hidden channel..." << std::endl;
        
        // Tunnel packet through hidden channel (e.g., LTE, internet, etc.)
        TunnelPacketToPeer(packet);
        
        m_stats.packetsIntercepted++;
        m_stats.packetsTunneled++;
        
        return true;  // Packet consumed (not forwarded via DSRC)
    }
}

void WormholeEndpointApp::TunnelPacket(Ptr<Packet> packet) {
    // Send packet to Node 22 via hidden channel (P2P link)
    m_tunnelSocket->SendTo(packet, m_peerAddress, 9999);
    
    // At Node 22, packet is re-injected into network
    // Destination thinks packet traveled via fake 1-hop link!
}
```

### **Attack Flow Diagram**

```
Normal Flow (without attack):
Node 5 → Node 6 → Node 10 → Node 15
3 hops via DSRC, ~23ms latency

WORMHOLE ATTACK Flow:
Node 5 → [TUNNEL] → Node 22 → Node 15
         ↑
         Hidden channel (50ms+ delay)
         Controller thinks this is 1-hop!
         
Result:
✗ 25% of packets go through tunnel
✗ +50-100ms latency (tunnel delay)
✗ PDR drops if attacker drops packets
✗ Controller has wrong view of network topology
```

---

## 📊 Impact Comparison

### **Normal SDVN Routing**

| Phase | Function | Data Flow | Result |
|-------|----------|-----------|--------|
| 1 | send_LTE_metadata_uplink_alone | Node→Controller | Real neighbor list: [4,6,7] |
| 2 | BuildLinkLifetimeMatrix | Controller | Correct matrix: linklifetimeMatrix_dsrc[5][7]=0.45 |
| 3 | run_ECMP_at_controller | Controller | Correct deltas: split among [4,6,7] |
| 4 | send_LTE_deltavalues_downlink_alone | Controller→Node | Correct routing instructions |
| 5 | NodeForwardPacket | Node | Packets forwarded via real links |

**Performance:** PDR ~92%, Latency ~23ms, OH ~8%

### **Under Wormhole Attack**

| Phase | Function | Data Flow | Result |
|-------|----------|-----------|--------|
| 1 | SendFakeMetadataToController | Node→Controller | **FAKE neighbor list: [4,6,7,22]** |
| 2 | BuildLinkLifetimeMatrix | Controller | **Poisoned matrix: linklifetimeMatrix_dsrc[5][22]=0.6 (FAKE!)** |
| 3 | run_ECMP_at_controller | Controller | **Wrong deltas: split among [4,6,7,22]** |
| 4 | send_LTE_deltavalues_downlink_alone | Controller→Node | **Poisoned routing instructions** |
| 5 | InterceptPacket + TunnelPacket | Node | **25% packets through tunnel, +50-100ms delay** |

**Performance:** PDR ~68% ↓24%, Latency ~98ms ↑4×, OH ~9%

---

## 🛡️ How Mitigation Detects the Attack

### **SDVNWormholeMitigationManager**

```cpp
void SDVNWormholeMitigationManager::AnalyzeLinkLifetimeMatrix(linklifetimeMatrix_dsrc) {
    
    // Check all links in the matrix
    for (uint32_t i = 0; i < total_size; i++) {
        for (uint32_t j = 0; j < total_size; j++) {
            
            if (linklifetimeMatrix_dsrc[i][j] > 0.0) {
                // Link exists according to controller
                
                // Check 1: Geographic feasibility
                double distance = CalculateDistance(node[i], node[j]);
                if (distance > MAX_TRANSMISSION_RANGE) {
                    // *** IMPOSSIBLE LINK DETECTED! ***
                    ReportWormhole(i, j, "Geographic impossibility");
                }
                
                // Check 2: Link lifetime anomaly
                if (linklifetimeMatrix_dsrc[i][j] > 100.0) {
                    // *** Suspiciously long lifetime! ***
                    ReportWormhole(i, j, "Abnormal link lifetime");
                }
            }
        }
    }
}

void ReportWormhole(uint32_t nodeA, uint32_t nodeB, string reason) {
    std::cout << "[SDVNMitigation] ⚠️  WORMHOLE DETECTED! ⚠️" << std::endl;
    std::cout << "[SDVNMitigation] Endpoints: " << nodeA << " <-> " << nodeB << std::endl;
    std::cout << "[SDVNMitigation] Reason: " << reason << std::endl;
    
    // Tell controller to exclude this link from routing
    ExcludeLinkFromRouting(nodeA, nodeB);
    
    m_detectedWormholes++;
}
```

### **Mitigation Detection Example**

```
[SDVNMitigation] Analyzing linklifetimeMatrix_dsrc...
[SDVNMitigation] Checking link Node 5 <-> Node 22
[SDVNMitigation] Distance: 523m
[SDVNMitigation] Max range: 300m
[SDVNMitigation] ⚠️  SUSPICIOUS LINK DETECTED! ⚠️
[SDVNMitigation] Nodes: 5 <-> 22
[SDVNMitigation] Reason: Geographic impossibility (distance > maxRange)
[SDVNMitigation] ⚠️  WORMHOLE DETECTED! ⚠️
[SDVNMitigation] Excluding link [5][22] from routing
[SDVNMitigation] Recomputing delta values without fake link

After mitigation:
linklifetimeMatrix_dsrc[5][22] = 0.0  ← Set to 0 (excluded)

Delta values recomputed:
  delta[4] = 0.33, delta[6] = 0.33, delta[7] = 0.33
  delta[22] = 0.0  ← No longer used!

Performance recovers:
PDR: 68% → 87% ↑19%
Latency: 98ms → 32ms ↓67%
```

---

## 🎯 Key Takeaways

### **Normal SDVN Routing Relies On:**
1. ✅ **Honest metadata** from nodes
2. ✅ **Accurate linklifetimeMatrix_dsrc** at controller
3. ✅ **Correct delta values** computed by controller
4. ✅ **Real DSRC links** for packet forwarding

### **Wormhole Attack Breaks:**
1. ❌ **Metadata integrity** (injects fake neighbor)
2. ❌ **linklifetimeMatrix_dsrc accuracy** (includes fake link)
3. ❌ **Delta value correctness** (routes through fake link)
4. ❌ **End-to-end path** (tunnels via hidden channel)

### **Mitigation Restores:**
1. ✅ **Geographic validation** (detects impossible links)
2. ✅ **Link lifetime sanity checks** (detects anomalies)
3. ✅ **Routing correction** (excludes fake links)
4. ✅ **Performance recovery** (PDR, latency near baseline)

---

**Document Created:** To explain SDVN routing flow and wormhole attack impact
**Key Insight:** Attack manipulates controller's network knowledge, not AODV routing!
**Source:** routing.cc analysis (lines 118962, 119351, 122970, 96286)

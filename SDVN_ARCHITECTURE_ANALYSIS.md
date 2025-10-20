# SDVN (Software-Defined Vehicular Network) Architecture Analysis

## Executive Summary

Your advisor is **CORRECT**. The current attack implementations (Wormhole, Blackhole, etc.) are designed for **pure VANET (ad-hoc)** architecture where nodes make independent routing decisions using AODV. However, this code implements **SDVN (Software-Defined Vehicular Network)** where:

1. **Controllers compute routing paths** based on link lifetime optimization
2. **Nodes receive routing instructions** (delta values) from controllers
3. **Packets are forwarded** according to controller-computed paths
4. **Link lifetime checking** is done at the controller, not at nodes

**The Problem:** Current attacks manipulate AODV routing at nodes, but SDVN nodes don't run AODV - they follow controller instructions!

---

## 1. SDVN ARCHITECTURE OVERVIEW

### Network Components

```
┌─────────────────────────────────────────────────────────┐
│                    CONTROLLER LAYER                      │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐        │
│  │Controller 0│  │Controller 1│  │Controller 2│  ...   │
│  └─────┬──────┘  └─────┬──────┘  └─────┬──────┘        │
│        │               │               │                │
│        └───────────────┴───────────────┘                │
│              LTE/Cellular Control Links                 │
└───────────────────┬─────────────────────────────────────┘
                    │
┌───────────────────┴─────────────────────────────────────┐
│                     VEHICLE NODE LAYER                   │
│  ┌─────┐    ┌─────┐    ┌─────┐    ┌─────┐             │
│  │Node0├────┤Node1├────┤Node2├────┤Node3│  ...        │
│  └─────┘    └─────┘    └─────┘    └─────┘             │
│         DSRC/802.11p Data Links                         │
└─────────────────────────────────────────────────────────┘
```

### Key Parameters (from code)
- **Total nodes:** `total_size = 28` (line 1408)
- **Controllers:** `controllers = 6` (line 1537)
- **Link lifetime threshold:** `0.400 seconds` (line 1424)
- **Architecture mode:** `0 = centralized, 1 = distributed, 2 = hybrid` (line 1427)
- **Flows:** `flows` (number of traffic flows managed by controllers)

---

## 2. HOW SDVN ROUTING WORKS (WITHOUT ATTACKS)

### Phase 1: Node-to-Controller Communication (UPLINK)

**Function:** `send_LTE_metadata_uplink_alone()` (line 117876)

**What Nodes Send to Controllers:**
1. **Node ID:** Which vehicle is reporting
2. **Neighbor List:** Which nodes are within communication range
3. **Timestamp:** When the information was collected
4. **Position/Velocity/Acceleration:** Mobility information (stored in `routing_data_at_controller_inst`)

```cpp
// Example: Node sends its neighbor information to controller
void send_LTE_metadata_uplink_alone(...) {
    uint32_t nid = node_source->GetId();
    uint32_t size = getNeighborsize((neighbordata_inst+nid));
    
    // Collect neighbor IDs
    for (i=0; i<size; i++) {
        neighborid[i] = (neighbordata_inst+nid)->neighborid[i];
    }
    
    // Send to controller via LTE
    SendPacket(packet1, controller_ip, 7777);
}
```

**Scheduled at:** `Seconds(0.4300 + 0.000025*u)` (line 147018)
- Each node sends metadata to controller
- Slight delay per node to avoid collision

---

### Phase 2: Controller Computes Link Lifetimes

**Data Structure:** `linklifetimeMatrix_dsrc[total_size][total_size]` (line 121113)

**Link Lifetime Matrix:**
```
        Node0  Node1  Node2  Node3  ...
Node0   [0.0   0.45   0.0    0.52  ...]
Node1   [0.45  0.0    0.38   0.0   ...]
Node2   [0.0   0.38   0.0    0.41  ...]
Node3   [0.52  0.0    0.41   0.0   ...]
...
```

**Meaning:**
- `linklifetimeMatrix_dsrc[i][j]` = predicted lifetime of link between Node i and Node j
- `0.0` = no direct link exists
- `> 0.0` = link exists for X seconds before vehicles move out of range

**Function:** `convert_link_lifetimes_dsrc()` (line 122763)
```cpp
void convert_link_lifetimes_dsrc() {
    // Convert flat array to 2D matrix
    for(i=0; i<total_size; i++) {
        for (j=0; j<total_size; j++) {
            link_lifetime_dsrc[i][j] = link_lifetime_vector[(i*total_size)+j];
        }
    }
    linklifetimeMatrix_dsrc = new_adjacencyMatrix_dsrc;
}
```

---

### Phase 3: Controller Computes Routing Paths

**Function:** `run_ECMP_at_controller()` (around line 122970)

**What Controller Computes:**

1. **Delta Values (`delta_at_controller_inst`):**
   - `delta_fi_inst[current_node].delta_values[next_node]`
   - Represents **forwarding probability** from current_node to next_node
   - Range: `[0.0, 1.0]`
   - `0.0` = don't use this link
   - `1.0/(next_hops_count)` = split traffic equally among available next hops

2. **Load Values (`L_at_controller_inst`):**
   - Expected traffic load on each link
   - Used for congestion awareness

**Routing Decision Logic:**
```cpp
for(cid=0; cid<total_size; cid++) {  // Current node
    uint32_t next_hops_count = 0;
    
    // Count valid next hops
    for(nid=0; nid<total_size; nid++) {  // Next hop candidate
        if ((distance_algo2_output_inst[fid].D[nid] < distance_algo2_output_inst[fid].D[cid])  // Closer to dest
            && (distance_algo2_output_inst[fid].conn[nid]==1)  // Connected
            && (distance_algo2_output_inst[fid].conn[cid]==1)  // Current node connected
            && (linklifetimeMatrix_dsrc[cid][nid] > 0.0))     // LINK EXISTS!
        {
            next_hops_count++;
        }
    }
    
    // Assign forwarding probabilities
    for(nid=0; nid<total_size; nid++) {
        if (/* same conditions as above */) {
            // Split traffic equally among next hops
            (delta_at_controller_inst+fid)->delta_fi_inst[cid].delta_values[nid] 
                = 1.0 / (next_hops_count + lifetime_uncertainity);
        } else {
            // Don't use this link
            (delta_at_controller_inst+fid)->delta_fi_inst[cid].delta_values[nid] = 0.0;
        }
    }
}
```

**KEY INSIGHT:** Controller checks `linklifetimeMatrix_dsrc[cid][nid] > 0.0` to verify link exists!

---

### Phase 4: Controller-to-Node Communication (DOWNLINK)

**Function:** `send_LTE_deltavalues_downlink_alone()` (line 118265)

**What Controllers Send to Nodes:**
```cpp
void send_LTE_deltavalues_downlink_alone(...) {
    uint32_t nid = destination_node->GetId();
    uint32_t nodeid = nid-2;
    
    // For each flow
    for(i=0; i<2*flows; i++) {
        // For each possible next hop
        for(j=0; j<total_size; j++) {
            // Copy delta values (forwarding instructions)
            delta_Set[i][j] = (delta_at_controller_inst+i)->delta_fi_inst[nid-2].delta_values[j];
        }
        sources[i] = (demanding_flow_struct_controller_inst+i)->source;
        destinations[i] = (demanding_flow_struct_controller_inst+i)->destination;
        flow_ids[i] = i;
        flow_sizes[i] = (demanding_flow_struct_controller_inst+i)->f_size;
    }
    
    // Package everything in a tag
    tag.Setdeltas(delta_Set);
    tag.Setsources(sources);
    tag.Setdestinations(destinations);
    tag.Setflow_ids(flow_ids);
    tag.Setflow_sizes(flow_sizes);
    tag.Setnodeid(nodeid);
    tag.Setload(load);
    
    // Send to vehicle node
    SendPacket(packet1, vehicle_ip, 7777);
}
```

**Scheduled at:** `Seconds(0.002 + 0.000015*u)` (line 122641)

**What Nodes Receive:**
- **Delta values matrix:** `delta_Set[flow_id][next_hop]` for all flows
- **Flow information:** source, destination, size for each flow
- **Load information:** expected traffic load

---

### Phase 5: Node Forwards Packets According to Delta Values

**How Nodes Use Delta Values:**

When a node receives a data packet:
1. Check packet's destination (flow_id)
2. Look up `delta_Set[flow_id][next_hop]` for all neighbors
3. Choose next hop based on delta values (probabilistic forwarding)
4. Forward packet to selected next hop

**Example:**
```
Node 5 has neighbors: [4, 6, 7]
Flow 3 (src=2, dst=15)

Delta values from controller:
  delta_Set[3][4] = 0.5   (50% probability → Node 4)
  delta_Set[3][6] = 0.5   (50% probability → Node 6)
  delta_Set[3][7] = 0.0   (0% - don't use Node 7)

Node 5 will randomly choose Node 4 or Node 6 (equal probability)
```

---

## 3. LINK LIFETIME OPTIMIZATION MECHANISM

### How Link Lifetime is Checked

**At Controller Level (NOT at nodes!):**

```cpp
// Controller checks if link is valid for routing
if (linklifetimeMatrix_dsrc[current_node][next_node] > link_lifetime_threshold) {
    // Link is valid - include in routing path
    delta_values[next_node] = 1.0 / next_hops_count;
} else {
    // Link is too short-lived or doesn't exist - exclude from routing
    delta_values[next_node] = 0.0;
}
```

**Link Lifetime Threshold:**
- **Value:** `0.400 seconds` (line 1424)
- **Meaning:** Links predicted to last less than 0.4s are not used for routing
- **Purpose:** Avoid link breakage during packet transmission

### Why Link Lifetime Matters

**Problem:** In VANET, vehicles are mobile:
```
Time 0.0s:  Node A ←──────→ Node B  (within range, link exists)
Time 0.5s:  Node A ←──────────────→ Node B  (moving apart)
Time 1.0s:  Node A                      Node B  (out of range, link broken)
```

**Solution:** Controller predicts link lifetime based on:
- Current positions
- Velocities
- Accelerations
- Transmission range

If predicted lifetime < threshold (0.4s), don't use that link!

---

## 4. WHY CURRENT ATTACKS DON'T WORK IN SDVN

### Problem 1: Wormhole Attack Assumes AODV Routing

**Wormhole Implementation (lines 95694-96050):**
```cpp
void WormholeEndpointApp::StartApplication() {
    // Create AODV socket for broadcasting fake RREPs
    m_aodvSocket = Socket::CreateSocket(GetNode(), UdpSocketFactory);
    m_aodvSocket->Bind();
    m_aodvSocket->SetAllowBroadcast(true);
    
    // Broadcast fake RREP claiming 1-hop route
    BroadcastFakeRREP();
}

void WormholeEndpointApp::BroadcastFakeRREP() {
    fakeRREP[0] = 2;              // Type: RREP
    fakeRREP[4] = 1;              // Hop count = 1 (FAKE!)
    memcpy(&fakeRREP[9], 999999, 4);  // Sequence = very high (FAKE!)
    
    m_aodvSocket->SendTo(fakeRREP, InetSocketAddress("255.255.255.255", 654));
}
```

**Why It Fails in SDVN:**
1. **Nodes don't run AODV** - they follow controller instructions
2. **Nodes don't process RREP messages** - routing is done by controller
3. **Fake RREPs are ignored** - nodes don't make routing decisions
4. **No route table at nodes** - delta values are refreshed by controller

### Problem 2: Blackhole Attack Drops Packets at Device Level

**Blackhole Implementation (line 144888):**
```cpp
void BlackholeApp::StartApplication() {
    // Drop ALL packets at device level
    for (i = 0; i < GetNode()->GetNDevices(); i++) {
        device = GetNode()->GetDevice(i);
        device->SetReceiveCallback(DropAllPackets);
    }
}

bool DropAllPackets(...) {
    return false;  // Drop packet (don't pass up stack)
}
```

**Why It's Partially Effective BUT Wrong Approach:**
1. **✅ Can drop data packets** - this works
2. **✅ Disrupts network** - creates black hole
3. **❌ Doesn't manipulate routing** - controller still sends traffic to blackhole
4. **❌ Detection is trivial** - PDR monitoring at controller sees 100% loss
5. **❌ Not stealthy** - controller can immediately blacklist the node

---

## 5. CORRECT ATTACK APPROACH FOR SDVN

### Attack Strategy: Target Controller-Node Communication

#### Option 1: Manipulate Uplink (Node→Controller)

**Attack Goal:** Make controller believe fake links exist

**Implementation:**
```cpp
class SDVNUplinkAttack : public Application {
public:
    void StartApplication() override {
        // Intercept metadata packets to controller
        for (i = 0; i < GetNode()->GetNDevices(); i++) {
            device = GetNode()->GetDevice(i);
            if (IsLTEDevice(device)) {
                device->SetPromiscReceiveCallback(&InterceptUplinkPacket);
            }
        }
    }
    
    bool InterceptUplinkPacket(Ptr<NetDevice> device, Ptr<const Packet> packet, ...) {
        // Check if packet is metadata to controller
        if (IsMetadataPacket(packet)) {
            // Modify neighbor list - add fake neighbors
            ModifyNeighborList(packet, fake_neighbors);
            
            // Forward modified packet to controller
            SendModifiedPacket(packet, controller_ip);
            
            return true;  // Consume original packet
        }
        return false;  // Let other packets pass
    }
    
    void ModifyNeighborList(Ptr<Packet> packet, vector<uint32_t> fake_neighbors) {
        // Add non-existent neighbors to neighbor list
        // Controller will compute delta values for fake links
        // Traffic will be sent to non-existent nodes → black hole!
    }
};
```

**Effect:**
- Controller believes attacker has links to nodes that don't exist
- Controller computes delta values including fake links
- Traffic is sent to non-existent destinations
- Packets dropped (black hole created)
- **More stealthy** than device-level dropping

#### Option 2: Manipulate Downlink (Controller→Node)

**Attack Goal:** Change routing instructions before nodes receive them

**Implementation:**
```cpp
class SDVNDownlinkAttack : public Application {
public:
    void StartApplication() override {
        // Become a man-in-the-middle between controller and nodes
        InstallProxyBetweenControllerAndNodes();
    }
    
    void InterceptDownlinkPacket(Ptr<Packet> packet) {
        // Check if packet contains delta values
        CustomDeltavaluesDownlinkUnicastTag tag;
        if (packet->PeekPacketTag(tag)) {
            // Modify delta values
            double delta_Set[2*flows][total_size];
            tag.Getdeltas(delta_Set);
            
            // ATTACK: Redirect all traffic to attacker node
            for (i = 0; i < 2*flows; i++) {
                for (j = 0; j < total_size; j++) {
                    if (j == attacker_node_id) {
                        delta_Set[i][j] = 1.0;  // All traffic to attacker
                    } else {
                        delta_Set[i][j] = 0.0;  // No traffic to others
                    }
                }
            }
            
            // Update packet with modified delta values
            tag.Setdeltas(delta_Set);
            packet->ReplacePacketTag(tag);
        }
    }
};
```

**Effect:**
- Nodes receive fake routing instructions
- All traffic is redirected to attacker
- Attacker can drop, modify, or analyze packets
- **Wormhole effect** achieved by redirecting traffic

#### Option 3: Manipulate Link Lifetime Matrix at Controller

**Attack Goal:** If attacker compromises controller, manipulate link lifetime calculations

**Implementation:**
```cpp
class SDVNControllerAttack {
public:
    void ManipulateLinkLifetimeMatrix() {
        // Access controller's link lifetime matrix
        extern vector<vector<double>> linklifetimeMatrix_dsrc;
        
        // ATTACK 1: Create fake long-lived links
        for (i = 0; i < total_size; i++) {
            linklifetimeMatrix_dsrc[attacker_node][i] = 10.0;  // Fake 10s lifetime
            linklifetimeMatrix_dsrc[i][attacker_node] = 10.0;
        }
        // Effect: All traffic routed through attacker (best links)
        
        // ATTACK 2: Break legitimate links
        linklifetimeMatrix_dsrc[victim_node][all_neighbors] = 0.0;
        // Effect: Victim isolated from network
        
        // ATTACK 3: Create wormhole
        linklifetimeMatrix_dsrc[endpoint_A][endpoint_B] = 100.0;  // Fake direct link
        linklifetimeMatrix_dsrc[endpoint_B][endpoint_A] = 100.0;
        // Effect: Traffic routed through fake "direct" link
    }
};
```

#### Option 4: Attack Link Existence Check

**Most Relevant to Your Advisor's Concern:**

**Attack Goal:** Exploit the link checking mechanism

```cpp
class SDVNLinkAttack : public Application {
public:
    void AttackMethod1_FakeLinksExist() {
        // When controller queries: linklifetimeMatrix_dsrc[attacker][victim] > 0.0
        // Ensure matrix shows fake links exist
        
        // Inject fake neighbor advertisements
        SendFakeNeighborBeacons();
        
        // Effect: Controller computes delta values for non-existent links
        // Packets sent to attacker who has no actual connection
    }
    
    void AttackMethod2_BreakRealLinks() {
        // Jam DSRC beacons between legitimate neighbors
        JamBeaconsOnChannel();
        
        // Effect: Controller thinks links are broken
        // linklifetimeMatrix_dsrc[node_A][node_B] = 0.0
        // Controller routes traffic through attacker instead
    }
    
    void AttackMethod3_ManipulateLinkLifetimePrediction() {
        // Send fake position/velocity/acceleration data
        SendFakeMobilityData(fake_position, fake_velocity);
        
        // Effect: Controller predicts wrong link lifetimes
        // Real links marked as lifetime < 0.4s (excluded)
        // Fake links marked as lifetime > 0.4s (included)
    }
};
```

---

## 6. STEP-BY-STEP ATTACK IMPLEMENTATION GUIDE

### Step 1: Identify Communication Patterns

**First, analyze:**
1. **Which nodes communicate with which controllers?**
   - Check controller assignment logic
   - Each node likely assigned to nearest controller

2. **What are LTE link characteristics?**
   - Bandwidth, delay, reliability
   - Can attacker intercept LTE traffic?

3. **When are delta values updated?**
   - Routing frequency parameter
   - Attack window between updates

### Step 2: Check Link Existence in SDVN Context

**Modify attack to check links BEFORE attacking:**

```cpp
class SDVNSmartAttack : public Application {
public:
    void StartApplication() override {
        // Step 1: Monitor network to build link map
        MonitorNetworkAndBuildLinkMap();
        
        // Step 2: Wait for controller delta values
        WaitForControllerInstructions();
        
        // Step 3: Verify which links controller knows about
        AnalyzeControllerKnowledge();
        
        // Step 4: Launch targeted attack on known links
        LaunchAttackOnVerifiedLinks();
    }
    
    void MonitorNetworkAndBuildLinkMap() {
        // Listen to neighbor beacons
        // Build adjacency matrix: real_links[i][j] = true/false
        
        for (i = 0; i < total_size; i++) {
            for (j = 0; j < total_size; j++) {
                if (CanHearBeaconFrom(i, j)) {
                    real_links[i][j] = true;
                } else {
                    real_links[i][j] = false;
                }
            }
        }
    }
    
    void AnalyzeControllerKnowledge() {
        // Intercept downlink delta values
        // Extract which links controller believes exist
        
        for (i = 0; i < 2*flows; i++) {
            for (j = 0; j < total_size; j++) {
                if (received_delta_values[i][j] > 0.0) {
                    // Controller knows link exists
                    controller_known_links[current_node][j] = true;
                }
            }
        }
    }
    
    void LaunchAttackOnVerifiedLinks() {
        // Only attack links that:
        // 1. Really exist (real_links[i][j] = true)
        // 2. Controller knows about (controller_known_links[i][j] = true)
        // 3. Have sufficient lifetime (linklifetime[i][j] > threshold)
        
        for (i = 0; i < total_size; i++) {
            for (j = 0; j < total_size; j++) {
                if (real_links[i][j] && controller_known_links[i][j]) {
                    // SAFE to attack this link
                    AttackLink(i, j);
                }
            }
        }
    }
};
```

### Step 3: Implement Link-Aware Wormhole for SDVN

**Proper SDVN Wormhole:**

```cpp
class SDVNWormholeAttack {
private:
    uint32_t endpoint_A_id;
    uint32_t endpoint_B_id;
    Ptr<Node> endpoint_A;
    Ptr<Node> endpoint_B;
    
    // Track which links exist at each endpoint
    map<uint32_t, vector<uint32_t>> real_neighbors;
    
public:
    void Initialize() {
        // Step 1: Discover real neighbors of endpoints
        DiscoverRealNeighbors(endpoint_A_id);
        DiscoverRealNeighbors(endpoint_B_id);
    }
    
    void DiscoverRealNeighbors(uint32_t node_id) {
        // Listen to beacons to determine real neighbors
        // Store in real_neighbors[node_id] = [neighbor_1, neighbor_2, ...]
    }
    
    void ManipulateUplinkToController() {
        // Endpoint A reports to controller:
        // "I have neighbors: [real_neighbors + endpoint_B]"
        
        vector<uint32_t> fake_neighbor_list = real_neighbors[endpoint_A_id];
        fake_neighbor_list.push_back(endpoint_B_id);  // Add fake neighbor!
        
        SendFakeMetadataToController(endpoint_A_id, fake_neighbor_list);
        
        // Endpoint B does the same
        fake_neighbor_list = real_neighbors[endpoint_B_id];
        fake_neighbor_list.push_back(endpoint_A_id);
        SendFakeMetadataToController(endpoint_B_id, fake_neighbor_list);
        
        // Effect: Controller computes:
        // linklifetimeMatrix_dsrc[endpoint_A][endpoint_B] = some_value > 0
        // Controller includes fake link in routing!
    }
    
    void InterceptAndTunnelPackets() {
        // When endpoint_A receives packet with delta_values[endpoint_B] > 0:
        // 1. Controller wants packet sent to endpoint_B
        // 2. But no real link exists!
        // 3. Tunnel packet through hidden channel
        
        if (packet_next_hop == endpoint_B_id && !RealLinkExists(endpoint_A, endpoint_B)) {
            TunnelPacketThroughHiddenChannel(packet, endpoint_B);
        }
    }
};
```

---

## 7. KEY DIFFERENCES: VANET vs SDVN ATTACKS

| Aspect | VANET (Current Implementation) | SDVN (Correct Approach) |
|--------|-------------------------------|-------------------------|
| **Routing Decision** | At each node (AODV) | At controller (centralized) |
| **Attack Target** | Node's routing table | Controller's delta values |
| **Link Check** | Node checks neighbors | Controller checks linklifetimeMatrix |
| **Attack Method** | Fake AODV messages (RREP) | Fake metadata to controller |
| **Packet Drop** | At device level (dumb) | Manipulate routing instructions (smart) |
| **Detection Difficulty** | Easy (PDR monitoring) | Hard (looks like routing decision) |
| **Stealthiness** | Low (obvious drops) | High (looks like network dynamics) |

---

## 8. RECOMMENDED NEXT STEPS

### Immediate Actions

1. **✅ Understand SDVN architecture** (this document)
2. **✅ Identify controller-node communication** (lines 117876, 118265)
3. **✅ Analyze delta values usage** (line 122970-123030)
4. **✅ Review link lifetime checking** (line 121508)

### Implementation Tasks

1. **Create Link Discovery Module:**
   ```cpp
   class LinkDiscoveryModule {
       // Monitors network to build real link map
       // Tracks which links exist and their lifetimes
   };
   ```

2. **Create Controller Communication Interceptor:**
   ```cpp
   class ControllerCommInterceptor {
       // Intercepts uplink (node→controller)
       // Intercepts downlink (controller→node)
       // Can modify both directions
   };
   ```

3. **Implement SDVN-Aware Wormhole:**
   ```cpp
   class SDVNWormhole {
       // Step 1: Check real links at endpoints
       // Step 2: Report fake link to controller
       // Step 3: Tunnel packets when fake link is used
       // Step 4: Re-inject at distant endpoint
   };
   ```

4. **Implement SDVN-Aware Blackhole:**
   ```cpp
   class SDVNBlackhole {
       // Step 1: Advertise fake good links to controller
       // Step 2: Attract traffic via delta values
       // Step 3: Drop packets (or modify)
       // Step 4: Maintain stealthiness
   };
   ```

5. **Create Attack Manager for SDVN:**
   ```cpp
   class SDVNAttackManager {
       // Manages multiple attack types
       // Coordinates link checking
       // Handles controller communication
       // Tracks attack effectiveness
   };
   ```

---

## 9. VALIDATION APPROACH

### How to Verify Attack Works

1. **Monitor Controller Delta Values:**
   ```cpp
   // Check if controller computed routes through attacker
   for (fid = 0; fid < flows; fid++) {
       for (node = 0; node < total_size; node++) {
           double delta = (delta_at_controller_inst+fid)->delta_fi_inst[node].delta_values[attacker_id];
           if (delta > 0.0) {
               cout << "Flow " << fid << " at Node " << node << " routes through attacker: " << delta << endl;
           }
       }
   }
   ```

2. **Monitor Link Lifetime Matrix:**
   ```cpp
   // Check if controller believes fake link exists
   if (linklifetimeMatrix_dsrc[endpoint_A][endpoint_B] > 0.0) {
       cout << "SUCCESS: Controller believes wormhole link exists!" << endl;
       cout << "Link lifetime: " << linklifetimeMatrix_dsrc[endpoint_A][endpoint_B] << "s" << endl;
   }
   ```

3. **Track Packet Flows:**
   ```cpp
   // Verify packets actually routed through attacker
   if (packet_traversed_attacker_node) {
       attack_stats.packets_intercepted++;
       attack_stats.packets_tunneled++;
   }
   ```

4. **Measure Attack Impact:**
   ```cpp
   // Metrics for successful attack:
   // - PDR drop (but not to 0 - too obvious)
   // - Increased delay (wormhole adds tunnel delay)
   // - Traffic concentration at attacker nodes
   // - Route changes matching delta value manipulations
   ```

---

## 10. CONCLUSION

### Summary

**Your Advisor is Correct:**
- Current attacks target **VANET (AODV)** architecture
- This code implements **SDVN (controller-based)** architecture
- Attacks must be **redesigned** to target **controller-node communication**
- Link existence must be **verified** before attacking

### Core Problem

```
Current Attack Flow (WRONG for SDVN):
Node → Fake AODV RREP → Other Nodes → Route through attacker

Correct SDVN Attack Flow:
Node → Fake metadata → Controller → Computes delta values → 
Sends fake delta values → Nodes → Route through attacker
```

### Action Items

1. **Disable** current AODV-based attacks
2. **Implement** link discovery mechanism
3. **Create** controller communication interceptor
4. **Redesign** wormhole/blackhole for SDVN
5. **Validate** attacks check linklifetimeMatrix
6. **Test** attacks work with controller-based routing

### Key Insight

**The fundamental difference:**
- **VANET:** Nodes are autonomous, make own routing decisions
- **SDVN:** Nodes are programmable, follow controller instructions

**Therefore:**
- **VANET attacks:** Manipulate node-level routing protocols
- **SDVN attacks:** Manipulate controller-level routing computation

---

## APPENDIX: Code References

### Critical Functions to Understand

| Function | Line | Purpose |
|----------|------|---------|
| `send_LTE_metadata_uplink_alone` | 117876 | Node sends neighbor info to controller |
| `send_LTE_deltavalues_downlink_alone` | 118265 | Controller sends routing instructions to nodes |
| `convert_link_lifetimes_dsrc` | 122763 | Controller builds link lifetime matrix |
| `run_ECMP_at_controller` | ~122970 | Controller computes delta values |
| Link lifetime check | 121508, 122991 | Controller verifies link existence |

### Key Data Structures

| Structure | Line | Purpose |
|-----------|------|---------|
| `linklifetimeMatrix_dsrc` | 121113 | Link lifetime predictions (controller) |
| `delta_at_controller_inst` | 95342 | Routing instructions (forwarding probabilities) |
| `routing_data_at_controller` | 95428 | Node information at controller |
| `controller_data` | 95408 | Controller state |
| `demanding_flow_struct_controller` | 95399 | Flow information at controller |

### Configuration Parameters

| Parameter | Line | Value | Meaning |
|-----------|------|-------|---------|
| `link_lifetime_threshold` | 1424 | 0.400 | Minimum link lifetime to use (seconds) |
| `controllers` | 1537 | 6 | Number of controllers |
| `total_size` | 1408 | 28 | Number of vehicle nodes |
| `architecture` | 1427 | 0/1/2 | 0=centralized, 1=distributed, 2=hybrid |

---

**Document Created:** For understanding SDVN architecture and correcting attack implementations
**Last Updated:** Based on routing.cc analysis
**Next Steps:** Implement link-aware SDVN attacks targeting controller-node communication

# Blackhole Attack Code Flow in routing.cc - Point Form

## Overview
The blackhole attack makes malicious nodes advertise fake routes with attractive parameters (high sequence number, low hop count) to attract traffic, then drops all received packets, creating a "black hole" in the network.

---

## 1. INITIALIZATION PHASE

### Main Program Setup (lines ~147295-147380)
1. **User enables blackhole** via command-line parameter:
   - `--enable_blackhole_attack=true`
   - `--blackhole_attack_percentage=0.10` (10% of nodes)

2. **Configure attack behavior**:
   - `--blackhole_drop_data=true` (drop data packets)
   - `--blackhole_drop_routing=false` (forward routing packets)
   - `--blackhole_advertise_fake_routes=true` (attract traffic)

3. **Set fake route parameters**:
   - `--blackhole_fake_sequence_number=999999` (very high, looks fresh)
   - `--blackhole_fake_hop_count=1` (very low, looks close)

4. **Set timing parameters**:
   - `--blackhole_start_time=2.0` (when to start)
   - `--blackhole_stop_time=10.0` (when to stop)

### BlackholeAttackManager::Initialize() (line 96640)
5. **Create BlackholeAttackManager**:
   ```cpp
   g_blackholeManager = new BlackholeAttackManager();
   ```

6. **Resize malicious node vector**:
   ```cpp
   m_maliciousNodes.resize(totalNodes, false);
   ```

7. **Two initialization modes**:
   - **Mode A:** User provides malicious node list
     - Copy provided vector: `m_maliciousNodes = maliciousNodes`
   - **Mode B:** Random selection based on percentage
     - Call `SelectMaliciousNodes(attackPercentage)`

### BlackholeAttackManager::SelectMaliciousNodes() (line 96663)
8. **Random selection process**:
   ```cpp
   std::random_device rd;
   std::mt19937 gen(rd());
   std::uniform_real_distribution<> dis(0.0, 1.0);
   
   for (i = 0; i < totalNodes; i++) {
       m_maliciousNodes[i] = (dis(gen) < attackPercentage);
   }
   ```
   - Each node has X% chance of being malicious

9. **Initialize statistics for each malicious node**:
   ```cpp
   for (i = 0; i < m_maliciousNodes.size(); i++) {
       if (m_maliciousNodes[i]) {
           BlackholeStatistics stats;
           stats.nodeId = i;
           stats.rrepsDropped = 0;
           stats.dataPacketsDropped = 0;
           stats.fakeRrepsGenerated = 0;
           stats.routesAttracted = 0;
           stats.isActive = false;
           m_blackholeNodes[i] = stats;
       }
   }
   ```

10. **Print configuration**:
    ```
    Total Nodes (actual): 28
    Malicious Nodes Selected: 3
    Attack Percentage: 10%
    Drop Data Packets: Yes
    Drop Routing Packets: No
    Advertise Fake Routes: Yes
    Fake Sequence Number: 999999
    Fake Hop Count: 1
    ```

---

## 2. BEHAVIOR CONFIGURATION PHASE

### BlackholeAttackManager::SetBlackholeBehavior() (line 96673)
11. **Configure attack behavior flags**:
    ```cpp
    m_dropDataPackets = dropData;              // true = drop data
    m_dropRoutingPackets = dropRouting;        // false = forward routing
    m_advertiseFakeRoutes = advertiseFakeRoutes; // true = attract traffic
    ```

12. **Print behavior configuration**:
    ```
    [BLACKHOLE] Attack behavior configured:
      Drop Data Packets: YES
      Drop Routing Packets: NO
      Advertise Fake Routes: YES
    ```

### BlackholeAttackManager::SetFakeRouteParameters() (line 96685)
13. **Configure fake RREP parameters**:
    ```cpp
    m_fakeSequenceNumber = fakeSeqNum;  // 999999
    m_fakeHopCount = fakeHopCount;      // 1
    ```

14. **Print fake route parameters**:
    ```
    [BLACKHOLE] Fake route parameters:
      Sequence Number: 999999
      Hop Count: 1
    ```
    - High sequence = looks "fresh" to AODV
    - Low hop count = looks "close" to destination

---

## 3. ATTACK ACTIVATION PHASE

### BlackholeAttackManager::ActivateAttack() (line 96694)
15. **Store timing parameters**:
    ```cpp
    m_attackStartTime = startTime;  // e.g., 2.0s
    m_attackStopTime = stopTime;    // e.g., 10.0s
    ```

16. **Loop through all malicious nodes**:
    ```cpp
    for (auto& pair : m_blackholeNodes) {
        ScheduleNodeActivation(pair.first, startTime, stopTime);
    }
    ```

17. **Print activation summary**:
    ```
    [BLACKHOLE] Attack scheduled for 3 nodes from 2.0s to 10.0s
    ```

### BlackholeAttackManager::ScheduleNodeActivation() (line 96707)
18. **Schedule activation event**:
    ```cpp
    Simulator::Schedule(startTime, 
                       &BlackholeAttackManager::ActivateBlackholeNodeInternal, 
                       this, nodeId);
    ```

19. **Schedule deactivation event**:
    ```cpp
    Simulator::Schedule(stopTime, 
                       &BlackholeAttackManager::DeactivateBlackholeOnNode, 
                       this, nodeId);
    ```

### BlackholeAttackManager::ActivateBlackholeNodeInternal() (line 96715)
20. **Mark node as active**:
    ```cpp
    m_blackholeNodes[nodeId].isActive = true;
    m_blackholeNodes[nodeId].attackStartTime = Simulator::Now();
    m_attackActive = true;
    ```

21. **Print activation message**:
    ```
    [BLACKHOLE] Node 5 activated at 2.0s
    [BLACKHOLE] Node 12 activated at 2.0s
    [BLACKHOLE] Node 18 activated at 2.0s
    ```

---

## 4. BLACKHOLE APP INSTALLATION PHASE

### Main Program - BlackholeApp Installation (lines 147334-147344)
22. **Loop through malicious nodes**:
    ```cpp
    for (i = 0; i < blackhole_malicious_nodes.size(); i++) {
        if (blackhole_malicious_nodes[i]) {
            // Install BlackholeApp on this node
        }
    }
    ```

23. **Create BlackholeApp instance**:
    ```cpp
    Ptr<Node> node = NodeList::GetNode(i);
    Ptr<BlackholeApp> app = CreateObject<BlackholeApp>();
    app->SetNodeId(i);
    ```

24. **Install app on node**:
    ```cpp
    node->AddApplication(app);
    ```

25. **Set app timing**:
    ```cpp
    app->SetStartTime(Seconds(blackhole_start_time));  // 2.0s
    app->SetStopTime(Seconds(blackholeStopTime));      // 10.0s
    ```

26. **Configure visualization** (Black color):
    ```cpp
    g_blackholeManager->ConfigureVisualization(anim, 0, 0, 0);
    anim.UpdateNodeColor(nodeId, 0, 0, 0);        // RGB: Black
    anim.UpdateNodeSize(nodeId, 4.0, 4.0);        // Larger size
    anim.UpdateNodeDescription(nodeId, "BLACKHOLE-5");
    ```

---

## 5. APP STARTUP PHASE

### BlackholeApp::StartApplication() (line 144888)
27. **Print startup message**:
    ```
    [BLACKHOLE-APP] Node 5 now dropping ALL packets
    ```

28. **Loop through all network devices**:
    ```cpp
    for (i = 0; i < GetNode()->GetNDevices(); i++) {
        device = GetNode()->GetDevice(i);
    }
    ```

29. **Install packet drop callback**:
    ```cpp
    device->SetReceiveCallback(MakeCallback(&BlackholeApp::DropAllPackets, this));
    ```
    - **CRITICAL:** Intercepts ALL incoming packets at device level
    - Returns `false` = packet consumed (dropped)
    - Returns `true` = packet passed up stack (normal)

---

## 6. FAKE ROUTE ADVERTISEMENT PHASE

### AODV Integration - RREQ Interception (in AODV routing protocol)
30. **When RREQ arrives at blackhole node**:
    - AODV routing protocol receives Route Request
    - Checks if node should generate fake RREP

31. **Query BlackholeAttackManager**:
    ```cpp
    if (g_blackholeManager->ShouldGenerateFakeRREP(nodeId, destination)) {
        GenerateFakeRREP();
    }
    ```

### BlackholeAttackManager::ShouldGenerateFakeRREP() (line 96781)
32. **Check three conditions**:
    ```cpp
    if (!m_advertiseFakeRoutes) return false;  // Feature disabled?
    if (!IsNodeBlackhole(nodeId)) return false; // Not malicious?
    
    RecordFakeRREP(nodeId);  // Update statistics
    return true;             // Yes, generate fake RREP!
    ```

### BlackholeAttackManager::RecordFakeRREP() (line 96806)
33. **Update statistics**:
    ```cpp
    m_blackholeNodes[nodeId].fakeRrepsGenerated++;
    ```

### AODV - Generate Fake RREP (in routing protocol)
34. **Create AODV RREP packet** with fake parameters:
    ```cpp
    rrepHeader.SetDst(requestedDestination);
    rrepHeader.SetDstSeqno(m_fakeSequenceNumber);  // 999999 (very high!)
    rrepHeader.SetHopCount(m_fakeHopCount);        // 1 (very low!)
    rrepHeader.SetLifeTime(MilliSeconds(10000));   // Long lifetime
    ```

35. **Send fake RREP to originator**:
    ```cpp
    SendTo(socket, packet, originator);
    ```
    - Originator receives RREP
    - Thinks blackhole node has excellent route (1 hop, fresh)
    - Updates routing table to route through blackhole

36. **Result of fake RREP**:
    - ✅ Blackhole appears to have best route to destination
    - ✅ Other nodes forward packets to blackhole
    - ✅ Traffic is attracted to the trap

---

## 7. PACKET DROP PHASE (Main Attack)

### BlackholeApp::DropAllPackets() (line 144899)
37. **Callback triggered** for every incoming packet:
    - All packets arriving at any device
    - Both data packets AND routing packets
    - Called BEFORE packet reaches network layer

38. **Notify attack manager**:
    ```cpp
    if (g_blackholeManager) {
        g_blackholeManager->ShouldDropDataPacket(m_nodeId, packet);
    }
    ```

39. **Drop the packet**:
    ```cpp
    return false;  // DON'T pass packet up the stack = DROP
    ```

### BlackholeAttackManager::ShouldDropDataPacket() (line 96763)
40. **Check if should drop data packets**:
    ```cpp
    if (!m_dropDataPackets) return false;   // Feature disabled?
    if (!IsNodeBlackhole(nodeId)) return false; // Not malicious?
    
    RecordPacketDrop(nodeId, true);  // true = data packet
    return true;                      // Yes, drop it!
    ```

### BlackholeAttackManager::RecordPacketDrop() (line 96795)
41. **Update drop statistics**:
    ```cpp
    if (isDataPacket) {
        m_blackholeNodes[nodeId].dataPacketsDropped++;
    } else {
        m_blackholeNodes[nodeId].rrepsDropped++;
    }
    ```

---

## 8. ROUTING PACKET HANDLING PHASE (Optional)

### BlackholeAttackManager::ShouldDropRoutingPacket() (line 96772)
42. **Check if should drop routing packets** (RREP):
    ```cpp
    if (!m_dropRoutingPackets) return false;  // Usually FALSE
    if (!IsNodeBlackhole(nodeId)) return false;
    
    RecordPacketDrop(nodeId, false);  // false = routing packet
    return true;
    ```

43. **Default behavior**:
    - `m_dropRoutingPackets = false` (don't drop routing)
    - Blackhole forwards routing packets normally
    - Only drops DATA packets
    - This makes attack harder to detect!

---

## 9. ATTACK DEACTIVATION PHASE

### BlackholeAttackManager::DeactivateBlackholeOnNode() (line 96737)
44. **Scheduled at stop time** (e.g., 10.0s):
    ```cpp
    Simulator::Schedule(stopTime, &DeactivateBlackholeOnNode, nodeId);
    ```

45. **Mark node as inactive**:
    ```cpp
    m_blackholeNodes[nodeId].isActive = false;
    m_blackholeNodes[nodeId].attackStopTime = Simulator::Now();
    ```

46. **Print deactivation message**:
    ```
    [BLACKHOLE] Node 5 deactivated at 10.0s
    ```

47. **BlackholeApp::StopApplication()** (automatic):
    - ns-3 framework stops application
    - Removes packet drop callbacks
    - Node returns to normal operation

### BlackholeAttackManager::DeactivateAttack() (line 96747)
48. **Deactivate all nodes** (if called):
    ```cpp
    for (auto& pair : m_blackholeNodes) {
        DeactivateBlackholeOnNode(pair.first);
    }
    m_attackActive = false;
    ```

---

## 10. STATISTICS COLLECTION PHASE

### BlackholeAttackManager::GetNodeStatistics() (line 96832)
49. **Retrieve stats for specific node**:
    ```cpp
    auto it = m_blackholeNodes.find(nodeId);
    if (it != m_blackholeNodes.end()) {
        return it->second;  // Return BlackholeStatistics struct
    }
    ```

### BlackholeAttackManager::GetAggregateStatistics() (line 96840)
50. **Aggregate all node statistics**:
    ```cpp
    BlackholeStatistics aggregate;
    
    for (const auto& pair : m_blackholeNodes) {
        const BlackholeStatistics& stats = pair.second;
        aggregate.dataPacketsDropped += stats.dataPacketsDropped;
        aggregate.rrepsDropped += stats.rrepsDropped;
        aggregate.fakeRrepsGenerated += stats.fakeRrepsGenerated;
        aggregate.routesAttracted += stats.routesAttracted;
    }
    
    return aggregate;
    ```

### BlackholeAttackManager::PrintStatistics() (line 96855)
51. **Print comprehensive summary**:
    ```
    ========== BLACKHOLE ATTACK STATISTICS ==========
    Total Blackhole Nodes: 3
    Attack Period: 2.0s to 10.0s
    Attack Status: INACTIVE
    
    AGGREGATE STATISTICS:
      Data Packets Dropped: 245
      RREP Packets Dropped: 0
      Fake RREPs Generated: 18
      Routes Attracted: 12
    
    PER-NODE STATISTICS:
      Node 5:
        Status: INACTIVE
        Data Packets Dropped: 89
        RREP Packets Dropped: 0
        Fake RREPs Generated: 6
        Duration: 8.0s
      Node 12:
        Status: INACTIVE
        Data Packets Dropped: 78
        RREP Packets Dropped: 0
        Fake RREPs Generated: 7
        Duration: 8.0s
      Node 18:
        Status: INACTIVE
        Data Packets Dropped: 78
        RREP Packets Dropped: 0
        Fake RREPs Generated: 5
        Duration: 8.0s
    ================================================
    ```

### BlackholeAttackManager::ExportStatistics() (line 96882)
52. **Export to CSV file**:
    ```cpp
    ofstream outFile("blackhole-attack-results.csv");
    
    outFile << "NodeID,Active,DataPacketsDropped,RREPsDropped,"
            << "FakeRREPsGenerated,RoutesAttracted,StartTime,"
            << "StopTime,Duration\n";
    
    for (const auto& pair : m_blackholeNodes) {
        const BlackholeStatistics& stats = pair.second;
        outFile << stats.nodeId << ","
                << (stats.isActive ? "1" : "0") << ","
                << stats.dataPacketsDropped << ","
                << stats.rrepsDropped << ","
                << stats.fakeRrepsGenerated << ","
                << stats.routesAttracted << ","
                << stats.attackStartTime.GetSeconds() << ","
                << stats.attackStopTime.GetSeconds() << ","
                << (stats.attackStopTime - stats.attackStartTime).GetSeconds()
                << "\n";
    }
    
    outFile.close();
    ```

53. **Print export confirmation**:
    ```
    [BLACKHOLE] Statistics exported to blackhole-attack-results.csv
    ```

---

## KEY DATA STRUCTURES

### BlackholeStatistics (struct) - Line 295
```cpp
struct BlackholeStatistics {
    uint32_t nodeId;                // Node identifier
    uint32_t rrepsDropped;          // Routing packets dropped
    uint32_t dataPacketsDropped;    // Data packets dropped (main metric)
    uint32_t fakeRrepsGenerated;    // Fake RREPs sent
    uint32_t routesAttracted;       // Routes diverted through blackhole
    Time attackStartTime;           // When attack started
    Time attackStopTime;            // When attack stopped
    bool isActive;                  // Current status
};
```

### BlackholeAttackManager Member Variables (lines 354-370)
```cpp
std::vector<bool> m_maliciousNodes;           // Which nodes are malicious
std::map<uint32_t, BlackholeStatistics> m_blackholeNodes;  // Statistics map
uint32_t m_totalNodes;                        // Total node count

// Attack behavior configuration
bool m_dropDataPackets;          // Drop data packets (main behavior)
bool m_dropRoutingPackets;       // Drop RREP packets (optional)
bool m_advertiseFakeRoutes;      // Send fake RREPs to attract traffic
uint32_t m_fakeSequenceNumber;   // Fake high sequence for RREP (999999)
uint8_t m_fakeHopCount;          // Fake low hop count for RREP (1)

Time m_attackStartTime;          // Attack start time
Time m_attackStopTime;           // Attack stop time
bool m_attackActive;             // Is attack currently active?
```

---

## COMPLETE FLOW DIAGRAM

```
1. Main Program
   ↓ (enable_blackhole_attack=true)
2. Create BlackholeAttackManager
   ↓
3. Initialize(maliciousNodes, percentage, totalNodes)
   ↓ (select random nodes)
4. SelectMaliciousNodes(percentage)
   ↓ (mark nodes as malicious)
5. SetBlackholeBehavior(dropData, dropRouting, advertiseFakeRoutes)
   ↓ (configure attack behavior)
6. SetFakeRouteParameters(seqNum=999999, hopCount=1)
   ↓ (configure fake RREP params)
7. ActivateAttack(startTime=2.0s, stopTime=10.0s)
   ↓ (schedule all nodes)
8. For each malicious node:
   → Create BlackholeApp
   → Install on node
   → Set timing
   ↓
9. StartApplication() on each BlackholeApp
   ↓ (install packet drop callbacks)
10. SetReceiveCallback(DropAllPackets)
    ↓ (intercept all packets)
11. Network operation begins
    ↓ (nodes send RREQs)
12. RREQ arrives at blackhole node
    ↓
13. ShouldGenerateFakeRREP()?
    ↓ (yes!)
14. Generate fake RREP:
    - Sequence = 999999 (high)
    - Hop count = 1 (low)
    ↓ (broadcast fake RREP)
15. Originator receives fake RREP
    ↓ (updates routing table)
16. Traffic routed through blackhole
    ↓ (packets arrive at blackhole)
17. DropAllPackets() callback triggered
    ↓
18. ShouldDropDataPacket()?
    ↓ (yes!)
19. RecordPacketDrop(isData=true)
    ↓
20. return false (DROP PACKET)
    ↓ (packet consumed)
21. Packet never reaches destination
    ↓ (black hole!)
22. Repeat for all attracted traffic
    ↓ (until stop time)
23. DeactivateBlackholeOnNode() at 10.0s
    ↓
24. StopApplication()
    ↓
25. GetAggregateStatistics()
    ↓
26. PrintStatistics()
    ↓
27. ExportStatistics("blackhole-attack-results.csv")
```

---

## ATTACK MECHANICS EXPLAINED

### How Traffic is Attracted
1. **High Sequence Number (999999)**:
   - AODV considers higher sequence = fresher route
   - Blackhole claims to have extremely fresh route
   - Other nodes prefer this route

2. **Low Hop Count (1)**:
   - AODV prefers shorter routes
   - Blackhole claims destination is only 1 hop away
   - Appears to be optimal route

3. **Combination Effect**:
   - Fresh + Short = Most attractive route
   - All traffic flows through blackhole
   - Perfect trap!

### Why It's Effective
1. **Device-Level Interception**:
   - Packets dropped BEFORE reaching network layer
   - No routing decisions made
   - No acknowledgments sent
   - Complete packet loss

2. **Selective Dropping**:
   - Can drop only data packets
   - Forward routing packets normally
   - Harder to detect (routing still works)
   - Only data delivery fails

3. **Statistical Evidence**:
   - Tracks every dropped packet
   - Records fake RREPs sent
   - Measures attack duration
   - Quantifies damage

---

## ATTACK SUCCESS METRICS

**Successful blackhole attack shows:**
- ✅ Data packets dropped > 0 (consuming traffic)
- ✅ Fake RREPs generated > 0 (attracting traffic)
- ✅ Routes attracted > 0 (diverting traffic)
- ✅ RREP packets dropped = 0 (if selective dropping)
- ✅ PDR (Packet Delivery Ratio) drops significantly
- ✅ Network throughput decreases
- ✅ End-to-end delay increases (retransmissions)

---

## CODE ENTRY POINTS IN routing.cc

| Component | Line Number | Function |
|-----------|-------------|----------|
| **BlackholeStatistics struct** | 295 | Data structure |
| **BlackholeAttackManager class** | 321 | Class declaration |
| **BlackholeApp class** | 144877 | Application class |
| **Constructor** | 96622 | Manager creation |
| **Initialize** | 96640 | Select malicious nodes |
| **SelectMaliciousNodes** | 96663 | Random selection |
| **SetBlackholeBehavior** | 96673 | Configure behavior |
| **SetFakeRouteParameters** | 96685 | Configure fake RREP |
| **ActivateAttack** | 96694 | Schedule activation |
| **ScheduleNodeActivation** | 96707 | Per-node scheduling |
| **ActivateBlackholeNodeInternal** | 96715 | Activate single node |
| **DeactivateBlackholeOnNode** | 96737 | Deactivate single node |
| **DeactivateAttack** | 96747 | Deactivate all nodes |
| **IsNodeBlackhole** | 96755 | Check node status |
| **ShouldDropDataPacket** | 96763 | Data drop decision |
| **ShouldDropRoutingPacket** | 96772 | Routing drop decision |
| **ShouldGenerateFakeRREP** | 96781 | Fake RREP decision |
| **RecordPacketDrop** | 96795 | Update drop stats |
| **RecordFakeRREP** | 96806 | Update RREP stats |
| **ConfigureVisualization** | 96813 | Visualization setup |
| **GetMaliciousNodeIds** | 96826 | Get malicious list |
| **GetNodeStatistics** | 96832 | Per-node stats |
| **GetAggregateStatistics** | 96840 | Aggregate stats |
| **PrintStatistics** | 96855 | Print summary |
| **ExportStatistics** | 96882 | CSV export |
| **StartApplication** | 144888 | App startup |
| **DropAllPackets** | 144899 | Drop callback |
| **Main integration** | 147295 | Setup in main() |

---

## COMPARISON: BLACKHOLE vs WORMHOLE

| Aspect | Blackhole | Wormhole |
|--------|-----------|----------|
| **Nodes** | Individual malicious nodes | Pairs of distant nodes |
| **Mechanism** | Fake route advertisement | Hidden tunnel |
| **Attraction** | High seq + low hop | Fake 1-hop routes |
| **Behavior** | Drop all packets | Forward through tunnel |
| **Detection** | PDR monitoring | Hop-count + RTT |
| **Complexity** | Simple (single node) | Complex (tunnel + pair) |
| **Impact** | Total packet loss | Route length distortion |

---

## SUMMARY

**Blackhole attack flow in 5 steps:**
1. **Select** malicious nodes (random, percentage-based)
2. **Advertise** fake routes (high seq, low hop) to attract traffic
3. **Install** packet drop callback at device level
4. **Intercept** all incoming packets before network layer
5. **Drop** all data packets (create black hole effect)

**Result:** Legitimate nodes route traffic through blackhole, packets are consumed without delivery, causing complete communication failure for affected routes.

**Key Difference from Wormhole:** Blackhole DROPS packets, Wormhole TUNNELS them. Blackhole is destructive, Wormhole is deceptive.

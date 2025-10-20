# Wormhole Attack Code Flow in routing.cc - Point Form

## Overview
The wormhole attack creates hidden tunnels between distant malicious nodes, making them appear as neighbors and disrupting routing.

---

## 1. INITIALIZATION PHASE

### Main Program Setup (lines ~147200-147250)
1. **User enables wormhole** via command-line parameter:
   - `--enable_wormhole_attack=true`
   - `--wormhole_attack_percentage=0.10` (10% of nodes)

2. **Create WormholeAttackManager**:
   ```cpp
   g_wormholeManager = new WormholeAttackManager();
   ```

3. **Initialize malicious nodes**:
   - Randomly select malicious nodes based on percentage
   - Store in vector `maliciousNodes[i] = true/false`

### WormholeAttackManager::Initialize() (line 96240)
4. **Store malicious node list**:
   - Resize vector to match total nodes
   - Mark malicious nodes: `m_maliciousNodes[i] = true`
   - Random selection using `std::uniform_real_distribution`

5. **Output selected nodes**:
   - Print count: "Total malicious nodes: X"
   - Print IDs: "Malicious nodes: 5, 12, 18..."

---

## 2. TUNNEL CREATION PHASE

### WormholeAttackManager::CreateWormholeTunnels() (line 96260)
6. **Extract malicious node IDs**:
   - Loop through `m_maliciousNodes[]`
   - Build list: `maliciousNodeIds = [5, 12, 18, 23]`

7. **Check minimum requirement**:
   - Need at least 2 malicious nodes for tunnel
   - Return early if < 2 nodes

8. **Pair malicious nodes**:
   - Option A: Sequential pairing (0-1, 2-3, 4-5...)
   - Option B: Random pairing (shuffle first)
   - Default: Random

### WormholeAttackManager::SelectRandomPairs() (line 96295)
9. **Shuffle node IDs**:
   ```cpp
   std::shuffle(maliciousNodeIds.begin(), maliciousNodeIds.end(), randomGen);
   ```

10. **Call sequential pairing**:
    - Pairs shuffled list: [12, 5], [23, 18]

### WormholeAttackManager::SelectSequentialPairs() (line 96288)
11. **Create tunnels for each pair**:
    ```cpp
    for (i = 0; i+1 < size; i += 2) {
        CreateWormholeTunnel(nodeIds[i], nodeIds[i+1]);
    }
    ```

### WormholeAttackManager::CreateWormholeTunnel() (line 96302)
12. **Get node pointers**:
    ```cpp
    nodeA = NodeList::GetNode(nodeIdA);
    nodeB = NodeList::GetNode(nodeIdB);
    ```

13. **Create Point-to-Point link** (hidden tunnel):
    ```cpp
    PointToPointHelper p2p;
    p2p.SetDeviceAttribute("DataRate", "100Mbps");  // High bandwidth
    p2p.SetChannelAttribute("Delay", "1ms");        // Low latency
    tunnelDevices = p2p.Install(nodeA, nodeB);
    ```

14. **Assign IP addresses to tunnel**:
    ```cpp
    Ipv4AddressHelper address;
    address.SetBase("100.0.X.0", "255.255.255.0");  // Private subnet
    tunnelInterfaces = address.Assign(tunnelDevices);
    ```

15. **Store tunnel metadata**:
    ```cpp
    WormholeTunnel tunnel = {
        nodeIdA, nodeIdB,
        endpointA, endpointB,
        tunnelDevices, tunnelInterfaces,
        isActive = false
    };
    m_tunnels.push_back(tunnel);
    ```

16. **Return tunnel ID**:
    - Sequential numbering: 0, 1, 2...

---

## 3. ATTACK ACTIVATION PHASE

### WormholeAttackManager::ActivateAttack() (line 96337)
17. **Schedule activation**:
    ```cpp
    Simulator::Schedule(startTime, &WormholeAttackManager::ActivateAttack);
    ```

18. **Loop through all tunnels**:
    ```cpp
    for (each tunnel in m_tunnels) {
        // Activate tunnel endpoints
    }
    ```

19. **Create WormholeEndpointApp for each node**:
    ```cpp
    Ptr<WormholeEndpointApp> appA = CreateObject<WormholeEndpointApp>();
    Ptr<WormholeEndpointApp> appB = CreateObject<WormholeEndpointApp>();
    ```

20. **Configure endpoints**:
    ```cpp
    appA->SetPeer(nodeB, tunnelInterface_B_Address);
    appA->SetTunnelId(tunnelId);
    appA->SetDropPackets(m_dropPackets);           // Drop or observe?
    appA->SetSelectiveTunneling(routing, data);     // What to tunnel?
    ```

21. **Install apps on nodes**:
    ```cpp
    nodeA->AddApplication(appA);
    nodeB->AddApplication(appB);
    ```

22. **Set start/stop times**:
    ```cpp
    appA->SetStartTime(startTime);
    appA->SetStopTime(stopTime);
    appB->SetStartTime(startTime);
    appB->SetStopTime(stopTime);
    ```

23. **Mark tunnel as active**:
    ```cpp
    tunnel.isActive = true;
    tunnel.appA = appA;
    tunnel.appB = appB;
    ```

---

## 4. ENDPOINT STARTUP PHASE

### WormholeEndpointApp::StartApplication() (line 95694)
24. **Print startup banner**:
    ```
    === WORMHOLE ATTACK STARTING on Node 5 (Tunnel 0) ===
    Peer Node: 12 @ 100.0.0.2
    ```

25. **Create tunnel socket** (UDP, port 9999):
    ```cpp
    m_tunnelSocket = Socket::CreateSocket(GetNode(), UdpSocketFactory);
    m_tunnelSocket->Bind(InetSocketAddress(Any, 9999));
    m_tunnelSocket->SetRecvCallback(&HandleTunneledPacket);
    ```
    - Listens for packets from peer via tunnel

26. **Create AODV injection socket** (UDP, port 654):
    ```cpp
    m_aodvSocket = Socket::CreateSocket(GetNode(), UdpSocketFactory);
    m_aodvSocket->Bind();
    m_aodvSocket->SetAllowBroadcast(true);
    ```
    - Used to send fake AODV messages

27. **Install promiscuous mode** on all devices:
    ```cpp
    for (i = 0; i < GetNode()->GetNDevices(); i++) {
        device = GetNode()->GetDevice(i);
        device->SetPromiscReceiveCallback(&InterceptPacket);
    }
    ```
    - Captures ALL packets passing through node

28. **Send immediate test broadcast**:
    ```cpp
    BroadcastFakeRREP();  // Test that attack works
    ```

29. **Schedule periodic broadcasts**:
    ```cpp
    Simulator::Schedule(Seconds(2.0), &PeriodicBroadcast);
    ```
    - Broadcasts fake routes every 2 seconds

---

## 5. FAKE ROUTE INJECTION PHASE

### WormholeEndpointApp::BroadcastFakeRREP() (line 95951)
30. **Create fake AODV RREP packet**:
    ```cpp
    fakeRREP[0] = 2;              // Type: RREP (Route Reply)
    fakeRREP[4] = 1;              // Hop count = 1 (fake!)
    memcpy(&fakeRREP[5], peerIP, 4);     // Destination = peer
    memcpy(&fakeRREP[9], 999999, 4);     // Sequence = very high (looks fresh)
    memcpy(&fakeRREP[17], 10000, 4);     // Lifetime = long
    ```

31. **Broadcast to all nodes**:
    ```cpp
    m_aodvSocket->SendTo(fakeRREP, InetSocketAddress("255.255.255.255", 654));
    ```
    - Port 654 = AODV routing protocol
    - Claims "I have 1-hop route to peer!"

32. **Update statistics**:
    ```cpp
    m_stats.packetsIntercepted++;
    m_stats.routingPacketsAffected++;
    ```

### WormholeEndpointApp::PeriodicBroadcast() (line 96008)
33. **Repeat every 2 seconds**:
    ```cpp
    BroadcastFakeRREP();
    Simulator::Schedule(Seconds(2.0), &PeriodicBroadcast);
    ```
    - Continuously poisons routing tables

---

## 6. PACKET INTERCEPTION PHASE

### WormholeEndpointApp::InterceptPacket() (line 96018)
34. **Callback triggered** for every packet:
    - Promiscuous mode captures all network traffic
    - Called with: device, packet, protocol, from, to, packetType

35. **Filter protocol**:
    ```cpp
    if (protocol != 0x0800) return false;  // Only IPv4
    ```

36. **Skip tunnel traffic**:
    ```cpp
    if (device->IsPointToPoint()) return false;  // Don't intercept our tunnel
    ```

37. **Parse packet headers**:
    ```cpp
    Ipv4Header ipHeader;
    packet->RemoveHeader(ipHeader);
    srcAddr = ipHeader.GetSource();
    dstAddr = ipHeader.GetDestination();
    ```

38. **Skip own packets**:
    ```cpp
    if (srcAddr == myAddress) return false;  // Don't intercept self
    ```

39. **Check if should tunnel**:
    ```cpp
    if (dstAddr == peerSubnet || routeGoesToPeer()) {
        shouldTunnel = true;
    }
    ```
    - Fake route makes traffic flow through us!

40. **Parse routing packets** (if AODV):
    ```cpp
    if (dstPort == 654) {  // AODV port
        msgType = payload[0];
        if (msgType == 1) {  // RREQ
            InterceptRREQ();
        }
    }
    ```

---

## 7. AODV RREQ INTERCEPTION PHASE

### WormholeEndpointApp::ReceivePacket() (line 95768) - RREQ Handler
41. **Detect RREQ message**:
    ```cpp
    uint8_t msgType = buffer[0];
    if (msgType == 1) {  // Route Request
    ```

42. **Extract originator address**:
    ```cpp
    uint32_t originatorIP;
    memcpy(&originatorIP, &buffer[5], 4);
    Ipv4Address originator(originatorIP);
    ```

43. **Update statistics**:
    ```cpp
    m_stats.packetsIntercepted++;
    m_stats.routingPacketsAffected++;
    ```

44. **Send fake RREP to originator**:
    ```cpp
    SendFakeRREP(originator);
    ```
    - "I have best route to your destination!"

### WormholeEndpointApp::SendFakeRREP() (line 95907)
45. **Create targeted fake RREP**:
    ```cpp
    fakeRREP[0] = 2;           // RREP type
    fakeRREP[4] = 1;           // Hop count = 1
    memcpy(&fakeRREP[5], peerIP, 4);      // Dest = peer
    memcpy(&fakeRREP[13], requesterIP, 4); // Orig = requester
    memcpy(&fakeRREP[17], 10000, 4);      // Long lifetime
    ```

46. **Send unicast to requester**:
    ```cpp
    m_aodvSocket->SendTo(fakeRREP, InetSocketAddress(requester, 654));
    ```

---

## 8. PACKET TUNNELING PHASE

### WormholeEndpointApp::TunnelPacket() (after interception)
47. **Copy intercepted packet**:
    ```cpp
    Ptr<Packet> forwardCopy = packet->Copy();
    ```

48. **Send through tunnel** (P2P link):
    ```cpp
    m_tunnelSocket->SendTo(forwardCopy, 0, 
                          InetSocketAddress(m_peerAddress, 9999));
    ```

49. **Update statistics**:
    ```cpp
    m_stats.packetsTunneled++;
    ```

50. **Decision: Drop or Forward?**
    ```cpp
    if (m_dropPackets) {
        m_stats.packetsDropped++;
        return true;   // Consume packet (drop)
    } else {
        return false;  // Let packet continue (observe-only)
    }
    ```

### WormholeEndpointApp::HandleTunneledPacket() (line ~96100)
51. **Receive from peer** via tunnel:
    ```cpp
    // Callback when packet arrives from peer
    Ptr<Packet> packet = socket->Recv();
    ```

52. **Re-inject into network**:
    ```cpp
    // Send packet into local network
    device->Send(packet, broadcastAddress, protocol);
    ```

53. **Update statistics**:
    ```cpp
    m_stats.packetsReceived++;
    m_stats.dataPacketsAffected++;
    ```

---

## 9. STATISTICS COLLECTION PHASE

### WormholeAttackManager::CollectStatisticsFromApps() (periodic)
54. **Loop through all tunnels**:
    ```cpp
    for (each tunnel) {
        statsA = tunnel.appA->GetStatistics();
        statsB = tunnel.appB->GetStatistics();
        aggregateStats.Add(statsA);
        aggregateStats.Add(statsB);
    }
    ```

55. **Calculate metrics**:
    - Total packets intercepted
    - Total packets tunneled
    - Total packets dropped
    - Routing packets affected
    - Data packets affected

### WormholeAttackManager::PrintStatistics() (end of simulation)
56. **Print summary**:
    ```
    === WORMHOLE ATTACK STATISTICS ===
    Number of Tunnels: 2
    Total Packets Intercepted: 156
    Total Packets Tunneled: 156
    Total Packets Dropped: 0
    Routing Packets Affected: 89
    Data Packets Affected: 67
    ```

### WormholeAttackManager::ExportStatistics() (CSV export)
57. **Write to file**:
    ```cpp
    ofstream file("wormhole-attack-results.csv");
    file << "Metric,Value\n";
    file << "NumberOfTunnels," << tunnelCount << "\n";
    file << "PacketsIntercepted," << total << "\n";
    // ... more metrics
    ```

---

## 10. ATTACK DEACTIVATION PHASE

### WormholeEndpointApp::StopApplication() (at stop time)
58. **Print final stats**:
    ```
    === WORMHOLE STOPPING on Node 5 ===
    Final Stats - Intercepted: 78, Tunneled: 78
    ```

59. **Close sockets**:
    ```cpp
    m_tunnelSocket->Close();
    m_tunnelSocket = nullptr;
    m_aodvSocket->Close();
    m_aodvSocket = nullptr;
    ```

60. **Remove promiscuous callbacks**:
    - Automatically handled by ns-3

---

## KEY DATA STRUCTURES

### WormholeTunnel (struct)
```cpp
struct WormholeTunnel {
    uint32_t nodeIdA, nodeIdB;              // Node IDs
    Ptr<Node> endpointA, endpointB;         // Node pointers
    NetDeviceContainer tunnelDevices;        // P2P devices
    Ipv4InterfaceContainer tunnelInterfaces; // IP addresses
    Ptr<WormholeEndpointApp> appA, appB;    // Attack apps
    bool isActive;                           // Status
}
```

### WormholeStatistics (struct)
```cpp
struct WormholeStatistics {
    uint32_t packetsIntercepted;      // Total caught
    uint32_t packetsTunneled;         // Sent to peer
    uint32_t packetsDropped;          // Dropped
    uint32_t packetsReceived;         // From peer
    uint32_t routingPacketsAffected;  // AODV messages
    uint32_t dataPacketsAffected;     // Data packets
}
```

---

## COMPLETE FLOW DIAGRAM

```
1. Main Program
   ↓ (enable_wormhole_attack=true)
2. Create WormholeAttackManager
   ↓
3. Initialize(maliciousNodes, percentage)
   ↓ (select random nodes)
4. CreateWormholeTunnels()
   ↓ (pair nodes)
5. CreateWormholeTunnel(A, B)
   ↓ (create P2P link)
6. ActivateAttack(startTime)
   ↓ (schedule apps)
7. StartApplication() on Node A & B
   ↓ (install promiscuous mode)
8. BroadcastFakeRREP()
   ↓ (every 2 seconds)
9. Nodes update routing tables
   ↓ (think A & B are 1 hop apart)
10. Traffic flows through A
    ↓ (InterceptPacket callback)
11. InterceptPacket(packet)
    ↓ (check if AODV or Data)
12. If AODV RREQ:
    → SendFakeRREP()
    → TunnelPacket() to peer B
    ↓
13. Peer B receives via HandleTunneledPacket()
    ↓ (re-inject into network)
14. Packet appears at distant location
    ↓ (wormhole successful!)
15. StopApplication() at end
    ↓
16. ExportStatistics()
```

---

## ATTACK SUCCESS METRICS

**Successful wormhole attack shows:**
- ✅ Packets intercepted > 0 (catching traffic)
- ✅ Packets tunneled > 0 (sending to peer)
- ✅ Routing packets affected > 0 (poisoned routes)
- ✅ Data packets affected > 0 (redirected data)
- ✅ Tunnel count = malicious_nodes / 2
- ✅ Fake RREPs broadcast periodically
- ✅ Routes through wormhole have hop count = 1

---

## CODE ENTRY POINTS IN routing.cc

| Component | Line Number | Function |
|-----------|-------------|----------|
| **WormholeEndpointApp class** | 191 | Class declaration |
| **WormholeAttackManager class** | 245 | Class declaration |
| **StartApplication** | 95694 | App startup |
| **InterceptPacket** | 96018 | Packet interception |
| **BroadcastFakeRREP** | 95951 | Route poisoning |
| **HandleTunneledPacket** | ~96100 | Receive from peer |
| **Initialize** | 96240 | Select malicious nodes |
| **CreateWormholeTunnels** | 96260 | Pair nodes |
| **CreateWormholeTunnel** | 96302 | Create P2P link |
| **ActivateAttack** | 96337 | Start attack |
| **Main integration** | ~147200 | Setup in main() |

---

## SUMMARY

**Wormhole attack flow in 5 steps:**
1. **Select** malicious nodes (random, percentage-based)
2. **Pair** them and create hidden P2P tunnels
3. **Inject** fake AODV RREPs claiming 1-hop routes
4. **Intercept** traffic attracted by fake routes
5. **Tunnel** packets to peer, re-inject at distant location

**Result:** Legitimate nodes believe distant nodes are neighbors, routing through wormhole tunnel instead of proper multi-hop paths.

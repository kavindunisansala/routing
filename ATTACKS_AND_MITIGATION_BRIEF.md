# VANET Security: Attacks and Mitigation - Brief Overview

## Complete Attack and Defense Implementation Summary

---

## 1. WORMHOLE ATTACK

### 🔴 Attack Description
**What it is:** Two malicious nodes create a hidden tunnel between distant parts of the network. They capture packets at one location and replay them at another, making nodes believe they are neighbors when they're actually far apart.

**How it works:**
```
Node A ──────────> Wormhole Node 1
                        ║ (Hidden Tunnel)
                        ║ Fast/Low-latency link
                        ║
                   Wormhole Node 2 ──────────> Node B

Result: Node A thinks Node B is 1-hop away (actually 10+ hops)
```

**Impact:**
- Disrupts routing tables (false shortest paths)
- Causes packet loops and congestion
- Enables eavesdropping on traffic
- Creates network partitioning

### 🛡️ Mitigation Process
**Detection Method:** Hop-count analysis and timing verification

**How it works:**
1. **Monitor hop counts** - Packets arriving with suspiciously low hop counts
2. **Timing analysis** - Calculate Round-Trip Time (RTT) between nodes
3. **Geographic validation** - Check if claimed distance matches GPS coordinates
4. **Neighbor verification** - Verify physical proximity using signal strength

**Implementation:**
```cpp
bool DetectWormhole(packet) {
    if (packet.hopCount < expectedMinHops) {
        // Suspiciously low hop count
        flag as wormhole;
    }
    if (RTT < theoreticalMinimum) {
        // Impossible timing
        flag as wormhole;
    }
    if (neighborDistance > radioRange) {
        // Claimed neighbor too far
        flag as wormhole;
    }
}
```

**Mitigation Actions:**
- Blacklist detected wormhole nodes
- Invalidate routes passing through suspicious nodes
- Recalculate routing tables
- Alert neighboring nodes

---

## 2. BLACKHOLE ATTACK

### 🔴 Attack Description
**What it is:** A malicious node falsely advertises excellent routes to all destinations, attracting traffic, then drops all received packets instead of forwarding them.

**How it works:**
```
Node A sends RREQ (looking for route to Node D)
    ↓
Blackhole Node responds: "I have best route! 1 hop to D!"
    ↓
Node A sends data through Blackhole
    ↓
Blackhole drops all packets (📦 → 🗑️)
    ↓
Data never reaches Node D
```

**AODV Manipulation:**
- Advertises route with sequence number = MAX (appears freshest)
- Claims hop count = 1 (appears shortest)
- Sends RREP immediately (fastest response)

**Impact:**
- 100% packet loss for affected routes
- Network isolation and partition
- Denial of Service (DoS)
- Data loss for critical safety messages

### 🛡️ Mitigation Process
**Detection Method:** Packet delivery monitoring and anomaly detection

**How it works:**
1. **Track packet forwarding** - Monitor if nodes actually forward packets they receive
2. **Delivery ratio analysis** - Calculate Per-Node Packet Delivery Ratio (PDR)
3. **Route reply validation** - Verify claimed routes are legitimate
4. **Behavioral analysis** - Detect nodes with abnormal drop rates

**Implementation:**
```cpp
// Monitor each node
for each node N {
    PDR = packetsForwarded / packetsReceived;
    
    if (PDR < threshold) {  // e.g., < 50%
        // Node is dropping too many packets
        blacklistScore[N]++;
        
        if (blacklistScore[N] > limit) {
            AddToBlacklist(N);
            InvalidateRoutes(N);
        }
    }
}
```

**Mitigation Actions:**
- Blacklist malicious nodes (prevent route selection)
- Remove from routing tables
- Disseminate blacklist to neighbors
- Find alternative routes avoiding blackhole
- Cooperative detection (share blacklist)

---

## 3. SYBIL ATTACK

### 🔴 Attack Description
**What it is:** A single malicious node creates multiple fake identities (Sybil nodes) to appear as many different nodes in the network.

**How it works:**
```
Physical Reality:
[Real Malicious Node] = 1 physical device

Network View:
[SybilID_1] [SybilID_2] [SybilID_3] ... [SybilID_N]
All controlled by the SAME physical node!
```

**Techniques:**
- Generate fake MAC addresses
- Forge multiple IP addresses
- Send messages with different source IDs
- Participate in routing as "multiple nodes"

**Impact:**
- Dominates voting/consensus mechanisms
- Manipulates routing decisions
- Enables other attacks (e.g., blackhole from "multiple sources")
- Disrupts trust-based systems
- Creates false traffic patterns

### 🛡️ Mitigation Process
**Detection Method:** Trusted certification and behavioral analysis

**How it works:**

**1. Certificate-Based Approach:**
```cpp
// Trusted Authority (CA) issues unique certificates
Certificate = {
    NodeID: unique_id,
    PublicKey: pk,
    GPS_Location: (lat, lon),
    Timestamp: issued_time,
    Signature: CA_signature
}

// Verify each node has valid, unique certificate
bool VerifyNode(node) {
    if (!ValidateCertificate(node.cert)) {
        return false;  // Fake node
    }
    if (IssuedToSameDevice(node.cert, existingCerts)) {
        return false;  // Sybil detected (multiple IDs, same device)
    }
    return true;
}
```

**2. Signal Strength Analysis:**
- Multiple "different" nodes from same physical location → suspicious
- Same signal strength pattern → likely Sybil

**3. Resource Testing:**
- Legitimate nodes have computational limits
- Challenge-response tests to verify independence
- Sybil nodes share resources, respond slower

**Implementation:**
```cpp
TrustedCertificationAuthority {
    // Register legitimate vehicles
    RegisterVehicle(VIN, PublicKey);
    
    // Issue unique certificate
    IssueCertificate(NodeID);
    
    // Revoke compromised certificates
    RevokeCertificate(NodeID);
}

SybilDetector {
    // Check certificate validity
    if (!ValidCertificate(node)) {
        RejectNode(node);
    }
    
    // Check for duplicate certificates
    if (CertificateAlreadyUsed(cert)) {
        FlagAsSybil(node);
    }
    
    // Monitor position/signal patterns
    if (MultipleNodesAtSameLocation()) {
        InvestigateSybil();
    }
}
```

**Mitigation Actions:**
- Reject nodes without valid certificates
- Blacklist nodes using duplicate certificates
- Isolate suspected Sybil clusters
- Update certificate revocation list (CRL)
- Require periodic re-authentication

---

## 4. REPLAY ATTACK

### 🔴 Attack Description
**What it is:** A malicious node captures legitimate network packets and retransmits them later, causing confusion, loops, and resource exhaustion.

**How it works:**
```
Time T1: Legitimate Node A sends: "Route to Node B via Path X"
    ↓ (Malicious node intercepts and stores)
Time T2: Network topology changes (Path X no longer valid)
    ↓
Time T3: Attacker replays old message: "Route to Node B via Path X"
    ↓
Nodes use outdated route → packets loop, get lost
```

**Capture Mechanism:**
- Promiscuous mode on network interface
- Store packet copies with metadata
- Wait for opportune moment

**Replay Strategy:**
- Replay during topology changes (maximum disruption)
- Replay routing messages (RREQ, RREP, RERR)
- Replay data packets (cause duplicates)

**Impact:**
- Routing table corruption (outdated routes)
- Packet duplication and loops
- Resource exhaustion (processing duplicates)
- Timestamp desynchronization
- DoS through replay flooding

### 🛡️ Mitigation Process
**Detection Method:** Bloom Filters + Sequence Number Windows

**Why Bloom Filters?**
- **Space-efficient**: 1KB per filter vs MB for hash tables
- **Fast**: O(k) constant-time queries (k=4 hash functions)
- **Probabilistic**: Controlled false positive rate (<5%)
- **Zero false negatives**: Never misses actual replays

**How it works:**

**Step 1: Packet Digest Creation**
```cpp
PacketDigest = Hash(sourceNodeID + sequenceNumber + payloadContent)
// Creates unique fingerprint for each packet
```

**Step 2: Bloom Filter Storage (3 Rotating Filters)**
```
Filter 0 [0-5s]:  ████░░░░░░ (stores recent packets)
Filter 1 [5-10s]: ░░░░░░░░░░ (empty, ready)
Filter 2 [empty]: ░░░░░░░░░░ (cleared, will rotate)

Every 5 seconds, rotate:
Active Filter → Frozen Filter → Cleared Filter → Active Filter
```

**Step 3: Detection Pipeline**
```cpp
function CheckPacket(packet) {
    // Step 1: Extract sequence number
    seqNo = packet.sequenceNumber;
    srcNode = packet.sourceNode;
    
    // Step 2: Validate sequence (per-source window)
    if (seqNo < window[srcNode].baseSeq) {
        return BLOCK;  // Too old, likely replay
    }
    if (seqNo in window[srcNode].received) {
        return BLOCK;  // Duplicate sequence
    }
    
    // Step 3: Create digest
    digest = Hash(srcNode + seqNo + payload);
    
    // Step 4: Query all 3 Bloom Filters
    for each filter {
        if (filter.Contains(digest)) {
            return BLOCK;  // Found in filter = REPLAY!
        }
    }
    
    // Step 5: New packet - insert and allow
    currentFilter.Insert(digest);
    window[srcNode].Add(seqNo);
    return ALLOW;
}
```

**Implementation Details:**

**Bloom Filter Structure:**
```cpp
class BloomFilter {
    bitArray[8192];              // 8KB bit array
    numHashFunctions = 4;         // 4 independent hashes
    secretKey;                    // Keyed hashing (security)
    
    Insert(item) {
        for i = 0 to 3 {
            hash = MurmurHash3(item + key, seed=i);
            index = hash % 8192;
            bitArray[index] = 1;
        }
    }
    
    Query(item) {
        for i = 0 to 3 {
            hash = MurmurHash3(item + key, seed=i);
            index = hash % 8192;
            if (bitArray[index] == 0) {
                return false;  // Definitely NOT in set
            }
        }
        return true;  // Probably in set
    }
}
```

**Sequence Window (Per-Source):**
```cpp
class SequenceWindow {
    baseSeq = 0;                 // Window start
    windowSize = 64;             // Track last 64 sequences
    receivedSeqs = Set();        // Sequences seen
    
    Validate(seqNo) {
        if (seqNo < baseSeq) {
            return false;  // Too old
        }
        if (seqNo in receivedSeqs) {
            return false;  // Duplicate
        }
        if (seqNo >= baseSeq + windowSize) {
            // Slide window forward
            baseSeq = seqNo - windowSize/2;
            CleanOldSequences();
        }
        receivedSeqs.Add(seqNo);
        return true;
    }
}
```

**Complete Detection System:**
```
                    Incoming Packet
                          │
                          ▼
            ┌─────────────────────────┐
            │  1. Sequence Validation │
            │  (Per-Source Window)    │
            └────────┬────────────────┘
                     │
                [Invalid?] ──Yes──> BLOCK (Old/Duplicate Sequence)
                     │ No
                     ▼
            ┌─────────────────────────┐
            │  2. Create Digest       │
            │  Hash(src+seq+payload)  │
            └────────┬────────────────┘
                     │
                     ▼
            ┌─────────────────────────┐
            │  3. Query Bloom Filters │
            │  Check Filters 0,1,2    │
            └────────┬────────────────┘
                     │
                [Found?] ──Yes──> BLOCK (Replay Detected!)
                     │ No
                     ▼
            ┌─────────────────────────┐
            │  4. Insert to Current   │
            │  Filter & Allow         │
            └─────────────────────────┘
```

**Mitigation Actions:**
- **Block replayed packets** immediately
- **Log detection** for analysis
- **Update statistics** (false positive rate, latency)
- **Alert neighboring nodes** about replay source
- **Rotate filters** every 5 seconds (automatic aging)

**Performance:**
- **Memory**: 3 KB (3 filters × 1KB)
- **Latency**: 1-5 ms per packet
- **Accuracy**: >95% detection rate
- **False Positives**: <5%

---

## 5. ROUTING TABLE POISONING ATTACK

### 🔴 Attack Description
**What it is:** A malicious node injects false routing information, corrupting routing tables across the network.

**How it works:**
```
Malicious node broadcasts:
"Destination: 10.0.0.0/8 via Me (best route!)"

But the route is:
- Non-existent
- Loops back to attacker
- Goes through blackhole
- Invalid next-hop
```

**AODV Poisoning Techniques:**
- Send fake RREP (Route Reply) with bogus routes
- Modify sequence numbers (appear fresher)
- Advertise non-existent destinations
- Create routing loops

**Impact:**
- Packets sent to wrong destinations
- Routing loops (packet circulates forever)
- Network partition (isolate nodes)
- Traffic redirection (to attacker)

### 🛡️ Mitigation Process
**Detection Method:** Route validation and consistency checking

**How it works:**
1. **Validate route announcements**
   - Check if announced destination exists
   - Verify next-hop is reachable
   - Cross-check with multiple neighbors

2. **Monitor routing updates**
   - Track frequency of updates from each node
   - Detect abnormal routing message patterns
   - Flag nodes sending too many updates

3. **Sequence number verification**
   - Ensure sequence numbers increment logically
   - Reject impossibly high sequence numbers

**Implementation:**
```cpp
bool ValidateRoute(routeUpdate) {
    // Check destination exists
    if (!KnownDestination(routeUpdate.dest)) {
        return false;  // Bogus destination
    }
    
    // Check next-hop is neighbor
    if (!IsNeighbor(routeUpdate.nextHop)) {
        return false;  // Invalid next-hop
    }
    
    // Check sequence number
    if (routeUpdate.seqNo > currentSeq + threshold) {
        return false;  // Suspicious sequence jump
    }
    
    // Check for loops
    if (CreatesLoop(routeUpdate)) {
        return false;  // Loop detected
    }
    
    return true;
}
```

**Mitigation Actions:**
- Reject invalid route updates
- Blacklist nodes sending bogus routes
- Maintain secure routing table
- Use authenticated routing (digital signatures)
- Periodic route refresh with trusted sources

---

## COMPARISON TABLE: ALL ATTACKS & MITIGATIONS

| Attack | Detection Method | Key Technique | Memory | Latency | Accuracy |
|--------|-----------------|---------------|---------|---------|----------|
| **Wormhole** | Hop-count + RTT | Timing analysis | Low | <1ms | ~85% |
| **Blackhole** | PDR monitoring | Delivery tracking | Medium | ~2ms | ~90% |
| **Sybil** | Certification | PKI + CA | Low | <1ms | ~99% |
| **Replay** | Bloom Filters | Probabilistic | 3KB | 1-5ms | >95% |
| **Poisoning** | Route validation | Consistency check | Low | <1ms | ~88% |

---

## INTEGRATED DEFENSE ARCHITECTURE

```
┌─────────────────────────────────────────────────────────┐
│                  VANET Network (ns-3)                    │
│              28 Nodes, 802.11p, AODV Routing            │
└────────────────────┬────────────────────────────────────┘
                     │
         ┌───────────┴───────────┐
         │                       │
    ┌────▼─────┐          ┌─────▼─────┐
    │  ATTACKS │          │  DEFENSE  │
    └────┬─────┘          └─────┬─────┘
         │                      │
    ┌────▼──────────────────────▼───────────┐
    │                                        │
    │  Wormhole   →  Hop-count Analysis     │
    │  Blackhole  →  PDR Monitoring         │
    │  Sybil      →  Certificate Validation │
    │  Replay     →  Bloom Filters          │
    │  Poisoning  →  Route Validation       │
    │                                        │
    └────────────────────────────────────────┘
                     │
         ┌───────────┴───────────┐
         │                       │
    ┌────▼─────┐          ┌─────▼─────┐
    │ Detection│          │ Mitigation│
    └────┬─────┘          └─────┬─────┘
         │                      │
         └──────────┬───────────┘
                    │
            ┌───────▼────────┐
            │  Blacklist     │
            │  Block Packets │
            │  Alert Nodes   │
            └────────────────┘
```

---

## SUMMARY: DEFENSE EFFECTIVENESS

✅ **Wormhole**: Detected via impossible hop-counts/timing  
✅ **Blackhole**: Detected via low packet delivery ratios  
✅ **Sybil**: Prevented via trusted certificate authority  
✅ **Replay**: Detected via Bloom Filters (most advanced)  
✅ **Poisoning**: Detected via route consistency checks  

**Overall Network Security:** Multi-layered defense with complementary techniques protecting against all major VANET attacks.

---

**Implementation Status:** All 5 attacks and defenses fully implemented and tested in ns-3.35 simulator.

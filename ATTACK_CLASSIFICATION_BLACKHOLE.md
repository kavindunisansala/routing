# Blackhole Attack Classification

## Overview
**Attack Type:** Blackhole Attack  
**Category:** Data Plane Attack (Packet Dropping)  
**Severity:** Critical  
**Implementation:** BlackholeAttackManager, SDVNBlackholeAttackApp, SimpleSDVNBlackholeApp  
**Location:** routing.cc lines 659-1000

## Attack Mechanism

### Description
A blackhole attack occurs when a malicious node attracts traffic by advertising favorable routes (low hop count, high sequence numbers) and then drops the attracted packets instead of forwarding them. This creates a "black hole" in the network where packets disappear.

### Attack Behavior

#### Variant 1: Simple Blackhole (SimpleSDVNBlackholeApp)
1. **Packet Interception**: Intercepts all packets passing through node
2. **Selective Dropping**: Drops packets based on drop probability (0.0-1.0)
3. **No Route Advertisement**: Doesn't manipulate routing (passive attack)
4. **Effect**: Only affects traffic naturally routed through malicious node

#### Variant 2: SDVN Blackhole (SDVNBlackholeAttackApp)
1. **Controller Manipulation**: Sends fake metadata to SDVN controller
2. **Advertise as Hub**: Claims to be highly connected node
3. **Attract Traffic**: Controller routes traffic through attacker
4. **Drop Packets**: Drops attracted packets (active attack)
5. **Effect**: Attracts more traffic than simple blackhole

#### Variant 3: AODV Blackhole (Traditional)
1. **RREP Manipulation**: Sends fake Route Reply (RREP) packets
2. **High Sequence Number**: Advertises artificially high sequence numbers
3. **Low Hop Count**: Claims to be very close to destination
4. **Route Attraction**: Becomes preferred next hop
5. **Packet Dropping**: Drops all data packets forwarded to it

### Attack Variants
- **Complete Blackhole**: Drops 100% of packets (drop probability = 1.0)
- **Selective Blackhole**: Drops only certain packets (drop probability < 1.0)
- **Gray Hole**: Drops packets from specific sources or destinations
- **Collaborative Blackhole**: Multiple blackhole nodes coordinate

## Configuration Parameters

### Initialization
```cpp
void Initialize(std::vector<bool>& maliciousNodes, double attackPercentage, uint32_t totalNodes);
```
- `maliciousNodes`: Boolean vector marking malicious nodes
- `attackPercentage`: Percentage of nodes to make malicious (0.0-1.0)
- `totalNodes`: Total number of nodes in network

### Blackhole Behavior (Traditional)
```cpp
void SetBlackholeBehavior(bool dropData, bool dropRouting, bool advertiseFakeRoutes);
```
- `dropData`: Drop data packets (main blackhole behavior)
- `dropRouting`: Drop RREP packets to disrupt routing
- `advertiseFakeRoutes`: Send fake RREPs to attract traffic

### Fake Route Parameters
```cpp
void SetFakeRouteParameters(uint32_t fakeSeqNum, uint8_t fakeHopCount);
```
- `fakeSeqNum`: Artificially high sequence number (e.g., 999999)
- `fakeHopCount`: Artificially low hop count (e.g., 1)

### SDVN Blackhole Behavior
```cpp
void SetAttackMode(bool advertiseAsHub, bool dropPackets, double dropProbability);
```
- `advertiseAsHub`: Advertise fake connectivity to controller
- `dropPackets`: Enable packet dropping
- `dropProbability`: Probability of dropping (0.0-1.0)

### Simple Blackhole Behavior
```cpp
void SetDropProbability(double probability);  // 0.0 = forward all, 1.0 = drop all
void SetDropDataOnly(bool dataOnly);          // Only drop data, forward control
```

## Attack Lifecycle

### Activation
```cpp
void ActivateAttack(Time startTime, Time stopTime);
void ActivateBlackholeOnNode(uint32_t nodeId, Time startTime, Time stopTime);
```
- `startTime`: When to start dropping packets
- `stopTime`: When to stop attack
- `nodeId`: Specific node to activate (per-node control)

### Deactivation
```cpp
void DeactivateAttack();
void DeactivateBlackholeOnNode(uint32_t nodeId);
```

### Attack Control
```cpp
bool IsNodeBlackhole(uint32_t nodeId) const;
bool ShouldDropDataPacket(uint32_t nodeId, Ptr<const Packet> packet);
bool ShouldDropRoutingPacket(uint32_t nodeId, Ptr<const Packet> packet);
bool ShouldGenerateFakeRREP(uint32_t nodeId, Ipv4Address dest);
```

## Statistics Collected

### BlackholeStatistics Structure (Traditional)
```cpp
struct BlackholeStatistics {
    uint32_t nodeId;
    uint32_t dataPacketsIntercepted;
    uint32_t dataPacketsDropped;
    uint32_t routingPacketsIntercepted;
    uint32_t routingPacketsDropped;
    uint32_t fakeRREPsSent;
    Time attackStartTime;
    Time attackStopTime;
    bool isActive;
};
```

### SDVNBlackholeStatistics Structure
```cpp
struct SDVNBlackholeStatistics {
    uint32_t nodeId;
    uint32_t fakeMetadatasSent;      // Fake neighbor ads to controller
    uint32_t packetsIntercepted;     // Data packets intercepted
    uint32_t packetsDropped;         // Data packets dropped
    uint32_t packetsForwarded;       // Data packets forwarded (selective)
    uint32_t attractedFlows;         // Flows routed through this node
    Time attackStartTime;
    Time attackStopTime;
    bool isActive;
};
```

### Available Metrics
- Per-node statistics
- Aggregate statistics across all blackhole nodes
- Packet counts (intercepted, dropped, forwarded)
- Fake route advertisements sent
- Attack duration
- Flows attracted to blackhole

## Detection Methods

### PDR Monitoring
**Principle:** Blackhole nodes have abnormally low Packet Delivery Ratio

**Technique:**
1. Monitor PDR for each node in network
2. Track packets sent via node vs packets successfully delivered
3. Flag nodes with PDR below threshold (e.g., < 50%)
4. Confirm detection with multiple observations

**Thresholds:**
```cpp
double pdrThreshold = 0.5;  // PDR < 50% = suspicious
uint32_t observationWindow = 100;  // packets
```

**Implementation:**
```cpp
void RecordPacketSent(uint32_t srcNode, uint32_t dstNode, uint32_t viaNode, uint32_t packetId);
void RecordPacketReceived(uint32_t srcNode, uint32_t dstNode, uint32_t packetId);
void RecordPacketDropped(uint32_t srcNode, uint32_t dstNode, uint32_t viaNode, uint32_t packetId);
void AnalyzeNodeBehavior(uint32_t nodeId);
```

### Confirmation Packet Scheme
**Principle:** Verify route validity before data transmission

**Technique:**
1. Source sends PREQ to destination
2. Destination receives RREP, sends back confirmation (CREP)
3. Source waits for CREP before sending data
4. If CREP not received, route is suspicious
5. Blackhole nodes can't forge CREPs (lack destination knowledge)

**Advantages:**
- Prevents initial route establishment through blackhole
- Low overhead (only during route discovery)
- No false positives from legitimate packet loss

### Traffic Pattern Analysis
**Principle:** Blackhole nodes show abnormal traffic patterns

**Technique:**
1. Monitor packets received vs packets forwarded per node
2. Normal nodes: forwarded ≈ received (minus local packets)
3. Blackhole nodes: forwarded << received
4. Track forwarding ratio over time

**Detection Formula:**
```cpp
forwardingRatio = packetsForwarded / (packetsReceived - packetsDestinedLocal);
bool isBlackhole = (forwardingRatio < 0.3);  // < 30% forwarding = suspicious
```

### Neighborhood Watch
**Principle:** Neighbors monitor each other's forwarding behavior

**Technique:**
1. Nodes in promiscuous mode listen to neighbors
2. Track if neighbor forwards packets it received
3. Report neighbors that consistently drop packets
4. Collaborative detection with voting

## Mitigation Strategies

### Node Blacklisting
**Strategy:** Exclude detected blackhole nodes from routing

**Implementation:**
```cpp
void BlacklistNode(uint32_t nodeId);
void ExcludeFromRouting(uint32_t nodeId);
bool ShouldExcludeNode(uint32_t nodeId) const;
```

**Steps:**
1. Detect blackhole node using PDR monitoring
2. Add node to blacklist
3. Exclude from routing computation
4. Inform other nodes (network-wide or controller)
5. Recompute routes avoiding blacklisted nodes

### Route Recalculation
**Strategy:** Find alternative routes excluding blackhole nodes

**Steps:**
1. Identify flows affected by blackhole
2. Mark blackhole node as unavailable
3. Trigger route discovery for affected flows
4. Update routing tables with new paths
5. Monitor PDR recovery

### Redundant Routes
**Strategy:** Maintain multiple routes per destination

**Technique:**
1. Discover multiple disjoint paths
2. Split traffic across paths (load balancing)
3. Monitor PDR per path
4. Abandon paths with low PDR
5. Resilient to single blackhole node

### Trust-Based Routing
**Strategy:** Route through trusted nodes only

**Technique:**
1. Maintain trust scores for each node
2. Decrease trust for nodes with low PDR
3. Prefer high-trust nodes during routing
4. Gradual trust recovery for rehabilitated nodes

## Test Script Parameters

### Command-Line Arguments
```bash
--present_blackhole_attack_nodes=20         # Attack percentage (20%, 40%, 60%, 80%, 100%)
--blackhole_drop_data=true                  # Drop data packets
--blackhole_drop_routing=false              # Drop routing packets
--blackhole_advertise_fake_routes=true      # Send fake RREPs
--blackhole_fake_seq_num=999999             # Fake sequence number
--blackhole_fake_hop_count=1                # Fake hop count
```

### SDVN-Specific Parameters
```bash
--sdvn_blackhole_advertise_hub=true         # Advertise as hub to controller
--sdvn_blackhole_drop_probability=1.0       # Drop probability (0.0-1.0)
```

### Detection/Mitigation Flags
```bash
--enable_blackhole_detection=true           # Enable PDR monitoring
--enable_blackhole_mitigation=true          # Enable node blacklisting
--blackhole_pdr_threshold=0.5               # PDR threshold for detection
```

## Expected Impact

### Performance Metrics

#### Without Mitigation
- **Packet Delivery Ratio (PDR):** 40-60% (severe degradation)
  - 20% attack: PDR ≈ 85%
  - 40% attack: PDR ≈ 70%
  - 60% attack: PDR ≈ 55%
  - 80% attack: PDR ≈ 40%
  - 100% attack: PDR ≈ 30%
- **Average Latency:** Increased by 20-40% (route failures, retransmissions)
- **Routing Overhead:** Increased by 50-100% (frequent route discoveries)
- **Throughput:** Reduced by 40-60%

#### With Detection Only
- **Detection Rate:** 90-95%
- **False Positive Rate:** < 5%
- **Detection Latency:** 1-3 seconds (depends on observation window)
- **PDR:** Still degraded (detection doesn't stop drops)

#### With Full Mitigation
- **PDR Recovery:** 90-95% (near-normal levels)
- **Latency Recovery:** Returns to baseline + 10-15% overhead
- **Route Stability:** Improved (blackhole nodes excluded)
- **Throughput Recovery:** 85-90% of normal
- **Detection Accuracy:** 92-97%

### Network Impact
- **Routing Protocol Disruption:** Critical (false routes, dropped packets)
- **Data Plane Impact:** Critical (packet drops)
- **Control Plane Impact:** High (fake route advertisements)
- **Resource Consumption:** Medium (retransmissions, route discoveries)

## Research Notes

### Key Characteristics
1. **Highest Impact:** Among all attacks, blackhole has most severe PDR impact
2. **Easy Detection:** PDR monitoring is simple and effective
3. **Effective Mitigation:** Node blacklisting works well
4. **Scalability Concern:** High attack percentage (80-100%) difficult to mitigate
5. **SDVN Enhancement:** Controller manipulation makes attack more effective

### Validation Criteria
- ✅ PDR degrades linearly with attack percentage
- ✅ Detection rate > 90%
- ✅ Mitigation recovers PDR to > 90%
- ✅ False positive rate < 5%
- ✅ Blackhole nodes successfully excluded from routing
- ✅ Route recalculation triggered appropriately

### Comparison: Simple vs SDVN Blackhole

| Aspect | Simple Blackhole | SDVN Blackhole |
|--------|-----------------|----------------|
| **Route Manipulation** | None | Controller manipulation |
| **Traffic Attraction** | Natural routing only | Active attraction |
| **Impact** | Moderate | High |
| **Detection Difficulty** | Easy | Moderate |
| **Implementation** | Simple | Complex |
| **Effect on PDR** | Moderate drop | Severe drop |

### Limitations
- Confirmation packet scheme adds overhead
- Trust-based routing requires stable network
- Blacklisting reduces network connectivity
- Detection requires observation window (delay)

## References

### Code Locations
- **Manager Class:** routing.cc line 659
- **SDVN Attack App:** routing.cc line 900
- **Simple Attack App:** routing.cc line 796
- **Statistics:** routing.cc lines 633, 796, 873
- **Mitigation Manager:** routing.cc line 963

### Related Files
- `test_sdvn_complete_evaluation.sh`: Comprehensive test suite
- `analyze_attack_results.py`: Analysis script with PDR curves

### Publications
- This implementation supports research on blackhole detection in SDVN and VANET
- Focus on PDR-based detection with low false positive rate
- Novel SDVN controller manipulation variant

---

**Last Updated:** 2024-11-06  
**Implementation Status:** Stable  
**Validation Status:** Validated (comprehensive evaluation completed)

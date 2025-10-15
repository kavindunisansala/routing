# Blackhole Attack Implementation - Complete Guide

## Overview

A **Blackhole Attack** is a serious denial-of-service attack in mobile ad-hoc networks (MANETs) and VANETs where malicious nodes:

1. **Advertise fake routes** with attractive parameters (high sequence numbers, low hop counts)
2. **Attract traffic** by claiming to have the best routes to destinations  
3. **Drop all received packets** creating a "black hole" where data disappears
4. **Disrupt network** by preventing legitimate communication

This implementation provides a realistic, configurable blackhole attack system for ns-3 VANET simulations, following the same architecture as the Wormhole Attack Manager.

## Architecture

### Class Structure

```cpp
class BlackholeAttackManager {
    // Configuration & Lifecycle
    void Initialize(vector<bool>& maliciousNodes, double attackPercentage, uint32_t totalNodes);
    void ActivateAttack(Time startTime, Time stopTime);
    void DeactivateAttack();
    
    // Attack Behavior
    void SetBlackholeBehavior(bool dropData, bool dropRouting, bool advertiseFakeRoutes);
    void SetFakeRouteParameters(uint32_t fakeSeqNum, uint8_t fakeHopCount);
    
    // Packet Interception
    bool ShouldDropDataPacket(uint32_t nodeId, Ptr<const Packet> packet);
    bool ShouldDropRoutingPacket(uint32_t nodeId, Ptr<const Packet> packet);
    bool ShouldGenerateFakeRREP(uint32_t nodeId, Ipv4Address dest);
    
    // Statistics & Reporting
    BlackholeStatistics GetNodeStatistics(uint32_t nodeId);
    BlackholeStatistics GetAggregateStatistics();
    void PrintStatistics();
    void ExportStatistics(string filename);
};
```

### BlackholeStatistics Structure

```cpp
struct BlackholeStatistics {
    uint32_t nodeId;
    uint32_t rrepsDropped;           // RREP packets dropped
    uint32_t dataPacketsDropped;     // Data packets dropped
    uint32_t fakeRrepsGenerated;     // Fake RREPs sent
    uint32_t routesAttracted;        // Routes established through this node
    Time attackStartTime;
    Time attackStopTime;
    bool isActive;
};
```

## Configuration Parameters

### Basic Attack Control

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `enable_blackhole_attack` | bool | false | Enable/disable blackhole attack |
| `blackhole_start_time` | double | 0.0 | When to start attack (seconds) |
| `blackhole_stop_time` | double | 0.0 | When to stop attack (0 = simTime) |
| `blackhole_attack_percentage` | double | 0.15 | Percentage of nodes to compromise (15%) |

### Attack Behavior

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `blackhole_drop_data` | bool | true | Drop data packets (main blackhole behavior) |
| `blackhole_drop_routing` | bool | false | Drop RREP routing packets |
| `blackhole_advertise_fake_routes` | bool | true | Send fake RREPs with high sequence numbers |

### Fake Route Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `blackhole_fake_sequence_number` | uint32_t | 999999 | Fake high sequence number for RREP |
| `blackhole_fake_hop_count` | uint8_t | 1 | Fake low hop count (1 = claim direct route) |

## How It Works

### Phase 1: Initialization

```cpp
// Create blackhole manager
g_blackholeManager = new ns3::BlackholeAttackManager();

// Initialize with malicious nodes
g_blackholeManager->Initialize(blackhole_malicious_nodes, 
                               blackhole_attack_percentage, 
                               actual_node_count);
```

- Randomly selects nodes based on attack percentage (e.g., 15% = 3-4 nodes in 23-node network)
- Initializes statistics tracking for each malicious node
- Stores malicious node list for reference

### Phase 2: Configuration

```cpp
// Set attack behavior
g_blackholeManager->SetBlackholeBehavior(
    true,   // Drop data packets
    false,  // Don't drop routing packets
    true    // Advertise fake routes
);

// Set fake route parameters
g_blackholeManager->SetFakeRouteParameters(
    999999, // High sequence number
    1       // Low hop count
);
```

### Phase 3: Activation

```cpp
// Activate attack from 0s to 10s
g_blackholeManager->ActivateAttack(
    ns3::Seconds(0.0),  // Start time
    ns3::Seconds(10.0)  // Stop time
);
```

- Schedules activation for each malicious node
- Schedules automatic deactivation at stop time
- Prints activation messages with timestamps

### Phase 4: Attack Execution

During the simulation, malicious nodes:

#### A. Advertise Fake Routes (AODV RREP Spoofing)
```cpp
// When a RREQ is received, blackhole node responds with fake RREP
if (g_blackholeManager->ShouldGenerateFakeRREP(nodeId, destination)) {
    // Generate RREP with:
    // - High sequence number (999999) to appear "fresh"
    // - Low hop count (1) to appear "close"
    // - This makes the route very attractive to source nodes
}
```

#### B. Drop Data Packets
```cpp
// When data packet arrives at blackhole node
if (g_blackholeManager->ShouldDropDataPacket(nodeId, packet)) {
    // Drop packet silently
    // Increment dataPacketsDropped counter
    // Packet never reaches destination → communication fails
}
```

#### C. Optionally Drop Routing Packets
```cpp
// When RREP arrives at blackhole node
if (g_blackholeManager->ShouldDropRoutingPacket(nodeId, packet)) {
    // Drop RREP to disrupt route discovery
    // Increment rrepsDropped counter
}
```

### Phase 5: Statistics Collection

```cpp
// At simulation end
g_blackholeManager->PrintStatistics();
g_blackholeManager->ExportStatistics("blackhole-attack-results.csv");
```

## Usage Examples

### Example 1: Basic Blackhole Attack

```bash
./waf --run "routing \
  --enable_blackhole_attack=true \
  --blackhole_attack_percentage=0.2 \
  --blackhole_start_time=0 \
  --blackhole_stop_time=10"
```

**Result:** 
- 20% of nodes become blackhole attackers
- Attack runs from 0s to 10s
- Data packets dropped, fake routes advertised

### Example 2: Aggressive Blackhole (Drop Everything)

```bash
./waf --run "routing \
  --enable_blackhole_attack=true \
  --blackhole_attack_percentage=0.25 \
  --blackhole_drop_data=true \
  --blackhole_drop_routing=true \
  --blackhole_advertise_fake_routes=true"
```

**Result:**
- 25% of nodes compromised
- Drops both data AND routing packets
- Severely disrupts network

### Example 3: Delayed Blackhole Attack

```bash
./waf --run "routing \
  --enable_blackhole_attack=true \
  --blackhole_start_time=5 \
  --blackhole_stop_time=15"
```

**Result:**
- Network operates normally for first 5 seconds
- Blackhole attack starts at 5s
- Attack continues until 15s
- Useful for testing network recovery

### Example 4: Combined with Wormhole

```bash
./waf --run "routing \
  --enable_wormhole_detection=true \
  --enable_wormhole_mitigation=true \
  --enable_blackhole_attack=true \
  --blackhole_attack_percentage=0.15 \
  --attack_percentage=0.2"
```

**Result:**
- Both wormhole and blackhole attacks active
- 20% of nodes for wormhole tunnels
- 15% of nodes for blackhole attack
- Tests detection system under multiple attack types

## Attack Scenarios

### Scenario 1: Stealthy Blackhole
```cpp
blackhole_drop_data = true;
blackhole_drop_routing = false;
blackhole_advertise_fake_routes = true;
blackhole_fake_sequence_number = 100000; // Moderately high
```
- Drops only data packets
- Appears to forward routing packets normally
- Harder to detect

### Scenario 2: Aggressive Blackhole
```cpp
blackhole_drop_data = true;
blackhole_drop_routing = true;
blackhole_advertise_fake_routes = true;
blackhole_fake_sequence_number = 999999; // Very high
```
- Drops everything
- Maximally disruptive
- Easier to detect due to obvious impact

### Scenario 3: Passive Blackhole
```cpp
blackhole_drop_data = true;
blackhole_drop_routing = false;
blackhole_advertise_fake_routes = false;
```
- Only drops data if it receives any
- Doesn't actively attract traffic
- Opportunistic attack

## Output & Statistics

### Console Output (During Initialization)

```
============================================
=== Enhanced Blackhole Attack Configuration ===
Total Nodes (actual): 23
Malicious Nodes Selected: 3
Attack Percentage: 15%
Drop Data Packets: Yes
Drop Routing Packets: No
Advertise Fake Routes: Yes
Fake Sequence Number: 999999
Fake Hop Count: 1
[BLACKHOLE] Attack behavior configured:
  Drop Data Packets: YES
  Drop Routing Packets: NO
  Advertise Fake Routes: YES
[BLACKHOLE] Fake route parameters:
  Sequence Number: 999999
  Hop Count: 1
[BLACKHOLE] Attack scheduled for 3 nodes from 0s to 10s
Configured 3 blackhole nodes
Attack active from 0s to 10s
============================================
```

### Console Output (During Attack)

```
[BLACKHOLE] Node 5 activated at 0s
[BLACKHOLE] Node 12 activated at 0s
[BLACKHOLE] Node 18 activated at 0s
...
[BLACKHOLE] Node 5 deactivated at 10s
[BLACKHOLE] Node 12 deactivated at 10s
[BLACKHOLE] Node 18 deactivated at 10s
```

### Final Statistics

```
========== BLACKHOLE ATTACK STATISTICS ==========
Total Blackhole Nodes: 3
Attack Period: 0s to 10s
Attack Status: INACTIVE

AGGREGATE STATISTICS:
  Data Packets Dropped: 342
  RREP Packets Dropped: 0
  Fake RREPs Generated: 28
  Routes Attracted: 15

PER-NODE STATISTICS:
  Node 5:
    Status: INACTIVE
    Data Packets Dropped: 124
    RREP Packets Dropped: 0
    Fake RREPs Generated: 9
    Duration: 10s
  Node 12:
    Status: INACTIVE
    Data Packets Dropped: 115
    RREP Packets Dropped: 0
    Fake RREPs Generated: 11
    Duration: 10s
  Node 18:
    Status: INACTIVE
    Data Packets Dropped: 103
    RREP Packets Dropped: 0
    Fake RREPs Generated: 8
    Duration: 10s
================================================
```

### CSV Export (blackhole-attack-results.csv)

```csv
NodeID,Active,DataPacketsDropped,RREPsDropped,FakeRREPsGenerated,RoutesAttracted,StartTime,StopTime,Duration
5,0,124,0,9,6,0,10,10
12,0,115,0,11,5,0,10,10
18,0,103,0,8,4,0,10,10
```

## Visualization

Blackhole nodes are visualized with:
- **Color**: Black (RGB: 0, 0, 0)
- **Size**: 4.0 x 4.0 (larger than normal nodes)
- **Label**: "BLACKHOLE-X" (where X is node ID)

This makes them easily identifiable in NetAnim visualizations.

## Impact on Network

### Expected Effects

1. **Packet Loss**: Significant increase in packet loss rate
2. **Throughput Reduction**: Lower overall network throughput
3. **Latency**: Increased average latency (packets retransmitted multiple times)
4. **Route Instability**: Frequent route changes as nodes discover blackholes
5. **Energy Waste**: Nodes waste energy transmitting to blackholes

### Metrics to Measure

- **Packet Delivery Ratio (PDR)**: Should decrease significantly
- **Average End-to-End Delay**: Should increase
- **Routing Overhead**: Should increase (more RREQs due to failed routes)
- **Energy Consumption**: Should increase

## Integration with Detection Systems

The Blackhole Attack Manager can be integrated with detection systems:

```cpp
// Detector can query blackhole status
bool isBlackhole = g_blackholeManager->IsNodeBlackhole(nodeId);

// Get statistics for analysis
BlackholeStatistics stats = g_blackholeManager->GetNodeStatistics(nodeId);

// Check if packet should be dropped (for detection logic)
if (g_blackholeManager->ShouldDropDataPacket(nodeId, packet)) {
    // Detection system can monitor this
}
```

## Comparison with Wormhole Attack

| Feature | Wormhole | Blackhole |
|---------|----------|-----------|
| **Mechanism** | Out-of-band tunnel | Route advertisement |
| **Node Count** | Pairs (2 per tunnel) | Individual nodes |
| **Packet Fate** | Tunneled or dropped | Always dropped |
| **Detection** | Latency-based | PDR/behavior-based |
| **Visibility** | Hidden tunnel | Appears as legitimate node |
| **Impact** | Disrupts routing | Creates denial of service |
| **Complexity** | High (needs tunnel) | Low (just drop packets) |

## Testing & Verification

### Test 1: Verify Blackhole Activation

```bash
./waf --run routing --enable_blackhole_attack=true 2>&1 | grep "\[BLACKHOLE\]"
```

**Expected:** Should see activation messages for blackhole nodes

### Test 2: Verify Packet Dropping

```bash
# Check aggregate statistics
grep "Data Packets Dropped" blackhole-attack-results.csv
```

**Expected:** Should show non-zero packet drops

### Test 3: Verify Fake RREP Generation

```bash
grep "Fake RREPs Generated" blackhole-attack-results.csv
```

**Expected:** Should show fake RREPs were sent

### Test 4: Network Impact

```bash
# Compare PDR with and without blackhole
./waf --run "routing --enable_blackhole_attack=false" > normal.log
./waf --run "routing --enable_blackhole_attack=true" > blackhole.log

# Compare packet delivery ratios
grep "PDR" normal.log
grep "PDR" blackhole.log
```

**Expected:** PDR should be lower with blackhole attack

## Troubleshooting

### Issue: No packets dropped

**Possible Causes:**
1. Blackhole nodes not receiving any traffic
2. Nodes not successfully attracting routes
3. Attack not activated (check timing)

**Solutions:**
- Increase `blackhole_attack_percentage`
- Ensure `blackhole_advertise_fake_routes=true`
- Check activation messages in log

### Issue: Too much disruption

**Possible Causes:**
1. Too many blackhole nodes
2. Aggressive configuration

**Solutions:**
- Reduce `blackhole_attack_percentage`
- Set `blackhole_drop_routing=false`
- Reduce attack duration

### Issue: Attack not visible in statistics

**Possible Causes:**
1. Attack disabled
2. Attack timing outside simulation time
3. Statistics not printed

**Solutions:**
- Verify `enable_blackhole_attack=true`
- Check start_time < simTime
- Ensure cleanup code runs

## Future Enhancements

1. **Collaborative Blackholes**: Multiple blackholes working together
2. **Gray Hole Attack**: Drop only some packets (partial blackhole)
3. **Time-Based Blackhole**: Alternate between normal and blackhole behavior
4. **Selective Blackhole**: Target specific flows or destinations
5. **Detection System**: Implement PDR-based blackhole detection
6. **Mitigation**: Route around detected blackhole nodes

## Summary

The Blackhole Attack implementation provides:

✅ Realistic AODV-based blackhole attack  
✅ Configurable attack behavior  
✅ Comprehensive statistics tracking  
✅ CSV export for analysis  
✅ Visualization support  
✅ Easy command-line configuration  
✅ Integration with existing simulation  

This allows researchers to:
- Study blackhole attack impact on VANETs
- Test detection and mitigation strategies
- Compare different attack configurations
- Analyze network resilience

**The blackhole attack is now ready to use alongside the wormhole attack!** 🎯

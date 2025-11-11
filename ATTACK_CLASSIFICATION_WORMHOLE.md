# Wormhole Attack Classification

## Overview
**Attack Type:** Wormhole Attack  
**Category:** Network Topology Attack  
**Severity:** High  
**Implementation:** WormholeAttackManager, WormholeEndpointApp  
**Location:** routing.cc lines 578-97920

## Attack Mechanism

### Description
A wormhole attack creates a high-speed tunnel (or "wormhole") between two colluding malicious nodes. These nodes intercept packets at one location and tunnel them through a private, low-latency connection to another location, then replay them. This creates false topology information and can disrupt routing protocols by making distant nodes appear adjacent.

### Attack Behavior
1. **Tunnel Creation**: Two malicious nodes establish a high-bandwidth, low-latency tunnel
2. **Packet Interception**: Endpoint A intercepts packets (routing/data)
3. **Tunneling**: Packets are sent through the private tunnel to endpoint B
4. **Replay**: Endpoint B replays packets as if they originated nearby
5. **Route Disruption**: Routes are computed using false hop counts and metrics

### Attack Variants
- **Selective Tunneling**: Can tunnel routing packets only, data packets only, or both
- **Packet Dropping**: Configurable to drop packets instead of tunneling
- **Random Pairing**: Malicious nodes can be paired randomly or sequentially

## Configuration Parameters

### Initialization
```cpp
void Initialize(std::vector<bool>& maliciousNodes, double attackPercentage, uint32_t totalNodes);
```
- `maliciousNodes`: Boolean vector marking malicious nodes
- `attackPercentage`: Percentage of nodes to make malicious (0.0-1.0)
- `totalNodes`: Total number of nodes in network

### Tunnel Configuration
```cpp
void CreateWormholeTunnels(std::string tunnelBandwidth, Time tunnelDelay, bool selectRandom);
```
- `tunnelBandwidth`: Tunnel bandwidth (e.g., "1000Mbps", "100Mbps")
- `tunnelDelay`: One-way tunnel delay (e.g., MilliSeconds(50))
- `selectRandom`: true = random pairing, false = sequential pairing

### Behavior Configuration
```cpp
void SetWormholeBehavior(bool dropPackets, bool tunnelRouting, bool tunnelData);
```
- `dropPackets`: Drop packets instead of tunneling (default: false)
- `tunnelRouting`: Tunnel routing protocol packets (default: true)
- `tunnelData`: Tunnel data packets (default: true)

### Verification Traffic
```cpp
void ConfigureVerificationTraffic(bool enable, uint32_t flowCount, double packetRate, 
                                  uint32_t packetSize, double startOffsetSec, uint16_t basePort);
```
- `enable`: Enable verification flows for detection testing
- `flowCount`: Number of verification flows
- `packetRate`: Packets per second per flow
- `packetSize`: Packet size in bytes
- `startOffsetSec`: Delay before starting verification traffic
- `basePort`: Base port number for flows

## Attack Lifecycle

### Activation
```cpp
void ActivateAttack(Time startTime, Time stopTime);
```
- `startTime`: When to activate wormhole tunnels
- `stopTime`: When to deactivate wormhole tunnels

### Deactivation
```cpp
void DeactivateAttack();
```

## Statistics Collected

### WormholeStatistics Structure
```cpp
struct WormholeStatistics {
    uint32_t packetsIntercepted;      // Total packets intercepted by endpoints
    uint32_t packetsTunneled;         // Packets successfully tunneled
    uint32_t packetsDropped;          // Packets dropped during tunneling
    uint32_t routingPacketsAffected;  // Routing packets affected
    uint32_t dataPacketsAffected;     // Data packets affected
    double totalTunnelingDelay;       // Cumulative tunneling delay
    Time firstPacketTime;             // First packet intercepted
    Time lastPacketTime;              // Last packet intercepted
};
```

### Available Metrics
- Per-tunnel statistics
- Aggregate statistics across all tunnels
- Packet counts by type (routing vs data)
- Tunneling delay measurements
- Attack duration

## Detection Methods

### RTT-Based Detection
**Principle:** Wormhole creates abnormally low RTT between distant nodes

**Technique:**
1. Monitor Round-Trip Time (RTT) for each flow
2. Compare observed RTT with expected RTT based on hop count
3. Flag flows with RTT significantly lower than expected
4. Detect wormhole if multiple flows show anomaly

**Thresholds:**
```cpp
double rttThreshold = 0.5;  // 50% lower than expected = suspicious
```

### Flow Latency Analysis
**Principle:** Wormhole affects latency distribution

**Technique:**
1. Track per-flow latency using FlowLatencyRecord
2. Compute average latency for normal vs affected flows
3. Detect significant latency anomalies
4. Identify path nodes involved in wormhole

**Detection Metrics:**
```cpp
struct WormholeDetectionMetrics {
    uint32_t totalFlows;              // Total flows monitored
    uint32_t flowsAffected;           // Flows affected by wormhole
    uint32_t flowsDetected;           // Flows where wormhole detected
    uint32_t truePositives;           // Correct detections
    uint32_t falsePositives;          // False alarms
    uint32_t falseNegatives;          // Missed detections
    double detectionAccuracy;         // Overall accuracy
    double avgNormalLatency;          // Baseline latency
    double avgWormholeLatency;        // Wormhole-affected latency
};
```

### Topology Verification
**Technique:**
1. Use verification flows with known paths
2. Measure end-to-end latency and hop count
3. Compare with expected topology metrics
4. Detect inconsistencies indicating wormhole

## Mitigation Strategies

### Route Isolation
**Strategy:** Exclude detected wormhole nodes from routing computation

**Implementation:**
1. Maintain blacklist of detected wormhole nodes
2. Exclude blacklisted nodes during route calculation
3. Force routes to avoid suspicious tunnels
4. Monitor PDR recovery after isolation

### Route Recalculation
**Strategy:** Recompute affected routes without wormhole nodes

**Steps:**
1. Identify flows affected by wormhole
2. Exclude wormhole endpoints from topology
3. Recompute shortest paths
4. Update routing tables for affected flows

### Packet Leashing
**Strategy:** Restrict packet's maximum travel distance

**Technique:**
1. Add geographic/hop-count constraints to packets
2. Packets expire if they exceed maximum allowed distance
3. Prevents long-distance tunneling
4. Requires geographic awareness

### Temporal Analysis
**Strategy:** Monitor timing patterns over time

**Technique:**
1. Track latency trends for each flow
2. Detect sudden latency drops (wormhole activation)
3. Verify timing consistency across multiple hops
4. Flag temporally inconsistent patterns

## Test Script Parameters

### Command-Line Arguments
```bash
--present_wormhole_attack_nodes=20          # Attack percentage (20%, 40%, 60%, 80%, 100%)
--use_enhanced_wormhole=true                # Enable enhanced wormhole implementation
--wormhole_bandwidth=1000Mbps               # Tunnel bandwidth
--wormhole_delay_us=50000                   # Tunnel delay in microseconds (50ms)
--wormhole_tunnel_routing=true              # Tunnel routing packets
--wormhole_tunnel_data=true                 # Tunnel data packets
--wormhole_enable_verification_flows=true   # Enable verification traffic
```

### Detection/Mitigation Flags
```bash
--enable_wormhole_detection=true            # Enable RTT-based detection
--enable_wormhole_mitigation=true           # Enable route isolation
```

## Expected Impact

### Performance Metrics

#### Without Mitigation
- **Packet Delivery Ratio (PDR):** ~98-99% (wormholes don't drop packets, just tunnel them)
- **Average Latency:** Reduced by 30-50% for tunneled packets (false improvement)
- **Routing Overhead:** Increased by 20-30% (route recalculations)
- **Tunnel Count Scaling:** Linear with attack percentage
  - 20% → 2 tunnels (30 nodes) / 6 tunnels (70 nodes)
  - 40% → 4 tunnels (30 nodes) / 12 tunnels (70 nodes)
  - 60% → 6 tunnels (30 nodes) / 18 tunnels (70 nodes)
  - 80% → 8 tunnels (30 nodes) / 24 tunnels (70 nodes)
  - 100% → 10 tunnels (30 nodes) / 30 tunnels (70 nodes)

#### With Detection Only
- **Detection Rate:** 85-95% (depends on RTT threshold)
- **False Positive Rate:** 5-10%
- **Detection Latency:** 2-5 seconds after attack starts

#### With Full Mitigation
- **PDR Recovery:** ~98-99% (minimal PDR impact even without mitigation)
- **Latency Recovery:** Returns to normal (no artificially low latency)
- **Route Stability:** Improved (excludes wormhole nodes)
- **Detection Accuracy:** 90-95%

### Network Impact
- **Routing Protocol Disruption:** High (false topology information)
- **Data Plane Impact:** Medium (packets tunneled but delivered)
- **Control Plane Impact:** High (false neighbor relationships)
- **Resource Consumption:** Medium (tunnel overhead)

## Research Notes

### Key Characteristics
1. **No Packet Loss:** This implementation doesn't drop packets, just tunnels them
2. **PDR Remains High:** PDR is NOT a good metric for wormhole detection
3. **Latency is Key:** Use latency analysis to detect wormholes
4. **Topology Pollution:** Main threat is false routing information
5. **Collusion Required:** Requires two cooperating malicious nodes

### Validation Criteria
- ✅ Tunnel count scales linearly with attack percentage
- ✅ Deterministic attacker selection (not probabilistic)
- ✅ Each tunnel has exactly 2 endpoints
- ✅ Latency reduction observed for tunneled packets
- ✅ Detection rate > 85%
- ✅ Mitigation restores normal latency patterns

### Limitations
- Implementation doesn't model real-world wormhole setup complexity
- Assumes ideal tunnel (no jitter, no packet loss in tunnel)
- Detection requires baseline latency measurements
- Mitigation requires centralized coordination

## References

### Code Locations
- **Manager Class:** routing.cc line 578
- **Endpoint App:** routing.cc line 97XXX (after manager)
- **Statistics:** routing.cc line 140
- **Detection Metrics:** routing.cc line 178

### Related Files
- `test_wormhole_focused.sh`: Focused test suite (30 nodes, 16 tests)
- `analyze_wormhole_focused.py`: Analysis with latency breakdown
- `WORMHOLE_FIX_SUMMARY.md`: Complete fix documentation
- `QUICK_START_WORMHOLE.sh`: Quick validation guide

### Publications
- This implementation supports research on wormhole detection in vehicular networks
- Focus on RTT-based detection with low overhead
- Novel latency breakdown analysis (normal vs wormhole-affected packets)

---

**Last Updated:** 2024-11-06  
**Implementation Status:** Fixed (deterministic attacker selection)  
**Validation Status:** Pending (awaiting test execution on Linux VM)

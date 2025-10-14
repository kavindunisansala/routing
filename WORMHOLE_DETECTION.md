# Wormhole Detection and Mitigation System

## Overview
This document describes the latency-based wormhole detection and mitigation system implemented in the VANET routing simulation, based on the research approach from SDN wormhole detection literature.

## Research Foundation

The solution is inspired by: **"Latency-based Wormhole Detection in Software-Defined Networks"**

Key findings from the research:
- Wormhole attacks significantly increase flow latency compared to legitimate paths
- In SDN experiments: wormhole-affected flows showed 2-3x latency increase
- Strategic wormhole placement can affect up to 42.39% of flows (Shentel topology)
- Random placement still impacts minimum 3.40% of flows
- Latency monitoring combined with flow percentage analysis provides effective detection

## Implementation Architecture

### 1. Detection Mechanism

#### Flow Latency Tracking (`FlowLatencyRecord`)
```cpp
struct FlowLatencyRecord {
    Ipv4Address srcAddr;              // Source IP
    Ipv4Address dstAddr;              // Destination IP
    Time firstPacketTime;             // First packet timestamp
    Time lastPacketTime;              // Last packet timestamp
    double totalLatency;              // Cumulative latency
    uint32_t packetCount;             // Number of packets
    double avgLatency;                // Average latency
    bool suspectedWormhole;           // Detection flag
    std::vector<uint32_t> pathNodes;  // Path information
};
```

#### Detection Algorithm
1. **Baseline Calculation**: Calculate average latency from normal flows
2. **Threshold Comparison**: Flag flows exceeding `baseline × threshold_multiplier`
3. **Minimum Sample Size**: Require at least 3 packets before detection
4. **Continuous Monitoring**: Periodic checks every `detection_check_interval` seconds

#### Detection Metrics (`WormholeDetectionMetrics`)
```cpp
struct WormholeDetectionMetrics {
    uint32_t totalFlows;              // Total flows monitored
    uint32_t flowsAffected;           // Flows affected by wormhole
    uint32_t flowsDetected;           // Detected wormhole flows
    uint32_t truePositives;           // Correct detections
    uint32_t falsePositives;          // False alarms
    uint32_t falseNegatives;          // Missed detections
    double detectionAccuracy;         // Accuracy percentage
    double avgNormalLatency;          // Normal flow latency
    double avgWormholeLatency;        // Wormhole flow latency
    double avgLatencyIncrease;        // Percentage increase
    uint32_t routeChanges;            // Mitigation actions
};
```

### 2. Mitigation Strategies

#### Route Invalidation
- Trigger AODV route discovery for affected flows
- Force alternative path selection avoiding wormhole nodes

#### Node Blacklisting
- Maintain blacklist of suspicious nodes
- Prevent route selection through blacklisted nodes

#### Adaptive Threshold
- Adjust detection threshold based on network conditions
- Reduce false positives in high-latency scenarios

## Configuration Parameters

### Command-Line Options

```bash
# Detection Configuration
--enable_wormhole_detection=true        # Enable detection system
--enable_wormhole_mitigation=true       # Enable automatic mitigation
--detection_latency_threshold=2.0       # Latency multiplier (2.0 = 200% of baseline)
--detection_check_interval=1.0          # Seconds between checks

# Wormhole Attack Configuration (for testing)
--use_enhanced_wormhole=true            # Enable wormhole attack
--attack_percentage=20.0                # Percentage of malicious nodes
--wormhole_bandwidth="1000Mbps"         # Tunnel bandwidth
--wormhole_delay_us=1                   # Tunnel delay (microseconds)
```

### Threshold Selection Guidelines

| Threshold | Sensitivity | False Positive Risk | Use Case |
|-----------|-------------|---------------------|----------|
| 1.5x | High | High | Low-latency networks |
| 2.0x | Medium | Medium | General use (recommended) |
| 2.5x | Low | Low | High-latency networks |
| 3.0x | Very Low | Very Low | Highly variable networks |

## Experimental Scenarios

### Scenario 1: Baseline (No Detection)
```bash
./waf --run "routing --use_enhanced_wormhole=true \
                     --attack_percentage=20.0 \
                     --enable_wormhole_detection=false \
                     --simTime=30"
```

**Purpose**: Establish baseline metrics for wormhole attack impact

**Expected Metrics**:
- Packets tunneled through wormhole
- Average latency (if measured)
- Packet delivery ratio
- Flows affected

### Scenario 2: Detection Only
```bash
./waf --run "routing --use_enhanced_wormhole=true \
                     --attack_percentage=20.0 \
                     --enable_wormhole_detection=true \
                     --enable_wormhole_mitigation=false \
                     --detection_latency_threshold=2.0 \
                     --simTime=30"
```

**Purpose**: Measure detection accuracy without mitigation

**Expected Metrics**:
- True positive rate
- False positive rate
- False negative rate
- Detection accuracy
- Time to detect

### Scenario 3: Detection + Mitigation
```bash
./waf --run "routing --use_enhanced_wormhole=true \
                     --attack_percentage=20.0 \
                     --enable_wormhole_detection=true \
                     --enable_wormhole_mitigation=true \
                     --detection_latency_threshold=2.0 \
                     --simTime=30"
```

**Purpose**: Evaluate full system performance with mitigation

**Expected Metrics**:
- Latency reduction after mitigation
- PDR improvement
- Route changes triggered
- Flows protected

### Scenario 4: No Attack (Normal Operation)
```bash
./waf --run "routing --use_enhanced_wormhole=false \
                     --enable_wormhole_detection=true \
                     --simTime=30"
```

**Purpose**: Measure false positive rate in normal conditions

**Expected Metrics**:
- False positive count
- System overhead
- Normal flow latency

## Performance Metrics Comparison

### Key Metrics to Compare

1. **Latency Analysis**
   - Average latency per scenario
   - Latency increase percentage
   - Latency variance

2. **Packet Delivery**
   - Packet Delivery Ratio (PDR)
   - Packets lost
   - Packets affected by wormhole

3. **Detection Effectiveness**
   - Detection accuracy (%)
   - True positive rate
   - False positive rate
   - Time to detect (seconds)

4. **Mitigation Effectiveness**
   - Flows protected
   - Route changes triggered
   - Latency after mitigation
   - PDR after mitigation

### Expected Results Table

| Scenario | Avg Latency | PDR | Flows Affected | Detection Accuracy | Latency Increase |
|----------|-------------|-----|----------------|-------------------|-----------------|
| Baseline (No Attack) | ~X ms | ~Y% | 0% | N/A | 0% |
| Attack Only | ~2-3X ms | ~(Y-Z)% | ~20-40% | N/A | ~100-200% |
| Detection Only | ~2-3X ms | ~(Y-Z)% | ~20-40% | ~90%+ | ~100-200% |
| Detection + Mitigation | ~1.2-1.5X ms | ~(Y-Z/2)% | ~10-20% | ~90%+ | ~20-50% |

*Values depend on network topology and traffic patterns*

## Output Analysis

### Detection Report Format

```
========== WORMHOLE DETECTION REPORT ==========
Detection Status: ENABLED
Mitigation Status: ENABLED
Latency Threshold Multiplier: 2.0x
Baseline Latency: X.XX ms

FLOW STATISTICS:
  Total Flows Monitored: XXX
  Flows Affected by Wormhole: XX
  Flows with Detection: XX
  Percentage of Flows Affected: XX.X%

LATENCY ANALYSIS:
  Average Normal Flow Latency: X.XX ms
  Average Wormhole Flow Latency: XX.XX ms
  Average Latency Increase: XXX.X%

MITIGATION ACTIONS:
  Route Changes Triggered: XX
  Nodes Blacklisted: X
===============================================
```

### CSV Export

Detection results are exported to CSV for analysis:
```
Metric,Value
DetectionEnabled,true
MitigationEnabled,true
LatencyThresholdMultiplier,2.0
BaselineLatency_ms,XX.XX
TotalFlows,XXX
FlowsAffected,XX
FlowsDetected,XX
AffectedPercentage,XX.XX
AvgNormalLatency_ms,XX.XX
AvgWormholeLatency_ms,XX.XX
AvgLatencyIncrease_percent,XXX.XX
RouteChangesTriggered,XX
NodesBlacklisted,X
```

## Implementation Notes

### Current Status
✅ Flow latency tracking implemented
✅ Baseline latency calculation
✅ Threshold-based detection
✅ Detection metrics collection
✅ Node blacklisting mechanism
✅ Route change triggering (placeholder)
⚠️ AODV routing table integration pending
⚠️ Packet send/receive hooks pending

### Integration Requirements

1. **Packet Tagging**: Add unique packet IDs for latency tracking
2. **Send Hooks**: Record packet send times at source
3. **Receive Hooks**: Record packet receive times at destination
4. **AODV Integration**: Access routing tables for actual route invalidation

### Limitations

1. **Detection Delay**: Requires minimum 3 packets per flow
2. **Baseline Accuracy**: Initial detection may have lower accuracy
3. **Route Change**: Placeholder implementation (requires AODV API access)
4. **Overhead**: Continuous flow monitoring adds computational cost

## Future Enhancements

1. **Machine Learning Detection**: Use ML models for pattern recognition
2. **Hop-by-Hop Latency**: Measure per-hop delays for precise localization
3. **Collaborative Detection**: Node cooperation for improved accuracy
4. **Dynamic Thresholds**: Adaptive thresholds based on network conditions
5. **Path Diversity**: Multipath routing to avoid wormholes

## References

1. Research paper: "Latency-based Wormhole Detection in Software-Defined Networks"
   - Mininet 3.3.0d4 with OpenFlow 1.5
   - Internet Topology Zoo networks (Nsfcnet, Neol, Shentel)
   - Gravity model traffic generation
   - Dijkstra's algorithm for strategic placement

2. ns-3 Network Simulator Documentation
   - AODV routing protocol
   - WAVE/VANET modules
   - Packet tagging and tracing

## Contact & Support

For questions or issues:
- Check simulation output logs for detection messages: `[DETECTOR]` prefix
- Review wormhole statistics: `[WORMHOLE]` prefix
- Examine CSV exports for detailed metrics

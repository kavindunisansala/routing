# Replay Attack Implementation with Bloom Filter-Based Mitigation

## Overview

This document describes the comprehensive Replay Attack implementation in the ns-3.35 VANET routing simulator. The implementation follows a research paper approach for in-network replay suppression using Bloom Filters with sequence number windows.

## Architecture

The Replay Attack system consists of three main components:

### 1. **Replay Attack Module**
- **ReplayAttackApp**: Application that captures and replays packets
- **ReplayAttackManager**: Coordinates replay attacks across multiple malicious nodes
- Captures legitimate network packets
- Replays packets at configurable intervals
- Tracks attack statistics

### 2. **Replay Detection Module**
- **ReplayDetector**: Core detection system using Bloom Filters
- **BloomFilter**: Efficient probabilistic data structure for packet digest storage
- **SequenceNumberWindow**: Per-node sequence number validation
- Implements keyed PRF to prevent chosen-insertion attacks
- Periodic Bloom Filter rotation mechanism

### 3. **Replay Mitigation Module**
- **ReplayMitigationManager**: Coordinates detection and blocking
- Integrates with ReplayDetector for real-time mitigation
- Tracks performance metrics
- Exports comprehensive statistics

## Key Features

### Bloom Filter-Based Detection
- **Multiple Hash Functions**: Configurable number of hash functions (default: 4)
- **Rotating Filter Set**: Multiple Bloom filters with periodic rotation (default: 3 filters, 5s rotation)
- **Keyed PRF**: Pseudorandom function with key to prevent chosen-insertion attacks
- **Target False-Positive Rate**: < 5 × 10⁻⁶

### Sequence Number Validation
- **Per-Node Windows**: Maintains sequence number window for each node (default: 64)
- **Reordering Tolerance**: Allows legitimate packet reordering within window
- **Duplicate Detection**: Identifies replayed packets via sequence number tracking

### Performance Metrics
- **Processing Latency**: Average packet processing time in microseconds
- **Throughput**: Packets processed per second
- **False-Positive Rate**: Ratio of legitimate packets incorrectly flagged
- **Detection Accuracy**: Percentage of actual replays detected
- **Memory Footprint**: Bloom filter memory usage

## Configuration Parameters

### Attack Configuration
```
enable_replay_attack=true              # Enable Replay attack
replay_start_time=1.0                  # Attack start time (seconds)
replay_stop_time=0.0                   # Attack stop time (0 = simTime)
replay_attack_percentage=0.10          # Malicious nodes (10%)
replay_interval=1.0                    # Replay interval (seconds)
replay_count_per_node=5                # Replays per node
replay_max_captured_packets=100        # Max captured packets
```

### Detection & Mitigation Configuration
```
enable_replay_detection=true           # Enable detection
enable_replay_mitigation=true          # Enable mitigation
bf_filter_size=8192                    # BF size (bits) = 1KB
bf_num_hash_functions=4                # Number of hash functions
bf_num_filters=3                       # Rotating filters
bf_rotation_interval=5.0               # Rotation interval (seconds)
bf_target_false_positive=0.000005      # Target FP rate: 5 × 10⁻⁶
seqno_window_size=64                   # Sequence window size
```

## Data Structures

### PacketDigest
```cpp
struct PacketDigest {
    uint32_t sourceNodeId;        // Source node ID
    uint32_t destNodeId;          // Destination node ID
    Ipv4Address sourceIp;         // Source IP
    Ipv4Address destIp;           // Destination IP
    uint32_t sequenceNumber;      // Packet sequence number
    uint32_t timestamp;           // Capture timestamp
    std::string payloadHash;      // Payload hash
};
```

### BloomFilterConfig
```cpp
struct BloomFilterConfig {
    uint32_t filterSize;              // Bits (default: 8192 = 1KB)
    uint32_t numHashFunctions;        // Hash count (default: 4)
    uint32_t numFilters;              // Rotating filters (default: 3)
    double rotationInterval;          // Rotation period (default: 5.0s)
    double targetFalsePositiveRate;   // Target FP (default: 5 × 10⁻⁶)
};
```

### ReplayDetectionMetrics
```cpp
struct ReplayDetectionMetrics {
    uint32_t totalPacketsProcessed;   // Total packets checked
    uint32_t replaysDetected;         // Replays detected
    uint32_t replaysBlocked;          // Replays blocked
    uint32_t falsePositives;          // False positives
    uint32_t falseNegatives;          // False negatives
    double falsePositiveRate;         // FP rate
    double detectionAccuracy;         // Accuracy percentage
    uint32_t bloomFilterInsertions;   // BF insertions
    uint32_t bloomFilterQueries;      // BF queries
    uint32_t bloomFilterRotations;    // BF rotations
    double avgProcessingLatency;      // Latency (μs)
    double throughput;                // Packets/sec
};
```

## Implementation Details

### BloomFilter Class
- **Keyed Hash Function**: `KeyedHash(digest, hashIndex)` uses PRF key to prevent attacks
- **Insert Operation**: Sets multiple bits based on hash functions
- **Query Operation**: Checks all bits; returns true if all set
- **Rotation**: Clears oldest filter periodically
- **Fill Ratio Tracking**: Monitors filter saturation

### SequenceNumberWindow Class
- **Sliding Window**: Maintains base sequence number
- **Validation**: Checks if sequence number is within acceptable range
- **Duplicate Detection**: Tracks received sequence numbers
- **Automatic Cleanup**: Removes old sequence numbers when window slides

### ReplayDetector Class
- **Packet Processing**: 
  1. Validate sequence number
  2. Create packet digest
  3. Query all Bloom filters
  4. Record digest if new packet
  5. Track performance metrics

- **Bloom Filter Rotation**:
  - Scheduled every `bf_rotation_interval` seconds
  - Moves to next filter in circular buffer
  - Clears oldest filter
  - Maintains packet history across rotations

### ReplayMitigationManager Class
- **Integration**: Links with ReplayDetector
- **Blocking**: Maintains set of blocked packets (nodeId, seqNo)
- **Performance Monitoring**: Periodic checks every 2 seconds
- **Statistics Export**: Comprehensive CSV reports

## Usage Examples

### Enable Replay Attack
```bash
./waf --run "routing --enable_replay_attack=true \
                     --replay_attack_percentage=0.15 \
                     --replay_interval=0.5 \
                     --replay_count_per_node=10"
```

### Enable Detection with Custom BF Parameters
```bash
./waf --run "routing --enable_replay_detection=true \
                     --enable_replay_mitigation=true \
                     --bf_filter_size=16384 \
                     --bf_num_hash_functions=5 \
                     --bf_num_filters=4 \
                     --bf_rotation_interval=3.0"
```

### Full Replay Attack Simulation
```bash
./waf --run "routing --enable_replay_attack=true \
                     --enable_replay_detection=true \
                     --enable_replay_mitigation=true \
                     --replay_attack_percentage=0.10 \
                     --replay_start_time=1.0 \
                     --replay_interval=1.0 \
                     --bf_filter_size=8192 \
                     --bf_num_hash_functions=4 \
                     --bf_target_false_positive=0.000005 \
                     --simTime=10"
```

## Output Files

### replay-attack-results.csv
```csv
Metric,Value
NumberOfMaliciousNodes,3
TotalPacketsCaptured,150
TotalPacketsReplayed,45
SuccessfulReplays,40
DetectedReplays,5
AttackDuration,9.0
SuccessRate,0.889
DetectionRate,0.111
```

### replay-detection-results.csv
```csv
Metric,Value
TotalPacketsProcessed,1520
ReplaysDetected,45
ReplaysBlocked,45
FalsePositives,0
FalseNegatives,0
FalsePositiveRate,0.0
DetectionAccuracy,1.0
BloomFilterInsertions,1475
BloomFilterQueries,1520
BloomFilterRotations,2
AvgProcessingLatency,12.5
Throughput,152.0
Filter0FillRatio,0.234
Filter0Insertions,500
Filter1FillRatio,0.189
Filter1Insertions,475
Filter2FillRatio,0.156
Filter2Insertions,500
```

### replay-mitigation-results.csv
```csv
Metric,Value
TotalPacketsProcessed,1520
TotalReplaysBlocked,45
UniqueBlockedPackets,45
FalsePositiveRate,0.0
DetectionAccuracy,1.0
AvgProcessingLatency,12.5
Throughput,152.0
```

## Performance Targets

Based on research paper specifications:

| Metric | Target | Implementation |
|--------|--------|----------------|
| False-Positive Rate | < 5 × 10⁻⁶ | Bloom Filter with optimal parameters |
| Throughput (iMIX) | Line-rate | Efficient hash functions, minimal overhead |
| Throughput (min packets) | ~25% drop acceptable | Bloom Filter size optimization |
| Latency Overhead | 2x worst-case | Fast BF queries, cached operations |
| Memory Footprint | Cache-optimized | Blocked BF structure, compact storage |

## Bloom Filter Optimization

### Filter Size Calculation
```
m = -n * ln(p) / (ln(2)^2)
where:
  m = filter size (bits)
  n = expected elements
  p = target false-positive rate
  
Example: n=1000, p=5×10⁻⁶
  m ≈ 28,755 bits ≈ 3.6 KB
```

### Optimal Hash Functions
```
k = (m/n) * ln(2)
where:
  k = number of hash functions
  m = filter size
  n = expected elements
  
Example: m=8192, n=1000
  k ≈ 5.7 ≈ 6 hash functions
```

## Integration with AODV Routing

The Replay Attack system integrates with AODV routing protocol:

1. **Packet Capture**: Malicious nodes capture routing and data packets
2. **Packet Replay**: Replay captured packets to disrupt routing
3. **Detection**: ReplayDetector validates all packets before processing
4. **Mitigation**: Blocks replayed packets from entering routing protocol

## Security Considerations

### Keyed PRF
- Prevents attackers from pre-computing hash values
- Random key generated at initialization
- Makes chosen-insertion attacks infeasible

### Sequence Number Windows
- Prevents simple replay attacks
- Tolerates legitimate packet reordering
- Per-node windows isolate attack impact

### Bloom Filter Rotation
- Limits time window for replay attacks
- Prevents filter saturation
- Maintains recent packet history

## Testing and Validation

### False-Positive Rate Validation
1. Run simulation without attack: `enable_replay_attack=false`
2. Check FP rate in CSV: Should be < 5 × 10⁻⁶
3. Verify no legitimate packets blocked

### Detection Accuracy Validation
1. Run simulation with attack: `enable_replay_attack=true`
2. Check detection rate in CSV
3. Verify all replays detected: `DetectedReplays == TotalPacketsReplayed`

### Performance Validation
1. Monitor `avgProcessingLatency` < 50 μs
2. Check `throughput` meets requirements
3. Verify Bloom Filter fill ratios < 0.5

## Troubleshooting

### High False-Positive Rate
- Increase `bf_filter_size`
- Increase `bf_num_hash_functions`
- Decrease `bf_rotation_interval`

### Low Detection Rate
- Check sequence number window size
- Verify Bloom Filter rotation is working
- Increase `bf_num_filters`

### High Latency
- Decrease `bf_num_hash_functions`
- Optimize filter size
- Check for filter saturation

## References

Research paper approach:
- Per-interval sequence numbers with per-AS windows
- Bloom Filter-based packet digest storage
- Periodic BF rotation mechanism
- Keyed PRF for chosen-insertion attack prevention
- Target: False-positive rate < 5 × 10⁻⁶

## Code Structure

```
routing.cc
├── Forward Declarations (lines 87-106)
│   ├── struct PacketDigest
│   ├── struct ReplayStatistics
│   ├── struct ReplayDetectionMetrics
│   ├── struct BloomFilterConfig
│   ├── class BloomFilter
│   ├── class SequenceNumberWindow
│   ├── class ReplayAttackApp
│   ├── class ReplayAttackManager
│   ├── class ReplayDetector
│   └── class ReplayMitigationManager
│
├── Class Declarations (lines 1055-1341)
│   ├── PacketDigest struct
│   ├── ReplayStatistics struct
│   ├── ReplayDetectionMetrics struct
│   ├── BloomFilterConfig struct
│   ├── BloomFilter class
│   ├── SequenceNumberWindow class
│   ├── ReplayAttackApp class
│   ├── ReplayAttackManager class
│   ├── ReplayDetector class
│   └── ReplayMitigationManager class
│
├── Implementation (lines 99104-100132)
│   ├── BloomFilter methods
│   ├── SequenceNumberWindow methods
│   ├── ReplayAttackApp methods
│   ├── ReplayAttackManager methods
│   ├── ReplayDetector methods
│   └── ReplayMitigationManager methods
│
├── Global Variables (lines 1541-1549)
│   ├── g_replayAttackManager
│   ├── g_replayDetector
│   └── g_replayMitigationManager
│
├── Configuration (lines 1477-1492)
│   ├── Attack parameters
│   └── Detection parameters
│
├── Command-Line Args (lines 145141-145158)
│   └── cmd.AddValue() for all parameters
│
├── Main Integration (lines 147396-147445)
│   ├── Attack initialization
│   ├── Detector initialization
│   ├── Mitigation manager setup
│   ├── BF rotation scheduling
│   └── Performance check scheduling
│
└── Cleanup & Export (lines 147572-147603)
    ├── Statistics printing
    ├── CSV export
    └── Memory cleanup
```

## Future Enhancements

1. **Adaptive Bloom Filter Sizing**: Dynamically adjust filter size based on traffic
2. **Machine Learning Integration**: Train ML model on replay patterns
3. **Distributed Detection**: Coordinate detection across multiple nodes
4. **Enhanced Metrics**: Add more detailed performance breakdowns
5. **Visualization**: Real-time BF fill ratio graphs
6. **Attack Variants**: Implement delayed replay, selective replay

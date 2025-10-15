# Blackhole Attack Mitigation System

## Overview
This implementation provides a **PDR-based (Packet Delivery Ratio) blackhole mitigation system** inspired by the Confirmation Packet Scheme. The system detects and blacklists nodes with suspiciously low packet delivery rates.

## Key Concepts Implemented

### 1. **Packet Delivery Monitoring**
- Tracks all packets sent through each node
- Monitors successful deliveries vs. timeouts
- Calculates per-node PDR (Packet Delivery Ratio)

### 2. **Threshold-Based Detection**
- Default PDR threshold: **50%** (configurable)
- Minimum sample size: **10 packets** before blacklisting
- Avoids false positives from temporary network issues

### 3. **Automatic Blacklisting**
- Nodes with PDR < threshold are automatically blacklisted
- Blacklisted nodes are logged with timestamp
- Statistics track per-node and aggregate metrics

### 4. **Real-time Monitoring**
- Continuous tracking during simulation
- 2-second timeout for packet delivery confirmation
- Immediate blacklisting when threshold is exceeded

## Configuration Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `enable_blackhole_mitigation` | false | Enable/disable mitigation system |
| `blackhole_pdr_threshold` | 0.5 | PDR threshold for blacklisting (50%) |
| `blackhole_min_packets` | 10 | Minimum packets before blacklisting |

## Usage Examples

### Basic Usage (Mitigation Only)
```bash
./waf --run "routing --enable_blackhole_mitigation=true"
```

### With Blackhole Attack + Mitigation
```bash
./waf --run "routing \
  --enable_blackhole_attack=true \
  --enable_blackhole_mitigation=true \
  --blackhole_attack_percentage=0.2"
```

### Custom PDR Threshold
```bash
./waf --run "routing \
  --enable_blackhole_attack=true \
  --enable_blackhole_mitigation=true \
  --blackhole_pdr_threshold=0.3"  # 30% threshold
```

### Full Configuration
```bash
./waf --run "routing \
  --enable_blackhole_attack=true \
  --blackhole_attack_percentage=0.15 \
  --blackhole_start_time=2.0 \
  --blackhole_stop_time=8.0 \
  --enable_blackhole_mitigation=true \
  --blackhole_pdr_threshold=0.4 \
  --simTime=10"
```

## Output Files

### 1. Console Output
The system prints real-time detection messages:
```
[MITIGATION] ⚠️  Node 29 BLACKLISTED at 3.45s (PDR: 12.5%, 105/120 dropped)
```

### 2. Statistics Summary
At simulation end, prints:
```
========== BLACKHOLE MITIGATION STATISTICS ==========
Mitigation Status: ACTIVE
PDR Threshold: 50%

OVERALL STATISTICS:
  Total Packets Sent: 1250
  Total Packets Delivered: 890
  Total Packets Dropped: 360
  Overall PDR: 71.2%
  Blacklisted Nodes: 3

BLACKLISTED NODES:
  Node 29:
    Packets via this node: 320
    Delivered: 28
    Dropped: 292
    PDR: 8.75%
    Blacklisted at: 3.45s
```

### 3. CSV Export
File: `blackhole-mitigation-results.csv`
```csv
NodeID,PacketsSentVia,PacketsDelivered,PacketsDropped,PDR,Blacklisted,BlacklistTime
10,45,44,1,97.78,0,0
15,67,65,2,97.01,0,0
29,320,28,292,8.75,1,3.45
```

## How It Works

### Detection Algorithm

1. **Packet Tracking**:
   ```
   When packet sent via node N:
     - Record: packetId, nextHop=N, timestamp
     - Start 2-second timeout timer
   ```

2. **Delivery Confirmation**:
   ```
   When packet received at destination:
     - Mark packet as delivered
     - Update node N's delivery counter
     - Calculate new PDR for node N
   ```

3. **Timeout Handling**:
   ```
   If packet not received within 2 seconds:
     - Mark as dropped
     - Update node N's drop counter
     - Recalculate PDR
     - Check if PDR < threshold
   ```

4. **Blacklisting**:
   ```
   If (PDR < threshold) AND (packets ≥ minimum):
     - Mark node as blacklisted
     - Log blacklist event
     - Node is avoided in future routing (planned)
   ```

## Comparison with Original Paper

| Feature | Paper Scheme | Our Implementation |
|---------|-------------|-------------------|
| **Detection Method** | Confirmation packets | PDR monitoring |
| **First Packet Test** | ✓ Explicit | ✓ Implicit (timeout) |
| **Threshold Time** | Calculated from hops | Fixed 2 seconds |
| **Second Chance** | ✓ White_Pkt mechanism | ✗ Simplified |
| **False Positive Handling** | Two-stage verification | Minimum sample size |
| **Broadcast Alerts** | ✓ Black_Pkt to all nodes | ✗ Local detection |
| **Route Avoidance** | ✓ Immediate | ⚠️  Planned |

## Integration with Blackhole Attack

The mitigation system is **independent** but **complementary** to the attack system:

- **Attack System**: Creates malicious blackhole nodes that drop packets
- **Mitigation System**: Detects and identifies these malicious nodes

Run both together to evaluate:
- **Detection Accuracy**: How many blackhole nodes are caught?
- **Detection Time**: How quickly are they identified?
- **False Positives**: Are legitimate nodes blacklisted?
- **Network Impact**: Does mitigation improve PDR?

## Expected Results

With attack **enabled** and mitigation **disabled**:
```
Overall PDR: ~40-60% (many packets dropped by blackholes)
Blacklisted Nodes: 0 (no detection)
```

With attack **enabled** and mitigation **enabled**:
```
Overall PDR: ~60-80% (improves as blackholes detected)
Blacklisted Nodes: 3-4 (matches number of blackhole nodes)
Detection Time: 1-4 seconds per node
```

## Performance Metrics

### Key Metrics to Evaluate:

1. **Detection Rate**: `Blacklisted Nodes / Actual Blackhole Nodes`
2. **False Positive Rate**: `Innocent Nodes Blacklisted / Total Innocent Nodes`
3. **Detection Time**: Average time to blacklist a malicious node
4. **PDR Improvement**: PDR with mitigation vs. without
5. **End-to-End Delay**: Impact of mitigation on latency

## Limitations & Future Work

### Current Limitations:
1. **No Route Avoidance**: Blacklisted nodes are detected but not avoided in routing
2. **No Second Chance**: Paper's white-list mechanism not implemented
3. **No Broadcast Alerts**: Detection is local, not shared network-wide
4. **Fixed Timeout**: 2-second timeout may not suit all network conditions

### Planned Enhancements:
1. Integrate with AODV routing to actually avoid blacklisted nodes
2. Add second-chance mechanism with temporary blacklisting
3. Implement network-wide alert broadcasting
4. Adaptive timeout based on network conditions
5. Integration with wormhole detection for combined security

## Troubleshooting

### Issue: No nodes being blacklisted
**Cause**: PDR threshold too low or minimum packets not reached
**Solution**: 
```bash
--blackhole_pdr_threshold=0.7  # Increase threshold to 70%
```

### Issue: Too many false positives
**Cause**: Network congestion or threshold too high
**Solution**:
```bash
--blackhole_pdr_threshold=0.3  # Lower threshold to 30%
--blackhole_min_packets=20     # Require more samples
```

### Issue: Late detection
**Cause**: Minimum packet requirement too high
**Solution**:
```bash
--blackhole_min_packets=5  # Reduce minimum to detect faster
```

## Testing Scenarios

### Scenario 1: Basic Detection Test
```bash
./waf --run "routing \
  --enable_blackhole_attack=true \
  --blackhole_attack_percentage=0.2 \
  --enable_blackhole_mitigation=true \
  --simTime=10" > test_basic.log
```
**Expected**: 4-5 nodes blacklisted within 3-4 seconds

### Scenario 2: Strict Detection
```bash
./waf --run "routing \
  --enable_blackhole_attack=true \
  --enable_blackhole_mitigation=true \
  --blackhole_pdr_threshold=0.7" > test_strict.log
```
**Expected**: Faster detection, possible false positives

### Scenario 3: Conservative Detection
```bash
./waf --run "routing \
  --enable_blackhole_attack=true \
  --enable_blackhole_mitigation=true \
  --blackhole_pdr_threshold=0.3 \
  --blackhole_min_packets=20" > test_conservative.log
```
**Expected**: Slower but more accurate detection

## Code Structure

### Class: `BlackholeMitigationManager`

**Key Methods**:
- `Initialize()`: Set up monitoring for all nodes
- `RecordPacketSent()`: Track packet sent via node
- `RecordPacketReceived()`: Confirm successful delivery
- `RecordPacketTimeout()`: Handle delivery failure
- `CheckAndBlacklistNode()`: Evaluate and blacklist if needed
- `PrintStatistics()`: Display detection results
- `ExportStatistics()`: Save results to CSV

**Data Structures**:
- `NodeStatistics`: Per-node PDR tracking
- `FlowRecord`: Individual packet tracking
- Global counters for aggregate statistics

## References

This implementation is inspired by:
> "Confirmation Packet Scheme for Blackhole Attack Mitigation in AODV"
> - Key Ideas: First packet verification, threshold-based detection, blacklisting
> - Simplified for practical ns-3 implementation

## Support

For issues or questions:
1. Check console output for `[MITIGATION]` log messages
2. Verify CSV files are generated
3. Ensure both attack and mitigation are enabled for testing
4. Check PDR threshold matches your network conditions

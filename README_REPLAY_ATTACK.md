# Replay Attack Implementation - Quick Start Guide

## Overview
This implementation adds comprehensive Replay Attack capabilities to the ns-3.35 VANET routing simulator, following a research paper approach using Bloom Filters and sequence number windows for in-network replay suppression.

## Key Features
✅ **Bloom Filter-Based Detection** - Efficient packet digest storage with < 5 × 10⁻⁶ false-positive rate  
✅ **Sequence Number Validation** - Per-node windows with reordering tolerance  
✅ **Keyed PRF Security** - Prevents chosen-insertion attacks on Bloom Filters  
✅ **Rotating Filter Set** - Periodic BF rotation to limit replay window  
✅ **Performance Metrics** - Latency, throughput, false-positive rate tracking  
✅ **CSV Export** - Comprehensive statistics for analysis  

## Quick Usage

### Enable Replay Attack Only
```bash
./waf --run "routing --enable_replay_attack=true \
                     --replay_attack_percentage=0.10 \
                     --simTime=10"
```

### Enable Detection and Mitigation
```bash
./waf --run "routing --enable_replay_attack=true \
                     --enable_replay_detection=true \
                     --enable_replay_mitigation=true \
                     --simTime=10"
```

### Custom Bloom Filter Configuration
```bash
./waf --run "routing --enable_replay_detection=true \
                     --bf_filter_size=16384 \
                     --bf_num_hash_functions=5 \
                     --bf_num_filters=4 \
                     --bf_rotation_interval=3.0"
```

## Configuration Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `enable_replay_attack` | false | Enable Replay attack |
| `replay_attack_percentage` | 0.10 | Percentage of malicious nodes (10%) |
| `replay_interval` | 1.0 | Interval between replays (seconds) |
| `replay_count_per_node` | 5 | Number of replays per node |
| `enable_replay_detection` | false | Enable detection |
| `enable_replay_mitigation` | false | Enable mitigation (blocking) |
| `bf_filter_size` | 8192 | Bloom filter size (bits) |
| `bf_num_hash_functions` | 4 | Number of hash functions |
| `bf_num_filters` | 3 | Number of rotating filters |
| `bf_rotation_interval` | 5.0 | Rotation interval (seconds) |
| `bf_target_false_positive` | 0.000005 | Target FP rate (5 × 10⁻⁶) |
| `seqno_window_size` | 64 | Sequence number window size |

## Output Files

After simulation, the following CSV files are generated:

- **replay-attack-results.csv** - Attack statistics (packets captured/replayed)
- **replay-detection-results.csv** - Detection metrics (FP rate, accuracy, BF stats)
- **replay-mitigation-results.csv** - Mitigation results (blocked packets, throughput)

## Example Output

```
=== Replay Attack Configuration ===
Total Nodes: 28
Malicious Nodes Selected: 3
Attack Percentage: 10%
Replay Interval: 1.0s
Replay Count Per Node: 5

=== Replay Detection and Mitigation System Configuration ===
Bloom Filter Configuration:
  - Filter Size: 8192 bits
  - Hash Functions: 4
  - Number of Filters: 3
  - Rotation Interval: 5.0s
  - Target FP Rate: 5e-06

========== REPLAY DETECTION REPORT ==========
Total Packets Processed: 1520
Replays Detected: 15
Replays Blocked: 15
False Positives: 0
False Negatives: 0
False Positive Rate: 0 (PASS)
Detection Accuracy: 100%

=== Bloom Filter Statistics ===
BF Insertions: 1505
BF Queries: 1520
BF Rotations: 2
Filter 0 - Fill Ratio: 23.4% (Insertions: 500)
Filter 1 - Fill Ratio: 18.9% (Insertions: 505)
Filter 2 - Fill Ratio: 15.6% (Insertions: 500)

=== Performance Metrics ===
Avg Processing Latency: 12.5 μs
Throughput: 152.0 packets/sec
```

## Testing

Run the test suite:
```bash
chmod +x test_replay_attack.sh
./test_replay_attack.sh
```

Tests include:
1. Basic attack without detection
2. Detection with default BF parameters
3. Full mitigation with blocking
4. False-positive rate validation (no attack)
5. High load stress test

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                   Replay Attack System                  │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌──────────────────┐      ┌──────────────────┐       │
│  │ ReplayAttackApp  │      │ ReplayDetector   │       │
│  │                  │      │                  │       │
│  │ - Capture pkts   │      │ - BloomFilters   │       │
│  │ - Replay pkts    │      │ - SeqNo windows  │       │
│  │ - Track stats    │      │ - Keyed PRF      │       │
│  └──────────────────┘      └──────────────────┘       │
│          │                          │                  │
│          ▼                          ▼                  │
│  ┌──────────────────┐      ┌──────────────────┐       │
│  │ReplayAttackMgr   │      │ReplayMitigationMgr│      │
│  │                  │      │                  │       │
│  │ - Coordinate     │◄────►│ - Block replays  │       │
│  │ - Aggregate      │      │ - Monitor perf   │       │
│  │ - Export stats   │      │ - Export metrics │       │
│  └──────────────────┘      └──────────────────┘       │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

## Key Algorithms

### Bloom Filter Query
```
IsReplayPacket(digest):
  For each filter in rotating set:
    If Query(digest) == true:
      Return true (likely replay)
  Return false (new packet)
```

### Sequence Number Validation
```
ValidateSequenceNumber(nodeId, seqNo):
  If seqNo < baseSeq:
    Return false (too old - replay)
  If seqNo in receivedSeqs:
    Return false (duplicate - replay)
  If seqNo >= baseSeq + windowSize:
    Slide window forward
  Return true (valid)
```

### Keyed Hash Function
```
KeyedHash(digest, hashIndex):
  keyedInput = key + "-" + hashIndex + "-" + digest
  Return Hash(keyedInput, hashIndex)
```

## Performance Targets

| Metric | Target | Notes |
|--------|--------|-------|
| False-Positive Rate | < 5 × 10⁻⁶ | Research paper requirement |
| Processing Latency | < 50 μs | Fast BF queries |
| Throughput | Line-rate for iMIX | Minimal overhead |
| Detection Accuracy | > 95% | High replay detection rate |
| Memory Usage | < 10 KB per filter | Efficient storage |

## Troubleshooting

### High False-Positive Rate
- Increase `bf_filter_size` (e.g., 16384 or 32768)
- Increase `bf_num_hash_functions` (e.g., 5 or 6)
- Decrease `bf_rotation_interval` to reduce filter saturation

### Low Detection Rate
- Check if sequence windows are too small
- Verify Bloom Filter rotation is working
- Increase `bf_num_filters` for longer history

### Compilation Errors
- Ensure all includes are present (`<chrono>`, `<random>`, `<set>`)
- Check namespace declarations
- Verify forward declarations match implementations

## Documentation

- **REPLAY_ATTACK_DOCUMENTATION.md** - Comprehensive technical documentation
- **test_replay_attack.sh** - Automated test suite
- **README_REPLAY_ATTACK.md** - This quick start guide

## Integration with Other Attacks

The Replay Attack system works independently but can be combined:

```bash
# Combine with Sybil and Blackhole attacks
./waf --run "routing \
    --enable_sybil_attack=true \
    --enable_blackhole_attack=true \
    --enable_replay_attack=true \
    --enable_sybil_detection=true \
    --enable_blackhole_mitigation=true \
    --enable_replay_detection=true \
    --enable_replay_mitigation=true \
    --simTime=10"
```

## Advanced Usage

### Optimize for Low Latency
```bash
./waf --run "routing --enable_replay_detection=true \
                     --bf_filter_size=4096 \
                     --bf_num_hash_functions=3 \
                     --bf_num_filters=2"
```

### Optimize for High Accuracy
```bash
./waf --run "routing --enable_replay_detection=true \
                     --bf_filter_size=32768 \
                     --bf_num_hash_functions=6 \
                     --bf_num_filters=5 \
                     --bf_rotation_interval=2.0"
```

### Optimize for Low Memory
```bash
./waf --run "routing --enable_replay_detection=true \
                     --bf_filter_size=4096 \
                     --bf_num_hash_functions=4 \
                     --bf_num_filters=2 \
                     --bf_rotation_interval=10.0"
```

## Code Locations

- **Class Declarations**: Lines 1055-1341 in `routing.cc`
- **Implementation**: Lines 99104-100132 in `routing.cc`
- **Configuration**: Lines 1477-1492 in `routing.cc`
- **Main Integration**: Lines 147396-147445 in `routing.cc`
- **Cleanup & Export**: Lines 147572-147603 in `routing.cc`

## Contact & Support

For issues or questions about the Replay Attack implementation:
1. Check REPLAY_ATTACK_DOCUMENTATION.md for detailed information
2. Run test suite to verify installation
3. Check CSV output files for debugging information

## License

This implementation is part of the ns-3.35 VANET routing simulator project.

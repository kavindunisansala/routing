# SDVN Attack Testing - README

## Overview

This directory contains comprehensive testing scripts for SDVN (Software-Defined Vehicular Network) attack implementations and their mitigation solutions.

## Test Scripts

### 1. `test_sdvn_attacks.sh` (Linux/Mac)
**Comprehensive automated testing suite**
- Tests all 5 SDVN attack types
- Runs each attack with and without mitigation
- Validates performance metrics against thresholds
- Generates detailed reports and CSV exports

**Usage**:
```bash
chmod +x test_sdvn_attacks.sh
./test_sdvn_attacks.sh
```

**Requirements**:
- NS-3 installed and compiled
- Bash shell
- bc calculator (for metric validation)

### 2. `test_sdvn_attacks.ps1` (Windows)
**PowerShell version of the testing suite**
- Same functionality as bash version
- Windows-compatible

**Usage**:
```powershell
.\test_sdvn_attacks.ps1
```

**Requirements**:
- NS-3 installed and compiled
- PowerShell 5.0+

### 3. `test_individual_attacks.sh`
**Quick testing script for individual attacks**
- Test single attack types quickly
- Flexible configuration
- Minimal setup

**Usage**:
```bash
chmod +x test_individual_attacks.sh

# Run baseline
./test_individual_attacks.sh baseline

# Test specific attack without mitigation
./test_individual_attacks.sh wormhole

# Test specific attack WITH mitigation
./test_individual_attacks.sh blackhole with_mitigation

# Run all tests
./test_individual_attacks.sh all
```

## Attack Types Tested

| Attack | Attack Number | Description |
|--------|--------------|-------------|
| **Wormhole** | 2 | Creates tunnels between malicious nodes to intercept routing |
| **Blackhole** | 1 | Drops all packets after attracting traffic |
| **Sybil** | 3 | Creates fake identities to pollute network view |
| **Replay** | 4 | Captures and replays packets to disrupt communication |
| **RTP** | 5 | Injects fake Multi-Hop Links in hybrid SDN |

## Performance Metrics

### Measured Metrics

1. **Packet Delivery Ratio (PDR)**
   - Percentage of packets successfully delivered
   - Baseline: ≥ 85%
   - Under attack: ≤ 60%
   - With mitigation: ≥ 75%

2. **End-to-End Latency**
   - Average packet delivery time (milliseconds)
   - Attack impact: ≤ 2.5x increase

3. **Network Overhead**
   - Control packet ratio
   - Maximum: 20%

4. **Detection Accuracy**
   - Percentage of correctly identified attacks
   - Minimum: 80%

### Performance Thresholds

```bash
BASELINE_PDR_MIN=0.85          # 85%
ATTACK_PDR_MAX=0.60            # 60%
MITIGATION_PDR_MIN=0.75        # 75%
DETECTION_ACCURACY_MIN=0.80    # 80%
LATENCY_INCREASE_MAX=2.5       # 2.5x
OVERHEAD_MAX=0.20              # 20%
```

## Test Scenarios

### Scenario 1: Baseline
- **Purpose**: Establish normal network performance
- **Configuration**: No attacks enabled
- **Expected**: PDR ≥ 85%, normal latency

### Scenario 2: Wormhole Attack
- **Configuration**:
  - Attack percentage: 20%
  - Tunnel bandwidth: 1000Mbps
  - Tunnel delay: 50ms
  - Start time: 10s

**Without Mitigation**:
- Expected: PDR drops to ~40-60%
- Latency increases 2-3x

**With Mitigation** (Latency-based detection):
- Detection threshold: 2.0x baseline
- Expected: PDR recovers to ~75-85%
- Detection accuracy: ≥ 85%

### Scenario 3: Blackhole Attack
- **Configuration**:
  - Attack percentage: 15%
  - Drop data packets: Yes
  - Advertise fake routes: Yes
  - Start time: 10s

**Without Mitigation**:
- Expected: PDR drops to ~30-50%
- Packets lost at malicious nodes

**With Mitigation** (PDR monitoring):
- PDR threshold: 0.5 (50%)
- Minimum packets: 10
- Expected: Malicious nodes blacklisted, PDR recovers to ~75%

### Scenario 4: Sybil Attack
- **Configuration**:
  - Attack percentage: 15%
  - Identities per node: 3
  - Clone legitimate nodes: Yes
  - Start time: 10s

**Without Mitigation**:
- Expected: Network confusion, PDR drops to ~45-65%
- Controller pollution

**With Mitigation** (Multi-technique):
- Trusted certification: Yes
- RSSI detection: Yes
- Expected: Fake identities detected, PDR ~75-80%

### Scenario 5: Replay Attack
- **Configuration**:
  - Attack percentage: 10%
  - Replay interval: 1s
  - Replay count: 5
  - Start time: 10s

**Without Mitigation**:
- Expected: Duplicate packets, confusion
- PDR may remain high but with duplicates

**With Mitigation** (Bloom Filters):
- Filter size: 8192 bits
- Hash functions: 4
- Rotation interval: 5s
- Expected: Replays detected with 99.9995% accuracy

### Scenario 6: RTP Attack
- **Configuration**:
  - Attack percentage: 10%
  - Inject fake MHLs: Yes
  - Fabricate multi-hop links: Yes
  - Start time: 10s

**Without Mitigation**:
- Expected: Routing confusion, PDR drops to ~40-60%
- Packets routed through non-existent links

**With Mitigation** (HybridShield):
- Probe verification: Yes
- Verification interval: 30s
- Expected: Fake MHLs detected, PDR recovers to ~75%

## Output Structure

```
results_YYYYMMDD_HHMMSS/
├── baseline/
│   ├── logs/baseline.log
│   ├── csv/baseline_stats.csv
│   └── stats/
├── wormhole/
│   ├── logs/
│   │   ├── wormhole_attack.log
│   │   └── wormhole_mitigation.log
│   ├── csv/
│   │   ├── wormhole_attack_stats.csv
│   │   ├── wormhole_mitigation_stats.csv
│   │   └── wormhole_detection.csv
│   └── stats/
├── blackhole/
│   ├── logs/...
│   ├── csv/...
│   └── stats/
├── sybil/
│   ├── logs/...
│   ├── csv/...
│   └── stats/
├── replay/
│   ├── logs/...
│   ├── csv/...
│   └── stats/
├── rtp/
│   ├── logs/...
│   ├── csv/...
│   └── stats/
└── summary/
    ├── test_summary.txt
    └── metrics_summary.csv
```

## Configuration Parameters

### Network Size
```bash
VEHICLES=18        # Number of vehicle nodes
RSUS=10           # Number of RSU nodes
TOTAL_NODES=28    # Total nodes in network
SIM_TIME=60       # Simulation time (seconds)
```

### Wormhole Attack
```bash
--enable_wormhole_attack=true
--use_enhanced_wormhole=true
--wormhole_random_pairing=true
--wormhole_tunnel_bandwidth="1000Mbps"
--wormhole_tunnel_delay_us=50000
--wormhole_start_time=10.0
--attack_percentage=0.20
```

### Wormhole Mitigation
```bash
--enable_wormhole_detection=true
--enable_wormhole_mitigation=true
--detection_latency_threshold=2.0
--detection_check_interval=1.0
```

### Blackhole Attack
```bash
--enable_blackhole_attack=true
--blackhole_drop_data=true
--blackhole_advertise_fake_routes=true
--blackhole_fake_sequence_number=999999
--blackhole_start_time=10.0
--blackhole_attack_percentage=0.15
```

### Blackhole Mitigation
```bash
--enable_blackhole_mitigation=true
--blackhole_pdr_threshold=0.5
--blackhole_min_packets=10
```

### Sybil Attack
```bash
--enable_sybil_attack=true
--sybil_identities_per_node=3
--sybil_clone_legitimate_nodes=true
--sybil_inject_fake_packets=true
--sybil_start_time=10.0
--sybil_attack_percentage=0.15
--sybil_broadcast_interval=2.0
```

### Sybil Mitigation
```bash
--enable_sybil_detection=true
--enable_sybil_mitigation=true
--enable_sybil_mitigation_advanced=true
--use_trusted_certification=true
--use_rssi_detection=true
--sybil_detection_threshold=0.8
```

### Replay Attack
```bash
--enable_replay_attack=true
--replay_start_time=10.0
--replay_attack_percentage=0.10
--replay_interval=1.0
--replay_count_per_node=5
--replay_max_captured_packets=100
```

### Replay Mitigation
```bash
--enable_replay_detection=true
--enable_replay_mitigation=true
--bf_filter_size=8192
--bf_num_hash_functions=4
--bf_num_filters=3
--bf_rotation_interval=5.0
```

### RTP Attack
```bash
--enable_rtp_attack=true
--rtp_inject_fake_routes=true
--rtp_fabricate_mhls=true
--rtp_start_time=10.0
--rtp_attack_percentage=0.10
```

### RTP Mitigation
```bash
--enable_hybrid_shield_detection=true
--enable_hybrid_shield_mitigation=true
--hybrid_shield_probe_timeout=100
--hybrid_shield_verification_interval=30.0
```

## Troubleshooting

### Script Permission Denied
```bash
chmod +x test_sdvn_attacks.sh
chmod +x test_individual_attacks.sh
```

### NS-3 Not Found
```bash
export NS3_PATH=/path/to/ns3
```

### Compilation Errors
```bash
cd $NS3_PATH
./waf clean
./waf configure
./waf build
```

### Missing bc Calculator
```bash
# Ubuntu/Debian
sudo apt-get install bc

# macOS
brew install bc
```

## Expected Test Duration

- **Baseline**: ~1 minute (30s simulation + processing)
- **Each Attack**: ~1-2 minutes per scenario
- **Complete Suite**: ~20-30 minutes (all attacks + mitigations)

## Interpreting Results

### Success Indicators
- ✓ Green checkmarks indicate metrics within thresholds
- PDR recovery with mitigation (≥75%)
- High detection accuracy (≥80%)
- Low overhead (≤20%)

### Failure Indicators
- ✗ Red X marks indicate metrics outside thresholds
- PDR not recovering with mitigation
- Low detection accuracy (<80%)
- Excessive overhead (>20%)

### Log Files
Check `*.log` files for detailed execution traces:
- Attack activation messages
- Packet statistics
- Detection events
- Mitigation actions

### CSV Files
Parse `*.csv` files for quantitative analysis:
- Timestamped metrics
- Per-node statistics
- Flow-level data

## Citation

If you use these testing scripts in your research, please cite:

```bibtex
@software{sdvn_attack_testing_2025,
  title={SDVN Attack Testing Suite},
  author={Your Name},
  year={2025},
  url={https://github.com/kavindunisansala/routing}
}
```

## License

See project LICENSE file.

## Contact

For issues or questions:
- GitHub Issues: https://github.com/kavindunisansala/routing/issues
- Email: [your-email@example.com]

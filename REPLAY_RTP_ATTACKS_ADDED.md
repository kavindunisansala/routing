# Replay and RTP Attacks Added to Test Suite

## ✅ Updates Made

Added **2 new attack tests** with their mitigation solutions to `test_sdvn_attacks.sh`:

### Test 7: Replay Attack (10% Malicious Nodes)
- **Attack Type**: Packet Replay Attack
- **Description**: Compromised data plane nodes capture and replay old packets
- **Impact**: Creates duplicate traffic, confuses routing, can replay authentication messages
- **Detection**: Bloom Filters to detect packet duplicates
- **Mitigation**: Automatic packet rejection and node blacklisting

**Parameters Used:**
```bash
--present_replay_attack_nodes=true
--enable_replay_attack=true
--replay_attack_percentage=0.1        # 10% of nodes
--replay_start_time=10.0              # Start at 10 seconds
--enable_replay_detection=true        # Bloom Filter detection
--enable_replay_mitigation=true       # Auto mitigation
```

### Test 8: Routing Table Poisoning (RTP) Attack (10% Malicious Nodes)
- **Attack Type**: Routing Table Poisoning (RTP)
- **Description**: Compromised nodes inject fake routing information
- **Impact**: Advertises false network topology, manipulates Multi-Hop Link (MHL) advertisements
- **Detection**: Controller validates routing consistency
- **Mitigation**: Route verification and anomaly detection

**Parameters Used:**
```bash
--enable_rtp_attack=true
--rtp_attack_percentage=0.1           # 10% of nodes
--rtp_start_time=10.0                 # Start at 10 seconds
```

### Test 9: Combined Attacks (Updated)
Now includes **ALL 5 attacks** simultaneously:
1. Wormhole
2. Blackhole
3. Sybil
4. Replay
5. RTP

All attacks run at 10% each to test controller resilience under maximum threat conditions.

## 📊 Complete Test Suite (9 Tests)

| Test # | Attack Type | Percentage | Description |
|--------|-------------|------------|-------------|
| 1 | Baseline | 0% | No attacks - performance baseline |
| 2 | Wormhole | 10% | Fake tunnels between nodes |
| 3 | Wormhole | 20% | Higher intensity wormhole |
| 4 | Blackhole | 10% | Silent packet dropping |
| 5 | Blackhole | 20% | Higher intensity blackhole |
| 6 | Sybil | 10% | Fake identity cloning |
| 7 | **Replay** | **10%** | **Packet replay attack** ✨ NEW |
| 8 | **RTP** | **10%** | **Routing table poisoning** ✨ NEW |
| 9 | Combined | 10% each | All 5 attacks together |

## 🔍 Attack Details

### Replay Attack Mechanism
```
┌─────────────────────────────────────────────────────────┐
│  REPLAY ATTACK IN SDVN DATA PLANE                       │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  1. Malicious Node captures legitimate packet           │
│     ┌─────────┐         ┌─────────┐                    │
│     │ Node A  │────────>│ Node B  │                    │
│     └─────────┘         └─────────┘                    │
│                              │                          │
│                         ┌────▼────┐                    │
│                         │ CAPTURE │ (Malicious)        │
│                         └─────────┘                    │
│                                                          │
│  2. Malicious node replays packet later                 │
│     ┌─────────┐         ┌─────────┐                    │
│     │ Node A  │<────────│ Node B  │ (Replay)          │
│     └─────────┘         └─────────┘                    │
│                                                          │
│  3. Controller detects duplicate with Bloom Filter      │
│     ┌──────────────┐                                    │
│     │  Controller  │ ❌ REJECT DUPLICATE                │
│     │ Bloom Filter │                                    │
│     └──────────────┘                                    │
└─────────────────────────────────────────────────────────┘
```

**Key Detection Features:**
- **Bloom Filters**: Space-efficient probabilistic data structure
- **Packet Fingerprinting**: Unique hash of packet contents
- **Timestamp Validation**: Checks for old packets being replayed
- **Sequence Number Tracking**: Detects out-of-order replays

**Mitigation Actions:**
- Automatic packet rejection
- Blacklist malicious nodes
- Alert controller of replay attempts
- Update network topology

### RTP Attack Mechanism
```
┌─────────────────────────────────────────────────────────┐
│  RTP ATTACK IN SDVN DATA PLANE                          │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  1. Malicious node injects fake routing info            │
│     ┌─────────────┐                                     │
│     │  Controller │                                     │
│     └──────▲──────┘                                     │
│            │ Fake MHL (Multi-Hop Link)                  │
│            │ "Node X is 1 hop from RSU!"               │
│     ┌──────┴──────┐                                     │
│     │ Malicious   │ (Actually 10 hops away)            │
│     │   Node X    │                                     │
│     └─────────────┘                                     │
│                                                          │
│  2. Controller receives conflicting topology data       │
│     ┌─────────────┐                                     │
│     │  Controller │ ⚠️  Topology Conflict!             │
│     │  Validates  │                                     │
│     │   Routes    │                                     │
│     └─────────────┘                                     │
│                                                          │
│  3. Detection: Route consistency checks                 │
│     - Verify hop counts make sense                      │
│     - Check RSSI matches reported distance              │
│     - Validate with multiple nodes                      │
│                                                          │
│  4. Mitigation: Reject fake routes                      │
│     ┌─────────────┐                                     │
│     │  Controller │ ✓ Use verified routes only         │
│     └─────────────┘                                     │
└─────────────────────────────────────────────────────────┘
```

**Key Detection Features:**
- **Topology Consistency Validation**: Compare routes from multiple sources
- **RSSI Cross-Verification**: Signal strength must match hop count
- **Historical Route Analysis**: Compare with known good routes
- **Anomaly Detection**: Statistical analysis of routing updates

**Mitigation Actions:**
- Reject suspicious routing advertisements
- Recalculate routes using trusted sources
- Blacklist nodes with repeated violations
- Alert network administrator

## 🚀 How to Run

### Run Complete Test Suite
```bash
cd ~/Downloads/ns-allinone-3.35/ns-3.35
git pull origin main
chmod +x test_sdvn_attacks.sh
./test_sdvn_attacks.sh
```

### Run Individual Tests
```bash
# Test Replay attack only
./waf --run "scratch/routing \
    --simTime=100 \
    --N_Vehicles=18 \
    --N_RSUs=10 \
    --architecture=0 \
    --present_replay_attack_nodes=true \
    --enable_replay_attack=true \
    --replay_attack_percentage=0.1 \
    --enable_replay_detection=true \
    --enable_replay_mitigation=true"

# Test RTP attack only
./waf --run "scratch/routing \
    --simTime=100 \
    --N_Vehicles=18 \
    --N_RSUs=10 \
    --architecture=0 \
    --enable_rtp_attack=true \
    --rtp_attack_percentage=0.1"
```

## 📁 Results Directory Structure

After running the complete suite, you'll get:
```
sdvn_results_TIMESTAMP/
├── baseline/
├── wormhole_10pct/
├── wormhole_20pct/
├── blackhole_10pct/
├── blackhole_20pct/
├── sybil_10pct/
├── replay_10pct/              ← NEW
│   ├── logs/
│   │   └── replay_10.log
│   ├── replay-attack-results.csv
│   ├── replay-detection-results.csv
│   └── replay-mitigation-results.csv
├── rtp_10pct/                 ← NEW
│   ├── logs/
│   │   └── rtp_10.log
│   ├── rtp-attack-results.csv
│   ├── rtp-detection-results.csv
│   └── rtp-mitigation-results.csv
├── combined_10pct/
│   └── logs/
│       └── combined.log       (All 5 attacks)
└── test_summary.txt
```

## 📊 Expected Metrics

### Replay Attack Results
- **PDR During Attack**: Should drop significantly (captured packets replayed)
- **Detection Rate**: ≥90% (Bloom Filters are very effective)
- **False Positive Rate**: <5% (Bloom Filters tuned for low false positives)
- **Mitigation PDR**: Should recover to ≥75% baseline

### RTP Attack Results
- **Routing Table Corruption**: Number of fake MHL advertisements injected
- **Topology Accuracy**: Percentage of correct routing entries
- **Route Convergence Time**: Time to stabilize after attack
- **Detection Rate**: ≥80% (depends on validation complexity)

## 🔧 Parameters Reference

### Replay Attack Parameters
```bash
--present_replay_attack_nodes=true     # Mark nodes as replay attackers (SDVN)
--enable_replay_attack=true            # Enable replay attack behavior
--replay_attack_percentage=0.1         # 10% of nodes are malicious
--replay_start_time=10.0               # Start attack at 10 seconds
--enable_replay_detection=true         # Enable Bloom Filter detection
--enable_replay_mitigation=true        # Enable automatic mitigation
```

### RTP Attack Parameters
```bash
--enable_rtp_attack=true               # Enable RTP attack
--rtp_attack_percentage=0.1            # 10% of nodes are malicious
--rtp_start_time=10.0                  # Start attack at 10 seconds
```

Note: RTP attack doesn't have `present_rtp_attack_nodes` parameter - it uses only `enable_rtp_attack`.

## 📚 CSV Output Files

### New CSV Files Generated

**Replay Attack:**
- `replay-attack-results.csv` - Packets captured and replayed
- `replay-detection-results.csv` - Bloom Filter detection statistics
- `replay-mitigation-results.csv` - Mitigation effectiveness metrics

**RTP Attack:**
- `rtp-attack-results.csv` - Fake routing advertisements injected
- `rtp-detection-results.csv` - Route validation results
- `rtp-mitigation-results.csv` - Route recovery metrics

## ✅ Summary of Changes

### Files Modified
- ✅ `test_sdvn_attacks.sh` - Added tests 7, 8, updated test 9

### New Test Functions Added
```bash
test_replay_10()    # Test 7: Replay attack with Bloom Filter mitigation
test_rtp_10()       # Test 8: RTP attack with route validation
```

### Updated Functions
```bash
test_combined()     # Test 9: Now includes all 5 attacks
main()              # Calls new test functions
generate_summary()  # Updated with new attack descriptions
collect_csv_files() # Added RTP CSV files to collection
```

## 🎯 Test Execution Order

The script runs tests in this order:
1. Baseline (establish performance metrics)
2. Individual attacks with increasing intensity
3. Replay attack (test duplicate detection)
4. RTP attack (test routing validation)
5. Combined attack (all 5 attacks together - stress test)

Total execution time: ~15-20 minutes for all 9 tests

## 📝 Next Steps

1. **Pull latest changes from GitHub**
   ```bash
   git pull origin main
   ```

2. **Make script executable**
   ```bash
   chmod +x test_sdvn_attacks.sh
   ```

3. **Run the complete test suite**
   ```bash
   ./test_sdvn_attacks.sh
   ```

4. **Analyze results**
   ```bash
   # View summary
   cat sdvn_results_*/test_summary.txt
   
   # Check Replay attack detection
   cat sdvn_results_*/replay_10pct/logs/replay_10.log
   
   # Check RTP attack results
   cat sdvn_results_*/rtp_10pct/logs/rtp_10.log
   ```

## 🔬 Analysis Tips

### For Replay Attack Analysis
Look for these metrics in logs:
- `packetsReplayed`: Total packets replayed
- `replayDetectionRate`: Percentage of replays detected
- `bloomFilterFalsePositives`: False positive count
- `maliciousNodesBlacklisted`: Nodes caught and blocked

### For RTP Attack Analysis
Look for these metrics in logs:
- `fakeMHLAdvertisements`: Fake routing messages injected
- `routeValidationFailures`: Routes rejected by controller
- `topologyCorruptionLevel`: Percentage of bad routing entries
- `routeConvergenceTime`: Time to recover correct topology

## 🎉 Status

✅ **COMPLETE** - All 5 SDVN data plane attacks now implemented with mitigation:
1. ✅ Wormhole (with detection & mitigation)
2. ✅ Blackhole (with PDR monitoring & blacklisting)
3. ✅ Sybil (with PKI & RSSI detection)
4. ✅ **Replay (with Bloom Filters & mitigation)** ← NEW
5. ✅ **RTP (with route validation & recovery)** ← NEW

The test suite is now **complete and ready for comprehensive SDVN security evaluation**!

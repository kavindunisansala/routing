# SDVN Attack Testing - Fixed Script Explanation

## Problem Identification

Your previous test script was **mixing attack parameters incorrectly**, causing exit code 1 errors. The issue was using parameters for VANET attacks instead of SDVN data plane attacks.

## Understanding SDVN vs VANET Attacks in routing.cc

The code supports **TWO distinct attack scenarios**:

### 1. VANET Attacks (Traditional AODV-based)
- Uses: `enable_wormhole_attack`, `enable_blackhole_attack`, `enable_sybil_attack`
- No SDN controllers involved
- Pure ad-hoc vehicular network attacks
- **NOT what you want for SDVN testing**

### 2. SDVN Data Plane Attacks (What you need!)
- Uses: `present_wormhole_attack_nodes`, `present_blackhole_attack_nodes`, `present_sybil_attack_nodes`
- Architecture: `--architecture=0` (centralized SDN)
- **Controllers are TRUSTED**
- **Data plane nodes (vehicles/RSUs) are COMPROMISED**
- Controllers actively detect and mitigate attacks

## Key Changes Made

### ❌ WRONG (Old broken script)
```bash
./waf --run "routing \
    --simTime=60 \
    --routing_test=false \
    --N_Vehicles=18 \
    --N_RSUs=10 \
    --enable_wormhole_attack=false \    # VANET parameter ❌
    --enable_blackhole_attack=false \   # VANET parameter ❌
    --enable_sybil_attack=false \       # VANET parameter ❌
    --enable_replay_attack=false \
    --enable_rtp_attack=false"
```

### ✅ CORRECT (New fixed script)
```bash
./waf --run "routing \
    --simTime=100 \
    --routing_test=false \
    --N_Vehicles=18 \
    --N_RSUs=10 \
    --architecture=0 \                           # SDVN centralized ✅
    --present_wormhole_attack_nodes=true \       # SDVN data plane attack ✅
    --use_enhanced_wormhole=true \               # Use enhanced implementation ✅
    --attack_percentage=0.1 \                    # 10% malicious nodes ✅
    --enable_wormhole_detection=true \           # Controller detection ✅
    --enable_wormhole_mitigation=true"           # Controller mitigation ✅
```

## SDVN Attack Parameter Mapping

### Wormhole Attack (SDVN Data Plane)
```bash
--present_wormhole_attack_nodes=true     # Mark nodes as malicious
--use_enhanced_wormhole=true             # Use AODV-based wormhole
--attack_percentage=0.1                  # 10% of nodes are malicious
--enable_wormhole_detection=true         # Controller RTT-based detection
--enable_wormhole_mitigation=true        # Controller route recalculation
```

### Blackhole Attack (SDVN Data Plane)
```bash
--present_blackhole_attack_nodes=true         # Mark nodes as malicious
--enable_blackhole_attack=true                # Enable attack behavior
--blackhole_attack_percentage=0.1             # 10% malicious
--blackhole_advertise_fake_routes=true        # Advertise fake routes
--enable_blackhole_mitigation=true            # Controller PDR monitoring
```

### Sybil Attack (SDVN Data Plane)
```bash
--present_sybil_attack_nodes=true             # Mark nodes as malicious
--enable_sybil_attack=true                    # Enable attack behavior
--sybil_attack_percentage=0.1                 # 10% malicious
--sybil_advertise_fake_routes=true            # Fake routes from clones
--sybil_clone_legitimate_nodes=true           # Clone real identities
--enable_sybil_detection=true                 # Controller detection
--enable_sybil_mitigation=true                # Controller mitigation
--enable_sybil_mitigation_advanced=true       # Advanced techniques
--use_trusted_certification=true              # PKI verification
--use_rssi_detection=true                     # RSSI-based co-location detection
```

## Architecture Understanding

### SDVN Data Plane Attack Architecture
```
┌─────────────────────────────────────────┐
│     SDN Controller (TRUSTED)            │
│  - Monitors network topology            │
│  - Detects suspicious behavior          │
│  - Recalculates routes                  │
│  - Blacklists malicious nodes           │
└─────────────────┬───────────────────────┘
                  │
    ┌─────────────┼─────────────┐
    │             │             │
┌───▼───┐    ┌───▼───┐    ┌───▼───┐
│Vehicle│    │ RSU   │    │Vehicle│
│(Good) │    │(EVIL!)│    │(Good) │
└───────┘    └───────┘    └───────┘
                │
       ┌────────┴────────┐
       │ Data Plane      │
       │ Attack Origin   │
       │ - Wormhole      │
       │ - Blackhole     │
       │ - Sybil         │
       └─────────────────┘
```

**Key Points**:
- ✅ Controllers: **TRUSTED** - provide detection/mitigation
- ❌ Data Plane Nodes: **COMPROMISED** - perform attacks
- Attacks happen at **edge/data layer**, not control plane
- Controller sees attack effects and responds

## Test Suite Structure

### 7 Test Scenarios:
1. **Baseline** - No attacks (performance reference)
2. **Wormhole 10%** - Low percentage malicious nodes
3. **Wormhole 20%** - Higher attack intensity
4. **Blackhole 10%** - PDR impact measurement
5. **Blackhole 20%** - Severe blackhole attack
6. **Sybil 10%** - Identity cloning attack
7. **Combined 10%** - All three attacks simultaneously

### Performance Metrics Collected:
- **PDR (Packet Delivery Ratio)**: Should drop during attack, recover with mitigation
- **End-to-End Latency**: Wormhole affects this significantly
- **Detection Accuracy**: How well controller identifies malicious nodes
- **Mitigation Effectiveness**: Performance recovery after detection

## How to Use

### 1. Make sure routing.cc is built with latest fixes
```bash
cd ~/Downloads/ns-allinone-3.35/ns-3.35
git pull origin main  # Get the duplicate parameter fix
./waf clean
./waf build
```

### 2. Run the fixed SDVN test script
```bash
./test_sdvn_attacks.sh
```

### 3. Expected output
```
================================================================
SDVN DATA PLANE ATTACK TESTING SUITE
================================================================

ℹ Testing compromised data plane nodes in SDVN architecture
ℹ Controllers: TRUSTED | Data Plane Nodes: MALICIOUS
ℹ Results will be saved to: ./sdvn_results_20251104_XXXXXX

================================================================
TEST 1: BASELINE (No Attacks)
================================================================

ℹ Running baseline SDVN simulation...
✓ Baseline test completed
ℹ Collected 5 result file(s) for baseline

================================================================
TEST 2: WORMHOLE ATTACK - 10% Malicious Data Plane Nodes
================================================================

ℹ Compromised vehicles/RSUs create fake tunnels
ℹ Controllers detect and mitigate wormhole paths
✓ Wormhole 10% test completed
...
```

## Differences from test_sdvn_attacks_before.sh

The "before" script worked because it used the **correct SDVN parameters**:
- ✅ Used `present_wormhole_attack_nodes=true`
- ✅ Used `present_blackhole_attack_nodes=true`
- ✅ Used `present_sybil_attack_nodes=true`
- ✅ Used `architecture=0` (centralized SDVN)
- ✅ Used `attack_percentage` to control malicious node ratio

Your broken script was trying to use:
- ❌ `enable_wormhole_attack=false` - VANET parameter, doesn't apply to SDVN
- ❌ `enable_blackhole_attack=false` - VANET parameter, doesn't apply to SDVN
- ❌ `enable_sybil_attack=false` - VANET parameter, doesn't apply to SDVN

## Result Files Expected

After successful run:
```
sdvn_results_TIMESTAMP/
├── baseline/
│   ├── logs/baseline.log
│   └── packet-delivery-analysis.csv
├── wormhole_10pct/
│   ├── logs/wormhole_10.log
│   └── packet-delivery-analysis.csv
├── wormhole_20pct/
│   └── ...
├── blackhole_10pct/
│   ├── logs/blackhole_10.log
│   └── blackhole-attack-results.csv
├── blackhole_20pct/
│   └── ...
├── sybil_10pct/
│   ├── logs/sybil_10.log
│   ├── sybil-attack-results.csv
│   └── sybil-detection-results.csv
├── combined_10pct/
│   └── ...
└── test_summary.txt
```

## Troubleshooting

### If you still get exit code 1:
1. **Verify rebuild**: Make sure you pulled commit `503654d` (duplicate parameter fix)
2. **Check architecture**: SDVN requires `--architecture=0`
3. **Verify parameters**: Must use `present_*_attack_nodes`, not `enable_*_attack`

### If simulation hangs:
- Reduce `SIM_TIME` from 100 to 60 seconds
- Reduce `VEHICLES` from 18 to 10

### If no CSV files generated:
- Check logs for errors: `tail -100 sdvn_results_*/*/logs/*.log`
- Verify `enable_packet_tracking=true` is set

## Summary

✅ **Fixed**: Used correct SDVN data plane attack parameters  
✅ **Architecture**: Centralized SDN with trusted controllers  
✅ **Attack Origin**: Compromised data plane nodes (vehicles/RSUs)  
✅ **Detection**: Controllers monitor and detect attacks  
✅ **Mitigation**: Controllers recalculate routes and blacklist nodes  

**The key insight**: SDVN attacks in this code are about **compromised data plane nodes** attacking the network while **controllers remain trusted and provide defense**.

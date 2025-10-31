# SDVN Attack Testing - Quick Start

## ✅ Correct Understanding

Your SDVN implementation tests **DATA PLANE ATTACKS** where:

```
┌─────────────────────────────┐
│  SDN Controller             │
│  ✓ TRUSTED                  │
│  ✓ Detects attacks          │
│  ✓ Mitigates attacks        │
└─────────────┬───────────────┘
              │
    ══════════╪══════════════
              │
        ┌─────┴─────┐
        │           │
    Vehicles      RSUs
    ✗ Can be      ✗ Can be
    malicious     malicious
```

## 🚀 How to Run Tests

### Step 1: Recompile (IMPORTANT!)
```bash
cd ~/Downloads/ns-allinone-3.35/ns-3.35
./waf clean
./waf configure
./waf
```

### Step 2: Install Python Dependencies
```bash
python3 setup_analysis_dependencies.py
```

### Step 3: Run SDVN Attack Tests
```bash
chmod +x test_sdvn_attacks.sh
./test_sdvn_attacks.sh
```

### Step 4: Analyze Results
```bash
python3 analyze_attack_results.py sdvn_attack_results_<timestamp>/
```

## 📊 What Gets Tested

### 7 Test Scenarios:
1. **Baseline** - No attacks (reference)
2. **Wormhole 10%** - 10% of nodes create fake tunnels
3. **Wormhole 20%** - 20% of nodes create fake tunnels  
4. **Blackhole 10%** - 10% of nodes drop packets
5. **Blackhole 20%** - 20% of nodes drop packets
6. **Sybil 10%** - 10% of nodes fake identities
7. **Combined 10%** - All three attacks at 10%

### Attack Mechanisms:

#### Wormhole Attack
- **Attackers**: 2+ malicious nodes collude
- **Method**: Create fake tunnel, encapsulate packets
- **Impact**: Controller sees false topology
- **Detection**: Controller monitors RTT/latency
- **Mitigation**: Controller recalculates routes

#### Blackhole Attack
- **Attackers**: Individual malicious nodes
- **Method**: Advertise good routes, drop packets
- **Impact**: Traffic disappears, PDR drops
- **Detection**: Controller monitors per-node PDR
- **Mitigation**: Controller blacklists nodes

#### Sybil Attack
- **Attackers**: Nodes with fake identities
- **Method**: Report false neighbors
- **Impact**: Topology database pollution
- **Detection**: Controller uses PKI + RSSI
- **Mitigation**: Certificate revocation

## 🔑 Critical Command-Line Arguments

```bash
# Enable SDVN architecture
--architecture=0

# Enable attacks BY NODES (not controllers)
--present_wormhole_attack_nodes=true
--present_blackhole_attack_nodes=true
--present_sybil_attack_nodes=true

# Configure attack intensity
--attack_percentage=0.1  # 10% malicious nodes

# Enable controller detection/mitigation
--enable_wormhole_detection=true
--enable_wormhole_mitigation=true
--enable_blackhole_mitigation=true
--enable_sybil_detection=true
--enable_sybil_mitigation=true

# Generate CSV output
--enable_packet_tracking=true
```

## 📁 Expected Output Files

```
sdvn_attack_results_<timestamp>/
├── test1_sdvn_baseline_packet-delivery-analysis.csv
├── test2_sdvn_wormhole_10_packet-delivery-analysis.csv
├── test3_sdvn_wormhole_20_packet-delivery-analysis.csv
├── test4_sdvn_blackhole_10_blackhole-attack-results.csv
├── test5_sdvn_blackhole_20_blackhole-attack-results.csv
├── test6_sdvn_sybil_10_sybil-attack-results.csv
├── test7_sdvn_combined_10_*_results.csv
├── *_detection-results.csv
├── *_mitigation-results.csv
└── sdvn_test_summary.txt
```

## 📈 Performance Metrics

### Primary Metrics:
- **PDR** (Packet Delivery Ratio): % of packets successfully delivered
- **End-to-End Delay**: Average transmission time
- **Throughput**: Data transmission rate
- **Detection Rate**: % of attacks correctly identified
- **False Positive Rate**: % of legitimate nodes flagged

### SDVN-Specific Metrics:
- **Controller Overhead**: Extra control plane traffic
- **Detection Time**: How fast controller identifies attacks
- **Mitigation Time**: How fast controller reconfigures network
- **Route Recalculation Count**: Number of topology updates

## 🎯 Expected Results

### Without Attacks (Baseline):
- PDR: 85-95%
- Delay: 10-50ms
- Throughput: High
- Controller Overhead: Low

### With Attacks (Before Mitigation):
- PDR: 40-70% (degraded)
- Delay: 50-200ms (increased)
- Throughput: Reduced
- Controller Overhead: Moderate

### With Detection + Mitigation:
- PDR: 70-85% (recovered)
- Delay: 20-80ms (improved)
- Detection Rate: 80-95%
- False Positive Rate: <5%

## ⚠️ Important Notes

### 1. Must Recompile!
The new command-line flags were added to `routing.cc`, so you **MUST** recompile:
```bash
./waf clean && ./waf
```

### 2. Architecture Parameter
- `--architecture=0` → Centralized SDVN (use this!)
- `--architecture=1` → Distributed
- `--architecture=2` → Hybrid

### 3. Attack Model
- **Controllers**: Always trusted ✓
- **Nodes**: Can be compromised ✗
- **Detection**: By controller (global view)
- **Mitigation**: By controller (network reconfiguration)

## 🔍 Troubleshooting

### Tests fail with "Invalid command-line arguments"?
→ You forgot to recompile! Run: `./waf clean && ./waf`

### No CSV files generated?
→ Check if `--enable_packet_tracking=true` is set
→ Look at output files: `cat sdvn_attack_results_*/test*_output.txt`

### Python analysis fails?
→ Install dependencies: `python3 setup_analysis_dependencies.py`

### Want to test individual attacks?
```bash
# Test only wormhole attack
./waf --run "routing --simTime=100 --N_Vehicles=18 --N_RSUs=10 \
    --architecture=0 \
    --present_wormhole_attack_nodes=true \
    --use_enhanced_wormhole=true \
    --attack_percentage=0.1 \
    --enable_wormhole_detection=true \
    --enable_wormhole_mitigation=true \
    --enable_packet_tracking=true"
```

## 📚 Documentation Files

- **SDVN_TESTING_GUIDE.md**: Complete technical guide
- **ATTACK_TESTING_GUIDE.md**: General testing guide  
- **test_sdvn_attacks.sh**: Automated test script
- **analyze_attack_results.py**: Analysis tool
- **diagnose_test_failure.sh**: Diagnostic tool

## 🎓 For Your Research Paper

Focus on these SDVN advantages:

1. **Global View**: Controller sees entire network
   - Better attack detection than distributed approach
   - Can identify attack patterns invisible to local nodes

2. **Centralized Mitigation**: Controller can reconfigure entire network
   - Network-wide response to attacks
   - Coordinated defense strategy

3. **Separation of Concerns**: Control plane vs data plane
   - Attackers can't compromise control logic
   - Controller remains trusted even with malicious nodes

4. **Proactive Defense**: Controller can predict and prevent
   - Analyzes traffic patterns
   - Preemptively blocks suspicious nodes

## 📞 Quick Commands Reference

```bash
# Full test suite
./test_sdvn_attacks.sh

# Analyze results
python3 analyze_attack_results.py sdvn_attack_results_*/

# View summary
cat sdvn_attack_results_*/sdvn_test_summary.txt

# Check errors
tail -50 sdvn_attack_results_*/test*_output.txt

# Diagnose problems
./diagnose_test_failure.sh
```

## ✅ Success Checklist

- [ ] Recompiled routing.cc with `./waf clean && ./waf`
- [ ] Installed Python dependencies
- [ ] Made test script executable: `chmod +x test_sdvn_attacks.sh`
- [ ] Ran test script: `./test_sdvn_attacks.sh`
- [ ] Got CSV files in results directory
- [ ] Ran analysis: `python3 analyze_attack_results.py sdvn_attack_results_*/`
- [ ] Reviewed plots and tables

Good luck with your SDVN security research! 🚀

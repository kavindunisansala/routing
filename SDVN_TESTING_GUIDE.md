# SDVN Attack Testing Guide - Data Plane Security

## Overview

Your `routing.cc` implements **SDVN (Software-Defined Vehicular Network) security attacks** where:

- **SDN Controllers**: TRUSTED (not compromised)
- **Data Plane Nodes**: Can be COMPROMISED (vehicles/RSUs)
- **Attack Model**: Malicious nodes attack the network while trusted controllers detect and mitigate

## SDVN Architecture

```
┌─────────────────────────────────────────┐
│   SDN Controller (TRUSTED)              │
│   - Global network view                 │
│   - Detects attacks                     │
│   - Reconfigures network                │
└──────────────┬──────────────────────────┘
               │ Control Plane
               │ (OpenFlow)
═══════════════╪═══════════════════════════
               │ Data Plane
      ┌────────┴────────┐
      │                 │
   Vehicles           RSUs
   (Can be         (Can be
   malicious)      malicious)
```

## Attack Types in SDVN

### 1. Wormhole Attack (Data Plane)
**Attackers**: Compromised data plane nodes (vehicles/RSUs)  
**How it works:**
- Two malicious nodes collude to create a fake "tunnel"
- Packets are encapsulated and forwarded through the tunnel
- Makes distant nodes appear as neighbors
- Controller sees a false network topology

**Impact on SDVN:**
- Controller calculates routes based on false topology
- Traffic is redirected through malicious tunnel
- Normal routing protocols are bypassed

**Detection by Controller:**
- RTT (Round Trip Time) monitoring
- Hop count verification
- Latency anomaly detection

**Mitigation by Controller:**
- Identifies suspicious routes with abnormal latency
- Recalculates routes avoiding tunnel endpoints
- Blacklists malicious node pairs

### 2. Blackhole Attack (Data Plane)
**Attackers**: Compromised data plane nodes  
**How it works:**
- Malicious nodes advertise good routes to attract traffic
- Once traffic is received, packets are silently dropped
- Node does not forward packets as expected

**Impact on SDVN:**
- Controller flow tables direct traffic to malicious nodes
- Packets disappear without trace
- Network PDR (Packet Delivery Ratio) degrades

**Detection by Controller:**
- Monitors PDR per node using global view
- Tracks which nodes have abnormally high packet loss
- Identifies nodes that receive but don't forward

**Mitigation by Controller:**
- Blacklists nodes with low forwarding ratio
- Reconfigures flow tables to avoid malicious nodes
- Redirects traffic through alternative paths

### 3. Sybil Attack (Data Plane)
**Attackers**: Compromised data plane nodes  
**How it works:**
- Malicious node claims multiple fake identities
- Reports false neighbor relationships to controller
- Pollutes controller's topology database

**Impact on SDVN:**
- Controller believes fake nodes exist
- Calculates routes through non-existent nodes
- Network topology map becomes corrupted

**Detection by Controller:**
- PKI-based identity verification
- RSSI (signal strength) analysis for co-location detection
- Resource testing (fake identities can't pass tests)
- Social network analysis (fake identities have suspicious patterns)

**Mitigation by Controller:**
- Requires trusted certificate authority
- Performs identity binding verification
- Uses challenge-response authentication
- Revokes certificates of detected Sybil nodes

## Key Differences: SDVN vs VANET

## Key Differences: SDVN vs Traditional VANET

| Aspect | Traditional VANET | SDVN |
|--------|-------------------|------|
| **Control** | Distributed (each node) | Centralized (SDN controller) |
| **Attack Detection** | Local (by neighbors) | Global (by controller) |
| **Mitigation** | Individual node response | Network-wide reconfiguration |
| **Attacker** | Malicious nodes | Malicious nodes (same) |
| **Defender** | Peer nodes | Central controller |
| **View** | Local neighborhood | Global network topology |
| **Response Time** | Fast (local) | Moderate (controller communication) |
| **Effectiveness** | Limited scope | Network-wide |

**Important**: In both cases, attacks come from **compromised data plane nodes**, but SDVN has a **trusted central controller** that can detect and mitigate attacks using its global network view.

## Test Script: test_sdvn_attacks.sh

**Purpose**: Test data plane attacks in SDVN architecture with trusted controller

### Usage

```bash
chmod +x test_sdvn_attacks.sh
./test_sdvn_attacks.sh
```

**Test Scenarios:**
- Baseline (no attacks)
- Wormhole attacks by nodes (10%, 20%)
- Blackhole attacks by nodes (10%, 20%)
- Sybil attacks by nodes (10%)
- Combined attacks (all at 10%)

**Critical Command-Line Arguments:**
```bash
--architecture=0                           # SDVN mode (centralized controller)
--present_wormhole_attack_nodes=true       # Enable wormhole by NODES
--present_blackhole_attack_nodes=true      # Enable blackhole by NODES
--present_sybil_attack_nodes=true          # Enable sybil by NODES
--attack_percentage=0.1                    # 10% of nodes are malicious
--enable_packet_tracking=true              # Generate CSV output
--enable_*_detection=true                  # Controller detection enabled
--enable_*_mitigation=true                 # Controller mitigation enabled
```

## SDVN Attack Command-Line Flags

### Newly Added Flags:

These flags enable data plane attacks in SDVN (added to routing.cc):

```bash
--present_wormhole_attack_nodes=<true/false>   # Wormhole attacks by nodes
--present_blackhole_attack_nodes=<true/false>  # Blackhole attacks by nodes
--present_sybil_attack_nodes=<true/false>      # Sybil attacks by nodes
```

**Complete Example:**
```bash
./waf --run "routing \
    --simTime=100 \
    --N_Vehicles=18 \
    --N_RSUs=10 \
    --architecture=0 \
    --present_wormhole_attack_nodes=true \
    --use_enhanced_wormhole=true \
    --attack_percentage=0.1 \
    --enable_wormhole_detection=true \
    --enable_wormhole_mitigation=true \
    --enable_packet_tracking=true"
```

This command:
1. Sets up SDVN with centralized controller
2. Enables wormhole attacks by 10% of data plane nodes
3. Enables controller-based detection and mitigation
4. Generates CSV files for analysis

## Expected CSV Output Files

The following CSV files are generated for analysis:

```
packet-delivery-analysis.csv        # Overall PDR metrics
blackhole-attack-results.csv        # Blackhole attack stats
sybil-attack-results.csv            # Sybil attack stats
sybil-detection-results.csv         # Detection performance
sybil-mitigation-results.csv        # Mitigation effectiveness
trusted-certification-results.csv   # PKI verification
rssi-detection-results.csv          # RSSI-based detection
resource-testing-results.csv        # Resource testing results
incentive-scheme-results.csv        # Incentive mechanism
```

## Running SDVN Tests

### Step 1: Install Dependencies
```bash
python3 setup_analysis_dependencies.py
# Or manually:
pip3 install pandas numpy matplotlib seaborn
```

### Step 2: Run SDVN Attack Tests
```bash
chmod +x test_sdvn_attacks.sh
./test_sdvn_attacks.sh
```

### Step 3: Analyze Results
```bash
python3 analyze_attack_results.py sdvn_attack_results_<timestamp>/
```

## Performance Metrics

### SDVN-Specific Metrics:
1. **Controller Overhead** - Extra control plane traffic
2. **Flow Table Updates** - Rate of flow modification
3. **Topology Convergence Time** - Time to detect topology changes
4. **Controller Response Time** - Latency for flow installation
5. **Inter-Controller Communication** - Control plane messaging
6. **Topology Database Accuracy** - Correctness of stored topology

### General Network Metrics:
1. **Packet Delivery Ratio (PDR)** - End-to-end delivery success
2. **End-to-End Delay** - Total transmission time
3. **Network Throughput** - Data transmission rate
4. **Packet Loss Rate** - Lost packet percentage
5. **Detection Rate** - Attack identification accuracy
6. **False Positive Rate** - Legitimate traffic misidentified

## Important Notes

### Current Limitation
The controller attack flags (`present_*_attack_controllers`) are **not exposed as command-line arguments** in your current code. The test script uses the available parameters that enable attacks, which will affect nodes but can be used to test SDVN behavior.

### To Enable True Controller Attacks
You would need to modify `routing.cc` to add command-line arguments:

```cpp
// Add these in the command-line parsing section:
cmd.AddValue("present_wormhole_attack_controllers", 
             "Enable wormhole attacks on controllers", 
             present_wormhole_attack_controllers);
cmd.AddValue("present_blackhole_attack_controllers", 
             "Enable blackhole attacks on controllers", 
             present_blackhole_attack_controllers);
cmd.AddValue("present_sybil_attack_controllers", 
             "Enable sybil attacks on controllers", 
             present_sybil_attack_controllers);
```

### Architecture Parameter
- `--architecture=0` → Centralized (single controller)
- `--architecture=1` → Distributed (multiple controllers)
- `--architecture=2` → Hybrid (mix of centralized and distributed)

## Quick Start for SDVN Testing

```bash
# 1. Make scripts executable
chmod +x test_sdvn_attacks.sh diagnose_test_failure.sh

# 2. Install Python dependencies
python3 setup_analysis_dependencies.py

# 3. Run SDVN tests
./test_sdvn_attacks.sh

# 4. Analyze results
python3 analyze_attack_results.py sdvn_attack_results_<timestamp>/

# 5. View summary
cat sdvn_attack_results_<timestamp>/sdvn_test_summary.txt
```

## Troubleshooting

### If tests fail:
```bash
# Run diagnostics
./diagnose_test_failure.sh

# Check specific test output
cat sdvn_attack_results_<timestamp>/test1_sdvn_baseline_output.txt | tail -50
```

### If no CSV files generated:
- Check if `--enable_packet_tracking=true` is set
- Verify the simulation completes successfully
- Look for errors in output files

### If wrong attack type tested:
- Use `test_sdvn_attacks.sh` for SDVN controller attacks
- Use `test_attacks_fixed.sh` for VANET node attacks
- Check `--architecture` parameter (0 for SDVN)

## Comparison: VANET vs SDVN

| Aspect | VANET | SDVN |
|--------|-------|------|
| **Attack Target** | Nodes (vehicles/RSUs) | Controllers |
| **Attack Scope** | Local (affects neighbors) | Global (affects entire network) |
| **Detection Difficulty** | Easier (local monitoring) | Harder (controller is trusted) |
| **Impact Severity** | Lower (limited scope) | Higher (network-wide) |
| **Mitigation** | Node isolation | Controller replacement |
| **Test Script** | `test_attacks_fixed.sh` | `test_sdvn_attacks.sh` |

## Expected Results

### Without Attacks (Baseline):
- PDR: 85-95%
- Delay: 10-50ms
- Throughput: High

### With SDVN Attacks:
- PDR: 40-70% (depending on attack intensity)
- Delay: 50-200ms (increased due to controller manipulation)
- Throughput: Significantly reduced
- Detection Rate: 80-95% (with mitigation enabled)

### After Mitigation:
- PDR: 70-85% (partial recovery)
- Delay: 20-80ms (improved)
- Throughput: Moderate recovery
- False Positive Rate: <5%

## Research Paper Metrics

For your research paper, focus on these SDVN-specific metrics:

1. **Controller Attack Impact**
   - PDR degradation vs baseline
   - Delay increase percentage
   - Throughput reduction

2. **Detection Performance**
   - Detection rate (True Positive Rate)
   - False positive rate
   - Detection time

3. **Mitigation Effectiveness**
   - PDR recovery percentage
   - Mitigation time
   - Controller failover time

4. **SDVN Overhead**
   - Control plane traffic increase
   - Flow table update rate
   - Inter-controller messaging

## References

- Test scripts: `test_sdvn_attacks.sh`, `test_attacks_fixed.sh`
- Analysis tool: `analyze_attack_results.py`
- Diagnostic tool: `diagnose_test_failure.sh`
- Dependency setup: `setup_analysis_dependencies.py`
- Main guide: `ATTACK_TESTING_GUIDE.md`

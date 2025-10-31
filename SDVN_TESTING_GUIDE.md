# SDVN vs VANET Attack Testing Guide

## Overview

Your `routing.cc` implementation supports **TWO types of attacks**:

1. **VANET Attacks** - Target vehicle nodes in the network
2. **SDVN Attacks** - Target SDN controllers in the network

## Key Differences

### VANET Attacks (Node-Level)
- **Target**: Vehicle nodes and RSU nodes
- **Flags**: `present_*_attack_nodes` (e.g., `present_wormhole_attack_nodes`)
- **Attack Location**: At the network edge (vehicles/RSUs)
- **Impact**: Affects local communication between nodes

### SDVN Attacks (Controller-Level)
- **Target**: SDN Controllers (centralized control plane)
- **Flags**: `present_*_attack_controllers` (e.g., `present_wormhole_attack_controllers`)
- **Attack Location**: At the control plane (controllers)
- **Impact**: Affects entire network topology and routing decisions

## Test Scripts Available

### 1. `test_sdvn_attacks.sh` ← **USE THIS FOR SDVN TESTING**

Tests **controller-level attacks** in SDVN architecture:

```bash
chmod +x test_sdvn_attacks.sh
./test_sdvn_attacks.sh
```

**Test Scenarios:**
- Baseline (no attacks)
- Wormhole attacks on controllers (10%, 20%)
- Blackhole attacks on controllers (10%, 20%)
- Sybil attacks on controllers (10%)
- Combined attacks (all at 10%)

**Command-Line Arguments Used:**
```bash
--architecture=0                    # Centralized SDVN
--use_enhanced_wormhole=true        # Wormhole attack
--enable_blackhole_attack=true      # Blackhole attack
--enable_sybil_attack=true          # Sybil attack
--enable_packet_tracking=true       # CSV output
--enable_*_detection=true           # Detection enabled
--enable_*_mitigation=true          # Mitigation enabled
```

### 2. `test_attacks_fixed.sh`

Tests **node-level attacks** in VANET architecture:
- Includes Replay attack (VANET-only)
- Targets vehicles and RSUs
- 8 test scenarios including replay attack

## SDVN Attack Details

### Wormhole Attack (Controller-Level)
**How it works:**
- Malicious controller creates fake tunnels in the network topology
- Manipulates OpenFlow flow tables to redirect traffic
- Creates artificial "shortcuts" that don't physically exist

**Detection:**
- RTT-based latency monitoring
- Hop count verification
- Path validation

**Mitigation:**
- Automatic route recalculation
- Flow table verification
- Controller reputation system

### Blackhole Attack (Controller-Level)
**How it works:**
- Malicious controller drops packets silently
- Advertises fake routes to attract traffic
- Manipulates flow entries to discard data

**Detection:**
- PDR (Packet Delivery Ratio) monitoring per controller
- Traffic flow analysis
- Controller behavior profiling

**Mitigation:**
- Controller blacklisting
- Route redistribution
- Backup controller activation

### Sybil Attack (Controller-Level)
**How it works:**
- Malicious controller creates fake node identities
- Pollutes the network topology database
- Injects false neighborhood information

**Detection:**
- Identity verification (PKI-based)
- RSSI-based co-location detection
- Resource testing
- Social network analysis

**Mitigation:**
- Trusted certification authority
- Identity binding verification
- Resource challenge-response
- Incentive-based revelation

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

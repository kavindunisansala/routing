# SDVN Security Attack Testing Guide

## Overview
This guide provides step-by-step instructions for testing Wormhole, Sybil, and Blackhole attacks in Software-Defined Vehicular Networks (SDVN) along with mitigation solutions and performance evaluation.

## Prerequisites

### Software Requirements
- NS-3.35 (or compatible version)
- Python 3.6+
- Required Python packages:
  ```bash
  pip3 install pandas numpy matplotlib seaborn
  ```
- Bash shell (Linux/macOS) or Git Bash (Windows)

### Hardware Requirements
- Minimum 4GB RAM
- 10GB free disk space
- Multi-core processor recommended

## Quick Start

### 1. Setup Environment

```bash
# Navigate to your workspace
cd ~/Downloads/ns-allinone-3.35/ns-3.35

# Copy routing.cc to scratch directory
cp /path/to/routing.cc scratch/

# Build the project
./waf build
```

### 2. Run Attack Tests

```bash
# Make test script executable
chmod +x test_attacks.sh

# Run all attack scenarios
./test_attacks.sh
```

This will run 8 test scenarios:
1. **Baseline** - No attacks (reference scenario)
2. **Wormhole 10%** - 10% malicious nodes with wormhole attack
3. **Wormhole 20%** - 20% malicious nodes with wormhole attack
4. **Blackhole 10%** - 10% malicious nodes with blackhole attack
5. **Blackhole 20%** - 20% malicious nodes with blackhole attack
6. **Sybil 10%** - 10% malicious nodes with sybil attack
7. **Combined 10%** - All three attacks at 10% intensity
8. **Combined 30%** - All three attacks at 30% intensity

### 3. Analyze Results

```bash
# Run analysis script (replace timestamp with your actual directory)
python3 analyze_attack_results.py attack_results_20250131_120000
```

## Individual Attack Testing

### Wormhole Attack

#### Test with 10% Malicious Nodes
```bash
./waf --run "routing \
    --simTime=100 \
    --N_Vehicles=18 \
    --N_RSUs=10 \
    --present_wormhole_attack_nodes=true \
    --attack_percentage=0.1 \
    --present_blackhole_attack_nodes=false \
    --present_sybil_attack_nodes=false"
```

#### Test with Mitigation Enabled
```bash
./waf --run "routing \
    --simTime=100 \
    --N_Vehicles=18 \
    --N_RSUs=10 \
    --present_wormhole_attack_nodes=true \
    --attack_percentage=0.2 \
    --enable_wormhole_mitigation=true"
```

### Blackhole Attack

#### Test with 15% Malicious Nodes
```bash
./waf --run "routing \
    --simTime=100 \
    --N_Vehicles=18 \
    --N_RSUs=10 \
    --present_blackhole_attack_nodes=true \
    --attack_percentage=0.15 \
    --present_wormhole_attack_nodes=false \
    --present_sybil_attack_nodes=false"
```

#### Test with Mitigation Enabled
```bash
./waf --run "routing \
    --simTime=100 \
    --N_Vehicles=18 \
    --N_RSUs=10 \
    --present_blackhole_attack_nodes=true \
    --attack_percentage=0.15 \
    --enable_blackhole_mitigation=true"
```

### Sybil Attack

#### Test with 20% Malicious Nodes
```bash
./waf --run "routing \
    --simTime=100 \
    --N_Vehicles=18 \
    --N_RSUs=10 \
    --present_sybil_attack_nodes=true \
    --attack_percentage=0.2 \
    --present_wormhole_attack_nodes=false \
    --present_blackhole_attack_nodes=false"
```

#### Test with Mitigation Enabled
```bash
./waf --run "routing \
    --simTime=100 \
    --N_Vehicles=18 \
    --N_RSUs=10 \
    --present_sybil_attack_nodes=true \
    --attack_percentage=0.2 \
    --enable_sybil_mitigation=true"
```

## Performance Metrics

### Primary Metrics Collected

1. **Packet Delivery Ratio (PDR)**
   - Definition: Ratio of successfully delivered packets to total sent packets
   - Formula: PDR = (Packets Received / Packets Sent) × 100%
   - Ideal Value: Close to 100%

2. **End-to-End Delay**
   - Definition: Average time taken for a packet to travel from source to destination
   - Unit: Milliseconds (ms)
   - Lower is better

3. **Network Throughput**
   - Definition: Amount of data successfully transmitted per unit time
   - Unit: Megabits per second (Mbps)
   - Higher is better

4. **Packet Loss Rate**
   - Definition: Percentage of packets lost during transmission
   - Formula: Loss Rate = (Packets Lost / Packets Sent) × 100%
   - Lower is better

5. **Routing Overhead**
   - Definition: Ratio of routing control packets to data packets
   - Lower indicates more efficient routing

6. **Detection Rate**
   - Definition: Percentage of attacks correctly identified
   - Formula: DR = (True Positives / (True Positives + False Negatives)) × 100%
   - Higher is better

7. **False Positive Rate**
   - Definition: Percentage of legitimate nodes incorrectly flagged as malicious
   - Formula: FPR = (False Positives / (False Positives + True Negatives)) × 100%
   - Lower is better

8. **Energy Consumption**
   - Definition: Total energy consumed by network nodes
   - Unit: Joules (J)
   - Lower indicates better efficiency

### Attack-Specific Metrics

#### Wormhole Attack
- **Packets Tunneled**: Number of packets forwarded through wormhole tunnel
- **Route Distortion Rate**: Percentage of routes affected by the attack
- **Tunnel Detection Time**: Time taken to detect the wormhole tunnel
- **Affected Routing Paths**: Number of routing paths passing through malicious nodes

#### Blackhole Attack
- **Packets Dropped**: Number of packets silently discarded by attacker
- **Traffic Attraction Rate**: Percentage of traffic attracted to blackhole
- **Network Coverage Degradation**: Reduction in effective network coverage
- **Isolation Time**: Time taken to isolate the malicious node

#### Sybil Attack
- **Fake Identities Created**: Number of fake node identities generated
- **Trust Value Manipulation**: Degree of trust system compromise
- **Resource Consumption Rate**: Additional resources consumed by fake nodes
- **Identity Verification Time**: Time taken to verify legitimate identities

## Expected Results Format

### CSV Output Files

Each test generates a CSV file with the following structure:

```csv
Timestamp,NodeID,PDR,Delay,Throughput,PacketLoss,RoutingOverhead,DetectionRate,FalsePositiveRate,EnergyConsumption
0.5,2,0.95,12.5,8.2,0.05,0.15,0.85,0.02,150.3
1.0,2,0.93,13.1,8.0,0.07,0.16,0.88,0.02,151.2
...
```

### Summary Statistics

The analysis script generates summary statistics comparing all scenarios:

```
Scenario              | Avg_PDR | Avg_Delay_ms | Avg_Throughput_Mbps | Detection_Rate
----------------------|---------|--------------|---------------------|----------------
Baseline (No Attack)  | 0.980   | 10.5         | 9.5                | N/A
Wormhole 10%         | 0.850   | 18.2         | 7.8                | 0.82
Wormhole 20%         | 0.720   | 25.6         | 6.2                | 0.85
Blackhole 10%        | 0.780   | 16.5         | 7.0                | 0.90
Blackhole 20%        | 0.650   | 22.8         | 5.5                | 0.92
Sybil 10%            | 0.820   | 15.3         | 7.5                | 0.75
Combined 10%         | 0.700   | 21.5         | 6.0                | 0.78
Combined 30%         | 0.520   | 35.2         | 4.2                | 0.80
```

## Mitigation Solutions

### 1. Wormhole Attack Mitigation

**Detection Mechanisms:**
- **RTT-based Detection**: Monitor round-trip time anomalies
- **Hop Count Analysis**: Check for impossible hop count values
- **Packet Leash**: Verify geographical and temporal constraints
- **Neighbor Discovery**: Validate neighbor relationships

**Implementation:**
```cpp
// Enable in routing.cc
bool enable_wormhole_mitigation = true;
double rtt_threshold = 50.0; // milliseconds
int max_hop_count = 10;
```

**Expected Improvement:**
- Detection Rate: 85-95%
- PDR Recovery: 10-15% improvement
- Delay Reduction: 20-30% compared to unmitigated attack

### 2. Blackhole Attack Mitigation

**Detection Mechanisms:**
- **Watchdog Mechanism**: Monitor packet forwarding behavior
- **Pathrater**: Rate nodes based on reliability
- **Data Routing Information (DRI)**: Track packet delivery
- **Collaborative Detection**: Share information between nodes

**Implementation:**
```cpp
// Enable in routing.cc
bool enable_blackhole_mitigation = true;
double trust_threshold = 0.6;
int monitoring_window = 100; // packets
```

**Expected Improvement:**
- Detection Rate: 90-98%
- PDR Recovery: 15-20% improvement
- Isolation Time: < 5 seconds

### 3. Sybil Attack Mitigation

**Detection Mechanisms:**
- **Identity Verification**: Use cryptographic certificates
- **Position Verification**: Verify physical location
- **RSSI Analysis**: Check signal strength patterns
- **Social Network Analysis**: Analyze communication patterns

**Implementation:**
```cpp
// Enable in routing.cc
bool enable_sybil_mitigation = true;
double rssi_threshold = -85.0; // dBm
int max_identities_per_location = 1;
```

**Expected Improvement:**
- Detection Rate: 80-90%
- False Positive Rate: < 5%
- PDR Recovery: 12-18% improvement

## Visualization and Analysis

### Generated Plots

1. **Performance Comparison Bar Charts**
   - PDR comparison across all scenarios
   - Delay comparison
   - Throughput comparison
   - Packet loss rate
   - Detection rate
   - Routing overhead

2. **Attack Impact Analysis**
   - Comparative degradation percentages
   - Severity classification
   - Mitigation effectiveness

3. **Time-series Analysis** (if temporal data available)
   - Metric evolution over simulation time
   - Attack detection timeline
   - Recovery patterns

### Using Results in Research

The analysis script generates:

1. **CSV Files**: For importing into Excel, MATLAB, or R
2. **PNG Plots**: High-resolution figures for papers
3. **LaTeX Tables**: Ready-to-use tables for research papers
4. **Statistical Summary**: Comprehensive numerical analysis

## Troubleshooting

### Common Issues

1. **Compilation Errors**
   ```bash
   # Clean build
   ./waf clean
   ./waf configure
   ./waf build
   ```

2. **Missing Performance Metrics CSV**
   - Check if simulation completed successfully
   - Verify output directory permissions
   - Review output.txt for errors

3. **Python Analysis Fails**
   ```bash
   # Install missing packages
   pip3 install pandas numpy matplotlib seaborn
   
   # Check Python version
   python3 --version  # Should be 3.6 or higher
   ```

4. **Low Detection Rates**
   - Increase monitoring window
   - Adjust detection thresholds
   - Enable multiple detection mechanisms

## Advanced Configuration

### Custom Test Scenarios

Create custom scenarios by modifying parameters:

```bash
./waf --run "routing \
    --simTime=150 \                      # Longer simulation
    --N_Vehicles=30 \                    # More vehicles
    --N_RSUs=15 \                        # More RSUs
    --attack_percentage=0.25 \           # 25% malicious
    --present_wormhole_attack_nodes=true \
    --enable_wormhole_mitigation=true \
    --rtt_threshold=45.0 \               # Custom threshold
    --max_hop_count=12"                  # Custom hop limit
```

### Batch Testing Different Parameters

```bash
# Test multiple attack percentages
for percentage in 0.05 0.10 0.15 0.20 0.25 0.30; do
    ./waf --run "routing \
        --simTime=100 \
        --N_Vehicles=18 \
        --N_RSUs=10 \
        --present_blackhole_attack_nodes=true \
        --attack_percentage=$percentage"
    
    mv performance_metrics.csv results/blackhole_${percentage}.csv
done
```

## Research Paper Integration

### Suggested Analysis Workflow

1. **Data Collection**: Run all test scenarios
2. **Statistical Analysis**: Use analysis script
3. **Visualization**: Generate plots
4. **Comparative Study**: Compare with baseline
5. **Mitigation Evaluation**: Test with/without mitigation
6. **Discussion**: Interpret results

### Key Findings to Report

- **Attack Impact**: Quantify degradation for each attack type
- **Detection Accuracy**: Report detection rate and false positives
- **Mitigation Effectiveness**: Show improvement percentages
- **Scalability**: Test with different network sizes
- **Real-world Applicability**: Discuss practical implications

## References

For more information on SDVN security:
1. NS-3 Documentation: https://www.nsnam.org/documentation/
2. VANET Security: Research papers on vehicular network security
3. SDN Security: Software-defined networking security literature

## Support

For issues or questions:
1. Check the troubleshooting section
2. Review NS-3 documentation
3. Check simulation output logs
4. Verify all prerequisites are installed

## License

This testing framework is provided for research and educational purposes.

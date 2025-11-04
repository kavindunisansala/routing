# SDVN Complete Security Evaluation - Implementation Guide

## Overview
This document describes the complete SDVN security evaluation framework that tests all data plane attacks with and without mitigation solutions, and generates comprehensive performance analysis.

## Components

### 1. Complete Evaluation Test Script
**File**: `test_sdvn_complete_evaluation.sh`

**Purpose**: Run all SDVN attacks with detection and full mitigation phases

**Test Phases** (17 tests total):
- **Phase 1**: Baseline (1 test)
- **Phase 2**: Wormhole Attack (3 tests: no mitigation, detection, full mitigation)
- **Phase 3**: Blackhole Attack (3 tests: no mitigation, detection, full mitigation)
- **Phase 4**: Sybil Attack (3 tests: no mitigation, detection, full mitigation)
- **Phase 5**: Replay Attack (3 tests: no mitigation, detection, full mitigation)
- **Phase 6**: RTP Attack (3 tests: no mitigation, detection, full mitigation)
- **Phase 7**: Combined Attack with all mitigations (1 test)

**Usage**:
```bash
cd ~/Downloads/ns-allinone-3.35/ns-3.35
chmod +x test_sdvn_complete_evaluation.sh
./test_sdvn_complete_evaluation.sh
```

**Output**: `./sdvn_evaluation_TIMESTAMP/`
- Test directories for each scenario
- CSV files with simulation metrics
- Log files for debugging
- Summary report

### 2. Complete Evaluation Analysis Script
**File**: `analyze_sdvn_complete_evaluation.py`

**Purpose**: Analyze results and generate before/after mitigation comparisons

**Features**:
- Loads metrics from all 17 test scenarios
- Calculates Packet Delivery Ratio (PDR)
- Measures end-to-end delay
- Computes throughput
- Generates mitigation effectiveness analysis
- Creates comparative visualizations

**Usage**:
```bash
python3 analyze_sdvn_complete_evaluation.py ./sdvn_evaluation_TIMESTAMP/
```

**Outputs**:
- `pdr_comparison.png` - PDR across all scenarios
- `mitigation_effectiveness.png` - Before vs after comparison
- `attack_impact.png` - Packet loss and delay analysis
- `overall_improvement.png` - Mitigation improvement by attack type
- `summary_table.tex` - LaTeX table for research papers
- `comparison_table.tex` - LaTeX comparison table
- `analysis_report.txt` - Comprehensive text report

### 3. Enhanced Replay/RTP Test Script
**File**: `test_replay_rtp_only.sh` (Updated)

**Purpose**: Diagnostic testing with RTP mitigation support

**Test Scenarios** (9 tests):
1. Baseline - No attacks
2. Replay Attack Only (no mitigation)
3. Replay with Detection (Bloom Filters)
4. Replay with Full Mitigation
5. RTP Attack Only (no mitigation)
6. RTP with Hybrid-Shield Detection
7. RTP with Hybrid-Shield Full Mitigation
8. Combined Replay + RTP attacks
9. Combined with all mitigations

**Usage**:
```bash
chmod +x test_replay_rtp_only.sh
./test_replay_rtp_only.sh
```

### 4. Original Analysis Script
**File**: `analyze_attack_results.py` (Enhanced)

**Purpose**: Analyze results from `test_sdvn_attacks.sh` (original script)

**Enhancements**:
- Added Replay attack metrics support
- Added RTP attack metrics support
- Support for 9 test scenarios
- Enhanced CSV file detection

## Attack Types and Mitigation Solutions

### 1. Wormhole Attack
**Mitigation**: RTT-based detection + route isolation
- **Detection**: Measures Round-Trip Time to detect tunneling
- **Mitigation**: Isolates malicious nodes, reroutes traffic

**Parameters**:
```bash
--enable_wormhole_attack=true
--wormhole_attack_percentage=0.10
--enable_wormhole_detection=true
--enable_wormhole_mitigation=true
```

### 2. Blackhole Attack
**Mitigation**: Traffic pattern analysis + node isolation
- **Detection**: Monitors packet forwarding behavior
- **Mitigation**: Identifies and isolates non-forwarding nodes

**Parameters**:
```bash
--enable_blackhole_attack=true
--blackhole_attack_percentage=0.10
--enable_blackhole_detection=true
--enable_blackhole_mitigation=true
```

### 3. Sybil Attack
**Mitigation**: Identity verification + MAC validation
- **Detection**: Checks for duplicate identities
- **Mitigation**: Validates MAC addresses, blocks fake identities

**Parameters**:
```bash
--enable_sybil_attack=true
--sybil_attack_percentage=0.10
--enable_sybil_detection=true
--enable_sybil_mitigation=true
```

### 4. Replay Attack
**Mitigation**: Bloom Filter sequence tracking + packet rejection
- **Detection**: Uses Bloom Filters to track sequence numbers
- **Mitigation**: Rejects duplicate/replayed packets

**Parameters**:
```bash
--enable_replay_attack=true
--replay_attack_percentage=0.10
--replay_start_time=10.0
--replay_interval=1.0
--replay_count_per_node=5
--enable_replay_detection=true
--enable_replay_mitigation=true
```

### 5. RTP Attack (Routing Table Poisoning)
**Mitigation**: Hybrid-Shield topology verification + route validation
- **Detection**: Probes verify MHL (Multi-Hop Link) authenticity
- **Mitigation**: Blocks fake route advertisements, validates topology

**Parameters**:
```bash
--enable_rtp_attack=true
--rtp_attack_percentage=0.10
--rtp_start_time=10.0
--enable_hybrid_shield_detection=true
--enable_hybrid_shield_mitigation=true
--hybrid_shield_probe_timeout=100
--hybrid_shield_verification_interval=30.0
```

## Performance Metrics

### Key Metrics Analyzed:
1. **Packet Delivery Ratio (PDR)**: Percentage of successfully delivered packets
2. **End-to-End Delay**: Average latency from source to destination
3. **Throughput**: Data transfer rate (Mbps)
4. **Packet Loss Rate**: Percentage of dropped packets
5. **Attack Detection Rate**: Percentage of detected attack attempts
6. **Mitigation Effectiveness**: PDR improvement after mitigation

## Workflow

### Complete Evaluation Workflow:

```bash
# Step 1: Run complete security evaluation
cd ~/Downloads/ns-allinone-3.35/ns-3.35
./test_sdvn_complete_evaluation.sh

# Step 2: Analyze results
python3 analyze_sdvn_complete_evaluation.py ./sdvn_evaluation_TIMESTAMP/

# Step 3: Review generated visualizations
cd sdvn_evaluation_TIMESTAMP/analysis_output/
ls -l  # View all generated files

# Step 4: Include LaTeX tables in your paper
cat summary_table.tex
cat comparison_table.tex
```

### Diagnostic Workflow (for Replay/RTP issues):

```bash
# Step 1: Run diagnostic tests
./test_replay_rtp_only.sh

# Step 2: Review diagnostic report
cat replay_rtp_test_TIMESTAMP/diagnostic_report.txt

# Step 3: Check individual test logs
cd replay_rtp_test_TIMESTAMP/
ls -la */
cat rtp_with_mitigation/rtp_mitigation.log
```

## Expected Results

### Without Mitigation:
- **Wormhole**: PDR degradation due to tunneling
- **Blackhole**: Significant packet loss
- **Sybil**: Network confusion, routing errors
- **Replay**: Duplicate packets, resource exhaustion
- **RTP**: Routing disruption, fake topology

### With Full Mitigation:
- **PDR Recovery**: Near-baseline delivery ratio
- **Delay Stabilization**: Consistent latency
- **Attack Isolation**: Malicious nodes identified and isolated
- **Network Resilience**: Continued operation under attack

## Troubleshooting

### Common Issues:

1. **Test fails with "unknown option"**
   - Check parameter names in `routing.cc`
   - Verify NS-3 build is up to date: `./waf build`

2. **No CSV files generated**
   - Check log files for errors
   - Verify `--enable_packet_tracking=true` is set
   - Ensure simulation completes without crashes

3. **Mitigation not activated**
   - Confirm both detection AND mitigation flags are set
   - Check log files for mitigation messages
   - Verify attack percentage > 0

4. **Analysis script errors**
   - Install required Python packages: `pip3 install pandas numpy matplotlib seaborn`
   - Check CSV file format matches expected columns
   - Review analysis_report.txt for details

## File Structure

```
ns-3.35/
├── test_sdvn_complete_evaluation.sh      # Complete 17-test evaluation
├── analyze_sdvn_complete_evaluation.py   # Analysis with visualizations
├── test_replay_rtp_only.sh               # Enhanced Replay/RTP diagnostic
├── analyze_attack_results.py             # Original analysis (enhanced)
├── test_sdvn_attacks.sh                  # Original 9-test script
├── sdvn_evaluation_TIMESTAMP/            # Complete evaluation results
│   ├── test01_baseline/
│   ├── test02_wormhole_10_no_mitigation/
│   ├── test03_wormhole_10_with_detection/
│   ├── test04_wormhole_10_with_mitigation/
│   ├── ... (13 more test directories)
│   ├── analysis_output/                  # Generated analysis
│   │   ├── pdr_comparison.png
│   │   ├── mitigation_effectiveness.png
│   │   ├── attack_impact.png
│   │   ├── overall_improvement.png
│   │   ├── summary_table.tex
│   │   ├── comparison_table.tex
│   │   └── analysis_report.txt
│   └── evaluation_summary.txt
└── replay_rtp_test_TIMESTAMP/            # Diagnostic results
    ├── baseline/
    ├── replay_attack_only/
    ├── replay_with_detection/
    ├── replay_full_mitigation/
    ├── rtp_attack_only/
    ├── rtp_with_detection/
    ├── rtp_with_mitigation/
    ├── combined_replay_rtp/
    └── diagnostic_report.txt
```

## Research Publication Support

The generated LaTeX tables and visualizations are publication-ready:

1. **summary_table.tex**: Complete metrics for all scenarios
2. **comparison_table.tex**: Before/after mitigation comparison
3. **PNG charts**: High-resolution (300 DPI) for papers

### Example LaTeX Integration:

```latex
\begin{table}[htbp]
\caption{SDVN Security Evaluation Results}
\label{tab:evaluation}
\input{summary_table.tex}
\end{table}

\begin{figure}[htbp]
\centering
\includegraphics[width=0.8\textwidth]{mitigation_effectiveness.png}
\caption{Mitigation Effectiveness Comparison}
\label{fig:mitigation}
\end{figure}
```

## Conclusion

This comprehensive evaluation framework provides:
- ✅ Complete testing of all 5 SDVN data plane attacks
- ✅ Three-phase testing (no mitigation, detection, full mitigation)
- ✅ Automated performance analysis and visualization
- ✅ Publication-ready outputs (LaTeX tables, high-res charts)
- ✅ Diagnostic tools for troubleshooting
- ✅ Detailed documentation and workflow guidance

For questions or issues, review the log files and diagnostic reports first, then check parameter configurations in `routing.cc`.

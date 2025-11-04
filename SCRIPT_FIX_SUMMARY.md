# SDVN Test Script Fix - Issue Analysis and Resolution

## 🔴 Problem Identified

The `test_sdvn_attacks.sh` script was **completely corrupted** and would not run on Ubuntu.

### Critical Issues Found:

1. **Duplicated Shebang Line**
   ```bash
   #!/bin/bash#!/bin/bash  # ❌ WRONG - duplicated
   ```
   Should be:
   ```bash
   #!/bin/bash  # ✅ CORRECT
   ```

2. **Lines Merged Together**
   Comments and code were concatenated on the same lines:
   ```bash
   RED='\033[0;31m'# Colors for output
   GREEN='\033[0;32m'RED='\033[0;31m'
   ```

3. **Function Definitions Broken**
   Functions were redefined multiple times with code mixed in:
   ```bash
   print_header() {# Configuration
       echo ""NS3_PATH="${NS3_PATH:-.}"
   ```

4. **Duplicate Variable Definitions**
   Variables like `RED`, `GREEN`, etc. were defined twice

5. **Syntax Errors Throughout**
   The entire file structure was corrupted, making it unparseable by bash

## ✅ Solution Applied

**Created a completely new, clean version** of the script based on the working reference (`test_sdvn_attacks_before.sh`).

### Files Created:
- `test_sdvn_attacks.sh` - **NEW FIXED VERSION** (clean, working script)
- `test_sdvn_attacks_CORRUPTED.sh` - Backup of the corrupted file (for reference)

### What the Fixed Script Does:

#### 7 Test Scenarios:
1. **Baseline** - No attacks (establish performance baseline)
2. **Wormhole 10%** - 10% malicious data plane nodes creating fake tunnels
3. **Wormhole 20%** - 20% malicious nodes (higher attack intensity)
4. **Blackhole 10%** - 10% nodes dropping packets silently
5. **Blackhole 20%** - 20% packet-dropping nodes
6. **Sybil 10%** - 10% nodes with fake identities
7. **Combined** - All three attacks at 10% each

#### Key Parameters Used (SDVN Data Plane Attacks):
```bash
--architecture=0                          # Centralized SDVN
--present_wormhole_attack_nodes=true      # SDVN wormhole (not enable_wormhole_attack)
--present_blackhole_attack_nodes=true     # SDVN blackhole (not enable_blackhole_attack)
--present_sybil_attack_nodes=true         # SDVN sybil (not enable_sybil_attack)
--attack_percentage=0.1                   # 10% of nodes compromised
--enable_wormhole_detection=true          # Controller detects attacks
--enable_wormhole_mitigation=true         # Controller mitigates attacks
```

#### Features:
- ✅ Color-coded output (RED/GREEN/YELLOW/BLUE)
- ✅ Proper error handling
- ✅ CSV file collection after each test
- ✅ Automatic summary report generation
- ✅ Individual log files per test
- ✅ Exit on test failure for debugging

## 🚀 How to Use on Ubuntu

### Step 1: Pull Latest Changes
```bash
cd ~/Downloads/ns-allinone-3.35/ns-3.35
git pull origin main
```

### Step 2: Make Script Executable
```bash
chmod +x test_sdvn_attacks.sh
```

### Step 3: Run the Tests
```bash
./test_sdvn_attacks.sh
```

### Step 4: View Results
```bash
# Results are saved to timestamped directory
ls -la sdvn_results_*/

# View summary
cat sdvn_results_*/test_summary.txt

# View individual test logs
cat sdvn_results_*/baseline/logs/baseline.log
cat sdvn_results_*/wormhole_10pct/logs/wormhole_10.log
```

## 🔍 What to Expect

### Successful Run Output:
```
================================================================
SDVN DATA PLANE ATTACK TESTING SUITE
================================================================

ℹ Testing compromised data plane nodes in SDVN architecture
ℹ Controllers: TRUSTED | Data Plane Nodes: MALICIOUS
ℹ Results will be saved to: ./sdvn_results_20250104_123456

================================================================
TEST 1: BASELINE (No Attacks)
================================================================

ℹ Running baseline SDVN simulation...
✓ Baseline test completed
✓ baseline - collected 5 file(s)

================================================================
TEST 2: WORMHOLE ATTACK - 10% Malicious Data Plane Nodes
================================================================
...
```

### Results Directory Structure:
```
sdvn_results_20250104_123456/
├── baseline/
│   ├── logs/
│   │   └── baseline.log
│   ├── packet-delivery-analysis.csv
│   └── DlRsrpSinrStats.txt
├── wormhole_10pct/
│   ├── logs/
│   │   └── wormhole_10.log
│   └── *.csv files
├── wormhole_20pct/
├── blackhole_10pct/
├── blackhole_20pct/
├── sybil_10pct/
├── combined_10pct/
└── test_summary.txt  ← Comprehensive summary report
```

## ⚠️ Important Notes

### SDVN vs VANET Parameters
The script uses **SDVN data plane attack parameters**, not VANET parameters:

| ❌ WRONG (VANET) | ✅ CORRECT (SDVN) |
|------------------|-------------------|
| `--enable_wormhole_attack=true` | `--present_wormhole_attack_nodes=true` |
| `--enable_blackhole_attack=true` | `--present_blackhole_attack_nodes=true` |
| `--enable_sybil_attack=true` | `--present_sybil_attack_nodes=true` |

### Controllers are TRUSTED
In SDVN data plane attacks:
- ✅ SDN **controllers** are TRUSTED (not compromised)
- ❌ Data plane **nodes** (vehicles/RSUs) are COMPROMISED
- ✅ Controllers **detect and mitigate** attacks from nodes

This is different from controller-level attacks where the controllers themselves are malicious.

## 🛠️ Troubleshooting

### If Script Still Fails on Ubuntu:

1. **Check Line Endings**
   ```bash
   # Convert Windows line endings to Unix
   dos2unix test_sdvn_attacks.sh
   ```

2. **Verify NS-3 is Built**
   ```bash
   ./waf build
   ```

3. **Check routing.cc is in scratch/**
   ```bash
   ls -la scratch/routing.cc
   ```

4. **Check for Duplicate Parameters in routing.cc**
   The previous fix should have removed duplicate parameter declarations.

5. **Run Individual Test Manually**
   ```bash
   ./waf --run "scratch/routing \
       --simTime=100 \
       --N_Vehicles=18 \
       --N_RSUs=10 \
       --architecture=0 \
       --enable_packet_tracking=true"
   ```

## 📊 Expected Metrics

After successful run, you should see:

- **Baseline PDR**: ≥85% (good network performance)
- **Attack PDR**: ≤60% (attacks successfully degrade performance)
- **Mitigation PDR**: ≥75% (controllers successfully mitigate attacks)
- **Detection Accuracy**: ≥80% (controllers identify malicious nodes)

## 📝 Summary

**Root Cause**: The original `test_sdvn_attacks.sh` was corrupted with:
- Duplicated shebang
- Merged lines
- Broken functions
- Syntax errors

**Fix Applied**: Complete rewrite with clean structure based on working reference script

**Status**: ✅ **READY TO USE** - Script is now syntactically correct and will run on Ubuntu

**Next Step**: Pull changes, make executable (`chmod +x`), and run `./test_sdvn_attacks.sh`

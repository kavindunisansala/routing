# SDVN Test Script - Quick Fix Guide

## Problem: Script Stops Suddenly

The script was stopping immediately due to these issues:

### Issues Fixed (Commit: b031f1f)

1. **`set -e` was too strict** ✅
   - Removed: This caused script to exit on ANY error (even expected ones)
   - Now: Script continues and shows helpful error messages

2. **Wrong NS3_PATH default** ✅
   - Was: `NS3_PATH="${NS3_PATH:-./build}"` ❌
   - Now: `NS3_PATH="${NS3_PATH:-.}"` (current directory) ✅

3. **Missing error checks** ✅
   - Added: Check if `waf` exists
   - Added: Check if `routing.cc` exists in scratch/
   - Added: Error handling for each simulation
   - Added: Show last 20 lines of log on failure

## How to Run Correctly

### Step 1: Navigate to NS-3 Root Directory
```bash
cd ~/Downloads/ns-allinone-3.35/ns-3.35
```

### Step 2: Ensure routing.cc is in scratch/
```bash
# Check if routing.cc exists
ls scratch/routing.cc

# If not, copy it there
cp /path/to/routing.cc scratch/
```

### Step 3: Make Script Executable
```bash
chmod +x test_sdvn_attacks.sh
```

### Step 4: Run the Script
```bash
./test_sdvn_attacks.sh
```

## Expected Output

```
================================================================
SDVN ATTACK TESTING SUITE
================================================================

ℹ Testing all 5 SDVN attack types and mitigation solutions
ℹ Results will be saved to: ./results_20251104_163652
ℹ Creating results directory: ./results_20251104_163652

================================================================
TEST 1: BASELINE (No Attack)
================================================================

ℹ Running baseline simulation...
ℹ Executing simulation...
✓ Baseline simulation completed
ℹ Baseline Metrics:
  PDR: 0.85
  Latency: 25.3ms
  Overhead: 0.15
...
```

## Troubleshooting

### Error: "waf not found"
**Problem**: You're not in the NS-3 root directory

**Solution**:
```bash
# Find your NS-3 directory
find ~ -name "waf" -type f 2>/dev/null

# Navigate there
cd /path/to/ns-3.35
```

### Error: "routing.cc not found in scratch/"
**Problem**: routing.cc is not in the scratch folder

**Solution**:
```bash
# Check where routing.cc is
find . -name "routing.cc" -type f

# Copy to scratch if found elsewhere
cp ./path/to/routing.cc scratch/

# Or create a symlink
ln -s /path/to/routing.cc scratch/routing.cc
```

### Simulation Fails with Compilation Errors
**Problem**: NS-3 needs to be compiled

**Solution**:
```bash
# Clean build
./waf clean

# Configure
./waf configure

# Build
./waf build

# Then run test script
./test_sdvn_attacks.sh
```

### Script Shows "Simulation failed!"
**Problem**: The simulation encountered an error

**What the script does**:
- Shows last 20 lines of the log file
- Continues to next test (doesn't stop completely)

**To debug**:
```bash
# Check the full log
cat results_*/baseline/logs/baseline.log

# Or just errors
grep -i "error\|fail\|fatal" results_*/baseline/logs/baseline.log
```

## Performance Tips

### Quick Test (Single Attack)
Use the individual test script:
```bash
chmod +x test_individual_attacks.sh

# Test just one attack
./test_individual_attacks.sh wormhole

# Test with mitigation
./test_individual_attacks.sh blackhole with_mitigation
```

### Reduce Simulation Time
Edit the script or use environment variable:
```bash
# Edit SIM_TIME in script (line 21)
SIM_TIME=30  # Reduce from 60 to 30 seconds

# Or modify number of vehicles/RSUs
VEHICLES=10  # Reduce from 18
RSUS=5       # Reduce from 10
```

### Run in Background
```bash
# Run with nohup to continue if SSH disconnects
nohup ./test_sdvn_attacks.sh > test_output.log 2>&1 &

# Check progress
tail -f test_output.log

# Or use screen/tmux
screen -S sdvn_test
./test_sdvn_attacks.sh
# Ctrl+A, D to detach
```

## Understanding Results

### Directory Structure
```
results_20251104_163652/
├── baseline/
│   ├── logs/baseline.log          # Full simulation output
│   ├── csv/baseline_stats.csv     # Metrics in CSV format
│   └── stats/                      # Additional statistics
├── wormhole/
│   ├── logs/
│   │   ├── wormhole_attack.log
│   │   └── wormhole_mitigation.log
│   └── csv/
├── blackhole/
├── sybil/
├── replay/
├── rtp/
└── summary/
    ├── test_summary.txt            # Human-readable summary
    └── metrics_summary.csv         # All metrics in one CSV
```

### Check Results
```bash
# View summary
cat results_*/summary/test_summary.txt

# Check if tests passed
grep -r "PASSED\|FAILED" results_*/

# View specific attack metrics
cat results_*/wormhole/logs/wormhole_attack.log | grep -i "PDR\|latency"
```

## Common Issues and Solutions

| Issue | Cause | Solution |
|-------|-------|----------|
| Script exits immediately | `set -e` was enabled | **Fixed in commit b031f1f** ✅ |
| "waf not found" | Wrong directory | Run from NS-3 root: `cd ns-3.35` |
| "routing.cc not found" | File not in scratch/ | Copy routing.cc to scratch/ folder |
| Compilation errors | Code issues | Check routing.cc syntax, run `./waf build` |
| No output files | Simulation crash | Check logs in results_*/*/logs/*.log |
| Permission denied | Script not executable | Run `chmod +x test_sdvn_attacks.sh` |

## What Changed in the Fix

### Before (BROKEN):
```bash
set -e  # Exit immediately on any error ❌
NS3_PATH="${NS3_PATH:-./build}"  # Wrong path ❌

./waf --run "..."  # No error handling ❌
# Script stops silently ❌
```

### After (FIXED):
```bash
# No set -e - handle errors explicitly ✅
NS3_PATH="${NS3_PATH:-.}"  # Correct: current directory ✅

# Check waf exists
if [ ! -f "waf" ]; then
    print_error "waf not found!"
    exit 1
fi

# Run with error handling
./waf --run "..." > log 2>&1 || {
    print_error "Failed! Check log:"
    tail -20 log  # Show last 20 lines ✅
    return 1
}

# Continue testing even if one fails ✅
```

## Next Steps

1. **Pull latest changes**:
   ```bash
   git pull origin main
   ```

2. **Try running again**:
   ```bash
   cd ~/Downloads/ns-allinone-3.35/ns-3.35
   ./test_sdvn_attacks.sh
   ```

3. **If it still stops**, check:
   - Is `routing.cc` in `scratch/` folder?
   - Does `./waf build` work without errors?
   - Can you run: `./waf --run "scratch/routing --simTime=10"` manually?

4. **For quick debugging**:
   ```bash
   # Test NS-3 is working
   ./waf --run "scratch/routing --simTime=5 --N_Vehicles=5 --N_RSUs=2"
   
   # If that works, the test script should work too
   ```

## Contact

If you still have issues after these fixes:
1. Check the log file: `cat results_*/baseline/logs/baseline.log`
2. Share the error message
3. Confirm: `pwd` (should show ns-3.35 directory)
4. Confirm: `ls scratch/routing.cc` (should exist)

---
**Last Updated**: November 4, 2025  
**Fix Commit**: b031f1f  
**Status**: ✅ Ready to use

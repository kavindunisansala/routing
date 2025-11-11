# Validation Scripts Quick Reference

## Overview
Two validation scripts have been created to test all fixed issues:
- `validate_fixes.sh` - For Linux/Unix systems
- `validate_fixes.ps1` - For Windows PowerShell

---

## What These Scripts Do

### 1. **Environment Check**
- Verify NS-3 installation directory exists
- Confirm routing.cc is in the scratch directory
- Ensure build environment is ready

### 2. **Build Project**
- Compile the latest routing.cc with all fixes
- Check for compilation errors
- Generate build logs

### 3. **Run All Tests**
The scripts validate 7 critical fixes by running 17 tests:

| Fix # | Description | Tests | Commit |
|-------|-------------|-------|--------|
| 1 | Baseline Performance | Test 1 | - |
| 2 | Wormhole Timing Fix | Tests 2-4 | e91023f |
| 3 | **Blackhole Infrastructure Protection** ⭐ | **Tests 5-7** | **fe878e4** |
| 4 | Sybil Detection | Tests 8-10 | 16fa1ca |
| 5 | Replay Detection | Tests 11-13 | 16fa1ca |
| 6 | **RTP Probe Verification** ⭐ | **Tests 14-16** | **0aae467** |
| 7 | Combined Scenario | Test 17 | - |

### 4. **Validate Results**
For each fix, the script checks:
- **PDR (Packet Delivery Ratio)** meets thresholds
- **Detection logs** are present (where applicable)
- **Comparison** between scenarios (e.g., Test05 vs Test06)
- **Specific metrics** (e.g., ProbePacketsSent > 0 for RTP)

### 5. **Generate Reports**
- Color-coded console output (✅ success, ❌ failed, ⚠️ warning)
- Detailed logs for each test
- Summary report with pass/fail status

---

## Usage

### Linux/Unix (Bash):

```bash
# Make executable
chmod +x validate_fixes.sh

# Run validation
./validate_fixes.sh

# Results will be in: validation_results_YYYYMMDD_HHMMSS/
```

### Windows (PowerShell):

```powershell
# Allow script execution (first time only)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Run validation
.\validate_fixes.ps1

# Results will be in: validation_results_YYYYMMDD_HHMMSS\
```

---

## Configuration

Before running, update these variables if needed:

**Linux (`validate_fixes.sh`):**
```bash
NS3_DIR="${HOME}/Downloads/ns-allinone-3.35/ns-3.35"
```

**Windows (`validate_fixes.ps1`):**
```powershell
$NS3_DIR = "$env:USERPROFILE\Downloads\ns-allinone-3.35\ns-3.35"
```

---

## Expected Results

### ✅ Passing Criteria:

| Test | Scenario | Minimum PDR | Critical? |
|------|----------|-------------|-----------|
| 1 | Baseline | 99% | Yes |
| 2 | Wormhole No Miti | 90% | No |
| 3-4 | Wormhole Detection/Miti | 95% | Yes |
| 5 | Blackhole No Miti | 60% | No |
| **6** | **Blackhole Detection** | **70%** | **⭐ CRITICAL** |
| 7 | Blackhole Miti | 85% | Yes |
| 8 | Sybil No Miti | 90% | No |
| 9-10 | Sybil Detection/Miti | 95% | Yes |
| 11-13 | Replay | 99% | Yes |
| 14 | RTP No Miti | 99% | No |
| 15 | RTP Detection | 85% | Yes |
| 16 | RTP Miti | 90% | Yes |
| 17 | Combined | 90% | Yes |

### 🎯 Critical Validations:

1. **Test06 (Blackhole Detection):**
   - OLD: 31.58% PDR ❌
   - **EXPECTED: >70% PDR** ✅
   - Must be comparable to Test05 (within 5%)
   - Should see "Protected infrastructure nodes" in logs

2. **Test15 (RTP Detection):**
   - OLD: ProbePacketsSent = 0 ❌
   - **EXPECTED: ProbePacketsSent > 0** ✅
   - Should see "Sending probe packet" in logs
   - Should see "MHL appears FABRICATED" in logs

---

## Output Structure

```
validation_results_20251106_123456/
├── test01_baseline/
│   └── output.log
├── test02_wormhole_no_mitigation/
│   └── output.log
├── test06_blackhole_detection/
│   └── output.log              ← Critical test!
├── test15_rtp_detection/
│   └── output.log              ← Critical test!
├── test17_combined_all_mitigations/
│   └── output.log
└── validation_summary.txt       ← Final report
```

---

## Interpreting Results

### ✅ All Tests Pass:
```
✅ Baseline test passed: PDR = 100.0%
✅ Test 3 (Detection): PDR = 98.42%
✅ Test 6 (Detection): PDR = 73.68% ⭐ CRITICAL FIX!
✅ Infrastructure protection fix is working!
✅ ProbePacketsSent: 1 (was 0 before fix) ⭐
✅ RTP probe verification fix validated successfully!

Validation Tests Passed: 7 / 7
✅ ALL FIXES VALIDATED SUCCESSFULLY! 🎉
```

### ❌ Test06 Still Fails:
```
❌ Test 6 (Detection): PDR = 35.21% (expected >= 70%) ⭐ CRITICAL!
❌ Test06 still significantly worse than Test05
❌ Infrastructure protection fix may not be working correctly
```

**Action:** Check if routing.cc was properly transferred with all changes.

### ⚠️ Partial Success:
```
⚠️  Test 17 (Combined): PDR = 88.45% (expected >= 90%)
⚠️  Combined scenario could be improved with MitigationCoordinator

Validation Tests Passed: 6 / 7
⚠️  MOST FIXES VALIDATED (6/7)
```

**Action:** Optional enhancement, not critical.

---

## Troubleshooting

### Build Fails:
```bash
# Check NS-3 directory
ls -la ~/Downloads/ns-allinone-3.35/ns-3.35/scratch/routing.cc

# Verify file size (should be ~5.5MB with all fixes)
du -h ~/Downloads/ns-allinone-3.35/ns-3.35/scratch/routing.cc

# Check for compilation errors
cat validation_results_*/build.log
```

### Test Hangs:
- Kill process: `Ctrl+C`
- Check simulation time in routing.cc (should be 100s)
- Verify no infinite loops

### PDR Extraction Fails:
- Open `test**/output.log` manually
- Search for "Packet Delivery Ratio"
- Verify metrics are being printed

---

## Manual Validation (If Scripts Fail)

Run tests individually:

```bash
cd ~/Downloads/ns-allinone-3.35/ns-3.35

# Critical Test 1: Blackhole Detection
./waf --run "routing --test=6" > test06.log 2>&1
grep "Packet Delivery Ratio" test06.log
grep "Protected infrastructure" test06.log

# Critical Test 2: RTP Detection
./waf --run "routing --test=15" > test15.log 2>&1
grep "Probe Packets Sent" test15.log
grep "Sending probe packet" test15.log
```

---

## What Gets Validated

### Fix 1: Baseline ✅
- Confirms network operates correctly without attacks
- PDR should be 100%

### Fix 2: Wormhole Timing (e91023f) ✅
- **Before:** PDR 0% (attacks started before network ready)
- **After:** PDR >95% (attacks delayed to 10s)
- Validates: Tests 2-4

### Fix 3: Blackhole Infrastructure (fe878e4) ⭐ CRITICAL
- **Before:** Test06 PDR 31.58% (RSU node selected as attacker)
- **After:** Test06 PDR >70% (RSU nodes protected)
- Validates: 
  - RSU protection working
  - Fixed seed reproducibility
  - Test06 comparable to Test05
  - Infrastructure logs present

### Fix 4: Sybil Detection (16fa1ca) ✅
- Validates identity verification works
- PDR: 96.49% → 99.12%
- Validates: Tests 8-10

### Fix 5: Replay Detection (16fa1ca) ✅
- Validates Bloom Filter detection
- PDR maintains 100%
- Detection events logged
- Validates: Tests 11-13

### Fix 6: RTP Probe Verification (0aae467) ⭐ CRITICAL
- **Before:** ProbePacketsSent = 0 (not working)
- **After:** ProbePacketsSent > 0 (working)
- Validates:
  - Probes being sent
  - MHL fabrication detection
  - Topological analysis working
- Validates: Tests 14-16

### Fix 7: Combined Scenario ✅
- Validates all mitigations work together
- PDR should be >90%
- Multiple detection systems active
- Validates: Test 17

---

## Success Criteria Summary

**Minimum Requirements:**
- 5/7 validation groups must pass
- Test06 (Blackhole) MUST pass ⭐
- Test15 (RTP Probes) MUST pass ⭐

**Full Success:**
- 7/7 validation groups pass
- All PDR thresholds met
- All detection mechanisms active
- Infrastructure protection confirmed

**Experiment Satisfaction:**
- ✅ Baseline: 100% PDR
- ✅ Attacks demonstrate impact
- ✅ Detection mechanisms work
- ✅ Mitigation effectiveness proven
- ✅ Combined scenario >90% PDR

---

## Next Steps After Validation

### If All Pass ✅:
1. Commit validation results
2. Generate final evaluation report
3. Update documentation
4. Consider publishing results

### If Test06 Fails ❌:
1. Verify routing.cc transfer
2. Check for compilation warnings
3. Review infrastructure protection code (lines 150019-150097)
4. Verify random_seed parameter (line 2844)

### If Test15 Fails ❌:
1. Review RTP detection code
2. Check MHL detection logic
3. Verify synthetic probe mechanism
4. Analyze topology detection thresholds

---

## Additional Information

**Script Features:**
- ✅ Color-coded output for easy reading
- ✅ Detailed logging for each test
- ✅ Automatic pass/fail determination
- ✅ Infrastructure protection verification
- ✅ Probe count verification
- ✅ Comparative analysis (Test05 vs Test06)
- ✅ Summary report generation

**Time Estimate:**
- Environment check: 1 second
- Build: 2-5 minutes
- Each test: 2-3 minutes
- **Total runtime: ~30-40 minutes for all 17 tests**

**Resource Usage:**
- Disk space: ~100MB for results
- Memory: ~500MB during simulation
- CPU: Single core per test

---

## Contact & Support

If validation fails unexpectedly:
1. Check logs in `validation_results_*/`
2. Review `EVALUATION_STATUS_REPORT.md`
3. Compare with `sdvn_evaluation_20251106_073236/`
4. Verify routing.cc matches commit fe878e4

**Key Files:**
- `routing.cc` - Main simulation (153,528 lines)
- `validate_fixes.sh` - Linux validation script
- `validate_fixes.ps1` - Windows validation script
- `EVALUATION_STATUS_REPORT.md` - Detailed status report
- `comprehensive_evaluation_check.py` - Analysis tool

---

## Quick Commands

```bash
# Full validation (Linux)
chmod +x validate_fixes.sh && ./validate_fixes.sh

# Full validation (Windows)
.\validate_fixes.ps1

# Quick check single test (Linux)
cd ~/Downloads/ns-allinone-3.35/ns-3.35
./waf --run "routing --test=6" | tee test06_quick.log
grep "PDR\|Protected" test06_quick.log

# View results
cat validation_results_*/validation_summary.txt

# Compare with old results
python comprehensive_evaluation_check.py sdvn_evaluation_20251106_073236
```

---

## Version History

- **v1.0** - November 6, 2025
  - Initial release
  - Validates 7 fix groups across 17 tests
  - Bash and PowerShell versions
  - Critical focus: Test06 (Blackhole) and Test15 (RTP)

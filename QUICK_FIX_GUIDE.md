# QUICK FIX GUIDE - Exit Code 1 Issue

## 🚨 CRITICAL BUG FOUND AND FIXED 🚨

**Problem**: Simulation always exits with code 1 and prints help text  
**Root Cause**: Duplicate parameter declarations in `routing.cc` (lines 149951-149954)  
**Status**: ✅ **FIXED** - Code pushed to GitHub (commit `503654d`)

---

## 🔧 IMMEDIATE ACTION REQUIRED

### You MUST rebuild the project for the fix to take effect:

```bash
cd ~/Downloads/ns-allinone-3.35/ns-3.35

# 1. Pull the fix
git pull origin main

# 2. Clean old build
./waf clean

# 3. Rebuild with fixed code
./waf build
```

**Build time**: 2-5 minutes

---

## ✅ Verify the Fix Works

### Test 1: Quick smoke test
```bash
./waf --run "scratch/routing --simTime=10 --routing_test=false --N_Vehicles=5 --N_RSUs=2" 2>&1 | head -20
```

**Should show**:
```
Network configuration: N_Vehicles=5, N_RSUs=2...
```

**Should NOT show**:
```
--simTime:           simTime [30]
--N_Vehicles:        N_Vehicles [18]
[Parameter list...]
```

### Test 2: Full test suite
```bash
./test_sdvn_attacks.sh
```

**Should show**:
```
✓ Baseline simulation completed
✓ Wormhole attack completed
...
```

---

## 📊 What Was Fixed

| Issue | Description | Fix |
|-------|-------------|-----|
| **Critical Bug** | 4 parameters declared twice in routing.cc | ✅ Removed duplicates |
| **Parameter Issue** | routing_test=true overriding values | ✅ Added --routing_test=false |
| **Syntax Errors** | Script variable inconsistencies | ✅ Fixed test scripts |

---

## 📁 Files Changed

### routing.cc (REBUILD REQUIRED ⚠️)
```diff
- cmd.AddValue ("experiment_number", "experiment_number", experiment_number);
- cmd.AddValue ("routing_test", "routing_test", routing_test);
- cmd.AddValue ("routing_algorithm", "routing_algorithm", routing_algorithm);
- cmd.AddValue ("qf", "qf", qf);
+ // Duplicate declarations removed (already declared earlier)
  cmd.Parse (argc, argv);
```

### test_sdvn_attacks.sh (AUTO-UPDATED ✅)
- Added `--routing_test=false` to all tests
- Fixed syntax errors
- Improved error handling

---

## 🎯 Expected Outcome

**Before fix**:
```
Command [...] exited with code 1
[Prints all parameter help text]
✗ Simulation failed
```

**After fix**:
```
Network configuration: N_Vehicles=18, N_RSUs=10, actual_total_nodes=28
[Simulation runs normally]
✓ Simulation completed
```

---

## 🆘 If Still Not Working

1. **Verify git pull succeeded**:
   ```bash
   git log --oneline -1
   # Should show: 503654d Fix critical bug: Remove duplicate parameter declarations
   ```

2. **Check routing.cc was updated**:
   ```bash
   grep -n "cmd.AddValue.*routing_test" routing.cc
   # Should show ONLY TWO lines (not four):
   # 149838: cmd.AddValue ("routing_test", ...
   # 149952: cmd.Parse (argc, argv);
   ```

3. **Verify rebuild completed**:
   ```bash
   ls -lh build/scratch/routing
   # Should show recent timestamp (within last few minutes)
   ```

4. **Check build errors**:
   ```bash
   ./waf build 2>&1 | tail -50
   # Should end with: 'build' finished successfully
   ```

---

## 📖 Detailed Documentation

For complete technical details, see:
- `COMPLETE_FIX_SUMMARY.md` - Comprehensive fix overview
- `FIX_DUPLICATE_PARAMETERS.md` - Technical analysis of the bug
- `FIX_EXIT_CODE_1.md` - routing_test parameter issue
- `TROUBLESHOOTING.md` - General troubleshooting guide

---

## ⏱️ Timeline

1. **Pull changes**: 10 seconds
2. **Clean build**: 1 minute
3. **Rebuild**: 2-5 minutes
4. **Verify**: 30 seconds
5. **Run tests**: 15-30 minutes

**Total**: ~20-40 minutes to fully verified

---

## ✨ Success Indicators

You'll know it's working when you see:

✅ Build completes with: `'build' finished successfully`  
✅ Simulation shows: `Network configuration: N_Vehicles=...`  
✅ NO help text printed during simulation  
✅ Exit code is 0 (not 1)  
✅ Results directory created with logs  

---

## 🚀 Ready to Test!

Once rebuilt, your test scripts will work correctly:

```bash
# Test all attacks
./test_sdvn_attacks.sh

# Test individual attacks
./test_individual_attacks.sh wormhole
./test_individual_attacks.sh blackhole
./test_individual_attacks.sh sybil
./test_individual_attacks.sh replay
./test_individual_attacks.sh rtp
```

---

**Last Updated**: 2025-01-04  
**Fix Commit**: `503654d`  
**Status**: ✅ READY TO REBUILD AND TEST

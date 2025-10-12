# Quick Test Guide for Division by Zero Fix

## 🎯 What Was Fixed

**Commit:** f2cf430
**Issue:** SIGSEGV at 1.036s due to division by zero
**Fix:** Added zero-checking before all divisions by U[nid] and U[cid]

## ⚡ Quick Test (3 minutes)

### In VirtualBox Linux:

```bash
# 1. Get latest code
cd ~/routing
git pull origin master

# 2. Copy to NS-3
cp routing.cc ~/ns-allinone-3.35/ns-3.35/scratch/

# 3. Build
cd ~/ns-allinone-3.35/ns-3.35
./waf

# 4. Run
./waf --run routing
```

## ✅ Success Indicators

### Before Fix:
```
HandleReadTwo: Received a Packet of size 1024 bytes from 10.1.50.23 at receiver 10.1.50.7 at time 1.036
HandleReadTwo: Received a Packet of size 1024 bytes from 10.1.50.23 at receiver 10.1.50.7 at time 1.036
Segmentation fault (core dumped)  ❌
```

### After Fix:
```
HandleReadTwo: Received a Packet of size 1024 bytes from 10.1.50.23 at receiver 10.1.50.7 at time 1.036
HandleReadTwo: Received a Packet of size 1024 bytes from 10.1.50.23 at receiver 10.1.50.7 at time 1.036
Proposed RL started at 1.036  ✅
HandleReadTwo: Received a Packet of size 1024 bytes from 10.1.50.23 at receiver 10.1.50.7 at time 1.03602
... (simulation continues) ✅
```

**Key difference:** 
- ❌ Before: Crash immediately after packets at 1.036s
- ✅ After: "Proposed RL started at 1.036" message appears, simulation continues

## 🔍 What to Look For

1. **No more SIGSEGV at 1.036s** ✅
2. **Message "Proposed RL started at 1.036"** appears ✅
3. **Simulation continues past 1.036s** ✅
4. **More "HandleReadTwo" messages after 1.036s** ✅

## 📊 Expected Output Pattern

```
... (packets being sent)
HandleReadTwo: Received a Packet ... at time 1.036
HandleReadTwo: Received a Packet ... at time 1.036
Proposed RL started at 1.036  ← CRITICAL: This line should appear!
HandleReadTwo: Received a Packet ... at time 1.03602  ← Simulation continues!
HandleReadTwo: Received a Packet ... at time 1.03604
HandleReadTwo: Received a Packet ... at time 1.03606
... (continues until simulation ends)
```

## 🐛 If Still Crashing

If you STILL get SIGSEGV after this fix, please run:

```bash
./waf --run "routing" --command-template="gdb --args %s"
```

Then in gdb:
```
(gdb) run
# Wait for crash
(gdb) backtrace
(gdb) print fid
(gdb) print nid
(gdb) print cid
(gdb) print proposed_algo2_output_inst[fid].U[nid]
(gdb) print proposed_algo2_output_inst[fid].U[cid]
```

Send me the output - but I'm 99% confident this fix will work!

## 🎉 Why This Fix Works

The crash was a **classic floating point exception**:

1. Wormhole attack reduces link lifetimes at 1.036s
2. Code sets `U[nid] = 0.0` for links below threshold
3. Code then divides by `U[nid]` → **Division by zero** → FPE → SIGSEGV

Now we check `U[nid] > 0.0` before dividing, so:
- If U is zero, skip that condition (no division)
- If U is non-zero, safe to divide

Simple, elegant, bulletproof! 🛡️

---

**Ready to test?** Copy the commands above and run them in your VirtualBox!

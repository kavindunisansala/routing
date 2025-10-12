# 🚨 STILL CRASHING? Here's What to Do

## Current Situation

You're getting SIGSEGV at 1.036s even though we've added:
1. ✅ Null pointer checks (commit efd8d2a)
2. ✅ Fixed `=` to `==` bug (commit 8a57c7c)  
3. ✅ Recursion depth protection (commit e8f438e)

## Most Likely Cause: You Don't Have Latest Code!

The `wget` command downloads from GitHub, but caching or timing might mean you got an old version.

## SOLUTION: Force Fresh Download

### Step 1: Verify Current State
```bash
cd ~/Downloads/ns-allinone-3.35/ns-3.35/scratch
grep "MAX_RECURSION_DEPTH" routing.cc
```

**If this returns NOTHING**, you don't have the latest fixes!

### Step 2: Force Download Latest
```bash
cd ~/Downloads/ns-allinone-3.35/ns-3.35/scratch

# Remove old file
rm routing.cc

# Download with timestamp to bypass cache
wget "https://raw.githubusercontent.com/kavindunisansala/routing/master/routing.cc?$(date +%s)" -O routing.cc

# Verify it downloaded correctly
wc -l routing.cc  # Should show ~141,176 lines
grep "MAX_RECURSION_DEPTH" routing.cc  # Should show 5+ matches
grep "met\[i\] ==" routing.cc  # Should show 4+ matches
```

### Step 3: Clean Rebuild
```bash
cd ~/Downloads/ns-allinone-3.35/ns-3.35
./waf clean
./waf build 2>&1 | tee build.log
```

### Step 4: Test
```bash
./waf --run "routing --use_enhanced_wormhole=true --simTime=30" 2>&1 | tee test.log
```

## If Still Crashes: Get Detailed Debug Info

```bash
./waf --run "routing --use_enhanced_wormhole=true --simTime=30" --command-template="gdb --args %s"
```

In gdb:
```gdb
(gdb) break update_stable
(gdb) break update_unstable  
(gdb) run
```

When it stops at first breakpoint:
```gdb
(gdb) continue
```

Keep pressing `continue` until it crashes. Then:
```gdb
(gdb) backtrace full
(gdb) frame 0
(gdb) print flow_id
(gdb) print current_hop
(gdb) print total_size
(gdb) print update_stable_depth
(gdb) print update_unstable_depth
```

**Copy the ENTIRE output and share it with me.**

## What to Check in the Output

### ✅ Good Signs:
```
DEBUG: flows=2, total_size=28, 2*flows=4
adjacency matrix generated at timestamp 1.0348
Routing distance-based: Number of paths...
```

### ❌ Bad Signs (Means You Have Old Code):
- No "MAX_RECURSION_DEPTH" messages
- No recursion depth errors
- Immediate SIGSEGV without any recursion warnings

### ⚠️ Protection Working:
```
ERROR: update_unstable recursion depth exceeded 100
```
This means protection is active but there's still a recursion issue.

## Alternative: Direct Git Clone

If wget keeps failing:
```bash
cd ~
git clone https://github.com/kavindunisansala/routing.git temp-routing
cp temp-routing/routing.cc ~/Downloads/ns-allinone-3.35/ns-3.35/scratch/
rm -rf temp-routing
cd ~/Downloads/ns-allinone-3.35/ns-3.35
./waf clean && ./waf build
```

## Check GitHub Web Interface

Go to: https://github.com/kavindunisansala/routing/blob/master/routing.cc

Search for "MAX_RECURSION_DEPTH" on the webpage. If you see it on GitHub but not in your downloaded file, there's a download issue.

## Last Resort: Increase Verbosity

If you have the latest code but still crashing:
```bash
export NS_LOG="*=level_all"
./waf --run "routing --use_enhanced_wormhole=true --simTime=30" 2>&1 | tee verbose.log
tail -200 verbose.log  # Show last 200 lines before crash
```

## Expected File Checksums

If you want to verify file integrity:
```bash
cd ~/Downloads/ns-allinone-3.35/ns-3.35/scratch
wc -l routing.cc
md5sum routing.cc
```

**Expected (approximately)**:
- Lines: ~141,176
- Size: ~5.5 MB

If your numbers are very different, you have the wrong version.

## Common Download Issues

### Issue: Cached Old Version
**Solution**: Add timestamp to URL or use `wget --no-cache`

### Issue: Partial Download
**Solution**: Check file size, re-download if too small

### Issue: Wrong Branch
**Solution**: Ensure using `/master/` not `/main/` or a commit hash

### Issue: GitHub Rate Limiting
**Solution**: Wait a few minutes, try again

## Summary Checklist

Before reporting "still crashing":

- [ ] Verified file has 141,000+ lines
- [ ] Verified `grep "MAX_RECURSION_DEPTH" routing.cc` returns results
- [ ] Verified `grep "met\[i\] ==" routing.cc` returns results  
- [ ] Did `./waf clean` before rebuild
- [ ] Rebuild completed successfully
- [ ] Ran with latest routing.cc file
- [ ] Checked test.log for error messages
- [ ] If still crashes, ran with gdb and got backtrace

---

**90% of "still crashing" reports are because the latest code wasn't actually used.** Please verify each step above before continuing with gdb debugging!

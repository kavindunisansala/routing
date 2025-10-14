# 🔧 Compilation Error Fix

## ❌ Error Message:
```
/usr/bin/ld: scratch/routing.cc.3.o: in function `GetIpFromNodeId(unsigned int)':
/home/kanisa/Downloads/ns-allinone-3.35/ns-3.35/build/../scratch/routing.cc:476:(.text+0x2a9): undefined reference to `Nodes'
```

## 🔍 Root Cause:

The error indicates that the **Linux version** of `routing.cc` has a different version than the **Windows version**. 

Specifically:
- Linux version has a function `GetIpFromNodeId()` that references undefined variable `Nodes`
- Windows version (d:\routing - Copy\routing.cc) does **NOT** have this function
- The files are **out of sync**!

## ✅ Solution:

You need to **recopy the latest version** from Windows to Linux.

---

## 🚀 Step-by-Step Fix:

### Step 1: Verify Windows Version is Correct

On **Windows PowerShell**:
```powershell
cd "d:\routing - Copy"

# Check the file has the detection hooks
Select-String -Path routing.cc -Pattern "g_packetIdCounter" -Context 2,2
Select-String -Path routing.cc -Pattern "RecordPacketSent" -Context 1,1
Select-String -Path routing.cc -Pattern "RecordPacketReceived" -Context 1,1
```

Expected output: Should show the detection hooks we added.

### Step 2: Copy to Linux

**Option A: Using Git (Recommended)**

On **Linux terminal**:
```bash
cd ~/Downloads/ns-allinone-3.35/ns-3.35/scratch

# Pull latest from GitHub
git clone https://github.com/kavindunisansala/routing.git temp_routing
cp temp_routing/routing.cc ./routing.cc
rm -rf temp_routing

# Verify the file
grep "g_packetIdCounter" routing.cc
grep "RecordPacketSent" routing.cc
```

**Option B: Using SCP/File Transfer**

If you have file sharing between Windows and Linux:
```bash
# On Linux
cd ~/Downloads/ns-allinone-3.35/ns-3.35/scratch
cp /path/to/windows/share/routing.cc ./routing.cc
```

**Option C: Manual Copy-Paste**

1. On Windows: Open `d:\routing - Copy\routing.cc` in a text editor
2. Copy the entire contents (Ctrl+A, Ctrl+C)
3. On Linux: 
   ```bash
   nano ~/Downloads/ns-allinone-3.35/ns-3.35/scratch/routing.cc
   ```
4. Delete all content and paste the Windows version
5. Save (Ctrl+O, Enter, Ctrl+X)

### Step 3: Verify File Sync

On **Linux**:
```bash
cd ~/Downloads/ns-allinone-3.35/ns-3.35/scratch

# Check file size (should be ~142,800 lines)
wc -l routing.cc

# Check for detection hooks
grep -n "g_packetIdCounter" routing.cc
grep -n "RecordPacketSent" routing.cc
grep -n "RecordPacketReceived" routing.cc
```

Expected output:
```
142838 routing.cc  (or similar line count)

443:static uint32_t g_packetIdCounter = 0;
113330:    g_wormholeDetector->RecordPacketSent(packetId, sourceIp, destination);
96568:    g_wormholeDetector->RecordPacketReceived(packetId, sourceIp, destIp);
```

### Step 4: Clean Build

On **Linux**:
```bash
cd ~/Downloads/ns-allinone-3.35/ns-3.35

# Clean previous build
./waf clean

# Rebuild
./waf
```

Expected output: **Successful compilation** with no errors!

---

## 🔍 Why This Happened:

The `GetIpFromNodeId` function was mentioned in documentation files (DETECTION_HOOKS_MISSING.md) but was **never supposed to be added** to the actual code. 

It seems an earlier version or manual edit added this function to the Linux file, which is why:
- ✅ Windows version is correct (no GetIpFromNodeId)
- ❌ Linux version has incorrect function
- 🔄 Need to resync

---

## ✅ Verification Checklist:

After copying and rebuilding:

- [ ] `routing.cc` on Linux has **same line count** as Windows (~142,800 lines)
- [ ] `grep "GetIpFromNodeId" routing.cc` returns **NO RESULTS**
- [ ] `grep "g_packetIdCounter" routing.cc` returns **1 result** (line ~443)
- [ ] `grep "RecordPacketSent" routing.cc` returns results (detection hooks)
- [ ] `./waf` compiles **successfully**
- [ ] `./waf --run routing` runs without errors

---

## 🎯 Alternative: Quick GitHub Pull

Since all fixes are committed to GitHub, the easiest solution:

```bash
# On Linux - fresh pull from GitHub
cd ~
rm -rf routing_temp
git clone https://github.com/kavindunisansala/routing.git routing_temp

# Copy to ns-3
cp routing_temp/routing.cc ~/Downloads/ns-allinone-3.35/ns-3.35/scratch/routing.cc

# Clean up
rm -rf routing_temp

# Verify
cd ~/Downloads/ns-allinone-3.35/ns-3.35
./waf clean
./waf
```

This guarantees you get the latest correct version!

---

## 📊 Expected Result After Fix:

```
kanisa@kanisa-VirtualBox:~/Downloads/ns-allinone-3.35/ns-3.35$ ./waf
Waf: Entering directory `/home/kanisa/Downloads/ns-allinone-3.35/ns-3.35/build'
[2535/2535] Linking build/scratch/routing
Waf: Leaving directory `/home/kanisa/Downloads/ns-allinone-3.35/ns-3.35/build'
Build commands will be stored in build/compile_commands.json
'build' finished successfully (42.531s)
```

✅ **No errors!** Ready to run detection tests!

---

## 💡 Pro Tip: Keep Files in Sync

To avoid this issue in the future:

1. **Always use GitHub as single source of truth**
2. **Pull from GitHub to Linux** rather than manual copying
3. **Check file sizes match** between Windows and Linux
4. **Use `git diff`** to verify files are identical

```bash
# Check if files match
cd ~/Downloads/ns-allinone-3.35/ns-3.35/scratch
git clone https://github.com/kavindunisansala/routing.git temp
diff routing.cc temp/routing.cc
# No output = files are identical!
```

---

**Fix the file sync issue using one of the methods above, then recompile!** ✅

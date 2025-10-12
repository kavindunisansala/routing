# Quick Fix Commands - Copy & Paste Ready

## 🚀 THE FASTEST WAY (30 seconds)

Copy and paste these commands into your **VirtualBox Linux terminal**:

```bash
# Navigate to home and clone repo
cd ~
git clone https://github.com/kavindunisansala/routing.git

# Copy complete file to NS-3
cp ~/routing/routing.cc ~/Downloads/ns-allinone-3.35/ns-3.35/scratch/

# Verify file copied correctly (should show 141184)
wc -l ~/Downloads/ns-allinone-3.35/ns-3.35/scratch/routing.cc

# Build and run
cd ~/Downloads/ns-allinone-3.35/ns-3.35
./waf
./waf --run routing
```

## ✅ What You Should See

### Step 1: After git clone
```
Cloning into 'routing'...
remote: Enumerating objects...
Receiving objects: 100% (XX/XX), done.
```

### Step 2: After wc -l
```
141184 /home/kanisa/Downloads/ns-allinone-3.35/ns-3.35/scratch/routing.cc  ✅
```
**If you see 46023 or any other number, the copy FAILED!**

### Step 3: After ./waf (first time)
```
Waf: Entering directory...
[2535/2535] Compiling scratch/routing.cc  ✅
Waf: Leaving directory...
'build' finished successfully
```
**No compilation errors!**

### Step 4: After ./waf --run routing
```
... (network setup messages)
HandleReadTwo: Received a Packet ... at time 1.036
HandleReadTwo: Received a Packet ... at time 1.036
Proposed RL started at 1.036  ← THIS IS THE KEY LINE!
HandleReadTwo: Received a Packet ... at time 1.03602
... (simulation continues - NO CRASH!) ✅
```

## ❌ What You Should NOT See

```
Segmentation fault (core dumped)  ← Should NOT appear at 1.036s!
```

```
46023 routing.cc  ← File is incomplete!
```

```
error: expected initializer at end of input  ← File is truncated!
```

## 🔍 Troubleshooting

### If git clone fails:
```bash
# Your VirtualBox might not have internet
# Try: Settings → Network → Adapter 1 → NAT
# Then retry git clone
```

### If repo already exists:
```bash
cd ~/routing
git pull origin master
cp routing.cc ~/Downloads/ns-allinone-3.35/ns-3.35/scratch/
```

### If file still shows wrong line count:
```bash
# Check if git repo has complete file
wc -l ~/routing/routing.cc

# Should show: 141184 /home/kanisa/routing/routing.cc
# If it shows 141184, then copy again:
cp ~/routing/routing.cc ~/Downloads/ns-allinone-3.35/ns-3.35/scratch/
```

## 📊 File Size Reference

**Complete file should be:**
- Lines: 141,184
- Size: ~4.5 MB
- Last line: `}` (closing brace of main function)

## 💡 Pro Tip

Save these commands in a script for future updates:

```bash
# Create update script
cat > ~/update_routing.sh << 'EOF'
#!/bin/bash
cd ~/routing
git pull origin master
cp routing.cc ~/Downloads/ns-allinone-3.35/ns-3.35/scratch/
cd ~/Downloads/ns-allinone-3.35/ns-3.35
./waf
EOF

chmod +x ~/update_routing.sh

# Now you can update anytime with:
~/update_routing.sh
```

---

**Just copy the commands from the top and you'll be running in 30 seconds!** 🚀

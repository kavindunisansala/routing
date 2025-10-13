# 🚀 FINAL VM COMMANDS - Copy & Paste Ready

## Clean Up and Get Latest Code

```bash
# 1. Navigate to routing directory
cd ~/routing

# 2. Pull latest code
git pull origin master

# 3. Copy to NS-3
cp routing.cc ~/Downloads/ns-allinone-3.35/ns-3.35/scratch/
cp wormhole_attack.h ~/Downloads/ns-allinone-3.35/ns-3.35/scratch/
cp wormhole_attack.inc ~/Downloads/ns-allinone-3.35/ns-3.35/scratch/

# 4. Navigate to NS-3
cd ~/Downloads/ns-allinone-3.35/ns-3.35

# 5. Build
./waf

# 6. Run with wormhole (10 seconds)
./waf --run "routing --use_enhanced_wormhole=true --simTime=10"

# 7. Check results
ls -lh wormhole-attack-results.csv
cat wormhole-attack-results.csv
```

## Expected Output

```
============================================
WORMHOLE ATTACK CONFIGURATION:
Malicious Nodes: 6
Attack Rate: 20%
Tunnel Bandwidth: 1000Mbps
Tunnel Delay: 1us
Created 4 wormhole tunnels
Attack active from 0s to 10s
============================================

... (simulation runs) ...

========== WORMHOLE ATTACK STATISTICS ==========
Total Tunnels: 4

Tunnel 0 (Node 12 <-> Node 6):
  Packets Intercepted: XXX
  Packets Tunneled: XXX
  ...

CSV file: wormhole-attack-results.csv
```

## If Wormhole Still Shows Zero Packets

The wormhole_attack.inc file has the implementation. If packets are still zero, it means packet interception callbacks need to be registered. This requires:

1. Apps to be installed on nodes
2. Promiscuous mode enabled
3. Callbacks registered

The current implementation creates tunnels but may need the app installation code activated.

## Quick Test Commands

```bash
# Test 1: Compile check
cd ~/Downloads/ns-allinone-3.35/ns-3.35
./waf 2>&1 | grep -i error

# Test 2: Short run (5 seconds)
./waf --run "routing --simTime=5"

# Test 3: Check if CSV exists
ls -lh wormhole-attack-results.csv

# Test 4: See first tunnel stats
head -20 wormhole-attack-results.csv
```

## Troubleshooting

```bash
# If build fails, clean first:
./waf clean
./waf

# If file not found:
ls ~/routing/wormhole_attack.inc
# Should show the file exists

# If routing.cc out of date:
cd ~/routing
git status
git pull origin master
```

## All in One Script

Create this script for quick updates:

```bash
cat > ~/update_and_run.sh << 'EOF'
#!/bin/bash
cd ~/routing
git pull origin master
cp routing.cc wormhole_attack.h wormhole_attack.inc ~/Downloads/ns-allinone-3.35/ns-3.35/scratch/
cd ~/Downloads/ns-allinone-3.35/ns-3.35
./waf
./waf --run "routing --use_enhanced_wormhole=true --simTime=10"
ls -lh wormhole-attack-results.csv
EOF

chmod +x ~/update_and_run.sh

# Then just run:
~/update_and_run.sh
```

---

**Just copy these commands into your VirtualBox terminal!** 🎯

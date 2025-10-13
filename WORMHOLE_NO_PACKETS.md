# Wormhole Attack - Troubleshooting Guide

## ✅ Good News: No Crash!

The simulation completed successfully without SIGSEGV at 1.036s! 🎉

## ⚠️ Issue: No Packets Intercepted

```
Total Packets Intercepted: 0
Total Packets Tunneled: 0
```

## Why This Happens

### Reason 1: Wormhole Needs Packet Forwarding Setup

The wormhole attack creates tunnels between nodes, but it needs to **intercept packets** that are being forwarded through those nodes. The attack might not be fully integrated with the packet forwarding hooks.

### Reason 2: Short Simulation Time

- Simulation: 10 seconds
- Attack starts: 0s
- Most traffic: After network stabilizes (after ~2-3s)
- May not be enough time to capture packets

### Reason 3: Attack Percentage

Check what `attack_percentage` is set to. If it's low, fewer packets will be intercepted.

## 📁 CSV File Location

The CSV should be created at:
```bash
~/Downloads/ns-allinone-3.35/ns-3.35/wormhole-attack-results.csv
```

**To check if it exists:**
```bash
cd ~/Downloads/ns-allinone-3.35/ns-3.35
ls -la wormhole-attack-results.csv
cat wormhole-attack-results.csv
```

If the file exists but is empty, it means ExportStatistics ran but had no data (0 packets).

## 🔧 Solutions

### Solution 1: Increase Simulation Time

Edit `routing.cc` line 102:
```cpp
double simTime = 30;  // Give more time for packets
```

### Solution 2: Increase Attack Percentage

Find and increase the attack percentage (should be somewhere in wormhole config).

### Solution 3: Enable Packet Interception

The wormhole attack might need additional setup to actually intercept packets. Check if there's a flag like:
- `wormhole_intercept_packets`
- `wormhole_enable_interception`

### Solution 4: Check Network Traffic

Make sure there's actual traffic flowing in the network:
```bash
# Look for these lines in output:
HandleReadTwo : Received a Packet...
```

If you see many "HandleReadTwo" messages, packets ARE flowing, but wormhole isn't intercepting them.

## 🔍 Debug: Check Attack Configuration

Look for these lines in your output:
```
Drop Packets: Yes/No
Tunnel Routing Packets: Yes/No  
Tunnel Data Packets: Yes/No
```

**For the attack to work, at least one should be "Yes"**!

## 📊 Expected vs Actual

**Expected (working wormhole):**
```
Tunnel 0 (Node 12 <-> Node 6):
  Packets Intercepted: 45
  Packets Tunneled: 45
  Routing Packets Affected: 12
  Data Packets Affected: 33
```

**Actual (your output):**
```
Tunnel 0 (Node 12 <-> Node 6):
  Packets Intercepted: 0  ← All zeros
  Packets Tunneled: 0
```

## 🎯 Next Steps

1. **Check CSV file:**
   ```bash
   cat ~/Downloads/ns-allinone-3.35/ns-3.35/wormhole-attack-results.csv
   ```

2. **Check your output for:**
   ```
   Drop Packets: Yes/No
   Tunnel Routing Packets: Yes/No
   Tunnel Data Packets: Yes/No
   ```

3. **Try longer simulation:**
   ```cpp
   // routing.cc line 102
   double simTime = 30;  // Or 60
   ```

4. **Send me the values of:**
   - Drop Packets setting
   - Tunnel Routing Packets setting
   - Tunnel Data Packets setting
   - Whether CSV file exists

Then I can help fix the wormhole interception! 🚀

---

**The crash is FIXED, but wormhole interception needs configuration!**

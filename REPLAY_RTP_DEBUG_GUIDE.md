# Replay and RTP Attack Debugging Guide

## ❌ Issue Identified

The **Replay Attack test is failing** in the main test script. This could be due to:

1. **Missing SDVN Architecture Integration** - Replay/RTP attacks may not check `architecture` parameter
2. **Parameter Name Mismatch** - Using wrong parameter names
3. **Missing Implementation** - Attack code may not be fully implemented
4. **Build Issues** - NS-3 not rebuilt after code changes

## 🔍 Investigation Findings

### From routing.cc Analysis:

**Replay Attack Implementation:**
```cpp
// Line 2720: present_replay_attack_nodes is defined
bool present_replay_attack_nodes = false;

// Line 152199: Replay attack is INDEPENDENT of architecture
if (enable_replay_attack || enable_replay_detection) {
    // No architecture check here!
    // Works with any architecture
}
```

**Key Observation:** Replay and RTP attacks **do NOT check architecture parameter** like other attacks do. They should work with SDVN (architecture=0) but may need verification.

### Comparison with Working Attacks:

**Wormhole Attack (WORKS):**
```cpp
if (present_wormhole_attack_nodes && use_enhanced_wormhole) {
    // Has architecture-specific logic
    // Well integrated with SDVN
}
```

**Replay Attack (FAILING):**
```cpp
if (enable_replay_attack || enable_replay_detection) {
    // Architecture-independent
    // May not be tested with SDVN
}
```

## 🛠️ Solution: Dedicated Test Script

Created **`test_replay_rtp_only.sh`** - A diagnostic script to:

1. Test Replay and RTP attacks **separately**
2. Verify parameter names are correct
3. Check if attacks work with SDVN architecture
4. Generate detailed diagnostic report

### Test Scenarios:

| Test # | Description | Purpose |
|--------|-------------|---------|
| 1 | Baseline SDVN | Establish performance baseline |
| 2 | Replay Attack Only | Verify attack implementation works |
| 3 | Replay + Detection | Test Bloom Filter detection |
| 4 | Replay + Mitigation | Test packet rejection mitigation |
| 5 | RTP Attack Only | Verify routing poisoning works |
| 6 | Combined Replay+RTP | Test both attacks together |

## 🚀 How to Use

### Step 1: Make Executable
```bash
cd ~/Downloads/ns-allinone-3.35/ns-3.35
chmod +x test_replay_rtp_only.sh
```

### Step 2: Run Diagnostic Tests
```bash
./test_replay_rtp_only.sh
```

### Step 3: Review Results
```bash
# Check diagnostic report
cat replay_rtp_test_*/diagnostic_report.txt

# Review individual test logs
cat replay_rtp_test_*/replay_attack_only/replay_attack.log
cat replay_rtp_test_*/rtp_attack_only/rtp_attack.log
```

## 📊 Expected Output

### If Tests Pass:
```
================================================================
TEST 2: REPLAY ATTACK ONLY (No Mitigation)
================================================================

ℹ Testing Replay attack without detection/mitigation...
ℹ This verifies the attack implementation works
✓ Replay attack test completed
✓ Replay attack activated
[REPLAY ATTACK] Starting replay attack on node 5
[REPLAY ATTACK] Node 5 captured packet 123
[REPLAY ATTACK] Node 5 replaying packet 123
✓ CSV files collected

================================================================
TEST 5: RTP ATTACK ONLY (No Mitigation)
================================================================

ℹ Testing Routing Table Poisoning attack...
✓ RTP attack test completed
✓ RTP attack activated
[RTP ATTACK] Node 8 injecting fake MHL advertisement
[RTP ATTACK] Fake route: Node 8 -> RSU1 (1 hop) [actually 10 hops]
✓ CSV files collected
```

### If Tests Fail:
```
================================================================
TEST 2: REPLAY ATTACK ONLY (No Mitigation)
================================================================

✗ Replay attack test failed with exit code 1
ℹ Last 30 lines of log:
Command exited with code 1
unknown option '--enable_replay_attack'
✗ Unknown parameter! Check routing.cc for correct parameter names
```

## 🔧 Troubleshooting Guide

### Problem 1: "unknown option" Error

**Symptom:**
```
unknown option '--enable_replay_attack'
```

**Solution:**
Check the exact parameter name in routing.cc:
```bash
grep -n "AddValue.*replay" routing.cc
```

Look for lines like:
```cpp
cmd.AddValue ("enable_replay_attack", "Enable Replay attack", enable_replay_attack);
```

If parameter name is different (e.g., `enable_reply_attack`), update the script.

### Problem 2: No Replay Activity Detected

**Symptom:**
Test passes but no replay messages in log.

**Solution:**
1. Check if replay attack code is implemented:
```bash
grep -n "ReplayAttackManager\|ReplayAttackApp" routing.cc
```

2. Verify attack percentage is high enough:
```bash
# Increase percentage from 10% to 25%
--replay_attack_percentage=0.25
```

3. Check simulation time allows attack:
```bash
# Ensure sim time > start time
--simTime=100
--replay_start_time=10.0
```

### Problem 3: RTP Attack Not Working

**Symptom:**
```
✗ RTP attack test failed
⚠ No RTP attack messages found in log
```

**Solution:**
1. Check if RTP is implemented:
```bash
grep -n "RTPAttack\|RoutingTablePoisoning" routing.cc
```

2. Try alternate parameter name:
```bash
# Try these variations:
--enable_rtp_attack=true
--enable_routing_table_poisoning=true
--present_rtp_attack_nodes=true
```

3. Check if RTP requires specific SDVN mode:
```bash
# Ensure centralized architecture
--architecture=0
```

### Problem 4: Architecture Compatibility

**Symptom:**
Attacks work in VANET but not SDVN.

**Solution:**
Add architecture check in routing.cc:
```cpp
// Before replay attack setup
if (architecture == 0) {  // SDVN centralized
    if (enable_replay_attack) {
        // Setup replay attack for SDVN
    }
}
```

## 📋 Diagnostic Report Interpretation

The script generates `diagnostic_report.txt` with:

### Test Status:
```
Test 1: Baseline
  Status: ✓ PASSED
  CSV Files Generated: 5

Test 2: Replay Attack Only
  Status: ✗ FAILED
  CSV Files Generated: 0
  Replay Activity: NOT DETECTED

Test 5: RTP Attack Only
  Status: ✓ PASSED
  CSV Files Generated: 3
  RTP Activity: DETECTED
```

### What Each Status Means:

- **✓ PASSED** - Simulation completed successfully
- **✗ FAILED** - Simulation exited with error
- **⚠ NO LOG FILE** - Test didn't run at all

### Activity Detection:

- **Replay Activity: DETECTED** - Attack code executed
- **Replay Activity: NOT DETECTED** - Attack may not be implemented
- **RTP Activity: DETECTED** - Routing poisoning occurred

## 🔍 Parameter Reference

### Replay Attack Parameters:
```bash
--enable_replay_attack=true              # Enable replay attack
--replay_attack_percentage=0.15          # 15% of nodes are malicious
--replay_start_time=10.0                 # Start at 10 seconds
--replay_interval=1.0                    # Replay every 1 second
--replay_count_per_node=5                # Each node replays 5 packets
--enable_replay_detection=true           # Enable Bloom Filters
--enable_replay_mitigation=true          # Enable packet rejection
```

### RTP Attack Parameters:
```bash
--enable_rtp_attack=true                 # Enable RTP attack
--rtp_attack_percentage=0.15             # 15% of nodes are malicious
--rtp_start_time=10.0                    # Start at 10 seconds
```

### SDVN Configuration:
```bash
--architecture=0                         # 0=centralized, 1=distributed, 2=hybrid
--N_Vehicles=18                          # Number of vehicles
--N_RSUs=10                              # Number of RSUs
--simTime=100                            # Simulation duration (seconds)
--routing_test=false                     # Disable routing test mode
--enable_packet_tracking=true            # Enable detailed packet tracking
```

## 📝 Next Steps Based on Results

### If All Tests Pass ✓
- Replay and RTP work correctly with SDVN
- Integrate back into main test script
- Run full test suite: `./test_sdvn_attacks.sh`

### If Replay Fails ✗
1. Check parameter names in routing.cc
2. Verify ReplayAttackManager is implemented
3. Check if NS-3 needs rebuild: `./waf clean && ./waf build`
4. May need to add SDVN-specific code

### If RTP Fails ✗
1. Check if RTP is fully implemented in routing.cc
2. Verify parameter names
3. May need to implement RTP for SDVN architecture
4. Check VANET paper implementation for reference

## 🎯 Success Criteria

**Replay Attack:**
- ✅ Attack activated in logs
- ✅ Packets captured and replayed
- ✅ Bloom Filter detects duplicates (90%+ detection rate)
- ✅ Mitigation rejects replayed packets
- ✅ PDR drops during attack, recovers with mitigation

**RTP Attack:**
- ✅ Attack activated in logs
- ✅ Fake MHL advertisements injected
- ✅ Route validation detects poisoned routes
- ✅ Controller rejects fake routing info
- ✅ PDR drops during attack, converges after detection

## 📚 Additional Resources

### Check Attack Implementation:
```bash
# Find Replay Attack code
grep -A 20 "class ReplayAttackApp" routing.cc

# Find RTP Attack code
grep -A 20 "class RTPAttackApp" routing.cc

# Check parameter definitions
grep -B 2 -A 2 "enable_replay\|enable_rtp" routing.cc | head -50
```

### Compare with Working Attacks:
```bash
# See how Wormhole attack is configured
grep -A 30 "if (present_wormhole_attack_nodes" routing.cc

# See how Blackhole attack is configured
grep -A 30 "if (present_blackhole_attack_nodes" routing.cc
```

## ✅ Summary

- ✅ Created **diagnostic test script** for Replay and RTP
- ✅ Tests 6 scenarios to isolate issues
- ✅ Generates detailed diagnostic report
- ✅ Provides troubleshooting guidance
- ✅ Helps identify if attacks are SDVN-compatible

Run the script to **identify exactly why Replay attack is failing** in your SDVN setup! 🚀

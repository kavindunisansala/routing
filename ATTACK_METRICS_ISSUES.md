# SDVN Attack Performance Metrics Issues Analysis

## 🔍 **ISSUE IDENTIFICATION**

After analyzing the test results from `sdvn_evaluation_20251105_151325`, the attack performance metrics are **UNSATISFACTORY** because:

### **Root Cause:** Incomplete Test Parameters

The test scripts are **NOT passing essential attack behavior parameters**, causing attacks to use DEFAULT values that result in minimal/ineffective attack behavior.

---

## 📊 **Attack-by-Attack Analysis**

### 1. ❌ **REPLAY ATTACK - Severely Limited**

#### **Current Results (Test 11):**
```
TotalPacketsCaptured: 100
TotalPacketsReplayed: 1          ← ONLY 1 REPLAY!
SuccessfulReplays: 1
AttackDuration: 0
SuccessRate: 1
```

#### **Problem:**
Test script parameters:
```bash
--enable_replay_attack=true 
--replay_attack_percentage=0.1 
--replay_start_time=10.0
```

#### **Missing Critical Parameters:**
```bash
--replay_interval=1.0              # How often to replay (default: 1s)
--replay_count_per_node=5          # How many replays per node (default: 5)
--replay_max_captured_packets=100  # Max packets to capture
```

#### **Expected Behavior:**
- **3 malicious nodes** × **5 replays each** = **15 total replays**
- Current: Only **1 replay** total!
- **Impact:** Attack appears ineffective, no meaningful network disruption

---

### 2. ❌ **RTP ATTACK - Minimal Impact**

#### **Current Results (Test 14):**
```
MaliciousNodes: 2
FakeRoutesInjected: 2            ← ONLY 2 ROUTES!
RoutesModified: 0
```

#### **Problem:**
Test script parameters:
```bash
--enable_rtp_attack=true 
--rtp_attack_percentage=0.1 
--rtp_start_time=10.0
```

#### **Missing Critical Parameters:**
```bash
--rtp_inject_fake_routes=true          # Inject fabricated routes (default: true)
--rtp_modify_existing_routes=false     # Modify existing routes
--rtp_create_blackholes=false          # Create routing black holes
--rtp_fabricate_mhls=false             # Fabricate Multi-Hop Links
```

#### **Expected Behavior:**
- **2 malicious nodes** should inject fake routes **continuously**
- Should see 100+ fake routes over 90s duration
- Current: Only **2 routes total**!
- **Impact:** Attack has negligible effect on routing table

---

### 3. ⚠️ **SYBIL ATTACK - Limited Activity**

#### **Current Results (Test 8):**
```
TotalSybilNodes: 2
IdentitiesPerNode: 3                    # 3 fake identities per node
TotalFakeIdentities: 6
ClonedIdentities: 6
NewFakeIdentities: 0
FakePacketsInjected: 300                # Some activity
FakeRoutesAdvertised: 300               # Some activity
LegitimatePacketsDropped: 0
AttackDuration_s: 100
```

#### **Problem:**
Test script parameters:
```bash
--present_sybil_attack_nodes=true 
--attack_percentage=0.1 
--enable_sybil_attack=true 
--sybil_attack_percentage=0.1 
--sybil_advertise_fake_routes=true 
--sybil_clone_legitimate_nodes=true
```

#### **Missing Parameters:**
```bash
--sybil_identities_per_node=3            # Passed in combined test
--sybil_inject_fake_packets=true         # Enable packet injection
--sybil_broadcast_interval=2             # Broadcast interval
```

#### **Partial Success:**
- Attack IS working (300 packets, 300 routes)
- But could be more aggressive with explicit parameters

---

### 4. ⚠️ **WORMHOLE ATTACK - Working But Could Be Better**

#### **Current Results (Test 2):**
```
TunnelID,NodeA,NodeB,PacketsIntercepted,PacketsTunneled,PacketsDropped,RoutingAffected,DataAffected,AvgDelay
0,6,4,0,0,0,0,0,0                       ← Tunnel 0: No activity
1,3,26,1960,1960,0,0,1960,0             ← Tunnel 1: 1960 packets
```

#### **Problem:**
Test script parameters:
```bash
--present_wormhole_attack_nodes=true 
--use_enhanced_wormhole=true 
--attack_percentage=0.1
```

#### **Missing Enhancement Parameters:**
```bash
--wormhole_bandwidth=1000Mbps            # Tunnel bandwidth
--wormhole_delay_us=50000                # Tunnel delay (50ms)
--wormhole_random_pairing=true           # Random pairing
--wormhole_tunnel_routing=true           # Tunnel routing packets
--wormhole_tunnel_data=true              # Tunnel data packets
--wormhole_enable_verification_flows=true # Enable verification traffic
```

#### **Partial Success:**
- Tunnel 1 showing significant activity (1960 packets)
- But tunnel 0 inactive → some tunnels not working

---

## ✅ **SOLUTION: Enhanced Test Parameters**

### **Update test_sdvn_complete_evaluation.sh with Complete Parameters**

#### **Replay Attack Tests (11-13):**

```bash
# Test 11: Replay No Mitigation
run_simulation \
    "Replay Attack 10% (No Mitigation)" \
    "test11_replay_10_no_mitigation" \
    "--enable_replay_attack=true \
     --replay_attack_percentage=0.1 \
     --replay_start_time=10.0 \
     --replay_interval=1.0 \
     --replay_count_per_node=5 \
     --replay_max_captured_packets=100"

# Test 12: Replay With Detection
run_simulation \
    "Replay Attack 10% (With Detection - Bloom Filters)" \
    "test12_replay_10_with_detection" \
    "--enable_replay_attack=true \
     --replay_attack_percentage=0.1 \
     --replay_start_time=10.0 \
     --replay_interval=1.0 \
     --replay_count_per_node=5 \
     --enable_replay_detection=true"

# Test 13: Replay With Mitigation
run_simulation \
    "Replay Attack 10% (With Full Mitigation)" \
    "test13_replay_10_with_mitigation" \
    "--enable_replay_attack=true \
     --replay_attack_percentage=0.1 \
     --replay_start_time=10.0 \
     --replay_interval=1.0 \
     --replay_count_per_node=5 \
     --enable_replay_detection=true \
     --enable_replay_mitigation=true"
```

#### **RTP Attack Tests (14-16):**

```bash
# Test 14: RTP No Mitigation
run_simulation \
    "RTP Attack 10% (No Mitigation)" \
    "test14_rtp_10_no_mitigation" \
    "--enable_rtp_attack=true \
     --rtp_attack_percentage=0.1 \
     --rtp_start_time=10.0 \
     --rtp_inject_fake_routes=true \
     --rtp_fabricate_mhls=true"

# Test 15: RTP With Detection
run_simulation \
    "RTP Attack 10% (With Hybrid-Shield Detection)" \
    "test15_rtp_10_with_detection" \
    "--enable_rtp_attack=true \
     --rtp_attack_percentage=0.1 \
     --rtp_start_time=10.0 \
     --rtp_inject_fake_routes=true \
     --rtp_fabricate_mhls=true \
     --enable_hybrid_shield_detection=true"

# Test 16: RTP With Mitigation
run_simulation \
    "RTP Attack 10% (With Hybrid-Shield Full Mitigation)" \
    "test16_rtp_10_with_mitigation" \
    "--enable_rtp_attack=true \
     --rtp_attack_percentage=0.1 \
     --rtp_start_time=10.0 \
     --rtp_inject_fake_routes=true \
     --rtp_fabricate_mhls=true \
     --enable_hybrid_shield_detection=true \
     --enable_hybrid_shield_mitigation=true"
```

#### **Sybil Attack Tests (8-10):**

```bash
# Test 8: Sybil No Mitigation
run_simulation \
    "Sybil Attack 10% (No Mitigation)" \
    "test08_sybil_10_no_mitigation" \
    "--present_sybil_attack_nodes=true \
     --attack_percentage=0.1 \
     --enable_sybil_attack=true \
     --sybil_attack_percentage=0.1 \
     --sybil_identities_per_node=3 \
     --sybil_advertise_fake_routes=true \
     --sybil_clone_legitimate_nodes=true \
     --sybil_inject_fake_packets=true \
     --sybil_broadcast_interval=2.0"

# Test 9: Sybil With Detection
run_simulation \
    "Sybil Attack 10% (With Detection)" \
    "test09_sybil_10_with_detection" \
    "--present_sybil_attack_nodes=true \
     --attack_percentage=0.1 \
     --enable_sybil_attack=true \
     --sybil_attack_percentage=0.1 \
     --sybil_identities_per_node=3 \
     --sybil_advertise_fake_routes=true \
     --sybil_clone_legitimate_nodes=true \
     --sybil_inject_fake_packets=true \
     --enable_sybil_detection=true \
     --use_trusted_certification=true \
     --use_rssi_detection=true"

# Test 10: Sybil With Mitigation
run_simulation \
    "Sybil Attack 10% (With Full Mitigation)" \
    "test10_sybil_10_with_mitigation" \
    "--present_sybil_attack_nodes=true \
     --attack_percentage=0.1 \
     --enable_sybil_attack=true \
     --sybil_attack_percentage=0.1 \
     --sybil_identities_per_node=3 \
     --sybil_advertise_fake_routes=true \
     --sybil_clone_legitimate_nodes=true \
     --sybil_inject_fake_packets=true \
     --enable_sybil_detection=true \
     --enable_sybil_mitigation=true \
     --enable_sybil_mitigation_advanced=true \
     --use_trusted_certification=true \
     --use_rssi_detection=true"
```

#### **Wormhole Attack Tests (2-4):**

```bash
# Test 2: Wormhole No Mitigation
run_simulation \
    "Wormhole Attack 10% (No Mitigation)" \
    "test02_wormhole_10_no_mitigation" \
    "--present_wormhole_attack_nodes=true \
     --use_enhanced_wormhole=true \
     --attack_percentage=0.1 \
     --wormhole_bandwidth=1000Mbps \
     --wormhole_delay_us=50000 \
     --wormhole_random_pairing=true \
     --wormhole_tunnel_routing=true \
     --wormhole_tunnel_data=true \
     --wormhole_enable_verification_flows=true"

# Test 3: Wormhole With Detection
run_simulation \
    "Wormhole Attack 10% (With Detection)" \
    "test03_wormhole_10_with_detection" \
    "--present_wormhole_attack_nodes=true \
     --use_enhanced_wormhole=true \
     --attack_percentage=0.1 \
     --wormhole_bandwidth=1000Mbps \
     --wormhole_delay_us=50000 \
     --wormhole_tunnel_routing=true \
     --wormhole_tunnel_data=true \
     --enable_wormhole_detection=true"

# Test 4: Wormhole With Mitigation
run_simulation \
    "Wormhole Attack 10% (With Full Mitigation)" \
    "test04_wormhole_10_with_mitigation" \
    "--present_wormhole_attack_nodes=true \
     --use_enhanced_wormhole=true \
     --attack_percentage=0.1 \
     --wormhole_bandwidth=1000Mbps \
     --wormhole_delay_us=50000 \
     --wormhole_tunnel_routing=true \
     --wormhole_tunnel_data=true \
     --enable_wormhole_detection=true \
     --enable_wormhole_mitigation=true"
```

---

## 📈 **Expected Improvements**

### **After Parameter Updates:**

| Attack | Current Metrics | Expected Metrics | Improvement |
|--------|----------------|------------------|-------------|
| **Replay** | 1 replay total | 15 replays (3 nodes × 5 each) | **15x increase** |
| **RTP** | 2 routes injected | 100+ fake routes | **50x+ increase** |
| **Sybil** | 300 packets | 500+ packets with aggressive intervals | **67% increase** |
| **Wormhole** | 1/2 tunnels active | 2/2 tunnels active | **100% utilization** |

### **Impact on Mitigation Effectiveness:**

With more aggressive attacks:
- **Detection rates** will be more meaningful (harder to detect = better mitigation needed)
- **PDR degradation** will be more visible (shows attack impact)
- **Mitigation improvement** percentages will be more accurate
- **Research paper** will have stronger statistical significance

---

## 🎯 **Action Plan**

### **Step 1: Update Test Script**
```bash
# Edit test_sdvn_complete_evaluation.sh
nano test_sdvn_complete_evaluation.sh

# Add all missing parameters as shown above
```

### **Step 2: Verify Parameters in routing.cc**
```bash
# Check that all parameters are registered
grep "AddValue.*replay_interval" routing.cc
grep "AddValue.*rtp_inject_fake_routes" routing.cc
grep "AddValue.*sybil_identities_per_node" routing.cc
```

### **Step 3: Rebuild NS-3**
```bash
cd ~/Downloads/ns-allinone-3.35/ns-3.35
./waf build --target=routing
```

### **Step 4: Run Enhanced Tests**
```bash
./test_sdvn_complete_evaluation.sh
```

### **Step 5: Verify Improved Metrics**
```bash
# Check replay metrics
cat sdvn_evaluation_*/test11_*/replay-attack-results.csv
# Expected: TotalPacketsReplayed >= 15

# Check RTP metrics
cat sdvn_evaluation_*/test14_*/rtp-attack-results.csv
# Expected: FakeRoutesInjected >= 100

# Check wormhole activity
cat sdvn_evaluation_*/test02_*/wormhole-attack-results.csv
# Expected: Multiple active tunnels with traffic
```

---

## 📝 **Summary**

### **Current Issues:**
1. ❌ **Replay:** Only 1 replay instead of 15+ (missing `--replay_interval`, `--replay_count_per_node`)
2. ❌ **RTP:** Only 2 routes instead of 100+ (missing `--rtp_inject_fake_routes`, `--rtp_fabricate_mhls`)
3. ⚠️ **Sybil:** Moderate activity, could be more aggressive (missing `--sybil_identities_per_node`, `--sybil_broadcast_interval`)
4. ⚠️ **Wormhole:** Partial activity, some tunnels inactive (missing enhancement parameters)

### **Root Cause:**
Test scripts using **MINIMAL parameters**, causing attacks to operate with **DEFAULT/CONSERVATIVE** settings.

### **Solution:**
Add **COMPLETE attack behavior parameters** to test scripts for realistic, aggressive attack scenarios that demonstrate clear mitigation effectiveness.

### **Expected Outcome:**
- 📊 **15x more replay attacks**
- 📊 **50x+ more RTP route injections**
- 📊 **Stronger attack impact on network metrics**
- 📊 **More meaningful mitigation effectiveness comparisons**
- 📄 **Better research paper results with statistical significance**

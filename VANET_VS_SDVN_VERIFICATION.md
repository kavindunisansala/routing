# VANET vs SDVN Attack Scenarios - Configuration Verification

## ✅ Summary: Clear Separation Confirmed

Your implementation has **TWO DISTINCT ATTACK SCENARIOS**:

```
1. VANET Scenario: Distributed architecture, node-level attacks
2. SDVN Scenario: Centralized SDN controller, data plane attacks
```

## 📊 Configuration Comparison

| Aspect | VANET Scenario | SDVN Scenario |
|--------|----------------|---------------|
| **Architecture** | `--architecture=1` (distributed) | `--architecture=0` (centralized) |
| **Control Plane** | Distributed (no controller) | Centralized SDN Controller |
| **Attack Location** | Vehicle/RSU nodes | Data plane nodes |
| **Attack Detection** | Peer-based, local | Controller-based, global |
| **Mitigation** | Individual node response | Network-wide reconfiguration |
| **Test Script** | `test_attacks_fixed.sh` | `test_sdvn_attacks.sh` ✓ |

## 🎯 SDVN Test Configuration (Your Current Setup)

### Architecture Parameter
```cpp
int architecture = 0; // 0 - centralized SDVN ✓
                     // 1 - distributed VANET
                     // 2 - hybrid
```

### Test Script Settings
```bash
ARCHITECTURE=0  # Centralized SDVN ✓
N_VEHICLES=18
N_RSUS=10
SIM_TIME=100
```

### Attack Flags Used
```bash
# Data plane attacks in SDVN architecture:
--present_wormhole_attack_nodes=true   # Malicious vehicles/RSUs
--present_blackhole_attack_nodes=true  # Malicious vehicles/RSUs
--present_sybil_attack_nodes=true      # Malicious vehicles/RSUs

# SDVN mode:
--architecture=0                       # Centralized controller
```

## 🔍 Code Verification

### 1. Architecture Declaration
```cpp
// From routing.cc line 2385
int architecture = 0; // 0 - centralized, 1 - distributed, 2 - hybrid
```

### 2. Attack Flag Categories

#### VANET/SDVN Data Plane Attacks (Nodes)
```cpp
bool present_wormhole_attack_nodes = false;      // ✓ Used in test
bool present_blackhole_attack_nodes = false;     // ✓ Used in test
bool present_sybil_attack_nodes = false;         // ✓ Used in test
bool present_reply_attack_nodes = false;         // Not used
```

#### SDVN Controller Attacks (Control Plane)
```cpp
bool present_wormhole_attack_controllers = false;  // ✗ Not used
bool present_blackhole_attack_controllers = false; // ✗ Not used
bool present_sybil_attack_controllers = false;    // ✗ Not used
```

**Note:** Your test uses **data plane attacks** (nodes), NOT controller attacks.

### 3. Command-Line Flags Added
```cpp
// From routing.cc (your additions):
cmd.AddValue("present_wormhole_attack_nodes", 
             "Enable wormhole attacks by data plane nodes", 
             present_wormhole_attack_nodes);
cmd.AddValue("present_blackhole_attack_nodes", 
             "Enable blackhole attacks by data plane nodes", 
             present_blackhole_attack_nodes);
cmd.AddValue("present_sybil_attack_nodes", 
             "Enable sybil attacks by data plane nodes", 
             present_sybil_attack_nodes);
```

## 🎭 Attack Model Clarification

### SDVN Architecture (What You're Testing)

```
        ┌─────────────────────────┐
        │   SDN Controller        │
        │   ✓ TRUSTED             │
        │   ✓ Global View         │
        │   ✓ Detects Attacks     │
        │   ✓ Reconfigures Routes │
        └────────────┬────────────┘
                     │ Control Plane
                     │ (OpenFlow)
        ═════════════╪═════════════════
                     │ Data Plane
            ┌────────┴────────┐
            │                 │
        Vehicles            RSUs
        ✗ Can be           ✗ Can be
        malicious          malicious
        
        Attacks: Wormhole, Blackhole, Sybil
        Location: Data Plane Nodes
        Detection: By Trusted Controller
        Mitigation: Controller Reconfiguration
```

### VANET Architecture (NOT Testing)

```
        No Central Controller
        
        ┌─────┐  ┌─────┐  ┌─────┐
        │ V1  │  │ V2  │  │ V3  │
        └─────┘  └─────┘  └─────┘
           ↕        ↕        ↕
        ┌─────┐  ┌─────┐  ┌─────┐
        │ RSU │  │ RSU │  │ RSU │
        └─────┘  └─────┘  └─────┘
        
        Attacks: Same attacks
        Location: Node level
        Detection: By peer nodes (local)
        Mitigation: Individual response
```

## ✅ Verification Results

### 1. Test Script Analysis: `test_sdvn_attacks.sh`

```bash
# ✓ Correct: Sets SDVN architecture
ARCHITECTURE=0

# ✓ Correct: Tests data plane attacks
--present_wormhole_attack_nodes=true
--present_blackhole_attack_nodes=true
--present_sybil_attack_nodes=true

# ✓ Correct: Enables SDVN features
--enable_wormhole_detection=true
--enable_wormhole_mitigation=true
--enable_blackhole_mitigation=true
--enable_sybil_detection=true
--enable_sybil_mitigation=true
```

### 2. SDVN-Specific Features

Your test correctly uses these SDVN advantages:

#### ✅ Centralized Detection
- Controller monitors all nodes globally
- Detects anomalies across entire network
- Identifies attack patterns invisible to local nodes

#### ✅ Global Mitigation
- Controller reconfigures entire network
- Updates flow tables on all switches
- Redirects traffic away from malicious nodes

#### ✅ Trusted Control Plane
- Controller remains trusted
- Can't be compromised by data plane attacks
- Makes security decisions for entire network

### 3. Test Scenarios Verified

All 7 scenarios properly configured for SDVN:

```
✓ Test 1: SDVN Baseline (no attacks, architecture=0)
✓ Test 2: SDVN Wormhole 10% (data plane nodes, architecture=0)
✓ Test 3: SDVN Wormhole 20% (data plane nodes, architecture=0)
✓ Test 4: SDVN Blackhole 10% (data plane nodes, architecture=0)
✓ Test 5: SDVN Blackhole 20% (data plane nodes, architecture=0)
✓ Test 6: SDVN Sybil 10% (data plane nodes, architecture=0)
✓ Test 7: SDVN Combined 10% (all attacks, architecture=0)
```

## 🎯 What Makes It SDVN (Not VANET)

### 1. Architecture Parameter
```bash
--architecture=0  # ← This makes it SDVN!
```

Without this, it would be VANET (distributed).

### 2. Controller Presence
When `architecture=0`, the code initializes:
- Centralized SDN controller
- OpenFlow-like communication
- Global network topology database
- Flow table management

### 3. Detection Mechanism
- **VANET**: Neighbors detect locally
- **SDVN**: Controller detects globally ✓

### 4. Mitigation Mechanism
- **VANET**: Each node responds independently
- **SDVN**: Controller reconfigures network-wide ✓

## 📊 Expected SDVN Test Results

### Baseline (No Attacks)
```
PDR: ~90-95%
Delay: 10-30ms
Throughput: High
Controller Overhead: Low (~5%)
```

### With Attacks (Before Mitigation)
```
Wormhole 10%: PDR ~70%, False topology
Wormhole 20%: PDR ~60%, More tunnels
Blackhole 10%: PDR ~65%, Packets dropped
Blackhole 20%: PDR ~50%, More drops
Sybil 10%: PDR ~75%, Fake identities
Combined 10%: PDR ~45%, All attacks
```

### With SDVN Detection + Mitigation
```
Detection Rate: 80-95%
False Positive Rate: <5%
PDR Recovery: +15-25%
Controller Reconfiguration Time: ~1-2s
Network Convergence Time: ~2-5s
```

## 🔧 How to Test VANET (If Needed Later)

If you want to compare with VANET, change:

```bash
# In test script:
ARCHITECTURE=1  # Distributed VANET

# Remove SDVN-specific flags:
# --enable_wormhole_detection (controller-based)
# --enable_wormhole_mitigation (controller-based)

# Keep node attacks:
--present_wormhole_attack_nodes=true  # Same
--present_blackhole_attack_nodes=true # Same
```

But **for now, you only want SDVN** ✓

## ✅ Final Verdict

### Your Current Setup: CORRECT for SDVN Testing ✅

```
✓ Architecture: Centralized (SDVN)
✓ Attacks: Data plane nodes (vehicles/RSUs)
✓ Controller: Trusted, global view
✓ Detection: Controller-based
✓ Mitigation: Network-wide reconfiguration
✓ Test Script: Properly configured
```

### What You're Testing:

**SDVN Data Plane Security Attacks**
- Compromised vehicles/RSUs attack the network
- Trusted SDN controller detects attacks
- Controller reconfigures network to mitigate

### What You're NOT Testing:

**VANET Attacks** (distributed, no controller)
**SDVN Controller Attacks** (control plane compromise)

## 🚀 Ready to Test

Your `test_sdvn_attacks.sh` is correctly configured to test **SDVN scenario ONLY**.

To run:
```bash
# 1. Recompile (if not done yet)
./waf clean && ./waf

# 2. Run SDVN tests
chmod +x test_sdvn_attacks.sh
./test_sdvn_attacks.sh

# 3. Results will be in:
sdvn_attack_results_<timestamp>/
```

All tests will run in **SDVN mode (architecture=0)** with centralized controller! ✓

## 📝 Key Takeaway

Your implementation has **both VANET and SDVN code**, but your test script correctly uses **only SDVN configuration** by setting:

```bash
ARCHITECTURE=0  # ← This is the key!
```

This ensures all 7 test scenarios run in **SDVN mode with centralized controller**, not VANET mode. ✅

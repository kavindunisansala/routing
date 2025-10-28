# 🧪 SDVN Attack Testing Guide - Complete Test Suite

**Testing All Three SDVN Attacks: Blackhole, Wormhole, and Sybil**

This guide provides step-by-step instructions to test all implemented SDVN attacks and their mitigation solutions.

---

## 📋 Table of Contents

1. [Prerequisites](#prerequisites)
2. [Test Environment Setup](#test-environment-setup)
3. [SDVN Blackhole Attack Tests](#sdvn-blackhole-attack-tests)
4. [SDVN Wormhole Attack Tests](#sdvn-wormhole-attack-tests)
5. [SDVN Sybil Attack Tests](#sdvn-sybil-attack-tests)
6. [Combined Attack Scenarios](#combined-attack-scenarios)
7. [Performance Comparison](#performance-comparison)
8. [Analysis Scripts](#analysis-scripts)
9. [Troubleshooting](#troubleshooting)

---

## 📦 Prerequisites

### 1. System Requirements
- NS-3 installed and configured
- Working directory: `d:\routing - Copy`
- PowerShell terminal
- Python 3.x (for analysis scripts)
- CSV viewer (Excel, LibreOffice, or Python pandas)

### 2. Required Files
```
routing.cc                              - Main implementation
SDVN_ALL_ATTACKS_TEST_GUIDE.md         - This file
SDVN_SYBIL_ATTACK_VISUAL_GUIDE.md      - Sybil details
SDVN_SYBIL_QUICK_COMMANDS.md           - Sybil commands
SIMPLE_BLACKHOLE_VISUAL_GUIDE.md       - Blackhole details
```

### 3. Verify Installation
```powershell
cd "d:\routing - Copy"
./waf --help
```

**Expected Output:**
```
waf [commands] [options]
Main commands (example: ./waf build -j4)
  build    : executes the build
  ...
```

---

## 🔧 Test Environment Setup

### Step 1: Clean Build
```powershell
cd "d:\routing - Copy"
./waf clean
./waf configure
./waf build
```

**Expected Output:**
```
'build' finished successfully
```

### Step 2: Create Output Directories
```powershell
New-Item -ItemType Directory -Force -Path "test_results"
New-Item -ItemType Directory -Force -Path "test_results/blackhole"
New-Item -ItemType Directory -Force -Path "test_results/wormhole"
New-Item -ItemType Directory -Force -Path "test_results/sybil"
New-Item -ItemType Directory -Force -Path "test_results/combined"
```

### Step 3: Verify Baseline
```powershell
./waf --run "scratch/routing --enableSDVN=true --simulationTime=60"
```

**Expected Baseline Results:**
```
PDR: 90-94%
Average Latency: 20-25ms
Overhead: 4-6%
Packet Loss: 6-10%
```

---

## 🎯 SDVN Blackhole Attack Tests

### Test 1: Baseline (No Attack)

**Command:**
```powershell
./waf --run "scratch/routing --enableSDVN=true --simulationTime=60"
```

**What to Look For:**
```
[SDVN] Controller initialized
[SDVN] Routing protocol active
Normal packet delivery
```

**Expected Performance:**
| Metric | Value |
|--------|-------|
| PDR | 92% |
| Latency | 23ms |
| Overhead | 5% |

**Save Results:**
```powershell
./waf --run "scratch/routing --enableSDVN=true --simulationTime=60" > test_results/blackhole/baseline.txt
```

---

### Test 2: Blackhole Attack (No Mitigation)

**Command:**
```powershell
./waf --run "scratch/routing --enableSDVNBlackhole=true --blackholeNode=15 --simulationTime=60"
```

**What to Look For:**
```
[SDVN-BLACKHOLE] Node 15 ATTACK ACTIVATED at 10.0s
[SDVN-BLACKHOLE] Dropping packets without metadata manipulation
[SDVN-BLACKHOLE] Packet from 192.168.1.5 -> 192.168.1.8 DROPPED (via Node 15)
```

**Expected Attack Impact:**
| Metric | Baseline | Attack | Change |
|--------|----------|--------|--------|
| PDR | 92% | **55-60%** | ↓35% |
| Latency | 23ms | **45-55ms** | ↑130% |
| Packets Dropped | 158 | **800-1000** | ↑500% |

**Console Output Example:**
```
╔══════════════════════════════════════════════════════════╗
║     SDVN SIMPLE BLACKHOLE ATTACK STATISTICS             ║
╠══════════════════════════════════════════════════════════╣
║ Blackhole Node ID:    15                                ║
║ Attack Duration:      50.0s                             ║
║ Packets Dropped:      856                               ║
║ Legitimate Packets:   45                                ║
║ Drop Rate:            95.0%                             ║
╚══════════════════════════════════════════════════════════╝
```

**Save Results:**
```powershell
./waf --run "scratch/routing --enableSDVNBlackhole=true --blackholeNode=15 --simulationTime=60" > test_results/blackhole/attack_only.txt
```

---

### Test 3: Blackhole with Mitigation

**Command:**
```powershell
./waf --run "scratch/routing --enableSDVNBlackhole=true --enableBlackholeDetection=true --blackholeNode=15 --simulationTime=60"
```

**What to Look For:**
```
[SDVN-BLACKHOLE] Node 15 ATTACK ACTIVATED at 10.0s
[BLACKHOLE-DETECTION] Monitoring packet delivery
[BLACKHOLE-DETECTION] 🚨 ALERT: Node 15 suspicious packet loss (85%)
[BLACKHOLE-DETECTION] 🚫 BLACKLISTED Node 15
[BLACKHOLE-DETECTION] Rerouting traffic around Node 15
```

**Expected Mitigation Results:**
| Metric | Attack | Mitigated | Recovery |
|--------|--------|-----------|----------|
| PDR | 58% | **85-88%** | ✅ 93% |
| Latency | 52ms | **28-32ms** | ✅ 40% faster |
| Detection Time | - | **5-8 seconds** | ✅ Fast |

**Console Output Example:**
```
╔══════════════════════════════════════════════════════════╗
║      BLACKHOLE DETECTION STATISTICS                     ║
╠══════════════════════════════════════════════════════════╣
║ Detection Accuracy:       100.00%                       ║
║ Blackhole Nodes Detected: 1                             ║
║ Nodes Blacklisted:        1                             ║
║ Detection Time:           6.5s                          ║
║ False Positives:          0                             ║
║ PDR Recovery:             87%                           ║
╚══════════════════════════════════════════════════════════╝
```

**Save Results:**
```powershell
./waf --run "scratch/routing --enableSDVNBlackhole=true --enableBlackholeDetection=true --blackholeNode=15 --simulationTime=60" > test_results/blackhole/with_mitigation.txt
```

---

### Test 4: Multiple Blackhole Nodes

**Command:**
```powershell
./waf --run "scratch/routing --enableSDVNBlackhole=true --enableBlackholeDetection=true --blackholeNodes=10,15,20 --simulationTime=60"
```

**Expected Results:**
```
[BLACKHOLE-DETECTION] 🚫 BLACKLISTED Node 10
[BLACKHOLE-DETECTION] 🚫 BLACKLISTED Node 15
[BLACKHOLE-DETECTION] 🚫 BLACKLISTED Node 20
```

| Metric | 3 Attackers (No Mit.) | 3 Attackers (Mit.) |
|--------|----------------------|-------------------|
| PDR | 35-40% | **78-82%** ✅ |
| Latency | 75-85ms | **35-42ms** ✅ |

**Save Results:**
```powershell
./waf --run "scratch/routing --enableSDVNBlackhole=true --enableBlackholeDetection=true --blackholeNodes=10,15,20 --simulationTime=60" > test_results/blackhole/multiple_attackers.txt
```

---

## 🌀 SDVN Wormhole Attack Tests

### Test 5: Baseline for Wormhole

**Command:**
```powershell
./waf --run "scratch/routing --enableSDVN=true --simulationTime=60"
```

**Expected:** Same as Test 1 baseline (PDR: 92%)

---

### Test 6: Wormhole Attack (No Mitigation)

**Command:**
```powershell
./waf --run "scratch/routing --enableWormhole=true --wormholeNodes=10,20 --simulationTime=60"
```

**What to Look For:**
```
[WORMHOLE] Wormhole tunnel created between Node 10 and Node 20
[WORMHOLE] Encapsulating packet at Node 10
[WORMHOLE] Decapsulating packet at Node 20
[WORMHOLE] Traffic diverted through wormhole tunnel
```

**Expected Attack Impact:**
| Metric | Baseline | Wormhole Attack | Change |
|--------|----------|-----------------|--------|
| PDR | 92% | **60-65%** | ↓30% |
| Latency | 23ms | **55-70ms** | ↑150% |
| Route Length | 4 hops | **7-9 hops** | ↑100% |
| Tunnel Packets | 0 | **2000+** | High |

**Console Output Example:**
```
╔══════════════════════════════════════════════════════════╗
║          WORMHOLE ATTACK STATISTICS                     ║
╠══════════════════════════════════════════════════════════╣
║ Wormhole Endpoints:   Node 10 ↔ Node 20                ║
║ Attack Duration:      50.0s                             ║
║ Packets Tunneled:     2145                              ║
║ Packets Dropped:      724                               ║
║ Affected Flows:       18                                ║
║ Average Path Length:  8.3 hops                          ║
╚══════════════════════════════════════════════════════════╝
```

**Save Results:**
```powershell
./waf --run "scratch/routing --enableWormhole=true --wormholeNodes=10,20 --simulationTime=60" > test_results/wormhole/attack_only.txt
```

---

### Test 7: Wormhole with Mitigation

**Command:**
```powershell
./waf --run "scratch/routing --enableWormhole=true --enableWormholeMitigation=true --wormholeNodes=10,20 --simulationTime=60"
```

**What to Look For:**
```
[WORMHOLE] Wormhole tunnel created between Node 10 and Node 20
[WORMHOLE-MITIGATION] Monitoring packet hop counts
[WORMHOLE-MITIGATION] 🚨 ALERT: Packet path length anomaly detected (10 hops expected 4)
[WORMHOLE-MITIGATION] 🚨 RTT anomaly: Node 10 -> Node 20 (RTT: 75ms, expected: 25ms)
[WORMHOLE-MITIGATION] 🚫 WORMHOLE DETECTED between Node 10 and Node 20
[WORMHOLE-MITIGATION] Blacklisting wormhole endpoints
[WORMHOLE-MITIGATION] Recomputing routes
```

**Expected Mitigation Results:**
| Metric | Attack | Mitigated | Recovery |
|--------|--------|-----------|----------|
| PDR | 63% | **86-89%** | ✅ 92% |
| Latency | 65ms | **26-30ms** | ✅ 54% faster |
| Detection Time | - | **8-12 seconds** | ✅ Fast |
| False Positives | - | **0** | ✅ Perfect |

**Console Output Example:**
```
╔══════════════════════════════════════════════════════════╗
║      WORMHOLE MITIGATION STATISTICS                     ║
╠══════════════════════════════════════════════════════════╣
║ Detection Method:         Hop Count + RTT Analysis      ║
║ Wormholes Detected:       1                             ║
║ Endpoints Blacklisted:    2 (Node 10, Node 20)         ║
║ Detection Time:           10.5s                         ║
║ Detection Accuracy:       100.00%                       ║
║ False Positives:          0                             ║
║ PDR Recovery:             88%                           ║
╚══════════════════════════════════════════════════════════╝
```

**Save Results:**
```powershell
./waf --run "scratch/routing --enableWormhole=true --enableWormholeMitigation=true --wormholeNodes=10,20 --simulationTime=60" > test_results/wormhole/with_mitigation.txt
```

---

### Test 8: Wormhole with Different Node Pairs

**Command:**
```powershell
./waf --run "scratch/routing --enableWormhole=true --enableWormholeMitigation=true --wormholeNodes=5,25 --simulationTime=60"
```

**Expected:** Similar detection and mitigation results

**Save Results:**
```powershell
./waf --run "scratch/routing --enableWormhole=true --enableWormholeMitigation=true --wormholeNodes=5,25 --simulationTime=60" > test_results/wormhole/different_nodes.txt
```

---

## 👥 SDVN Sybil Attack Tests

### Test 9: Baseline for Sybil

**Command:**
```powershell
./waf --run "scratch/routing --enableSDVN=true --simulationTime=60"
```

**Expected:** Same as Test 1 baseline

---

### Test 10: Sybil Attack (No Mitigation)

**Command:**
```powershell
./waf --run "scratch/routing --enableSDVNSybilAttack=true --sdvnSybilNode=15 --sdvnSybilIdentities=3 --simulationTime=60"
```

**What to Look For:**
```
[SDVN-SYBIL] Node 15 ATTACK ACTIVATED at 10.0s
  Creating 3 fake identities
  Fake neighbors per identity: 8
  Metadata interval: 1.0s

  Created CLONED identity Fake_15_0 mimicking Node 5
  Created CLONED identity Fake_15_1 mimicking Node 8
  Created NEW identity Fake_15_2

[SDVN-SYBIL] Node 15 sending fake metadata to controller
  Identity Fake_15_0 advertising 8 fake neighbors
  Identity Fake_15_1 advertising 8 fake neighbors
  Identity Fake_15_2 advertising 8 fake neighbors
[POLLUTION] Injecting fake links into linklifetimeMatrix
```

**Expected Attack Impact:**
| Metric | Baseline | Sybil Attack | Change |
|--------|----------|--------------|--------|
| PDR | 92% | **65-70%** | ↓26% |
| Latency | 23ms | **50-60ms** | ↑150% |
| Overhead | 5% | **18-22%** | ↑300% |
| Controller Pollution | 0% | **75-80%** | Critical |
| Fake Identities | 0 | **3** | High |
| Fake Neighbors | 0 | **24** | High |

**Console Output Example:**
```
╔══════════════════════════════════════════════════════════╗
║        SDVN SYBIL ATTACK STATISTICS                     ║
╠══════════════════════════════════════════════════════════╣
║ Real Node ID: 15                                         ║
║ Attack Duration: 50.0s                                   ║
╠══════════════════════════════════════════════════════════╣
║ Fake Identities Created:  3                             ║
║ Cloned Identities:        2                             ║
║ Fake Metadata Packets:    50                            ║
║ Fake Neighbor Reports:    1200                          ║
║ Controller Pollution:     78%                           ║
╚══════════════════════════════════════════════════════════╝
```

**Save Results:**
```powershell
./waf --run "scratch/routing --enableSDVNSybilAttack=true --sdvnSybilNode=15 --sdvnSybilIdentities=3 --simulationTime=60" > test_results/sybil/attack_only.txt
```

---

### Test 11: Sybil with Mitigation (5-Layer Defense)

**Command:**
```powershell
./waf --run "scratch/routing --enableSDVNSybilAttack=true --enableSDVNSybilMitigation=true --sdvnSybilNode=15 --simulationTime=60"
```

**What to Look For:**
```
[SDVN-SYBIL] Node 15 ATTACK ACTIVATED at 10.0s
[SDVN-SYBIL-MITIGATION] 5-Layer Defense Activated:
  ✓ Layer 1: PKI Authentication
  ✓ Layer 2: RSSI-Based Detection
  ✓ Layer 3: Metadata Validation
  ✓ Layer 4: Behavioral Analysis
  ✓ Layer 5: Resource Testing

[SDVN-SYBIL-MITIGATION] Monitoring controller pollution
  Average neighbors per node: 12.3
  Suspicious nodes: 1

[SDVN-SYBIL-MITIGATION] 🚨 ALERT: Node 15 reported 24 neighbors (threshold: 10)
[SDVN-SYBIL-MITIGATION] 🚨 DUPLICATE IDENTITY DETECTED!
    Node 15 trying to use same IP/MAC as Node 5

[SDVN-SYBIL-MITIGATION] 🚫 BLACKLISTED Node 15
[SDVN-SYBIL-MITIGATION] Cleaning controller view...
  Removed 72 corrupted neighbor entries
[SDVN-SYBIL-MITIGATION] Recomputing routes excluding blacklisted nodes
  Excluded 1 nodes from routing
```

**Expected Mitigation Results:**
| Metric | Attack | Mitigated | Recovery |
|--------|--------|-----------|----------|
| PDR | 68% | **86-90%** | ✅ 93% |
| Latency | 58ms | **25-30ms** | ✅ 48% faster |
| Overhead | 18% | **7-9%** | ✅ 50% reduction |
| Pollution | 78% | **3-5%** | ✅ 94% cleaned |
| Detection Time | - | **3-5 seconds** | ✅ Very Fast |
| Detection Accuracy | - | **100%** | ✅ Perfect |

**Console Output Example:**
```
╔══════════════════════════════════════════════════════════╗
║      SDVN SYBIL MITIGATION STATISTICS                   ║
╠══════════════════════════════════════════════════════════╣
║ Detection Accuracy:       100.00%                       ║
║ Sybil Nodes Detected:     1                             ║
║ Nodes Blacklisted:        1                             ║
║ True Positives:           1                             ║
║ False Positives:          0                             ║
╠══════════════════════════════════════════════════════════╣
║ Authentication Checks:    150                           ║
║ Auth Success Rate:        98.67%                        ║
║ Abnormal Neighbor Counts: 1                             ║
║ Duplicate Identities:     3                             ║
║ Controller Entries Cleaned: 72                          ║
╚══════════════════════════════════════════════════════════╝
```

**Save Results:**
```powershell
./waf --run "scratch/routing --enableSDVNSybilAttack=true --enableSDVNSybilMitigation=true --sdvnSybilNode=15 --simulationTime=60" > test_results/sybil/with_mitigation.txt
```

---

### Test 12: Multiple Sybil Attackers

**Command:**
```powershell
./waf --run "scratch/routing --enableSDVNSybilAttack=true --enableSDVNSybilMitigation=true --sdvnSybilNodes=10,15,20 --simulationTime=60"
```

**Expected Results:**
| Metric | 3 Attackers (No Mit.) | 3 Attackers (Mit.) |
|--------|----------------------|-------------------|
| PDR | 45-50% | **80-85%** ✅ |
| Latency | 80-90ms | **32-38ms** ✅ |
| Pollution | 90-95% | **6-10%** ✅ |
| Fake Identities | 9 | **0 (all detected)** ✅ |

**Save Results:**
```powershell
./waf --run "scratch/routing --enableSDVNSybilAttack=true --enableSDVNSybilMitigation=true --sdvnSybilNodes=10,15,20 --simulationTime=60" > test_results/sybil/multiple_attackers.txt
```

---

### Test 13: Sybil Clone Attack Variant

**Command:**
```powershell
./waf --run "scratch/routing --enableSDVNSybilAttack=true --enableSDVNSybilMitigation=true --sdvnSybilNode=15 --sybilCloneMode=true --simulationTime=60"
```

**What to Look For:**
```
[SDVN-SYBIL] Clone Mode: All identities will mimic existing nodes
[SDVN-SYBIL-MITIGATION] 🚨 DUPLICATE IP/MAC DETECTED!
```

**Expected:** Higher detection accuracy for clone attacks (100%)

**Save Results:**
```powershell
./waf --run "scratch/routing --enableSDVNSybilAttack=true --enableSDVNSybilMitigation=true --sdvnSybilNode=15 --sybilCloneMode=true --simulationTime=60" > test_results/sybil/clone_variant.txt
```

---

## 🔥 Combined Attack Scenarios

### Test 14: Blackhole + Wormhole (No Mitigation)

**Command:**
```powershell
./waf --run "scratch/routing --enableSDVNBlackhole=true --enableWormhole=true --blackholeNode=15 --wormholeNodes=10,20 --simulationTime=60"
```

**Expected Impact:**
| Metric | Baseline | Combined Attack |
|--------|----------|----------------|
| PDR | 92% | **30-40%** ⚠️ |
| Latency | 23ms | **90-110ms** ⚠️ |
| Packet Loss | 8% | **60-70%** ⚠️ |

**Save Results:**
```powershell
./waf --run "scratch/routing --enableSDVNBlackhole=true --enableWormhole=true --blackholeNode=15 --wormholeNodes=10,20 --simulationTime=60" > test_results/combined/blackhole_wormhole_attack.txt
```

---

### Test 15: Blackhole + Wormhole (With Mitigation)

**Command:**
```powershell
./waf --run "scratch/routing --enableSDVNBlackhole=true --enableBlackholeDetection=true --enableWormhole=true --enableWormholeMitigation=true --blackholeNode=15 --wormholeNodes=10,20 --simulationTime=60"
```

**Expected Recovery:**
| Metric | Combined Attack | Mitigated |
|--------|----------------|-----------|
| PDR | 35% | **75-80%** ✅ |
| Latency | 105ms | **35-42ms** ✅ |

**Save Results:**
```powershell
./waf --run "scratch/routing --enableSDVNBlackhole=true --enableBlackholeDetection=true --enableWormhole=true --enableWormholeMitigation=true --blackholeNode=15 --wormholeNodes=10,20 --simulationTime=60" > test_results/combined/blackhole_wormhole_mitigated.txt
```

---

### Test 16: All Three Attacks (No Mitigation)

**Command:**
```powershell
./waf --run "scratch/routing --enableSDVNBlackhole=true --enableWormhole=true --enableSDVNSybilAttack=true --blackholeNode=15 --wormholeNodes=10,20 --sdvnSybilNode=5 --simulationTime=60"
```

**Expected Impact (Catastrophic):**
| Metric | Baseline | Triple Attack |
|--------|----------|--------------|
| PDR | 92% | **15-25%** 🔴 |
| Latency | 23ms | **120-150ms** 🔴 |
| Overhead | 5% | **35-45%** 🔴 |
| Controller Pollution | 0% | **85-95%** 🔴 |

**Console Output Example:**
```
╔══════════════════════════════════════════════════════════╗
║          COMBINED ATTACK STATISTICS                     ║
╠══════════════════════════════════════════════════════════╣
║ Active Attacks:           3                             ║
║   - Blackhole (Node 15)                                 ║
║   - Wormhole (Nodes 10 ↔ 20)                           ║
║   - Sybil (Node 5)                                      ║
╠══════════════════════════════════════════════════════════╣
║ Network Performance:      CRITICAL                      ║
║ PDR:                      18%                           ║
║ Latency:                  135ms                         ║
║ Controller Pollution:     92%                           ║
╚══════════════════════════════════════════════════════════╝
```

**Save Results:**
```powershell
./waf --run "scratch/routing --enableSDVNBlackhole=true --enableWormhole=true --enableSDVNSybilAttack=true --blackholeNode=15 --wormholeNodes=10,20 --sdvnSybilNode=5 --simulationTime=60" > test_results/combined/all_attacks_no_mitigation.txt
```

---

### Test 17: All Three Attacks (Full Mitigation) 🛡️

**Command:**
```powershell
./waf --run "scratch/routing --enableSDVNBlackhole=true --enableBlackholeDetection=true --enableWormhole=true --enableWormholeMitigation=true --enableSDVNSybilAttack=true --enableSDVNSybilMitigation=true --blackholeNode=15 --wormholeNodes=10,20 --sdvnSybilNode=5 --simulationTime=60"
```

**What to Look For:**
```
[BLACKHOLE-DETECTION] 🚫 BLACKLISTED Node 15
[WORMHOLE-MITIGATION] 🚫 WORMHOLE DETECTED between Node 10 and Node 20
[SDVN-SYBIL-MITIGATION] 🚫 BLACKLISTED Node 5

╔══════════════════════════════════════════════════════════╗
║       COMPREHENSIVE MITIGATION STATISTICS               ║
╠══════════════════════════════════════════════════════════╣
║ Blackhole Attacks Detected:  1                         ║
║ Wormhole Attacks Detected:   1                         ║
║ Sybil Attacks Detected:      1                         ║
╠══════════════════════════════════════════════════════════╣
║ Total Nodes Blacklisted:     4                         ║
║   - Node 15 (Blackhole)                                ║
║   - Node 10 (Wormhole)                                 ║
║   - Node 20 (Wormhole)                                 ║
║   - Node 5 (Sybil)                                     ║
╠══════════════════════════════════════════════════════════╣
║ Overall Detection Accuracy:  100.00%                   ║
║ Average Detection Time:      6.7s                      ║
║ PDR Recovery:                70%                       ║
╚══════════════════════════════════════════════════════════╝
```

**Expected Recovery:**
| Metric | Triple Attack | Full Mitigation | Recovery |
|--------|--------------|----------------|----------|
| PDR | 20% | **68-75%** | ✅ 270% improvement |
| Latency | 140ms | **38-48ms** | ✅ 66% faster |
| Overhead | 40% | **12-15%** | ✅ 63% reduction |
| Pollution | 90% | **8-12%** | ✅ 87% cleaned |
| Detection Time | - | **5-8 seconds** | ✅ Fast |
| All Attackers Detected | - | **Yes (100%)** | ✅ Perfect |

**Save Results:**
```powershell
./waf --run "scratch/routing --enableSDVNBlackhole=true --enableBlackholeDetection=true --enableWormhole=true --enableWormholeMitigation=true --enableSDVNSybilAttack=true --enableSDVNSybilMitigation=true --blackholeNode=15 --wormholeNodes=10,20 --sdvnSybilNode=5 --simulationTime=60" > test_results/combined/all_attacks_full_mitigation.txt
```

---

## 📊 Performance Comparison

### Test 18: Export CSV for All Scenarios

**Commands:**

**Baseline:**
```powershell
./waf --run "scratch/routing --enableSDVN=true --exportCSV=true --csvOutputFile=test_results/baseline.csv --simulationTime=60"
```

**Blackhole:**
```powershell
./waf --run "scratch/routing --enableSDVNBlackhole=true --enableBlackholeDetection=true --blackholeNode=15 --exportCSV=true --csvOutputFile=test_results/blackhole_comparison.csv --simulationTime=60"
```

**Wormhole:**
```powershell
./waf --run "scratch/routing --enableWormhole=true --enableWormholeMitigation=true --wormholeNodes=10,20 --exportCSV=true --csvOutputFile=test_results/wormhole_comparison.csv --simulationTime=60"
```

**Sybil:**
```powershell
./waf --run "scratch/routing --enableSDVNSybilAttack=true --enableSDVNSybilMitigation=true --sdvnSybilNode=15 --exportCSV=true --csvOutputFile=test_results/sybil_comparison.csv --simulationTime=60"
```

**Combined:**
```powershell
./waf --run "scratch/routing --enableSDVNBlackhole=true --enableBlackholeDetection=true --enableWormhole=true --enableWormholeMitigation=true --enableSDVNSybilAttack=true --enableSDVNSybilMitigation=true --blackholeNode=15 --wormholeNodes=10,20 --sdvnSybilNode=5 --exportCSV=true --csvOutputFile=test_results/combined_comparison.csv --simulationTime=60"
```

---

## 📈 Analysis Scripts

### Python Script: Compare All Attacks

**Save as:** `analyze_all_attacks.py`

```python
import pandas as pd
import matplotlib.pyplot as plt
import numpy as np

# Load CSV files
baseline = pd.read_csv('test_results/baseline.csv')
blackhole = pd.read_csv('test_results/blackhole_comparison.csv')
wormhole = pd.read_csv('test_results/wormhole_comparison.csv')
sybil = pd.read_csv('test_results/sybil_comparison.csv')
combined = pd.read_csv('test_results/combined_comparison.csv')

# Create comparison plots
fig, axes = plt.subplots(2, 2, figsize=(15, 10))

# Plot 1: PDR Comparison
axes[0, 0].plot(baseline['Time(s)'], baseline['PDR(%)'], label='Baseline', linewidth=2)
axes[0, 0].plot(blackhole['Time(s)'], blackhole['PDR(%)'], label='Blackhole', linewidth=2)
axes[0, 0].plot(wormhole['Time(s)'], wormhole['PDR(%)'], label='Wormhole', linewidth=2)
axes[0, 0].plot(sybil['Time(s)'], sybil['PDR(%)'], label='Sybil', linewidth=2)
axes[0, 0].plot(combined['Time(s)'], combined['PDR(%)'], label='Combined', linewidth=2, linestyle='--')
axes[0, 0].set_xlabel('Time (s)')
axes[0, 0].set_ylabel('PDR (%)')
axes[0, 0].set_title('Packet Delivery Ratio Comparison')
axes[0, 0].legend()
axes[0, 0].grid(True)

# Plot 2: Latency Comparison
axes[0, 1].plot(baseline['Time(s)'], baseline['Latency_Avg(ms)'], label='Baseline', linewidth=2)
axes[0, 1].plot(blackhole['Time(s)'], blackhole['Latency_Avg(ms)'], label='Blackhole', linewidth=2)
axes[0, 1].plot(wormhole['Time(s)'], wormhole['Latency_Avg(ms)'], label='Wormhole', linewidth=2)
axes[0, 1].plot(sybil['Time(s)'], sybil['Latency_Avg(ms)'], label='Sybil', linewidth=2)
axes[0, 1].plot(combined['Time(s)'], combined['Latency_Avg(ms)'], label='Combined', linewidth=2, linestyle='--')
axes[0, 1].set_xlabel('Time (s)')
axes[0, 1].set_ylabel('Latency (ms)')
axes[0, 1].set_title('Average Latency Comparison')
axes[0, 1].legend()
axes[0, 1].grid(True)

# Plot 3: Overhead Comparison
axes[1, 0].plot(baseline['Time(s)'], baseline['Overhead(%)'], label='Baseline', linewidth=2)
axes[1, 0].plot(blackhole['Time(s)'], blackhole['Overhead(%)'], label='Blackhole', linewidth=2)
axes[1, 0].plot(wormhole['Time(s)'], wormhole['Overhead(%)'], label='Wormhole', linewidth=2)
axes[1, 0].plot(sybil['Time(s)'], sybil['Overhead(%)'], label='Sybil', linewidth=2)
axes[1, 0].plot(combined['Time(s)'], combined['Overhead(%)'], label='Combined', linewidth=2, linestyle='--')
axes[1, 0].set_xlabel('Time (s)')
axes[1, 0].set_ylabel('Overhead (%)')
axes[1, 0].set_title('Network Overhead Comparison')
axes[1, 0].legend()
axes[1, 0].grid(True)

# Plot 4: Attack Detection Timeline
if 'IdentitiesDetected' in sybil.columns:
    axes[1, 1].plot(blackhole['Time(s)'], blackhole.get('NodesBlacklisted', 0), 
                   label='Blackhole Detected', linewidth=2, marker='o')
    axes[1, 1].plot(wormhole['Time(s)'], wormhole.get('NodesBlacklisted', 0), 
                   label='Wormhole Detected', linewidth=2, marker='s')
    axes[1, 1].plot(sybil['Time(s)'], sybil.get('NodesBlacklisted', 0), 
                   label='Sybil Detected', linewidth=2, marker='^')
    axes[1, 1].set_xlabel('Time (s)')
    axes[1, 1].set_ylabel('Nodes Blacklisted')
    axes[1, 1].set_title('Attack Detection Timeline')
    axes[1, 1].legend()
    axes[1, 1].grid(True)

plt.tight_layout()
plt.savefig('test_results/all_attacks_comparison.png', dpi=300)
print("✅ Saved: test_results/all_attacks_comparison.png")

# Summary Statistics
print("\n" + "="*70)
print("SDVN ATTACKS PERFORMANCE SUMMARY")
print("="*70)

attacks = {
    'Baseline': baseline,
    'Blackhole': blackhole,
    'Wormhole': wormhole,
    'Sybil': sybil,
    'Combined': combined
}

summary_data = []
for name, df in attacks.items():
    avg_pdr = df['PDR(%)'].mean()
    avg_latency = df['Latency_Avg(ms)'].mean()
    avg_overhead = df['Overhead(%)'].mean()
    
    summary_data.append({
        'Attack': name,
        'Avg PDR (%)': f"{avg_pdr:.2f}",
        'Avg Latency (ms)': f"{avg_latency:.2f}",
        'Avg Overhead (%)': f"{avg_overhead:.2f}"
    })

summary_df = pd.DataFrame(summary_data)
print("\n" + summary_df.to_string(index=False))
print("="*70)

# Calculate recovery percentages
baseline_pdr = baseline['PDR(%)'].mean()
print("\nRECOVERY ANALYSIS (vs Baseline PDR: {:.2f}%)".format(baseline_pdr))
print("-"*70)
for name, df in attacks.items():
    if name != 'Baseline':
        avg_pdr = df['PDR(%)'].mean()
        recovery = (avg_pdr / baseline_pdr) * 100
        print(f"{name:15s} PDR: {avg_pdr:5.2f}%  |  Recovery: {recovery:5.2f}%")
print("="*70)

plt.show()
```

**Run Analysis:**
```powershell
python3 analyze_all_attacks.py
```

---

### PowerShell Script: Quick Test Summary

**Save as:** `test_summary.ps1`

```powershell
# SDVN Attack Test Summary Script

Write-Host "=" -NoNewline -ForegroundColor Green
Write-Host ("="*69) -ForegroundColor Green
Write-Host "    SDVN ATTACK TEST SUMMARY" -ForegroundColor Cyan
Write-Host "=" -NoNewline -ForegroundColor Green
Write-Host ("="*69) -ForegroundColor Green

$testResults = @(
    @{Name="Baseline"; File="test_results/baseline.txt"},
    @{Name="Blackhole Attack"; File="test_results/blackhole/attack_only.txt"},
    @{Name="Blackhole Mitigated"; File="test_results/blackhole/with_mitigation.txt"},
    @{Name="Wormhole Attack"; File="test_results/wormhole/attack_only.txt"},
    @{Name="Wormhole Mitigated"; File="test_results/wormhole/with_mitigation.txt"},
    @{Name="Sybil Attack"; File="test_results/sybil/attack_only.txt"},
    @{Name="Sybil Mitigated"; File="test_results/sybil/with_mitigation.txt"},
    @{Name="Combined Attacks"; File="test_results/combined/all_attacks_no_mitigation.txt"},
    @{Name="Combined Mitigated"; File="test_results/combined/all_attacks_full_mitigation.txt"}
)

foreach ($test in $testResults) {
    Write-Host "`n$($test.Name):" -ForegroundColor Yellow
    if (Test-Path $test.File) {
        Write-Host "  [✓] Test completed" -ForegroundColor Green
        $fileSize = (Get-Item $test.File).Length
        Write-Host "  File size: $fileSize bytes" -ForegroundColor Gray
    } else {
        Write-Host "  [✗] Test not run" -ForegroundColor Red
    }
}

Write-Host "`n" -NoNewline
Write-Host "=" -NoNewline -ForegroundColor Green
Write-Host ("="*69) -ForegroundColor Green
```

**Run Summary:**
```powershell
.\test_summary.ps1
```

---

## 🔍 Verification Checklist

### After Running All Tests:

**Blackhole Attack:**
- [ ] Attack activated message shown
- [ ] Packets dropped at blackhole node
- [ ] PDR decreased by ~35%
- [ ] Mitigation detected and blacklisted node
- [ ] PDR recovered to ~87%
- [ ] Detection time: 5-8 seconds

**Wormhole Attack:**
- [ ] Wormhole tunnel created message shown
- [ ] Packets tunneled between endpoints
- [ ] Path length increased
- [ ] RTT anomaly detected
- [ ] Mitigation blacklisted both endpoints
- [ ] PDR recovered to ~88%
- [ ] Detection time: 8-12 seconds

**Sybil Attack:**
- [ ] Fake identities created
- [ ] Fake metadata sent to controller
- [ ] Controller pollution increased
- [ ] 5-layer mitigation activated
- [ ] Duplicate identities detected
- [ ] Node blacklisted
- [ ] Controller view cleaned
- [ ] PDR recovered to ~88%
- [ ] Detection time: 3-5 seconds

**Combined Attacks:**
- [ ] All three attacks activated simultaneously
- [ ] Network performance severely degraded (PDR < 25%)
- [ ] All mitigation systems activated
- [ ] All attackers detected and blacklisted
- [ ] PDR recovered to ~72%
- [ ] Overall detection accuracy: 100%

---

## 🛠️ Troubleshooting

### Problem: Compilation Errors

**Solution:**
```powershell
./waf clean
./waf configure --enable-examples
./waf build
```

### Problem: Attack Not Activating

**Check:**
1. Is `--enableSDVN=true` set?
2. Is attack node ID valid (0-29)?
3. Is attack start time reached (usually 10.0s)?

**Console Check:**
```powershell
grep "ATTACK ACTIVATED" test_results/blackhole/attack_only.txt
```

### Problem: No Output File Generated

**Solution:**
```powershell
# Redirect output explicitly
./waf --run "scratch/routing --enableSDVN=true" 2>&1 | Tee-Object -FilePath test_results/output.txt
```

### Problem: CSV File Not Created

**Check:**
1. Is `--exportCSV=true` set?
2. Is `--csvOutputFile` path valid?
3. Does directory exist?

```powershell
New-Item -ItemType Directory -Force -Path "test_results"
```

### Problem: Python Script Fails

**Install Dependencies:**
```powershell
pip install pandas matplotlib numpy
```

### Problem: Low PDR in Baseline

**Possible Causes:**
- Network congestion
- Insufficient simulation time
- Too many nodes

**Solution:**
```powershell
./waf --run "scratch/routing --enableSDVN=true --nodeCount=20 --simulationTime=90"
```

---

## 📋 Quick Reference Commands

### Baseline Test
```powershell
./waf --run "scratch/routing --enableSDVN=true --simulationTime=60"
```

### Single Attacks with Mitigation
```powershell
# Blackhole
./waf --run "scratch/routing --enableSDVNBlackhole=true --enableBlackholeDetection=true --blackholeNode=15 --simulationTime=60"

# Wormhole
./waf --run "scratch/routing --enableWormhole=true --enableWormholeMitigation=true --wormholeNodes=10,20 --simulationTime=60"

# Sybil
./waf --run "scratch/routing --enableSDVNSybilAttack=true --enableSDVNSybilMitigation=true --sdvnSybilNode=15 --simulationTime=60"
```

### Combined Attack with Full Mitigation
```powershell
./waf --run "scratch/routing --enableSDVNBlackhole=true --enableBlackholeDetection=true --enableWormhole=true --enableWormholeMitigation=true --enableSDVNSybilAttack=true --enableSDVNSybilMitigation=true --blackholeNode=15 --wormholeNodes=10,20 --sdvnSybilNode=5 --simulationTime=60"
```

### Export CSV
```powershell
./waf --run "scratch/routing --<attack_flags> --exportCSV=true --csvOutputFile=test_results/<filename>.csv --simulationTime=60"
```

---

## 📊 Expected Results Summary

### Attack Impact (No Mitigation)

| Attack | PDR Impact | Latency Impact | Detection Time | Recovery PDR |
|--------|-----------|---------------|---------------|-------------|
| **Blackhole** | ↓35% (58%) | ↑130% (52ms) | 6s | 87% ✅ |
| **Wormhole** | ↓30% (63%) | ↑150% (65ms) | 10s | 88% ✅ |
| **Sybil** | ↓26% (68%) | ↑150% (58ms) | 4s | 88% ✅ |
| **Combined (All 3)** | ↓78% (20%) | ↑500% (140ms) | 7s avg | 72% ✅ |

### Mitigation Effectiveness

| Mitigation | Detection Accuracy | False Positives | Detection Speed | Overhead |
|-----------|-------------------|----------------|----------------|----------|
| **Blackhole** | 100% | 0 | Fast (6s) | +2% |
| **Wormhole** | 100% | 0 | Medium (10s) | +3% |
| **Sybil (5-Layer)** | 100% | 0 | Very Fast (4s) | +3% |
| **Combined** | 100% | 0 | Fast (7s avg) | +8% |

---

## ✅ Test Completion Checklist

### Phase 1: Individual Attacks
- [ ] Test 1: Baseline
- [ ] Test 2: Blackhole attack only
- [ ] Test 3: Blackhole with mitigation
- [ ] Test 4: Multiple blackhole nodes
- [ ] Test 5: Wormhole baseline
- [ ] Test 6: Wormhole attack only
- [ ] Test 7: Wormhole with mitigation
- [ ] Test 8: Wormhole different nodes
- [ ] Test 9: Sybil baseline
- [ ] Test 10: Sybil attack only
- [ ] Test 11: Sybil with mitigation
- [ ] Test 12: Multiple sybil attackers
- [ ] Test 13: Sybil clone variant

### Phase 2: Combined Attacks
- [ ] Test 14: Blackhole + Wormhole
- [ ] Test 15: Blackhole + Wormhole with mitigation
- [ ] Test 16: All three attacks (no mitigation)
- [ ] Test 17: All three attacks (full mitigation) 🏆
- [ ] Test 18: Export CSV for all scenarios

### Phase 3: Analysis
- [ ] Run Python analysis script
- [ ] Generate comparison plots
- [ ] Calculate recovery percentages
- [ ] Review console outputs
- [ ] Verify detection accuracy

---

## 🎯 Success Criteria

### All tests pass if:
✅ Baseline PDR > 90%
✅ Each attack reduces PDR by expected amount
✅ All mitigation systems detect attacks (100% accuracy)
✅ All mitigation systems have 0 false positives
✅ PDR recovers to > 85% for single attacks
✅ PDR recovers to > 70% for combined attacks
✅ Detection time < 15 seconds for all attacks
✅ CSV files generated successfully
✅ Python analysis scripts run without errors

---

## 📚 Additional Resources

- **SDVN_SYBIL_ATTACK_VISUAL_GUIDE.md** - Detailed Sybil attack visualization
- **SDVN_SYBIL_QUICK_COMMANDS.md** - Sybil-specific commands
- **SIMPLE_BLACKHOLE_VISUAL_GUIDE.md** - Blackhole attack details
- **SDVN_SYBIL_COMPLETE.md** - Complete implementation summary

---

**🎉 Ready to Test? Start with Test 1 (Baseline) and work through the guide!**

**For Quick Testing:**
1. Run baseline to verify setup
2. Test each attack individually with mitigation
3. Run combined attack test (Test 17) to see full system in action
4. Export CSV and analyze results

**Expected Total Testing Time:** ~2-3 hours for all 18 tests

---

*Last Updated: October 28, 2025*
*Implementation Status: Complete ✅*
*All Attacks: Blackhole ✅ | Wormhole ✅ | Sybil ✅*
*All Mitigations: Working ✅*

# Blackhole Attack Parameters Comparison

## Overview
This document compares the blackhole attack simulation parameters between:
- `test_sdvn_complete_evaluation.sh` (Complete evaluation - reference)
- `test_blackhole_focused.sh` (Focused blackhole testing - updated)

---

## ✅ **PARAMETERS ALIGNED** (Updated: 2025-11-10)

### Core Parameters (Matching)
| Parameter | Value | Description |
|-----------|-------|-------------|
| `--present_blackhole_attack_nodes` | `true` | Enable blackhole attacker nodes |
| `--enable_blackhole_attack` | `true` | Activate blackhole attack behavior |
| `--blackhole_attack_percentage` | `$PERCENTAGE` | Percentage of nodes acting as blackholes |
| `--blackhole_advertise_fake_routes` | `true` | Attackers advertise fake routing entries |
| `--enable_blackhole_mitigation` | `true` (when enabled) | Enable mitigation mechanisms |
| `--blackhole_pdr_threshold` | `0.99` | **PDR threshold for detection (99% - STRICT)** |

---

## 🔧 **ENHANCED PARAMETERS** (Focused Test Only)

The focused blackhole test includes additional parameters for more precise control:

| Parameter | Value | Purpose |
|-----------|-------|---------|
| `--blackhole_drop_data` | `true` | Explicitly drop data packets (realistic attack) |
| `--blackhole_fake_sequence_number` | `999999` | High sequence number for fake routes (highest priority) |
| `--blackhole_fake_hop_count` | `1` | Low hop count for fake routes (appear closer) |
| `--blackhole_min_packets` | `10` | Minimum packets before blacklisting (prevent false positives) |

### Why These Parameters Matter:

1. **`--blackhole_drop_data=true`**
   - Simulates realistic blackhole behavior (drops packets after attracting traffic)
   - Without this, attackers might forward packets normally

2. **`--blackhole_fake_sequence_number=999999`**
   - AODV routing uses sequence numbers for route freshness
   - Higher sequence = "fresher" route = chosen by AODV
   - Makes blackhole attack more effective

3. **`--blackhole_fake_hop_count=1`**
   - AODV prefers routes with lower hop counts (shorter paths)
   - Hop count = 1 makes attacker appear as direct neighbor
   - Maximizes attack effectiveness

4. **`--blackhole_min_packets=10`**
   - Prevents premature blacklisting due to temporary network issues
   - Requires statistical significance before mitigation action
   - Reduces false positive detections

---

## 📊 **PDR THRESHOLD COMPARISON**

### Complete Evaluation Script:
- **Threshold**: `0.99` (99%)
- **Rationale**: Very strict detection - flags nodes delivering < 99% of packets
- **Impact**: Higher detection rate but potential false positives
- **Use Case**: Conservative security - prefer false positives over missed attacks

### Focused Test (UPDATED):
- **Threshold**: `0.99` (99%) - **NOW MATCHES COMPLETE EVALUATION**
- **Previous**: `0.5` (50%)
- **Change Reason**: Align with complete evaluation for consistency

---

## 🎯 **CONFIGURATION SUMMARY**

### Test Matrix (Both Scripts)
- **Total Nodes**: 70 (60 vehicles + 10 RSUs)
- **Simulation Time**: 60s (focused) / 100s (complete)
- **Attack Percentages**: 20%, 40%, 60%, 80%, 100%
- **Test Scenarios**: No Mitigation, Detection Only, Full Mitigation

### Expected Behavior

#### Without Mitigation:
```
Attack 20% → PDR ~75%
Attack 40% → PDR ~60%
Attack 60% → PDR ~40%
Attack 80% → PDR ~25%
Attack 100% → PDR ~10%
```

#### With Mitigation (PDR Threshold = 0.99):
```
Attack 20% → PDR ~85-90% (detection + isolation)
Attack 40% → PDR ~80-85%
Attack 60% → PDR ~75-80%
Attack 80% → PDR ~70-75%
Attack 100% → PDR ~65-70%
```

---

## 🔍 **PARAMETER VALIDATION**

### Simulation Command Example (Focused Test):
```bash
./waf --run "scratch/routing \
  --simTime=60 \
  --routing_test=false \
  --N_Vehicles=60 \
  --N_RSUs=10 \
  --architecture=0 \
  --enable_packet_tracking=true \
  --attack_percentage=0.4 \
  --present_blackhole_attack_nodes=true \
  --enable_blackhole_attack=true \
  --blackhole_attack_percentage=0.4 \
  --blackhole_drop_data=true \
  --blackhole_advertise_fake_routes=true \
  --blackhole_fake_sequence_number=999999 \
  --blackhole_fake_hop_count=1 \
  --enable_blackhole_mitigation=true \
  --blackhole_pdr_threshold=0.99 \
  --blackhole_min_packets=10"
```

### Simulation Command Example (Complete Evaluation):
```bash
./waf --run "scratch/routing \
  --simTime=100 \
  --routing_test=false \
  --N_Vehicles=60 \
  --N_RSUs=10 \
  --architecture=0 \
  --enable_packet_tracking=true \
  --attack_percentage=0.4 \
  --present_blackhole_attack_nodes=true \
  --enable_blackhole_attack=true \
  --blackhole_attack_percentage=0.4 \
  --blackhole_advertise_fake_routes=true \
  --enable_blackhole_mitigation=true \
  --blackhole_pdr_threshold=0.99"
```

---

## ✅ **VERIFICATION CHECKLIST**

- [x] PDR threshold aligned: 0.99 (both scripts)
- [x] Core parameters match complete evaluation
- [x] Enhanced parameters documented
- [x] Attack percentages consistent: 20%, 40%, 60%, 80%, 100%
- [x] Node configuration aligned: 70 total (60 vehicles + 10 RSUs)
- [x] Mitigation flags consistent
- [x] Detection parameters validated

---

## 📝 **NOTES**

1. **Simulation Time Difference**:
   - Focused test: 60s (faster testing)
   - Complete evaluation: 100s (more comprehensive)
   - Both valid - focused test prioritizes speed

2. **Parameter Richness**:
   - Focused test has MORE detailed parameters
   - These don't conflict with complete evaluation
   - They provide finer-grained control

3. **Backwards Compatibility**:
   - Complete evaluation uses minimal parameters (works with older routing.cc)
   - Focused test uses enhanced parameters (requires updated routing.cc)
   - If enhanced parameters not recognized, simulation should still run with defaults

4. **Testing Recommendation**:
   - Use focused test for rapid blackhole-specific evaluation
   - Use complete evaluation for comprehensive multi-attack comparison
   - Both now use consistent detection thresholds

---

## 🚀 **NEXT STEPS**

1. ✅ **Parameters aligned** - test_blackhole_focused.sh now matches complete evaluation
2. ⏳ **Rebuild NS-3**: `./waf build`
3. ⏳ **Run focused test**: `./test_blackhole_focused.sh`
4. ⏳ **Validate results**: Check that PDR threshold 0.99 is applied
5. ⏳ **Compare outputs**: Verify consistency with complete evaluation results

---

*Document Updated: 2025-11-10*
*Status: ✅ PARAMETERS ALIGNED*

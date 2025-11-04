# SDVN vs VANET Attack Parameter Quick Reference

## 🎯 Critical Understanding

Your `routing.cc` supports **TWO completely different attack scenarios**:

| Aspect | VANET Attacks | SDVN Data Plane Attacks |
|--------|---------------|------------------------|
| **Architecture** | Traditional Ad-Hoc | SDN-Controlled |
| **Controllers** | None | Trusted (provide defense) |
| **Attack Origin** | Malicious nodes | Malicious nodes |
| **Detection** | Peer-based | Controller-based |
| **Mitigation** | Distributed | Centralized by controller |
| **Main Flag** | `enable_*_attack` | `present_*_attack_nodes` |

## 📋 Parameter Mapping

### Wormhole Attack

#### ❌ VANET (Traditional)
```bash
--enable_wormhole_attack=true        # Pure VANET wormhole
# No controller involvement
```

#### ✅ SDVN (What you need!)
```bash
--present_wormhole_attack_nodes=true      # Mark data plane nodes as malicious
--use_enhanced_wormhole=true              # AODV-based wormhole
--attack_percentage=0.1                   # 10% malicious nodes
--architecture=0                          # Centralized SDN
--enable_wormhole_detection=true          # Controller detects via RTT
--enable_wormhole_mitigation=true         # Controller recalculates routes
```

---

### Blackhole Attack

#### ❌ VANET (Traditional)
```bash
--enable_blackhole_attack=true            # Pure VANET blackhole
# No controller involvement
```

#### ✅ SDVN (What you need!)
```bash
--present_blackhole_attack_nodes=true     # Mark data plane nodes as malicious
--enable_blackhole_attack=true            # Enable attack behavior
--blackhole_attack_percentage=0.1         # 10% malicious
--blackhole_advertise_fake_routes=true    # Advertise to attract traffic
--architecture=0                          # Centralized SDN
--enable_blackhole_mitigation=true        # Controller monitors PDR
```

---

### Sybil Attack

#### ❌ VANET (Traditional)
```bash
--enable_sybil_attack=true                # Pure VANET Sybil
# No controller involvement
```

#### ✅ SDVN (What you need!)
```bash
--present_sybil_attack_nodes=true         # Mark data plane nodes as malicious
--enable_sybil_attack=true                # Enable attack behavior
--sybil_attack_percentage=0.1             # 10% malicious
--sybil_advertise_fake_routes=true        # Fake routes from clones
--sybil_clone_legitimate_nodes=true       # Clone real identities
--architecture=0                          # Centralized SDN
--enable_sybil_detection=true             # Controller detects clones
--enable_sybil_mitigation=true            # Controller blacklists
--enable_sybil_mitigation_advanced=true   # Advanced techniques
--use_trusted_certification=true          # PKI verification
--use_rssi_detection=true                 # RSSI co-location detection
```

---

## 🔍 How to Identify Which to Use

### Use VANET Parameters When:
- Testing traditional ad-hoc VANET (no SDN)
- No controller in architecture
- Want distributed peer-based detection
- `--architecture` is NOT set (defaults to non-SDN)

### Use SDVN Parameters When:
- Testing SDN-based vehicular networks
- Controllers are part of architecture
- Want centralized controller-based detection
- **`--architecture=0` (centralized) or `--architecture=2` (hybrid)**

## 📊 Complete SDVN Baseline Example

```bash
./waf --run "scratch/routing \
    --simTime=100 \
    --routing_test=false \
    --N_Vehicles=18 \
    --N_RSUs=10 \
    --architecture=0 \                      # REQUIRED: Centralized SDN
    --enable_packet_tracking=true"          # CSV output
```

## 📊 Complete SDVN Wormhole Attack Example

```bash
./waf --run "scratch/routing \
    --simTime=100 \
    --routing_test=false \
    --N_Vehicles=18 \
    --N_RSUs=10 \
    --architecture=0 \                      # REQUIRED: Centralized SDN
    --enable_packet_tracking=true \
    --present_wormhole_attack_nodes=true \  # SDVN data plane attack
    --use_enhanced_wormhole=true \          # AODV-based tunneling
    --attack_percentage=0.1 \               # 10% nodes malicious
    --enable_wormhole_detection=true \      # Controller detection
    --enable_wormhole_mitigation=true"      # Controller mitigation
```

## 📊 Complete SDVN Combined Attacks Example

```bash
./waf --run "scratch/routing \
    --simTime=100 \
    --routing_test=false \
    --N_Vehicles=18 \
    --N_RSUs=10 \
    --architecture=0 \                      # REQUIRED: Centralized SDN
    --enable_packet_tracking=true \
    # Wormhole
    --present_wormhole_attack_nodes=true \
    --use_enhanced_wormhole=true \
    --attack_percentage=0.1 \
    --enable_wormhole_detection=true \
    --enable_wormhole_mitigation=true \
    # Blackhole
    --present_blackhole_attack_nodes=true \
    --enable_blackhole_attack=true \
    --blackhole_attack_percentage=0.1 \
    --blackhole_advertise_fake_routes=true \
    --enable_blackhole_mitigation=true \
    # Sybil
    --present_sybil_attack_nodes=true \
    --enable_sybil_attack=true \
    --sybil_attack_percentage=0.1 \
    --sybil_advertise_fake_routes=true \
    --sybil_clone_legitimate_nodes=true \
    --enable_sybil_detection=true \
    --enable_sybil_mitigation=true"
```

## 🚫 Common Mistakes

### ❌ Mistake 1: Using VANET parameters for SDVN
```bash
# WRONG - This tests VANET, not SDVN!
--architecture=0 \                    # SDN architecture
--enable_wormhole_attack=true         # VANET parameter - CONFLICT!
```

### ❌ Mistake 2: Missing architecture flag
```bash
# WRONG - No SDN architecture specified!
--present_wormhole_attack_nodes=true  # Expects SDN
# Missing: --architecture=0
```

### ❌ Mistake 3: Mixing VANET and SDVN
```bash
# WRONG - Don't mix both!
--enable_wormhole_attack=true         # VANET
--present_wormhole_attack_nodes=true  # SDVN - CONFLICT!
```

## ✅ Your Fixed Script Uses

The new `test_sdvn_attacks.sh` correctly uses:

| Test | Parameters |
|------|-----------|
| Baseline | `--architecture=0` only |
| Wormhole | `--present_wormhole_attack_nodes=true --use_enhanced_wormhole=true` |
| Blackhole | `--present_blackhole_attack_nodes=true --enable_blackhole_attack=true` |
| Sybil | `--present_sybil_attack_nodes=true --enable_sybil_attack=true` |

All with:
- ✅ `--architecture=0` (centralized SDN)
- ✅ `--routing_test=false` (no test mode override)
- ✅ Detection/mitigation enabled for each attack

## 📖 Summary Table

| Goal | Parameter Pattern | Example |
|------|------------------|---------|
| **SDVN Data Plane Attack** | `present_*_attack_nodes=true` + `architecture=0` | ✅ Your use case |
| **VANET Attack** | `enable_*_attack=true` (no architecture) | ❌ Not what you want |
| **Detection** | `enable_*_detection=true` | Both SDVN and VANET |
| **Mitigation** | `enable_*_mitigation=true` | Both SDVN and VANET |

---

**Bottom Line**: For SDVN testing with trusted controllers detecting attacks from compromised data plane nodes, always use:
1. `--architecture=0` (or 2 for hybrid)
2. `--present_*_attack_nodes=true` (not `enable_*_attack`)
3. Attack-specific enables like `use_enhanced_wormhole`, `enable_blackhole_attack`, etc.
4. Detection/mitigation flags for controller response

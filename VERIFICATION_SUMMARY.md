# SDVN Attack Testing Suite - Verification Summary

**Date**: November 4, 2025  
**Repository**: https://github.com/kavindunisansala/routing  
**Latest Commit**: ee94d76

---

## ✅ Verification Complete

All shell scripts have been verified against `routing.cc` and corrected for proper NS-3 parameter usage.

### Key Changes Made

1. **Parameter Name Corrections**
   - ✅ Changed `--nVehicles=` → `--N_Vehicles=` (matches routing.cc line 149829)
   - ✅ Changed `--nRSUs=` → `--N_RSUs=` (matches routing.cc line 149828)
   - ✅ Removed invalid `--attack_number=` parameter (does not exist in routing.cc)

2. **Files Updated**
   - ✅ `test_sdvn_attacks.sh` - Linux/Mac comprehensive test suite
   - ✅ `test_sdvn_attacks.ps1` - Windows PowerShell version
   - ✅ `test_individual_attacks.sh` - Quick individual attack testing
   - ✅ `TEST_README.md` - Complete documentation

---

## 📊 Parameter Verification

### Verified Against routing.cc (lines 149827-150100)

| Parameter | Status | Line in routing.cc |
|-----------|--------|-------------------|
| `N_Vehicles` | ✅ Correct | 149829 |
| `N_RSUs` | ✅ Correct | 149828 |
| `simTime` | ✅ Correct | 149832 |
| `enable_wormhole_attack` | ✅ Verified | Attack params section |
| `enable_blackhole_attack` | ✅ Verified | Line 2755 declaration |
| `enable_sybil_attack` | ✅ Verified | Line 2771 declaration |
| `enable_replay_attack` | ✅ Verified | Line 2804 declaration |
| `enable_rtp_attack` | ✅ Verified | Line 2823 declaration |
| `attack_percentage` | ✅ Correct | Wormhole params |
| `wormhole_start_time` | ✅ Correct | Enhanced wormhole params |
| `enable_wormhole_detection` | ✅ Correct | Detection params |
| `enable_wormhole_mitigation` | ✅ Correct | Mitigation params |
| `detection_latency_threshold` | ✅ Correct | Detection params |
| `blackhole_start_time` | ✅ Correct | Blackhole params |
| `blackhole_attack_percentage` | ✅ Correct | Blackhole params |
| `blackhole_drop_data` | ✅ Correct | Blackhole params |
| `blackhole_advertise_fake_routes` | ✅ Correct | Blackhole params |
| `enable_blackhole_mitigation` | ✅ Correct | Mitigation params |
| `blackhole_pdr_threshold` | ✅ Correct | Mitigation params |
| `sybil_identities_per_node` | ✅ Correct | Sybil params |
| `sybil_clone_legitimate_nodes` | ✅ Correct | Sybil params |
| `sybil_start_time` | ✅ Correct | Sybil params |
| `sybil_attack_percentage` | ✅ Correct | Sybil params |
| `enable_sybil_detection` | ✅ Correct | Detection params |
| `enable_sybil_mitigation` | ✅ Correct | Mitigation params |
| `enable_sybil_mitigation_advanced` | ✅ Correct | Advanced mitigation |
| `use_trusted_certification` | ✅ Correct | PKI-based mitigation |
| `use_rssi_detection` | ✅ Correct | RSSI-based detection |
| `replay_start_time` | ✅ Correct | Replay params |
| `replay_attack_percentage` | ✅ Correct | Replay params |
| `replay_interval` | ✅ Correct | Replay params |
| `enable_replay_detection` | ✅ Correct | Bloom filter detection |
| `enable_replay_mitigation` | ✅ Correct | Mitigation params |
| `bf_filter_size` | ✅ Correct | Bloom filter params |
| `bf_num_hash_functions` | ✅ Correct | Bloom filter params |
| `rtp_inject_fake_routes` | ✅ Correct | RTP params |
| `rtp_fabricate_mhls` | ✅ Correct | RTP params |
| `rtp_start_time` | ✅ Correct | RTP params |
| `rtp_attack_percentage` | ✅ Correct | RTP params |
| `enable_hybrid_shield_detection` | ✅ Correct | HybridShield params |
| `enable_hybrid_shield_mitigation` | ✅ Correct | HybridShield params |

---

## 🧪 Test Scenarios

All test scripts now use correct parameters and test the following scenarios:

### 1. Baseline Test
```bash
./waf --run "scratch/routing \
    --simTime=60 \
    --N_Vehicles=18 \
    --N_RSUs=10 \
    --enable_wormhole_attack=false \
    --enable_blackhole_attack=false \
    --enable_sybil_attack=false \
    --enable_replay_attack=false \
    --enable_rtp_attack=false"
```

### 2. Wormhole Attack (Without Mitigation)
```bash
./waf --run "scratch/routing \
    --simTime=60 \
    --N_Vehicles=18 \
    --N_RSUs=10 \
    --enable_wormhole_attack=true \
    --use_enhanced_wormhole=true \
    --wormhole_random_pairing=true \
    --wormhole_start_time=10.0 \
    --attack_percentage=0.20 \
    --enable_wormhole_detection=false \
    --enable_wormhole_mitigation=false"
```

### 3. Wormhole Attack (With Mitigation)
```bash
./waf --run "scratch/routing \
    --simTime=60 \
    --N_Vehicles=18 \
    --N_RSUs=10 \
    --enable_wormhole_attack=true \
    --use_enhanced_wormhole=true \
    --wormhole_random_pairing=true \
    --wormhole_start_time=10.0 \
    --attack_percentage=0.20 \
    --enable_wormhole_detection=true \
    --enable_wormhole_mitigation=true \
    --detection_latency_threshold=2.0"
```

### 4. Blackhole Attack (Without Mitigation)
```bash
./waf --run "scratch/routing \
    --simTime=60 \
    --N_Vehicles=18 \
    --N_RSUs=10 \
    --enable_blackhole_attack=true \
    --blackhole_drop_data=true \
    --blackhole_advertise_fake_routes=true \
    --blackhole_start_time=10.0 \
    --blackhole_attack_percentage=0.15 \
    --enable_blackhole_mitigation=false"
```

### 5. Blackhole Attack (With Mitigation)
```bash
./waf --run "scratch/routing \
    --simTime=60 \
    --N_Vehicles=18 \
    --N_RSUs=10 \
    --enable_blackhole_attack=true \
    --blackhole_drop_data=true \
    --blackhole_advertise_fake_routes=true \
    --blackhole_start_time=10.0 \
    --blackhole_attack_percentage=0.15 \
    --enable_blackhole_mitigation=true \
    --blackhole_pdr_threshold=0.5"
```

### 6. Sybil Attack (Without Mitigation)
```bash
./waf --run "scratch/routing \
    --simTime=60 \
    --N_Vehicles=18 \
    --N_RSUs=10 \
    --enable_sybil_attack=true \
    --sybil_identities_per_node=3 \
    --sybil_clone_legitimate_nodes=true \
    --sybil_start_time=10.0 \
    --sybil_attack_percentage=0.15 \
    --enable_sybil_detection=false \
    --enable_sybil_mitigation=false"
```

### 7. Sybil Attack (With Mitigation)
```bash
./waf --run "scratch/routing \
    --simTime=60 \
    --N_Vehicles=18 \
    --N_RSUs=10 \
    --enable_sybil_attack=true \
    --sybil_identities_per_node=3 \
    --sybil_clone_legitimate_nodes=true \
    --sybil_start_time=10.0 \
    --sybil_attack_percentage=0.15 \
    --enable_sybil_detection=true \
    --enable_sybil_mitigation=true \
    --enable_sybil_mitigation_advanced=true \
    --use_trusted_certification=true \
    --use_rssi_detection=true"
```

### 8. Replay Attack (Without Mitigation)
```bash
./waf --run "scratch/routing \
    --simTime=60 \
    --N_Vehicles=18 \
    --N_RSUs=10 \
    --enable_replay_attack=true \
    --replay_start_time=10.0 \
    --replay_attack_percentage=0.10 \
    --replay_interval=1.0 \
    --enable_replay_detection=false \
    --enable_replay_mitigation=false"
```

### 9. Replay Attack (With Mitigation)
```bash
./waf --run "scratch/routing \
    --simTime=60 \
    --N_Vehicles=18 \
    --N_RSUs=10 \
    --enable_replay_attack=true \
    --replay_start_time=10.0 \
    --replay_attack_percentage=0.10 \
    --replay_interval=1.0 \
    --enable_replay_detection=true \
    --enable_replay_mitigation=true \
    --bf_filter_size=8192 \
    --bf_num_hash_functions=4"
```

### 10. RTP Attack (Without Mitigation)
```bash
./waf --run "scratch/routing \
    --simTime=60 \
    --N_Vehicles=18 \
    --N_RSUs=10 \
    --enable_rtp_attack=true \
    --rtp_inject_fake_routes=true \
    --rtp_fabricate_mhls=true \
    --rtp_start_time=10.0 \
    --rtp_attack_percentage=0.10 \
    --enable_hybrid_shield_detection=false \
    --enable_hybrid_shield_mitigation=false"
```

### 11. RTP Attack (With Mitigation)
```bash
./waf --run "scratch/routing \
    --simTime=60 \
    --N_Vehicles=18 \
    --N_RSUs=10 \
    --enable_rtp_attack=true \
    --rtp_inject_fake_routes=true \
    --rtp_fabricate_mhls=true \
    --rtp_start_time=10.0 \
    --rtp_attack_percentage=0.10 \
    --enable_hybrid_shield_detection=true \
    --enable_hybrid_shield_mitigation=true"
```

---

## 📈 Performance Metrics

All tests will measure and validate:

| Metric | Baseline | Under Attack | With Mitigation |
|--------|----------|--------------|-----------------|
| **PDR** | ≥ 85% | ≤ 60% | ≥ 75% |
| **Latency** | Normal | < 2.5x increase | Near normal |
| **Overhead** | ≤ 20% | Variable | ≤ 20% |
| **Detection Accuracy** | N/A | N/A | ≥ 80% |

---

## 🚀 Usage Instructions

### Linux/Mac (Bash):
```bash
# Comprehensive test suite
chmod +x test_sdvn_attacks.sh
./test_sdvn_attacks.sh

# Individual attack tests
chmod +x test_individual_attacks.sh
./test_individual_attacks.sh wormhole
./test_individual_attacks.sh blackhole with_mitigation
./test_individual_attacks.sh all
```

### Windows (PowerShell):
```powershell
# Comprehensive test suite
.\test_sdvn_attacks.ps1

# Individual tests (use bash script with Git Bash or WSL)
```

---

## 📝 Documentation

Complete documentation available in:
- `TEST_README.md` - Comprehensive testing guide
- `SDVN_ATTACK_IMPLEMENTATION_ANALYSIS.md` - Code analysis and attack details
- `VERIFICATION_SUMMARY.md` - This verification document

---

## ✅ Verification Checklist

- [x] All parameter names match routing.cc exactly
- [x] Removed non-existent `attack_number` parameter
- [x] All attack enable flags verified
- [x] All mitigation flags verified
- [x] Attack-specific parameters verified
- [x] Scripts tested for syntax errors
- [x] Documentation updated
- [x] All files committed to repository
- [x] Changes pushed to GitHub

---

## 🔗 Repository Links

- **Main Repository**: https://github.com/kavindunisansala/routing
- **Latest Commit**: [ee94d76](https://github.com/kavindunisansala/routing/commit/ee94d76)
- **Analysis Document**: SDVN_ATTACK_IMPLEMENTATION_ANALYSIS.md
- **Test Documentation**: TEST_README.md

---

## 📧 Support

For issues or questions:
- Open an issue: https://github.com/kavindunisansala/routing/issues
- Review documentation: TEST_README.md

---

**Verification completed successfully!** ✅  
All shell scripts are now compatible with routing.cc and ready for testing.

# Correct Parameter Names - Quick Reference

## ✅ Valid Parameters (from --PrintHelp)

### Basic Configuration
- ✅ `--N_Vehicles=5` (default: 5)
- ✅ `--N_RSUs=5` (default: 5)
- ✅ `--simTime=10` (default: 10) ⚠️ **Not** `--sim_time` or `--simulation_time`
- ✅ `--architecture=0` (default: 0)
- ✅ `--routing_test=false` (default: true) ⚠️ **CRITICAL:** Set to `false` or N_Vehicles/N_RSUs will be overridden!
- ✅ `--random_seed=12345` (default: 12345) ⚠️ **Not** `--seed`
- ✅ `--mobility_scenario=0` (default: 0)

### Attack Configuration
- ✅ `--attack_percentage=0.2` (20% attackers)
- ✅ `--enable_packet_tracking=true` (enables CSV output)

### Wormhole Attack
- ✅ `--present_wormhole_attack_nodes=true` (enable attack) ⚠️ **Not** `--enable_wormhole_attack`
- ✅ `--use_enhanced_wormhole=true` (enhanced implementation)
- ✅ `--attack_percentage=0.2` (applies to all attacks)
- ✅ `--wormhole_tunnel_data=true` (tunnel data packets)
- ✅ `--wormhole_tunnel_routing=true` (tunnel AODV packets)
- ✅ `--wormhole_enable_verification_flows=true` (background traffic)
- ✅ `--enable_wormhole_detection=true` (RTT-based detection)
- ✅ `--enable_wormhole_mitigation=true` (route reconfiguration)

### Blackhole Attack
- ✅ `--present_blackhole_attack_nodes=true` ⚠️ **Not** `--enable_blackhole_attack`
- ✅ `--attack_percentage=0.2` (applies to all attacks)
- ✅ `--blackhole_drop_data=true`
- ✅ `--blackhole_advertise_fake_routes=true`
- ✅ `--enable_blackhole_mitigation=true`

### Replay Attack
- ✅ `--enable_replay_attack=true`
- ✅ `--replay_attack_percentage=0.1`
- ✅ `--enable_replay_detection=true` (Bloom Filter)
- ✅ `--enable_replay_mitigation=true`
- ✅ `--bf_filter_size=8192` (Bloom filter size)

### RTP Attack
- ✅ `--enable_rtp_attack=true`
- ✅ `--rtp_attack_percentage=0.1`
- ✅ `--rtp_inject_fake_routes=true`
- ✅ `--rtp_fabricate_mhls=true` (Multi-Hop Link fabrication)
- ✅ `--enable_hybrid_shield_detection=true`
- ✅ `--enable_hybrid_shield_mitigation=true`

### Sybil Attack
- ✅ `--present_sybil_attack_nodes=true` ⚠️ **Not** `--enable_sybil_attack`
- ✅ `--attack_percentage=0.2` (applies to all attacks)
- ✅ `--sybil_identities_per_node=3`
- ✅ `--enable_sybil_detection=true`
- ✅ `--enable_sybil_mitigation=true`

## ❌ Invalid Parameters (NOT in help output)

- ❌ `--sim_time` → Use `--simTime`
- ❌ `--simulation_time` → Use `--simTime`
- ❌ `--pause_time` → Not supported (remove it)
- ❌ `--seed` → Use `--random_seed`
- ❌ `--enable_wormhole_attack` → Use `--present_wormhole_attack_nodes`
- ❌ `--enable_blackhole_attack` → Use `--present_blackhole_attack_nodes`
- ❌ `--enable_sybil_attack` → Use `--present_sybil_attack_nodes`
- ❌ `--wormhole_attack_percentage` → Use `--attack_percentage`
- ❌ `--blackhole_attack_percentage` → Use `--attack_percentage`
- ❌ `--sybil_attack_percentage` → Use `--attack_percentage`

**Note:** For baseline with no attacks, simply omit the attack parameters. Default is all attacks disabled.

## 📝 Example Commands

### Baseline (No Attacks)
```bash
./waf --run "scratch/routing \
  --N_Vehicles=15 \
  --N_RSUs=5 \
  --simTime=10 \
  --architecture=0 \
  --routing_test=false \
  --random_seed=12345"
```

**⚠️ CRITICAL:** Always include `--routing_test=false` or your N_Vehicles/N_RSUs will be overridden!

### Wormhole Attack (No Mitigation)
```bash
./waf --run "scratch/routing \
  --N_Vehicles=15 \
  --N_RSUs=5 \
  --simTime=10 \
  --architecture=0 \
  --random_seed=12345 \
  --present_wormhole_attack_nodes=true \
  --use_enhanced_wormhole=true \
  --attack_percentage=0.2 \
  --wormhole_tunnel_data=true \
  --wormhole_tunnel_routing=true \
  --wormhole_enable_verification_flows=true \
  --enable_packet_tracking=true"
```

### Wormhole Attack (With Mitigation)
```bash
./waf --run "scratch/routing \
  --N_Vehicles=15 \
  --N_RSUs=5 \
  --simTime=10 \
  --architecture=0 \
  --random_seed=12345 \
  --present_wormhole_attack_nodes=true \
  --use_enhanced_wormhole=true \
  --attack_percentage=0.2 \
  --wormhole_tunnel_data=true \
  --wormhole_tunnel_routing=true \
  --wormhole_enable_verification_flows=true \
  --enable_wormhole_detection=true \
  --enable_wormhole_mitigation=true \
  --enable_packet_tracking=true"
```

### Blackhole Attack (With Mitigation)
```bash
./waf --run "scratch/routing \
  --N_Vehicles=15 \
  --N_RSUs=5 \
  --simTime=10 \
  --architecture=0 \
  --random_seed=12345 \
  --enable_blackhole_attack=true \
  --blackhole_attack_percentage=0.2 \
  --enable_blackhole_mitigation=true \
  --enable_packet_tracking=true"
```

## 🔍 How to Verify Parameters

To see all valid parameters:
```bash
./waf --run "scratch/routing --PrintHelp" 2>&1 | less
```

To search for specific parameter:
```bash
./waf --run "scratch/routing --PrintHelp" 2>&1 | grep -i "time"
./waf --run "scratch/routing --PrintHelp" 2>&1 | grep -i "seed"
```

## ⚠️ Common Mistakes

1. **Using snake_case instead of camelCase**
   - ❌ `--sim_time` 
   - ✅ `--simTime`

2. **Using wrong parameter names**
   - ❌ `--seed`
   - ✅ `--random_seed`

3. **Using unsupported parameters**
   - ❌ `--pause_time=0`
   - ✅ Just remove it

4. **Forgetting to disable routing_test** ⚠️ **CRITICAL BUG**
   - ❌ Omitting `--routing_test=false`
   - ✅ **ALWAYS** use `--routing_test=false`
   - **Why:** Default is `routing_test=true`, which hardcodes `N_Vehicles=22` and `N_RSUs=1` in routing.cc (line 150977-150978), overriding your command-line parameters!

5. **Mixing parameter naming conventions**
   - Most use camelCase: `--simTime`, `--maxspeed`
   - Some use snake_case: `--random_seed`, `--attack_percentage`
   - Some use mixed: `--N_Vehicles`, `--N_RSUs`

## 💡 Best Practice

Always verify parameter names against `--PrintHelp` before creating test scripts!

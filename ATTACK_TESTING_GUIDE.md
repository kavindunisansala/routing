# Attack Testing Guide - Step by Step

## Current Status
✅ **Code compiled successfully** - V2V unicast traffic added to Architecture 0  
❌ **Tests failing** - Simulations run but exit with non-zero return code  
🔍 **Issue**: Simulations appear incomplete - no CSV output files generated

---

## Root Cause Analysis

### Problem Symptoms
1. **Test script reports "Failed"** but simulation logs show activity
2. **No CSV files generated** (packet-delivery-analysis.csv, wormhole-attack-results.csv, etc.)
3. **Simulation logs incomplete** - stop abruptly without final metrics summary
4. **Exit code non-zero** - causes `if ./waf --run` to fail in test scripts

### Likely Causes
1. **Simulation crashes before completion** -SegFault or assertion failure
2. **CSV writing logic not executing** - metrics collection incomplete
3. **Timeout issue** - simulation taking too long and being killed
4. **Memory/resource exhaustion** - 70 nodes may exceed limits

### Debug Commands (Run on Linux machine eie@ist105)

```bash
# 1. Check if simulation completes without crashing
cd ~/ns-allinone-3.35/ns-3.35
./waf --run "scratch/routing --N_Vehicles=15 --N_RSUs=5 --simTime=10 \
  --pause_time=0 --architecture=0 --seed=12345 --enable_wormhole_attack=false" \
  2>&1 | tee baseline_test.log

# 2. Check exit code
echo "Exit code: $?"

# 3. Look for CSV files
ls -lh *.csv

# 4. Check for crash/error messages
grep -i "error\|segmentation\|assertion\|abort\|core" baseline_test.log

# 5. Check if metrics were printed
grep -i "packet delivery ratio\|PacketsTunneled\|TotalPacketsSent" baseline_test.log
```

---

## Testing Strategy: One Attack at a Time

### Phase 1: Fix Baseline First (CRITICAL)
**Before testing any attacks, baseline MUST work!**

```bash
cd ~/ns-allinone-3.35/ns-3.35

# Test 1: Minimal baseline (10 nodes, 10s)
./waf --run "scratch/routing --N_Vehicles=5 --N_RSUs=5 --simTime=10 \
  --pause_time=0 --architecture=0 --seed=12345 --enable_wormhole_attack=false \
  --enable_blackhole_attack=false --enable_replay_attack=false \
  --enable_sybil_attack=false --enable_rtp_attack=false"

# Expected output:
# - Should complete without crash
# - Exit code 0
# - CSV files: packet-delivery-analysis.csv, metrics_summary.csv
# - Final metrics printed: "packet delivery ratio is X"
```

**If baseline fails:**
1. Check `routing.cc` for segfaults in new V2V code
2. Verify `send_distributed_packets()` and `AODV_dataunicast_alone()` work
3. Check array bounds (ns3::total_size=80 but actual_total_nodes=20)
4. Look for null pointer dereferences

**If baseline works:**
- Proceed to attack testing below

---

### Phase 2: Wormhole Attack Testing

#### Step 2.1: Wormhole Without Mitigation

```bash
cd ~/ns-allinone-3.35/ns-3.35

# Test: 20% wormhole attackers, no detection/mitigation
./waf --run "scratch/routing --N_Vehicles=15 --N_RSUs=5 --simTime=10 \
  --pause_time=0 --architecture=0 --seed=12345 \
  --enable_wormhole_attack=true --wormhole_attack_percentage=0.2 \
  --wormhole_tunnel_data=true --wormhole_enable_verification_flows=true \
  --enable_wormhole_detection=false --enable_wormhole_mitigation=false"

# Expected results:
# - PacketsTunneled > 0 (wormhole should intercept AODV packets on port 654)
# - PacketsIntercepted > 0
# - Latency anomalies (tunneled packets have different RTT)
# - CSV files: wormhole-attack-results.csv, packet-delivery-analysis.csv

# Verify wormhole is working:
grep "PacketsTunneled" wormhole-attack-results.csv
grep "Wormhole" simulation.log
```

**Success Criteria:**
- ✅ Exit code 0
- ✅ PacketsTunneled > 0 in wormhole-attack-results.csv
- ✅ AODV packets visible on port 654 (grep for "AODV" in logs)
- ✅ V2V traffic flowing (e.g., vehicle 2 → vehicle 3)

**If PacketsTunneled = 0:**
- Check: Are AODV packets being generated? (grep "AODV" simulation.log)
- Check: Is wormhole monitoring port 654? (grep "wormhole\|654" simulation.log)
- Check: V2V unicast traffic flowing? (grep "AODV-DATA-PLANE" simulation.log)

#### Step 2.2: Wormhole With Detection Only

```bash
# Test: 20% wormhole attackers, detection enabled, no mitigation
./waf --run "scratch/routing --N_Vehicles=15 --N_RSUs=5 --simTime=10 \
  --pause_time=0 --architecture=0 --seed=12345 \
  --enable_wormhole_attack=true --wormhole_attack_percentage=0.2 \
  --wormhole_tunnel_data=true --wormhole_enable_verification_flows=true \
  --enable_wormhole_detection=true --enable_wormhole_mitigation=false"

# Expected results:
# - PacketsTunneled > 0 (attack still happening)
# - DetectionRate > 0 (RTT-based detection should identify anomalies)
# - Packets still forwarded through tunnel (no mitigation)
```

**Success Criteria:**
- ✅ PacketsTunneled > 0 (attack active)
- ✅ DetectionRate > 0 (anomalies detected)
- ✅ Detection logs: grep "wormhole.*detected\|RTT.*anomaly" simulation.log

#### Step 2.3: Wormhole With Full Mitigation

```bash
# Test: 20% wormhole attackers, detection + mitigation
./waf --run "scratch/routing --N_Vehicles=15 --N_RSUs=5 --simTime=10 \
  --pause_time=0 --architecture=0 --seed=12345 \
  --enable_wormhole_attack=true --wormhole_attack_percentage=0.2 \
  --wormhole_tunnel_data=true --wormhole_enable_verification_flows=true \
  --enable_wormhole_detection=true --enable_wormhole_mitigation=true"

# Expected results:
# - PacketsIntercepted > 0 (attack attempted)
# - PacketsMitigated > 0 (routes reconfigured to avoid tunnel)
# - PDR improves compared to no-mitigation case
# - Latency anomalies reduced
```

**Success Criteria:**
- ✅ PacketsMitigated > 0
- ✅ PDR higher than without mitigation
- ✅ Mitigation logs: grep "mitigation\|route.*reconfigured" simulation.log

---

### Phase 3: Blackhole Attack Testing

#### Step 3.1: Blackhole Without Mitigation

```bash
# Test: 20% blackhole attackers
./waf --run "scratch/routing --N_Vehicles=15 --N_RSUs=5 --simTime=10 \
  --pause_time=0 --architecture=0 --seed=12345 \
  --enable_blackhole_attack=true --blackhole_attack_percentage=0.2 \
  --enable_blackhole_detection=false --enable_blackhole_mitigation=false"

# Expected results:
# - TotalPacketsDropped > 0 (blackhole nodes drop all forwarded packets)
# - PDR < 100% (packet loss due to blackholes)
# - RoutesAffected > 0 (routes pass through blackholes)
```

**Success Criteria:**
- ✅ TotalPacketsDropped > 0 in blackhole-attack-results.csv
- ✅ PDR significantly lower than baseline
- ✅ V2V traffic routing through blackhole nodes

**If TotalPacketsDropped = 0:**
- Check: Are packets being routed through designated blackhole nodes?
- Check: Is packet dropping logic active? (grep "blackhole.*drop" simulation.log)

#### Step 3.2: Blackhole With Detection

```bash
# Test: 20% blackhole attackers, detection enabled
./waf --run "scratch/routing --N_Vehicles=15 --N_RSUs=5 --simTime=10 \
  --pause_time=0 --architecture=0 --seed=12345 \
  --enable_blackhole_attack=true --blackhole_attack_percentage=0.2 \
  --enable_blackhole_detection=true --enable_blackhole_mitigation=false"

# Expected results:
# - TotalPacketsDropped > 0 (attack still active)
# - DetectionRate > 0 (watchdog identifies missing ACKs)
```

#### Step 3.3: Blackhole With Mitigation

```bash
# Test: 20% blackhole attackers, full mitigation
./waf --run "scratch/routing --N_Vehicles=15 --N_RSUs=5 --simTime=10 \
  --pause_time=0 --architecture=0 --seed=12345 \
  --enable_blackhole_attack=true --blackhole_attack_percentage=0.2 \
  --enable_blackhole_detection=true --enable_blackhole_mitigation=true"

# Expected results:
# - PDR improves (routes avoid blackholes)
# - MitigatedRoutes > 0
```

---

### Phase 4: Replay Attack Testing

#### Step 4.1: Replay Without Mitigation

```bash
# Test: 20% replay attackers
./waf --run "scratch/routing --N_Vehicles=15 --N_RSUs=5 --simTime=10 \
  --pause_time=0 --architecture=0 --seed=12345 \
  --enable_replay_attack=true --replay_attack_percentage=0.2 \
  --enable_replay_detection=false --enable_replay_mitigation=false"

# Expected results:
# - TotalPacketsReplayed > 0
# - Duplicate packets in network
# - Congestion/bandwidth waste
```

#### Step 4.2: Replay With Detection (Bloom Filter)

```bash
# Test: Bloom Filter detection
./waf --run "scratch/routing --N_Vehicles=15 --N_RSUs=5 --simTime=10 \
  --pause_time=0 --architecture=0 --seed=12345 \
  --enable_replay_attack=true --replay_attack_percentage=0.2 \
  --enable_replay_detection=true --enable_replay_mitigation=false"

# Expected results:
# - DetectionRate > 95% (Bloom Filter catches replays)
# - FalsePositiveRate < 1%
```

#### Step 4.3: Replay With Mitigation

```bash
# Test: Full replay mitigation
./waf --run "scratch/routing --N_Vehicles=15 --N_RSUs=5 --simTime=10 \
  --pause_time=0 --architecture=0 --seed=12345 \
  --enable_replay_attack=true --replay_attack_percentage=0.2 \
  --enable_replay_detection=true --enable_replay_mitigation=true"

# Expected results:
# - Replayed packets dropped
# - Network congestion reduced
```

---

### Phase 5: RTP Attack Testing (Infrastructure Only)

#### Step 5.1: RTP Without Mitigation

```bash
# Test: 20% RTP attackers (RSU poisoning)
./waf --run "scratch/routing --N_Vehicles=15 --N_RSUs=5 --simTime=10 \
  --pause_time=0 --architecture=0 --seed=12345 \
  --enable_rtp_attack=true --rtp_attack_percentage=0.2 \
  --enable_rtp_detection=false --enable_rtp_mitigation=false"

# Expected results:
# - NodesPoisoned > 0 (static routing tables corrupted)
# - RoutingErrors > 0 (packets misdirected)
# - Impact on infrastructure (RSU-controller) only
```

#### Step 5.2: RTP With Detection

```bash
# Test: Hybrid-Shield detection
./waf --run "scratch/routing --N_Vehicles=15 --N_RSUs=5 --simTime=10 \
  --pause_time=0 --architecture=0 --seed=12345 \
  --enable_rtp_attack=true --rtp_attack_percentage=0.2 \
  --enable_rtp_detection=true --enable_rtp_mitigation=false"

# Expected results:
# - DetectionRate > 90% (Hybrid-Shield catches invalid routes)
```

#### Step 5.3: RTP With Mitigation

```bash
# Test: Full RTP mitigation
./waf --run "scratch/routing --N_Vehicles=15 --N_RSUs=5 --simTime=10 \
  --pause_time=0 --architecture=0 --seed=12345 \
  --enable_rtp_attack=true --rtp_attack_percentage=0.2 \
  --enable_rtp_detection=true --enable_rtp_mitigation=true"

# Expected results:
# - Poisoned routes corrected
# - Routing errors reduced
```

---

### Phase 6: Sybil Attack Testing

#### Step 6.1: Sybil Without Mitigation

```bash
# Test: 20% sybil attackers (fake identities)
./waf --run "scratch/routing --N_Vehicles=15 --N_RSUs=5 --simTime=10 \
  --pause_time=0 --architecture=0 --seed=12345 \
  --enable_sybil_attack=true --sybil_attack_percentage=0.2 \
  --enable_sybil_detection=false --enable_sybil_mitigation=false"

# Expected results:
# - FakeIdentitiesBroadcast > 0
# - Position/velocity spoofing in DSRC broadcasts
# - Neighbor table pollution
```

#### Step 6.2: Sybil With Detection

```bash
# Test: Position verification detection
./waf --run "scratch/routing --N_Vehicles=15 --N_RSUs=5 --simTime=10 \
  --pause_time=0 --architecture=0 --seed=12345 \
  --enable_sybil_attack=true --sybil_attack_percentage=0.2 \
  --enable_sybil_detection=true --enable_sybil_mitigation=false"

# Expected results:
# - FalsePositiveRate < 1% (legitimate nodes not flagged)
# - PositionAnomalyRate < 5% (fake positions caught)
```

#### Step 6.3: Sybil With Mitigation

```bash
# Test: Full sybil mitigation
./waf --run "scratch/routing --N_Vehicles=15 --N_RSUs=5 --simTime=10 \
  --pause_time=0 --architecture=0 --seed=12345 \
  --enable_sybil_attack=true --sybil_attack_percentage=0.2 \
  --enable_sybil_detection=true --enable_sybil_mitigation=true"

# Expected results:
# - Fake identities filtered
# - Neighbor tables cleaned
```

---

## Troubleshooting Common Issues

### Issue 1: Simulation Crashes
**Symptoms:** Exit code != 0, incomplete logs, no CSV files

**Debug Steps:**
```bash
# Run with gdb to catch crash
gdb --args ./build/scratch/ns3-dev-routing-debug \
  --N_Vehicles=15 --N_RSUs=5 --simTime=10 --architecture=0

# In gdb:
(gdb) run
# Wait for crash
(gdb) backtrace
```

### Issue 2: No CSV Files Generated
**Symptoms:** Simulation completes but no output

**Check:**
```bash
# 1. Verify CSV writing code is being called
grep "Writing.*csv\|Saving.*results" simulation.log

# 2. Check file permissions
ls -lh *.csv

# 3. Look for I/O errors
dmesg | grep -i "error\|denied"
```

### Issue 3: PacketsTunneled = 0 (Wormhole)
**Symptoms:** Wormhole attack shows no activity

**Debug:**
```bash
# 1. Confirm AODV packets exist
grep "AODV\|port 654" simulation.log | head -20

# 2. Confirm V2V traffic
grep "AODV-DATA-PLANE\|send_distributed_packets" simulation.log | head -20

# 3. Check wormhole monitoring
grep -i "wormhole.*intercept\|tunnel" simulation.log | head -20
```

### Issue 4: TotalPacketsDropped = 0 (Blackhole)
**Symptoms:** Blackhole attack shows no drops

**Debug:**
```bash
# 1. Confirm blackhole nodes designated
grep "blackhole.*node\|Blackhole attacker" simulation.log

# 2. Check if packets routed through blackholes
grep "forwarding.*through.*blackhole" simulation.log

# 3. Verify drop logic
grep "drop\|discard" simulation.log | grep -i "blackhole"
```

---

## Next Steps

### Immediate Actions (Priority Order)

1. **FIX BASELINE FIRST** ⚠️ CRITICAL
   ```bash
   # Test with minimal configuration
   cd ~/ns-allinone-3.35/ns-3.35
   ./waf --run "scratch/routing --N_Vehicles=5 --N_RSUs=5 --simTime=10 \
     --architecture=0 --seed=12345" 2>&1 | tee baseline_minimal.log
   
   # Check exit code
   echo "Exit code: $?"
   
   # Look for CSV files
   ls -lh *.csv
   
   # Check for errors
   grep -i "error\|segmentation\|abort" baseline_minimal.log
   ```

2. **If baseline works → Test Wormhole**
   - Start with 20% attackers, no mitigation
   - Verify PacketsTunneled > 0
   - Then add detection
   - Finally add mitigation

3. **If baseline fails → Debug routing.cc**
   - Check `send_distributed_packets()` function
   - Verify `AODV_dataunicast_alone()` not crashing
   - Look for array bounds issues
   - Check null pointer dereferences

4. **Document Results**
   - For each test, record: PDR, latency, attack metrics, exit code
   - Save logs: `cp simulation.log attack_X_config_Y.log`
   - Note any anomalies or unexpected behavior

---

## Expected Results Summary

| Attack | No Mitigation | With Detection | With Mitigation |
|--------|--------------|----------------|-----------------|
| **Wormhole** | PacketsTunneled > 0<br>Latency anomalies | DetectionRate > 0<br>RTT analysis | PacketsMitigated > 0<br>PDR improves |
| **Blackhole** | PacketsDropped > 0<br>PDR < 50% | DetectionRate > 0<br>Watchdog alerts | PDR > 80%<br>Routes rerouted |
| **Replay** | PacketsReplayed > 0<br>Congestion | DetectionRate > 95%<br>Bloom Filter | Replays dropped<br>FPR < 1% |
| **RTP** | NodesPoisoned > 0<br>Infra only | DetectionRate > 90%<br>Hybrid-Shield | Routes corrected<br>Errors reduced |
| **Sybil** | FakeIDs > 0<br>Table pollution | FPR < 1%<br>PAR < 5% | IDs filtered<br>Tables cleaned |

---

## Contact/Support

If you encounter persistent issues:
1. Share the complete `simulation.log` file
2. Include exit code: `echo $?` after running
3. List CSV files generated: `ls -lh *.csv`
4. Provide system info: `uname -a` and `free -h`


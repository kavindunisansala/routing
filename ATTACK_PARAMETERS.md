# Attack Command-Line Parameters - Quick Reference

## Overview
Different attacks use different parameter naming conventions in the NS-3 simulation.

## Attack Parameters

### Wormhole Attack
```bash
--present_wormhole_attack_nodes=1
--attack_percentage=0.2
```

### Blackhole Attack
```bash
--present_blackhole_attack_nodes=1
--attack_percentage=0.2
```

### Sybil Attack
```bash
--present_sybil_attack_nodes=1
--attack_percentage=0.2
```

### Replay Attack
```bash
--enable_replay_attack=1
--replay_attack_percentage=0.2
```
**Note**: Uses `enable_` prefix and `replay_attack_percentage` (not `attack_percentage`)

### RTP (Routing Table Poisoning) Attack
```bash
--enable_rtp_attack=1
--rtp_attack_percentage=0.2
```
**Note**: Uses `enable_` prefix and `rtp_attack_percentage` (not `attack_percentage`)

## Example Commands

### Baseline (No Attack)
```bash
./waf --run "scratch/routing --architecture=0 --N_Vehicles=20 --N_RSUs=2 --simTime=10"
```

### Wormhole Attack
```bash
./waf --run "scratch/routing --architecture=0 --N_Vehicles=20 --N_RSUs=2 --simTime=10 --present_wormhole_attack_nodes=1 --attack_percentage=0.2"
```

### Replay Attack
```bash
./waf --run "scratch/routing --architecture=0 --N_Vehicles=20 --N_RSUs=2 --simTime=10 --enable_replay_attack=1 --replay_attack_percentage=0.2"
```

### RTP Attack
```bash
./waf --run "scratch/routing --architecture=0 --N_Vehicles=20 --N_RSUs=2 --simTime=10 --enable_rtp_attack=1 --rtp_attack_percentage=0.2"
```

## Pattern Summary

| Attack | Enable Flag | Percentage Parameter |
|--------|------------|---------------------|
| Wormhole | `present_wormhole_attack_nodes` | `attack_percentage` |
| Blackhole | `present_blackhole_attack_nodes` | `attack_percentage` |
| Sybil | `present_sybil_attack_nodes` | `attack_percentage` |
| Replay | `enable_replay_attack` | `replay_attack_percentage` |
| RTP | `enable_rtp_attack` | `rtp_attack_percentage` |

## Test Scripts Fixed

The `verify_new_architecture.sh` script has been updated to use the correct parameters for each attack type.

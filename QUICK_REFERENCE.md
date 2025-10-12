# WORMHOLE ATTACK - QUICK REFERENCE CARD

**Last Updated:** October 12, 2025 14:30  
**Build Status:** ✅ Ready (10 errors fixed)

---

## 📅 Latest Update [2025-10-12 14:30]

**All compilation errors resolved!**
- Fixed: NS-3 API compatibility (3 errors)
- Fixed: Variable naming issues (7 errors)
- Status: Ready for successful build

**Quick Build:**
```powershell
./waf clean && ./waf configure --enable-examples && ./waf build
```

---

## 🚀 Quick Commands

```bash
# Basic run
./waf --run "routing --use_enhanced_wormhole=true"

# Custom attack intensity
./waf --run "routing --use_enhanced_wormhole=true --attack_percentage=0.2"

# Drop mode (no tunneling)
./waf --run "routing --use_enhanced_wormhole=true --wormhole_drop_packets=true"

# Analyze results
python3 wormhole_analysis.py wormhole-attack-results.csv --plot

# Run test suite
./wormhole_test_suite.sh
```

## 📋 Configuration Parameters

| Parameter | Default | Range | Description |
|-----------|---------|-------|-------------|
| `use_enhanced_wormhole` | true | bool | Enable/disable |
| `attack_percentage` | 0.1 | 0.0-1.0 | % of malicious nodes |
| `wormhole_bandwidth` | "1000Mbps" | string | Tunnel bandwidth |
| `wormhole_delay_us` | 1 | 0-∞ | Tunnel delay (μs) |
| `wormhole_random_pairing` | true | bool | Random vs sequential |
| `wormhole_drop_packets` | false | bool | Drop instead of tunnel |
| `wormhole_tunnel_routing` | true | bool | Affect routing pkts |
| `wormhole_tunnel_data` | true | bool | Affect data pkts |
| `wormhole_start_time` | 0.0 | 0.0-simTime | Start time (s) |
| `wormhole_stop_time` | 0.0 | 0.0-simTime | Stop time (s) |

## 📊 Output Files

| File | Content |
|------|---------|
| `wormhole-attack-results.csv` | Per-tunnel and aggregate statistics |
| `routing.xml` | NetAnim visualization file |
| Console | Real-time statistics summary |

## 🔍 CSV File Format

```csv
TunnelID,NodeA,NodeB,PacketsIntercepted,PacketsTunneled,PacketsDropped,RoutingAffected,DataAffected,AvgDelay
0,5,23,1234,1200,34,856,378,0.000001
...
TOTAL,ALL,ALL,15234,14998,236,10234,5000,0.000001
```

## 📈 Key Statistics

- **Packets Intercepted**: Total packets captured
- **Packets Tunneled**: Successfully sent through wormhole
- **Packets Dropped**: Packets discarded
- **Routing Affected**: Routing protocol packets impacted
- **Data Affected**: Application data packets impacted
- **Avg Delay**: Mean tunneling delay

## 🎯 Common Use Cases

### 1. Basic Attack
```bash
./waf --run "routing --use_enhanced_wormhole=true --attack_percentage=0.1"
```

### 2. High Intensity
```bash
./waf --run "routing --use_enhanced_wormhole=true --attack_percentage=0.3"
```

### 3. Routing Disruption
```bash
./waf --run "routing --use_enhanced_wormhole=true \
             --wormhole_tunnel_routing=true --wormhole_tunnel_data=false"
```

### 4. Delayed Attack
```bash
./waf --run "routing --use_enhanced_wormhole=true \
             --wormhole_start_time=30.0 --wormhole_stop_time=80.0"
```

### 5. Blackhole Variant
```bash
./waf --run "routing --use_enhanced_wormhole=true --wormhole_drop_packets=true"
```

## 🐛 Troubleshooting

| Problem | Solution |
|---------|----------|
| No CSV file | Check `use_enhanced_wormhole=true` |
| Zero packets | Increase `simTime`, check traffic |
| Compilation error | Verify wormhole_attack.h/cc present |
| Segfault | Run with gdb: `--command-template="gdb %s"` |

## 📚 File Locations

```
routing/
├── routing.cc                  # Main simulation
├── wormhole_attack.h           # Header file
├── wormhole_attack.cc          # Implementation
├── wormhole_example.cc         # Standalone example
├── wormhole_test_suite.sh      # Test script
├── wormhole_analysis.py        # Analysis tool
├── README.md                   # Full documentation
├── BUILD_GUIDE.md              # Integration guide
└── IMPLEMENTATION_SUMMARY.md   # Technical details
```

## 🔧 Code Snippets

### Initialize Manager
```cpp
ns3::WormholeAttackManager* manager = new ns3::WormholeAttackManager();
manager->Initialize(maliciousNodes, 0.1, 100);
```

### Create Tunnels
```cpp
manager->CreateWormholeTunnels("1000Mbps", ns3::MicroSeconds(1), true);
```

### Activate Attack
```cpp
manager->ActivateAttack(ns3::Seconds(0.0), ns3::Seconds(300.0));
```

### Get Statistics
```cpp
WormholeStatistics stats = manager->GetAggregateStatistics();
std::cout << "Intercepted: " << stats.packetsIntercepted << std::endl;
```

### Export Results
```cpp
manager->ExportStatistics("results.csv");
```

## 📊 Analysis Commands

```bash
# Basic analysis
python3 wormhole_analysis.py wormhole-attack-results.csv

# With plots
python3 wormhole_analysis.py wormhole-attack-results.csv --plot

# Open animation
netanim routing.xml
```

## 🎓 Research Scenarios

### Vary Attack Intensity
```bash
for i in 0.05 0.10 0.15 0.20 0.25 0.30; do
    ./waf --run "routing --attack_percentage=$i"
    mv wormhole-attack-results.csv results_$i.csv
done
```

### Vary Network Size
```bash
for n in 50 75 100 125 150; do
    ./waf --run "routing --N_Vehicles=$n --attack_percentage=0.1"
    mv wormhole-attack-results.csv results_n${n}.csv
done
```

### Compare Drop vs Tunnel
```bash
# Tunnel mode
./waf --run "routing --wormhole_drop_packets=false"
mv wormhole-attack-results.csv results_tunnel.csv

# Drop mode
./waf --run "routing --wormhole_drop_packets=true"
mv wormhole-attack-results.csv results_drop.csv
```

## 🔒 Security Implications

### Attack Effectiveness Factors
- **Attack %**: More malicious nodes = higher impact
- **Tunnel Speed**: Faster tunnel = more attractive route
- **Node Placement**: Strategic location = more interception
- **Selective Targeting**: Routing pkts = topology disruption

### Detection Indicators
- Abnormal RTT (Round Trip Time)
- Geographic inconsistencies
- Unexpected route changes
- Packet correlation anomalies

## 💡 Tips & Best Practices

1. **Start Small**: Begin with 10% attack percentage
2. **Run Long**: Use simTime > 100s for reliable statistics
3. **Repeat**: Run multiple times for statistical significance
4. **Visualize**: Use NetAnim to understand topology
5. **Analyze**: Always check CSV for detailed metrics
6. **Test First**: Run wormhole_test_suite.sh before experiments

## 📞 Getting Help

1. Read `README.md` for full documentation
2. Check `BUILD_GUIDE.md` for integration
3. Review `IMPLEMENTATION_SUMMARY.md` for technical details
4. Examine `wormhole_example.cc` for usage patterns

## ⚡ Performance Tips

- Disable logging: `export NS_LOG=""`
- Reduce stats: Comment out tracking code
- Optimize network: Use appropriate routing protocol
- Profile: Run with `--command-template="valgrind %s"`

## 🎯 Success Checklist

- [ ] Code compiles without errors
- [ ] Simulation runs successfully
- [ ] CSV file is generated
- [ ] Statistics make sense
- [ ] NetAnim shows red nodes
- [ ] Analysis script works
- [ ] Results are repeatable

---

**Version:** 2.1  
**Last Updated:** October 11, 2025  
**Quick Reference for:** Enhanced Wormhole Attack Implementation

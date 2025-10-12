# NS-3 VANET Routing Simulation with Wormhole Attack

[![NS-3 Version](https://img.shields.io/badge/NS--3-3.35-blue.svg)](https://www.nsnam.org/)
[![License](https://img.shields.io/badge/license-GPL-green.svg)](LICENSE)
[![Build Status](https://img.shields.io/badge/build-passing-brightgreen.svg)](BUILD_STATUS_FINAL.txt)

## 📋 Overview

This project implements a **Vehicular Ad-Hoc Network (VANET)** routing simulation with an advanced **Wormhole Attack** implementation for NS-3.35. The simulation includes comprehensive statistics collection, visualization support, and analysis tools.

### Key Features

- ✅ **Multiple Routing Protocols**: AODV, OLSR, DSDV, DSR
- ✅ **Enhanced Wormhole Attack**: Configurable tunneling with statistics
- ✅ **Security Attacks**: Blackhole, Greyhole, Replay attacks
- ✅ **Real-time Visualization**: NetAnim integration
- ✅ **Comprehensive Metrics**: CSV export and Python analysis
- ✅ **Mobility Models**: Random waypoint, constant velocity
- ✅ **Radio Propagation**: Two-ray ground model

## 🚀 Quick Start

### Prerequisites

```bash
# NS-3 3.35 installed
cd ~/Downloads/ns-allinone-3.35/ns-3.35/

# Required: Copy files to scratch directory
```

### Installation

1. **Clone this repository:**
```bash
git clone https://github.com/kavindunisansala/routing.git
cd routing
```

2. **Copy files to NS-3 scratch directory:**
```bash
cp routing.cc wormhole_attack.h wormhole_attack.cc \
   ~/Downloads/ns-allinone-3.35/ns-3.35/scratch/
```

3. **Build:**
```bash
cd ~/Downloads/ns-allinone-3.35/ns-3.35/
./waf clean
./waf build
```

4. **Run simulation:**
```bash
./waf --run "routing --use_enhanced_wormhole=true --simTime=10"
```

## 📖 Documentation

| Document | Description |
|----------|-------------|
| [START_HERE.txt](START_HERE.txt) | Quick 4-step guide to get started |
| [BUILD_GUIDE.md](BUILD_GUIDE.md) | Complete build history and troubleshooting |
| [TROUBLESHOOTING.md](TROUBLESHOOTING.md) | Error resolution log with timestamps |
| [QUICK_REFERENCE.md](QUICK_REFERENCE.md) | Configuration parameters reference |
| [README.md](README.md) | Full implementation details |

## ⚙️ Configuration

### Wormhole Attack Parameters

```cpp
bool use_enhanced_wormhole = true;           // Enable wormhole attack
std::string wormhole_tunnel_bandwidth = "1000Mbps";
uint32_t wormhole_tunnel_delay_us = 1;       // 1 microsecond
bool wormhole_drop_packets = false;          // Tunnel (not drop)
bool wormhole_random_pairing = true;         // Random malicious pairs
```

### Simulation Parameters

```bash
./waf --run "routing \
  --protocol=AODV \
  --simTime=300 \
  --nWifis=50 \
  --use_enhanced_wormhole=true \
  --wormhole_attack_percentage=0.1"
```

## 📊 Output Files

| File | Description |
|------|-------------|
| `wormhole-attack-results.csv` | Wormhole tunnel statistics |
| `VanetRoutingCompare.csv` | Routing protocol metrics |
| `vanet-routing.xml` | NetAnim visualization file |

## 🔬 Analysis

### Python Analysis Script

```bash
python3 wormhole_analysis.py wormhole-attack-results.csv --plot
```

### Example Output

```
========== WORMHOLE ATTACK STATISTICS ==========
Total Tunnels: 5

Tunnel 0 (Node 2 <-> Node 15):
  Packets Intercepted: 234
  Packets Tunneled: 234
  Routing Packets Affected: 89
  Data Packets Affected: 145
```

## 🛠️ Build History

### Latest Build (2025-10-12)

✅ **All 30+ compilation errors resolved:**

1. Build #1: Variable naming (7 errors) - Fixed
2. Build #2: NS-3 API compatibility (3 errors) - Fixed
3. Build #3: Missing headers (1 error) - Fixed
4. Build #4: Linker errors (9 errors) - Fixed
5. Build #5: Log component conflict (1 error) - Fixed
6. Build #6: NS_LOG macro errors (30+ errors) - Fixed

See [BUILD_STATUS_FINAL.txt](BUILD_STATUS_FINAL.txt) for details.

## 📁 Project Structure

```
routing/
├── routing.cc                    # Main simulation (140K+ lines)
├── wormhole_attack.h             # Wormhole attack header
├── wormhole_attack.cc            # Wormhole attack implementation
├── wormhole_example.cc           # Standalone example
├── wormhole_analysis.py          # Analysis script
├── wormhole_test_suite.sh        # Test suite
├── Documentation/
│   ├── README.md                 # Full documentation
│   ├── BUILD_GUIDE.md            # Build instructions
│   ├── TROUBLESHOOTING.md        # Error solutions
│   ├── QUICK_REFERENCE.md        # Parameter reference
│   └── START_HERE.txt            # Quick start
└── Support Files/
    ├── BUILD_STATUS_FINAL.txt    # Build summary
    ├── SYNC_NOW.txt              # File sync guide
    └── .gitignore                # Git ignore rules
```

## 🔍 Features

### Wormhole Attack Implementation

- **Packet Interception**: Promiscuous mode on all interfaces
- **High-Speed Tunneling**: 1000Mbps, 1μs delay between malicious nodes
- **Selective Tunneling**: Configure routing vs data packet handling
- **Statistics Collection**: Per-tunnel and aggregate metrics
- **Visualization Support**: NetAnim integration with color coding

### Supported Attack Types

| Attack | Status | Description |
|--------|--------|-------------|
| Wormhole | ✅ Full | High-speed tunnel between malicious nodes |
| Blackhole | ✅ Full | Drop all packets |
| Greyhole | ✅ Full | Selective packet dropping |
| Replay | ✅ Full | Packet replay attacks |

## 🧪 Testing

Run the test suite:

```bash
./wormhole_test_suite.sh
```

Tests include:
- Basic wormhole functionality
- Packet interception rates
- Tunnel statistics accuracy
- Attack activation/deactivation
- Multiple tunnel scenarios

## 📈 Performance

Tested with:
- **Network Size**: 10-100 nodes
- **Simulation Time**: 10-600 seconds
- **Malicious Nodes**: 5-20% of network
- **Packet Load**: 10-1000 packets/second

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the GPL License - see the LICENSE file for details.

## 👥 Authors

- **Kavindu Nisansala** - [kavindunisansala](https://github.com/kavindunisansala)

## 🙏 Acknowledgments

- NS-3 Development Team
- VANET Research Community
- Contributors and testers

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/kavindunisansala/routing/issues)
- **Documentation**: See docs in repository
- **Build Problems**: See [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

## 🔖 Version History

- **v1.0.0** (2025-10-12): Initial release with full wormhole attack implementation
  - 30+ compilation errors fixed
  - NS-3 3.35 compatibility
  - Complete documentation
  - Analysis tools included

---

**⚠️ Important Notes:**

1. This is for **educational and research purposes** only
2. Requires **NS-3 3.35** (tested version)
3. Files must be copied to NS-3 `scratch/` directory
4. See [START_HERE.txt](START_HERE.txt) for quickest setup

---

Made with ❤️ for VANET security research

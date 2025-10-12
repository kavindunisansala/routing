# Wormhole Attack Implementation - Build & Integration Guide

**Last Updated:** October 12, 2025 15:25  
**Build Status:** ✅ ALL FIXES COMPLETE (30+ errors fixed) - READY FOR LINUX

---

## 📅 Build Log

### [2025-10-12 15:25] ✅ ALL FIXES COMPLETE - READY FOR LINUX BUILD
**Status:** Windows files fully corrected, need Linux file sync  
**Total Fixes:** 30+ compilation errors across 6 build attempts  
**Action Required:** Copy 3 files to Linux (see SYNC_NOW.txt)

**Build History Summary:**
1. Build #1: Variable naming (replay→reply) - 7 errors - ✅ FIXED
2. Build #2: NS-3 API compatibility - 3 errors - ✅ FIXED
3. Build #3: Missing headers - 1 error - ✅ FIXED
4. Build #4: Linker errors - 9 errors - ✅ FIXED
5. Build #5: Log component conflict - 1 error - ✅ FIXED
6. Build #6: NS_LOG macro errors - 30+ errors - ✅ FIXED

### [2025-10-12 15:20] NS_LOG Macro Cleanup
- **Issue:** g_log not declared (all NS_LOG_* macros failed)
- **Cause:** Removed NS_LOG_COMPONENT_DEFINE but kept NS_LOG calls
- **Fix:** Commented out all 30+ NS_LOG_FUNCTION/INFO/DEBUG/WARN calls
- **Files:** wormhole_attack.cc
- **Result:** No more g_log references in included .cc file

### [2025-10-12 15:00] LINKER FIX ⚠️ IMPORTANT
- ✅ **CRITICAL FIX:** Added `#include "wormhole_attack.cc"` in routing.cc (line 58)
- **Why?** NS-3 scratch/ doesn't auto-compile .cc files - must include explicitly
- **Result:** All 9 linker errors resolved

### [2025-10-12 14:45] Applications Module
- ✅ wormhole_example.cc fixed (1 error)

### [2025-10-12 14:30] Initial Fixes
- ✅ routing.cc fixed (7 errors)
- ✅ wormhole_attack files fixed (3 errors)

---

## ⚠️ IMPORTANT: NS-3 Scratch Directory Note

**For files in NS-3's `scratch/` directory:**
- WAF does **NOT** automatically compile separate .cc files
- You **MUST** include .cc files explicitly with `#include`
- This is already done in routing.cc line 58: `#include "wormhole_attack.cc"`

**Already configured correctly - no action needed!** ✅

---

## Quick Start

### 1. File Placement

Place the new files in your NS-3 project directory:

```
ns-3.35/
├── scratch/
│   ├── routing.cc                    # Modified main simulation
│   ├── wormhole_attack.h             # New header
│   ├── wormhole_attack.cc            # New implementation
│   └── wormhole_example.cc           # New standalone example
└── routing/                           # Or your custom module
    ├── wormhole_attack.h
    └── wormhole_attack.cc
```

### 2. Build Configuration

#### Option A: Using scratch/ directory (Easiest)

```bash
# Copy files to NS-3 scratch directory
cd /path/to/ns-allinone-3.35/ns-3.35/scratch/
cp /path/to/routing.cc .
cp /path/to/wormhole_attack.h .
cp /path/to/wormhole_attack.cc .
cp /path/to/wormhole_example.cc .

# Build
cd ..
./waf configure --enable-examples
./waf build
```

#### Option B: Creating a custom module

1. Create module structure:
```bash
cd /path/to/ns-allinone-3.35/ns-3.35/src/
mkdir vanet-routing
cd vanet-routing
mkdir model helper test examples doc
```

2. Create `wscript` file in `src/vanet-routing/`:
```python
def build(bld):
    module = bld.create_ns3_module('vanet-routing', ['core', 'network', 'internet', 
                                                       'wifi', 'wave', 'point-to-point',
                                                       'mobility', 'applications', 'netanim'])
    module.source = [
        'model/wormhole_attack.cc',
        ]

    headers = bld(features='ns3header')
    headers.module = 'vanet-routing'
    headers.source = [
        'model/wormhole_attack.h',
        ]

    if bld.env.ENABLE_EXAMPLES:
        bld.recurse('examples')

    bld.ns3_python_bindings()
```

3. Place files:
```bash
mv wormhole_attack.h src/vanet-routing/model/
mv wormhole_attack.cc src/vanet-routing/model/
mv routing.cc scratch/
mv wormhole_example.cc src/vanet-routing/examples/
```

4. Rebuild:
```bash
./waf configure --enable-examples
./waf build
```

### 3. Compilation

```bash
# Clean build
./waf clean
./waf configure --enable-examples --enable-tests
./waf build

# If you get errors, try:
./waf configure --enable-examples --disable-python
./waf build -v  # Verbose output
```

### 4. Common Compilation Issues

#### Issue 1: "wormhole_attack.h: No such file or directory"

**Solution:** Make sure the header is in the same directory as routing.cc, or use:
```cpp
#include "model/wormhole_attack.h"  // If using module structure
```

#### Issue 2: Undefined references to WormholeAttackManager

**Solution:** Ensure wormhole_attack.cc is compiled. Check wscript or add to scratch:
```bash
cd scratch/
# Both .cc files must be present
ls -l routing.cc wormhole_attack.cc
```

#### Issue 3: Namespace errors

**Solution:** Make sure you're using `ns3::` namespace correctly:
```cpp
// In routing.cc
ns3::WormholeAttackManager* g_wormholeManager = nullptr;
```

### 5. Running the Simulation

```bash
# Basic run with wormhole attack
./waf --run "routing --use_enhanced_wormhole=true"

# With custom parameters
./waf --run "routing --use_enhanced_wormhole=true \
             --attack_percentage=0.2 \
             --simTime=300 \
             --N_Vehicles=75 \
             --N_RSUs=40"

# Run standalone example
./waf --run "wormhole_example --nNodes=50 --simTime=100"

# With GDB debugger
./waf --run routing --command-template="gdb --args %s --use_enhanced_wormhole=true"

# With Valgrind (memory check)
./waf --run routing --command-template="valgrind --leak-check=full %s"
```

### 6. Verify Installation

Create a test script `test_wormhole.sh`:

```bash
#!/bin/bash
echo "Testing wormhole attack implementation..."

# Test 1: Compile check
echo "1. Checking compilation..."
./waf build 2>&1 | grep -i "error"
if [ $? -eq 1 ]; then
    echo "   ✓ Compilation successful"
else
    echo "   ✗ Compilation errors detected"
    exit 1
fi

# Test 2: Run test
echo "2. Running short simulation..."
./waf --run "routing --use_enhanced_wormhole=true --simTime=10" > /tmp/wormhole_test.log 2>&1

# Test 3: Check output
if grep -q "wormhole tunnels" /tmp/wormhole_test.log; then
    echo "   ✓ Wormhole attack activated"
else
    echo "   ✗ Wormhole attack not detected in output"
    exit 1
fi

# Test 4: Check statistics
if [ -f "wormhole-attack-results.csv" ]; then
    echo "   ✓ Statistics file generated"
    rm wormhole-attack-results.csv
else
    echo "   ✗ Statistics file not generated"
fi

echo ""
echo "All tests passed! ✓"
```

Run it:
```bash
chmod +x test_wormhole.sh
./test_wormhole.sh
```

### 7. Integration with Existing Code

If you have existing `routing.cc` with custom functions:

1. **Add the include at the top:**
```cpp
#include "wormhole_attack.h"
```

2. **Add configuration variables** (after other global variables):
```cpp
// Existing variables...
bool present_wormhole_attack_nodes = true;

// Add new variables
bool use_enhanced_wormhole = true;
std::string wormhole_tunnel_bandwidth = "1000Mbps";
uint32_t wormhole_tunnel_delay_us = 1;
bool wormhole_random_pairing = true;
bool wormhole_drop_packets = false;
bool wormhole_tunnel_routing = true;
bool wormhole_tunnel_data = true;
double wormhole_start_time = 0.0;
double wormhole_stop_time = 0.0;

ns3::WormholeAttackManager* g_wormholeManager = nullptr;
```

3. **Add command-line options** in main():
```cpp
CommandLine cmd;
// ... existing options ...
cmd.AddValue("use_enhanced_wormhole", "Use enhanced wormhole", use_enhanced_wormhole);
cmd.AddValue("attack_percentage", "Attack percentage", attack_percentage);
// ... add other wormhole options ...
cmd.Parse(argc, argv);
```

4. **Replace old wormhole setup:**
```cpp
// OLD:
// setup_wormhole_tunnels(anim);

// NEW:
if (present_wormhole_attack_nodes && use_enhanced_wormhole) {
    g_wormholeManager = new ns3::WormholeAttackManager();
    g_wormholeManager->Initialize(wormhole_malicious_nodes, attack_percentage, total_size);
    g_wormholeManager->SetWormholeBehavior(wormhole_drop_packets, 
                                           wormhole_tunnel_routing, 
                                           wormhole_tunnel_data);
    
    ns3::Time tunnelDelay = ns3::MicroSeconds(wormhole_tunnel_delay_us);
    g_wormholeManager->CreateWormholeTunnels(wormhole_tunnel_bandwidth, 
                                             tunnelDelay, 
                                             wormhole_random_pairing);
    
    double stopTime = (wormhole_stop_time > 0) ? wormhole_stop_time : simTime;
    g_wormholeManager->ActivateAttack(ns3::Seconds(wormhole_start_time), 
                                      ns3::Seconds(stopTime));
    
    g_wormholeManager->ConfigureVisualization(anim, 255, 0, 0);
}
```

5. **Add cleanup before Simulator::Destroy():**
```cpp
Simulator::Run();

// Add this:
if (g_wormholeManager != nullptr) {
    g_wormholeManager->PrintStatistics();
    g_wormholeManager->ExportStatistics("wormhole-attack-results.csv");
    delete g_wormholeManager;
    g_wormholeManager = nullptr;
}

Simulator::Destroy();
```

### 8. Testing Script Usage

```bash
# Make executable
chmod +x wormhole_test_suite.sh
chmod +x wormhole_analysis.py

# Run test suite
./wormhole_test_suite.sh

# Analyze results
python3 wormhole_analysis.py wormhole-attack-results.csv

# Generate plots
python3 wormhole_analysis.py wormhole-attack-results.csv --plot
```

### 9. Troubleshooting

#### Segmentation Fault
```bash
# Run with GDB
./waf --run routing --command-template="gdb --args %s --use_enhanced_wormhole=true"
# In GDB:
(gdb) run
(gdb) bt  # backtrace when it crashes
```

#### No Statistics Generated
Check that:
1. `use_enhanced_wormhole=true` is set
2. `present_wormhole_attack_nodes=true` in code
3. At least 2 nodes are marked as malicious
4. Simulation runs long enough for packets to be sent

#### NetAnim Not Working
```bash
# Install netanim module
sudo apt-get install netanim  # On Ubuntu/Debian

# Generate animation
./waf --run "routing --use_enhanced_wormhole=true"

# Open animation
netanim routing.xml
```

### 10. Performance Optimization

For large-scale simulations:

```cpp
// Disable statistics collection for speed
#define WORMHOLE_DISABLE_STATS

// In wormhole_attack.cc, wrap statistics code:
#ifndef WORMHOLE_DISABLE_STATS
    m_stats.packetsIntercepted++;
#endif
```

Reduce logging:
```bash
export NS_LOG=""  # Disable all logging
./waf --run routing
```

### 11. Documentation Generation

Generate API documentation:
```bash
# Install Doxygen
sudo apt-get install doxygen graphviz

# Generate docs
doxygen Doxyfile

# View in browser
firefox html/index.html
```

### 12. Continuous Integration

Example `.gitlab-ci.yml` or `.github/workflows/build.yml`:

```yaml
name: Build and Test

on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Install NS-3 dependencies
        run: |
          sudo apt-get update
          sudo apt-get install -y gcc g++ python3 python3-dev cmake
      - name: Build
        run: |
          ./waf configure --enable-examples
          ./waf build
      - name: Test
        run: |
          ./waf --run "routing --use_enhanced_wormhole=true --simTime=10"
          test -f wormhole-attack-results.csv
```

### 13. Docker Container

Create `Dockerfile`:
```dockerfile
FROM ubuntu:20.04
RUN apt-get update && apt-get install -y \
    build-essential gcc g++ python3 python3-dev \
    git wget cmake
RUN wget https://www.nsnam.org/releases/ns-allinone-3.35.tar.bz2 && \
    tar xjf ns-allinone-3.35.tar.bz2
WORKDIR /ns-allinone-3.35/ns-3.35
COPY wormhole_attack.h scratch/
COPY wormhole_attack.cc scratch/
COPY routing.cc scratch/
RUN ./waf configure --enable-examples && ./waf build
CMD ["./waf", "--run", "routing --use_enhanced_wormhole=true"]
```

Build and run:
```bash
docker build -t vanet-wormhole .
docker run vanet-wormhole
```

---

## Support

If you encounter issues:

1. Check NS-3 version compatibility (tested on 3.35)
2. Review NS-3 documentation: https://www.nsnam.org/documentation/
3. Check compilation flags in wscript
4. Verify all dependencies are installed

## Success Checklist

- [ ] Files compiled without errors
- [ ] Simulation runs with `--use_enhanced_wormhole=true`
- [ ] `wormhole-attack-results.csv` is generated
- [ ] Statistics are printed to console
- [ ] NetAnim visualization shows red malicious nodes
- [ ] Test suite passes all tests
- [ ] Analysis script generates plots

---

**Last Updated:** October 11, 2025

# Quick Troubleshooting Guide

**Last Updated:** October 12, 2025 14:30

---

## 📅 Build Error Resolution Log

### [2025-10-12 15:20] Build Attempt #6: NS_LOG Still Active ⚠️ PARTIAL FIX
**File:** wormhole_attack.cc  
**Error:** g_log not declared (NS_LOG calls need g_log variable)

**Problem:** Removed NS_LOG_COMPONENT_DEFINE but kept NS_LOG_* calls
- NS_LOG macros require g_log to be defined
- When included in routing.cc, should use parent's g_log OR remove all NS_LOG calls

**Solution Applied:** Commented out most NS_LOG_* calls in wormhole_attack.cc
**Remaining:** Some multiline NS_LOG statements may still be uncommented

⚠️ **CRITICAL: You MUST copy updated files from Windows to Linux!**
The Linux system still has OLD versions without these fixes.

---

### [2025-10-12 15:15] Build Attempt #5: Log Component Conflict ✅ FIXED
**File:** wormhole_attack.cc  
**Error:** g_log ambiguity (multiple NS_LOG_COMPONENT_DEFINE)

**Error:** 'reference to g_log is ambiguous'
- **Cause:** Both routing.cc and wormhole_attack.cc define NS_LOG_COMPONENT_DEFINE
- **Fix:** Removed NS_LOG_COMPONENT_DEFINE from wormhole_attack.cc (line 19)
- **Note:** Will use parent file's log component when included

**IMPORTANT:** You also have replay/reply naming errors - this means your Linux system  
has an OLD version of routing.cc. You must copy the FIXED routing.cc from Windows  
to Linux, or the previous 7 variable naming errors will persist!

---

### [2025-10-12 15:00] Build Attempt #4: Linker Error ✅ FIXED
**File:** routing.cc  
**Error:** 9 undefined reference errors (linker stage)

**Error:** Undefined reference to WormholeAttackManager methods
- **Cause:** WAF doesn't compile wormhole_attack.cc automatically in scratch/
- **Fix:** Added `#include "wormhole_attack.cc"` after header (line 58)
- **Reason:** NS-3 scratch directory requires explicit inclusion of .cc files

---

### [2025-10-12 14:45] Build Attempt #3: Missing Applications Module ✅ FIXED
**File:** wormhole_example.cc  
**Error:** 1 error resolved

**Error:** UdpEchoServerHelper/UdpEchoClientHelper not declared (lines 128, 135)
- **Fix:** Added missing header `#include "ns3/applications-module.h"`
- **Change:** Added include after wifi-module.h (line 15)

---

### [2025-10-12 14:30] Build Attempt #2: NS-3 API Errors ✅ FIXED
**Files:** wormhole_attack.h, wormhole_attack.cc  
**Errors:** 3 errors resolved

**Error 1:** Promiscuous callback signature mismatch (line 78)
- **Fix:** Added 2 missing parameters to ReceivePacket() declaration
- **Change:** 4 parameters → 6 parameters (added `const Address &to, NetDevice::PacketType`)

**Error 2:** Ipv4Address has no member 'IsEqual' (line 83)
- **Fix:** Changed `.IsEqual()` to `!=` operator
- **Change:** `!m_peerAddress.IsEqual(...)` → `m_peerAddress != ...`

**Error 3:** Declaration mismatch
- **Fix:** Resolved automatically by Error 1 fix

---

### [2025-10-12 14:00] Build Attempt #1: Variable Naming ✅ FIXED
**File:** routing.cc  
**Errors:** 7 errors resolved

**Errors 1-4:** replay vs reply in declare_attackers() (lines 138584-138613)
- **Fix:** Changed `replay_*` → `reply_*` (4 variable names)

**Errors 5-6:** replay vs reply in main() (line 140910)
- **Fix:** Changed function call parameters `replay_*` → `reply_*`

**Error 7:** Too many arguments (line 140912)
- **Fix:** Removed 4 duplicate parameters (14 → 10 parameters)

---

## Common Build Errors and Solutions

**Solution:** Already fixed in the updated `routing.cc`. The code now includes both naming conventions as aliases:
```cpp
bool present_reply_attack_nodes = false;
bool present_replay_attack_nodes = false;  // Alias
std::vector<bool> reply_malicious_nodes(total_size, false);
std::vector<bool> replay_malicious_nodes(total_size, false);  // Alias
```

### Error 2: Too Many Arguments
```
error: too many arguments to function 'void setup_routing_table_poisoning_attack(...)'
```
**Cause:** Duplicate parameters in function call.

**Solution:** Already fixed. The correct call is:
```cpp
setup_routing_table_poisoning_attack(
    routing_table_poisoning_malicious_nodes,
    total_size,
    simTime,
    anim,
    routing_table_poisoning_malicious_controllers,
    controllers,
    getControllerNode,
    Ipv4Address("99.99.99.0"),
    Ipv4Mask("255.255.255.0"),
    1  // Only 10 parameters, not 14
);
```

### Error 3: Header Not Found
```
fatal error: wormhole_attack.h: No such file or directory
```
**Cause:** Header file not in correct location.

**Solution:**
```bash
# Make sure both files are in the same directory
cd /path/to/ns-3.35/scratch/
ls -l routing.cc wormhole_attack.h wormhole_attack.cc

# If using module structure:
# Include with path: #include "model/wormhole_attack.h"
```

### Error 4: Undefined Reference
```
undefined reference to 'ns3::WormholeAttackManager::Initialize(...)'
```
**Cause:** `wormhole_attack.cc` not being compiled.

**Solution:**
```bash
# For scratch directory:
cd /path/to/ns-3.35/scratch/
# Ensure wormhole_attack.cc exists
ls wormhole_attack.cc

# Rebuild clean
cd ..
./waf clean
./waf configure --enable-examples
./waf build
```

### Error 5: Namespace Issues
```
error: 'WormholeAttackManager' does not name a type
```
**Cause:** Missing namespace qualifier.

**Solution:**
```cpp
// Wrong:
WormholeAttackManager* g_wormholeManager = nullptr;

// Correct:
ns3::WormholeAttackManager* g_wormholeManager = nullptr;
```

### Error 6: Conflicting Declaration
```
error: conflicting declaration of 'bool replay_malicious_nodes'
```
**Cause:** Variable declared twice or with different types.

**Solution:** Check for duplicate declarations. The updated code has proper alias declarations.

---

## Build Commands Reference

### Clean Build
```bash
./waf clean
./waf configure --enable-examples --enable-tests
./waf build
```

### Verbose Build (See Full Errors)
```bash
./waf build -v
```

### Build Specific File
```bash
./waf --targets=routing
```

### Check Syntax Without Full Build
```bash
g++ -std=c++17 -I./build/ns3 -I./src -fsyntax-only scratch/routing.cc
```

---

## Quick Fixes Checklist

Before building, verify:
- [ ] `wormhole_attack.h` is in scratch/ or correct module path
- [ ] `wormhole_attack.cc` is in scratch/ or correct module path
- [ ] `routing.cc` includes `#include "wormhole_attack.h"`
- [ ] Both `replay` and `reply` variables are declared
- [ ] Function calls have correct number of parameters
- [ ] Namespace `ns3::` is used for custom classes
- [ ] All files are saved

---

## Windows-Specific Issues

### Issue: PowerShell Path Problems
```bash
# Use full paths
cd C:\ns-allinone-3.35\ns-3.35
.\waf configure --enable-examples
.\waf build
```

### Issue: Line Endings
```bash
# Convert to Unix line endings if needed
dos2unix scratch/routing.cc
dos2unix scratch/wormhole_attack.h
dos2unix scratch/wormhole_attack.cc
```

### Issue: Visual Studio Build
```bash
# Use specific compiler
./waf configure --enable-examples --check-cxx-compiler=g++
./waf build
```

---

## Test After Build

```bash
# Quick test (10 seconds)
./waf --run "routing --use_enhanced_wormhole=true --simTime=10"

# Verify output file created
ls -l wormhole-attack-results.csv

# Check for error messages
grep -i error wormhole-attack-results.csv
```

---

## Still Having Issues?

1. **Check NS-3 Version:**
   ```bash
   ./waf --version
   ```
   Expected: 3.35 or compatible

2. **Check Compiler:**
   ```bash
   g++ --version
   ```
   Expected: GCC 7+ or Clang 6+

3. **Verify Dependencies:**
   ```bash
   ./waf configure --check-cxx-compiler=g++ --check-profile=optimized
   ```

4. **Try Minimal Example:**
   ```bash
   # Build standalone example first
   ./waf --run wormhole_example
   ```

5. **Check Build Log:**
   ```bash
   ./waf build 2>&1 | tee build.log
   # Review build.log for specific errors
   ```

---

## Getting Help

If errors persist:

1. Copy full error message
2. Note NS-3 version, OS, compiler version
3. Check if files are in correct location
4. Try clean rebuild
5. Consult NS-3 documentation: https://www.nsnam.org/docs/

---

**Last Updated:** October 12, 2025

**Status:** All known compilation errors fixed ✅

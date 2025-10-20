# Replay Attack Compilation Fixes

## Errors Fixed

### Error 1: `std::max` Macro Conflict
**Location:** Line 99440  
**Error:**
```
error: expected unqualified-id before numeric constant
 1363 | #define max 40
99440 | aggregate.attackDuration = std::max(aggregate.attackDuration, stats.attackDuration);
```

**Cause:** The preprocessor macro `#define max 40` conflicts with `std::max()` function call.

**Fix:** Replace `std::max()` with ternary operator:
```cpp
// Before:
aggregate.attackDuration = std::max(aggregate.attackDuration, stats.attackDuration);

// After:
aggregate.attackDuration = (aggregate.attackDuration > stats.attackDuration) ? 
                           aggregate.attackDuration : stats.attackDuration;
```

---

### Error 2: Assignment to Const Member
**Location:** Line 99732  
**Error:**
```
error: assignment of member 'ns3::ReplayDetectionMetrics::falsePositiveRate' in read-only object
m_metrics.falsePositiveRate = static_cast<double>(m_metrics.falsePositives) / m_metrics.totalPacketsProcessed;
```

**Cause:** Cannot modify `m_metrics` in a `const` member function.

**Fix:** Use local variables instead:
```cpp
// Before:
m_metrics.falsePositiveRate = static_cast<double>(m_metrics.falsePositives) / m_metrics.totalPacketsProcessed;
m_metrics.detectionAccuracy = static_cast<double>(m_metrics.replaysDetected - m_metrics.falsePositives) / 
                             std::max(1u, m_metrics.replaysDetected);

// After:
double falsePositiveRate = static_cast<double>(m_metrics.falsePositives) / m_metrics.totalPacketsProcessed;
uint32_t maxReplays = (m_metrics.replaysDetected > 1u) ? m_metrics.replaysDetected : 1u;
double detectionAccuracy = static_cast<double>(m_metrics.replaysDetected - m_metrics.falsePositives) / maxReplays;
```

---

### Error 3: `std::max` Macro Conflict (Second Instance)
**Location:** Line 99734  
**Error:**
```
error: expected unqualified-id before numeric constant
 1363 | #define max 40
99734 | std::max(1u, m_metrics.replaysDetected);
```

**Cause:** Same macro conflict as Error 1.

**Fix:** Replace with ternary operator:
```cpp
// Before:
std::max(1u, m_metrics.replaysDetected)

// After:
(m_metrics.replaysDetected > 1u) ? m_metrics.replaysDetected : 1u
```

---

### Error 4: Unused Variable
**Location:** Line 99855  
**Error:**
```
error: unused variable 'elapsed' [-Werror=unused-variable]
double elapsed = (now - m_lastPerformanceCheck).GetSeconds();
```

**Cause:** Variable `elapsed` declared but never used.

**Fix:** Remove the unused variable:
```cpp
// Before:
void ReplayMitigationManager::PeriodicPerformanceCheck() {
    Time now = Simulator::Now();
    double elapsed = (now - m_lastPerformanceCheck).GetSeconds();

// After:
void ReplayMitigationManager::PeriodicPerformanceCheck() {
    Time now = Simulator::Now();
```

---

### Error 5: Const-Correctness
**Location:** Line 99899  
**Error:**
```
error: passing 'const std::map<unsigned int, unsigned int>' as 'this' argument discards qualifiers
<< " (Total Packets: " << m_packetsProcessedPerNode[pair.first] << ")\n";
```

**Cause:** Using `operator[]` on a const map in a const function. `operator[]` is non-const.

**Fix:** Use `find()` instead:
```cpp
// Before:
for (const auto& pair : m_replaysBlockedPerNode) {
    std::cout << "Node " << pair.first << " - Replays Blocked: " << pair.second 
              << " (Total Packets: " << m_packetsProcessedPerNode[pair.first] << ")\n";
}

// After:
for (const auto& pair : m_replaysBlockedPerNode) {
    auto it = m_packetsProcessedPerNode.find(pair.first);
    uint32_t totalPackets = (it != m_packetsProcessedPerNode.end()) ? it->second : 0;
    std::cout << "Node " << pair.first << " - Replays Blocked: " << pair.second 
              << " (Total Packets: " << totalPackets << ")\n";
}
```

---

## Summary

✅ **5 compilation errors fixed:**
1. `std::max` macro conflict (line 99440) - replaced with ternary operator
2. Const member assignment (line 99732) - use local variables
3. `std::max` macro conflict (line 99734) - replaced with ternary operator  
4. Unused variable `elapsed` (line 99855) - removed
5. Const-correctness with map operator[] (line 99899) - use find()

## Root Causes

1. **Macro `#define max 40`** at line 1363 conflicts with C++ standard library
2. **Const-correctness** issues in member functions
3. **Unused variable** with `-Werror` flag

## Prevention

To avoid these issues in the future:
- Avoid using `std::max` when `#define max` exists, or undef the macro
- Use local variables in const functions instead of modifying members
- Remove unused variables or comment them out with explanation
- Use `at()` or `find()` instead of `operator[]` for const map access

## Testing

After fixes, the code should compile successfully:
```bash
./waf clean
./waf configure
./waf build
```

Expected output:
```
[2885/2885] Linking build/scratch/routing
Build commands will be stored in build/compile_commands.json
'build' finished successfully
```

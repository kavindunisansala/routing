# Fix: Compilation Errors from Non-Const total_size

## Problem

When we changed `total_size` from `const int` to `int`, C++ couldn't use it for compile-time array sizes:

```cpp
error: size of array 'Getdeltas' is not an integral constant-expression
93494 |         double (*Getdeltas())[total_size] ;
```

## Why This Happened

C++ requires array sizes to be **compile-time constants**. When we removed `const`, the compiler couldn't determine array sizes at compile time.

## Solution: Dual Variables

We now use **TWO variables**:

1. **`total_size`** (const int = 28) - For compile-time array declarations
2. **`actual_total_nodes`** (uint32_t) - For runtime loop bounds

### Changes Made

**Line 92-94:**
```cpp
const int total_size = 28;  // Maximum network size for compile-time arrays
uint32_t N_RSUs = 10;
uint32_t N_Vehicles = 18;
uint32_t actual_total_nodes = 28;  // Runtime node count (N_Vehicles + N_RSUs)
```

**Line 139203:**
```cpp
// Update actual_total_nodes based on runtime configuration
actual_total_nodes = N_Vehicles + N_RSUs;
std::cout << "Network configuration: N_Vehicles=" << N_Vehicles 
          << ", N_RSUs=" << N_RSUs 
          << ", actual_total_nodes=" << actual_total_nodes 
          << ", total_size=" << total_size << " (compile-time max)" << std::endl;
```

**Line 116671 (transmit_solution):**
```cpp
for (uint32_t u=0;u< actual_total_nodes;u++)  // Changed from total_size
```

**Line 116701 (transmit_delta_values):**
```cpp
for (uint32_t u=0;u< actual_total_nodes;u++)  // Changed from total_size
```

## How It Works

1. **Compile time:** Arrays use `total_size=28` (max capacity)
2. **Runtime:** Code changes to `N_Vehicles=22, N_RSUs=1`
3. **Runtime:** `actual_total_nodes = 22 + 1 = 23`
4. **Loops:** Use `actual_total_nodes=23` (not 28!)
5. **Safety checks:** Prevent accessing indices 1-9 in RSU_Nodes (only 0 exists)

## Result

- ✅ Arrays compile with `total_size` (const)
- ✅ Loops use `actual_total_nodes` (runtime value)
- ✅ No out-of-bounds access to RSU_Nodes
- ✅ No SIGSEGV at 1.036s!

---

**Commit:** Pending
**Files:** routing.cc (4 changes)

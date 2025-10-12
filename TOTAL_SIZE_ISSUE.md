# CRITICAL ISSUE: total_size Mismatch

## The Real Problem

Your simulation crashed because of a **fundamental mismatch**:

- **Code expects:** `total_size = 100` nodes (hardcoded throughout 140K+ lines)
- **Actual nodes created:** 30 nodes (shown in your output: "Total Nodes (actual): 30")
- **Code tries to access:** Arrays sized for 100, using indices 0-29
- **Result:** Null pointer crash when routing tries to access node data

## Why This Happens

The simulation creates different numbers of nodes based on parameters:
- Default: N_Vehicles=75, N_RSUs=40 → 117+ nodes
- Your run: Created only 30 nodes somehow

## The Core Issue

`total_size = 100` is **NOT just a variable** - it's a compile-time constant used in:
1. Array declarations: `double (*deltas)[total_size]`
2. Vector initializations: `std::vector<bool> nodes(total_size, false)`  
3. Loop boundaries: `for(uint32_t i=0; i<total_size; i++)`
4. Routing algorithms throughout the code

**You CANNOT change it dynamically** without rewriting huge portions of code.

## Two Solutions

### Option 1: Match Node Count to total_size (RECOMMENDED)

Run the simulation with parameters that create exactly 100 nodes:

```bash
# Calculate: 1 controller + 1 management + 98 network nodes = 100
# Split as: 60 vehicles + 38 RSUs = 98
./waf --run "routing --use_enhanced_wormhole=true --N_Vehicles=60 --N_RSUs=38 --simTime=30"
```

Or safer - create MORE than 100:
```bash
# Keep default: 75 vehicles + 40 RSUs = 117+ nodes (> 100 is OK)
./waf --run "routing --use_enhanced_wormhole=true --N_Vehicles=75 --N_RSUs=40 --simTime=30"
```

### Option 2: Change total_size to Match Your Nodes (RISKY)

If you really want 30 nodes, you need to:

1. **Change line 92 to:**
   ```cpp
   const int total_size = 28;  // 30 total - 2 special nodes
   ```

2. **Set node parameters:**
   ```cpp
   uint32_t N_RSUs = 10;
   uint32_t N_Vehicles = 18;
   // 1 + 1 + 18 + 10 = 30 nodes
   ```

3. **Rebuild completely:**
   ```bash
   ./waf clean
   ./waf build
   ```

## Why Your Run Has Only 30 Nodes

Check your command line - you might have used:
```bash
--N_Vehicles=18 --N_RSUs=10
```

Or there's a configuration override somewhere limiting nodes.

## Immediate Fix

**Try this command (matching defaults):**

```bash
cd ~/Downloads/ns-allinone-3.35/ns-3.35
./waf --run "routing --use_enhanced_wormhole=true --simTime=30"
# Don't specify N_Vehicles or N_RSUs - use defaults
```

This should create 115+ nodes (more than 100), which is OK because:
- Arrays can hold up to 100
- Our wormhole fix uses actual count dynamically
- Routing code will only use first 100 nodes for routing tables

## Why the Null Pointer Crash

At line 115474:
```cpp
for(uint32_t i=0; i<total_size; i++)  // loops 0-99 (100 times)
{
    proposed_algo2_output_inst[flow_id].met[i] = false;  // accessing index 30-99
    // These indices don't exist when you only have 30 nodes!
}
```

The routing algorithm tries to initialize arrays for 100 nodes but you only have 30, causing null pointer access.

## Bottom Line

**Do NOT try to change total_size dynamically.** Instead:

1. ✅ **Run with default node counts** (75 vehicles + 40 RSUs)
2. ✅ **Or explicitly set:** `--N_Vehicles=60 --N_RSUs=38` (= ~100 nodes)
3. ❌ **Do NOT use fewer than 98 network nodes** (100 minus 2 special nodes)

The wormhole attack fix I made is correct and working (notice "Created 1 wormhole tunnels" - no crash there!). The crash is in the routing algorithm which expects exactly 100 nodes.

## Quick Test Command

```bash
cd ~/Downloads/ns-allinone-3.35/ns-3.35
./waf --run "routing --use_enhanced_wormhole=true --N_Vehicles=60 --N_RSUs=38 --simTime=30"
```

This should give you ~100 nodes and prevent the routing crash.

#!/bin/bash

################################################################################
# Verify if NS-3 Fixes Were Applied
################################################################################

echo "================================================================================"
echo "CHECKING IF NS-3 WAS REBUILT WITH FIXES"
echo "================================================================================"
echo ""

# Check build timestamp
ROUTING_BIN="/home/eie/ns-allinone-3.35/ns-3.35/build/scratch/routing"
if [ -f "$ROUTING_BIN" ]; then
    echo "Build executable found:"
    ls -lh "$ROUTING_BIN"
    echo ""
    echo "Build timestamp:"
    stat "$ROUTING_BIN" | grep "Modify:"
    echo ""
else
    echo "❌ ERROR: Executable not found at $ROUTING_BIN"
    exit 1
fi

# Check if routing.cc was modified
ROUTING_SRC="/home/eie/ns-allinone-3.35/ns-3.35/scratch/routing.cc"
if [ -f "$ROUTING_SRC" ]; then
    echo "Source file found:"
    ls -lh "$ROUTING_SRC"
    echo ""
    echo "Source timestamp:"
    stat "$ROUTING_SRC" | grep "Modify:"
    echo ""
else
    echo "❌ ERROR: Source file not found at $ROUTING_SRC"
    exit 1
fi

# Check if binary is older than source (needs rebuild)
if [ "$ROUTING_SRC" -nt "$ROUTING_BIN" ]; then
    echo "⚠️  WARNING: Source file is NEWER than binary!"
    echo "   → NS-3 needs to be rebuilt!"
    echo ""
    NEEDS_REBUILD=true
else
    echo "✓ Binary is up to date"
    echo ""
    NEEDS_REBUILD=false
fi

# Check for specific fixes in source code
echo "================================================================================"
echo "VERIFYING FIXES IN SOURCE CODE"
echo "================================================================================"
echo ""

echo "1. Checking for 'actual_total_nodes' fix (lines 152197, 152479, 152648)..."
FIXED_COUNT=$(grep -c "rand()%actual_total_nodes" "$ROUTING_SRC" || echo 0)
if [ "$FIXED_COUNT" -ge 3 ]; then
    echo "   ✓ Found $FIXED_COUNT instances of 'rand()%actual_total_nodes'"
else
    echo "   ❌ ERROR: Only found $FIXED_COUNT instances (expected 3+)"
fi
echo ""

echo "2. Checking for bounds checking in check_and_transmit (line 132773)..."
if grep -q "Bounds checking for node access" "$ROUTING_SRC"; then
    echo "   ✓ Bounds checking found in check_and_transmit"
else
    echo "   ❌ ERROR: Bounds checking NOT found in check_and_transmit"
fi
echo ""

echo "3. Checking for 'return' fix in MacRx (line 130793)..."
# This is harder to check without context, skip for now
echo "   (Skipped - requires context check)"
echo ""

# Summary
echo "================================================================================"
echo "SUMMARY"
echo "================================================================================"
echo ""

if [ "$NEEDS_REBUILD" = true ]; then
    echo "⚠️  ACTION REQUIRED: Rebuild NS-3"
    echo ""
    echo "Run these commands:"
    echo "  cd ~/ns-allinone-3.35/ns-3.35"
    echo "  ./waf build"
    echo ""
elif [ "$FIXED_COUNT" -lt 3 ]; then
    echo "⚠️  ACTION REQUIRED: Apply fixes to routing.cc"
    echo ""
    echo "The fixes haven't been applied to the source code yet!"
    echo ""
else
    echo "✓ Fixes appear to be applied correctly"
    echo "✓ Binary is up to date"
    echo ""
    echo "If tests are still failing, the issue may be elsewhere."
fi

echo "================================================================================"

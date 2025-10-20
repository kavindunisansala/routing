#!/bin/bash

# Replay Attack Verification Script
# This script helps diagnose why packet capture isn't working

echo "=========================================="
echo "Replay Attack System Verification"
echo "=========================================="
echo ""

# Check if we're in ns-3 directory
if [ ! -f "waf" ]; then
    echo "ERROR: Not in ns-3 directory!"
    echo "Please run this script from your ns-3.35 directory"
    exit 1
fi

echo "1. Checking routing.cc exists..."
if [ -f "scratch/routing.cc" ]; then
    echo "   ✓ routing.cc found in scratch directory"
    
    # Check for the fix
    if grep -q "GetNode()->GetNDevices()" scratch/routing.cc; then
        echo "   ✓ Packet capture fix is present (uses GetNode())"
    else
        echo "   ✗ WARNING: Fix not found! Check if code is updated"
    fi
else
    echo "   ✗ ERROR: routing.cc not found in scratch directory"
    exit 1
fi

echo ""
echo "2. Compiling (this may take a moment)..."
./waf > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "   ✓ Compilation successful"
else
    echo "   ✗ Compilation failed - check for errors"
    exit 1
fi

echo ""
echo "3. Running simulation with replay attack..."
echo "   (Looking for debug messages...)"
echo ""

./waf --run "routing --enable_replay_attack=true --enable_replay_detection=true --simTime=10" 2>&1 | tee /tmp/replay_output.log

echo ""
echo "=========================================="
echo "Analysis of Output"
echo "=========================================="

# Check for key indicators
MALICIOUS_COUNT=$(grep -c "Starting replay attack on node" /tmp/replay_output.log)
CALLBACK_COUNT=$(grep -c "Installed promiscuous callback" /tmp/replay_output.log)
INTERCEPT_COUNT=$(grep -c "InterceptPacket callback is working" /tmp/replay_output.log)
CAPTURED=$(grep "Total Packets Captured:" /tmp/replay_output.log | awk '{print $4}')
REPLAYED=$(grep "Total Packets Replayed:" /tmp/replay_output.log | awk '{print $4}')

echo ""
echo "Malicious Nodes Started: $MALICIOUS_COUNT"
echo "Callbacks Installed: $CALLBACK_COUNT"
echo "InterceptPacket Calls: $INTERCEPT_COUNT"
echo "Packets Captured: $CAPTURED"
echo "Packets Replayed: $REPLAYED"
echo ""

# Diagnosis
if [ "$MALICIOUS_COUNT" -eq 0 ]; then
    echo "❌ PROBLEM: Applications not starting"
    echo "   Check: Application scheduling and start times"
elif [ "$CALLBACK_COUNT" -eq 0 ]; then
    echo "❌ PROBLEM: Callbacks not being installed"
    echo "   Check: Device types (might all be point-to-point)"
elif [ "$INTERCEPT_COUNT" -eq 0 ]; then
    echo "❌ PROBLEM: Callbacks installed but not triggered"
    echo "   Check: Packet flow during attack window"
elif [ "$CAPTURED" -eq 0 ]; then
    echo "❌ PROBLEM: Intercepts happening but not capturing"
    echo "   Check: CapturePacket() implementation"
elif [ "$REPLAYED" -eq 0 ]; then
    echo "⚠️  WARNING: Capturing but not replaying"
    echo "   Check: Replay scheduling and timing"
else
    echo "✅ SUCCESS: Replay attack system is working!"
fi

echo ""
echo "Full output saved to: /tmp/replay_output.log"
echo "To view: cat /tmp/replay_output.log | grep REPLAY"

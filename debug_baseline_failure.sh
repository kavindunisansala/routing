#!/bin/bash

################################################################################
# Debug Script - Analyze Baseline Test Failure
# Investigates why test01_baseline failed after 637s
################################################################################

echo "================================================================================"
echo "DEEP ANALYSIS: BASELINE TEST FAILURE"
echo "================================================================================"
echo ""

# Find the most recent wormhole evaluation directory
LATEST_DIR=$(ls -td wormhole_evaluation_* 2>/dev/null | head -1)

if [ -z "$LATEST_DIR" ]; then
    echo "ERROR: No wormhole evaluation directory found!"
    echo "Please run the test first: ./test_wormhole_focused.sh"
    exit 1
fi

echo "Analyzing directory: $LATEST_DIR"
echo ""

# Check if baseline log exists
BASELINE_LOG="${LATEST_DIR}/simulation.log"

if [ ! -f "$BASELINE_LOG" ]; then
    echo "ERROR: Baseline log not found at $BASELINE_LOG"
    exit 1
fi

echo "================================================================================
" 
echo "1. LOG FILE SIZE AND BASIC INFO"
echo "================================================================================"
ls -lh "$BASELINE_LOG"
echo ""
echo "Total lines in log: $(wc -l < "$BASELINE_LOG")"
echo ""

echo "================================================================================"
echo "2. LAST 50 LINES OF LOG (Error Context)"
echo "================================================================================"
tail -50 "$BASELINE_LOG"
echo ""

echo "================================================================================"
echo "3. SEARCH FOR CRITICAL ERRORS"
echo "================================================================================"
echo ""

echo "--- Segmentation Faults ---"
grep -i "segmentation fault\|segfault\|core dumped" "$BASELINE_LOG" || echo "None found"
echo ""

echo "--- Assertion Failures ---"
grep -i "assert\|assertion failed" "$BASELINE_LOG" || echo "None found"
echo ""

echo "--- Abort/Terminate ---"
grep -i "abort\|terminate\|fatal" "$BASELINE_LOG" || echo "None found"
echo ""

echo "--- Out of Bounds Warnings ---"
grep -i "out of bounds\|WARNING.*bounds" "$BASELINE_LOG" | tail -20 || echo "None found"
echo ""

echo "--- Memory Errors ---"
grep -i "bad_alloc\|out of memory\|allocation failed" "$BASELINE_LOG" || echo "None found"
echo ""

echo "--- NS-3 Errors ---"
grep -i "ns3.*error\|ERROR:" "$BASELINE_LOG" | tail -20 || echo "None found"
echo ""

echo "================================================================================"
echo "4. SIMULATION PROGRESS CHECK"
echo "================================================================================"
echo ""

echo "--- Simulation Time Progress ---"
grep -E "Simulator.*Now|Current.*time|Simulation.*time" "$BASELINE_LOG" | tail -10 || echo "No time stamps found"
echo ""

echo "--- Packet Statistics ---"
grep -i "packet.*sent\|packet.*received\|packet.*delivered" "$BASELINE_LOG" | tail -10 || echo "No packet stats found"
echo ""

echo "--- Did simulation complete? ---"
grep -i "simulation.*complete\|simulation.*finished\|simulation.*end" "$BASELINE_LOG" || echo "❌ Simulation did NOT complete normally"
echo ""

echo "================================================================================"
echo "5. CHECK FOR INFINITE LOOPS OR HANGS"
echo "================================================================================"
echo ""

echo "--- Repeated Messages (potential infinite loop) ---"
tail -100 "$BASELINE_LOG" | sort | uniq -c | sort -rn | head -10
echo ""

echo "================================================================================"
echo "6. ROUTING TABLE SIZE ISSUES"
echo "================================================================================"
echo ""

echo "--- Routing Table Accesses ---"
grep -i "routing table\|route.*entry" "$BASELINE_LOG" | wc -l
echo " routing table related lines found"
echo ""

echo "--- Array Index Issues ---"
grep -E "index.*[0-9]+.*exceeds\|index.*out of range" "$BASELINE_LOG" | tail -10 || echo "None found"
echo ""

echo "================================================================================"
echo "7. 70-NODE SPECIFIC ISSUES"
echo "================================================================================"
echo ""

echo "--- Node Count Mentions ---"
grep -E "70 nodes|60 vehicles|10 RSU" "$BASELINE_LOG" | head -5 || echo "No node count found"
echo ""

echo "--- MAX_NODES Checks ---"
grep -i "MAX_NODES\|max.*nodes\|node.*limit" "$BASELINE_LOG" || echo "None found"
echo ""

echo "================================================================================"
echo "8. SYSTEM RESOURCE ISSUES"
echo "================================================================================"
echo ""

# Check if the process ran out of resources
if [ -f "/var/log/syslog" ]; then
    echo "--- Recent System Errors (last 30 mins) ---"
    sudo journalctl --since "30 minutes ago" | grep -i "kill\|oom\|out of memory" | tail -10 || echo "No system resource issues found"
elif [ -f "/var/log/messages" ]; then
    echo "--- Recent System Errors ---"
    sudo tail -100 /var/log/messages | grep -i "kill\|oom\|out of memory" || echo "No system resource issues found"
else
    echo "System logs not accessible (need sudo)"
fi
echo ""

echo "================================================================================"
echo "9. COMPILATION/LINKING ISSUES"
echo "================================================================================"
echo ""

echo "--- Undefined References ---"
grep -i "undefined reference\|undefined symbol" "$BASELINE_LOG" || echo "None found"
echo ""

echo "--- Missing Main Function ---"
grep -i "undefined reference to.*main" "$BASELINE_LOG" || echo "None found"
echo ""

echo "================================================================================"
echo "10. EXIT STATUS ANALYSIS"
echo "================================================================================"
echo ""

# Check if there's an exit status file
if [ -f "${LATEST_DIR}/test01_baseline.exit" ]; then
    EXIT_CODE=$(cat "${LATEST_DIR}/test01_baseline.exit")
    echo "Exit Code: $EXIT_CODE"
    echo ""
    case $EXIT_CODE in
        0)
            echo "✓ Normal exit"
            ;;
        1)
            echo "✗ General error"
            ;;
        2)
            echo "✗ Misuse of shell command"
            ;;
        126)
            echo "✗ Command cannot execute (permission issue)"
            ;;
        127)
            echo "✗ Command not found"
            ;;
        128)
            echo "✗ Invalid exit argument"
            ;;
        130)
            echo "✗ Script terminated by Ctrl+C (SIGINT)"
            ;;
        137)
            echo "✗ Process killed (SIGKILL) - possibly OOM"
            ;;
        139)
            echo "✗ Segmentation fault (SIGSEGV)"
            ;;
        143)
            echo "✗ Terminated (SIGTERM)"
            ;;
        *)
            echo "✗ Unknown error code: $EXIT_CODE"
            ;;
    esac
else
    echo "No exit code file found"
fi
echo ""

echo "================================================================================"
echo "11. RECOMMENDED ACTIONS"
echo "================================================================================"
echo ""

# Analyze and provide recommendations
HAS_BOUNDS_ERROR=$(grep -c "out of bounds" "$BASELINE_LOG" 2>/dev/null || echo 0)
HAS_SEGFAULT=$(grep -c "segmentation fault\|segfault" "$BASELINE_LOG" 2>/dev/null || echo 0)
HAS_ASSERT=$(grep -c "assertion failed" "$BASELINE_LOG" 2>/dev/null || echo 0)
SIM_COMPLETE=$(grep -c "simulation.*complete\|Simulation.*finished" "$BASELINE_LOG" 2>/dev/null || echo 0)

if [ $HAS_SEGFAULT -gt 0 ]; then
    echo "⚠ SEGMENTATION FAULT detected!"
    echo "   Action: Run with gdb to get stack trace:"
    echo "   gdb --args ~/ns-allinone-3.35/ns-3.35/build/scratch/routing [args]"
    echo ""
elif [ $HAS_BOUNDS_ERROR -gt 0 ]; then
    echo "⚠ BOUNDS CHECK WARNINGS detected!"
    echo "   Action: Review all bounds checking in routing.cc"
    echo "   The added bounds checks should 'return' not 'continue'"
    echo "   Check lines: 106200, 130775, 132258, 133208, 124143, 124154"
    echo ""
elif [ $HAS_ASSERT -gt 0 ]; then
    echo "⚠ ASSERTION FAILURE detected!"
    echo "   Action: Review the assertion condition and fix the logic"
    echo ""
elif [ $SIM_COMPLETE -eq 0 ]; then
    echo "⚠ SIMULATION DID NOT COMPLETE!"
    echo "   Possible causes:"
    echo "   1. Infinite loop in routing logic"
    echo "   2. Deadlock in event scheduling"
    echo "   3. Process killed by system (OOM)"
    echo "   4. Timeout (637s suggests manual termination)"
    echo ""
    echo "   Actions:"
    echo "   1. Check last simulation time reached (should be 60s)"
    echo "   2. Monitor memory usage: watch -n 1 free -h"
    echo "   3. Run with smaller node count (e.g., 40 nodes) to verify"
    echo "   4. Add debug output in routing.cc main loop"
else
    echo "✓ No obvious errors found in log"
    echo "  The test may have timed out or been manually stopped"
fi
echo ""

echo "================================================================================"
echo "12. QUICK VERIFICATION COMMANDS"
echo "================================================================================"
echo ""
echo "# Check if executable exists and has correct permissions:"
echo "ls -lh ~/ns-allinone-3.35/ns-3.35/build/scratch/routing"
echo ""
echo "# Run a quick 10-second test with 30 nodes:"
echo "cd ~/ns-allinone-3.35/ns-3.35"
echo "./build/scratch/routing --total_nodes=30 --n_vehicles=27 --n_rsu=3 --simulation_time=10 --architecture=0"
echo ""
echo "# Monitor memory during test:"
echo "watch -n 1 'ps aux | grep routing | grep -v grep'"
echo ""
echo "# Check for core dumps:"
echo "ls -lh core* 2>/dev/null"
echo ""

echo "================================================================================"
echo "ANALYSIS COMPLETE"
echo "================================================================================"

#!/bin/bash
# Verify routing.cc has the compilation fixes applied
# Run this on your Linux VM to check if the file is correct

FILE="$HOME/Downloads/ns-allinone-3.35/ns-3.35/scratch/routing.cc"

echo "========================================"
echo "Verifying routing.cc compilation fixes"
echo "========================================"
echo ""

if [ ! -f "$FILE" ]; then
    echo "❌ ERROR: File not found at $FILE"
    exit 1
fi

echo "File found: $FILE"
echo ""

# Check 1: Forward declaration should NOT exist
echo "Check 1: Forward declaration removed?"
if grep -q "^enum MitigationType;" "$FILE"; then
    echo "❌ FAIL: 'enum MitigationType;' forward declaration still exists (line below)"
    grep -n "^enum MitigationType;" "$FILE"
    echo "   ACTION: Delete this line"
    FIX1=0
else
    echo "✅ PASS: Forward declaration removed"
    FIX1=1
fi
echo ""

# Check 2: Declaration has const
echo "Check 2: GetTypeName() declaration has const?"
if grep -q "std::string GetTypeName(MitigationType type) const;" "$FILE"; then
    echo "✅ PASS: Declaration has const (line below)"
    grep -n "std::string GetTypeName(MitigationType type) const;" "$FILE" | head -1
    FIX2=1
else
    echo "❌ FAIL: Declaration missing const"
    grep -n "std::string GetTypeName(MitigationType type);" "$FILE" | head -1
    echo "   ACTION: Add 'const' before semicolon"
    FIX2=0
fi
echo ""

# Check 3: Implementation has const
echo "Check 3: GetTypeName() implementation has const?"
if grep -q "std::string MitigationCoordinator::GetTypeName(MitigationType type) const {" "$FILE"; then
    echo "✅ PASS: Implementation has const (line below)"
    grep -n "std::string MitigationCoordinator::GetTypeName(MitigationType type) const {" "$FILE" | head -1
    FIX3=1
else
    echo "❌ FAIL: Implementation missing const"
    grep -n "std::string MitigationCoordinator::GetTypeName(MitigationType type) {" "$FILE" | head -1
    echo "   ACTION: Add 'const' before opening brace"
    FIX3=0
fi
echo ""

# Summary
echo "========================================"
echo "Summary"
echo "========================================"
if [ $FIX1 -eq 1 ] && [ $FIX2 -eq 1 ] && [ $FIX3 -eq 1 ]; then
    echo "✅ ALL FIXES APPLIED - Ready to build!"
    echo ""
    echo "Run: cd ~/Downloads/ns-allinone-3.35/ns-3.35 && ./waf build"
else
    echo "❌ FIXES NEEDED - File is not updated"
    echo ""
    echo "Options:"
    echo "1. Copy the fixed routing.cc from Windows to Linux"
    echo "2. Run the fix_compilation.sh script"
    echo "3. Manually edit the file (see COMPILATION_FIX_INSTRUCTIONS.md)"
fi
echo ""

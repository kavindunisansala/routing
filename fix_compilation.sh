#!/bin/bash
# Fix MitigationCoordinator compilation errors in routing.cc
# Date: 2025-11-06

echo "Fixing routing.cc compilation errors..."

cd ~/Downloads/ns-allinone-3.35/ns-3.35/scratch/

# Backup
echo "Creating backup: routing.cc.backup"
cp routing.cc routing.cc.backup

# Fix 1: Remove invalid enum forward declaration
echo "Fix 1: Removing 'enum MitigationType;' forward declaration"
sed -i '/^enum MitigationType;$/d' routing.cc

# Fix 2: Add const to GetTypeName declaration
echo "Fix 2: Adding const to GetTypeName() declaration"
sed -i 's/std::string GetTypeName(MitigationType type);$/std::string GetTypeName(MitigationType type) const;/' routing.cc

# Fix 3: Add const to GetTypeName implementation
echo "Fix 3: Adding const to GetTypeName() implementation"
sed -i 's/std::string MitigationCoordinator::GetTypeName(MitigationType type) {$/std::string MitigationCoordinator::GetTypeName(MitigationType type) const {/' routing.cc

echo ""
echo "Verifying fixes..."
echo ""

# Verify fix 1
echo "Checking fix 1 (should be empty):"
grep -n "^enum MitigationType;$" routing.cc || echo "✓ Forward declaration removed"
echo ""

# Verify fix 2
echo "Checking fix 2 (should show line with const):"
grep -n "std::string GetTypeName(MitigationType type) const;" routing.cc | head -1
echo ""

# Verify fix 3
echo "Checking fix 3 (should show line with const):"
grep -n "std::string MitigationCoordinator::GetTypeName(MitigationType type) const {" routing.cc | head -1
echo ""

echo "Fixes applied! Now building..."
echo ""

cd ~/Downloads/ns-allinone-3.35/ns-3.35/
./waf build

echo ""
echo "Done!"

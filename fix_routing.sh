#!/bin/bash
# fix_routing.sh - Remove GetIpFromNodeId function from routing.cc

echo "=== Fixing routing.cc - Removing GetIpFromNodeId function ==="

# Backup
cp ~/Downloads/ns-allinone-3.35/ns-3.35/scratch/routing.cc ~/Downloads/ns-allinone-3.35/ns-3.35/scratch/routing.cc.backup
echo "✅ Backup created: routing.cc.backup"

# Search for the function
echo ""
echo "Searching for GetIpFromNodeId function..."
grep -n "GetIpFromNodeId" ~/Downloads/ns-allinone-3.35/ns-3.35/scratch/routing.cc

echo ""
echo "This function must be manually removed from your routing.cc file."
echo ""
echo "Please follow these steps:"
echo "1. Open the file in nano:"
echo "   nano ~/Downloads/ns-allinone-3.35/ns-3.35/scratch/routing.cc"
echo ""
echo "2. Press Ctrl+W to search for: GetIpFromNodeId"
echo ""
echo "3. Delete the entire function (typically looks like this):"
echo "   Ipv4Address GetIpFromNodeId(uint32_t nodeId) {"
echo "       if (nodeId >= Nodes.GetN()) return Ipv4Address::GetZero();"
echo "       ... more lines ..."
echo "   }"
echo ""
echo "4. Delete ALL calls to GetIpFromNodeId in the file"
echo ""
echo "5. Save with Ctrl+O, then Enter, then Ctrl+X"
echo ""
echo "6. Recompile:"
echo "   cd ~/Downloads/ns-allinone-3.35/ns-3.35"
echo "   ./waf clean"
echo "   ./waf"
echo ""
echo "OR better yet - download fresh from GitHub:"
echo "   wget https://raw.githubusercontent.com/kavindunisansala/routing/master/routing.cc -O ~/Downloads/ns-allinone-3.35/ns-3.35/scratch/routing.cc"
echo ""

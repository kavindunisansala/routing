#!/bin/bash
################################################################################
# Quick Fix Script - Download Latest routing.cc from GitHub
# Run this on your Linux system
################################################################################

echo "═══════════════════════════════════════════════════════════════════════════"
echo "  Downloading latest routing.cc from GitHub..."
echo "═══════════════════════════════════════════════════════════════════════════"

cd ~/Downloads/ns-allinone-3.35/ns-3.35/scratch

# Backup old file
echo "Backing up old routing.cc..."
cp routing.cc routing.cc.backup_$(date +%Y%m%d_%H%M%S)

# Download latest from GitHub
echo "Downloading from GitHub..."
wget -q --show-progress -O routing.cc \
  https://raw.githubusercontent.com/kavindunisansala/routing/master/routing.cc

if [ $? -eq 0 ]; then
    echo "✅ Download successful!"
    
    # Also get the .inc file
    echo "Downloading wormhole_attack.inc..."
    wget -q --show-progress -O wormhole_attack.inc \
      https://raw.githubusercontent.com/kavindunisansala/routing/master/wormhole_attack.inc
    
    echo "Downloading wormhole_attack.h..."
    wget -q --show-progress -O wormhole_attack.h \
      https://raw.githubusercontent.com/kavindunisansala/routing/master/wormhole_attack.h
    
    echo ""
    echo "═══════════════════════════════════════════════════════════════════════════"
    echo "  Verifying files..."
    echo "═══════════════════════════════════════════════════════════════════════════"
    
    # Verify the fix
    echo ""
    echo "Checking for replay/reply alias variables:"
    grep -n "present_replay_attack_nodes.*alias" routing.cc || \
    grep -n "uint32_t present_replay_attack_nodes" routing.cc || \
    echo "⚠️  Alias not found - checking alternate location..."
    
    echo ""
    echo "Checking wormhole include:"
    grep -n '#include "wormhole_attack.inc"' routing.cc
    
    echo ""
    echo "Files in scratch directory:"
    ls -lh routing.cc wormhole_attack.*
    
    echo ""
    echo "═══════════════════════════════════════════════════════════════════════════"
    echo "  ✅ Files updated! Now build:"
    echo "═══════════════════════════════════════════════════════════════════════════"
    echo ""
    echo "  cd ~/Downloads/ns-allinone-3.35/ns-3.35"
    echo "  ./waf build"
    echo ""
else
    echo "❌ Download failed! Check your internet connection."
    echo "   Restoring backup..."
    mv routing.cc.backup_* routing.cc 2>/dev/null
    exit 1
fi

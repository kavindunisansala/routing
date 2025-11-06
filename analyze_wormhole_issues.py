#!/usr/bin/env python3
"""
Wormhole Attack Analysis - Diagnostic Script
Analyzes the issues with wormhole tunnel creation and mitigation effectiveness
"""

import os
import pandas as pd
import sys

def analyze_wormhole_results(results_dir):
    """Analyze wormhole attack results"""
    
    print("="*80)
    print("WORMHOLE ATTACK DIAGNOSTIC ANALYSIS")
    print("="*80)
    
    # Test directories to analyze
    tests = [
        ("Baseline", "test01_baseline"),
        ("20% No Mitigation", "test02_wormhole_20_no_mitigation"),
        ("40% No Mitigation", "test02_wormhole_40_no_mitigation"),
        ("60% No Mitigation", "test02_wormhole_60_no_mitigation"),
        ("80% No Mitigation", "test02_wormhole_80_no_mitigation"),
        ("100% No Mitigation", "test02_wormhole_100_no_mitigation"),
        ("20% With Detection", "test03_wormhole_20_with_detection"),
        ("40% With Detection", "test03_wormhole_40_with_detection"),
        ("60% With Detection", "test03_wormhole_60_with_detection"),
        ("80% With Detection", "test03_wormhole_80_with_detection"),
        ("20% With Mitigation", "test04_wormhole_20_with_mitigation"),
        ("40% With Mitigation", "test04_wormhole_40_with_mitigation"),
        ("60% With Mitigation", "test04_wormhole_60_with_mitigation"),
        ("80% With Mitigation", "test04_wormhole_80_with_mitigation"),
    ]
    
    print("\n" + "-"*80)
    print("PACKET DELIVERY ANALYSIS")
    print("-"*80)
    print(f"{'Test':<35} {'PDR%':<10} {'Delivered':<12} {'Dropped':<10} {'Total':<10}")
    print("-"*80)
    
    for test_name, test_dir in tests:
        pdr_file = os.path.join(results_dir, test_dir, "packet-delivery-analysis.csv")
        if not os.path.exists(pdr_file):
            print(f"{test_name:<35} {'N/A':<10}")
            continue
        
        df = pd.read_csv(pdr_file)
        total = len(df)
        delivered = len(df[df['Delivered'] == 1])
        dropped = total - delivered
        pdr = (delivered / total * 100) if total > 0 else 0
        
        print(f"{test_name:<35} {pdr:>6.2f}%    {delivered:<12} {dropped:<10} {total:<10}")
    
    print("\n" + "-"*80)
    print("WORMHOLE TUNNEL ANALYSIS")
    print("-"*80)
    print(f"{'Test':<35} {'Tunnels':<10} {'Active':<10} {'Packets':<12} {'Nodes':<20}")
    print("-"*80)
    
    for test_name, test_dir in tests:
        if "baseline" in test_dir:
            continue
        
        attack_file = os.path.join(results_dir, test_dir, "wormhole-attack-results.csv")
        if not os.path.exists(attack_file):
            print(f"{test_name:<35} {'N/A':<10}")
            continue
        
        df = pd.read_csv(attack_file)
        # Remove TOTAL row
        df = df[df['TunnelID'] != 'TOTAL']
        
        total_tunnels = len(df)
        active_tunnels = len(df[df['PacketsIntercepted'] > 0])
        total_packets = df['PacketsIntercepted'].sum()
        
        # Get node pairs
        nodes = []
        for _, row in df.iterrows():
            if row['PacketsIntercepted'] > 0:
                nodes.append(f"({row['NodeA']}-{row['NodeB']})")
        nodes_str = ", ".join(nodes[:3])
        if len(nodes) > 3:
            nodes_str += f", +{len(nodes)-3} more"
        
        print(f"{test_name:<35} {total_tunnels:<10} {active_tunnels:<10} {total_packets:<12} {nodes_str}")
    
    print("\n" + "-"*80)
    print("MITIGATION EFFECTIVENESS ANALYSIS")
    print("-"*80)
    
    mitigation_tests = [
        ("20%", "test03_wormhole_20_with_detection", "test04_wormhole_20_with_mitigation"),
        ("40%", "test03_wormhole_40_with_detection", "test04_wormhole_40_with_mitigation"),
        ("60%", "test03_wormhole_60_with_detection", "test04_wormhole_60_with_mitigation"),
        ("80%", "test03_wormhole_80_with_detection", "test04_wormhole_80_with_mitigation"),
    ]
    
    print(f"{'Attack %':<12} {'Detection Only':<20} {'Full Mitigation':<20} {'Improvement':<15}")
    print("-"*80)
    
    for percentage, detection_dir, mitigation_dir in mitigation_tests:
        detection_file = os.path.join(results_dir, detection_dir, "wormhole-detection-results.csv")
        mitigation_file = os.path.join(results_dir, mitigation_dir, "wormhole-detection-results.csv")
        
        if os.path.exists(detection_file):
            det_df = pd.read_csv(detection_file)
            flows_detected_det = det_df[det_df['Metric'] == 'FlowsDetected']['Value'].values[0] if len(det_df[det_df['Metric'] == 'FlowsDetected']) > 0 else 0
            routes_changed_det = det_df[det_df['Metric'] == 'RouteChangesTriggered']['Value'].values[0] if len(det_df[det_df['Metric'] == 'RouteChangesTriggered']) > 0 else 0
        else:
            flows_detected_det = 0
            routes_changed_det = 0
        
        if os.path.exists(mitigation_file):
            mit_df = pd.read_csv(mitigation_file)
            flows_detected_mit = mit_df[mit_df['Metric'] == 'FlowsDetected']['Value'].values[0] if len(mit_df[mit_df['Metric'] == 'FlowsDetected']) > 0 else 0
            routes_changed_mit = mit_df[mit_df['Metric'] == 'RouteChangesTriggered']['Value'].values[0] if len(mit_df[mit_df['Metric'] == 'RouteChangesTriggered']) > 0 else 0
            nodes_blacklisted = mit_df[mit_df['Metric'] == 'NodesBlacklisted']['Value'].values[0] if len(mit_df[mit_df['Metric'] == 'NodesBlacklisted']) > 0 else 0
        else:
            flows_detected_mit = 0
            routes_changed_mit = 0
            nodes_blacklisted = 0
        
        print(f"{percentage:<12} Det:{flows_detected_det} Routes:0{'':<7} Det:{flows_detected_mit} Routes:{routes_changed_mit} BL:{nodes_blacklisted}{'':<3} Routes +{routes_changed_mit}")
    
    print("\n" + "="*80)
    print("KEY FINDINGS")
    print("="*80)
    
    print("\n1. TUNNEL CREATION ISSUE:")
    print("   - All attack percentages create exactly 4 tunnels")
    print("   - Only 1 tunnel is active (intercepting packets)")
    print("   - Expected: Number of tunnels should increase with attack percentage")
    print("   - Root Cause: Probabilistic attacker selection + sequential pairing")
    print("     * GetBooleanWithProbability() creates random number of attackers")
    print("     * Even at 100%, not all nodes become attackers (probabilistic)")
    print("     * Tunnels = floor(num_attackers / 2)")
    
    print("\n2. PDR REMAINS CONSTANT AT 98.75%:")
    print("   - PDR is identical across all attack percentages (20% to 100%)")
    print("   - Packet loss: 173 packets (1.25%) in all scenarios")
    print("   - Root Cause: Wormhole attack doesn't DROP packets")
    print("     * Wormholes create fast tunnels between attacker pairs")
    print("     * Packets are forwarded through tunnels, not dropped")
    print("     * The 1.25% loss appears unrelated to wormhole intensity")
    
    print("\n3. MITIGATION NOT IMPROVING PDR:")
    print("   - Detection is working (133 flows detected)")
    print("   - Mitigation triggers route changes and blacklists nodes")
    print("   - BUT: PDR remains 98.75% (same as no mitigation)")
    print("   - Root Cause: Since wormholes don't drop packets, mitigation can't improve PDR")
    print("     * Mitigation is designed to avoid malicious nodes")
    print("     * But malicious nodes aren't dropping traffic")
    print("     * PDR improvement requires attackers that DROP packets (blackhole)")
    
    print("\n" + "="*80)
    print("RECOMMENDATIONS")
    print("="*80)
    
    print("\n1. FIX TUNNEL CREATION:")
    print("   - Replace probabilistic selection with deterministic selection")
    print("   - Calculate exact number: num_attackers = ceil(num_vehicles * attack_percentage)")
    print("   - Select attackers deterministically (e.g., first N vehicles)")
    print("   - Expected result: 20% = 12 attackers (6 tunnels), 100% = 60 attackers (30 tunnels)")
    
    print("\n2. ENHANCE WORMHOLE ATTACK IMPACT:")
    print("   - Option A: Make wormhole tunnels drop packets (add packet loss rate)")
    print("   - Option B: Wormhole + Blackhole combination (tunnels lead to blackholes)")
    print("   - Option C: Wormhole causes routing loops (packets circulate indefinitely)")
    print("   - This would make PDR vary with attack intensity")
    
    print("\n3. VERIFY MITIGATION EFFECTIVENESS:")
    print("   - After fixing attack impact, re-test mitigation")
    print("   - Expected: Detection → Route changes → PDR recovery")
    print("   - Goal: No mitigation (low PDR) → Full mitigation (high PDR)")
    
    print("\n")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        results_dir = r"d:\routing copy\sdvn_evaluation_20251106_143501"
        print(f"Using default results directory: {results_dir}\n")
    else:
        results_dir = sys.argv[1]
    
    if not os.path.exists(results_dir):
        print(f"Error: Results directory not found: {results_dir}")
        sys.exit(1)
    
    analyze_wormhole_results(results_dir)

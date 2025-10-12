#!/usr/bin/env python3
"""
wormhole_analysis.py
Analyze wormhole attack statistics from CSV output

Usage:
    python3 wormhole_analysis.py wormhole-attack-results.csv
    python3 wormhole_analysis.py wormhole-attack-results.csv --plot
"""

import sys
import csv
import argparse
from collections import defaultdict

def parse_csv(filename):
    """Parse the wormhole statistics CSV file"""
    tunnels = []
    aggregate = None
    
    with open(filename, 'r') as f:
        reader = csv.DictReader(f)
        for row in reader:
            if row['TunnelID'] == 'TOTAL':
                aggregate = row
            else:
                tunnels.append(row)
    
    return tunnels, aggregate

def print_statistics(tunnels, aggregate):
    """Print formatted statistics"""
    print("\n" + "="*70)
    print("  WORMHOLE ATTACK ANALYSIS")
    print("="*70)
    
    print(f"\nTotal Tunnels: {len(tunnels)}")
    
    if aggregate:
        print("\nAGGREGATE STATISTICS:")
        print(f"  Total Packets Intercepted: {aggregate['PacketsIntercepted']}")
        print(f"  Total Packets Tunneled: {aggregate['PacketsTunneled']}")
        print(f"  Total Packets Dropped: {aggregate['PacketsDropped']}")
        print(f"  Routing Packets Affected: {aggregate['RoutingAffected']}")
        print(f"  Data Packets Affected: {aggregate['DataAffected']}")
        print(f"  Average Tunneling Delay: {float(aggregate['AvgDelay']):.9f} seconds")
        
        # Calculate success rate
        total = int(aggregate['PacketsIntercepted'])
        tunneled = int(aggregate['PacketsTunneled'])
        if total > 0:
            success_rate = (tunneled / total) * 100
            print(f"  Tunneling Success Rate: {success_rate:.2f}%")
    
    print("\nPER-TUNNEL STATISTICS:")
    print("-"*70)
    print(f"{'ID':<5} {'Nodes':<12} {'Intercept':<10} {'Tunnel':<10} {'Drop':<8} {'Success%':<10}")
    print("-"*70)
    
    for tunnel in tunnels:
        tunnel_id = tunnel['TunnelID']
        nodes = f"{tunnel['NodeA']}-{tunnel['NodeB']}"
        intercepted = int(tunnel['PacketsIntercepted'])
        tunneled = int(tunnel['PacketsTunneled'])
        dropped = int(tunnel['PacketsDropped'])
        
        if intercepted > 0:
            success = (tunneled / intercepted) * 100
        else:
            success = 0.0
        
        print(f"{tunnel_id:<5} {nodes:<12} {intercepted:<10} {tunneled:<10} {dropped:<8} {success:<10.2f}")
    
    print("="*70)

def analyze_attack_effectiveness(tunnels, aggregate):
    """Analyze the effectiveness of the wormhole attack"""
    print("\n" + "="*70)
    print("  ATTACK EFFECTIVENESS ANALYSIS")
    print("="*70)
    
    if not aggregate:
        print("No aggregate data available")
        return
    
    total_intercepted = int(aggregate['PacketsIntercepted'])
    total_tunneled = int(aggregate['PacketsTunneled'])
    total_dropped = int(aggregate['PacketsDropped'])
    routing_affected = int(aggregate['RoutingAffected'])
    data_affected = int(aggregate['DataAffected'])
    
    print(f"\n1. INTERCEPTION RATE")
    print(f"   Total packets intercepted: {total_intercepted}")
    if total_intercepted > 0:
        print(f"   Routing packets: {routing_affected} ({(routing_affected/total_intercepted)*100:.1f}%)")
        print(f"   Data packets: {data_affected} ({(data_affected/total_intercepted)*100:.1f}%)")
    
    print(f"\n2. TUNNELING EFFECTIVENESS")
    if total_intercepted > 0:
        tunnel_rate = (total_tunneled / total_intercepted) * 100
        drop_rate = (total_dropped / total_intercepted) * 100
        print(f"   Successfully tunneled: {total_tunneled} ({tunnel_rate:.2f}%)")
        print(f"   Dropped: {total_dropped} ({drop_rate:.2f}%)")
    
    print(f"\n3. ATTACK IMPACT")
    if total_intercepted > 0:
        print(f"   Routing protocol impact: {routing_affected} packets")
        print(f"   Data traffic impact: {data_affected} packets")
        
        if routing_affected > 0:
            print(f"   → Likely causing topology disruption")
        if data_affected > 0:
            print(f"   → Likely causing throughput degradation")
    
    print(f"\n4. TUNNEL DISTRIBUTION")
    active_tunnels = sum(1 for t in tunnels if int(t['PacketsIntercepted']) > 0)
    print(f"   Active tunnels: {active_tunnels}/{len(tunnels)}")
    
    if len(tunnels) > 0:
        avg_per_tunnel = total_intercepted / len(tunnels)
        print(f"   Avg packets per tunnel: {avg_per_tunnel:.2f}")
    
    # Find most active tunnel
    if tunnels:
        most_active = max(tunnels, key=lambda t: int(t['PacketsIntercepted']))
        print(f"\n5. MOST ACTIVE TUNNEL")
        print(f"   Tunnel ID: {most_active['TunnelID']}")
        print(f"   Nodes: {most_active['NodeA']} <-> {most_active['NodeB']}")
        print(f"   Packets intercepted: {most_active['PacketsIntercepted']}")
    
    print("="*70)

def plot_statistics(tunnels, aggregate):
    """Generate plots using matplotlib"""
    try:
        import matplotlib.pyplot as plt
        import numpy as np
    except ImportError:
        print("\nMatplotlib not available. Install with: pip install matplotlib")
        return
    
    print("\nGenerating plots...")
    
    # Create figure with subplots
    fig, axes = plt.subplots(2, 2, figsize=(14, 10))
    fig.suptitle('Wormhole Attack Analysis', fontsize=16, fontweight='bold')
    
    # Plot 1: Packets per tunnel
    ax1 = axes[0, 0]
    tunnel_ids = [t['TunnelID'] for t in tunnels]
    intercepted = [int(t['PacketsIntercepted']) for t in tunnels]
    tunneled = [int(t['PacketsTunneled']) for t in tunnels]
    dropped = [int(t['PacketsDropped']) for t in tunnels]
    
    x = np.arange(len(tunnel_ids))
    width = 0.25
    
    ax1.bar(x - width, intercepted, width, label='Intercepted', color='orange')
    ax1.bar(x, tunneled, width, label='Tunneled', color='green')
    ax1.bar(x + width, dropped, width, label='Dropped', color='red')
    
    ax1.set_xlabel('Tunnel ID')
    ax1.set_ylabel('Packet Count')
    ax1.set_title('Packets per Tunnel')
    ax1.set_xticks(x)
    ax1.set_xticklabels(tunnel_ids)
    ax1.legend()
    ax1.grid(True, alpha=0.3)
    
    # Plot 2: Success rate per tunnel
    ax2 = axes[0, 1]
    success_rates = []
    for t in tunnels:
        inter = int(t['PacketsIntercepted'])
        tunn = int(t['PacketsTunneled'])
        if inter > 0:
            success_rates.append((tunn / inter) * 100)
        else:
            success_rates.append(0)
    
    ax2.bar(tunnel_ids, success_rates, color='skyblue')
    ax2.set_xlabel('Tunnel ID')
    ax2.set_ylabel('Success Rate (%)')
    ax2.set_title('Tunneling Success Rate')
    ax2.set_ylim([0, 105])
    ax2.grid(True, alpha=0.3)
    
    # Plot 3: Packet type distribution
    if aggregate:
        ax3 = axes[1, 0]
        routing = int(aggregate['RoutingAffected'])
        data = int(aggregate['DataAffected'])
        
        labels = ['Routing\nPackets', 'Data\nPackets']
        sizes = [routing, data]
        colors = ['#ff9999', '#66b3ff']
        explode = (0.1, 0)
        
        ax3.pie(sizes, explode=explode, labels=labels, colors=colors,
                autopct='%1.1f%%', shadow=True, startangle=90)
        ax3.set_title('Affected Packet Types')
    
    # Plot 4: Tunnel activity heatmap
    ax4 = axes[1, 1]
    node_pairs = [f"{t['NodeA']}-{t['NodeB']}" for t in tunnels]
    activity = [int(t['PacketsIntercepted']) for t in tunnels]
    
    colors_map = plt.cm.YlOrRd(np.linspace(0.3, 0.9, len(tunnels)))
    bars = ax4.barh(node_pairs, activity, color=colors_map)
    ax4.set_xlabel('Packets Intercepted')
    ax4.set_ylabel('Node Pair')
    ax4.set_title('Tunnel Activity')
    ax4.grid(True, alpha=0.3, axis='x')
    
    plt.tight_layout()
    
    # Save figure
    output_file = 'wormhole_analysis.png'
    plt.savefig(output_file, dpi=300, bbox_inches='tight')
    print(f"Plot saved to: {output_file}")
    
    plt.show()

def main():
    parser = argparse.ArgumentParser(description='Analyze wormhole attack statistics')
    parser.add_argument('csvfile', help='CSV file with wormhole statistics')
    parser.add_argument('--plot', action='store_true', help='Generate plots')
    
    args = parser.parse_args()
    
    try:
        tunnels, aggregate = parse_csv(args.csvfile)
    except FileNotFoundError:
        print(f"Error: File '{args.csvfile}' not found")
        sys.exit(1)
    except Exception as e:
        print(f"Error parsing CSV: {e}")
        sys.exit(1)
    
    print_statistics(tunnels, aggregate)
    analyze_attack_effectiveness(tunnels, aggregate)
    
    if args.plot:
        plot_statistics(tunnels, aggregate)

if __name__ == '__main__':
    main()

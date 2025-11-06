#!/usr/bin/env python3
"""
Wormhole Attack Focused Analysis Script
Analyzes wormhole-specific results with emphasis on latency and tunnel metrics
30 nodes (20 vehicles + 10 RSUs), 5 attack percentages
"""

import os
import sys
import csv
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from collections import defaultdict
import pandas as pd
from datetime import datetime

# Set style for publication-quality figures
plt.style.use('seaborn-v0_8-paper')
sns.set_palette("husl")
plt.rcParams['figure.figsize'] = (14, 10)
plt.rcParams['font.size'] = 10
plt.rcParams['axes.labelsize'] = 12
plt.rcParams['axes.titlesize'] = 14
plt.rcParams['legend.fontsize'] = 10

class WormholeFocusedAnalyzer:
    def __init__(self, results_dir):
        self.results_dir = results_dir
        self.output_dir = os.path.join(results_dir, "analysis_output")
        os.makedirs(self.output_dir, exist_ok=True)
        
        self.attack_percentages = [20, 40, 60, 80, 100]
        self.scenarios = ['no_mitigation', 'with_detection', 'with_mitigation']
        
        self.results = defaultdict(lambda: defaultdict(dict))
        self.baseline = None
        
    def load_packet_delivery_data(self, test_dir):
        """Load packet delivery analysis CSV"""
        csv_path = os.path.join(test_dir, "packet-delivery-analysis.csv")
        if not os.path.exists(csv_path):
            return None
        
        try:
            df = pd.read_csv(csv_path)
            total_packets = len(df)
            delivered_packets = len(df[df['Delivered'] == 1])
            pdr = (delivered_packets / total_packets * 100) if total_packets > 0 else 0
            
            # Calculate latency metrics for delivered packets
            delivered_df = df[df['Delivered'] == 1]
            if len(delivered_df) > 0:
                avg_latency = delivered_df['DelayMs'].mean()
                median_latency = delivered_df['DelayMs'].median()
                min_latency = delivered_df['DelayMs'].min()
                max_latency = delivered_df['DelayMs'].max()
                std_latency = delivered_df['DelayMs'].std()
                
                # Calculate latency for wormhole-affected packets
                wormhole_affected = delivered_df[delivered_df['WormholeOnPath'] == 1]
                if len(wormhole_affected) > 0:
                    avg_wormhole_latency = wormhole_affected['DelayMs'].mean()
                    wormhole_packet_count = len(wormhole_affected)
                else:
                    avg_wormhole_latency = 0
                    wormhole_packet_count = 0
                
                # Calculate latency for normal packets
                normal_packets = delivered_df[delivered_df['WormholeOnPath'] == 0]
                if len(normal_packets) > 0:
                    avg_normal_latency = normal_packets['DelayMs'].mean()
                    normal_packet_count = len(normal_packets)
                else:
                    avg_normal_latency = 0
                    normal_packet_count = 0
            else:
                avg_latency = median_latency = min_latency = max_latency = std_latency = 0
                avg_wormhole_latency = avg_normal_latency = 0
                wormhole_packet_count = normal_packet_count = 0
            
            return {
                'total_packets': total_packets,
                'delivered_packets': delivered_packets,
                'dropped_packets': total_packets - delivered_packets,
                'pdr': pdr,
                'avg_latency': avg_latency,
                'median_latency': median_latency,
                'min_latency': min_latency,
                'max_latency': max_latency,
                'std_latency': std_latency,
                'avg_wormhole_latency': avg_wormhole_latency,
                'avg_normal_latency': avg_normal_latency,
                'wormhole_packet_count': wormhole_packet_count,
                'normal_packet_count': normal_packet_count
            }
        except Exception as e:
            print(f"  ⚠ Error loading {csv_path}: {e}")
            return None
    
    def load_wormhole_tunnel_data(self, test_dir):
        """Load wormhole attack results CSV"""
        csv_path = os.path.join(test_dir, "wormhole-attack-results.csv")
        if not os.path.exists(csv_path):
            return None
        
        try:
            df = pd.read_csv(csv_path)
            # Remove TOTAL row
            df = df[df['TunnelID'] != 'TOTAL']
            
            total_tunnels = len(df)
            active_tunnels = len(df[df['PacketsIntercepted'] > 0])
            total_intercepted = df['PacketsIntercepted'].sum()
            total_tunneled = df['PacketsTunneled'].sum()
            
            # Get active tunnel details
            active_df = df[df['PacketsIntercepted'] > 0]
            tunnel_nodes = []
            for _, row in active_df.iterrows():
                tunnel_nodes.append((row['NodeA'], row['NodeB']))
            
            return {
                'total_tunnels': total_tunnels,
                'active_tunnels': active_tunnels,
                'packets_intercepted': total_intercepted,
                'packets_tunneled': total_tunneled,
                'tunnel_nodes': tunnel_nodes
            }
        except Exception as e:
            print(f"  ⚠ Error loading {csv_path}: {e}")
            return None
    
    def load_all_results(self):
        """Load all test results"""
        print("\n" + "="*80)
        print("LOADING WORMHOLE FOCUSED EVALUATION RESULTS")
        print("="*80)
        
        # Load baseline
        print("\nLoading Baseline...")
        baseline_dir = os.path.join(self.results_dir, "test01_baseline")
        self.baseline = self.load_packet_delivery_data(baseline_dir)
        if self.baseline:
            print(f"  ✓ Baseline PDR: {self.baseline['pdr']:.2f}%, "
                  f"Latency: {self.baseline['avg_latency']:.2f}ms")
        
        # Load wormhole attack results
        print("\nLoading Wormhole Attack results...")
        for percentage in self.attack_percentages:
            for scenario in self.scenarios:
                if scenario == 'no_mitigation':
                    test_prefix = 'test02'
                elif scenario == 'with_detection':
                    test_prefix = 'test03'
                else:  # with_mitigation
                    test_prefix = 'test04'
                
                test_dir = os.path.join(self.results_dir, 
                                       f"{test_prefix}_wormhole_{percentage}_{scenario}")
                
                pdr_data = self.load_packet_delivery_data(test_dir)
                tunnel_data = self.load_wormhole_tunnel_data(test_dir)
                
                if pdr_data:
                    self.results[percentage][scenario] = {
                        'pdr_data': pdr_data,
                        'tunnel_data': tunnel_data
                    }
                    tunnels_info = f", Tunnels: {tunnel_data['total_tunnels']}" if tunnel_data else ""
                    print(f"  ✓ {percentage}% {scenario}: PDR={pdr_data['pdr']:.2f}%, "
                          f"Latency={pdr_data['avg_latency']:.2f}ms{tunnels_info}")
    
    def generate_pdr_and_latency_curves(self):
        """Generate combined PDR and Latency curves"""
        print("\n" + "="*80)
        print("GENERATING PDR AND LATENCY CURVES")
        print("="*80)
        
        fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(16, 6))
        
        # PDR curves
        for scenario in self.scenarios:
            percentages = []
            pdrs = []
            
            for percentage in self.attack_percentages:
                if percentage in self.results and scenario in self.results[percentage]:
                    percentages.append(percentage)
                    pdrs.append(self.results[percentage][scenario]['pdr_data']['pdr'])
            
            if percentages:
                label = scenario.replace('_', ' ').title()
                marker = 'x' if scenario == 'no_mitigation' else ('o' if scenario == 'with_detection' else '^')
                linestyle = '--' if scenario == 'no_mitigation' else (':' if scenario == 'with_detection' else '-')
                
                ax1.plot(percentages, pdrs, marker=marker, linestyle=linestyle, 
                        linewidth=2, markersize=10, label=label)
        
        if self.baseline:
            ax1.axhline(y=self.baseline['pdr'], color='green', linestyle='-.', 
                       linewidth=1.5, alpha=0.5, label='Baseline')
        
        ax1.set_xlabel('Attack Percentage (%)', fontsize=12)
        ax1.set_ylabel('Packet Delivery Ratio (%)', fontsize=12)
        ax1.set_title('PDR vs Attack Intensity (30 nodes)', fontsize=14, weight='bold')
        ax1.legend(loc='best')
        ax1.grid(True, alpha=0.3)
        ax1.set_xlim(15, 105)
        ax1.set_ylim(0, 105)
        
        # Latency curves
        for scenario in self.scenarios:
            percentages = []
            latencies = []
            
            for percentage in self.attack_percentages:
                if percentage in self.results and scenario in self.results[percentage]:
                    percentages.append(percentage)
                    latencies.append(self.results[percentage][scenario]['pdr_data']['avg_latency'])
            
            if percentages:
                label = scenario.replace('_', ' ').title()
                marker = 'x' if scenario == 'no_mitigation' else ('o' if scenario == 'with_detection' else '^')
                linestyle = '--' if scenario == 'no_mitigation' else (':' if scenario == 'with_detection' else '-')
                
                ax2.plot(percentages, latencies, marker=marker, linestyle=linestyle, 
                        linewidth=2, markersize=10, label=label)
        
        if self.baseline:
            ax2.axhline(y=self.baseline['avg_latency'], color='green', linestyle='-.', 
                       linewidth=1.5, alpha=0.5, label='Baseline')
        
        ax2.set_xlabel('Attack Percentage (%)', fontsize=12)
        ax2.set_ylabel('Average Latency (ms)', fontsize=12)
        ax2.set_title('Latency vs Attack Intensity (30 nodes)', fontsize=14, weight='bold')
        ax2.legend(loc='best')
        ax2.grid(True, alpha=0.3)
        ax2.set_xlim(15, 105)
        
        plt.tight_layout()
        output_path = os.path.join(self.output_dir, 'pdr_latency_vs_attack_percentage.png')
        plt.savefig(output_path, dpi=300, bbox_inches='tight')
        print(f"✓ Saved: {output_path}")
        plt.close()
    
    def generate_tunnel_analysis(self):
        """Generate tunnel creation and activity analysis"""
        print("\n" + "="*80)
        print("GENERATING TUNNEL ANALYSIS")
        print("="*80)
        
        fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(16, 6))
        
        # Tunnel count analysis
        percentages = []
        total_tunnels_list = []
        active_tunnels_list = []
        expected_tunnels_list = []
        
        for percentage in self.attack_percentages:
            if percentage in self.results and 'no_mitigation' in self.results[percentage]:
                tunnel_data = self.results[percentage]['no_mitigation']['tunnel_data']
                if tunnel_data:
                    percentages.append(percentage)
                    total_tunnels_list.append(tunnel_data['total_tunnels'])
                    active_tunnels_list.append(tunnel_data['active_tunnels'])
                    # Expected: 20 vehicles * percentage / 2
                    expected = int((20 * (percentage / 100)) / 2)
                    expected_tunnels_list.append(expected)
        
        x = np.arange(len(percentages))
        width = 0.25
        
        ax1.bar(x - width, total_tunnels_list, width, label='Total Tunnels Created', color='steelblue')
        ax1.bar(x, active_tunnels_list, width, label='Active Tunnels', color='orange')
        ax1.bar(x + width, expected_tunnels_list, width, label='Expected Tunnels', color='green', alpha=0.6)
        
        ax1.set_xlabel('Attack Percentage (%)', fontsize=12)
        ax1.set_ylabel('Number of Tunnels', fontsize=12)
        ax1.set_title('Wormhole Tunnel Creation Analysis', fontsize=14, weight='bold')
        ax1.set_xticks(x)
        ax1.set_xticklabels([f'{p}%' for p in percentages])
        ax1.legend()
        ax1.grid(True, axis='y', alpha=0.3)
        
        # Packets intercepted analysis
        percentages2 = []
        intercepted_list = []
        
        for percentage in self.attack_percentages:
            if percentage in self.results and 'no_mitigation' in self.results[percentage]:
                tunnel_data = self.results[percentage]['no_mitigation']['tunnel_data']
                if tunnel_data:
                    percentages2.append(percentage)
                    intercepted_list.append(tunnel_data['packets_intercepted'])
        
        ax2.plot(percentages2, intercepted_list, marker='o', linestyle='-', 
                linewidth=2, markersize=10, color='red')
        ax2.set_xlabel('Attack Percentage (%)', fontsize=12)
        ax2.set_ylabel('Packets Intercepted', fontsize=12)
        ax2.set_title('Wormhole Traffic Interception', fontsize=14, weight='bold')
        ax2.grid(True, alpha=0.3)
        ax2.set_xlim(15, 105)
        
        plt.tight_layout()
        output_path = os.path.join(self.output_dir, 'tunnel_analysis.png')
        plt.savefig(output_path, dpi=300, bbox_inches='tight')
        print(f"✓ Saved: {output_path}")
        plt.close()
    
    def generate_latency_breakdown(self):
        """Generate latency breakdown: wormhole vs normal packets"""
        print("\n" + "="*80)
        print("GENERATING LATENCY BREAKDOWN ANALYSIS")
        print("="*80)
        
        fig, ax = plt.subplots(figsize=(12, 8))
        
        x_labels = []
        normal_latencies = []
        wormhole_latencies = []
        
        for percentage in self.attack_percentages:
            if percentage in self.results and 'no_mitigation' in self.results[percentage]:
                pdr_data = self.results[percentage]['no_mitigation']['pdr_data']
                x_labels.append(f'{percentage}%')
                normal_latencies.append(pdr_data['avg_normal_latency'])
                wormhole_latencies.append(pdr_data['avg_wormhole_latency'])
        
        x = np.arange(len(x_labels))
        width = 0.35
        
        ax.bar(x - width/2, normal_latencies, width, label='Normal Packets', color='#4ecdc4')
        ax.bar(x + width/2, wormhole_latencies, width, label='Wormhole-Affected Packets', color='#ff6b6b')
        
        ax.set_xlabel('Attack Percentage', fontsize=12)
        ax.set_ylabel('Average Latency (ms)', fontsize=12)
        ax.set_title('Latency Breakdown: Normal vs Wormhole-Affected Packets', 
                     fontsize=14, weight='bold')
        ax.set_xticks(x)
        ax.set_xticklabels(x_labels)
        ax.legend()
        ax.grid(True, axis='y', alpha=0.3)
        
        plt.tight_layout()
        output_path = os.path.join(self.output_dir, 'latency_breakdown.png')
        plt.savefig(output_path, dpi=300, bbox_inches='tight')
        print(f"✓ Saved: {output_path}")
        plt.close()
    
    def generate_statistical_summary(self):
        """Generate detailed statistical summary"""
        print("\n" + "="*80)
        print("GENERATING STATISTICAL SUMMARY")
        print("="*80)
        
        summary_file = os.path.join(self.output_dir, 'wormhole_analysis_summary.txt')
        
        with open(summary_file, 'w') as f:
            f.write("="*80 + "\n")
            f.write("WORMHOLE ATTACK FOCUSED ANALYSIS - STATISTICAL SUMMARY\n")
            f.write("="*80 + "\n")
            f.write(f"\nGenerated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
            f.write(f"Results Directory: {self.results_dir}\n")
            f.write(f"Network: 30 nodes (20 vehicles + 10 RSUs)\n\n")
            
            # Baseline
            f.write("-"*80 + "\n")
            f.write("BASELINE PERFORMANCE\n")
            f.write("-"*80 + "\n")
            if self.baseline:
                f.write(f"PDR: {self.baseline['pdr']:.2f}%\n")
                f.write(f"Avg Latency: {self.baseline['avg_latency']:.2f} ms\n")
                f.write(f"Median Latency: {self.baseline['median_latency']:.2f} ms\n")
                f.write(f"Std Dev Latency: {self.baseline['std_latency']:.2f} ms\n")
                f.write(f"Total Packets: {self.baseline['total_packets']}\n")
                f.write(f"Delivered: {self.baseline['delivered_packets']}\n\n")
            
            # Wormhole attack analysis
            f.write("-"*80 + "\n")
            f.write("WORMHOLE ATTACK ANALYSIS\n")
            f.write("-"*80 + "\n\n")
            
            f.write(f"{'Attack%':<10} {'Scenario':<20} {'PDR%':<10} {'AvgLat(ms)':<12} "
                   f"{'Tunnels':<10} {'Active':<10} {'Intercepted':<12}\n")
            f.write("-"*80 + "\n")
            
            for percentage in self.attack_percentages:
                if percentage not in self.results:
                    continue
                
                for scenario in self.scenarios:
                    if scenario not in self.results[percentage]:
                        continue
                    
                    pdr_data = self.results[percentage][scenario]['pdr_data']
                    tunnel_data = self.results[percentage][scenario]['tunnel_data']
                    
                    pdr = pdr_data['pdr']
                    latency = pdr_data['avg_latency']
                    tunnels = tunnel_data['total_tunnels'] if tunnel_data else 0
                    active = tunnel_data['active_tunnels'] if tunnel_data else 0
                    intercepted = tunnel_data['packets_intercepted'] if tunnel_data else 0
                    
                    scenario_short = scenario.replace('_', ' ')[:18]
                    f.write(f"{percentage}%{'':<8} {scenario_short:<20} {pdr:>6.2f}%{'':<3} "
                           f"{latency:>8.2f}{'':<3} {tunnels:>8} {active:>10} {intercepted:>12}\n")
                
                f.write("\n")
            
            # Mitigation effectiveness
            f.write("="*80 + "\n")
            f.write("MITIGATION EFFECTIVENESS\n")
            f.write("="*80 + "\n\n")
            
            f.write(f"{'Attack%':<12} {'No Miti PDR':<15} {'Full Miti PDR':<15} "
                   f"{'PDR Gain':<12} {'Latency Reduction':<20}\n")
            f.write("-"*80 + "\n")
            
            for percentage in self.attack_percentages:
                if (percentage in self.results and 
                    'no_mitigation' in self.results[percentage] and
                    'with_mitigation' in self.results[percentage]):
                    
                    no_miti = self.results[percentage]['no_mitigation']['pdr_data']
                    with_miti = self.results[percentage]['with_mitigation']['pdr_data']
                    
                    pdr_gain = with_miti['pdr'] - no_miti['pdr']
                    lat_reduction = no_miti['avg_latency'] - with_miti['avg_latency']
                    
                    f.write(f"{percentage}%{'':<10} {no_miti['pdr']:>6.2f}%{'':<8} "
                           f"{with_miti['pdr']:>6.2f}%{'':<8} {pdr_gain:>+6.2f}%{'':<5} "
                           f"{lat_reduction:>+8.2f} ms\n")
            
            f.write("\n")
        
        print(f"✓ Saved: {summary_file}")
    
    def run_complete_analysis(self):
        """Run all analysis steps"""
        print("\n" + "="*80)
        print("WORMHOLE FOCUSED ANALYSIS")
        print("="*80)
        print(f"\nResults Directory: {self.results_dir}")
        print(f"Output Directory: {self.output_dir}")
        
        # Load all data
        self.load_all_results()
        
        # Generate visualizations
        print("\n" + "="*80)
        print("GENERATING VISUALIZATIONS")
        print("="*80)
        
        self.generate_pdr_and_latency_curves()
        self.generate_tunnel_analysis()
        self.generate_latency_breakdown()
        
        # Generate reports
        print("\n" + "="*80)
        print("GENERATING REPORTS")
        print("="*80)
        
        self.generate_statistical_summary()
        
        # Final summary
        print("\n" + "="*80)
        print("ANALYSIS COMPLETE")
        print("="*80)
        print(f"\nAll outputs saved to: {self.output_dir}")
        print("\nGenerated files:")
        print("  1. pdr_latency_vs_attack_percentage.png - PDR and Latency curves")
        print("  2. tunnel_analysis.png - Tunnel creation and interception")
        print("  3. latency_breakdown.png - Normal vs Wormhole-affected latency")
        print("  4. wormhole_analysis_summary.txt - Detailed statistics")
        print("\nReady for publication! 📊")

def main():
    if len(sys.argv) < 2:
        print("Usage: python3 analyze_wormhole_focused.py <results_directory>")
        print("\nExample:")
        print("  python3 analyze_wormhole_focused.py ./wormhole_evaluation_20251106_123456")
        sys.exit(1)
    
    results_dir = sys.argv[1]
    
    if not os.path.exists(results_dir):
        print(f"❌ Error: Results directory not found: {results_dir}")
        sys.exit(1)
    
    # Run analysis
    analyzer = WormholeFocusedAnalyzer(results_dir)
    analyzer.run_complete_analysis()

if __name__ == "__main__":
    main()

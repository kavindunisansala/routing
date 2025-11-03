#!/usr/bin/env python3
"""
SDVN Mitigation Effectiveness Analyzer
Compares attack impact WITH and WITHOUT mitigation solutions
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
import os
import sys
from pathlib import Path

class MitigationAnalyzer:
    def __init__(self, results_dir):
        self.results_dir = results_dir
        self.test_pairs = [
            # (without_mitigation, with_mitigation, attack_name, percentage)
            ('test02_wormhole_10_no_mitigation', 'test03_wormhole_10_with_mitigation', 'Wormhole', '10%'),
            ('test04_wormhole_20_no_mitigation', 'test05_wormhole_20_with_mitigation', 'Wormhole', '20%'),
            ('test06_blackhole_10_no_mitigation', 'test07_blackhole_10_with_mitigation', 'Blackhole', '10%'),
            ('test08_blackhole_20_no_mitigation', 'test09_blackhole_20_with_mitigation', 'Blackhole', '20%'),
            ('test10_sybil_10_no_mitigation', 'test11_sybil_10_with_mitigation', 'Sybil', '10%'),
            ('test12_combined_10_no_mitigation', 'test13_combined_10_with_mitigation', 'Combined', '10%'),
        ]
        self.baseline_dir = 'test01_baseline'
        self.results = []
        
    def load_packet_data(self, test_dir):
        """Load packet-delivery-analysis.csv from a test directory"""
        csv_path = os.path.join(self.results_dir, test_dir, 'packet-delivery-analysis.csv')
        if os.path.exists(csv_path):
            try:
                df = pd.read_csv(csv_path)
                return df
            except Exception as e:
                print(f"  ⚠ Error loading {test_dir}: {e}")
                return None
        else:
            print(f"  ⚠ File not found: {csv_path}")
            return None
    
    def calculate_metrics(self, df):
        """Calculate performance metrics from packet data"""
        if df is None or df.empty:
            return None
        
        total_packets = len(df)
        delivered_packets = df['Delivered'].sum() if 'Delivered' in df.columns else 0
        
        metrics = {
            'total_packets': total_packets,
            'delivered_packets': delivered_packets,
            'dropped_packets': total_packets - delivered_packets,
            'pdr': (delivered_packets / total_packets) if total_packets > 0 else 0,
            'packet_loss_rate': 1 - (delivered_packets / total_packets) if total_packets > 0 else 0,
        }
        
        # Calculate delay for delivered packets only
        if 'DelayMs' in df.columns and 'Delivered' in df.columns:
            delivered_df = df[df['Delivered'] == 1]
            if len(delivered_df) > 0:
                metrics['avg_delay_ms'] = delivered_df['DelayMs'].mean()
                metrics['max_delay_ms'] = delivered_df['DelayMs'].max()
                metrics['min_delay_ms'] = delivered_df['DelayMs'].min()
            else:
                metrics['avg_delay_ms'] = 0
                metrics['max_delay_ms'] = 0
                metrics['min_delay_ms'] = 0
        
        # Calculate throughput (approximate)
        if 'ReceiveTime' in df.columns and 'SendTime' in df.columns:
            sim_duration = df['ReceiveTime'].max() - df['SendTime'].min()
            if sim_duration > 0:
                packet_size_bytes = 512
                total_bytes = delivered_packets * packet_size_bytes
                metrics['throughput_mbps'] = (total_bytes * 8) / (sim_duration * 1_000_000)
            else:
                metrics['throughput_mbps'] = 0
        
        return metrics
    
    def analyze_mitigation_effectiveness(self):
        """Analyze effectiveness of mitigation for each attack"""
        print("\n" + "="*80)
        print("SDVN MITIGATION EFFECTIVENESS ANALYSIS")
        print("="*80)
        
        # Load baseline
        print("\nLoading baseline (no attacks)...")
        baseline_df = self.load_packet_data(self.baseline_dir)
        baseline_metrics = self.calculate_metrics(baseline_df)
        
        if baseline_metrics:
            print(f"  ✓ Baseline PDR: {baseline_metrics['pdr']:.4f} ({baseline_metrics['delivered_packets']}/{baseline_metrics['total_packets']})")
            print(f"  ✓ Baseline Delay: {baseline_metrics['avg_delay_ms']:.2f} ms")
        
        # Analyze each test pair
        print("\n" + "-"*80)
        print("Comparing Attack Impact: WITH vs WITHOUT Mitigation")
        print("-"*80)
        
        for without_dir, with_dir, attack_name, percentage in self.test_pairs:
            print(f"\n{attack_name} Attack ({percentage}):")
            
            # Load data
            df_without = self.load_packet_data(without_dir)
            df_with = self.load_packet_data(with_dir)
            
            if df_without is None or df_with is None:
                print("  ✗ Data not available")
                continue
            
            # Calculate metrics
            metrics_without = self.calculate_metrics(df_without)
            metrics_with = self.calculate_metrics(df_with)
            
            if not metrics_without or not metrics_with:
                print("  ✗ Could not calculate metrics")
                continue
            
            # Calculate improvements
            pdr_improvement = (metrics_with['pdr'] - metrics_without['pdr']) * 100
            delay_reduction = metrics_without['avg_delay_ms'] - metrics_with['avg_delay_ms']
            loss_reduction = (metrics_without['packet_loss_rate'] - metrics_with['packet_loss_rate']) * 100
            
            # Store results
            result = {
                'Attack': f"{attack_name} {percentage}",
                'PDR_Without': metrics_without['pdr'],
                'PDR_With': metrics_with['pdr'],
                'PDR_Improvement': pdr_improvement,
                'Delay_Without': metrics_without['avg_delay_ms'],
                'Delay_With': metrics_with['avg_delay_ms'],
                'Delay_Reduction': delay_reduction,
                'Loss_Rate_Without': metrics_without['packet_loss_rate'],
                'Loss_Rate_With': metrics_with['packet_loss_rate'],
                'Loss_Reduction': loss_reduction,
                'Packets_Without': metrics_without['delivered_packets'],
                'Packets_With': metrics_with['delivered_packets'],
            }
            self.results.append(result)
            
            # Print comparison
            print(f"  WITHOUT Mitigation:")
            print(f"    PDR: {metrics_without['pdr']:.4f} ({metrics_without['delivered_packets']}/{metrics_without['total_packets']})")
            print(f"    Delay: {metrics_without['avg_delay_ms']:.2f} ms")
            print(f"    Packet Loss: {metrics_without['packet_loss_rate']:.4f}")
            
            print(f"  WITH Mitigation:")
            print(f"    PDR: {metrics_with['pdr']:.4f} ({metrics_with['delivered_packets']}/{metrics_with['total_packets']})")
            print(f"    Delay: {metrics_with['avg_delay_ms']:.2f} ms")
            print(f"    Packet Loss: {metrics_with['packet_loss_rate']:.4f}")
            
            print(f"  IMPROVEMENT:")
            print(f"    PDR: +{pdr_improvement:.2f}% {'✓' if pdr_improvement > 0 else '✗'}")
            print(f"    Delay: -{delay_reduction:.2f} ms {'✓' if delay_reduction > 0 else '✗'}")
            print(f"    Loss Rate: -{loss_reduction:.2f}% {'✓' if loss_reduction > 0 else '✗'}")
        
        return pd.DataFrame(self.results)
    
    def generate_comparison_table(self, df):
        """Generate comparison table"""
        if df.empty:
            return
        
        output_file = os.path.join(self.results_dir, 'mitigation_effectiveness_summary.csv')
        df.to_csv(output_file, index=False)
        print(f"\n✓ Comparison table saved to: {output_file}")
        
        # Print formatted table
        print("\n" + "="*80)
        print("MITIGATION EFFECTIVENESS SUMMARY")
        print("="*80)
        print(df.to_string(index=False))
    
    def generate_visualizations(self, df):
        """Generate comparison visualizations"""
        if df.empty:
            return
        
        print("\nGenerating visualizations...")
        
        # Set style
        sns.set_style("whitegrid")
        fig, axes = plt.subplots(2, 2, figsize=(16, 12))
        fig.suptitle('SDVN Mitigation Effectiveness Analysis', fontsize=16, fontweight='bold')
        
        attacks = df['Attack'].tolist()
        x = np.arange(len(attacks))
        width = 0.35
        
        # Plot 1: PDR Comparison
        ax1 = axes[0, 0]
        ax1.bar(x - width/2, df['PDR_Without'], width, label='Without Mitigation', color='salmon', alpha=0.8)
        ax1.bar(x + width/2, df['PDR_With'], width, label='With Mitigation', color='lightgreen', alpha=0.8)
        ax1.set_xlabel('Attack Scenario')
        ax1.set_ylabel('Packet Delivery Ratio (PDR)')
        ax1.set_title('PDR: With vs Without Mitigation')
        ax1.set_xticks(x)
        ax1.set_xticklabels(attacks, rotation=45, ha='right', fontsize=9)
        ax1.legend()
        ax1.grid(axis='y', alpha=0.3)
        ax1.set_ylim(0, 1.0)
        
        # Plot 2: Delay Comparison
        ax2 = axes[0, 1]
        ax2.bar(x - width/2, df['Delay_Without'], width, label='Without Mitigation', color='coral', alpha=0.8)
        ax2.bar(x + width/2, df['Delay_With'], width, label='With Mitigation', color='lightblue', alpha=0.8)
        ax2.set_xlabel('Attack Scenario')
        ax2.set_ylabel('Average Delay (ms)')
        ax2.set_title('Delay: With vs Without Mitigation')
        ax2.set_xticks(x)
        ax2.set_xticklabels(attacks, rotation=45, ha='right', fontsize=9)
        ax2.legend()
        ax2.grid(axis='y', alpha=0.3)
        
        # Plot 3: PDR Improvement
        ax3 = axes[1, 0]
        colors = ['green' if val > 0 else 'red' for val in df['PDR_Improvement']]
        ax3.bar(x, df['PDR_Improvement'], color=colors, alpha=0.7)
        ax3.set_xlabel('Attack Scenario')
        ax3.set_ylabel('PDR Improvement (%)')
        ax3.set_title('PDR Improvement with Mitigation')
        ax3.set_xticks(x)
        ax3.set_xticklabels(attacks, rotation=45, ha='right', fontsize=9)
        ax3.axhline(y=0, color='black', linestyle='--', linewidth=0.5)
        ax3.grid(axis='y', alpha=0.3)
        
        # Plot 4: Packet Loss Reduction
        ax4 = axes[1, 1]
        colors = ['green' if val > 0 else 'red' for val in df['Loss_Reduction']]
        ax4.bar(x, df['Loss_Reduction'], color=colors, alpha=0.7)
        ax4.set_xlabel('Attack Scenario')
        ax4.set_ylabel('Packet Loss Reduction (%)')
        ax4.set_title('Packet Loss Reduction with Mitigation')
        ax4.set_xticks(x)
        ax4.set_xticklabels(attacks, rotation=45, ha='right', fontsize=9)
        ax4.axhline(y=0, color='black', linestyle='--', linewidth=0.5)
        ax4.grid(axis='y', alpha=0.3)
        
        plt.tight_layout()
        
        output_file = os.path.join(self.results_dir, 'mitigation_effectiveness_comparison.png')
        plt.savefig(output_file, dpi=300, bbox_inches='tight')
        print(f"  ✓ Visualization saved to: {output_file}")
        plt.close()
    
    def generate_latex_table(self, df):
        """Generate LaTeX table for publication"""
        if df.empty:
            return
        
        output_file = os.path.join(self.results_dir, 'mitigation_effectiveness_latex.tex')
        
        with open(output_file, 'w') as f:
            f.write("\\begin{table}[htbp]\n")
            f.write("\\centering\n")
            f.write("\\caption{SDVN Mitigation Effectiveness: Performance Comparison}\n")
            f.write("\\label{tab:mitigation_effectiveness}\n")
            f.write("\\begin{tabular}{|l|c|c|c|c|c|c|}\n")
            f.write("\\hline\n")
            f.write("\\textbf{Attack} & \\multicolumn{2}{c|}{\\textbf{PDR}} & \\multicolumn{2}{c|}{\\textbf{Delay (ms)}} & \\multicolumn{2}{c|}{\\textbf{Improvement}} \\\\\n")
            f.write("\\cline{2-7}\n")
            f.write(" & No Mit. & With Mit. & No Mit. & With Mit. & PDR (\\%) & Loss (\\%) \\\\\n")
            f.write("\\hline\n")
            
            for _, row in df.iterrows():
                f.write(f"{row['Attack']} & {row['PDR_Without']:.3f} & {row['PDR_With']:.3f} & ")
                f.write(f"{row['Delay_Without']:.2f} & {row['Delay_With']:.2f} & ")
                f.write(f"+{row['PDR_Improvement']:.2f} & -{row['Loss_Reduction']:.2f} \\\\\n")
            
            f.write("\\hline\n")
            f.write("\\end{tabular}\n")
            f.write("\\end{table}\n")
        
        print(f"  ✓ LaTeX table saved to: {output_file}")
    
    def generate_report(self):
        """Generate comprehensive analysis report"""
        df = self.analyze_mitigation_effectiveness()
        
        if not df.empty:
            self.generate_comparison_table(df)
            self.generate_visualizations(df)
            self.generate_latex_table(df)
            
            print("\n" + "="*80)
            print("ANALYSIS COMPLETE")
            print("="*80)
            print(f"\nAll results saved to: {self.results_dir}/")
            print("\nGenerated files:")
            print("  - mitigation_effectiveness_summary.csv")
            print("  - mitigation_effectiveness_comparison.png")
            print("  - mitigation_effectiveness_latex.tex")
            print("\n" + "="*80)

def main():
    if len(sys.argv) < 2:
        print("="*80)
        print("SDVN Mitigation Effectiveness Analyzer")
        print("="*80)
        print("\nUsage:")
        print("  python3 analyze_mitigation_comparison.py <results_directory>")
        print("\nExample:")
        print("  python3 analyze_mitigation_comparison.py sdvn_mitigation_comparison_20251103_120000")
        print("\nThis tool compares attack impact WITH and WITHOUT mitigation solutions.")
        print("="*80)
        sys.exit(1)
    
    results_dir = sys.argv[1]
    
    if not os.path.exists(results_dir):
        print(f"Error: Directory '{results_dir}' not found")
        sys.exit(1)
    
    analyzer = MitigationAnalyzer(results_dir)
    analyzer.generate_report()

if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""
SDVN Attack Analysis Tool
Analyzes performance metrics from attack scenarios
Generates comparative analysis and visualizations
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
import os
import sys
from pathlib import Path

class AttackAnalyzer:
    def __init__(self, results_dir):
        self.results_dir = results_dir
        self.metrics = {}
        self.scenarios = [
            ('baseline', 'Baseline (No Attack)'),
            ('wormhole_10', 'Wormhole 10%'),
            ('wormhole_20', 'Wormhole 20%'),
            ('blackhole_10', 'Blackhole 10%'),
            ('blackhole_20', 'Blackhole 20%'),
            ('sybil_10', 'Sybil 10%'),
            ('combined_10', 'Combined 10%'),
            ('combined_30', 'Combined 30%')
        ]
        
    def load_metrics(self):
        """Load all CSV metric files"""
        print("Loading metric files...")
        for i, (scenario_id, scenario_name) in enumerate(self.scenarios, 1):
            csv_file = os.path.join(self.results_dir, f'test{i}_{scenario_id}_metrics.csv')
            if os.path.exists(csv_file):
                try:
                    df = pd.read_csv(csv_file)
                    self.metrics[scenario_name] = df
                    print(f"  ✓ Loaded: {scenario_name}")
                except Exception as e:
                    print(f"  ✗ Error loading {scenario_name}: {e}")
            else:
                print(f"  ⚠ File not found: {csv_file}")
    
    def calculate_summary_statistics(self):
        """Calculate summary statistics for all scenarios"""
        print("\nCalculating summary statistics...")
        
        summary_data = []
        
        for scenario_name, df in self.metrics.items():
            if df.empty:
                continue
                
            summary = {
                'Scenario': scenario_name,
                'Avg_PDR': df['PDR'].mean() if 'PDR' in df.columns else 0,
                'Avg_Delay_ms': df['Delay'].mean() * 1000 if 'Delay' in df.columns else 0,
                'Avg_Throughput_Mbps': df['Throughput'].mean() if 'Throughput' in df.columns else 0,
                'Packet_Loss_Rate': df['PacketLoss'].mean() if 'PacketLoss' in df.columns else 0,
                'Routing_Overhead': df['RoutingOverhead'].mean() if 'RoutingOverhead' in df.columns else 0,
                'Detection_Rate': df['DetectionRate'].mean() if 'DetectionRate' in df.columns else 0,
                'False_Positive_Rate': df['FalsePositiveRate'].mean() if 'FalsePositiveRate' in df.columns else 0,
                'Energy_Consumption_J': df['EnergyConsumption'].mean() if 'EnergyConsumption' in df.columns else 0
            }
            summary_data.append(summary)
        
        summary_df = pd.DataFrame(summary_data)
        
        # Save summary
        summary_file = os.path.join(self.results_dir, 'summary_statistics.csv')
        summary_df.to_csv(summary_file, index=False)
        print(f"  ✓ Summary saved to: {summary_file}")
        
        return summary_df
    
    def generate_comparison_table(self, summary_df):
        """Generate detailed comparison table"""
        print("\nGenerating comparison table...")
        
        if summary_df.empty:
            print("  ⚠ No data available for comparison")
            return
        
        # Calculate percentage degradation compared to baseline
        baseline_idx = summary_df[summary_df['Scenario'].str.contains('Baseline')].index
        if len(baseline_idx) > 0:
            baseline = summary_df.iloc[baseline_idx[0]]
            
            comparison_data = []
            for idx, row in summary_df.iterrows():
                if 'Baseline' in row['Scenario']:
                    continue
                    
                comparison = {
                    'Scenario': row['Scenario'],
                    'PDR_Degradation_%': ((row['Avg_PDR'] - baseline['Avg_PDR']) / baseline['Avg_PDR'] * 100) if baseline['Avg_PDR'] > 0 else 0,
                    'Delay_Increase_%': ((row['Avg_Delay_ms'] - baseline['Avg_Delay_ms']) / baseline['Avg_Delay_ms'] * 100) if baseline['Avg_Delay_ms'] > 0 else 0,
                    'Throughput_Degradation_%': ((row['Avg_Throughput_Mbps'] - baseline['Avg_Throughput_Mbps']) / baseline['Avg_Throughput_Mbps'] * 100) if baseline['Avg_Throughput_Mbps'] > 0 else 0,
                    'Attack_Severity': self._classify_severity(row, baseline)
                }
                comparison_data.append(comparison)
            
            comparison_df = pd.DataFrame(comparison_data)
            comparison_file = os.path.join(self.results_dir, 'attack_impact_comparison.csv')
            comparison_df.to_csv(comparison_file, index=False)
            print(f"  ✓ Comparison saved to: {comparison_file}")
            
            return comparison_df
    
    def _classify_severity(self, attack_row, baseline_row):
        """Classify attack severity based on impact"""
        pdr_drop = (baseline_row['Avg_PDR'] - attack_row['Avg_PDR']) / baseline_row['Avg_PDR'] if baseline_row['Avg_PDR'] > 0 else 0
        delay_increase = (attack_row['Avg_Delay_ms'] - baseline_row['Avg_Delay_ms']) / baseline_row['Avg_Delay_ms'] if baseline_row['Avg_Delay_ms'] > 0 else 0
        
        severity_score = pdr_drop + delay_increase
        
        if severity_score > 1.0:
            return "Critical"
        elif severity_score > 0.5:
            return "High"
        elif severity_score > 0.2:
            return "Medium"
        else:
            return "Low"
    
    def generate_visualizations(self, summary_df):
        """Generate visualization plots"""
        print("\nGenerating visualizations...")
        
        if summary_df.empty:
            print("  ⚠ No data available for visualization")
            return
        
        # Set style
        sns.set_style("whitegrid")
        plt.rcParams['figure.figsize'] = (15, 10)
        
        # Create figure with subplots
        fig, axes = plt.subplots(2, 3, figsize=(18, 12))
        fig.suptitle('SDVN Attack Performance Analysis', fontsize=16, fontweight='bold')
        
        scenarios = summary_df['Scenario'].tolist()
        
        # Plot 1: PDR Comparison
        ax1 = axes[0, 0]
        ax1.bar(range(len(scenarios)), summary_df['Avg_PDR'], color='steelblue')
        ax1.set_xlabel('Scenario')
        ax1.set_ylabel('Packet Delivery Ratio')
        ax1.set_title('PDR Comparison')
        ax1.set_xticks(range(len(scenarios)))
        ax1.set_xticklabels([s.replace(' ', '\n') for s in scenarios], rotation=45, ha='right', fontsize=8)
        ax1.grid(axis='y', alpha=0.3)
        
        # Plot 2: Delay Comparison
        ax2 = axes[0, 1]
        ax2.bar(range(len(scenarios)), summary_df['Avg_Delay_ms'], color='coral')
        ax2.set_xlabel('Scenario')
        ax2.set_ylabel('Average Delay (ms)')
        ax2.set_title('End-to-End Delay Comparison')
        ax2.set_xticks(range(len(scenarios)))
        ax2.set_xticklabels([s.replace(' ', '\n') for s in scenarios], rotation=45, ha='right', fontsize=8)
        ax2.grid(axis='y', alpha=0.3)
        
        # Plot 3: Throughput Comparison
        ax3 = axes[0, 2]
        ax3.bar(range(len(scenarios)), summary_df['Avg_Throughput_Mbps'], color='lightgreen')
        ax3.set_xlabel('Scenario')
        ax3.set_ylabel('Throughput (Mbps)')
        ax3.set_title('Network Throughput Comparison')
        ax3.set_xticks(range(len(scenarios)))
        ax3.set_xticklabels([s.replace(' ', '\n') for s in scenarios], rotation=45, ha='right', fontsize=8)
        ax3.grid(axis='y', alpha=0.3)
        
        # Plot 4: Packet Loss Rate
        ax4 = axes[1, 0]
        ax4.bar(range(len(scenarios)), summary_df['Packet_Loss_Rate'], color='salmon')
        ax4.set_xlabel('Scenario')
        ax4.set_ylabel('Packet Loss Rate')
        ax4.set_title('Packet Loss Rate Comparison')
        ax4.set_xticks(range(len(scenarios)))
        ax4.set_xticklabels([s.replace(' ', '\n') for s in scenarios], rotation=45, ha='right', fontsize=8)
        ax4.grid(axis='y', alpha=0.3)
        
        # Plot 5: Detection Rate
        ax5 = axes[1, 1]
        detection_rates = summary_df['Detection_Rate'].fillna(0)
        ax5.bar(range(len(scenarios)), detection_rates, color='mediumseagreen')
        ax5.set_xlabel('Scenario')
        ax5.set_ylabel('Detection Rate')
        ax5.set_title('Attack Detection Rate')
        ax5.set_xticks(range(len(scenarios)))
        ax5.set_xticklabels([s.replace(' ', '\n') for s in scenarios], rotation=45, ha='right', fontsize=8)
        ax5.grid(axis='y', alpha=0.3)
        
        # Plot 6: Routing Overhead
        ax6 = axes[1, 2]
        ax6.bar(range(len(scenarios)), summary_df['Routing_Overhead'], color='mediumpurple')
        ax6.set_xlabel('Scenario')
        ax6.set_ylabel('Routing Overhead')
        ax6.set_title('Routing Overhead Comparison')
        ax6.set_xticks(range(len(scenarios)))
        ax6.set_xticklabels([s.replace(' ', '\n') for s in scenarios], rotation=45, ha='right', fontsize=8)
        ax6.grid(axis='y', alpha=0.3)
        
        plt.tight_layout()
        
        # Save figure
        plot_file = os.path.join(self.results_dir, 'performance_comparison.png')
        plt.savefig(plot_file, dpi=300, bbox_inches='tight')
        print(f"  ✓ Visualization saved to: {plot_file}")
        plt.close()
        
        # Generate additional attack-specific plots
        self._generate_attack_impact_plot(summary_df)
    
    def _generate_attack_impact_plot(self, summary_df):
        """Generate attack impact comparison plot"""
        baseline_idx = summary_df[summary_df['Scenario'].str.contains('Baseline')].index
        if len(baseline_idx) == 0:
            return
        
        baseline = summary_df.iloc[baseline_idx[0]]
        attack_scenarios = summary_df[~summary_df['Scenario'].str.contains('Baseline')]
        
        if attack_scenarios.empty:
            return
        
        fig, ax = plt.subplots(figsize=(12, 6))
        
        x = np.arange(len(attack_scenarios))
        width = 0.25
        
        pdr_impact = [(baseline['Avg_PDR'] - row['Avg_PDR']) / baseline['Avg_PDR'] * 100 
                     for _, row in attack_scenarios.iterrows()]
        delay_impact = [(row['Avg_Delay_ms'] - baseline['Avg_Delay_ms']) / baseline['Avg_Delay_ms'] * 100 
                       for _, row in attack_scenarios.iterrows()]
        throughput_impact = [(baseline['Avg_Throughput_Mbps'] - row['Avg_Throughput_Mbps']) / baseline['Avg_Throughput_Mbps'] * 100 
                            for _, row in attack_scenarios.iterrows()]
        
        ax.bar(x - width, pdr_impact, width, label='PDR Degradation', color='steelblue')
        ax.bar(x, delay_impact, width, label='Delay Increase', color='coral')
        ax.bar(x + width, throughput_impact, width, label='Throughput Degradation', color='lightgreen')
        
        ax.set_xlabel('Attack Scenario')
        ax.set_ylabel('Impact (%)')
        ax.set_title('Attack Impact Comparison (vs Baseline)')
        ax.set_xticks(x)
        ax.set_xticklabels([s.replace(' ', '\n') for s in attack_scenarios['Scenario']], rotation=45, ha='right', fontsize=9)
        ax.legend()
        ax.grid(axis='y', alpha=0.3)
        
        plt.tight_layout()
        impact_file = os.path.join(self.results_dir, 'attack_impact_comparison.png')
        plt.savefig(impact_file, dpi=300, bbox_inches='tight')
        print(f"  ✓ Attack impact plot saved to: {impact_file}")
        plt.close()
    
    def generate_latex_table(self, summary_df):
        """Generate LaTeX table for research paper"""
        print("\nGenerating LaTeX table...")
        
        latex_file = os.path.join(self.results_dir, 'results_latex_table.tex')
        
        with open(latex_file, 'w') as f:
            f.write("\\begin{table}[htbp]\n")
            f.write("\\centering\n")
            f.write("\\caption{Performance Comparison Under Different Attack Scenarios}\n")
            f.write("\\label{tab:attack_performance}\n")
            f.write("\\begin{tabular}{|l|c|c|c|c|}\n")
            f.write("\\hline\n")
            f.write("\\textbf{Scenario} & \\textbf{PDR} & \\textbf{Delay (ms)} & \\textbf{Throughput (Mbps)} & \\textbf{Detection Rate} \\\\\n")
            f.write("\\hline\n")
            
            for _, row in summary_df.iterrows():
                f.write(f"{row['Scenario']} & {row['Avg_PDR']:.3f} & {row['Avg_Delay_ms']:.2f} & {row['Avg_Throughput_Mbps']:.2f} & {row['Detection_Rate']:.3f} \\\\\n")
            
            f.write("\\hline\n")
            f.write("\\end{tabular}\n")
            f.write("\\end{table}\n")
        
        print(f"  ✓ LaTeX table saved to: {latex_file}")
    
    def generate_report(self):
        """Generate comprehensive analysis report"""
        print("\n" + "="*60)
        print("SDVN ATTACK ANALYSIS REPORT")
        print("="*60)
        
        self.load_metrics()
        
        if not self.metrics:
            print("\n⚠ No metric files found. Please check the results directory.")
            return
        
        summary_df = self.calculate_summary_statistics()
        
        if not summary_df.empty:
            comparison_df = self.generate_comparison_table(summary_df)
            self.generate_visualizations(summary_df)
            self.generate_latex_table(summary_df)
            
            print("\n" + "="*60)
            print("SUMMARY STATISTICS")
            print("="*60)
            print(summary_df.to_string(index=False))
            
            if comparison_df is not None and not comparison_df.empty:
                print("\n" + "="*60)
                print("ATTACK IMPACT ANALYSIS")
                print("="*60)
                print(comparison_df.to_string(index=False))
        
        print("\n" + "="*60)
        print("ANALYSIS COMPLETE")
        print("="*60)
        print(f"\nAll results saved to: {self.results_dir}")
        print("\nGenerated files:")
        print("  - summary_statistics.csv")
        print("  - attack_impact_comparison.csv")
        print("  - performance_comparison.png")
        print("  - attack_impact_comparison.png")
        print("  - results_latex_table.tex")

def main():
    if len(sys.argv) < 2:
        print("Usage: python3 analyze_attack_results.py <results_directory>")
        sys.exit(1)
    
    results_dir = sys.argv[1]
    
    if not os.path.exists(results_dir):
        print(f"Error: Directory '{results_dir}' not found")
        sys.exit(1)
    
    analyzer = AttackAnalyzer(results_dir)
    analyzer.generate_report()

if __name__ == "__main__":
    main()

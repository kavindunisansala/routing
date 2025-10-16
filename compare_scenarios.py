"""
VANET Scenario Comparison Tool
===============================

Compare multiple packet-delivery-analysis.csv files from different scenarios:
- Baseline (no attack)
- Attack only
- Attack + Mitigation

This helps evaluate the effectiveness of mitigation strategies.

Author: VANET Security Research
Date: October 2025
"""

import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import numpy as np
from pathlib import Path
import sys

sns.set_style("whitegrid")
plt.rcParams['figure.figsize'] = (14, 8)
plt.rcParams['font.size'] = 11

class ScenarioComparator:
    """Compare multiple simulation scenarios"""
    
    def __init__(self):
        self.scenarios = {}
        self.metrics_comparison = {}
    
    def load_scenario(self, name, csv_file):
        """Load a scenario CSV file"""
        try:
            df = pd.read_csv(csv_file)
            self.scenarios[name] = df
            print(f"✅ Loaded '{name}': {len(df)} packets from {csv_file}")
            return True
        except FileNotFoundError:
            print(f"❌ File not found: {csv_file}")
            return False
        except Exception as e:
            print(f"❌ Error loading {csv_file}: {e}")
            return False
    
    def calculate_scenario_metrics(self, name, df):
        """Calculate metrics for a single scenario"""
        total = len(df)
        delivered = df['Delivered'].sum()
        
        metrics = {
            'Total Packets': total,
            'Delivered': delivered,
            'Dropped': total - delivered,
            'PDR (%)': (delivered / total * 100) if total > 0 else 0,
            'Avg Delay (ms)': df[df['Delivered'] == 1]['DelayMs'].mean(),
            'Wormhole Affected': df['WormholeOnPath'].sum(),
            'Blackhole Affected': df['BlackholeOnPath'].sum(),
        }
        
        return metrics
    
    def compare_all_scenarios(self):
        """Calculate and compare metrics for all scenarios"""
        print("\n" + "="*80)
        print("📊 SCENARIO COMPARISON")
        print("="*80 + "\n")
        
        for name, df in self.scenarios.items():
            metrics = self.calculate_scenario_metrics(name, df)
            self.metrics_comparison[name] = metrics
            
            print(f"📈 {name}:")
            for metric, value in metrics.items():
                if isinstance(value, float):
                    print(f"   {metric:.<35} {value:>10.2f}")
                else:
                    print(f"   {metric:.<35} {value:>10}")
            print()
    
    def plot_pdr_comparison(self, output_dir='comparison_plots'):
        """Compare PDR across scenarios"""
        Path(output_dir).mkdir(exist_ok=True)
        
        scenarios = list(self.metrics_comparison.keys())
        pdr_values = [self.metrics_comparison[s]['PDR (%)'] for s in scenarios]
        
        fig, ax = plt.subplots(figsize=(10, 6))
        bars = ax.bar(scenarios, pdr_values, color=['#2ecc71', '#e74c3c', '#3498db'], 
                     alpha=0.8, edgecolor='black', linewidth=2)
        
        # Add value labels
        for bar in bars:
            height = bar.get_height()
            ax.text(bar.get_x() + bar.get_width()/2., height,
                   f'{height:.1f}%',
                   ha='center', va='bottom', fontweight='bold', fontsize=13)
        
        ax.set_ylabel('Packet Delivery Ratio (%)', fontweight='bold', fontsize=13)
        ax.set_title('PDR Comparison Across Scenarios', fontweight='bold', fontsize=15, pad=20)
        ax.set_ylim(0, 110)
        ax.grid(axis='y', alpha=0.3)
        
        plt.tight_layout()
        plt.savefig(f'{output_dir}/pdr_scenario_comparison.png', dpi=300, bbox_inches='tight')
        print(f"✅ Saved: {output_dir}/pdr_scenario_comparison.png")
        plt.close()
    
    def plot_delay_comparison(self, output_dir='comparison_plots'):
        """Compare delay across scenarios"""
        Path(output_dir).mkdir(exist_ok=True)
        
        scenarios = list(self.metrics_comparison.keys())
        delay_values = [self.metrics_comparison[s]['Avg Delay (ms)'] for s in scenarios]
        
        fig, ax = plt.subplots(figsize=(10, 6))
        bars = ax.bar(scenarios, delay_values, color=['#2ecc71', '#e74c3c', '#3498db'],
                     alpha=0.8, edgecolor='black', linewidth=2)
        
        for bar in bars:
            height = bar.get_height()
            ax.text(bar.get_x() + bar.get_width()/2., height,
                   f'{height:.2f}ms',
                   ha='center', va='bottom', fontweight='bold', fontsize=13)
        
        ax.set_ylabel('Average End-to-End Delay (ms)', fontweight='bold', fontsize=13)
        ax.set_title('Delay Comparison Across Scenarios', fontweight='bold', fontsize=15, pad=20)
        ax.grid(axis='y', alpha=0.3)
        
        plt.tight_layout()
        plt.savefig(f'{output_dir}/delay_scenario_comparison.png', dpi=300, bbox_inches='tight')
        print(f"✅ Saved: {output_dir}/delay_scenario_comparison.png")
        plt.close()
    
    def plot_delay_distributions(self, output_dir='comparison_plots'):
        """Plot delay distributions for all scenarios"""
        Path(output_dir).mkdir(exist_ok=True)
        
        fig, ax = plt.subplots(figsize=(12, 6))
        
        colors = ['#2ecc71', '#e74c3c', '#3498db', '#f39c12', '#9b59b6']
        
        for i, (name, df) in enumerate(self.scenarios.items()):
            delivered = df[df['Delivered'] == 1]
            if len(delivered) > 0:
                ax.hist(delivered['DelayMs'], bins=50, alpha=0.5, 
                       label=name, color=colors[i % len(colors)], edgecolor='black')
        
        ax.set_xlabel('End-to-End Delay (ms)', fontweight='bold', fontsize=13)
        ax.set_ylabel('Frequency', fontweight='bold', fontsize=13)
        ax.set_title('Delay Distribution Comparison', fontweight='bold', fontsize=15, pad=20)
        ax.legend(fontsize=12)
        ax.grid(axis='y', alpha=0.3)
        
        plt.tight_layout()
        plt.savefig(f'{output_dir}/delay_distribution_comparison.png', dpi=300, bbox_inches='tight')
        print(f"✅ Saved: {output_dir}/delay_distribution_comparison.png")
        plt.close()
    
    def plot_metrics_radar(self, output_dir='comparison_plots'):
        """Create radar chart comparing multiple metrics"""
        Path(output_dir).mkdir(exist_ok=True)
        
        # Normalize metrics for radar chart (0-100 scale)
        categories = ['PDR', 'Delay\n(inverted)', 'Delivery\nRate']
        
        fig, ax = plt.subplots(figsize=(10, 10), subplot_kw=dict(projection='polar'))
        
        angles = np.linspace(0, 2 * np.pi, len(categories), endpoint=False).tolist()
        angles += angles[:1]  # Complete the circle
        
        colors = ['#2ecc71', '#e74c3c', '#3498db', '#f39c12']
        
        for i, (name, metrics) in enumerate(self.metrics_comparison.items()):
            pdr = metrics['PDR (%)']
            delay_inverted = 100 - min(metrics['Avg Delay (ms)'], 100)  # Invert delay
            delivery_rate = (metrics['Delivered'] / metrics['Total Packets']) * 100
            
            values = [pdr, delay_inverted, delivery_rate]
            values += values[:1]  # Complete the circle
            
            ax.plot(angles, values, 'o-', linewidth=2, label=name, 
                   color=colors[i % len(colors)], markersize=8)
            ax.fill(angles, values, alpha=0.15, color=colors[i % len(colors)])
        
        ax.set_xticks(angles[:-1])
        ax.set_xticklabels(categories, fontsize=12, fontweight='bold')
        ax.set_ylim(0, 100)
        ax.set_title('Multi-Metric Performance Comparison', fontweight='bold', 
                    fontsize=15, pad=30)
        ax.legend(loc='upper right', bbox_to_anchor=(1.3, 1.1), fontsize=11)
        ax.grid(True)
        
        plt.tight_layout()
        plt.savefig(f'{output_dir}/metrics_radar_comparison.png', dpi=300, bbox_inches='tight')
        print(f"✅ Saved: {output_dir}/metrics_radar_comparison.png")
        plt.close()
    
    def plot_improvement_percentage(self, baseline_name, output_dir='comparison_plots'):
        """Plot improvement percentages relative to baseline"""
        Path(output_dir).mkdir(exist_ok=True)
        
        if baseline_name not in self.metrics_comparison:
            print(f"❌ Baseline '{baseline_name}' not found!")
            return
        
        baseline_pdr = self.metrics_comparison[baseline_name]['PDR (%)']
        baseline_delay = self.metrics_comparison[baseline_name]['Avg Delay (ms)']
        
        scenarios = []
        pdr_improvements = []
        delay_improvements = []
        
        for name, metrics in self.metrics_comparison.items():
            if name != baseline_name:
                scenarios.append(name)
                pdr_imp = ((metrics['PDR (%)'] - baseline_pdr) / baseline_pdr) * 100
                delay_imp = ((baseline_delay - metrics['Avg Delay (ms)']) / baseline_delay) * 100
                pdr_improvements.append(pdr_imp)
                delay_improvements.append(delay_imp)
        
        x = np.arange(len(scenarios))
        width = 0.35
        
        fig, ax = plt.subplots(figsize=(10, 6))
        bars1 = ax.bar(x - width/2, pdr_improvements, width, label='PDR Improvement', 
                      color='#2ecc71', alpha=0.8, edgecolor='black', linewidth=1.5)
        bars2 = ax.bar(x + width/2, delay_improvements, width, label='Delay Reduction',
                      color='#3498db', alpha=0.8, edgecolor='black', linewidth=1.5)
        
        # Add value labels
        for bars in [bars1, bars2]:
            for bar in bars:
                height = bar.get_height()
                ax.text(bar.get_x() + bar.get_width()/2., height,
                       f'{height:+.1f}%',
                       ha='center', va='bottom' if height > 0 else 'top',
                       fontweight='bold', fontsize=11)
        
        ax.set_ylabel('Improvement (%)', fontweight='bold', fontsize=13)
        ax.set_title(f'Performance Improvement Relative to {baseline_name}', 
                    fontweight='bold', fontsize=15, pad=20)
        ax.set_xticks(x)
        ax.set_xticklabels(scenarios)
        ax.legend(fontsize=12)
        ax.axhline(y=0, color='black', linestyle='--', linewidth=1)
        ax.grid(axis='y', alpha=0.3)
        
        plt.tight_layout()
        plt.savefig(f'{output_dir}/improvement_percentage.png', dpi=300, bbox_inches='tight')
        print(f"✅ Saved: {output_dir}/improvement_percentage.png")
        plt.close()
    
    def export_comparison_table(self, output_file='scenario_comparison.csv'):
        """Export comparison table as CSV"""
        df = pd.DataFrame(self.metrics_comparison).T
        df.to_csv(output_file)
        print(f"✅ Comparison table saved: {output_file}")
    
    def generate_all_comparisons(self, baseline_name=None, output_dir='comparison_plots'):
        """Generate all comparison plots"""
        print("\n📊 Generating comparison plots...")
        print("-" * 80)
        
        self.plot_pdr_comparison(output_dir)
        self.plot_delay_comparison(output_dir)
        self.plot_delay_distributions(output_dir)
        self.plot_metrics_radar(output_dir)
        
        if baseline_name:
            self.plot_improvement_percentage(baseline_name, output_dir)
        
        print("-" * 80)
        print(f"✅ All comparison plots saved to '{output_dir}/'\n")


def main():
    """Main execution"""
    print("\n" + "="*80)
    print("🔬 VANET Scenario Comparison Tool")
    print("="*80 + "\n")
    
    comparator = ScenarioComparator()
    
    # Example: Load three scenarios
    print("📂 Loading scenario files...\n")
    
    # Scenario 1: Baseline (no attack)
    if Path('baseline.csv').exists():
        comparator.load_scenario('Baseline (No Attack)', 'baseline.csv')
    elif Path('packet-delivery-analysis.csv').exists():
        comparator.load_scenario('Scenario 1', 'packet-delivery-analysis.csv')
    
    # Scenario 2: Attack only
    if Path('wormhole_attack.csv').exists():
        comparator.load_scenario('Wormhole Attack', 'wormhole_attack.csv')
    
    # Scenario 3: Attack + Mitigation
    if Path('wormhole_mitigated.csv').exists():
        comparator.load_scenario('With Mitigation', 'wormhole_mitigated.csv')
    
    if len(comparator.scenarios) == 0:
        print("❌ No CSV files found!")
        print("\n💡 Usage Instructions:")
        print("   1. Run baseline simulation:")
        print("      ./waf --run \"routing --use_enhanced_wormhole=false --enable_packet_tracking --simTime=10\"")
        print("      mv packet-delivery-analysis.csv baseline.csv\n")
        print("   2. Run attack simulation:")
        print("      ./waf --run \"routing --enable_packet_tracking --simTime=10\"")
        print("      mv packet-delivery-analysis.csv wormhole_attack.csv\n")
        print("   3. Run attack + mitigation:")
        print("      ./waf --run \"routing --enable_wormhole_detection --enable_wormhole_mitigation --enable_packet_tracking --simTime=10\"")
        print("      mv packet-delivery-analysis.csv wormhole_mitigated.csv\n")
        print("   4. Run this script again:")
        print("      python compare_scenarios.py\n")
        return
    
    if len(comparator.scenarios) < 2:
        print("⚠️  Only one scenario loaded. Need at least 2 for comparison.")
        return
    
    # Compare scenarios
    comparator.compare_all_scenarios()
    
    # Generate visualizations
    baseline = list(comparator.scenarios.keys())[0] if 'Baseline' in str(comparator.scenarios.keys()) else None
    comparator.generate_all_comparisons(baseline_name=baseline)
    
    # Export results
    comparator.export_comparison_table()
    
    print("="*80)
    print("✅ Comparison Complete!")
    print("="*80)
    print("\n📁 Generated Files:")
    print("   📊 Comparison plots: comparison_plots/*.png")
    print("   📈 Comparison table: scenario_comparison.csv")
    print("\n💡 Use these comparisons in your research paper!\n")


if __name__ == "__main__":
    main()

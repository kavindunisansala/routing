#!/usr/bin/env python3
"""
Comprehensive SDVN Evaluation Analysis Script
Analyzes results from 76-test comprehensive evaluation (70 nodes, 5 attack percentages)
Generates publication-ready graphs and statistical analysis
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
plt.rcParams['figure.figsize'] = (12, 8)
plt.rcParams['font.size'] = 10
plt.rcParams['axes.labelsize'] = 12
plt.rcParams['axes.titlesize'] = 14
plt.rcParams['legend.fontsize'] = 10
plt.rcParams['xtick.labelsize'] = 10
plt.rcParams['ytick.labelsize'] = 10

class SDVNComprehensiveAnalyzer:
    def __init__(self, results_dir):
        self.results_dir = results_dir
        self.output_dir = os.path.join(results_dir, "analysis_output")
        os.makedirs(self.output_dir, exist_ok=True)
        
        # Attack percentages tested
        self.attack_percentages = [20, 40, 60, 80, 100]
        
        # Test configurations
        self.attack_types = ['wormhole', 'blackhole', 'sybil', 'replay', 'rtp']
        self.scenarios = ['no_mitigation', 'with_detection', 'with_mitigation']
        
        # Results storage
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
            
            # Calculate average delay for delivered packets
            delivered_df = df[df['Delivered'] == 1]
            avg_delay = delivered_df['DelayMs'].mean() if len(delivered_df) > 0 else 0
            
            return {
                'total_packets': total_packets,
                'delivered_packets': delivered_packets,
                'dropped_packets': total_packets - delivered_packets,
                'pdr': pdr,
                'avg_delay': avg_delay
            }
        except Exception as e:
            print(f"  ⚠ Error loading {csv_path}: {e}")
            return None
    
    def load_all_results(self):
        """Load all test results"""
        print("\n" + "="*80)
        print("LOADING COMPREHENSIVE EVALUATION RESULTS")
        print("="*80)
        
        # Load baseline
        print("\nLoading Baseline...")
        baseline_dir = os.path.join(self.results_dir, "test01_baseline")
        self.baseline = self.load_packet_delivery_data(baseline_dir)
        if self.baseline:
            print(f"  ✓ Baseline PDR: {self.baseline['pdr']:.2f}%")
        
        # Load attack results
        for attack_type in self.attack_types:
            print(f"\nLoading {attack_type.upper()} results...")
            
            for percentage in self.attack_percentages:
                for scenario in self.scenarios:
                    # Construct test directory name
                    if attack_type == 'wormhole':
                        test_prefix = 'test02' if scenario == 'no_mitigation' else ('test03' if scenario == 'with_detection' else 'test04')
                    elif attack_type == 'blackhole':
                        test_prefix = 'test05' if scenario == 'no_mitigation' else ('test06' if scenario == 'with_detection' else 'test07')
                    elif attack_type == 'sybil':
                        test_prefix = 'test08' if scenario == 'no_mitigation' else ('test09' if scenario == 'with_detection' else 'test10')
                    elif attack_type == 'replay':
                        test_prefix = 'test11' if scenario == 'no_mitigation' else ('test12' if scenario == 'with_detection' else 'test13')
                    elif attack_type == 'rtp':
                        test_prefix = 'test14' if scenario == 'no_mitigation' else ('test15' if scenario == 'with_detection' else 'test16')
                    
                    test_dir = os.path.join(self.results_dir, f"{test_prefix}_{attack_type}_{percentage}_{scenario}")
                    
                    data = self.load_packet_delivery_data(test_dir)
                    if data:
                        self.results[attack_type][percentage][scenario] = data
                        print(f"  ✓ {attack_type} {percentage}% {scenario}: PDR={data['pdr']:.2f}%")
        
        # Load combined attack results
        print("\nLoading Combined Attack results...")
        for percentage in self.attack_percentages:
            test_dir = os.path.join(self.results_dir, f"test17_combined_{percentage}_with_all_mitigations")
            data = self.load_packet_delivery_data(test_dir)
            if data:
                self.results['combined'][percentage]['with_all_mitigations'] = data
                print(f"  ✓ Combined {percentage}%: PDR={data['pdr']:.2f}%")
    
    def generate_pdr_vs_attack_percentage_curves(self):
        """Generate PDR vs Attack Percentage curves for each attack type"""
        print("\n" + "="*80)
        print("GENERATING PDR vs ATTACK PERCENTAGE CURVES")
        print("="*80)
        
        fig, axes = plt.subplots(2, 3, figsize=(18, 12))
        axes = axes.flatten()
        
        for idx, attack_type in enumerate(self.attack_types):
            ax = axes[idx]
            
            # Prepare data for each scenario
            for scenario in self.scenarios:
                percentages = []
                pdrs = []
                
                for percentage in self.attack_percentages:
                    if percentage in self.results[attack_type] and scenario in self.results[attack_type][percentage]:
                        percentages.append(percentage)
                        pdrs.append(self.results[attack_type][percentage][scenario]['pdr'])
                
                if percentages:
                    label = scenario.replace('_', ' ').title()
                    marker = 'x' if scenario == 'no_mitigation' else ('o' if scenario == 'with_detection' else '^')
                    linestyle = '--' if scenario == 'no_mitigation' else (':' if scenario == 'with_detection' else '-')
                    
                    ax.plot(percentages, pdrs, marker=marker, linestyle=linestyle, 
                           linewidth=2, markersize=8, label=label)
            
            # Add baseline reference line
            if self.baseline:
                ax.axhline(y=self.baseline['pdr'], color='green', linestyle='-.', 
                          linewidth=1, alpha=0.5, label='Baseline')
            
            ax.set_xlabel('Attack Percentage (%)')
            ax.set_ylabel('Packet Delivery Ratio (%)')
            ax.set_title(f'{attack_type.upper()} Attack Impact')
            ax.legend(loc='best')
            ax.grid(True, alpha=0.3)
            ax.set_xlim(15, 105)
            ax.set_ylim(0, 105)
        
        # Combined attack in last subplot
        ax = axes[5]
        percentages = []
        pdrs = []
        
        for percentage in self.attack_percentages:
            if percentage in self.results['combined'] and 'with_all_mitigations' in self.results['combined'][percentage]:
                percentages.append(percentage)
                pdrs.append(self.results['combined'][percentage]['with_all_mitigations']['pdr'])
        
        if percentages:
            ax.plot(percentages, pdrs, marker='s', linestyle='-', 
                   linewidth=2, markersize=8, label='All Mitigations', color='purple')
        
        if self.baseline:
            ax.axhline(y=self.baseline['pdr'], color='green', linestyle='-.', 
                      linewidth=1, alpha=0.5, label='Baseline')
        
        ax.set_xlabel('Attack Percentage (%)')
        ax.set_ylabel('Packet Delivery Ratio (%)')
        ax.set_title('COMBINED Attack (All Mitigations)')
        ax.legend(loc='best')
        ax.grid(True, alpha=0.3)
        ax.set_xlim(15, 105)
        ax.set_ylim(0, 105)
        
        plt.tight_layout()
        output_path = os.path.join(self.output_dir, 'pdr_vs_attack_percentage_comprehensive.png')
        plt.savefig(output_path, dpi=300, bbox_inches='tight')
        print(f"✓ Saved: {output_path}")
        plt.close()
    
    def generate_mitigation_effectiveness_heatmap(self):
        """Generate heatmap showing mitigation effectiveness"""
        print("\n" + "="*80)
        print("GENERATING MITIGATION EFFECTIVENESS HEATMAP")
        print("="*80)
        
        # Calculate mitigation effectiveness: (PDR_miti - PDR_no_miti) / (100 - PDR_no_miti) * 100
        effectiveness_data = []
        
        for attack_type in self.attack_types:
            row = []
            for percentage in self.attack_percentages:
                if (percentage in self.results[attack_type] and 
                    'no_mitigation' in self.results[attack_type][percentage] and
                    'with_mitigation' in self.results[attack_type][percentage]):
                    
                    pdr_no_miti = self.results[attack_type][percentage]['no_mitigation']['pdr']
                    pdr_with_miti = self.results[attack_type][percentage]['with_mitigation']['pdr']
                    
                    # Calculate effectiveness percentage
                    if pdr_no_miti < 100:
                        effectiveness = (pdr_with_miti - pdr_no_miti) / (100 - pdr_no_miti) * 100
                    else:
                        effectiveness = 0
                    
                    row.append(effectiveness)
                else:
                    row.append(0)
            
            effectiveness_data.append(row)
        
        # Create heatmap
        fig, ax = plt.subplots(figsize=(12, 8))
        
        effectiveness_df = pd.DataFrame(
            effectiveness_data,
            index=[a.upper() for a in self.attack_types],
            columns=[f'{p}%' for p in self.attack_percentages]
        )
        
        sns.heatmap(effectiveness_df, annot=True, fmt='.1f', cmap='RdYlGn', 
                   center=50, vmin=0, vmax=100, cbar_kws={'label': 'Effectiveness (%)'})
        
        ax.set_title('Mitigation Effectiveness Across Attack Types and Intensities\n' +
                    '(Higher is Better: Recovery of PDR degradation)', fontsize=14, weight='bold')
        ax.set_xlabel('Attack Percentage', fontsize=12)
        ax.set_ylabel('Attack Type', fontsize=12)
        
        plt.tight_layout()
        output_path = os.path.join(self.output_dir, 'mitigation_effectiveness_heatmap.png')
        plt.savefig(output_path, dpi=300, bbox_inches='tight')
        print(f"✓ Saved: {output_path}")
        plt.close()
    
    def generate_attack_comparison_bars(self):
        """Generate bar chart comparing attack impacts at different percentages"""
        print("\n" + "="*80)
        print("GENERATING ATTACK COMPARISON BAR CHARTS")
        print("="*80)
        
        fig, axes = plt.subplots(1, len(self.attack_percentages), figsize=(20, 6))
        
        for idx, percentage in enumerate(self.attack_percentages):
            ax = axes[idx]
            
            attack_names = []
            no_miti_pdrs = []
            with_miti_pdrs = []
            
            for attack_type in self.attack_types:
                if (percentage in self.results[attack_type] and
                    'no_mitigation' in self.results[attack_type][percentage]):
                    
                    attack_names.append(attack_type.upper())
                    no_miti_pdrs.append(self.results[attack_type][percentage]['no_mitigation']['pdr'])
                    
                    if 'with_mitigation' in self.results[attack_type][percentage]:
                        with_miti_pdrs.append(self.results[attack_type][percentage]['with_mitigation']['pdr'])
                    else:
                        with_miti_pdrs.append(0)
            
            x = np.arange(len(attack_names))
            width = 0.35
            
            ax.bar(x - width/2, no_miti_pdrs, width, label='No Mitigation', color='#ff6b6b')
            ax.bar(x + width/2, with_miti_pdrs, width, label='With Mitigation', color='#4ecdc4')
            
            ax.set_xlabel('Attack Type')
            ax.set_ylabel('PDR (%)')
            ax.set_title(f'Attack Impact at {percentage}%')
            ax.set_xticks(x)
            ax.set_xticklabels(attack_names, rotation=45, ha='right')
            ax.legend()
            ax.grid(True, axis='y', alpha=0.3)
            ax.set_ylim(0, 105)
            
            # Add baseline reference
            if self.baseline:
                ax.axhline(y=self.baseline['pdr'], color='green', linestyle='--', 
                          linewidth=1, alpha=0.5)
        
        plt.tight_layout()
        output_path = os.path.join(self.output_dir, 'attack_comparison_by_percentage.png')
        plt.savefig(output_path, dpi=300, bbox_inches='tight')
        print(f"✓ Saved: {output_path}")
        plt.close()
    
    def generate_combined_attack_performance(self):
        """Generate graph showing combined attack performance"""
        print("\n" + "="*80)
        print("GENERATING COMBINED ATTACK PERFORMANCE GRAPH")
        print("="*80)
        
        fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(16, 6))
        
        # Left: Combined attack PDR vs percentage
        percentages = []
        pdrs = []
        
        for percentage in self.attack_percentages:
            if percentage in self.results['combined'] and 'with_all_mitigations' in self.results['combined'][percentage]:
                percentages.append(percentage)
                pdrs.append(self.results['combined'][percentage]['with_all_mitigations']['pdr'])
        
        if percentages:
            ax1.plot(percentages, pdrs, marker='o', linestyle='-', linewidth=3, 
                    markersize=10, color='purple', label='Combined Attack (All Mitigations)')
            
            if self.baseline:
                ax1.axhline(y=self.baseline['pdr'], color='green', linestyle='--', 
                          linewidth=2, alpha=0.7, label='Baseline (No Attack)')
            
            ax1.set_xlabel('Attack Percentage (%)', fontsize=12)
            ax1.set_ylabel('Packet Delivery Ratio (%)', fontsize=12)
            ax1.set_title('Combined Attack Performance\n(All 5 Attacks + All Mitigations)', 
                         fontsize=14, weight='bold')
            ax1.legend(fontsize=10)
            ax1.grid(True, alpha=0.3)
            ax1.set_xlim(15, 105)
            ax1.set_ylim(0, 105)
        
        # Right: Comparison with individual attacks
        comparison_data = []
        labels = []
        
        for percentage in self.attack_percentages:
            avg_individual_pdrs = []
            
            for attack_type in self.attack_types:
                if (percentage in self.results[attack_type] and 
                    'with_mitigation' in self.results[attack_type][percentage]):
                    avg_individual_pdrs.append(self.results[attack_type][percentage]['with_mitigation']['pdr'])
            
            if avg_individual_pdrs:
                avg_pdr = np.mean(avg_individual_pdrs)
                comparison_data.append(avg_pdr)
                labels.append(f'{percentage}%')
        
        combined_pdrs_for_comparison = [pdrs[i] for i in range(len(pdrs))]
        
        x = np.arange(len(labels))
        width = 0.35
        
        ax2.bar(x - width/2, comparison_data, width, label='Avg Individual Attacks', color='#95a5a6')
        ax2.bar(x + width/2, combined_pdrs_for_comparison, width, label='Combined Attack', color='purple')
        
        ax2.set_xlabel('Attack Percentage', fontsize=12)
        ax2.set_ylabel('PDR (%)', fontsize=12)
        ax2.set_title('Combined vs Average Individual Attack Performance', 
                     fontsize=14, weight='bold')
        ax2.set_xticks(x)
        ax2.set_xticklabels(labels)
        ax2.legend(fontsize=10)
        ax2.grid(True, axis='y', alpha=0.3)
        ax2.set_ylim(0, 105)
        
        plt.tight_layout()
        output_path = os.path.join(self.output_dir, 'combined_attack_analysis.png')
        plt.savefig(output_path, dpi=300, bbox_inches='tight')
        print(f"✓ Saved: {output_path}")
        plt.close()
    
    def generate_statistical_summary(self):
        """Generate statistical summary tables"""
        print("\n" + "="*80)
        print("GENERATING STATISTICAL SUMMARY")
        print("="*80)
        
        summary_file = os.path.join(self.output_dir, 'statistical_summary.txt')
        
        with open(summary_file, 'w') as f:
            f.write("="*80 + "\n")
            f.write("COMPREHENSIVE SDVN EVALUATION - STATISTICAL SUMMARY\n")
            f.write("="*80 + "\n")
            f.write(f"\nGenerated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
            f.write(f"Results Directory: {self.results_dir}\n\n")
            
            # Baseline
            f.write("-"*80 + "\n")
            f.write("BASELINE PERFORMANCE\n")
            f.write("-"*80 + "\n")
            if self.baseline:
                f.write(f"PDR: {self.baseline['pdr']:.2f}%\n")
                f.write(f"Avg Delay: {self.baseline['avg_delay']:.2f} ms\n")
                f.write(f"Total Packets: {self.baseline['total_packets']}\n")
                f.write(f"Delivered: {self.baseline['delivered_packets']}\n")
                f.write(f"Dropped: {self.baseline['dropped_packets']}\n\n")
            
            # Attack summaries
            for attack_type in self.attack_types:
                f.write("-"*80 + "\n")
                f.write(f"{attack_type.upper()} ATTACK ANALYSIS\n")
                f.write("-"*80 + "\n")
                
                f.write(f"\n{'Attack %':<12} {'No Miti PDR':<15} {'Detection PDR':<15} {'Full Miti PDR':<15} {'Effectiveness':<15}\n")
                f.write("-"*80 + "\n")
                
                for percentage in self.attack_percentages:
                    if percentage in self.results[attack_type]:
                        no_miti = self.results[attack_type][percentage].get('no_mitigation', {}).get('pdr', 0)
                        detection = self.results[attack_type][percentage].get('with_detection', {}).get('pdr', 0)
                        mitigation = self.results[attack_type][percentage].get('with_mitigation', {}).get('pdr', 0)
                        
                        # Calculate effectiveness
                        if no_miti < 100:
                            effectiveness = (mitigation - no_miti) / (100 - no_miti) * 100
                        else:
                            effectiveness = 0
                        
                        f.write(f"{percentage}%{'':<10} {no_miti:>6.2f}%{'':<8} {detection:>6.2f}%{'':<8} "
                               f"{mitigation:>6.2f}%{'':<8} {effectiveness:>6.2f}%\n")
                
                f.write("\n")
            
            # Combined attack summary
            f.write("-"*80 + "\n")
            f.write("COMBINED ATTACK ANALYSIS (All 5 Attacks with All Mitigations)\n")
            f.write("-"*80 + "\n")
            
            f.write(f"\n{'Attack %':<15} {'PDR':<15} {'Avg Delay (ms)':<20}\n")
            f.write("-"*80 + "\n")
            
            for percentage in self.attack_percentages:
                if percentage in self.results['combined'] and 'with_all_mitigations' in self.results['combined'][percentage]:
                    data = self.results['combined'][percentage]['with_all_mitigations']
                    f.write(f"{percentage}%{'':<13} {data['pdr']:>6.2f}%{'':<8} {data['avg_delay']:>10.2f}\n")
            
            f.write("\n")
            
            # Summary statistics
            f.write("="*80 + "\n")
            f.write("KEY FINDINGS\n")
            f.write("="*80 + "\n\n")
            
            # Find best and worst performing attacks
            avg_pdrs_no_miti = defaultdict(list)
            avg_pdrs_with_miti = defaultdict(list)
            
            for attack_type in self.attack_types:
                for percentage in self.attack_percentages:
                    if percentage in self.results[attack_type]:
                        if 'no_mitigation' in self.results[attack_type][percentage]:
                            avg_pdrs_no_miti[attack_type].append(
                                self.results[attack_type][percentage]['no_mitigation']['pdr']
                            )
                        if 'with_mitigation' in self.results[attack_type][percentage]:
                            avg_pdrs_with_miti[attack_type].append(
                                self.results[attack_type][percentage]['with_mitigation']['pdr']
                            )
            
            f.write("Average PDR across all attack percentages:\n\n")
            f.write(f"{'Attack Type':<15} {'No Mitigation':<20} {'With Mitigation':<20} {'Improvement':<15}\n")
            f.write("-"*80 + "\n")
            
            for attack_type in self.attack_types:
                avg_no_miti = np.mean(avg_pdrs_no_miti[attack_type]) if avg_pdrs_no_miti[attack_type] else 0
                avg_with_miti = np.mean(avg_pdrs_with_miti[attack_type]) if avg_pdrs_with_miti[attack_type] else 0
                improvement = avg_with_miti - avg_no_miti
                
                f.write(f"{attack_type.upper():<15} {avg_no_miti:>6.2f}%{'':<12} "
                       f"{avg_with_miti:>6.2f}%{'':<12} {improvement:>+6.2f}%\n")
            
            f.write("\n")
        
        print(f"✓ Saved: {summary_file}")
    
    def generate_latex_tables(self):
        """Generate LaTeX tables for publication"""
        print("\n" + "="*80)
        print("GENERATING LATEX TABLES")
        print("="*80)
        
        latex_file = os.path.join(self.output_dir, 'latex_tables.tex')
        
        with open(latex_file, 'w') as f:
            f.write("% LaTeX Tables for SDVN Comprehensive Evaluation\n")
            f.write("% Generated: " + datetime.now().strftime('%Y-%m-%d %H:%M:%S') + "\n\n")
            
            # Table 1: PDR comparison across attack types and percentages
            f.write("\\begin{table}[htbp]\n")
            f.write("\\centering\n")
            f.write("\\caption{PDR (\\%) Comparison: No Mitigation vs Full Mitigation}\n")
            f.write("\\label{tab:pdr_comparison}\n")
            f.write("\\begin{tabular}{l" + "c" * (len(self.attack_percentages) * 2) + "}\n")
            f.write("\\hline\n")
            
            # Header
            f.write("Attack & \\multicolumn{2}{c}{20\\%} & \\multicolumn{2}{c}{40\\%} & "
                   "\\multicolumn{2}{c}{60\\%} & \\multicolumn{2}{c}{80\\%} & \\multicolumn{2}{c}{100\\%} \\\\\n")
            f.write("Type & No & Full & No & Full & No & Full & No & Full & No & Full \\\\\n")
            f.write("\\hline\n")
            
            # Data rows
            for attack_type in self.attack_types:
                row = [attack_type.upper()]
                for percentage in self.attack_percentages:
                    if percentage in self.results[attack_type]:
                        no_miti = self.results[attack_type][percentage].get('no_mitigation', {}).get('pdr', 0)
                        mitigation = self.results[attack_type][percentage].get('with_mitigation', {}).get('pdr', 0)
                        row.append(f"{no_miti:.1f}")
                        row.append(f"{mitigation:.1f}")
                    else:
                        row.extend(["-", "-"])
                
                f.write(" & ".join(row) + " \\\\\n")
            
            f.write("\\hline\n")
            f.write("\\end{tabular}\n")
            f.write("\\end{table}\n\n")
            
            # Table 2: Mitigation effectiveness
            f.write("\\begin{table}[htbp]\n")
            f.write("\\centering\n")
            f.write("\\caption{Mitigation Effectiveness (\\%) Across Attack Intensities}\n")
            f.write("\\label{tab:mitigation_effectiveness}\n")
            f.write("\\begin{tabular}{l" + "c" * len(self.attack_percentages) + "}\n")
            f.write("\\hline\n")
            f.write("Attack Type & " + " & ".join([f"{p}\\%" for p in self.attack_percentages]) + " \\\\\n")
            f.write("\\hline\n")
            
            for attack_type in self.attack_types:
                row = [attack_type.upper()]
                for percentage in self.attack_percentages:
                    if (percentage in self.results[attack_type] and
                        'no_mitigation' in self.results[attack_type][percentage] and
                        'with_mitigation' in self.results[attack_type][percentage]):
                        
                        no_miti = self.results[attack_type][percentage]['no_mitigation']['pdr']
                        mitigation = self.results[attack_type][percentage]['with_mitigation']['pdr']
                        
                        if no_miti < 100:
                            effectiveness = (mitigation - no_miti) / (100 - no_miti) * 100
                        else:
                            effectiveness = 0
                        
                        row.append(f"{effectiveness:.1f}")
                    else:
                        row.append("-")
                
                f.write(" & ".join(row) + " \\\\\n")
            
            f.write("\\hline\n")
            f.write("\\end{tabular}\n")
            f.write("\\end{table}\n\n")
        
        print(f"✓ Saved: {latex_file}")
    
    def run_complete_analysis(self):
        """Run all analysis steps"""
        print("\n" + "="*80)
        print("COMPREHENSIVE SDVN EVALUATION ANALYSIS")
        print("="*80)
        print(f"\nResults Directory: {self.results_dir}")
        print(f"Output Directory: {self.output_dir}")
        
        # Load all data
        self.load_all_results()
        
        # Generate visualizations
        print("\n" + "="*80)
        print("GENERATING VISUALIZATIONS")
        print("="*80)
        
        self.generate_pdr_vs_attack_percentage_curves()
        self.generate_mitigation_effectiveness_heatmap()
        self.generate_attack_comparison_bars()
        self.generate_combined_attack_performance()
        
        # Generate reports
        print("\n" + "="*80)
        print("GENERATING REPORTS")
        print("="*80)
        
        self.generate_statistical_summary()
        self.generate_latex_tables()
        
        # Final summary
        print("\n" + "="*80)
        print("ANALYSIS COMPLETE")
        print("="*80)
        print(f"\nAll outputs saved to: {self.output_dir}")
        print("\nGenerated files:")
        print("  1. pdr_vs_attack_percentage_comprehensive.png - PDR curves")
        print("  2. mitigation_effectiveness_heatmap.png - Effectiveness heatmap")
        print("  3. attack_comparison_by_percentage.png - Attack comparison bars")
        print("  4. combined_attack_analysis.png - Combined attack performance")
        print("  5. statistical_summary.txt - Detailed statistics")
        print("  6. latex_tables.tex - Publication-ready LaTeX tables")
        print("\nReady for publication! 📊")

def main():
    if len(sys.argv) < 2:
        print("Usage: python analyze_comprehensive_evaluation.py <results_directory>")
        print("\nExample:")
        print("  python analyze_comprehensive_evaluation.py ./sdvn_evaluation_20251106_123456")
        sys.exit(1)
    
    results_dir = sys.argv[1]
    
    if not os.path.exists(results_dir):
        print(f"❌ Error: Results directory not found: {results_dir}")
        sys.exit(1)
    
    # Run analysis
    analyzer = SDVNComprehensiveAnalyzer(results_dir)
    analyzer.run_complete_analysis()

if __name__ == "__main__":
    main()

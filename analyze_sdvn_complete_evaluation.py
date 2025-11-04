#!/usr/bin/env python3
"""
SDVN Complete Security Evaluation Analyzer
Analyzes performance metrics from complete attack evaluation
Generates before/after mitigation comparisons and visualizations
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
import os
import sys
from pathlib import Path
from datetime import datetime

class SDVNEvaluationAnalyzer:
    def __init__(self, results_dir):
        self.results_dir = results_dir
        self.metrics = {}
        
        # Define test scenarios with grouping
        self.scenarios = {
            'baseline': {
                'id': 'test01_baseline',
                'name': 'Baseline',
                'attack': None,
                'mitigation': None
            },
            'wormhole': [
                {'id': 'test02_wormhole_10_no_mitigation', 'name': 'Wormhole No Mitigation', 'attack': 'Wormhole', 'mitigation': 'None'},
                {'id': 'test03_wormhole_10_with_detection', 'name': 'Wormhole Detection', 'attack': 'Wormhole', 'mitigation': 'Detection'},
                {'id': 'test04_wormhole_10_with_mitigation', 'name': 'Wormhole Full Mitigation', 'attack': 'Wormhole', 'mitigation': 'Full'}
            ],
            'blackhole': [
                {'id': 'test05_blackhole_10_no_mitigation', 'name': 'Blackhole No Mitigation', 'attack': 'Blackhole', 'mitigation': 'None'},
                {'id': 'test06_blackhole_10_with_detection', 'name': 'Blackhole Detection', 'attack': 'Blackhole', 'mitigation': 'Detection'},
                {'id': 'test07_blackhole_10_with_mitigation', 'name': 'Blackhole Full Mitigation', 'attack': 'Blackhole', 'mitigation': 'Full'}
            ],
            'sybil': [
                {'id': 'test08_sybil_10_no_mitigation', 'name': 'Sybil No Mitigation', 'attack': 'Sybil', 'mitigation': 'None'},
                {'id': 'test09_sybil_10_with_detection', 'name': 'Sybil Detection', 'attack': 'Sybil', 'mitigation': 'Detection'},
                {'id': 'test10_sybil_10_with_mitigation', 'name': 'Sybil Full Mitigation', 'attack': 'Sybil', 'mitigation': 'Full'}
            ],
            'replay': [
                {'id': 'test11_replay_10_no_mitigation', 'name': 'Replay No Mitigation', 'attack': 'Replay', 'mitigation': 'None'},
                {'id': 'test12_replay_10_with_detection', 'name': 'Replay Detection', 'attack': 'Replay', 'mitigation': 'Detection'},
                {'id': 'test13_replay_10_with_mitigation', 'name': 'Replay Full Mitigation', 'attack': 'Replay', 'mitigation': 'Full'}
            ],
            'rtp': [
                {'id': 'test14_rtp_10_no_mitigation', 'name': 'RTP No Mitigation', 'attack': 'RTP', 'mitigation': 'None'},
                {'id': 'test15_rtp_10_with_detection', 'name': 'RTP Detection', 'attack': 'RTP', 'mitigation': 'Detection'},
                {'id': 'test16_rtp_10_with_mitigation', 'name': 'RTP Full Mitigation', 'attack': 'RTP', 'mitigation': 'Full'}
            ],
            'combined': {
                'id': 'test17_combined_10_with_all_mitigations',
                'name': 'Combined All Mitigations',
                'attack': 'Combined',
                'mitigation': 'Full'
            }
        }
        
        # Set style
        sns.set_style("whitegrid")
        sns.set_palette("husl")
        
    def load_metrics(self):
        """Load all CSV metric files from test results"""
        print("Loading metric files from SDVN evaluation results...")
        print(f"Results directory: {self.results_dir}\n")
        
        # Load baseline
        baseline = self.scenarios['baseline']
        self._load_scenario_metrics(baseline['id'], baseline['name'])
        
        # Load attack groups
        for attack_type in ['wormhole', 'blackhole', 'sybil', 'replay', 'rtp']:
            for scenario in self.scenarios[attack_type]:
                self._load_scenario_metrics(scenario['id'], scenario['name'])
        
        # Load combined
        combined = self.scenarios['combined']
        self._load_scenario_metrics(combined['id'], combined['name'])
        
        if not self.metrics:
            print("\n⚠ No metric files loaded. Check directory structure.")
            return False
        
        print(f"\n✓ Successfully loaded {len(self.metrics)} scenario(s)")
        return True
    
    def _load_scenario_metrics(self, scenario_id, scenario_name):
        """Load metrics for a specific scenario"""
        scenario_dir = os.path.join(self.results_dir, scenario_id)
        
        if not os.path.exists(scenario_dir):
            print(f"  ⚠ Scenario directory not found: {scenario_id}")
            return
        
        # Try to find relevant CSV files
        csv_files = [f for f in os.listdir(scenario_dir) if f.endswith('.csv')]
        
        if not csv_files:
            print(f"  ⚠ No CSV files in: {scenario_id}")
            return
        
        # Prioritize packet delivery analysis
        primary_csv = None
        for csv_file in csv_files:
            if 'packet-delivery' in csv_file.lower() or 'analysis' in csv_file.lower():
                primary_csv = csv_file
                break
        
        if not primary_csv and csv_files:
            primary_csv = csv_files[0]
        
        if primary_csv:
            csv_path = os.path.join(scenario_dir, primary_csv)
            try:
                df = pd.read_csv(csv_path)
                self.metrics[scenario_name] = {
                    'data': df,
                    'files': csv_files,
                    'primary': primary_csv
                }
                print(f"  ✓ {scenario_name}: {primary_csv} ({len(df)} rows, {len(csv_files)} CSV files)")
            except Exception as e:
                print(f"  ✗ Error loading {scenario_name}: {e}")
    
    def calculate_summary_statistics(self):
        """Calculate summary statistics for all scenarios"""
        print("\nCalculating summary statistics...")
        
        summary_data = []
        
        for scenario_name, scenario_info in self.metrics.items():
            df = scenario_info['data']
            
            # Try to extract common metrics
            stats = {'Scenario': scenario_name}
            
            # Packet-related metrics
            if 'PacketsSent' in df.columns and 'PacketsReceived' in df.columns:
                total_sent = df['PacketsSent'].sum()
                total_received = df['PacketsReceived'].sum()
                stats['PDR (%)'] = (total_received / total_sent * 100) if total_sent > 0 else 0
                stats['Packets Sent'] = total_sent
                stats['Packets Received'] = total_received
                stats['Packet Loss'] = total_sent - total_received
            
            # Delay metrics
            if 'AverageDelay' in df.columns:
                stats['Avg Delay (ms)'] = df['AverageDelay'].mean()
            elif 'Delay' in df.columns:
                stats['Avg Delay (ms)'] = df['Delay'].mean()
            
            # Throughput metrics
            if 'Throughput' in df.columns:
                stats['Avg Throughput (kbps)'] = df['Throughput'].mean()
            
            # Attack-specific metrics
            if 'AttackDetected' in df.columns:
                stats['Attack Detection Rate (%)'] = df['AttackDetected'].sum() / len(df) * 100
            
            if 'MitigationActive' in df.columns:
                stats['Mitigation Active (%)'] = df['MitigationActive'].sum() / len(df) * 100
            
            summary_data.append(stats)
        
        self.summary_df = pd.DataFrame(summary_data)
        print(f"✓ Summary statistics calculated for {len(summary_data)} scenarios")
        
        return self.summary_df
    
    def generate_comparison_analysis(self):
        """Generate before/after mitigation comparison"""
        print("\nGenerating mitigation effectiveness analysis...")
        
        comparison_data = []
        
        for attack_type in ['wormhole', 'blackhole', 'sybil', 'replay', 'rtp']:
            scenarios = self.scenarios[attack_type]
            
            # Find no mitigation, detection, and full mitigation scenarios
            no_mitigation = None
            with_detection = None
            full_mitigation = None
            
            for scenario in scenarios:
                scenario_name = scenario['name']
                if scenario_name in self.metrics:
                    if scenario['mitigation'] == 'None':
                        no_mitigation = self.metrics[scenario_name]['data']
                    elif scenario['mitigation'] == 'Detection':
                        with_detection = self.metrics[scenario_name]['data']
                    elif scenario['mitigation'] == 'Full':
                        full_mitigation = self.metrics[scenario_name]['data']
            
            if no_mitigation is not None:
                comparison = {'Attack': attack_type.capitalize()}
                
                # Calculate PDR improvement
                if 'PacketsSent' in no_mitigation.columns:
                    no_mit_pdr = self._calculate_pdr(no_mitigation)
                    comparison['PDR No Mitigation (%)'] = no_mit_pdr
                    
                    if with_detection is not None:
                        det_pdr = self._calculate_pdr(with_detection)
                        comparison['PDR With Detection (%)'] = det_pdr
                        comparison['Detection Improvement (%)'] = det_pdr - no_mit_pdr
                    
                    if full_mitigation is not None:
                        full_pdr = self._calculate_pdr(full_mitigation)
                        comparison['PDR Full Mitigation (%)'] = full_pdr
                        comparison['Full Mitigation Improvement (%)'] = full_pdr - no_mit_pdr
                
                # Calculate delay improvement
                if 'AverageDelay' in no_mitigation.columns or 'Delay' in no_mitigation.columns:
                    delay_col = 'AverageDelay' if 'AverageDelay' in no_mitigation.columns else 'Delay'
                    no_mit_delay = no_mitigation[delay_col].mean()
                    comparison['Delay No Mitigation (ms)'] = no_mit_delay
                    
                    if full_mitigation is not None and delay_col in full_mitigation.columns:
                        full_delay = full_mitigation[delay_col].mean()
                        comparison['Delay Full Mitigation (ms)'] = full_delay
                        comparison['Delay Reduction (%)'] = ((no_mit_delay - full_delay) / no_mit_delay * 100) if no_mit_delay > 0 else 0
                
                comparison_data.append(comparison)
        
        self.comparison_df = pd.DataFrame(comparison_data)
        print(f"✓ Comparison analysis completed for {len(comparison_data)} attacks")
        
        return self.comparison_df
    
    def _calculate_pdr(self, df):
        """Calculate Packet Delivery Ratio from dataframe"""
        if 'PacketsSent' in df.columns and 'PacketsReceived' in df.columns:
            sent = df['PacketsSent'].sum()
            received = df['PacketsReceived'].sum()
            return (received / sent * 100) if sent > 0 else 0
        return 0
    
    def generate_visualizations(self):
        """Generate comprehensive visualizations"""
        print("\nGenerating visualizations...")
        
        output_dir = os.path.join(self.results_dir, 'analysis_output')
        os.makedirs(output_dir, exist_ok=True)
        
        # 1. PDR Comparison Chart
        self._plot_pdr_comparison(output_dir)
        
        # 2. Mitigation Effectiveness Chart
        self._plot_mitigation_effectiveness(output_dir)
        
        # 3. Attack Impact Analysis
        self._plot_attack_impact(output_dir)
        
        # 4. Overall Performance Comparison
        self._plot_overall_comparison(output_dir)
        
        print(f"✓ Visualizations saved to: {output_dir}")
    
    def _plot_pdr_comparison(self, output_dir):
        """Plot PDR comparison across all scenarios"""
        if not hasattr(self, 'summary_df') or 'PDR (%)' not in self.summary_df.columns:
            return
        
        plt.figure(figsize=(14, 6))
        
        # Filter scenarios with PDR data
        pdr_data = self.summary_df[self.summary_df['PDR (%)'].notna()]
        
        if len(pdr_data) == 0:
            return
        
        scenarios = pdr_data['Scenario']
        pdrs = pdr_data['PDR (%)']
        
        # Create bar plot
        bars = plt.bar(range(len(scenarios)), pdrs, color='skyblue', edgecolor='navy', alpha=0.7)
        
        # Color baseline differently
        if 'Baseline' in scenarios.values:
            baseline_idx = scenarios[scenarios == 'Baseline'].index[0]
            bars[list(scenarios.index).index(baseline_idx)].set_color('green')
            bars[list(scenarios.index).index(baseline_idx)].set_alpha(0.8)
        
        plt.xlabel('Test Scenario', fontsize=12, fontweight='bold')
        plt.ylabel('Packet Delivery Ratio (%)', fontsize=12, fontweight='bold')
        plt.title('SDVN Security Evaluation - Packet Delivery Ratio Comparison', fontsize=14, fontweight='bold')
        plt.xticks(range(len(scenarios)), scenarios, rotation=45, ha='right')
        plt.ylim(0, 105)
        plt.grid(axis='y', alpha=0.3)
        
        # Add value labels on bars
        for i, (idx, pdr) in enumerate(zip(scenarios.index, pdrs)):
            plt.text(i, pdr + 1, f'{pdr:.1f}%', ha='center', va='bottom', fontsize=9)
        
        plt.tight_layout()
        plt.savefig(os.path.join(output_dir, 'pdr_comparison.png'), dpi=300)
        plt.close()
        print("  ✓ PDR comparison chart saved")
    
    def _plot_mitigation_effectiveness(self, output_dir):
        """Plot mitigation effectiveness for each attack"""
        if not hasattr(self, 'comparison_df'):
            return
        
        plt.figure(figsize=(12, 6))
        
        attacks = self.comparison_df['Attack']
        x = np.arange(len(attacks))
        width = 0.35
        
        # Get PDR data
        no_mit = self.comparison_df.get('PDR No Mitigation (%)', pd.Series([0]*len(attacks)))
        full_mit = self.comparison_df.get('PDR Full Mitigation (%)', pd.Series([0]*len(attacks)))
        
        # Create grouped bar plot
        plt.bar(x - width/2, no_mit, width, label='No Mitigation', color='coral', alpha=0.8)
        plt.bar(x + width/2, full_mit, width, label='Full Mitigation', color='lightgreen', alpha=0.8)
        
        plt.xlabel('Attack Type', fontsize=12, fontweight='bold')
        plt.ylabel('Packet Delivery Ratio (%)', fontsize=12, fontweight='bold')
        plt.title('Mitigation Effectiveness - Before vs After', fontsize=14, fontweight='bold')
        plt.xticks(x, attacks)
        plt.legend()
        plt.ylim(0, 105)
        plt.grid(axis='y', alpha=0.3)
        
        # Add improvement percentage annotations
        for i, (no, full) in enumerate(zip(no_mit, full_mit)):
            if no > 0:
                improvement = full - no
                plt.text(i, max(no, full) + 2, f'+{improvement:.1f}%', 
                        ha='center', va='bottom', fontsize=9, fontweight='bold', color='green')
        
        plt.tight_layout()
        plt.savefig(os.path.join(output_dir, 'mitigation_effectiveness.png'), dpi=300)
        plt.close()
        print("  ✓ Mitigation effectiveness chart saved")
    
    def _plot_attack_impact(self, output_dir):
        """Plot attack impact on network performance"""
        if not hasattr(self, 'summary_df'):
            return
        
        fig, axes = plt.subplots(1, 2, figsize=(14, 5))
        
        # Packet Loss comparison
        if 'Packet Loss' in self.summary_df.columns:
            ax = axes[0]
            packet_loss_data = self.summary_df[self.summary_df['Packet Loss'].notna()]
            
            if len(packet_loss_data) > 0:
                scenarios = packet_loss_data['Scenario']
                losses = packet_loss_data['Packet Loss']
                
                bars = ax.bar(range(len(scenarios)), losses, color='tomato', alpha=0.7)
                ax.set_xlabel('Scenario', fontsize=10, fontweight='bold')
                ax.set_ylabel('Packet Loss', fontsize=10, fontweight='bold')
                ax.set_title('Packet Loss Across Scenarios', fontsize=12, fontweight='bold')
                ax.set_xticks(range(len(scenarios)))
                ax.set_xticklabels(scenarios, rotation=45, ha='right', fontsize=8)
                ax.grid(axis='y', alpha=0.3)
        
        # Delay comparison
        if 'Avg Delay (ms)' in self.summary_df.columns:
            ax = axes[1]
            delay_data = self.summary_df[self.summary_df['Avg Delay (ms)'].notna()]
            
            if len(delay_data) > 0:
                scenarios = delay_data['Scenario']
                delays = delay_data['Avg Delay (ms)']
                
                bars = ax.bar(range(len(scenarios)), delays, color='gold', alpha=0.7)
                ax.set_xlabel('Scenario', fontsize=10, fontweight='bold')
                ax.set_ylabel('Average Delay (ms)', fontsize=10, fontweight='bold')
                ax.set_title('Average Delay Across Scenarios', fontsize=12, fontweight='bold')
                ax.set_xticks(range(len(scenarios)))
                ax.set_xticklabels(scenarios, rotation=45, ha='right', fontsize=8)
                ax.grid(axis='y', alpha=0.3)
        
        plt.tight_layout()
        plt.savefig(os.path.join(output_dir, 'attack_impact.png'), dpi=300)
        plt.close()
        print("  ✓ Attack impact chart saved")
    
    def _plot_overall_comparison(self, output_dir):
        """Plot overall performance comparison"""
        if not hasattr(self, 'comparison_df'):
            return
        
        fig, ax = plt.subplots(figsize=(10, 6))
        
        attacks = self.comparison_df['Attack']
        improvements = self.comparison_df.get('Full Mitigation Improvement (%)', pd.Series([0]*len(attacks)))
        
        # Create bar plot
        colors = ['green' if x > 0 else 'red' for x in improvements]
        bars = ax.barh(attacks, improvements, color=colors, alpha=0.7)
        
        ax.set_xlabel('PDR Improvement (%)', fontsize=12, fontweight='bold')
        ax.set_ylabel('Attack Type', fontsize=12, fontweight='bold')
        ax.set_title('Overall Mitigation Improvement by Attack Type', fontsize=14, fontweight='bold')
        ax.axvline(x=0, color='black', linestyle='-', linewidth=0.5)
        ax.grid(axis='x', alpha=0.3)
        
        # Add value labels
        for i, (attack, improvement) in enumerate(zip(attacks, improvements)):
            ax.text(improvement + 0.5, i, f'{improvement:.1f}%', 
                   va='center', fontsize=10, fontweight='bold')
        
        plt.tight_layout()
        plt.savefig(os.path.join(output_dir, 'overall_improvement.png'), dpi=300)
        plt.close()
        print("  ✓ Overall improvement chart saved")
    
    def generate_latex_table(self):
        """Generate LaTeX table for research papers"""
        print("\nGenerating LaTeX tables...")
        
        output_dir = os.path.join(self.results_dir, 'analysis_output')
        os.makedirs(output_dir, exist_ok=True)
        
        try:
            # Summary statistics table
            if hasattr(self, 'summary_df'):
                latex_file = os.path.join(output_dir, 'summary_table.tex')
                with open(latex_file, 'w') as f:
                    f.write("% SDVN Security Evaluation - Summary Statistics\n")
                    # Use to_string() as fallback if jinja2 not available
                    try:
                        f.write(self.summary_df.to_latex(index=False, float_format='%.2f'))
                    except ImportError:
                        f.write("% Note: Install jinja2 for proper LaTeX formatting\n")
                        f.write("% pip install jinja2\n\n")
                        f.write(self.summary_df.to_string())
                print(f"  ✓ Summary table saved: summary_table.tex")
            
            # Comparison table
            if hasattr(self, 'comparison_df'):
                latex_file = os.path.join(output_dir, 'comparison_table.tex')
                with open(latex_file, 'w') as f:
                    f.write("% SDVN Security Evaluation - Mitigation Comparison\n")
                    try:
                        f.write(self.comparison_df.to_latex(index=False, float_format='%.2f'))
                    except ImportError:
                        f.write("% Note: Install jinja2 for proper LaTeX formatting\n")
                        f.write("% pip install jinja2\n\n")
                        f.write(self.comparison_df.to_string())
                print(f"  ✓ Comparison table saved: comparison_table.tex")
        except Exception as e:
            print(f"  ⚠ Warning: LaTeX table generation had issues: {e}")
            print(f"  → Install jinja2: pip install jinja2")
    
    def generate_report(self):
        """Generate comprehensive analysis report"""
        print("\nGenerating analysis report...")
        
        output_dir = os.path.join(self.results_dir, 'analysis_output')
        os.makedirs(output_dir, exist_ok=True)
        
        report_file = os.path.join(output_dir, 'analysis_report.txt')
        
        with open(report_file, 'w') as f:
            f.write("═" * 70 + "\n")
            f.write("SDVN COMPLETE SECURITY EVALUATION - ANALYSIS REPORT\n")
            f.write("═" * 70 + "\n\n")
            
            f.write(f"Analysis Date: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
            f.write(f"Results Directory: {self.results_dir}\n")
            f.write(f"Total Scenarios Analyzed: {len(self.metrics)}\n\n")
            
            f.write("─" * 70 + "\n")
            f.write("SUMMARY STATISTICS\n")
            f.write("─" * 70 + "\n\n")
            
            if hasattr(self, 'summary_df'):
                f.write(self.summary_df.to_string(index=False))
                f.write("\n\n")
            
            f.write("─" * 70 + "\n")
            f.write("MITIGATION EFFECTIVENESS ANALYSIS\n")
            f.write("─" * 70 + "\n\n")
            
            if hasattr(self, 'comparison_df'):
                f.write(self.comparison_df.to_string(index=False))
                f.write("\n\n")
            
            f.write("─" * 70 + "\n")
            f.write("KEY FINDINGS\n")
            f.write("─" * 70 + "\n\n")
            
            # Calculate key findings
            if hasattr(self, 'comparison_df'):
                f.write("Attack Mitigation Performance:\n")
                for _, row in self.comparison_df.iterrows():
                    attack = row['Attack']
                    if 'Full Mitigation Improvement (%)' in row:
                        improvement = row['Full Mitigation Improvement (%)']
                        f.write(f"  • {attack}: {improvement:.1f}% PDR improvement\n")
                f.write("\n")
            
            f.write("Mitigation Solutions Tested:\n")
            f.write("  1. Wormhole: RTT-based detection + route isolation\n")
            f.write("  2. Blackhole: Traffic pattern analysis + node isolation\n")
            f.write("  3. Sybil: Identity verification + MAC validation\n")
            f.write("  4. Replay: Bloom Filter sequence tracking + packet rejection\n")
            f.write("  5. RTP: Hybrid-Shield topology verification + route validation\n\n")
            
            f.write("═" * 70 + "\n")
            f.write("END OF REPORT\n")
            f.write("═" * 70 + "\n")
        
        print(f"✓ Analysis report saved: {report_file}")
    
    def run_complete_analysis(self):
        """Run complete analysis pipeline"""
        print("\n" + "="*70)
        print("SDVN COMPLETE SECURITY EVALUATION - ANALYSIS")
        print("="*70 + "\n")
        
        # Load metrics
        if not self.load_metrics():
            print("\n✗ Failed to load metrics. Exiting.")
            return False
        
        # Calculate statistics
        self.calculate_summary_statistics()
        
        # Generate comparison
        self.generate_comparison_analysis()
        
        # Generate visualizations
        self.generate_visualizations()
        
        # Generate LaTeX tables
        self.generate_latex_table()
        
        # Generate report
        self.generate_report()
        
        print("\n" + "="*70)
        print("✓ ANALYSIS COMPLETE")
        print("="*70)
        print(f"\nResults saved to: {os.path.join(self.results_dir, 'analysis_output')}")
        print("\nGenerated files:")
        print("  • pdr_comparison.png")
        print("  • mitigation_effectiveness.png")
        print("  • attack_impact.png")
        print("  • overall_improvement.png")
        print("  • summary_table.tex")
        print("  • comparison_table.tex")
        print("  • analysis_report.txt")
        
        return True


def main():
    if len(sys.argv) < 2:
        print("Usage: python3 analyze_sdvn_complete_evaluation.py <results_directory>")
        print("\nExample:")
        print("  python3 analyze_sdvn_complete_evaluation.py ./sdvn_evaluation_20250104_120000")
        sys.exit(1)
    
    results_dir = sys.argv[1]
    
    if not os.path.exists(results_dir):
        print(f"✗ Error: Results directory not found: {results_dir}")
        sys.exit(1)
    
    analyzer = SDVNEvaluationAnalyzer(results_dir)
    success = analyzer.run_complete_analysis()
    
    sys.exit(0 if success else 1)


if __name__ == '__main__':
    main()

"""
VANET Packet Delivery Analysis and Visualization Tool
======================================================

This script analyzes packet-delivery-analysis.csv generated from ns-3 routing simulation
and creates comprehensive visualizations for research paper analysis.

Author: VANET Security Research
Date: October 2025
"""

import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import numpy as np
from pathlib import Path
import warnings
warnings.filterwarnings('ignore')

# Set style for publication-quality plots
sns.set_style("whitegrid")
plt.rcParams['figure.figsize'] = (12, 8)
plt.rcParams['font.size'] = 11
plt.rcParams['axes.labelsize'] = 12
plt.rcParams['axes.titlesize'] = 14
plt.rcParams['xtick.labelsize'] = 10
plt.rcParams['ytick.labelsize'] = 10
plt.rcParams['legend.fontsize'] = 10

class PacketAnalyzer:
    """Analyzes packet delivery data from VANET simulation"""
    
    def __init__(self, csv_file):
        """Initialize analyzer with CSV file path"""
        self.csv_file = csv_file
        self.df = None
        self.metrics = {}
        
    def load_data(self):
        """Load and validate CSV data"""
        try:
            self.df = pd.read_csv(self.csv_file)
            print(f"✅ Loaded {len(self.df)} packet records from {self.csv_file}")
            print(f"   Columns: {list(self.df.columns)}")
            return True
        except FileNotFoundError:
            print(f"❌ Error: File '{self.csv_file}' not found!")
            print("   Please run the simulation first to generate the CSV file.")
            return False
        except Exception as e:
            print(f"❌ Error loading file: {e}")
            return False
    
    def calculate_metrics(self):
        """Calculate key performance metrics"""
        if self.df is None:
            print("❌ No data loaded!")
            return
        
        total_packets = len(self.df)
        delivered_packets = self.df['Delivered'].sum()
        dropped_packets = total_packets - delivered_packets
        
        self.metrics = {
            'Total Packets': total_packets,
            'Delivered Packets': delivered_packets,
            'Dropped Packets': dropped_packets,
            'Packet Delivery Ratio (%)': (delivered_packets / total_packets) * 100 if total_packets > 0 else 0,
            'Average Delay (ms)': self.df[self.df['Delivered'] == 1]['DelayMs'].mean(),
            'Min Delay (ms)': self.df[self.df['Delivered'] == 1]['DelayMs'].min(),
            'Max Delay (ms)': self.df[self.df['Delivered'] == 1]['DelayMs'].max(),
            'Std Delay (ms)': self.df[self.df['Delivered'] == 1]['DelayMs'].std(),
            'Wormhole Affected Packets': self.df['WormholeOnPath'].sum(),
            'Blackhole Affected Packets': self.df['BlackholeOnPath'].sum(),
            'Wormhole Impact (%)': (self.df['WormholeOnPath'].sum() / total_packets) * 100,
            'Blackhole Impact (%)': (self.df['BlackholeOnPath'].sum() / total_packets) * 100,
        }
        
        # Additional metrics for attacked packets
        wormhole_packets = self.df[self.df['WormholeOnPath'] == 1]
        blackhole_packets = self.df[self.df['BlackholeOnPath'] == 1]
        normal_packets = self.df[(self.df['WormholeOnPath'] == 0) & (self.df['BlackholeOnPath'] == 0)]
        
        if len(wormhole_packets) > 0:
            self.metrics['Wormhole PDR (%)'] = (wormhole_packets['Delivered'].sum() / len(wormhole_packets)) * 100
            delivered_wormhole = wormhole_packets[wormhole_packets['Delivered'] == 1]
            if len(delivered_wormhole) > 0:
                self.metrics['Avg Delay - Wormhole (ms)'] = delivered_wormhole['DelayMs'].mean()
        
        if len(blackhole_packets) > 0:
            self.metrics['Blackhole PDR (%)'] = (blackhole_packets['Delivered'].sum() / len(blackhole_packets)) * 100
            delivered_blackhole = blackhole_packets[blackhole_packets['Delivered'] == 1]
            if len(delivered_blackhole) > 0:
                self.metrics['Avg Delay - Blackhole (ms)'] = delivered_blackhole['DelayMs'].mean()
        
        if len(normal_packets) > 0:
            self.metrics['Normal PDR (%)'] = (normal_packets['Delivered'].sum() / len(normal_packets)) * 100
            delivered_normal = normal_packets[normal_packets['Delivered'] == 1]
            if len(delivered_normal) > 0:
                self.metrics['Avg Delay - Normal (ms)'] = delivered_normal['DelayMs'].mean()
    
    def print_summary(self):
        """Print summary statistics"""
        print("\n" + "="*70)
        print("📊 PACKET DELIVERY ANALYSIS SUMMARY")
        print("="*70)
        
        for metric, value in self.metrics.items():
            if isinstance(value, float):
                print(f"  {metric:.<50} {value:>10.2f}")
            else:
                print(f"  {metric:.<50} {value:>10}")
        
        print("="*70 + "\n")
    
    def plot_pdr_comparison(self, output_dir='plots'):
        """Plot PDR comparison between normal, wormhole, and blackhole packets"""
        Path(output_dir).mkdir(exist_ok=True)
        
        categories = []
        pdr_values = []
        colors = []
        
        if 'Normal PDR (%)' in self.metrics:
            categories.append('Normal\nPackets')
            pdr_values.append(self.metrics['Normal PDR (%)'])
            colors.append('#2ecc71')  # Green
        
        if 'Wormhole PDR (%)' in self.metrics:
            categories.append('Wormhole\nAffected')
            pdr_values.append(self.metrics['Wormhole PDR (%)'])
            colors.append('#e74c3c')  # Red
        
        if 'Blackhole PDR (%)' in self.metrics:
            categories.append('Blackhole\nAffected')
            pdr_values.append(self.metrics['Blackhole PDR (%)'])
            colors.append('#e67e22')  # Orange
        
        if 'Packet Delivery Ratio (%)' in self.metrics:
            categories.append('Overall')
            pdr_values.append(self.metrics['Packet Delivery Ratio (%)'])
            colors.append('#3498db')  # Blue
        
        fig, ax = plt.subplots(figsize=(10, 6))
        bars = ax.bar(categories, pdr_values, color=colors, alpha=0.8, edgecolor='black', linewidth=1.5)
        
        # Add value labels on bars
        for bar in bars:
            height = bar.get_height()
            ax.text(bar.get_x() + bar.get_width()/2., height,
                   f'{height:.1f}%',
                   ha='center', va='bottom', fontweight='bold', fontsize=12)
        
        ax.set_ylabel('Packet Delivery Ratio (%)', fontweight='bold')
        ax.set_title('PDR Comparison: Normal vs Attack-Affected Packets', fontweight='bold', pad=20)
        ax.set_ylim(0, 110)
        ax.grid(axis='y', alpha=0.3)
        
        plt.tight_layout()
        plt.savefig(f'{output_dir}/pdr_comparison.png', dpi=300, bbox_inches='tight')
        print(f"✅ Saved: {output_dir}/pdr_comparison.png")
        plt.close()
    
    def plot_delay_comparison(self, output_dir='plots'):
        """Plot delay comparison between different packet types"""
        Path(output_dir).mkdir(exist_ok=True)
        
        categories = []
        delay_values = []
        colors = []
        
        if 'Avg Delay - Normal (ms)' in self.metrics:
            categories.append('Normal\nPackets')
            delay_values.append(self.metrics['Avg Delay - Normal (ms)'])
            colors.append('#2ecc71')
        
        if 'Avg Delay - Wormhole (ms)' in self.metrics:
            categories.append('Wormhole\nAffected')
            delay_values.append(self.metrics['Avg Delay - Wormhole (ms)'])
            colors.append('#e74c3c')
        
        if 'Avg Delay - Blackhole (ms)' in self.metrics:
            categories.append('Blackhole\nAffected')
            delay_values.append(self.metrics['Avg Delay - Blackhole (ms)'])
            colors.append('#e67e22')
        
        if 'Average Delay (ms)' in self.metrics:
            categories.append('Overall')
            delay_values.append(self.metrics['Average Delay (ms)'])
            colors.append('#3498db')
        
        fig, ax = plt.subplots(figsize=(10, 6))
        bars = ax.bar(categories, delay_values, color=colors, alpha=0.8, edgecolor='black', linewidth=1.5)
        
        for bar in bars:
            height = bar.get_height()
            ax.text(bar.get_x() + bar.get_width()/2., height,
                   f'{height:.2f}ms',
                   ha='center', va='bottom', fontweight='bold', fontsize=11)
        
        ax.set_ylabel('Average End-to-End Delay (ms)', fontweight='bold')
        ax.set_title('Delay Comparison: Normal vs Attack-Affected Packets', fontweight='bold', pad=20)
        ax.grid(axis='y', alpha=0.3)
        
        plt.tight_layout()
        plt.savefig(f'{output_dir}/delay_comparison.png', dpi=300, bbox_inches='tight')
        print(f"✅ Saved: {output_dir}/delay_comparison.png")
        plt.close()
    
    def plot_delay_distribution(self, output_dir='plots'):
        """Plot delay distribution histogram with attack indicators"""
        Path(output_dir).mkdir(exist_ok=True)
        
        delivered = self.df[self.df['Delivered'] == 1]
        
        fig, ax = plt.subplots(figsize=(12, 6))
        
        # Plot histograms for different packet types
        normal = delivered[(delivered['WormholeOnPath'] == 0) & (delivered['BlackholeOnPath'] == 0)]
        wormhole = delivered[delivered['WormholeOnPath'] == 1]
        blackhole = delivered[delivered['BlackholeOnPath'] == 1]
        
        bins = np.linspace(0, delivered['DelayMs'].max(), 50)
        
        if len(normal) > 0:
            ax.hist(normal['DelayMs'], bins=bins, alpha=0.5, label='Normal', color='#2ecc71', edgecolor='black')
        if len(wormhole) > 0:
            ax.hist(wormhole['DelayMs'], bins=bins, alpha=0.5, label='Wormhole', color='#e74c3c', edgecolor='black')
        if len(blackhole) > 0:
            ax.hist(blackhole['DelayMs'], bins=bins, alpha=0.5, label='Blackhole', color='#e67e22', edgecolor='black')
        
        ax.set_xlabel('End-to-End Delay (ms)', fontweight='bold')
        ax.set_ylabel('Frequency', fontweight='bold')
        ax.set_title('Delay Distribution by Packet Type', fontweight='bold', pad=20)
        ax.legend()
        ax.grid(axis='y', alpha=0.3)
        
        plt.tight_layout()
        plt.savefig(f'{output_dir}/delay_distribution.png', dpi=300, bbox_inches='tight')
        print(f"✅ Saved: {output_dir}/delay_distribution.png")
        plt.close()
    
    def plot_packet_timeline(self, output_dir='plots'):
        """Plot packet delivery over time"""
        Path(output_dir).mkdir(exist_ok=True)
        
        # Create time bins
        time_bins = pd.cut(self.df['SendTime'], bins=20)
        
        # Calculate PDR per time bin
        pdr_over_time = self.df.groupby(time_bins)['Delivered'].mean() * 100
        time_labels = [f"{interval.left:.1f}-{interval.right:.1f}" for interval in pdr_over_time.index]
        
        fig, ax = plt.subplots(figsize=(14, 6))
        ax.plot(range(len(pdr_over_time)), pdr_over_time.values, marker='o', linewidth=2, 
                markersize=8, color='#3498db', markerfacecolor='#e74c3c', markeredgecolor='black')
        
        ax.set_xlabel('Simulation Time (seconds)', fontweight='bold')
        ax.set_ylabel('Packet Delivery Ratio (%)', fontweight='bold')
        ax.set_title('PDR Over Simulation Time', fontweight='bold', pad=20)
        ax.set_xticks(range(len(time_labels)))
        ax.set_xticklabels(time_labels, rotation=45, ha='right')
        ax.grid(alpha=0.3)
        ax.set_ylim(0, 110)
        
        plt.tight_layout()
        plt.savefig(f'{output_dir}/pdr_timeline.png', dpi=300, bbox_inches='tight')
        print(f"✅ Saved: {output_dir}/pdr_timeline.png")
        plt.close()
    
    def plot_attack_impact(self, output_dir='plots'):
        """Plot attack impact pie chart"""
        Path(output_dir).mkdir(exist_ok=True)
        
        wormhole_count = self.df['WormholeOnPath'].sum()
        blackhole_count = self.df['BlackholeOnPath'].sum()
        normal_count = len(self.df) - wormhole_count - blackhole_count
        
        fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(14, 6))
        
        # Pie chart 1: Packet distribution
        labels1 = ['Normal', 'Wormhole', 'Blackhole']
        sizes1 = [normal_count, wormhole_count, blackhole_count]
        colors1 = ['#2ecc71', '#e74c3c', '#e67e22']
        explode1 = (0.05, 0.1, 0.1)
        
        ax1.pie(sizes1, explode=explode1, labels=labels1, colors=colors1, autopct='%1.1f%%',
                shadow=True, startangle=90, textprops={'fontsize': 12, 'fontweight': 'bold'})
        ax1.set_title('Packet Distribution by Attack Type', fontweight='bold', pad=20)
        
        # Pie chart 2: Delivery status
        delivered = self.df['Delivered'].sum()
        dropped = len(self.df) - delivered
        
        labels2 = ['Delivered', 'Dropped']
        sizes2 = [delivered, dropped]
        colors2 = ['#2ecc71', '#e74c3c']
        explode2 = (0.05, 0.1)
        
        ax2.pie(sizes2, explode=explode2, labels=labels2, colors=colors2, autopct='%1.1f%%',
                shadow=True, startangle=90, textprops={'fontsize': 12, 'fontweight': 'bold'})
        ax2.set_title('Overall Packet Delivery Status', fontweight='bold', pad=20)
        
        plt.tight_layout()
        plt.savefig(f'{output_dir}/attack_impact_pie.png', dpi=300, bbox_inches='tight')
        print(f"✅ Saved: {output_dir}/attack_impact_pie.png")
        plt.close()
    
    def plot_node_communication_matrix(self, output_dir='plots'):
        """Plot source-destination communication heatmap"""
        Path(output_dir).mkdir(exist_ok=True)
        
        # Create communication matrix
        comm_matrix = self.df.groupby(['SourceNode', 'DestNode']).size().reset_index(name='Count')
        pivot = comm_matrix.pivot(index='SourceNode', columns='DestNode', values='Count').fillna(0)
        
        fig, ax = plt.subplots(figsize=(12, 10))
        sns.heatmap(pivot, annot=False, cmap='YlOrRd', cbar_kws={'label': 'Packet Count'}, ax=ax)
        
        ax.set_xlabel('Destination Node', fontweight='bold')
        ax.set_ylabel('Source Node', fontweight='bold')
        ax.set_title('Node-to-Node Communication Matrix', fontweight='bold', pad=20)
        
        plt.tight_layout()
        plt.savefig(f'{output_dir}/communication_matrix.png', dpi=300, bbox_inches='tight')
        print(f"✅ Saved: {output_dir}/communication_matrix.png")
        plt.close()
    
    def plot_delay_boxplot(self, output_dir='plots'):
        """Plot delay box plot comparing packet types"""
        Path(output_dir).mkdir(exist_ok=True)
        
        delivered = self.df[self.df['Delivered'] == 1].copy()
        
        # Create packet type labels
        delivered['PacketType'] = 'Normal'
        delivered.loc[delivered['WormholeOnPath'] == 1, 'PacketType'] = 'Wormhole'
        delivered.loc[delivered['BlackholeOnPath'] == 1, 'PacketType'] = 'Blackhole'
        
        fig, ax = plt.subplots(figsize=(10, 6))
        
        # Create box plot
        box_data = [
            delivered[delivered['PacketType'] == 'Normal']['DelayMs'],
            delivered[delivered['PacketType'] == 'Wormhole']['DelayMs'],
            delivered[delivered['PacketType'] == 'Blackhole']['DelayMs']
        ]
        
        bp = ax.boxplot(box_data, labels=['Normal', 'Wormhole', 'Blackhole'],
                        patch_artist=True, showmeans=True)
        
        colors = ['#2ecc71', '#e74c3c', '#e67e22']
        for patch, color in zip(bp['boxes'], colors):
            patch.set_facecolor(color)
            patch.set_alpha(0.7)
        
        ax.set_ylabel('End-to-End Delay (ms)', fontweight='bold')
        ax.set_title('Delay Distribution Box Plot by Packet Type', fontweight='bold', pad=20)
        ax.grid(axis='y', alpha=0.3)
        
        plt.tight_layout()
        plt.savefig(f'{output_dir}/delay_boxplot.png', dpi=300, bbox_inches='tight')
        print(f"✅ Saved: {output_dir}/delay_boxplot.png")
        plt.close()
    
    def export_metrics_csv(self, output_file='analysis_metrics.csv'):
        """Export calculated metrics to CSV"""
        metrics_df = pd.DataFrame(list(self.metrics.items()), columns=['Metric', 'Value'])
        metrics_df.to_csv(output_file, index=False)
        print(f"✅ Metrics exported to: {output_file}")
    
    def export_latex_table(self, output_file='metrics_table.tex'):
        """Export metrics as LaTeX table for research paper"""
        with open(output_file, 'w') as f:
            f.write("\\begin{table}[htbp]\n")
            f.write("\\centering\n")
            f.write("\\caption{Packet Delivery Analysis Metrics}\n")
            f.write("\\begin{tabular}{|l|r|}\n")
            f.write("\\hline\n")
            f.write("\\textbf{Metric} & \\textbf{Value} \\\\\n")
            f.write("\\hline\n")
            
            for metric, value in self.metrics.items():
                if isinstance(value, float):
                    f.write(f"{metric} & {value:.2f} \\\\\n")
                else:
                    f.write(f"{metric} & {value} \\\\\n")
            
            f.write("\\hline\n")
            f.write("\\end{tabular}\n")
            f.write("\\label{tab:metrics}\n")
            f.write("\\end{table}\n")
        
        print(f"✅ LaTeX table exported to: {output_file}")
    
    def generate_all_plots(self, output_dir='plots'):
        """Generate all visualization plots"""
        print("\n📊 Generating all plots...")
        print("-" * 70)
        
        self.plot_pdr_comparison(output_dir)
        self.plot_delay_comparison(output_dir)
        self.plot_delay_distribution(output_dir)
        self.plot_packet_timeline(output_dir)
        self.plot_attack_impact(output_dir)
        self.plot_node_communication_matrix(output_dir)
        self.plot_delay_boxplot(output_dir)
        
        print("-" * 70)
        print(f"✅ All plots saved to '{output_dir}/' directory\n")


def main():
    """Main execution function"""
    print("\n" + "="*70)
    print("🚗 VANET Packet Delivery Analysis Tool")
    print("="*70 + "\n")
    
    # Initialize analyzer
    csv_file = 'packet-delivery-analysis.csv'
    analyzer = PacketAnalyzer(csv_file)
    
    # Load data
    if not analyzer.load_data():
        print("\n💡 TIP: Run the simulation first:")
        print("   ./waf --run \"routing --enable_packet_tracking --simTime=10\"\n")
        return
    
    # Calculate metrics
    print("\n📈 Calculating metrics...")
    analyzer.calculate_metrics()
    
    # Print summary
    analyzer.print_summary()
    
    # Generate visualizations
    analyzer.generate_all_plots('plots')
    
    # Export results
    print("📄 Exporting results...")
    analyzer.export_metrics_csv('analysis_metrics.csv')
    analyzer.export_latex_table('metrics_table.tex')
    
    print("\n" + "="*70)
    print("✅ Analysis Complete!")
    print("="*70)
    print("\n📁 Generated Files:")
    print("   📊 Plots: plots/*.png (7 visualization files)")
    print("   📈 Metrics: analysis_metrics.csv")
    print("   📄 LaTeX Table: metrics_table.tex")
    print("\n💡 Use these files in your research paper!\n")


if __name__ == "__main__":
    main()

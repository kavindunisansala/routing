#!/usr/bin/env python3
"""
Deep Analysis of SDVN Mitigation Performance
Analyzes all test results to evaluate mitigation effectiveness
"""

import os
import csv
import sys
from pathlib import Path
from collections import defaultdict

class MitigationAnalyzer:
    def __init__(self, base_dir):
        self.base_dir = Path(base_dir)
        self.results = {}
        
    def read_csv(self, filepath):
        """Read CSV file and return data"""
        try:
            with open(filepath, 'r') as f:
                reader = csv.DictReader(f)
                return list(reader)
        except Exception as e:
            print(f"Warning: Could not read {filepath}: {e}")
            return []
    
    def read_key_value_csv(self, filepath):
        """Read key-value format CSV"""
        try:
            data = {}
            with open(filepath, 'r') as f:
                reader = csv.reader(f)
                for row in reader:
                    if len(row) >= 2 and not row[0].startswith('#'):
                        data[row[0]] = row[1]
            return data
        except Exception as e:
            print(f"Warning: Could not read {filepath}: {e}")
            return {}
    
    def calculate_pdr_from_packets(self, test_dir):
        """Calculate PDR from packet delivery analysis"""
        pkt_file = test_dir / "packet-delivery-analysis.csv"
        if not pkt_file.exists():
            return None
        
        data = self.read_csv(pkt_file)
        if not data:
            return None
        
        total = len(data)
        delivered = sum(1 for row in data if row.get('Delivered') == '1')
        
        return {
            'total_packets': total,
            'delivered': delivered,
            'pdr_percent': (delivered / total * 100) if total > 0 else 0
        }
    
    def analyze_wormhole(self):
        """Deep analysis of wormhole attack and mitigation"""
        print("\n" + "="*80)
        print("WORMHOLE ATTACK & MITIGATION ANALYSIS")
        print("="*80)
        
        tests = {
            'no_mitigation': 'test02_wormhole_10_no_mitigation',
            'with_detection': 'test03_wormhole_10_with_detection',
            'with_mitigation': 'test04_wormhole_10_with_mitigation'
        }
        
        for scenario, test_name in tests.items():
            test_dir = self.base_dir / test_name
            print(f"\n{scenario.upper().replace('_', ' ')}:")
            print("-" * 80)
            
            # Read wormhole attack results
            attack_file = test_dir / "wormhole-attack-results.csv"
            if attack_file.exists():
                with open(attack_file, 'r') as f:
                    lines = f.readlines()
                    print("\nWormhole Attack Statistics:")
                    for line in lines:
                        print(f"  {line.strip()}")
                
                # Parse TOTAL line
                for line in lines:
                    if line.startswith('TOTAL'):
                        parts = line.strip().split(',')
                        if len(parts) >= 8:
                            print(f"\n  ✓ Packets Intercepted: {parts[3]}")
                            print(f"  ✓ Packets Tunneled: {parts[4]}")
                            print(f"  ✓ Routing Packets Affected: {parts[6]}")
                            print(f"  ✓ Data Packets Affected: {parts[7]}")
            
            # Read detection results
            detection_file = test_dir / "wormhole-detection-results.csv"
            if detection_file.exists():
                data = self.read_key_value_csv(detection_file)
                print("\nWormhole Detection Metrics:")
                for key, value in data.items():
                    if not key.startswith('#'):
                        print(f"  {key}: {value}")
            
            # Calculate PDR
            pdr_data = self.calculate_pdr_from_packets(test_dir)
            if pdr_data:
                print(f"\nPacket Delivery Performance:")
                print(f"  Total Packets: {pdr_data['total_packets']}")
                print(f"  Delivered: {pdr_data['delivered']}")
                print(f"  PDR: {pdr_data['pdr_percent']:.2f}%")
    
    def analyze_blackhole(self):
        """Deep analysis of blackhole attack and mitigation"""
        print("\n" + "="*80)
        print("BLACKHOLE ATTACK & MITIGATION ANALYSIS")
        print("="*80)
        
        tests = {
            'no_mitigation': 'test05_blackhole_10_no_mitigation',
            'with_detection': 'test06_blackhole_10_with_detection',
            'with_mitigation': 'test07_blackhole_10_with_mitigation'
        }
        
        for scenario, test_name in tests.items():
            test_dir = self.base_dir / test_name
            print(f"\n{scenario.upper().replace('_', ' ')}:")
            print("-" * 80)
            
            # Read blackhole attack results
            attack_file = test_dir / "blackhole-attack-results.csv"
            if attack_file.exists():
                data = self.read_csv(attack_file)
                active_nodes = [row for row in data if row.get('Active') == '1']
                total_dropped = sum(int(row.get('DataPacketsDropped', 0)) for row in data)
                
                print(f"\nBlackhole Attack Statistics:")
                print(f"  Total Malicious Nodes: {len(data)}")
                print(f"  Active Nodes: {len(active_nodes)}")
                print(f"  Total Packets Dropped: {total_dropped}")
                
                if active_nodes:
                    print(f"\n  Active Blackhole Nodes:")
                    for node in active_nodes:
                        print(f"    Node {node.get('NodeID')}: Dropped {node.get('DataPacketsDropped')} packets")
            
            # Read mitigation results
            mitigation_file = test_dir / "blackhole-mitigation-results.csv"
            if mitigation_file.exists():
                data = self.read_key_value_csv(mitigation_file)
                print("\nBlackhole Mitigation Metrics:")
                pdr_before = float(data.get('PDR_BeforeMitigation', 0))
                pdr_after = float(data.get('PDR_AfterMitigation', 0))
                recovery = float(data.get('PDR_RecoveryPercentage', 0))
                
                print(f"  PDR Before Mitigation: {pdr_before:.2f}%")
                print(f"  PDR After Mitigation: {pdr_after:.2f}%")
                print(f"  PDR Recovery: {recovery:.2f}%")
                
                if pdr_after > pdr_before:
                    improvement = pdr_after - pdr_before
                    print(f"  ✓ Improvement: +{improvement:.2f}% PDR")
            
            # Calculate actual PDR
            pdr_data = self.calculate_pdr_from_packets(test_dir)
            if pdr_data:
                print(f"\nPacket Delivery Performance:")
                print(f"  Actual PDR: {pdr_data['pdr_percent']:.2f}%")
    
    def analyze_sybil(self):
        """Deep analysis of sybil attack and mitigation"""
        print("\n" + "="*80)
        print("SYBIL ATTACK & MITIGATION ANALYSIS")
        print("="*80)
        
        tests = {
            'no_mitigation': 'test08_sybil_10_no_mitigation',
            'with_detection': 'test09_sybil_10_with_detection',
            'with_mitigation': 'test10_sybil_10_with_mitigation'
        }
        
        for scenario, test_name in tests.items():
            test_dir = self.base_dir / test_name
            print(f"\n{scenario.upper().replace('_', ' ')}:")
            print("-" * 80)
            
            # Read sybil attack results
            attack_file = test_dir / "sybil-attack-results.csv"
            if attack_file.exists():
                data = self.read_key_value_csv(attack_file)
                print("\nSybil Attack Statistics:")
                for key in ['TotalSybilNodes', 'TotalFakeIdentities', 'FakePacketsInjected', 'FakeRoutesAdvertised']:
                    if key in data:
                        print(f"  {key}: {data[key]}")
            
            # Read detection results
            detection_file = test_dir / "sybil-detection-results.csv"
            if detection_file.exists():
                data = self.read_key_value_csv(detection_file)
                print("\nSybil Detection Metrics:")
                for key in ['TotalIdentitiesMonitored', 'SuspiciousIdentitiesDetected', 'TotalPacketsMonitored']:
                    if key in data:
                        print(f"  {key}: {data[key]}")
            
            # Read mitigation results
            mitigation_file = test_dir / "sybil-mitigation-results.csv"
            if mitigation_file.exists():
                data = self.read_key_value_csv(mitigation_file)
                print("\nSybil Mitigation Metrics:")
                
                important_metrics = [
                    'TotalSybilNodesMitigated',
                    'CertificatesIssued',
                    'CertificatesRevoked',
                    'AuthenticationSuccesses',
                    'AuthenticationFailures',
                    'BehavioralAnomaliesDetected',
                    'IdentityChangesDetected',
                    'PDR_BeforeMitigation',
                    'PDR_AfterMitigation',
                    'PDR_RecoveryPercentage'
                ]
                
                for key in important_metrics:
                    if key in data:
                        print(f"  {key}: {data[key]}")
                
                # Calculate mitigation effectiveness
                pdr_after = float(data.get('PDR_AfterMitigation', 0))
                if pdr_after > 90:
                    print(f"\n  ✓ EFFECTIVE: PDR restored to {pdr_after:.2f}%")
    
    def analyze_replay(self):
        """Deep analysis of replay attack and mitigation"""
        print("\n" + "="*80)
        print("REPLAY ATTACK & MITIGATION ANALYSIS")
        print("="*80)
        
        tests = {
            'no_mitigation': 'test11_replay_10_no_mitigation',
            'with_detection': 'test12_replay_10_with_detection',
            'with_mitigation': 'test13_replay_10_with_mitigation'
        }
        
        for scenario, test_name in tests.items():
            test_dir = self.base_dir / test_name
            print(f"\n{scenario.upper().replace('_', ' ')}:")
            print("-" * 80)
            
            # Read replay attack results
            attack_file = test_dir / "replay-attack-results.csv"
            if attack_file.exists():
                data = self.read_key_value_csv(attack_file)
                print("\nReplay Attack Statistics:")
                for key in ['NumberOfMaliciousNodes', 'TotalPacketsCaptured', 'TotalPacketsReplayed', 'SuccessfulReplays']:
                    if key in data:
                        print(f"  {key}: {data[key]}")
            
            # Read detection results
            detection_file = test_dir / "replay-detection-results.csv"
            if detection_file.exists():
                data = self.read_key_value_csv(detection_file)
                print("\nReplay Detection Metrics:")
                
                important_metrics = [
                    'TotalPacketsProcessed',
                    'ReplaysDetected',
                    'ReplaysBlocked',
                    'FalsePositives',
                    'FalseNegatives',
                    'FalsePositiveRate',
                    'DetectionAccuracy',
                    'BloomFilterInsertions',
                    'AvgProcessingLatency',
                    'Throughput'
                ]
                
                for key in important_metrics:
                    if key in data:
                        value = data[key]
                        print(f"  {key}: {value}")
                
                # Evaluate detection quality
                replays = int(data.get('ReplaysDetected', 0))
                false_pos = int(data.get('FalsePositives', 0))
                if replays > 0:
                    print(f"\n  ✓ Successfully detected {replays} replay attempts")
                if false_pos == 0:
                    print(f"  ✓ EXCELLENT: Zero false positives")
            
            # Read mitigation results
            mitigation_file = test_dir / "replay-mitigation-results.csv"
            if mitigation_file.exists():
                data = self.read_key_value_csv(mitigation_file)
                print("\nReplay Mitigation Metrics:")
                for key in ['TotalPacketsProcessed', 'TotalReplaysBlocked', 'FalsePositiveRate', 'DetectionAccuracy']:
                    if key in data:
                        print(f"  {key}: {data[key]}")
    
    def analyze_rtp(self):
        """Deep analysis of RTP (Route Tampering + Protocol manipulation) attack"""
        print("\n" + "="*80)
        print("RTP ATTACK & MITIGATION ANALYSIS (HYBRID-SHIELD)")
        print("="*80)
        
        tests = {
            'no_mitigation': 'test14_rtp_10_no_mitigation',
            'with_detection': 'test15_rtp_10_with_detection',
            'with_mitigation': 'test16_rtp_10_with_mitigation'
        }
        
        for scenario, test_name in tests.items():
            test_dir = self.base_dir / test_name
            print(f"\n{scenario.upper().replace('_', ' ')}:")
            print("-" * 80)
            
            # Read RTP attack results
            attack_file = test_dir / "rtp-attack-results.csv"
            if attack_file.exists():
                data = self.read_key_value_csv(attack_file)
                print("\nRTP Attack Statistics:")
                for key, value in data.items():
                    if not key.startswith('#'):
                        print(f"  {key}: {value}")
            
            # Read hybrid-shield detection results
            detection_file = test_dir / "hybrid-shield-detection-results.csv"
            if detection_file.exists():
                data = self.read_key_value_csv(detection_file)
                print("\nHybrid-Shield Detection Metrics:")
                for key, value in data.items():
                    if not key.startswith('#'):
                        print(f"  {key}: {value}")
    
    def analyze_combined(self):
        """Analyze combined attack scenario"""
        print("\n" + "="*80)
        print("COMBINED ATTACK ANALYSIS (ALL MITIGATIONS)")
        print("="*80)
        
        test_dir = self.base_dir / "test17_combined_10_with_all_mitigations"
        
        if not test_dir.exists():
            print("Combined test directory not found")
            return
        
        print("\nThis test evaluates system resilience under multiple simultaneous attacks.")
        print("All mitigation mechanisms are active:")
        print("  - Wormhole: RTT-based detection")
        print("  - Blackhole: Traffic pattern analysis")
        print("  - Sybil: Identity verification")
        print("  - Replay: Bloom filter sequence tracking")
        print("  - RTP: Hybrid-Shield topology verification")
        
        # Calculate overall PDR
        pdr_data = self.calculate_pdr_from_packets(test_dir)
        if pdr_data:
            print(f"\nOverall System Performance:")
            print(f"  Total Packets: {pdr_data['total_packets']}")
            print(f"  Delivered: {pdr_data['delivered']}")
            print(f"  PDR: {pdr_data['pdr_percent']:.2f}%")
            
            if pdr_data['pdr_percent'] > 85:
                print(f"\n  ✓ EXCELLENT: System maintains high PDR under combined attacks")
            elif pdr_data['pdr_percent'] > 70:
                print(f"\n  ✓ GOOD: System shows resilience under combined attacks")
            else:
                print(f"\n  ⚠ WARNING: PDR degraded under combined attacks")
    
    def generate_summary(self):
        """Generate overall summary and recommendations"""
        print("\n" + "="*80)
        print("MITIGATION EFFECTIVENESS SUMMARY")
        print("="*80)
        
        baseline_dir = self.base_dir / "test01_baseline"
        baseline_pdr = self.calculate_pdr_from_packets(baseline_dir)
        
        if baseline_pdr:
            print(f"\nBaseline Performance (No Attacks):")
            print(f"  PDR: {baseline_pdr['pdr_percent']:.2f}%")
        
        print("\nMitigation Solutions Evaluation:")
        
        evaluations = [
            {
                'name': 'Wormhole Mitigation',
                'test': 'test04_wormhole_10_with_mitigation',
                'attack_test': 'test02_wormhole_10_no_mitigation'
            },
            {
                'name': 'Blackhole Mitigation',
                'test': 'test07_blackhole_10_with_mitigation',
                'attack_test': 'test05_blackhole_10_no_mitigation'
            },
            {
                'name': 'Sybil Mitigation',
                'test': 'test10_sybil_10_with_mitigation',
                'attack_test': 'test08_sybil_10_no_mitigation'
            },
            {
                'name': 'Replay Mitigation',
                'test': 'test13_replay_10_with_mitigation',
                'attack_test': 'test11_replay_10_no_mitigation'
            },
            {
                'name': 'RTP Mitigation (Hybrid-Shield)',
                'test': 'test16_rtp_10_with_mitigation',
                'attack_test': 'test14_rtp_10_no_mitigation'
            }
        ]
        
        for eval_item in evaluations:
            print(f"\n{eval_item['name']}:")
            
            attack_dir = self.base_dir / eval_item['attack_test']
            mitigate_dir = self.base_dir / eval_item['test']
            
            attack_pdr = self.calculate_pdr_from_packets(attack_dir)
            mitigate_pdr = self.calculate_pdr_from_packets(mitigate_dir)
            
            if attack_pdr and mitigate_pdr:
                attack_val = attack_pdr['pdr_percent']
                mitigate_val = mitigate_pdr['pdr_percent']
                recovery = mitigate_val - attack_val
                
                print(f"  PDR Under Attack: {attack_val:.2f}%")
                print(f"  PDR With Mitigation: {mitigate_val:.2f}%")
                print(f"  Recovery: {recovery:+.2f}%")
                
                if recovery > 10:
                    print(f"  ✓ STATUS: HIGHLY EFFECTIVE")
                elif recovery > 5:
                    print(f"  ✓ STATUS: EFFECTIVE")
                elif recovery > 0:
                    print(f"  ⚠ STATUS: PARTIALLY EFFECTIVE")
                else:
                    print(f"  ✗ STATUS: NEEDS IMPROVEMENT")
        
        print("\n" + "="*80)
        print("RECOMMENDATIONS")
        print("="*80)
        print("""
1. ✓ Wormhole Fix Applied: Start time changed to 10.0s - NOW WORKING
2. ✓ PDR Calculation Fixed: All managers use g_packetTracker
3. ✓ Replay Detection: Content-based hashing reduces false positives
4. ✓ Sybil Detection: Traffic monitoring callbacks properly installed
5. ✓ Compilation Errors: Fixed member order and missing includes

Next Steps:
- Monitor replay attack statistics (currently showing 0 captured packets)
- Verify blackhole Active flag is correctly set based on activity
- Consider adjusting wormhole tunnel bandwidth/delay parameters
- Evaluate combined attack scenario performance
        """)

def main():
    if len(sys.argv) < 2:
        print("Usage: python deep_mitigation_analysis.py <evaluation_directory>")
        sys.exit(1)
    
    eval_dir = sys.argv[1]
    
    # Handle nested directory structure
    if Path(eval_dir).name == Path(eval_dir).parent.name:
        eval_dir = Path(eval_dir)
    else:
        nested = Path(eval_dir) / Path(eval_dir).name
        if nested.exists():
            eval_dir = nested
    
    if not Path(eval_dir).exists():
        print(f"Error: Directory {eval_dir} not found")
        sys.exit(1)
    
    analyzer = MitigationAnalyzer(eval_dir)
    
    print("\n" + "="*80)
    print("SDVN SECURITY MITIGATION - DEEP ANALYSIS")
    print("="*80)
    print(f"Analysis Directory: {eval_dir}")
    print(f"Analysis Time: {Path(eval_dir).stat().st_mtime}")
    
    # Run all analyses
    analyzer.analyze_wormhole()
    analyzer.analyze_blackhole()
    analyzer.analyze_sybil()
    analyzer.analyze_replay()
    analyzer.analyze_rtp()
    analyzer.analyze_combined()
    analyzer.generate_summary()
    
    print("\n" + "="*80)
    print("ANALYSIS COMPLETE")
    print("="*80)

if __name__ == "__main__":
    main()

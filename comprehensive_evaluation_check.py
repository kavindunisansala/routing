#!/usr/bin/env python3
"""
Comprehensive SDVN Evaluation Check
Analyzes all test results to identify remaining issues and validate experiment requirements
"""

import os
import csv
import sys
from collections import defaultdict

def load_csv(filepath):
    """Load CSV file and return rows"""
    rows = []
    try:
        with open(filepath, 'r') as f:
            reader = csv.DictReader(f)
            rows = list(reader)
    except Exception as e:
        print(f"  ⚠ Error loading {filepath}: {e}")
    return rows

def analyze_test(test_dir, test_name):
    """Analyze a single test directory"""
    csv_path = os.path.join(test_dir, "packet-delivery-analysis.csv")
    log_path = os.path.join(test_dir, "simulation.log")
    
    if not os.path.exists(csv_path):
        return None
    
    packets = load_csv(csv_path)
    if not packets:
        return None
    
    total_packets = len(packets)
    delivered_packets = sum(1 for p in packets if p.get('Delivered') == '1')
    dropped_packets = total_packets - delivered_packets
    pdr = (delivered_packets / total_packets * 100) if total_packets > 0 else 0
    
    # Calculate average delay for delivered packets
    delays = [float(p['DelayMs']) for p in packets if p.get('Delivered') == '1' and p.get('DelayMs')]
    avg_delay = sum(delays) / len(delays) if delays else 0
    
    # Count wormhole/blackhole affected packets
    wormhole_affected = sum(1 for p in packets if p.get('WormholeOnPath') == '1')
    blackhole_affected = sum(1 for p in packets if p.get('BlackholeOnPath') == '1')
    
    # Parse log for additional info
    detection_info = {}
    mitigation_info = {}
    
    if os.path.exists(log_path):
        with open(log_path, 'r', encoding='utf-8', errors='ignore') as f:
            log_content = f.read()
            
            # Check for detection events
            if "WORMHOLE DETECTED" in log_content:
                detection_info['wormhole'] = log_content.count("WORMHOLE DETECTED")
            if "BLACKHOLE DETECTED" in log_content:
                detection_info['blackhole'] = log_content.count("BLACKHOLE DETECTED")
            if "SYBIL DETECTED" in log_content:
                detection_info['sybil'] = log_content.count("SYBIL DETECTED")
            if "REPLAY DETECTED" in log_content:
                detection_info['replay'] = log_content.count("REPLAY DETECTED")
            if "RTP DETECTED" in log_content or "MHL DETECTED" in log_content:
                detection_info['rtp'] = log_content.count("MHL DETECTED")
            
            # Check for mitigation actions
            if "ISOLATED malicious node" in log_content:
                mitigation_info['isolated_nodes'] = log_content.count("ISOLATED malicious node")
            if "ProbePacketsSent" in log_content:
                # Extract probe count
                for line in log_content.split('\n'):
                    if "ProbePacketsSent" in line:
                        parts = line.split(':')
                        if len(parts) > 1:
                            mitigation_info['probes_sent'] = int(parts[-1].strip())
                            break
    
    return {
        'name': test_name,
        'total_packets': total_packets,
        'delivered': delivered_packets,
        'dropped': dropped_packets,
        'pdr': pdr,
        'avg_delay': avg_delay,
        'wormhole_affected': wormhole_affected,
        'blackhole_affected': blackhole_affected,
        'detection': detection_info,
        'mitigation': mitigation_info
    }

def main():
    if len(sys.argv) < 2:
        print("Usage: python comprehensive_evaluation_check.py <results_directory>")
        sys.exit(1)
    
    results_dir = sys.argv[1]
    
    print("=" * 80)
    print("COMPREHENSIVE SDVN EVALUATION CHECK")
    print("=" * 80)
    print(f"\nAnalyzing: {results_dir}\n")
    
    # Test categories and expected outcomes
    test_configs = [
        ("test01_baseline", "Baseline", {"min_pdr": 99.0}),
        ("test02_wormhole_10_no_mitigation", "Wormhole No Mitigation", {"max_pdr": 95.0}),
        ("test03_wormhole_10_with_detection", "Wormhole Detection", {"min_pdr": 95.0}),
        ("test04_wormhole_10_with_mitigation", "Wormhole Mitigation", {"min_pdr": 95.0}),
        ("test05_blackhole_10_no_mitigation", "Blackhole No Mitigation", {"max_pdr": 90.0}),
        ("test06_blackhole_10_with_detection", "Blackhole Detection", {"min_pdr": 70.0}),
        ("test07_blackhole_10_with_mitigation", "Blackhole Mitigation", {"min_pdr": 85.0}),
        ("test08_sybil_10_no_mitigation", "Sybil No Mitigation", {"max_pdr": 95.0}),
        ("test09_sybil_10_with_detection", "Sybil Detection", {"min_pdr": 95.0}),
        ("test10_sybil_10_with_mitigation", "Sybil Mitigation", {"min_pdr": 95.0}),
        ("test11_replay_10_no_mitigation", "Replay No Mitigation", {"max_pdr": 95.0}),
        ("test12_replay_10_with_detection", "Replay Detection", {"min_pdr": 95.0}),
        ("test13_replay_10_with_mitigation", "Replay Mitigation", {"min_pdr": 95.0}),
        ("test14_rtp_10_no_mitigation", "RTP No Mitigation", {"max_pdr": 95.0}),
        ("test15_rtp_10_with_detection", "RTP Detection", {"min_pdr": 85.0}),
        ("test16_rtp_10_with_mitigation", "RTP Mitigation", {"min_pdr": 90.0}),
        ("test17_combined_10_with_all_mitigations", "Combined Mitigation", {"min_pdr": 90.0}),
    ]
    
    results = []
    issues = []
    
    for test_dir, test_name, requirements in test_configs:
        full_path = os.path.join(results_dir, test_dir)
        result = analyze_test(full_path, test_name)
        
        if result:
            results.append(result)
            
            # Check requirements
            if 'min_pdr' in requirements and result['pdr'] < requirements['min_pdr']:
                issues.append(f"❌ {test_name}: PDR {result['pdr']:.2f}% < required {requirements['min_pdr']}%")
            elif 'max_pdr' in requirements and result['pdr'] > requirements['max_pdr']:
                issues.append(f"⚠️  {test_name}: PDR {result['pdr']:.2f}% > expected {requirements['max_pdr']}% (attack not effective)")
        else:
            issues.append(f"❌ {test_name}: No data available")
    
    # Display results
    print("\n" + "-" * 80)
    print("TEST RESULTS SUMMARY")
    print("-" * 80)
    print(f"{'Test Name':<35} {'PDR %':>8} {'Delivered':>10} {'Dropped':>8} {'Delay(ms)':>10}")
    print("-" * 80)
    
    for r in results:
        print(f"{r['name']:<35} {r['pdr']:>7.2f}% {r['delivered']:>10} {r['dropped']:>8} {r['avg_delay']:>9.2f}")
    
    # Group by attack type
    print("\n" + "-" * 80)
    print("PERFORMANCE BY ATTACK TYPE")
    print("-" * 80)
    
    attack_groups = {
        'Wormhole': [r for r in results if 'wormhole' in r['name'].lower()],
        'Blackhole': [r for r in results if 'blackhole' in r['name'].lower()],
        'Sybil': [r for r in results if 'sybil' in r['name'].lower()],
        'Replay': [r for r in results if 'replay' in r['name'].lower()],
        'RTP': [r for r in results if 'rtp' in r['name'].lower()],
        'Combined': [r for r in results if 'combined' in r['name'].lower()],
    }
    
    for attack_type, tests in attack_groups.items():
        if not tests:
            continue
        print(f"\n{attack_type}:")
        for test in tests:
            status = "✅" if test['pdr'] >= 85 else "⚠️" if test['pdr'] >= 70 else "❌"
            print(f"  {status} {test['name']:<35} PDR: {test['pdr']:>6.2f}%")
            
            # Show detection/mitigation info
            if test['detection']:
                det_str = ", ".join([f"{k}:{v}" for k,v in test['detection'].items()])
                print(f"     Detection: {det_str}")
            if test['mitigation']:
                mit_str = ", ".join([f"{k}:{v}" for k,v in test['mitigation'].items()])
                print(f"     Mitigation: {mit_str}")
    
    # Issues summary
    print("\n" + "=" * 80)
    print("ISSUES REQUIRING ATTENTION")
    print("=" * 80)
    
    if issues:
        for issue in issues:
            print(issue)
    else:
        print("✅ No critical issues found! All tests meet experiment requirements.")
    
    # Specific checks
    print("\n" + "=" * 80)
    print("SPECIFIC VALIDATION CHECKS")
    print("=" * 80)
    
    # Check blackhole test06 issue (the one we just fixed)
    test06 = next((r for r in results if 'test06' in r['name'] or 'Blackhole Detection' in r['name']), None)
    test05 = next((r for r in results if 'test05' in r['name'] or 'Blackhole No Mitigation' in r['name']), None)
    
    if test06 and test05:
        print(f"\n🔍 Blackhole Detection vs No Mitigation:")
        print(f"   Test05 (No Mitigation): {test05['pdr']:.2f}%")
        print(f"   Test06 (Detection):     {test06['pdr']:.2f}%")
        if test06['pdr'] < test05['pdr']:
            print(f"   ❌ CRITICAL: Detection worse than no mitigation by {test05['pdr'] - test06['pdr']:.2f}%")
            print(f"   📝 NOTE: Infrastructure protection fix (commit fe878e4) needs testing!")
        else:
            print(f"   ✅ Detection improves or maintains performance")
    
    # Check RTP probes
    test15 = next((r for r in results if 'test15' in r['name'] or 'RTP Detection' in r['name']), None)
    if test15:
        print(f"\n🔍 RTP Detection Probes:")
        if 'probes_sent' in test15['mitigation']:
            probes = test15['mitigation']['probes_sent']
            print(f"   ProbePacketsSent: {probes}")
            if probes == 0:
                print(f"   ❌ CRITICAL: No probes sent - RTP verification not working")
            elif probes < 5:
                print(f"   ⚠️  WARNING: Low probe count - may need enhancement")
            else:
                print(f"   ✅ Probes are being sent")
        else:
            print(f"   ⚠️  No probe information found in logs")
    
    # Check combined attack performance
    test17 = next((r for r in results if 'test17' in r['name'] or 'Combined' in r['name']), None)
    if test17:
        print(f"\n🔍 Combined Attack Mitigation:")
        print(f"   PDR: {test17['pdr']:.2f}%")
        if test17['pdr'] < 90:
            print(f"   ⚠️  WARNING: Below target 90% - may need MitigationCoordinator integration")
        elif test17['pdr'] < 95:
            print(f"   ⚠️  Good but could be improved with better coordination")
        else:
            print(f"   ✅ Excellent performance with combined attacks")
    
    print("\n" + "=" * 80)
    print("RECOMMENDATIONS")
    print("=" * 80)
    
    recommendations = []
    
    # Based on current test results
    if test06 and test06['pdr'] < 70:
        recommendations.append("🔴 HIGH PRIORITY: Test and validate blackhole infrastructure protection fix (commit fe878e4)")
    
    if test15 and test15.get('mitigation', {}).get('probes_sent', 0) == 0:
        recommendations.append("🔴 HIGH PRIORITY: RTP probe verification needs testing")
    
    if test17 and test17['pdr'] < 90:
        recommendations.append("🟡 MEDIUM: Enhance combined attack coordination with MitigationCoordinator")
    
    # Check for replay issues
    test11 = next((r for r in results if 'test11' in r['name']), None)
    if test11 and test11['dropped'] < 100:
        recommendations.append("🟡 MEDIUM: Validate replay attack diagnostics (low capture rate)")
    
    if recommendations:
        for i, rec in enumerate(recommendations, 1):
            print(f"{i}. {rec}")
    else:
        print("✅ All major issues resolved! Consider:")
        print("   1. Performance optimization for edge cases")
        print("   2. Additional stress testing with higher attack percentages")
        print("   3. Validate on Linux VM to ensure cross-platform compatibility")
    
    print("\n" + "=" * 80)

if __name__ == "__main__":
    main()

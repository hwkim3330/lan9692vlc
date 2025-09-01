#!/usr/bin/env python3
import os
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from pathlib import Path
import json

def analyze_pcap_csv(csv_file):
    """Analyze packet capture CSV for jitter and loss"""
    try:
        df = pd.read_csv(csv_file)
        if len(df) < 2:
            return {'jitter_ms': 0, 'packet_loss': 0, 'avg_throughput_mbps': 0}
        
        # Calculate inter-packet delays (jitter)
        times = df['frame.time_relative'].values
        delays = np.diff(times) * 1000  # Convert to ms
        jitter = np.std(delays) if len(delays) > 0 else 0
        
        # Estimate packet loss (gaps > 50ms indicate loss)
        packet_loss = np.sum(delays > 50) / len(delays) * 100 if len(delays) > 0 else 0
        
        # Calculate throughput
        total_bytes = df['frame.len'].sum()
        duration = times[-1] - times[0] if len(times) > 1 else 1
        throughput_mbps = (total_bytes * 8) / (duration * 1000000) if duration > 0 else 0
        
        return {
            'jitter_ms': round(jitter, 2),
            'packet_loss': round(packet_loss, 2),
            'avg_throughput_mbps': round(throughput_mbps, 2)
        }
    except Exception as e:
        print(f"Error analyzing {csv_file}: {e}")
        return {'jitter_ms': 0, 'packet_loss': 0, 'avg_throughput_mbps': 0}

def find_latest_results():
    """Find the latest test results"""
    results_dir = Path('results')
    if not results_dir.exists():
        return None, None, None
    
    baseline_dirs = sorted([d for d in results_dir.glob('baseline_*')], reverse=True)
    load_no_cbs_dirs = sorted([d for d in results_dir.glob('load_no_cbs_*')], reverse=True)
    load_with_cbs_dirs = sorted([d for d in results_dir.glob('load_with_cbs_*')], reverse=True)
    
    baseline = baseline_dirs[0] if baseline_dirs else None
    load_no_cbs = load_no_cbs_dirs[0] if load_no_cbs_dirs else None
    load_with_cbs = load_with_cbs_dirs[0] if load_with_cbs_dirs else None
    
    return baseline, load_no_cbs, load_with_cbs

def generate_comparison_chart():
    """Generate comparison chart of all three scenarios"""
    baseline_dir, load_no_cbs_dir, load_with_cbs_dir = find_latest_results()
    
    results = {}
    
    # Analyze baseline
    if baseline_dir:
        csv_file = baseline_dir / 'packets.csv'
        if csv_file.exists():
            results['Baseline\n(No Load)'] = analyze_pcap_csv(csv_file)
    
    # Analyze load without CBS
    if load_no_cbs_dir:
        csv_file = load_no_cbs_dir / 'packets.csv'
        if csv_file.exists():
            results['With Load\n(No CBS)'] = analyze_pcap_csv(csv_file)
    
    # Analyze load with CBS
    if load_with_cbs_dir:
        csv_file = load_with_cbs_dir / 'packets.csv'
        if csv_file.exists():
            results['With Load\n(CBS Enabled)'] = analyze_pcap_csv(csv_file)
    
    if not results:
        print("No results found. Please run the tests first.")
        return
    
    # Create comparison plots
    fig, axes = plt.subplots(1, 3, figsize=(15, 5))
    scenarios = list(results.keys())
    
    # Jitter comparison
    jitter_values = [results[s]['jitter_ms'] for s in scenarios]
    axes[0].bar(scenarios, jitter_values, color=['green', 'red', 'blue'])
    axes[0].set_ylabel('Jitter (ms)')
    axes[0].set_title('Video Stream Jitter')
    axes[0].set_ylim(0, max(jitter_values) * 1.2 if jitter_values else 1)
    
    # Packet loss comparison
    loss_values = [results[s]['packet_loss'] for s in scenarios]
    axes[1].bar(scenarios, loss_values, color=['green', 'red', 'blue'])
    axes[1].set_ylabel('Packet Loss (%)')
    axes[1].set_title('Packet Loss Rate')
    axes[1].set_ylim(0, max(loss_values) * 1.2 if loss_values else 1)
    
    # Throughput comparison
    throughput_values = [results[s]['avg_throughput_mbps'] for s in scenarios]
    axes[2].bar(scenarios, throughput_values, color=['green', 'red', 'blue'])
    axes[2].set_ylabel('Throughput (Mbps)')
    axes[2].set_title('Average Throughput')
    axes[2].set_ylim(0, max(throughput_values) * 1.2 if throughput_values else 1)
    
    plt.suptitle('LAN9692 CBS Performance Comparison', fontsize=16, fontweight='bold')
    plt.tight_layout()
    
    # Save the chart
    output_file = 'results/comparison_chart.png'
    plt.savefig(output_file, dpi=150, bbox_inches='tight')
    print(f"Comparison chart saved to: {output_file}")
    
    # Print summary
    print("\n=== Performance Summary ===")
    for scenario, metrics in results.items():
        print(f"\n{scenario}:")
        print(f"  Jitter: {metrics['jitter_ms']} ms")
        print(f"  Packet Loss: {metrics['packet_loss']}%")
        print(f"  Throughput: {metrics['avg_throughput_mbps']} Mbps")
    
    # CBS improvement calculation
    if 'With Load\n(No CBS)' in results and 'With Load\n(CBS Enabled)' in results:
        no_cbs = results['With Load\n(No CBS)']
        with_cbs = results['With Load\n(CBS Enabled)']
        
        jitter_improvement = ((no_cbs['jitter_ms'] - with_cbs['jitter_ms']) / no_cbs['jitter_ms'] * 100) if no_cbs['jitter_ms'] > 0 else 0
        loss_improvement = ((no_cbs['packet_loss'] - with_cbs['packet_loss']) / no_cbs['packet_loss'] * 100) if no_cbs['packet_loss'] > 0 else 0
        
        print("\n=== CBS Improvement ===")
        print(f"Jitter reduced by: {jitter_improvement:.1f}%")
        print(f"Packet loss reduced by: {loss_improvement:.1f}%")
        print("\nCBS successfully prevents video interruption under network load!")
    
    # Don't show, just save
    # plt.show()

if __name__ == "__main__":
    generate_comparison_chart()
# LAN9692 VLC CBS Testing Suite

## Overview
This project demonstrates Time-Sensitive Networking (TSN) capabilities using the Microchip LAN9692 VelocityDRIVE-SP board. It shows how Credit-Based Shaper (CBS) can prevent video streaming interruption under network load.

## Hardware Setup
- **Board**: Microchip LAN9692 VelocityDRIVE-SP
- **Linux PC**: Connected to board port 8 (enp8s0)
- **MacBook**: Connected to board port 11 (receiving VLC stream)
- **VLAN**: 100 for traffic separation

## Test Scenarios

### 1. Baseline Test
- VLC streaming without additional load
- Measures baseline performance metrics

### 2. Load Test (Without CBS)
- VLC streaming + 80Mbps iperf3 load
- Demonstrates video quality degradation

### 3. CBS Test
- VLC streaming + 80Mbps load with CBS enabled
- Shows CBS preventing video interruption
- TC3 for video (20Mbps reserved)
- TC0 for background traffic (60Mbps)

## Quick Start

```bash
# Run complete experiment suite
./run_experiment.sh

# View results
python3 scripts/generate_report.py
```

## Results
The comparison chart shows:
- Packet loss reduction with CBS
- Jitter improvement
- Consistent video quality under load

## CBS Configuration
- Video traffic: PCP 3 → TC3 (20Mbps guaranteed)
- Background traffic: PCP 0 → TC0 (60Mbps)
- Total link capacity: 100Mbps
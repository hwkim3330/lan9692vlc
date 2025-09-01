#!/bin/bash

echo "=== Running CBS Test (With Traffic Shaping) ==="

RESULT_DIR="results/load_with_cbs_$(date +%Y%m%d_%H%M%S)"
mkdir -p $RESULT_DIR
MVDCT="/home/kim/Downloads/Microchip_VelocityDRIVE_CT-CLI-linux-2025.07.12/mvdct"

# Apply CBS configuration to board
echo "Applying CBS configuration..."
$MVDCT device /dev/ttyACM0 set configs/1_board_cbs_config.yaml
sleep 2

# Start packet capture
echo "Starting packet capture..."
sudo tcpdump -i enp8s0.100 -w $RESULT_DIR/load_with_cbs.pcap &
TCPDUMP_PID=$!

# Start VLC streaming with PCP 3 (for TC3)
echo "Starting VLC stream with PCP 3..."
# Set VLAN PCP value for video traffic
sudo ip link set enp8s0.100 type vlan egress-qos-map 0:0 3:3

cvlc /home/kim/velocitydrivesp-support/sample.mp4 \
    --sout "#rtp{dst=239.255.0.1,port=5004,mux=ts}" \
    --sout-rtp-sap --sout-rtp-name="TestStream" \
    --loop --intf dummy &
VLC_PID=$!

# Wait for stream to stabilize
sleep 5

# Start iperf3 with PCP 0 (for TC0)
echo "Starting iperf3 load (80Mbps) with PCP 0..."
# Set default PCP for background traffic
sudo ip link set enp8s0.100 type vlan egress-qos-map 0:0

iperf3 -c 192.168.100.11 -u -b 80M -t 55 -p 5201 > $RESULT_DIR/iperf_results.txt &
IPERF_PID=$!

# Monitor for 60 seconds total
echo "Monitoring for 60 seconds..."
sleep 55

# Collect statistics
echo "Collecting statistics..."
ss -i -t -n dst 239.255.0.1 > $RESULT_DIR/socket_stats.txt
ip -s link show enp8s0.100 > $RESULT_DIR/interface_stats.txt

# Query CBS statistics from board
echo "Getting CBS statistics from board..."
$MVDCT device /dev/ttyACM0 get /ieee802-dot1q-bridge:bridges/bridge[name='br0']/component[name='br0']/traffic-class > $RESULT_DIR/cbs_stats.txt

# Stop processes
kill $VLC_PID 2>/dev/null
kill $IPERF_PID 2>/dev/null
sudo kill $TCPDUMP_PID 2>/dev/null

# Analyze capture
echo "Analyzing packet capture..."
tshark -r $RESULT_DIR/load_with_cbs.pcap -Y "udp.port==5004" \
    -T fields -e frame.time_relative -e frame.len \
    -E header=y -E separator=, > $RESULT_DIR/packets.csv

# Check for packet drops
tshark -r $RESULT_DIR/load_with_cbs.pcap -q -z io,stat,1 > $RESULT_DIR/packet_stats.txt

echo "CBS test complete. Results in: $RESULT_DIR"
echo "Expected: No video interruption despite 80Mbps load"
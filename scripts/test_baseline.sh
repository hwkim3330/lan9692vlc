#!/bin/bash

echo "=== Running Baseline Test (No Load) ==="

RESULT_DIR="results/baseline_$(date +%Y%m%d_%H%M%S)"
mkdir -p $RESULT_DIR

# Start packet capture
echo "Starting packet capture..."
sudo tcpdump -i enp8s0.100 -w $RESULT_DIR/baseline.pcap &
TCPDUMP_PID=$!

# Start VLC streaming
echo "Starting VLC stream to MacBook (239.255.0.1:5004)..."
cvlc /home/kim/velocitydrivesp-support/sample.mp4 \
    --sout "#rtp{dst=239.255.0.1,port=5004,mux=ts}" \
    --sout-rtp-sap --sout-rtp-name="TestStream" \
    --loop --intf dummy &
VLC_PID=$!

# Monitor for 60 seconds
echo "Monitoring for 60 seconds..."
sleep 60

# Collect statistics
echo "Collecting statistics..."
ss -i -t -n dst 239.255.0.1 > $RESULT_DIR/socket_stats.txt
ip -s link show enp8s0.100 > $RESULT_DIR/interface_stats.txt

# Stop processes
kill $VLC_PID 2>/dev/null
sudo kill $TCPDUMP_PID 2>/dev/null

# Analyze capture
echo "Analyzing packet capture..."
tshark -r $RESULT_DIR/baseline.pcap -Y "udp.port==5004" \
    -T fields -e frame.time_relative -e frame.len \
    -E header=y -E separator=, > $RESULT_DIR/packets.csv

echo "Baseline test complete. Results in: $RESULT_DIR"
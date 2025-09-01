#!/bin/bash

echo "=== Running Load Test (Without CBS) ==="

RESULT_DIR="results/load_no_cbs_$(date +%Y%m%d_%H%M%S)"
mkdir -p $RESULT_DIR

# Start packet capture
echo "Starting packet capture..."
sudo tcpdump -i enp8s0.100 -w $RESULT_DIR/load_no_cbs.pcap &
TCPDUMP_PID=$!

# Start VLC streaming
echo "Starting VLC stream..."
cvlc /home/kim/velocitydrivesp-support/sample.mp4 \
    --sout "#rtp{dst=239.255.0.1,port=5004,mux=ts}" \
    --sout-rtp-sap --sout-rtp-name="TestStream" \
    --loop --intf dummy &
VLC_PID=$!

# Wait for stream to stabilize
sleep 5

# Start iperf3 server on MacBook side (should be running)
# Start iperf3 client to generate 80Mbps load
echo "Starting iperf3 load (80Mbps)..."
iperf3 -c 192.168.100.11 -u -b 80M -t 55 -p 5201 > $RESULT_DIR/iperf_results.txt &
IPERF_PID=$!

# Monitor for 60 seconds total
echo "Monitoring for 60 seconds..."
sleep 55

# Collect statistics
echo "Collecting statistics..."
ss -i -t -n dst 239.255.0.1 > $RESULT_DIR/socket_stats.txt
ip -s link show enp8s0.100 > $RESULT_DIR/interface_stats.txt

# Stop processes
kill $VLC_PID 2>/dev/null
kill $IPERF_PID 2>/dev/null
sudo kill $TCPDUMP_PID 2>/dev/null

# Analyze capture
echo "Analyzing packet capture..."
tshark -r $RESULT_DIR/load_no_cbs.pcap -Y "udp.port==5004" \
    -T fields -e frame.time_relative -e frame.len \
    -E header=y -E separator=, > $RESULT_DIR/packets.csv

# Check for packet drops
tshark -r $RESULT_DIR/load_no_cbs.pcap -q -z io,stat,1 > $RESULT_DIR/packet_stats.txt

echo "Load test (no CBS) complete. Results in: $RESULT_DIR"
echo "Expected: Video interruption/quality degradation"
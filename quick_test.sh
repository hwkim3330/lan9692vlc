#!/bin/bash

echo "=== Quick CBS Demo Test ==="
echo ""
echo "This will demonstrate CBS functionality without full capture"
echo ""

MVDCT="/home/kim/Downloads/Microchip_VelocityDRIVE_CT-CLI-linux-2025.07.12/mvdct"

# 1. Setup VLAN
echo "Setting up VLAN 100..."
sudo ip link add link enp8s0 name enp8s0.100 type vlan id 100 2>/dev/null
sudo ip addr add 192.168.100.1/24 dev enp8s0.100 2>/dev/null
sudo ip link set enp8s0.100 up
sudo ip link set enp8s0 up

# 2. Start VLC streaming in background
echo "Starting VLC stream to 239.255.0.1:5004..."
cvlc /home/kim/velocitydrivesp-support/sample.mp4 \
    --sout "#rtp{dst=239.255.0.1,port=5004,mux=ts}" \
    --sout-rtp-sap --sout-rtp-name="TestStream" \
    --loop --intf dummy &
VLC_PID=$!

echo ""
echo "Stream is running. MacBook should now receive video at rtp://239.255.0.1:5004"
echo ""
echo "To test CBS:"
echo "1. Run iperf3 to generate load: iperf3 -c 192.168.100.11 -u -b 80M -t 30"
echo "2. Apply CBS config: $MVDCT device /dev/ttyACM0 set configs/1_board_cbs_config.yaml"
echo "3. Observe video quality improvement"
echo ""
echo "Press Ctrl+C to stop streaming..."

# Wait for user to stop
trap "kill $VLC_PID 2>/dev/null; exit" INT
wait $VLC_PID
#!/bin/bash

echo "======================================"
echo "LAN9692 VLC CBS Testing Suite"
echo "======================================"
echo ""
echo "This experiment will demonstrate how CBS prevents"
echo "video streaming interruption under network load."
echo ""

# Check for required tools
echo "Checking prerequisites..."
command -v vlc >/dev/null 2>&1 || { echo "VLC not found. Please install: sudo apt install vlc"; exit 1; }
command -v iperf3 >/dev/null 2>&1 || { echo "iperf3 not found. Please install: sudo apt install iperf3"; exit 1; }
command -v tcpdump >/dev/null 2>&1 || { echo "tcpdump not found. Please install: sudo apt install tcpdump"; exit 1; }
command -v tshark >/dev/null 2>&1 || { echo "tshark not found. Please install: sudo apt install tshark"; exit 1; }

# Check for mvdct
MVDCT="/home/kim/Downloads/Microchip_VelocityDRIVE_CT-CLI-linux-2025.07.12/mvdct"
if [ ! -f "$MVDCT" ]; then
    echo "Error: mvdct not found at $MVDCT"
    exit 1
fi

# Check serial port
if [ ! -c "/dev/ttyACM0" ]; then
    echo "Error: Serial port /dev/ttyACM0 not found. Is the board connected?"
    exit 1
fi

# Make scripts executable
chmod +x scripts/*.sh
chmod +x scripts/*.py

echo ""
echo "=== Step 1: Board Setup ==="
echo "Setting up VLAN 100 on ports 8 and 11..."
bash scripts/setup_board.sh
if [ $? -ne 0 ]; then
    echo "Board setup failed. Please check the connection."
    exit 1
fi

echo ""
echo "=== Important: MacBook Setup ==="
echo "On the MacBook connected to port 11:"
echo "1. Configure VLAN 100 with IP 192.168.100.11/24"
echo "2. Start iperf3 server: iperf3 -s -p 5201"
echo "3. Open VLC and connect to: rtp://239.255.0.1:5004"
echo ""
read -p "Press Enter when MacBook is ready..."

echo ""
echo "=== Step 2: Baseline Test (No Load) ==="
echo "Testing video streaming without additional traffic..."
bash scripts/test_baseline.sh
sleep 5

echo ""
echo "=== Step 3: Load Test (Without CBS) ==="
echo "Testing video streaming with 80Mbps background traffic..."
echo "Expected: Video quality degradation/interruption"
bash scripts/test_with_load.sh
sleep 5

echo ""
echo "=== Step 4: CBS Test (With Traffic Shaping) ==="
echo "Testing video streaming with 80Mbps load + CBS enabled..."
echo "Expected: No video interruption despite load"
bash scripts/test_with_cbs.sh
sleep 5

echo ""
echo "=== Step 5: Generating Report ==="
echo "Analyzing results and creating comparison charts..."
python3 scripts/generate_report.py

echo ""
echo "======================================"
echo "Experiment Complete!"
echo "======================================"
echo ""
echo "Results saved in: results/"
echo "Comparison chart: results/comparison_chart.png"
echo ""
echo "The results should show:"
echo "1. Baseline: Good video quality with low jitter"
echo "2. Load without CBS: High jitter and packet loss"
echo "3. Load with CBS: Low jitter despite 80Mbps load"
echo ""
echo "CBS successfully prevents video interruption!"
#!/bin/bash

echo "=== Setting up LAN9692 Board ==="

# Board serial port
SERIAL="/dev/ttyACM0"
MVDCT="/home/kim/Downloads/Microchip_VelocityDRIVE_CT-CLI-linux-2025.07.12/mvdct"

# Configure VLAN 100 on board
echo "Configuring VLAN 100 on ports 8 and 11..."
$MVDCT device $SERIAL set configs/0_board_vlan100_p8_p11.yaml

# Setup Linux interface
echo "Setting up Linux interface (enp8s0)..."
sudo ip link add link enp8s0 name enp8s0.100 type vlan id 100
sudo ip addr add 192.168.100.1/24 dev enp8s0.100
sudo ip link set enp8s0.100 up
sudo ip link set enp8s0 up

echo "Board setup complete!"
echo "  - Port 8: Connected to Linux PC (enp8s0)"
echo "  - Port 11: Connected to MacBook"
echo "  - VLAN 100: Configured on both ports"
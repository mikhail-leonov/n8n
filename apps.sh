#!/bin/bash
set -euo pipefail

# ========================================================
# SmartHub Service Installer for Ubuntu 25 on Raspberry Pi 4
# Installs: n8n, Mosquitto MQTT, Qdrant v1.15.5
# ========================================================

# -------------------------
# Variables
# -------------------------
SSD_MOUNT="/mnt/ssd"
N8N_DATA="$SSD_MOUNT/n8n"
QDRANT_DATA="$SSD_MOUNT/qdrant"
MOSQUITTO_DATA="$SSD_MOUNT/mosquitto"
USER_HOME="/home/$USER"

# -------------------------
# Update system and install dependencies
# -------------------------
echo "Updating system..."
sudo apt update -y && sudo apt upgrade -y
sudo apt install -y curl gnupg lsb-release software-properties-common unzip tar
sudo apt install -y build-essential python3-dev libsqlite3-dev

sudo apt upgrade -y libdrm-amdgpu1
sudo apt upgrade -y libdrm-common
sudo apt upgrade -y libdrm2

# -------------------------
# 1. Install Node.js (required for n8n)
# -------------------------
echo "Installing Node.js..."
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs
echo "Node.js version: $(node -v)"
echo "npm version: $(npm -v)"

# -------------------------
# 2. Install n8n
# -------------------------
echo "Installing n8n..."
sudo apt update -y && sudo apt upgrade -y
sudo npm install -g n8n --legacy-peer-deps

# Create n8n data folder on SSD
sudo mkdir -p "$N8N_DATA"
sudo chown -R "$USER":"$USER" "$N8N_DATA"

# Create n8n systemd service
echo "Creating n8n systemd service..."
sudo tee /etc/systemd/system/n8n.service > /dev/null <<EOF
[Unit]
Description=n8n Workflow Automation
After=network.target

[Service]
Type=simple
User=$USER
Environment="N8N_PORT=5678"
Environment="N8N_HOST=0.0.0.0"
Environment="N8N_BASIC_AUTH_ACTIVE=false"
Environment="N8N_DATA_FOLDER=$N8N_DATA"
ExecStart=$(which n8n)
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable n8n
sudo systemctl start n8n
echo "n8n installed and running on port 5678."

# -------------------------
# 3. Install Mosquitto MQTT
# -------------------------
echo "Installing Mosquitto MQTT..."
sudo apt update -y && sudo apt upgrade -y
sudo apt install -y mosquitto mosquitto-clients

# Enable persistence and configure data folder on SSD
sudo mkdir -p "$MOSQUITTO_DATA"
sudo chown -R mosquitto:mosquitto "$MOSQUITTO_DATA"

sudo tee /etc/mosquitto/mosquitto.conf > /dev/null <<EOF
persistence true
persistence_location $MOSQUITTO_DATA/
listener 1883
allow_anonymous true
EOF

sudo systemctl enable mosquitto
sudo systemctl restart mosquitto
echo "Mosquitto MQTT installed and running on port 1883."

# -------------------------
# 4. Install Qdrant vector DB v1.15.5
# -------------------------
echo "Installing Qdrant v1.15.5..."
QDRANT_VERSION="1.15.5"
QDRANT_URL="https://github.com/qdrant/qdrant/releases/download/v1.15.5/qdrant-aarch64-unknown-linux-musl.tar.gz"

sudo mkdir -p "$QDRANT_DATA"
sudo chown -R "$USER":"$USER" "$QDRANT_DATA"

cd /tmp
curl -L "$QDRANT_URL" -o qdrant.tar.gz
tar -xzf qdrant.tar.gz
sudo mv qdrant /usr/local/bin/qdrant
rm qdrant.tar.gz

# Qdrant systemd service
echo "Creating Qdrant systemd service..."
sudo tee /etc/systemd/system/qdrant.service > /dev/null <<EOF
[Unit]
Description=Qdrant Vector Database
After=network.target

[Service]
Type=simple
User=$USER
ExecStart=/usr/local/bin/qdrant --storage-path $QDRANT_DATA
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable qdrant
sudo systemctl start qdrant
echo "Qdrant v${QDRANT_VERSION} installed and running."

# -------------------------
# 5. Firewall / Ports check (optional)
# -------------------------
echo "Checking open ports..."
sudo ss -tulwn | grep -E "5678|1883|6333"

echo "Installation completed successfully!"
echo "Access info:"
echo "n8n: http://<Pi_IP>:5678"
echo "Mosquitto MQTT: tcp://<Pi_IP>:1883"
echo "Qdrant: http://<Pi_IP>:6333"

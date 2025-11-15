#!/bin/bash
set -euo pipefail

# =========================
# Clean SmartHub Install
# =========================

SSD_MOUNT="/mnt/ssd"
N8N_DATA="$SSD_MOUNT/n8n"
QDRANT_DATA="$SSD_MOUNT/qdrant"
MOSQUITTO_DATA="$SSD_MOUNT/mosquitto"
USER_HOME="/home/$USER"

echo "Stopping services..."
sudo systemctl stop n8n 2>/dev/null || true
sudo systemctl stop qdrant 2>/dev/null || true
sudo systemctl stop mosquitto 2>/dev/null || true

echo "Disabling services..."
sudo systemctl disable n8n 2>/dev/null || true
sudo systemctl disable qdrant 2>/dev/null || true
sudo systemctl disable mosquitto 2>/dev/null || true

echo "Removing systemd service files..."
sudo rm -f /etc/systemd/system/n8n.service
sudo rm -f /etc/systemd/system/qdrant.service
# Keep mosquitto package intact if desired; remove custom config
sudo rm -f /etc/mosquitto/mosquitto.conf

sudo systemctl daemon-reload
sudo systemctl reset-failed

echo "Removing installed binaries..."
sudo npm uninstall -g n8n || true
sudo rm -f /usr/local/bin/qdrant || true
sudo rm -f /usr/local/bin/n8n || true

echo "Removing data directories..."
sudo rm -rf "$N8N_DATA"
sudo rm -rf "$QDRANT_DATA"
sudo rm -rf "$MOSQUITTO_DATA"

echo "Removing Node.js (optional)..."
sudo apt remove -y nodejs
sudo apt purge -y nodejs
sudo apt autoremove -y

echo "Removing downloaded files in /tmp..."
sudo rm -f /tmp/qdrant.tar.gz

echo "Clean-up completed. All services, binaries, and data removed."

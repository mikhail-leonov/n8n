#!/bin/bash
set -e

SSD_MOUNT="/mnt/ssd"

DIRS_TO_MOVE=(
    "/var/log"
    "/var/tmp"
    "/var/cache"
    "/var/lib/mosquitto"
    "/var/lib/n8n"
    "/var/lib/qdrant"
    "/home"
    "/opt"
)

echo "Processing directories..."

for d in "${DIRS_TO_MOVE[@]}"; do
    SSD_DIR="$SSD_MOUNT$d"
    OLD_DIR="${d}.old"

    echo "----------------------------------------"
    echo "Handling $d"

    # Ensure source directory exists
    if [ ! -d "$d" ]; then
        echo "Source directory missing, creating empty: $d"
        mkdir -p "$d"
    fi

    # Ensure SSD target exists
    if [ ! -d "$SSD_DIR" ]; then
        echo "Creating SSD directory: $SSD_DIR"
        mkdir -p "$SSD_DIR"
    else
        echo "SSD directory already exists: $SSD_DIR"
    fi

    # Sync only if SSD directory is empty
    if [ -z "$(ls -A "$SSD_DIR" 2>/dev/null)" ]; then
        echo "Syncing $d --> $SSD_DIR (non-destructive)..."
        rsync -aHAX "$d/" "$SSD_DIR/" 2>/dev/null || true
    else
        echo "SSD directory already contains data — skipping rsync."
    fi

    # Rename original dir to .old only if not already done
    if [ ! -e "$OLD_DIR" ]; then
        echo "Renaming original directory: $d --> $OLD_DIR"
        mv "$d" "$OLD_DIR"
    else
        echo "Backup directory exists ($OLD_DIR) — skipping rename."
    fi

    # Create symbolic link from original path to SSD directory
    if [ ! -L "$d" ]; then
        echo "Creating symbolic link: $d --> $SSD_DIR"
        ln -s "$SSD_DIR" "$d"
    else
        echo "Symbolic link already exists: $d"
    fi
done

echo "----------------------------------------"
echo "All done. Originals preserved as .old, symbolic links to SSD active."

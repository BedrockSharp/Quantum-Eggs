#!/bin/bash
# -----------------------------------------------
# QuantumMC - Pterodactyl Start Script
# Runtime: .NET 10
# -----------------------------------------------
QUANTUM_DLL="QuantumMC.dll"
DOWNLOAD_URL="https://github.com/BedrockSharp/QuantumMC/releases/download/v0.0.1-alpha2/QuantumMC.dll"
cd /home/container || { echo "[ERROR] Could not change to /home/container"; exit 1; }
if [ ! -f "$QUANTUM_DLL" ]; then
    echo "[WARN] $QUANTUM_DLL not found. Attempting to download..."
    if command -v wget &> /dev/null; then
        wget -q --show-progress -O "$QUANTUM_DLL" "$DOWNLOAD_URL"
    elif command -v curl &> /dev/null; then
        curl -L --progress-bar -o "$QUANTUM_DLL" "$DOWNLOAD_URL"
    else
        echo "[ERROR] Neither wget nor curl is available. Cannot download $QUANTUM_DLL."
        exit 1
    fi
    if [ ! -f "$QUANTUM_DLL" ]; then
        echo "[ERROR] Download failed. Please manually upload $QUANTUM_DLL to /home/container."
        exit 1
    fi
    echo "[INFO] Download complete."
fi
CRASH_COUNT=0
MAX_CRASHES=5
CRASH_WINDOW=60  # seconds
LAST_CRASH_TIME=0
while true; do
    echo "[INFO] Starting QuantumMC..."
    dotnet "$QUANTUM_DLL"
    EXIT_CODE=$?
    NOW=$(date +%s)
    TIME_SINCE_LAST=$((NOW - LAST_CRASH_TIME))
    if [ $EXIT_CODE -eq 0 ]; then
        echo "[INFO] Server exited cleanly (code 0). Shutting down."
        exit 0
    fi
    echo "[WARN] Server stopped with exit code $EXIT_CODE."
    if [ $TIME_SINCE_LAST -gt $CRASH_WINDOW ]; then
        CRASH_COUNT=0
    fi
    CRASH_COUNT=$((CRASH_COUNT + 1))
    LAST_CRASH_TIME=$NOW
    if [ $CRASH_COUNT -ge $MAX_CRASHES ]; then
        echo "[ERROR] Server crashed $MAX_CRASHES times within ${CRASH_WINDOW}s. Giving up."
        exit 1
    fi
    echo "[WARN] Server crashed. Restarting in 5 seconds... (crash $CRASH_COUNT/$MAX_CRASHES)"
    sleep 5
done

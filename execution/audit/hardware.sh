#!/bin/bash
# hardware.sh - Hardware detection for Linux Mint Cinnamon systems
# Part of Mint System Assistant
# Exports AUDIT_* environment variables for profile generation

set -o pipefail

# ============================================
# CPU DETECTION
# ============================================

detect_cpu() {
    # Model name
    AUDIT_CPU_MODEL=$(lscpu 2>/dev/null | grep "Model name" | sed 's/Model name:[[:space:]]*//' | head -1)

    # Get actual physical cores (not threads)
    local cores_per_socket=$(lscpu 2>/dev/null | grep "Core(s) per socket:" | awk '{print $4}')
    local sockets=$(lscpu 2>/dev/null | grep "Socket(s):" | awk '{print $2}')
    AUDIT_CPU_CORES=$((${cores_per_socket:-1} * ${sockets:-1}))

    # Get total threads (logical CPUs)
    AUDIT_CPU_THREADS=$(lscpu 2>/dev/null | grep "^CPU(s):" | awk '{print $2}')
    if [ -z "$AUDIT_CPU_THREADS" ]; then
        AUDIT_CPU_THREADS=$(nproc --all 2>/dev/null || grep -c ^processor /proc/cpuinfo)
    fi

    # Architecture detection (AMD Zen, Intel)
    AUDIT_CPU_ARCH=""
    if echo "$AUDIT_CPU_MODEL" | grep -qiE "Ryzen.*(9[0-9]{3}|8[0-9]{3})"; then
        AUDIT_CPU_ARCH="Zen 5 (Granite Ridge)"
    elif echo "$AUDIT_CPU_MODEL" | grep -qiE "Ryzen.*(7[0-9]{3})"; then
        AUDIT_CPU_ARCH="Zen 4 (Raphael)"
    elif echo "$AUDIT_CPU_MODEL" | grep -qiE "Ryzen.*(5[0-9]{3}|6[0-9]{3})"; then
        AUDIT_CPU_ARCH="Zen 3/4"
    elif echo "$AUDIT_CPU_MODEL" | grep -qiE "Ryzen.*(3[0-9]{3}|4[0-9]{3})"; then
        AUDIT_CPU_ARCH="Zen 2/3"
    elif echo "$AUDIT_CPU_MODEL" | grep -qiE "Core.*i[579]-1[4-5]"; then
        AUDIT_CPU_ARCH="Raptor Lake"
    elif echo "$AUDIT_CPU_MODEL" | grep -qiE "Core.*i[579]-1[2-3]"; then
        AUDIT_CPU_ARCH="Alder Lake"
    fi

    # Base and max frequency
    AUDIT_CPU_BASE_FREQ=$(lscpu 2>/dev/null | grep "CPU MHz:" | awk '{printf "%.2f GHz", $3/1000}')
    AUDIT_CPU_MAX_FREQ=$(lscpu 2>/dev/null | grep "CPU max MHz:" | awk '{printf "%.2f GHz", $4/1000}')

    # CPU features
    local flags=$(grep "^flags" /proc/cpuinfo 2>/dev/null | head -1)
    AUDIT_CPU_FEATURES=""
    echo "$flags" | grep -q "avx512" && AUDIT_CPU_FEATURES+="AVX-512, "
    echo "$flags" | grep -q "avx2" && AUDIT_CPU_FEATURES+="AVX2, "
    echo "$flags" | grep -q "aes" && AUDIT_CPU_FEATURES+="AES-NI, "
    echo "$flags" | grep -q "svm\|vmx" && AUDIT_CPU_FEATURES+="Virtualization, "
    AUDIT_CPU_FEATURES="${AUDIT_CPU_FEATURES%, }"

    # Cache sizes
    AUDIT_CPU_L3_CACHE=$(lscpu 2>/dev/null | grep "L3 cache:" | awk '{print $3 $4}')

    export AUDIT_CPU_MODEL AUDIT_CPU_CORES AUDIT_CPU_THREADS AUDIT_CPU_ARCH
    export AUDIT_CPU_BASE_FREQ AUDIT_CPU_MAX_FREQ AUDIT_CPU_FEATURES AUDIT_CPU_L3_CACHE
}

# ============================================
# GPU DETECTION
# ============================================

detect_gpu() {
    AUDIT_GPU_MODEL=""
    AUDIT_GPU_VRAM=""
    AUDIT_GPU_DRIVER=""
    AUDIT_GPU_CUDA=""
    AUDIT_GPU_ARCH=""
    AUDIT_GPU_SECONDARY=""
    AUDIT_GPU_TEMP=""

    # Check for NVIDIA GPU
    if command -v nvidia-smi &>/dev/null; then
        AUDIT_GPU_MODEL=$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | head -1)
        AUDIT_GPU_VRAM=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader 2>/dev/null | head -1)
        AUDIT_GPU_DRIVER=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null | head -1)
        AUDIT_GPU_CUDA=$(nvidia-smi 2>/dev/null | grep "CUDA Version" | sed 's/.*CUDA Version: //' | awk '{print $1}')
        AUDIT_GPU_TEMP=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader 2>/dev/null | head -1)

        # Detect architecture from model name
        if echo "$AUDIT_GPU_MODEL" | grep -qE "RTX (50[0-9]{2}|60[0-9]{2})"; then
            AUDIT_GPU_ARCH="Blackwell"
        elif echo "$AUDIT_GPU_MODEL" | grep -qE "RTX 40[0-9]{2}"; then
            AUDIT_GPU_ARCH="Ada Lovelace"
        elif echo "$AUDIT_GPU_MODEL" | grep -qE "RTX 30[0-9]{2}"; then
            AUDIT_GPU_ARCH="Ampere"
        elif echo "$AUDIT_GPU_MODEL" | grep -qE "RTX 20[0-9]{2}"; then
            AUDIT_GPU_ARCH="Turing"
        elif echo "$AUDIT_GPU_MODEL" | grep -qE "GTX 16[0-9]{2}"; then
            AUDIT_GPU_ARCH="Turing"
        fi

        # Check for open kernel modules
        if modinfo nvidia 2>/dev/null | grep -q "open"; then
            AUDIT_GPU_DRIVER_TYPE="open kernel modules"
        else
            AUDIT_GPU_DRIVER_TYPE="proprietary"
        fi
    fi

    # Check for AMD GPU (secondary/iGPU)
    local gpu_pci=$(lspci 2>/dev/null | grep -iE "VGA|3D|Display")
    if echo "$gpu_pci" | grep -qiE "AMD.*Radeon|ATI.*Radeon"; then
        local amd_line=$(echo "$gpu_pci" | grep -iE "AMD.*Radeon|ATI.*Radeon" | head -1)
        local amd_model=$(echo "$amd_line" | sed 's/.*: //' | sed 's/\[.*\]//' | xargs)

        # Check if it's an unnamed device (new hardware)
        if echo "$amd_model" | grep -qE "Device [0-9a-f]+" && ! echo "$amd_model" | grep -qiE "Radeon|RX"; then
            AUDIT_GPU_SECONDARY="AMD iGPU (amdgpu)"
        else
            AUDIT_GPU_SECONDARY="$amd_model"
        fi
    fi

    # GPU switching mode (PRIME)
    AUDIT_GPU_PRIME_MODE=""
    if command -v prime-select &>/dev/null; then
        AUDIT_GPU_PRIME_MODE=$(prime-select query 2>/dev/null)
    fi

    export AUDIT_GPU_MODEL AUDIT_GPU_VRAM AUDIT_GPU_DRIVER AUDIT_GPU_CUDA
    export AUDIT_GPU_ARCH AUDIT_GPU_SECONDARY AUDIT_GPU_TEMP AUDIT_GPU_DRIVER_TYPE
    export AUDIT_GPU_PRIME_MODE
}

# ============================================
# MEMORY DETECTION
# ============================================

detect_memory() {
    # Total RAM
    AUDIT_RAM_TOTAL=$(free -h 2>/dev/null | awk '/Mem:/ {print $2}')
    AUDIT_RAM_TOTAL_GB=$(free -g 2>/dev/null | awk '/Mem:/ {print $2}')

    # Used RAM
    AUDIT_RAM_USED=$(free -h 2>/dev/null | awk '/Mem:/ {print $3}')

    # RAM type (requires dmidecode - may need sudo)
    AUDIT_RAM_TYPE=$(sudo dmidecode -t memory 2>/dev/null | grep "Type:" | grep -v "Error\|Unknown" | head -1 | awk '{print $2}')
    [ -z "$AUDIT_RAM_TYPE" ] && AUDIT_RAM_TYPE="Unknown"

    # RAM speed
    AUDIT_RAM_SPEED=$(sudo dmidecode -t memory 2>/dev/null | grep "Speed:" | grep -v "Unknown" | head -1 | awk '{print $2 " " $3}')

    # Swap
    AUDIT_SWAP_TOTAL=$(free -h 2>/dev/null | awk '/Swap:/ {print $2}')

    # Check for zram
    if [ -d /sys/block/zram0 ]; then
        local zram_size=$(cat /sys/block/zram0/disksize 2>/dev/null)
        AUDIT_ZRAM_SIZE=$(echo "scale=0; $zram_size / 1024 / 1024 / 1024" | bc 2>/dev/null || echo "enabled")
    else
        AUDIT_ZRAM_SIZE=""
    fi

    export AUDIT_RAM_TOTAL AUDIT_RAM_TOTAL_GB AUDIT_RAM_USED AUDIT_RAM_TYPE
    export AUDIT_RAM_SPEED AUDIT_SWAP_TOTAL AUDIT_ZRAM_SIZE
}

# ============================================
# STORAGE DETECTION
# ============================================

detect_storage() {
    AUDIT_STORAGE_MODEL=""
    AUDIT_STORAGE_SIZE=""
    AUDIT_STORAGE_TYPE=""

    # Try to find primary NVMe/SSD device directly
    local primary_device=""

    # Check for NVMe first
    if [ -b /dev/nvme0n1 ]; then
        primary_device="nvme0n1"
    # Check for SATA SSD/HDD
    elif [ -b /dev/sda ]; then
        primary_device="sda"
    fi

    if [ -n "$primary_device" ]; then
        # Get storage model
        if [ -f "/sys/block/$primary_device/device/model" ]; then
            AUDIT_STORAGE_MODEL=$(cat /sys/block/$primary_device/device/model 2>/dev/null | xargs)
        fi

        # Get size using lsblk
        AUDIT_STORAGE_SIZE=$(lsblk -d -n -o SIZE /dev/$primary_device 2>/dev/null)

        # Detect storage type
        local rotational=$(cat /sys/block/$primary_device/queue/rotational 2>/dev/null)
        if echo "$primary_device" | grep -q "nvme"; then
            AUDIT_STORAGE_TYPE="NVMe SSD"
        elif [ "$rotational" = "0" ]; then
            AUDIT_STORAGE_TYPE="SATA SSD"
        else
            AUDIT_STORAGE_TYPE="HDD"
        fi
    fi

    # Fallback: use lsblk to get model info if direct read failed
    if [ -z "$AUDIT_STORAGE_MODEL" ] && [ -n "$primary_device" ]; then
        AUDIT_STORAGE_MODEL=$(lsblk -d -n -o MODEL /dev/$primary_device 2>/dev/null | xargs)
    fi

    # Disk usage
    AUDIT_DISK_USED=$(df -h / 2>/dev/null | awk 'NR==2 {print $3}')
    AUDIT_DISK_TOTAL=$(df -h / 2>/dev/null | awk 'NR==2 {print $2}')
    AUDIT_DISK_PERCENT=$(df -h / 2>/dev/null | awk 'NR==2 {print $5}')

    # Check for LUKS encryption
    if lsblk -o FSTYPE 2>/dev/null | grep -q "crypto_LUKS"; then
        AUDIT_STORAGE_ENCRYPTED="LUKS"
    else
        AUDIT_STORAGE_ENCRYPTED="No"
    fi

    export AUDIT_STORAGE_MODEL AUDIT_STORAGE_SIZE AUDIT_STORAGE_TYPE
    export AUDIT_DISK_USED AUDIT_DISK_TOTAL AUDIT_DISK_PERCENT AUDIT_STORAGE_ENCRYPTED
}

# ============================================
# MOTHERBOARD DETECTION
# ============================================

detect_motherboard() {
    AUDIT_MB_MODEL=$(cat /sys/class/dmi/id/board_name 2>/dev/null)
    AUDIT_MB_VENDOR=$(cat /sys/class/dmi/id/board_vendor 2>/dev/null)
    AUDIT_MB_BIOS=$(cat /sys/class/dmi/id/bios_version 2>/dev/null)
    AUDIT_MB_BIOS_DATE=$(cat /sys/class/dmi/id/bios_date 2>/dev/null)

    # Chipset detection
    local chipset=$(lspci 2>/dev/null | grep -i "Host bridge" | head -1 | sed 's/.*: //')
    if echo "$chipset" | grep -qiE "AMD"; then
        AUDIT_MB_CHIPSET=$(echo "$chipset" | grep -oE "[ABCX][0-9]{3}" | head -1)
    elif echo "$chipset" | grep -qiE "Intel"; then
        AUDIT_MB_CHIPSET=$(echo "$chipset" | grep -oE "[ZHBQ][0-9]{3}" | head -1)
    fi

    export AUDIT_MB_MODEL AUDIT_MB_VENDOR AUDIT_MB_BIOS AUDIT_MB_BIOS_DATE AUDIT_MB_CHIPSET
}

# ============================================
# DISPLAY DETECTION (xrandr for X11)
# ============================================

detect_display() {
    AUDIT_DISPLAY_OUTPUT=""
    AUDIT_DISPLAY_RESOLUTION=""
    AUDIT_DISPLAY_REFRESH=""
    AUDIT_DISPLAY_CONNECTION=""
    AUDIT_DISPLAY_MODEL=""

    # Use xrandr for X11/Cinnamon
    if command -v xrandr &>/dev/null; then
        local output=$(xrandr --current 2>/dev/null)

        # Parse primary connected output
        local primary_line=$(echo "$output" | grep " connected" | head -1)
        AUDIT_DISPLAY_OUTPUT=$(echo "$primary_line" | awk '{print $1}')

        # Parse resolution from current mode (marked with *)
        local mode_line=$(echo "$output" | grep '\*' | head -1)
        if [ -n "$mode_line" ]; then
            AUDIT_DISPLAY_RESOLUTION=$(echo "$mode_line" | awk '{print $1}')
            AUDIT_DISPLAY_REFRESH=$(echo "$mode_line" | grep -oE '[0-9]+\.[0-9]+\*' | tr -d '*')
            [ -n "$AUDIT_DISPLAY_REFRESH" ] && AUDIT_DISPLAY_REFRESH="${AUDIT_DISPLAY_REFRESH} Hz"
        fi

        # Connection type from output name
        if echo "$AUDIT_DISPLAY_OUTPUT" | grep -q "DP"; then
            AUDIT_DISPLAY_CONNECTION="DisplayPort"
        elif echo "$AUDIT_DISPLAY_OUTPUT" | grep -q "HDMI"; then
            AUDIT_DISPLAY_CONNECTION="HDMI"
        elif echo "$AUDIT_DISPLAY_OUTPUT" | grep -q "eDP"; then
            AUDIT_DISPLAY_CONNECTION="Internal (eDP)"
        elif echo "$AUDIT_DISPLAY_OUTPUT" | grep -q "VGA"; then
            AUDIT_DISPLAY_CONNECTION="VGA"
        fi

        # Try to get monitor model via xrandr --prop
        if [ -n "$AUDIT_DISPLAY_OUTPUT" ]; then
            AUDIT_DISPLAY_MODEL=$(xrandr --prop 2>/dev/null | grep -A5 "^$AUDIT_DISPLAY_OUTPUT" | grep "EDID" -A1 | tail -1 | xargs 2>/dev/null)
            # Fallback: just report the output name
            [ -z "$AUDIT_DISPLAY_MODEL" ] && AUDIT_DISPLAY_MODEL="$AUDIT_DISPLAY_OUTPUT"
        fi
    fi

    export AUDIT_DISPLAY_OUTPUT AUDIT_DISPLAY_RESOLUTION AUDIT_DISPLAY_REFRESH AUDIT_DISPLAY_CONNECTION AUDIT_DISPLAY_MODEL
}

# ============================================
# NETWORK DETECTION
# ============================================

detect_network() {
    AUDIT_NET_INTERFACES=""

    # Get active network interface
    local default_if=$(ip route 2>/dev/null | grep default | awk '{print $5}' | head -1)

    if [ -n "$default_if" ]; then
        # Interface type
        if echo "$default_if" | grep -qE "^wl"; then
            AUDIT_NET_TYPE="WiFi"
            # Get WiFi info
            AUDIT_NET_SSID=$(iwgetid -r 2>/dev/null)
        elif echo "$default_if" | grep -qE "^en|^eth"; then
            AUDIT_NET_TYPE="Ethernet"
        fi

        # Get driver
        AUDIT_NET_DRIVER=$(readlink /sys/class/net/$default_if/device/driver 2>/dev/null | xargs basename)

        # Get IP
        AUDIT_NET_IP=$(ip -4 addr show "$default_if" 2>/dev/null | grep inet | awk '{print $2}' | cut -d/ -f1)

        AUDIT_NET_INTERFACE="$default_if"
    fi

    export AUDIT_NET_INTERFACE AUDIT_NET_TYPE AUDIT_NET_DRIVER AUDIT_NET_IP AUDIT_NET_SSID
}

# ============================================
# AUDIO DETECTION
# ============================================

detect_audio() {
    # Detect audio server
    if pgrep -x "pipewire" > /dev/null; then
        AUDIT_AUDIO_SERVER="PipeWire"
        AUDIT_AUDIO_VERSION=$(pipewire --version 2>/dev/null | head -1 | awk '{print $NF}')
    elif pgrep -x "pulseaudio" > /dev/null; then
        AUDIT_AUDIO_SERVER="PulseAudio"
        AUDIT_AUDIO_VERSION=$(pulseaudio --version 2>/dev/null | awk '{print $NF}')
    else
        AUDIT_AUDIO_SERVER="ALSA"
        AUDIT_AUDIO_VERSION=""
    fi

    # Default sink (output)
    if command -v pactl &>/dev/null; then
        AUDIT_AUDIO_OUTPUT=$(pactl get-default-sink 2>/dev/null)
        AUDIT_AUDIO_INPUT=$(pactl get-default-source 2>/dev/null)
    fi

    export AUDIT_AUDIO_SERVER AUDIT_AUDIO_VERSION AUDIT_AUDIO_OUTPUT AUDIT_AUDIO_INPUT
}

# ============================================
# USB DEVICES DETECTION
# ============================================

detect_usb() {
    AUDIT_USB_DEVICES=""

    if command -v lsusb &>/dev/null; then
        # Get interesting USB devices (filter out hubs and generic controllers)
        AUDIT_USB_DEVICES=$(lsusb 2>/dev/null | grep -viE "hub|root hub|controller" | sed 's/Bus [0-9]* Device [0-9]*: ID [0-9a-f:]*  *//' | head -10)
    fi

    export AUDIT_USB_DEVICES
}

# ============================================
# MAIN: RUN ALL DETECTIONS
# ============================================

main() {
    detect_cpu
    detect_gpu
    detect_memory
    detect_storage
    detect_motherboard
    detect_display
    detect_network
    detect_audio
    detect_usb
}

# Always run main to populate AUDIT_* variables
main

# Print summary if run directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "=== Hardware Detection Summary ==="
    echo "CPU: $AUDIT_CPU_MODEL ($AUDIT_CPU_CORES cores / $AUDIT_CPU_THREADS threads)"
    echo "GPU: $AUDIT_GPU_MODEL ($AUDIT_GPU_VRAM)"
    [ -n "$AUDIT_GPU_PRIME_MODE" ] && echo "PRIME: $AUDIT_GPU_PRIME_MODE"
    echo "RAM: $AUDIT_RAM_TOTAL ($AUDIT_RAM_TYPE)"
    echo "Storage: $AUDIT_STORAGE_MODEL ($AUDIT_STORAGE_SIZE, $AUDIT_STORAGE_TYPE)"
    echo "Display: $AUDIT_DISPLAY_RESOLUTION @ $AUDIT_DISPLAY_REFRESH"
fi

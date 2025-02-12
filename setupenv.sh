#!/bin/bash

#!/bin/bash

# Default paths - can be overridden with command line arguments
KLIPPER_DIR="${HOME}/klipper"
KLIPPY_ENV="${HOME}/klippy-env"
CONFIG_DIR="${HOME}/klipper_config"
BACKUP_DIR="${HOME}/q1pro-klipper-backup"

# Print usage information
usage() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -a, --all         Perform all operations"
    echo "  -b, --backup      Only backup config files"
    echo "  -u, --update      Only update Python packages"
    echo "  -p, --patch       Only apply patches"
    echo "  -i, --install     Install Beacon3D"
    echo "  -k, --klipper     Specify custom Klipper directory"
    echo "  -c, --config      Specify custom config directory"
    echo "  -h, --help        Display this help message"
    exit 1
}

# Logging function
log() {
    local level=$1
    shift
    case $level in
        "INFO")
            echo -e "[INFO] $*"
            ;;
        "WARN")
            echo -e "[WARN] $*"
            ;;
        "ERROR")
            echo -e "[ERROR] $*"
            ;;
    esac
}

# Backup function
backup_configs() {
    log "INFO" "Starting config backup..."


    local backup_path="${BACKUP_DIR}"

    if [ ! -d "$BACKUP_DIR" ]; then
        mkdir -p "$BACKUP_DIR"
    fi

    if [ ! -d "$CONFIG_DIR" ]; then
        log "ERROR" "Config directory not found: $CONFIG_DIR"
        return 1
    fi

    # Create backup
    mkdir -p "$backup_path"
    if (tar cvf - ${KLIPPER_DIR} ${CONFIG_DIR}) | (cd ${BACKUP_DIR}; tar xf -) then
        log "INFO" "Backup created successfully at: $backup_path"

    else
        log "ERROR" "Backup failed"
        return 1
    fi
}

# Update Python packages
update_python() {
    log "INFO" "Updating Python packages..."

    if [ ! -d "$KLIPPER_DIR" ]; then
        log "ERROR" "Klipper directory not found: $KLIPPER_DIR"
        return 1
    fi

    sudo service klipper stop

    cd $HOME

    wget https://github.com/stew675/ShakeTune_For_Qidi/releases/download/v1.0.0/python-3-12-3.tgz

    tar xvzf python-3-12-3.tgz

    rm python-3-12-3.tgz

    sudo rm -rf $KLIPPY_ENV

    ~/python-3.12.3/bin/python3.12 -m venv klippy-env

    cd ~/klippy-env

    sed -i 's/greenlet==1.1.2/greenlet==3.0.3/' $KLIPPER_DIR/scripts/klippy-requirements.txt # Need to upgrade this package for 3.12.


    if bin/pip install -r $KLIPPER_DIR/scripts/klippy-requirements.txt; then
        log "INFO" "Python packages updated successfully"
    else
        log "ERROR" "Failed to update Python packages"
        return 1
    fi
}

# Install Beacon3D
install_beacon3d() {
    log "INFO" "Installing Beacon3D..."

    # Check if beacon_klipper directory already exists
    if [ -d "${HOME}/beacon_klipper" ]; then
        log "WARN" "Beacon3D directory already exists. Removing for fresh install..."
        rm -rf "${HOME}/beacon_klipper"
    fi

    # Clone the repository
    cd "${HOME}" || exit 1
    if git clone https://github.com/beacon3d/beacon_klipper.git; then
        log "INFO" "Successfully cloned Beacon3D repository"
    else
        log "ERROR" "Failed to clone Beacon3D repository"
        return 1
    fi

    # Run the install script
    cd "${HOME}/beacon_klipper" || exit 1
    if ./install.sh; then
        log "INFO" "Successfully installed Beacon3D"
    else
        log "ERROR" "Failed to install Beacon3D"
        return 1
    fi
}

# Apply patches
apply_patches() {
    log "INFO" "Applying patches..."

    if [ ! -d "$PATCH_DIR" ]; then
        log "ERROR" "Patch directory not found: $PATCH_DIR"
        return 1
    fi

    if [ ! -d "$KLIPPER_DIR" ]; then
        log "ERROR" "Klipper directory not found: $KLIPPER_DIR"
        return 1
    fi

    # Navigate to Klipper directory
    cd "$KLIPPER_DIR" || exit 1

    # Apply each patch file
    for patch_file in "$PATCH_DIR"/*.patch; do
        if [ -f "$patch_file" ]; then
            log "INFO" "Applying patch: $(basename "$patch_file")"
            if [ "$(basename "$patch_file")" = "printer_cfg.patch" ]; then
                local bdev = $( ls /dev/serial/by-id/usb-Beacon* | head -n1 )
                sed -i "s|{{beacon_dev}}|$bdev|g" "$patch_file"
            fi
            if patch < "$patch_file"; then
                log "INFO" "Successfully applied patch: $(basename "$patch_file")"
            else
                log "ERROR" "Failed to apply patch: $(basename "$patch_file")"
                return 1
            fi
        fi
    done
}

# Parse command line arguments
DO_ALL=0
DO_BACKUP=0
DO_UPDATE=0
DO_PATCH=0
DO_INSTALL=0

while [[ $# -gt 0 ]]; do
    case $1 in
        -a|--all)
            DO_ALL=1
            shift
            ;;
        -b|--backup)
            DO_BACKUP=1
            shift
            ;;
        -u|--update)
            DO_UPDATE=1
            shift
            ;;
        -p|--patch)
            DO_PATCH=1
            shift
            ;;
        -i|--install)
            DO_INSTALL=1
            shift
            ;;
        -k|--klipper)
            KLIPPER_DIR="$2"
            shift 2
            ;;
        -c|--config)
            CONFIG_DIR="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

# If no specific operations selected, show usage
if [ $DO_ALL -eq 0 ] && [ $DO_BACKUP -eq 0 ] && [ $DO_UPDATE -eq 0 ] && [ $DO_PATCH -eq 0 ] && [ $DO_INSTALL -eq 0 ]; then
    usage
fi

# Perform selected operations
if [ $DO_ALL -eq 1 ] || [ $DO_BACKUP -eq 1 ]; then
    backup_configs || exit 1
fi

if [ $DO_ALL -eq 1 ] || [ $DO_UPDATE -eq 1 ]; then
    update_python || exit 1
fi

if [ $DO_ALL -eq 1 ] || [ $DO_PATCH -eq 1 ]; then
    apply_patches || exit 1
fi

if [ $DO_ALL -eq 1 ] || [ $DO_INSTALL -eq 1 ]; then
    install_beacon3d || exit 1
fi

log "INFO" "All operations completed successfully"
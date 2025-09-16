#!/bin/bash

# ──────────────────────────────────────────────────────────────
# 🎨 Terminal Colors
# ──────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

info()    { echo -e "${BLUE}${BOLD}→${NC} ${BLUE}$1${NC}"; }
success() { echo -e "${GREEN}${BOLD}✔${NC} ${GREEN}$1${NC}"; }
warn()    { echo -e "${YELLOW}${BOLD}!${NC} ${YELLOW}$1${NC}"; }
error()   { echo -e "${RED}${BOLD}✖${NC} ${RED}$1${NC}"; }
divider() { echo -e "${BOLD}──────────────────────────────────────────────${NC}"; }

# Ensure script is run from repo root
ROOT_DIR=$(pwd)

# ──────────────────────────────────────────────────────────────
# Apply Recovery Patch (non-fatal warning only)
# ──────────────────────────────────────────────────────────────
apply_recovery_patch() {
    local root_dir
    root_dir=$(pwd)
    local target_dir="bootable/recovery"
    local patch_file="$root_dir/device/xiaomi/pipa/patches/atomic-recovery.diff"
    local temp_patch="/tmp/atomic-recovery.patch"

    info "Attempting to apply recovery patch..."

    if [ ! -f "$patch_file" ]; then
        warn "Patch file not found, skipping: $patch_file"
        return
    fi

    if ! cd "$target_dir"; then
        warn "Could not enter $target_dir, skipping patch."
        return
    fi
    
    tr -d '\r' < "$patch_file" > "$temp_patch"

    if git apply --check --ignore-whitespace "$temp_patch" >/dev/null 2>&1; then
        if git apply --ignore-whitespace "$temp_patch" >/dev/null 2>&1; then
            git add .
            git commit -m "Apply recovery patch: $(sha1sum "$temp_patch" | awk '{print $1}')" -q || true
            success "Recovery patch applied successfully."
        else
            warn "Recovery patch failed to apply cleanly; skipping."
            git reset --hard HEAD >/dev/null 2>&1 || true
            git clean -fd >/dev/null 2>&1 || true
        fi
    else
        warn "Recovery patch is already applied or not applicable; skipping."
    fi

    rm -f "$temp_patch"
    cd "$root_dir"
}

# ──────────────────────────────────────────────────────────────
# Apply Tablet FW Patch (git apply; no git am)
# ──────────────────────────────────────────────────────────────
apply_tablet_patch() {
    local root_dir
    root_dir=$(pwd)
    local target_dir="frameworks/base"
    local patch_file="$root_dir/device/xiaomi/pipa/patches/tablet-fwb.patch"
    local temp_patch="/tmp/tablet-fwb.patch"

    info "Attempting to apply tablet-fwb.patch..."

    if [ ! -f "$patch_file" ]; then
        warn "Patch file not found, skipping: $patch_file"
        return
    fi

    if ! cd "$target_dir"; then
        warn "Could not enter $target_dir, skipping patch."
        return
    fi

    tr -d '\r' < "$patch_file" > "$temp_patch"

    if git apply --check --ignore-whitespace "$temp_patch" >/dev/null 2>&1; then
        if git apply --ignore-whitespace "$temp_patch" >/dev/null 2>&1; then
            git add .
            git commit -m "Apply tablet patch: $(sha1sum "$temp_patch" | awk '{print $1}')" -q || true
            success "Tablet patch applied successfully."
        else
            warn "Tablet patch failed to apply cleanly; skipping."
            git reset --hard HEAD >/dev/null 2>&1 || true
            git clean -fd >/dev/null 2>&1 || true
        fi
    else
        warn "Tablet patch seems to be already applied or not applicable; skipping."
    fi

    rm -f "$temp_patch"
    cd "$root_dir"
}

# ──────────────────────────────────────────────────────────────
# Run Patch Setup
# ──────────────────────────────────────────────────────────────
DEVICE_PATH="${ROOT_DIR}/device/xiaomi/pipa"
mkdir -p "$DEVICE_PATH/patches"

apply_recovery_patch
apply_tablet_patch

echo "-------------------------------------"
echo "           Setup complete!           "
echo "-------------------------------------"

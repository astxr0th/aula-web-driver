#!/usr/bin/env bash

set -euo pipefail

AULA_VENDOR_ID="2e3c"   # confirmed from an actual Aula WIN60 HE (idVendor 0x2e3c); add more
                        # below if you have an Aula device that reports a different vendor id
WEBDRIVER_URL="https://www.aulastar.com/web-drive/"
UDEV_RULE_PATH="/etc/udev/rules.d/70-aula-webhid.rules"

log() { printf '==> %s\n' "$1"; }
err() { printf 'ERROR: %s\n' "$1" >&2; }

require_root_reexec() {
    [ "$(id -u)" -eq 0 ] && return
    local self esc
    self="$(readlink -f "$0")"
    if command -v sudo >/dev/null 2>&1; then esc=sudo
    elif command -v doas >/dev/null 2>&1; then esc=doas
    elif command -v pkexec >/dev/null 2>&1; then esc=pkexec
    else
        err "Need root for package install + udev rule, and no sudo/doas/pkexec found."
        err "Re-run this script as root manually: su -c '$self'"
        exit 1
    fi
    log "Re-running with $esc for the privileged steps..."
    exec "$esc" "$self" "$@"
}

detect_pm() {
    if command -v pacman >/dev/null 2>&1; then echo pacman
    elif command -v apt-get >/dev/null 2>&1; then echo apt
    elif command -v dnf >/dev/null 2>&1; then echo dnf
    elif command -v yum >/dev/null 2>&1; then echo yum
    elif command -v zypper >/dev/null 2>&1; then echo zypper
    elif command -v apk >/dev/null 2>&1; then echo apk
    elif command -v xbps-install >/dev/null 2>&1; then echo xbps
    elif command -v emerge >/dev/null 2>&1; then echo emerge
    elif command -v nix-env >/dev/null 2>&1; then echo nix
    else echo unknown
    fi
}

find_webhid_browser() {
    local bin
    for bin in chromium chromium-browser google-chrome google-chrome-stable \
               brave-browser brave microsoft-edge microsoft-edge-stable \
               vivaldi-stable vivaldi opera; do
        command -v "$bin" >/dev/null 2>&1 && { echo "$bin"; return 0; }
    done
    if command -v flatpak >/dev/null 2>&1; then
        local app
        for app in org.chromium.Chromium com.google.Chrome com.brave.Browser \
                   com.microsoft.Edge com.vivaldi.Vivaldi com.opera.Opera; do
            flatpak info "$app" >/dev/null 2>&1 && { echo "flatpak run $app"; return 0; }
        done
    fi
    if command -v snap >/dev/null 2>&1 && snap list chromium >/dev/null 2>&1; then
        echo "chromium"; return 0
    fi
    return 1
}

install_browser() {
    local pm="$1"
    log "No WebHID-capable browser found - installing Chromium via $pm"
    case "$pm" in
        pacman) pacman -Sy --needed --noconfirm chromium ;;
        apt)
            apt-get update
            if ! apt-get install -y chromium 2>/dev/null && ! apt-get install -y chromium-browser 2>/dev/null; then
                if command -v snap >/dev/null 2>&1; then
                    log "APT chromium package unavailable (common on newer Ubuntu) - trying snap"
                    snap install chromium
                else
                    err "Could not install chromium via apt or snap."
                    exit 1
                fi
            fi
            ;;
        dnf)    dnf install -y chromium ;;
        yum)    yum install -y chromium ;;
        zypper) zypper --non-interactive install chromium ;;
        apk)    apk add --no-cache chromium ;;
        xbps)   xbps-install -Sy chromium ;;
        emerge) emerge --ask=n www-client/chromium ;;
        nix)    nix-env -iA nixpkgs.chromium ;;
        *)
            if command -v flatpak >/dev/null 2>&1; then
                log "Unknown package manager - trying Flatpak instead"
                flatpak install -y --noninteractive flathub org.chromium.Chromium
            else
                err "Don't know how to install a browser on this system, and flatpak isn't available."
                err "Install any Chromium-based browser (Chrome, Chromium, Brave, Edge, Vivaldi, Opera) manually, then re-run this script."
                exit 1
            fi
            ;;
    esac
}

install_udev_rule() {
    log "Installing udev rule for Aula HID devices (vendor id $AULA_VENDOR_ID) at $UDEV_RULE_PATH"
    cat > "$UDEV_RULE_PATH" <<EOF
# Grants the active logged-in user access to Aula HID/USB devices so browser-based
# WebHID drivers (aulastar.com/web-drive etc.) can see and open them.
SUBSYSTEM=="hidraw", ATTRS{idVendor}=="$AULA_VENDOR_ID", MODE="0660", GROUP="plugdev", TAG+="uaccess"
SUBSYSTEM=="usb", ATTRS{idVendor}=="$AULA_VENDOR_ID", MODE="0660", GROUP="plugdev", TAG+="uaccess"
EOF
    getent group plugdev >/dev/null 2>&1 || groupadd plugdev
    local real_user="${SUDO_USER:-${DOAS_USER:-}}"
    [ -n "$real_user" ] && usermod -aG plugdev "$real_user"
    udevadm control --reload-rules
    udevadm trigger
}

main() {
    require_root_reexec "$@"

    install_udev_rule

    local browser
    if browser="$(find_webhid_browser)"; then
        log "Found WebHID-capable browser: $browser"
    else
        install_browser "$(detect_pm)"
        browser="$(find_webhid_browser)" || { err "Browser install seems to have failed."; exit 1; }
    fi

    echo
    log "Done. Launch the official Aula web driver with:"
    echo
    echo "    $browser \"$WEBDRIVER_URL\""
    echo
    log "Firefox and Safari cannot run this driver (no WebHID support, by browser-vendor choice)."
    log "If your keyboard was already plugged in, unplug/replug it once so the new udev rule applies."
}

main "$@"

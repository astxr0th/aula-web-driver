# aula-web-driver
a script to make the aula web driver work on every linux distro (only for chromium based browser as firefox doesn't support webhid)

# aula-webdriver-setup.sh
#
# Makes the official AULA web driver (aulastar.com/web-drive, WebHID-based) usable on
# any Linux distro, for any Aula HID device.
#
# WebHID is only implemented by Chromium-based browsers (Chrome, Chromium, Brave, Edge,
# Vivaldi, Opera). Firefox and Safari have never implemented it - that's a browser-vendor
# decision, and no script run outside the browser can change it. What this script actually
# fixes, on any distro:
#   1. Makes sure a WebHID-capable browser is installed (native package manager, with a
#      Flatpak/snap fallback where the native package is missing or renamed).
#   2. Installs a udev rule granting your user access to Aula HID devices, so the browser's
#      device picker can see/open them instead of silently failing on a root-only /dev/hidraw*.
#
# Usage: ./aula-webdriver-setup.sh   (will re-exec itself with sudo/doas/pkexec as needed)

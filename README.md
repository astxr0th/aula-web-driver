# aula-web-driver

AULA's keyboard software is a web app ([aulastar.com/web-drive](https://www.aulastar.com/web-drive/))
that talks to the keyboard over WebHID. On Linux it usually can't see the device, because regular
users don't have access to the hidraw node. This script fixes that and makes sure you have a
browser that can run it.

Tested with an AULA WIN60 HE. Other AULA devices should work if they use the same USB vendor ID
(`2e3c`).

## Usage

```sh
curl -O https://raw.githubusercontent.com/astxr0th/aula-web-driver/main/aula-webdriver-setup.sh
chmod +x aula-webdriver-setup.sh
./aula-webdriver-setup.sh
```

It re-runs itself with `sudo`, `doas` or `pkexec`, whichever is available. When it's done it prints
the command to open the driver. If the keyboard was already plugged in, replug it once.

## What it does

1. Writes a udev rule to `/etc/udev/rules.d/70-aula-webhid.rules` that gives the logged-in user
   access to AULA devices (`uaccess`, plus the `plugdev` group as a fallback), then reloads udev.
2. Looks for a Chromium-based browser: Chrome, Chromium, Brave, Edge, Vivaldi or Opera, including
   Flatpak and Snap installs.
3. If it finds none, it installs Chromium with your package manager. Supported: pacman, apt, dnf,
   yum, zypper, apk, xbps, emerge, nix, with Flatpak as a fallback.

## Browser support

WebHID only exists in Chromium-based browsers. Firefox and Safari don't implement it, so the
driver won't work there no matter what.

## Other AULA devices

If your device has a different vendor ID (check with `lsusb`), change `AULA_VENDOR_ID` at the top
of the script and run it again.

## Uninstall

```sh
sudo rm /etc/udev/rules.d/70-aula-webhid.rules
sudo udevadm control --reload-rules
```

## Post install script for Lenovo 15ILL9 on Fedora 42
- setup.sh should be performed, after

```bash
sudo dnf install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
```

```bash
sudo dnf -y update
```

```bash
sudo reboot
```
- setup.sh checks for FW updates, adds Flatpak, installs coddecs and Intel media driver
- applies fix for Gnome audio "Dummy output"
- applies fix for Bluetooth

### install_apps.sh
- just installs my favourite apps
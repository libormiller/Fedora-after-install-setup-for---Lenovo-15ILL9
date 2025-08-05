#!/bin/bash

# Simple progress tracking
TOTAL_STEPS=15
CURRENT_STEP=0

progress() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
    echo "[$CURRENT_STEP/$TOTAL_STEPS] $1"
}

echo "======================================"
echo "Fedora Post-Installation Setup Script"
echo "======================================"
echo ""

### 1. Basic Setup ###
progress "Installing RPM Fusion repositories..."
sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

progress "Updating system packages..."
sudo dnf -y update

progress "Performing firmware update..."
sudo fwupdmgr refresh --force
sudo fwupdmgr get-devices
sudo fwupdmgr get-updates
sudo fwupdmgr update

progress "Adding Flathub repository..."
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

progress "Installing proprietary video codecs..."
sudo dnf4 group upgrade multimedia -y
sudo dnf swap 'ffmpeg-free' 'ffmpeg' --allowerasing -y
sudo dnf upgrade @multimedia --setopt="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin -y
sudo dnf group install -y sound-and-video 
sudo dnf install ffmpeg-libs libva libva-utils -y

progress "Installing Intel media driver..."
sudo dnf swap libva-intel-media-driver intel-media-driver --allowerasing -y
sudo dnf install libva-intel-driver -y

progress "Installing Firefox multimedia support..."
sudo dnf install -y openh264 gstreamer1-plugin-openh264 mozilla-openh264
sudo dnf config-manager setopt fedora-cisco-openh264.enabled=1

echo "Basic setup complete!"
echo ""

### Flatpak-based installations ###
progress "Installing Flatpak applications..."

# Make sure Flathub is added
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# App list
progress "Installing Thunderbird..."
flatpak install -y flathub org.mozilla.Thunderbird

progress "Installing Obsidian..."
flatpak install -y flathub md.obsidian.Obsidian

progress "Installing Discord..."
flatpak install -y flathub com.discordapp.Discord

progress "Installing OnlyOffice..."
flatpak install -y flathub org.onlyoffice.desktopeditors

progress "Installing Spotify..."
flatpak install -y flathub com.spotify.Client

progress "Installing Steam..."
flatpak install -y flathub com.valvesoftware.Steam

progress "Installing FreeTube..."
flatpak install -y flathub io.freetubeapp.FreeTube

progress "Installing qBittorrent..."
flatpak install -y flathub org.qbittorrent.qBittorrent

progress "Installing VLC..."
flatpak install -y flathub org.videolan.VLC

echo "Flatpak applications installed successfully."
echo ""

### VS Code via Microsoft RPM repo ###
progress "Installing Visual Studio Code..."

# Import Microsoft GPG key and add repo
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\nautorefresh=1\ntype=rpm-md\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/vscode.repo > /dev/null

# Install VS Code
sudo dnf check-update || true
sudo dnf install -y code

echo ""
echo "Visual Studio Code installed successfully."

echo "-------------------------------------"
echo "All applications have been installed!"

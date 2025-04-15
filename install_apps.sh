#!/bin/bash
#Comments and echoes ARE chatGPT generated

set -e

echo "-------------------------------------"
echo "Fedora application install script"
echo "-------------------------------------"
echo ""

### Flatpak-based installations ###
echo "[1/2] Installing Flatpak applications..."

# Make sure Flathub is added
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# App list
flatpak install -y flathub org.mozilla.Thunderbird
flatpak install -y flathub md.obsidian.Obsidian
flatpak install -y flathub com.discordapp.Discord
flatpak install -y flathub org.onlyoffice.desktopeditors
flatpak install -y flathub com.spotify.Client
flatpak install -y flathub com.valvesoftware.Steam
flatpak install -y flathub io.freetubeapp.FreeTube

echo "Flatpak applications installed successfully."
echo ""

### VS Code via Microsoft RPM repo ###
echo "[2/2] Installing Visual Studio Code..."

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

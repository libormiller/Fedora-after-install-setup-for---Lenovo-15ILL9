#!/bin/bash
#Comments and echoes ARE chatGPT generated

echo "-------------------------------------"
echo "Fedora post-installation setup script"
echo "-------------------------------------"
echo ""

### 1. Basic Setup ###
echo "[1/3] Starting basic setup..."
echo "Performing FW update"
sudo fwupdmgr refresh --force
sudo fwupdmgr get-devices
sudo fwupdmgr get-updates
sudo fwupdmgr update

echo "Adding the Flathub remote, if it doesn't exist..."
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

echo "Intalling proprietary video codecs"
sudo dnf4 group upgrade multimedia
sudo dnf swap 'ffmpeg-free' 'ffmpeg' --allowerasing
sudo dnf upgrade @multimedia --setopt="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin
sudo dnf4 group install -y sound-and-video
sudo dnf install ffmpeg-libs libva libva-utils
sudo dnf swap libva-intel-media-driver intel-media-driver --allowerasing

echo "Installing Intel media driver"
sudo dnf install libva-intel-driver

echo "Installing openh264 and gstreamer plugins for Mozilla Firefox..."
sudo dnf install -y openh264 gstreamer1-plugin-openh264 mozilla-openh264
sudo dnf config-manager setopt fedora-cisco-openh264.enabled=1

echo "Basic setup complete!"
echo ""

### 2. Audio Fix ###
echo "[2/3] Applying audio configuration fix..."
if [ -d "alsa-ucm-conf" ]; then
    echo "The 'alsa-ucm-conf' folder already exists. Skipping clone."
else
    git clone https://github.com/alsa-project/alsa-ucm-conf.git
fi
pushd alsa-ucm-conf > /dev/null
sudo cp -r ucm2 /usr/share/alsa/
popd > /dev/null

echo "Audio fix complete!"
echo ""

### 3. Bluetooth Fix ###
echo "[3/3] Applying Bluetooth firmware fix..."
# Create a backup directory for the current Bluetooth firmware files.
mkdir -p bt-fw-backup
sudo mv /lib/firmware/intel/ibt-0190-* bt-fw-backup/ || echo "No existing firmware files to move."
if [ -d "linux-firmware" ]; then
    echo "The 'linux-firmware' folder already exists. Skipping clone."
else
    git clone https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git
fi
sudo cp linux-firmware/intel/ibt-0190-* /lib/firmware/intel/
sudo ln -sf /lib/firmware/intel/ibt-0190-0291.sfi /lib/firmware/intel/ibt-0190-0291-pci.sfi
sudo ln -sf /lib/firmware/intel/ibt-0190-0291.ddc /lib/firmware/intel/ibt-0190-0291-pci.ddc

echo "Rebuilding initramfs with dracut..."
sudo dracut --force

echo "Bluetooth firmware fix complete!"
echo ""
echo "-------------------------------------"
echo "Fedora post-installation setup completed successfully!"

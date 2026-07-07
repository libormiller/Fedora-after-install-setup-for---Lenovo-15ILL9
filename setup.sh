#!/bin/bash

# Skript se zastaví při neočekávaných chybách mimo definované kroky
set -e

# Aktualizovaný počet kroků (přidán Distrobox, NPU ovladače a OpenVINO)
TOTAL_STEPS=23
CURRENT_STEP=0

# Transakční funkce pro bezpečné spouštění s automatickým rollbackem
run_step() {
    local step_desc="$1"
    local cmd="$2"
    local rollback_cmd="$3"

    CURRENT_STEP=$((CURRENT_STEP + 1))
    echo "=================================================="
    echo "[$CURRENT_STEP/$TOTAL_STEPS] $step_desc"
    echo "=================================================="
    
    # Dočasně vypneme globální 'set -e', abychom zachytili návratový kód sami
    set +e
    eval "$cmd"
    local exit_code=$?
    set -e

    if [ $exit_code -ne 0 ]; then
        echo ""
        echo "❌ CHYBA: Krok '$step_desc' selhal s kódem $exit_code!"
        if [ -n "$rollback_cmd" ]; then
            echo "🔄 Spouštím návrat změn (Rollback) do stavu před tímto krokem..."
            echo "   Provádím: $rollback_cmd"
            eval "$rollback_cmd"
            echo "✅ Změny tohoto kroku byly bezpečně vráceny."
        else
            echo "ℹ️ Pro tento krok není potřeba nebo definován žádný rollback."
        fi
        echo "⛔ Skript byl z bezpečnostních doomed důvodů přerušen."
        exit 1
    fi
    echo "🔹 Krok dokončen úspěšně."
    echo ""
}

echo "======================================================"
echo " Fedora Post-Installation Setup Script (Safe & Async) "
echo "======================================================"
echo ""

### 1. Základní nastavení a repozitáře ###
run_step "Installing RPM Fusion repositories..." \
         "sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-\$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-\$(rpm -E %fedora).noarch.rpm" \
         "sudo rm -f /etc/yum.repos.d/rpmfusion-*"

run_step "Updating system packages..." \
         "sudo dnf -y update" \
         ""

run_step "Performing firmware update..." \
         "sudo fwupdmgr refresh --force && sudo fwupdmgr get-devices && sudo fwupdmgr get-updates && sudo fwupdmgr update -y" \
         ""

run_step "Adding Flathub repository..." \
         "flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo" \
         "flatpak remote-delete flathub"

run_step "Installing proprietary video codecs..." \
         "sudo dnf4 group upgrade multimedia -y && sudo dnf swap 'ffmpeg-free' 'ffmpeg' --allowerasing -y && sudo dnf upgrade @multimedia --setopt=\"install_weak_deps=False\" --exclude=PackageKit-gstreamer-plugin -y && sudo dnf group install -y sound-and-video && sudo dnf install ffmpeg-libs libva libva-utils -y" \
         ""

run_step "Installing Intel media driver..." \
         "sudo dnf swap libva-intel-media-driver intel-media-driver --allowerasing -y && sudo dnf install libva-intel-driver -y" \
         ""

run_step "Installing Firefox multimedia support..." \
         "sudo dnf install -y openh264 gstreamer1-plugin-openh264 mozilla-openh264 && sudo dnf config-manager setopt fedora-cisco-openh264.enabled=1" \
         ""


### 2. Integrace Distroboxu pro Ubuntu aplikace (MATLAB, DaVinci...) ###
run_step "Installing Podman and Distrobox..." \
         "sudo dnf install -y podman distrobox" \
         "sudo dnf remove -y podman distrobox"

run_step "Creating Ubuntu container for specialized apps..." \
         "distrobox create --name ubuntu-studio --image ubuntu:24.04 --yes" \
         "distrobox rm --name ubuntu-studio --force"


### 3. Nativní Intel NPU a OpenVINO AI Setup ###
run_step "Installing native Intel NPU driver..." \
         "sudo dnf install -y intel-npu-driver" \
         "sudo dnf remove -y intel-npu-driver"

run_step "Configuring user permissions for NPU access (render group)..." \
         "sudo usermod -a -G render \$USER" \
         "sudo gpasswd -d \$USER render 2>/dev/null || true"

run_step "Installing Intel OpenVINO Toolkit and hardware plugins..." \
         "sudo dnf install -y openvino openvino-plugins python3-openvino" \
         "sudo dnf remove -y openvino openvino-plugins python3-openvino"


### 4. Instalace Flatpak aplikací ###
run_step "Installing Thunderbird..." "flatpak install -y flathub org.mozilla.Thunderbird" "flatpak uninstall -y org.mozilla.Thunderbird 2>/dev/null || true"
run_step "Installing Obsidian..." "flatpak install -y flathub md.obsidian.Obsidian" "flatpak uninstall -y md.obsidian.Obsidian 2>/dev/null || true"
run_step "Installing Discord..." "flatpak install -y flathub com.discordapp.Discord" "flatpak uninstall -y com.discordapp.Discord 2>/dev/null || true"
run_step "Installing OnlyOffice..." "flatpak install -y flathub org.onlyoffice.desktopeditors" "flatpak uninstall -y org.onlyoffice.desktopeditors 2>/dev/null || true"
run_step "Installing Spotify..." "flatpak install -y flathub com.spotify.Client" "flatpak uninstall -y com.spotify.Client 2>/dev/null || true"
run_step "Installing Steam..." "flatpak install -y flathub com.valvesoftware.Steam" "flatpak uninstall -y com.valvesoftware.Steam 2>/dev/null || true"
run_step "Installing FreeTube..." "flatpak install -y flathub io.freetubeapp.FreeTube" "flatpak uninstall -y io.freetubeapp.FreeTube 2>/dev/null || true"
run_step "Installing qBittorrent..." "flatpak install -y flathub org.qbittorrent.qBittorrent" "flatpak uninstall -y org.qbittorrent.qBittorrent 2>/dev/null || true"
run_step "Installing VLC..." "flatpak install -y flathub org.videolan.VLC" "flatpak uninstall -y org.videolan.VLC 2>/dev/null || true"


### 5. Vývojové nástroje a Virtualizace ###
run_step "Installing Visual Studio Code..." \
         "sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc && echo -e '[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\nautorefresh=1\ntype=rpm-md\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc' | sudo tee /etc/yum.repos.d/vscode.repo > /dev/null && sudo dnf check-update || true && sudo dnf install -y code" \
         "sudo rm -f /etc/yum.repos.d/vscode.repo && sudo dnf remove -y code"

run_step "Installing VirtManager (Virtual Machine Manager)..." \
         "sudo dnf install -y virt-manager" \
         "sudo dnf remove -y virt-manager"

echo "--------------------------------------------------"
echo "🎉 Všechny kroky a aplikace byly úspěšně nastaveny!"
echo "--------------------------------------------------"
echo "⚠️ DŮLEŽITÉ: Pro správné fungování NPU, OpenVINO a Distroboxu"
echo "   se prosím odhlaste a znovu přihlaste do systému,"
echo "   aby se projevilo vaše členství ve skupině 'render'."
echo "--------------------------------------------------"

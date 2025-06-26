#!/bin/bash

# === CEH Practical Toolset Installer for Parrot OS ===
# Optimized version: Better layout, efficiency, and keyboard config handling

GREEN='\033[0;32m'
NC='\033[0m'

declare -A tools
tools["Footprinting and Reconnaissance"]="whois nslookup dig theharvester recon-ng shodan-cli maltego"
tools["Scanning Networks"]="nmap masscan hping3"
tools["Enumeration"]="enum4linux smbclient snmpwalk"
tools["Vulnerability Assessment"]="openvas searchsploit"
tools["System Hacking"]="metasploit-framework msfvenom netcat socat hydra medusa john hashcat"
tools["Malware Threats"]="veil thefatrat exiftool binwalk strings clamav"
tools["Sniffing and MITM"]="wireshark tshark tcpdump ettercap bettercap responder"
tools["Password Cracking"]="john hashcat hydra"
tools["Web Application Attacks"]="burpsuite sqlmap ffuf"
tools["SQL Injection & XSS"]="sqlmap burpsuite"
tools["Wireless Attacks"]="aircrack-ng wifite"
tools["Social Engineering"]="setoolkit"
tools["Mobile & IoT Testing"]="mobsf frida"
tools["Post-Exploitation"]="netcat"

install_tools() {
    category="$1"
    echo -e "${GREEN}Installing tools for: $category${NC}"
    for tool in ${tools[$category]}; do
        if ! command -v "$tool" &> /dev/null; then
            echo "[+] Installing: $tool"
            sudo apt install -y "$tool" 2>/dev/null || echo "[!] Could not install $tool"
        else
            echo "[-] $tool already installed."
        fi
    done
}

echo "[+] Updating base system and installing common dependencies..."
sudo apt update
sudo apt install -y python3 python3-pip python3-venv build-essential git curl wget gnupg \
                    software-properties-common unzip net-tools xdg-utils docker.io docker-compose

# Tool category selection
echo "Available Categories:"
i=1
for category in "${!tools[@]}"; do
    echo "$i) $category"
    ((i++))
done

echo
read -rp "Enter the number(s) of the category you want to install tools for (space-separated, or type 'all'): " choices

if [[ "$choices" == "all" ]]; then
    for category in "${!tools[@]}"; do
        install_tools "$category"
    done
else
    for choice in $choices; do
        category=$(printf "%s\n" "${!tools[@]}" | sed -n "${choice}p")
        install_tools "$category"
    done
fi

# === Dirsearch ===
DIRSEARCH_DIR="$HOME/dirsearch"
if [ ! -d "$DIRSEARCH_DIR" ]; then
    echo "[+] Installing dirsearch..."
    git clone https://github.com/maurosoria/dirsearch.git "$DIRSEARCH_DIR"
    pip3 install -r "$DIRSEARCH_DIR/requirements.txt"
    echo 'alias dirsearch="python3 ~/dirsearch/dirsearch.py"' >> ~/.bashrc
    source ~/.bashrc
fi

# === Obsidian Installation ===
echo "[+] Installing Obsidian via GitHub direct .deb link..."
OBSIDIAN_URL=$(curl -s https://api.github.com/repos/obsidianmd/obsidian-releases/releases/latest | grep browser_download_url | grep amd64.deb | cut -d '"' -f 4)
if [ -n "$OBSIDIAN_URL" ]; then
    wget -O /tmp/obsidian.deb "$OBSIDIAN_URL"
    sudo apt install -y /tmp/obsidian.deb
    if [ -f /usr/bin/obsidian ]; then
        echo "[+] Creating Obsidian desktop launcher..."
        mkdir -p ~/.local/share/applications
        cat <<EOF > ~/.local/share/applications/obsidian.desktop
[Desktop Entry]
Name=Obsidian
Exec=/usr/bin/obsidian
Icon=obsidian
Type=Application
Categories=Office;NoteTaking;
StartupNotify=true
Terminal=false
EOF
    else
        echo "[!] Obsidian binary not found."
    fi
else
    echo "[!] Could not retrieve Obsidian .deb link."
fi

# === Mousepad Default Editor ===
echo "[+] Setting Mousepad as the default text editor..."
sudo apt install -y mousepad
xdg-mime default mousepad.desktop text/plain
xdg-mime default mousepad.desktop application/x-shellscript

# === Keyboard Layout: Portuguese (no dead keys) ===
echo "[+] Configuring keyboard layout: Portuguese (no dead keys)..."

DE=$(echo "$XDG_CURRENT_DESKTOP" | tr '[:upper:]' '[:lower:]')

apply_kde() {
    echo "[!] KDE detected. Please configure layout via GUI:"
    echo "    System Settings → Input Devices → Keyboard → Layouts"
}

apply_mate() {
    gsettings set org.mate.peripherals-keyboard-xkb.kbd layouts "['pt']"
    gsettings set org.mate.peripherals-keyboard-xkb.kbd variants "['nodeadkeys']"
    gsettings set org.mate.peripherals-keyboard-xkb.kbd options "['lv3:none','terminate:ctrl_alt_bksp']"
    echo "[✓] MATE layout applied. Re-login recommended."
}

apply_xfce() {
    xfconf-query -c keyboard-layout -p /Default/XkbLayout -s "pt"
    xfconf-query -c keyboard-layout -p /Default/XkbVariant -s "nodeadkeys"
    echo "[✓] XFCE layout applied. Re-login recommended."
}

apply_x11_fallback() {
    setxkbmap -layout pt -variant nodeadkeys
    echo "[✓] Layout applied temporarily via X11."
}

case "$DE" in
    *mate*) apply_mate ;;
    *xfce*) apply_xfce ;;
    *kde*|*plasma*) apply_kde ;;
    *) apply_x11_fallback ;;
esac

echo
echo "[*] Current layout status:"
setxkbmap -query

# === Additional Tools ===
echo "[+] Installing CrackMapExec..."
sudo apt install -y pipx
pipx ensurepath
pipx install git+https://github.com/Porchetta-Industries/CrackMapExec.git

echo "[+] Installing other tools..."
sudo apt install -y exploitdb seclists steghide strace ltrace

echo "[+] Installing Impacket..."
pipx install impacket

# === Post-Install Tool Check ===
echo -e "\n${GREEN}Verifying installed tools...${NC}"
installed_tools=()
for category in "${!tools[@]}"; do
    for tool in ${tools[$category]}; do
        if command -v "$tool" &> /dev/null; then
            installed_tools+=("$tool")
        fi
    done
done

echo -e "\n${GREEN}Installed Tools:${NC}"
for t in "${installed_tools[@]}"; do
    echo "✔️  $t"
done

echo -e "\n${GREEN}Basic Tests:${NC}"
for t in nmap sqlmap john hydra wireshark dirsearch; do
    if command -v $t &> /dev/null; then
        echo -e "\n[TEST] $t:"
        case $t in
            nmap) $t -V ;;
            sqlmap) $t --version ;;
            john) $t --list=formats | head -n 5 ;;
            hydra) $t -L /dev/null -P /dev/null -t 1 localhost ssh ;;
            wireshark) echo "Use GUI to verify wireshark." ;;
            dirsearch) dirsearch -u http://localhost -e html -l 1 ;;
        esac
    fi
done

echo -e "\n${GREEN}All done. Your CEH/Parrot OS setup is complete!${NC}"

#!/bin/bash
set -o pipefail
red='\e[1;91m'
grn='\e[1;92m'
cyn='\e[1;96m'
rst='\e[0m'
t=$(($(nproc --all) - 1))
die () { echo -e "\n${red}:: $1 ${rst}  $?\n" ; exit 1 ; }
msg () { echo -e "\n${grn}:: $1${rst}\n" ; }
if [[ "${BASH_SOURCE[0]}" != "$(basename -- "$0")" ]]; then
    echo -e "\n${red}Do not source this script!\n\nUsage:${rst} bash $(basename -- "$0")\n"
    kill -INT $$
fi
[[ $EUID -ne 0 ]] && echo "This script must be run as root." && exit 1
echo ""
read -rp $'\e[1;92m:: Enter user name:\e[0m ' USER
HOME="/home/$USER"
TMP="$HOME/.tmp"
ANDROID_DIR="$HOME/Android"
cd "$HOME"
sudo -u "$USER" mkdir -p "$TMP"
sudo -u "$USER" mkdir -p "$ANDROID_DIR"
if [ -f "$TMP"/count* ]; then
    msg "Setup already ran before."
    msg "You may need to run some commands manually"
    msg "if the script did not succeed."
    sleep 1
fi
if [ ! -d "$ANDROID_DIR"/scripts/setup ]; then
	msg "Cloning setup scripts..."
	sudo -u "$USER" mkdir "$ANDROID_DIR"/scripts
	sudo -u "$USER" git clone https://github.com/RebelLion420/build_scripts "$ANDROID_DIR"/scripts
fi
msg "Setup scripts acquired"
if [ ! -f "$TMP"/count1 ]; then
	cd "$ANDROID_DIR"/scripts
	msg "Setting up Android Build Environment..."
	bash setup/arch-manjaro.sh || die "Arch-Manjaro" && exit 1
	bash setup/install_android_sdk.sh || die "Android SDK" && exit 1
	sudo -u "$USER" touch "$TMP"/count1
fi
msg "Prerequisites installed succesfully."
if [ ! -f "$TMP"/count2 ]; then
	msg "Installing ccache..."
	bash setup/ccache.sh || die "ccache"
	sudo -u "$USER" touch "$TMP"/count2
fi
msg "ccache installed succesfully"
if [ ! -f "$TMP"/count3 ]; then
	msg "Installing make..."
	bash setup/make.sh || die "make"
	sudo -u "$USER" touch "$TMP"/count3
fi
msg "make installed succesfully"
if [ ! -f "$TMP"/count4 ]; then
	msg "Installing ninja..."
	bash setup/ninja.sh || die "ninja"
	sudo -u "$USER" touch "$TMP"/count4
fi
msg "ninja installed succesfully"
if [ ! -f "$TMP"/count5 ]; then
	msg "Installing hub..."
	bash setup/hub.sh || die "hub"
	sudo -u "$USER" touch "$TMP"/count5
fi
msg "hub installed succesfully"
sleep 1
msg "Build environment setup complete!"
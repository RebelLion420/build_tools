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
read -rp $'\e[1;92m:: Enter Username:\e[0m ' USER
HOME="/home/$USER"
TMP="$HOME/.tmp"
ANDROID_DIR="$HOME/Android"
FAKEROOT="fakeroot_1.36.orig.tar.gz"
FR_URL="https://ftp.debian.org/debian/pool/main/f/fakeroot/"$FAKEROOT""
FR_DIR="$TMP/fakeroot"
sudo -u "$USER" mkdir -p "$TMP"
sudo -u "$USER" mkdir -p "$ANDROID_DIR"
#sudo -u "$USER" mkdir -p "$FR_DIR"
if [ -f "$TMP"/count1 ]; then
    msg "Setup already ran before."
    msg "You may need to run some commands manually"
    msg "if the script did not succeed."
    sleep 1
fi
cd "$HOME" || exit 1
msg "Arch Linux Arm setup"
sleep 1
if [ ! -f "$TMP"/count1 ]; then
    msg "Checking prerequisites..."
    pkgs=$(cat ~/tools/termux-arch-setup/tArch-pkgs.txt)
	for pkg in $pkgs; do
		pacman -Qi "${pkg}" &>/dev/null || {
		msg "Installing ${cyn}${pkg}${rst}"
		pacman -S --needed --noconfirm "${pkg}"
		}
	done
	touch "$TMP"/count1
fi
msg "Packages up-to-date."
#if [ ! -f "$TMP"/count2 ]; then
#    cd "$TMP" || exit 1 
#    msg "Making fakeroot package..."
#    sudo -u "$USER" wget -q "$FR_URL"
#    sudo -u "$USER" tar xf "$FAKEROOT" -C "$FR_DIR" --strip-components=1
#    cd "$FR_DIR" || die "Fakeroot source failed to download! Aborting."
#    sudo -u "$USER" ./bootstrap
#    sudo -u "$USER" ./configure --prefix=/usr \
#        --libdir=/opt/fakeroot/libs \
#        --disable-static \
#        --with-ipc=tcp
#    sudo -u "$USER" make -j"$t" 
#    msg "Fakeroot package ready. Installing..." 
#    make install
#    touch "$TMP"/count2
#fi
#msg "Fakeroot installed."
sleep 1
cd "$HOME"
read -rp $'\e[1;92m:: Do you want to sync a project?\e[0m ' ifsync
if [[ "${ifsync,,}" =~ ^(y|yes)$ ]]; then
    until [[ "${dosync,,}" =~ ^(n|no)$ ]]; do
        until [[ "${yn,,}" =~ ^(y|yes)$ ]]; do
            if [ ! -d "$ANDROID_DIR" ]; then
			mkdir -p "$ANDROID_DIR"
			fi
			cd "$ANDROID_DIR"
            manifest=
            read -rp $'\e[1;92m:: Username/Repo:\e[0m ' url
            read -rp $'\e[1;92m:: Repo Branch:\e[0m ' branch
            read -rp $'\e[1;92m:: Project Folder:\e[0m ' folder
			read -rp $'\e[1;92m:: Shallow Clone? (ENTER if unsure)\e[0m ' shallow
            read -rp $'\e[1;92m:: Local Manifest? [User/Repo]: (ENTER if unsure)\e[0m ' manifest
            echo ""
            read -rp $'\e[1;92m:: Is this correct?\e[0m ' yn
        done
        mkdir -p "$folder" && cd "$folder" || die "ERROR"
        if [[ "${shallow,,}" =~ ^(y|yes)$ ]]; then
            sudo -u "$USER" repo init -u git://github.com/"$url" -b "$branch" --depth=1 --groups=all,-notdefault,-device,-darwin,-x86,-mips,-exynos5,mako || {
                die "Init failed!"
                exit 1
            }
        else
            sudo -u "$USER" repo init -u git://github.com/"$url" -b "$branch" || {
                die "Init failed!"
                exit 1
            }
        fi
        if [[ $manifest != "" ]]; then git clone https://github.com/"$manifest" .repo/local_manifests; fi
        sudo -u "$USER" repo sync -j"$t" -cq --optimized-fetch --no-clone-bundle --no-tags || {
            die "Sync aborted!"
            exit 1
        }
        read -rp $'\e[1;92m:: Do you want to sync another project?\e[0m ' dosync
    done
fi
cd "$HOME"
read -rp $'\e[1;92m:: Do you want to clone a separate repo?\e[0m ' ifclone
if [[ "${ifclone,,}" =~ ^(y|yes)$ ]]; then
    until [[ "${doclone,,}" =~ ^(n|no)$ ]]; do
        until [[ "${yn,,}" =~ ^(y|yes)$ ]]; do
            read -rp $'\e[1;92m:: Username/Repo:\e[0m ' url
            read -rp $'\e[1;92m:: Repo branch:\e[0m ' branch
            read -rp $'\e[1;92m:: Local Folder Location [ENTER for default]:\e[0m ' folder
            read -rp $'\e[1;92m:: Clone submodules? (ENTER if unsure)\e[0m ' subs
            read -rp $'\e[1;92m:: Is this correct?\e[0m ' yn
        done
		if [ -n "$folder" ]; then
			mkdir -p "$HOME"/"$folder"
		fi
        if [[ "${subs,,}" =~ ^(y|yes)$ ]]; then
            sudo -u "$USER" git clone --recurse-submodules -j"$t" -b "$branch" https://github.com/"$url" "$HOME"/"$folder"
        else
            sudo -u "$USER" git clone -j"$t" -b "$branch" https://github.com/"$url" "$HOME"/"$folder"
        fi
        read -rp $'\e[1;92m:: Do you want to clone another repo?\e[0m ' doclone
    done
fi
msg "Setup Complete!"
msg "Enjoy!"
rm -rf "$TMP"

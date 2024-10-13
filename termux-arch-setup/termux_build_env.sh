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
echo ""
read -rp $'\e[1;92m:: Enter Username:\e[0m ' USER
msg "NOTICE: Password is only stored in context of this script"
sleep 2
read -rsp $'\e[1;92m:: Enter sudo Password:\e[0m ' PASSWORD
asudo="echo $PASSWORD | sudo -S"
HOME="/home/$USER"
TMP="$HOME/.tmp"
ANDROID_DIR="$HOME/android"
FAKEROOT="fakeroot_1.36.orig.tar.gz"
FR_URL="https://ftp.debian.org/debian/pool/main/f/fakeroot/$FAKEROOT"
FR_DIR="$TMP/fakeroot"
mkdir -p $TMP
mkdir -p $ANDROID_DIR
#mkdir -p $FR_DIR
if [ -f $TMP/count1 ]; then
    msg "Setup already ran before."
    msg "You may need to run some commands manually"
    msg "if the script did not succeed."
    sleep 1
fi
cd $HOME || exit 1
msg "Arch Linux Arm setup"
sleep 1
if [ ! -f $TMP/count1 ]; then
    msg "Checking prerequisites..."
    pkgs=$(cat ~/build_tools/termux-arch-setup/tArch-pkgs.txt)
    if [ -f $TMP/count1 ]; then
	for pkg in $pkgs; do
            pacman -Qi "${pkg}" &>/dev/null || {
                msg "Installing ${cyn}${pkg}${rst}"
                asudo pacman -S --needed --noconfirm "${pkg}"
            }
        done
    else
	    echo $pkgs | xargs asudo pacman -S --needed --noconfirm
    fi
	touch $TMP/count1
fi
msg "Packages up-to-date."
#if [ ! -f $TMP/count2 ]; then
#    cd $TMP || exit 1 
#    msg "Making fakeroot package..."
#    wget -q $FR_URL
#    tar xf $FAKEROOT -C $FR_DIR --strip-components=1
#    cd $FR_DIR || die "Fakeroot source failed to download! Aborting."
#    ./bootstrap
#    ./configure --prefix=/usr \
#        --libdir=/opt/fakeroot/libs \
#        --disable-static \
#        --with-ipc=tcp
#    make -j"$t" 
#    msg "Fakeroot package ready. Installing..." 
#    asudo make install
#    touch $TMP/count2
#fi
#msg "Fakeroot installed."
sleep 1
cd $HOME || exit 1
read -rp $'\e[1;92m:: Do you want to sync a project?\e[0m ' ifsync
if [[ "${ifsync,,}" =~ ^(y|yes)$ ]]; then
    until [[ "${dosync,,}" =~ ^(n|no)$ ]]; do
        until [[ "${yn,,}" =~ ^(y|yes)$ ]]; do
            if [ ! -d $ANDROID_DIR ]; then
			mkdir -p $ANDROID_DIR
			fi
			cd $ANDROID_DIR
            manifest=
            read -rp $'\e[1;92m:: Username/Repo:\e[0m ' url
            read -rp $'\e[1;92m:: Repo Branch:\e[0m ' branch
            read -rp $'\e[1;92m:: Project Folder:\e[0m ' folder
			read -rp $'\e[1;92m:: Shallow Clone? (ENTER if unsure)\e[0m ' shallow
            read -rp $'\e[1;92m:: Local Manifest? [User/Repo]: (ENTER if unsure)\e[0m ' manifest
            echo ""
            read -rp $'\e[1;92m:: Is this correct?\e[0m ' yn
        done
        mkdir "$folder" && cd "$folder" || exit 1
        if [[ "${shallow,,}" =~ ^(y|yes)$ ]]; then
            repo init -u git://github.com/"$url" -b "$branch" --depth=1 --groups=all,-notdefault,-device,-darwin,-x86,-mips,-exynos5,mako || {
                die "Init failed!"
                exit 1
            }
        else
            repo init -u git://github.com/"$url" -b "$branch" || {
                die "Init failed!"
                exit 1
            }
        fi
        if [[ $manifest != "" ]]; then git clone https://github.com/"$manifest" .repo/local_manifests; fi
        repo sync -j"$t" -cq --optimized-fetch --no-clone-bundle --no-tags || {
            die "Sync aborted!"
            exit 1
        }
        read -rp $'\e[1;92m:: Do you want to sync another project?\e[0m ' dosync
    done
fi
read -rp $'\e[1;92m:: Do you want to clone a repo?\e[0m ' ifclone
if [[ "${ifclone,,}" =~ ^(y|yes)$ ]]; then
    until [[ "${doclone,,}" =~ ^(n|no)$ ]]; do
		if [ ! -d $ANDROID_DIR ]; then; mkdir -p $ANDROID_DIR; fi
        cd $ANDROID_DIR
        until [[ "${yn,,}" =~ ^(y|yes)$ ]]; do
            read -rp $'\e[1;92m:: Username/Repo:\e[0m ' url
            read -rp $'\e[1;92m:: Repo branch:\e[0m ' branch
            read -rp $'\e[1;92m:: Project Folder:\e[0m ' folder
            read -rp $'\e[1;92m:: Clone submodules? (ENTER if unsure)\e[0m ' subs
            read -rp $'\e[1;92m:: Is this correct?\e[0m ' yn
        done
        if [[ "${subs,,}" =~ ^(y|yes)$ ]]; then
            git clone --recurse-submodules -j"$t" -b "$branch" https://github.com/"$url" $ANDROID_DIR/"$folder"
        else
            git clone -j"$t" -b "$branch" https://github.com/"$url" $ANDROID_DIR/"$folder"
        fi
        read -rp $'\e[1;92m:: Do you want to clone another repo?\e[0m ' doclone
    done
fi
msg "Setup Complete!"
msg "Enjoy!"
rm -rf $TMP

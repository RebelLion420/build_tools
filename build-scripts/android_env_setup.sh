#!/bin/bash
set -o pipefail
red='\e[1;91m'
grn='\e[1;92m'
cyn='\e[1;96m'
rst='\e[0m'
t=$(($(nproc --all) - 1))
die () { msg "\n${red}:: $1 ${rst}  $?\n" ; exit 1 ; }
msg () { msg "\n${grn}:: $1${rst}\n" ; }
if [[ "${BASH_SOURCE[0]}" != "$(basename -- "$0")" ]]; then
    msg "\n${red}Do not source this script!\n\nUsage:${rst} sudo bash $(basename -- "$0")\n"
    kill -INT $$
fi
echo ""
read -rp $'\e[1;92m:: Enter user name:\e[0m ' USER
read -rp $'\e[1;92m:: Sudo Password:\e[0m ' PASSWORD
asudo="echo $PASSWORD | sudo -S"
HOME='/home/${USER}'
TMP='${HOME}/.tmp'
ANDROID_DIR='${HOME}/Android'
cd $HOME
mkdir -p $TMP
mkdir -p $ANDROID_DIR
if [ -f $TMP/count1 ]; then
    msg "Setup already ran before."
    msg "You may need to run some commands manually"
    msg "if the script did not succeed."
    sleep 1
fi
msg "Arch Linux Arm setup"
sleep 1
if [ ! -d $ANDROID_DIR/scripts ]; then
	msg "Cloning setup scripts..."
	mkdir $ANDROID_DIR/scripts
	git clone https://github.com/RebelLion420/build_scripts $ANDROID_DIR/scripts
fi
msg "Setup scripts acquired"
if [ ! -f $TMP/count1 ]; then
	cd $ANDROID_DIR/scripts
	msg "Setting up Android Build Environment..."
	yes | asudo bash setup/arch-manjaro.sh || die "Arch-Manjaro" && exit 1
	yes | asudo bash setup/install_android_sdk.sh || die "Android SDK" && exit 1
	touch $TMP/count1
fi
msg "Prerequisites installed succesfully."
if [ ! -f $TMP/count2 ]; then
	msg "Installing ccache..."
	yes | asudo bash setup/ccache.sh || die "ccache"
	touch $TMP/count2
fi
msg "ccache installed succesfully"
if [ ! -f $TMP/count3 ]; then
	msg "Installing make..."
	yes | asudo bash setup/make.sh || die "make"
	touch $TMP/count3
fi
msg "make installed succesfully"
if [ ! -f $TMP/count4 ]; then
	msg "Installing ninja..."
	yes | asudo bash setup/ninja.sh || die "ninja"
	touch $TMP/count4
fi
msg "ninja installed succesfully"
if [ ! -f $TMP/count5 ]; then
	msg "Installing hub..."
	yes | asudo bash setup/hub.sh || die "hub"
	touch $TMP/count5
fi
msg "hub installed succesfully"
sleep 1
msg "Build environment setup complete!"
#!/usr/bin/bash
set -o pipefail
red='\e[1;91m'
grn='\e[1;92m'
cyn='\e[1;96m'
rst='\e[0m'
die () { echo -e "\n${red}:: $1 ${rst}  $?\n" ; exit 1 ; }
msg () { echo -e "\n${grn}:: $1${rst}\n" ; }
BASEDIR=$(pwd)
pkg update -y
yes|xargs -a $BASEDIR/termux-pkgs.txt || die "Failed to install packages! Make sure all packages in 'termux-pkgs.txt' are installed!"
msg "Allow Termux to access Android filesystem on next popup"
sleep 3
termux-setup-storage
msg "Wait for Arch Linux install script to finish..."
sleep 1
wget https://raw.githubusercontent.com/SDRausty/termux-arch/master/setupTermuxArch.bash
bash setupTermuxArch.bash || bash setupTermuxArch refresh || die "Error occured during Arch Linux install! Scroll up to check logs for more info"
msg "'~/arch/startarch' to boot your new Linux environment!"
exit 0
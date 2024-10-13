#!/usr/bin/bash
set -o pipefail
red='\e[1;91m'
grn='\e[1;92m'
cyn='\e[1;96m'
rst='\e[0m'
die () { echo -e "\n${red}:: $1 ${rst}  $?\n" ; exit 1 ; }
msg () { echo -e "\n${grn}:: $1${rst}\n" ; }
msg "Installing required packages..."
pkg update
pkg install bash-completion bsdtar busybox curl git hub openssh proot tergent tmux -y || die "Failed to install packages!"
msg "Packages up-to-date"
sleep 1
msg "Allow Termux to access Android filesystem on next popup"
sleep 3
termux-setup-storage
msg "Wait for Arch Linux install script to finish..."
sleep 1
wget -nv https://raw.githubusercontent.com/SDRausty/termux-arch/master/setupTermuxArch.bash
bash setupTermuxArch.bash || bash setupTermuxArch refresh
msg "'~/arch/startarch' to boot your new Linux environment!"
exit 0
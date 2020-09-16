#!/usr/bin/bash
BASEDIR=$(pwd)
yes|pkg update
yes|xargs -a $BASEDIR/termux.pkgs
termux-setup-storage
wget https://raw.githubusercontent.com/SDRausty/termux-arch/master/setupTermuxArch.bash
bash setupTermuxArch.bash


#!/usr/bin/bash
BASEDIR=$(pwd)
for PKG in $(cat $BASEDIR/termux.pkgs); do
    apt list -a $PKG 2&>/dev/null || {
        echo $PKG >> $BASEDIR/pkgs.txt
    }
done
yes|xargs -a $BASEDIR/pkgs.txt pkg install
rm $BASEDIR/pkgs.txt
termux-setup-storage
wget https://raw.githubusercontent.com/SDRausty/termux-arch/master/setupTermuxArch.bash
bash setupTermuxArch.bash


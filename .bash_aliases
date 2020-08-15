#
# Decorations
#
red='\e[1;31m'
green='\e[1;32m'
white='\e[1;97m'
reset='\e[0m'
echorun () { echo -e "\n$green\$ $*$reset" ; "$@" ; }
#
# Shortcuts
#
alias vim=nvim
alias reload='source ~/.bash_profile||source ~/.bashrc'
alias ls='ls -F --color=always --group-directories-first'
alias lsa='ls -AR -I ".git" -I ".repo"'
alias export64='echorun export ARCH=arm64 && export SUBARCH=$ARCH && export CROSS_COMPILE=~/toolchain/bin/aarch64-linux-gnu-'
alias kclean='echorun make clean && make mrproper && rm -rf ~/kernel_out && mkdir -p ~/kernel_out/modinstall'
alias sysclean='echorun rm -rf out/target/product/perry/system out/target/product/perry/*.zip* out/target/product/perry/*.img'
alias repopull='echorun repo sync -cq -j$(nproc --all) --force-sync --no-tags --prune --no-clone-bundle --optimized-fetch'
alias filterlog="grep -iE 'crash|error|fail|failed|fatal|missing|not found| W | D | E ' buildlog.txt &> errors.txt"
alias bmake='mka -j$(nproc --all) bootimage 2>&1 | tee buildlog.txt && filterlog'
alias rmake='mka -j$(nproc --all) recoveryimage 2>&1 | tee buildlog.txt && filterlog'
alias synceach='echo "" ; for d in ./*/ ; do (cd "$d" && echo -e "* $(basename "`pwd`")" && git reset --hard HEAD && git clean -fd && git pull && echo "" || exit 1) ; done || echo -e "Error occured.\n"'
alias gstart='gcloud compute instances start'
alias gstop='gcloud compute instances stop'
alias glist='gcloud compute instances list'
alias cibuild='trigger_build.bash RebelLion420 kernel_perry'
#
# Git Aliases
#
alias git=hub
alias gl='git log --color --decorate --oneline --graph'
alias gd='git diff -w --color'
#
# Directory Navigation
#
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
#
# MEGATools
#
if command -v megatools &>/dev/null; then
    alias megaget='megatools get'
    alias megaput='megatools put'
    alias megals='megatools ls'
    alias megarm='megatools rm'
fi
#
# Custom Commands
#
# Transfer.sh tool to quickly send files
transfer() {
	if [ $# -eq 0 ]; then echo -e "No arguments specified. Usage:\necho transfer /tmp/test.md\ncat /tmp/test.md | transfer test.md"; return 1; fi
	tmpfile=$( mktemp -t transferXXX ); if tty -s; then basefile=$(basename "$1" | sed -e 's/[^a-zA-Z0-9._-]/-/g'); curl --progress-bar --upload-file "$1" "https://transfer.sh/$basefile" >> $tmpfile; else curl --progress-bar --upload-file "-" "https://transfer.sh/$1" >> $tmpfile ; fi; cat $tmpfile; rm -f $tmpfile
}
# Sometimes you just wanna say "Fuck Jack"
fuckjack () {
	local T=$ANDROID_BUILD_TOP
	if [ ! $T ]; then
		[[ -f ./build/envsetup.sh ]] && . build/envsetup.sh && fuckjack || {
			echo -e "\n${red}Cannot find top of tree. Make sure build environment is setup, '. build/envsetup.sh'"
			kill -INT $$
		}
	else
		echo "Fuck Jack"
		sleep 1
		echo "Setting optimal parameters"
		export ANDROID_JACK_VM_ARGS="-Xmx4096m -XX:+TieredCompilation -Dfile.encoding=UTF-8"
		export SERVER_NB_COMPILE=4
		export JACK_SERVER_VM_ARGUMENTS=${ANDROID_JACK_VM_ARGS}
		$T/prebuilts/sdk/tools/jack-admin kill-server
		$T/prebuilts/sdk/tools/jack-admin start-server
		echo "Hopefully this works... Good luck."
	fi
}
# Push file to MEGA w/ optional location
megapush () {
	if [ -z "$*" ]; then
		echo -e "\t${red}Specify remote path and target file!$reset"
		return 1
	elif [ -z $2 ]; then
		megaput --enable-previews $1
	else
		megaput --enable-previews --path=/Root/$1 $2
	fi
}
# Make directory and change into it
mkcd () {
	if [ -z $1 ]; then
		echo "Target Directory Required"
		return 1
	fi
	mkdir -p $1
	cd $1
}
# Add changes to index and proceed with chosen git command
gitcont () {
	if [[ $# -eq 0 ]]; then
		echo -e "Argument Required:     pick  merge  rebase  revert\n\nAlso include 'empty' if commit is empty to skip, e.g.\n\n\tgitcont rebase empty"
		kill -INT ${$}
	fi
	if [[ $2 == "empty" ]]; then
		git reset --quiet
	else
		git add -A
	fi
	case $1 in
		"pick") GIT_EDITOR=true git cherry-pick --continue ;;
		"merge") GIT_EDITOR=true git merge --continue ;;
		"rebase") GIT_EDITOR=true git rebase --continue ;;
		"revert") GIT_EDITOR=true git revert --continue ;;
	esac
}
# Self-explanatory archive extractor
extract () {
	if [ -f $1 ] ; then
		case $1 in
			*.tar.bz2)   tar xjf $1 ;;
			*.tar.gz)    tar xzf $1 ;;
			*.bz2)       bunzip2 $1 ;;
			*.rar)       rar x $1 ;;
			*.gz)        gunzip $1 ;;
			*.tar)       tar xf $1 ;;
			*.tbz2)      tar xjf $1 ;;
			*.tgz)       tar xzf $1 ;;
			*.zip)       unzip $1 ;;
			*.Z)         uncompress $1 ;;
			*.7z)        7z x $1 ;;
			*)           echo "'$1' cannot be extracted via extract()" ;;
		esac
	else
		echo "'$1' is not a valid file"
		return 1
	fi
}
# Output key net addresses
netinfo ()
{
	echo "--------------- Network Information ---------------"
	/sbin/ifconfig wlp3s0 | awk /'inet / {print "Inet Address:       " $2}'
	/sbin/ifconfig wlp3s0 | awk /'inet / {print "Broadcast Address:  " $6}'
	myip=`lynx -dump -hiddenlinks=ignore -nolist http://checkip.dyndns.org:8245/ | sed '/^$/d; s/^[ ]*//g; s/[ ]*$//g' `
	echo "${myip}"
	echo "---------------------------------------------------"
}
# Output sizes of all directories in current directory
dirsize ()
{
	du -shx * .[a-zA-Z0-9_]* 2> /dev/null | \
	egrep '^ *[0-9.]*[MG]' | sort -n > /tmp/list
	egrep '^ *[0-9.]*M' /tmp/list
	egrep '^ *[0-9.]*G' /tmp/list
	rm -rf /tmp/list
}

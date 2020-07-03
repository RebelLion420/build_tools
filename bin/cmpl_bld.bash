_bld_complete()
{
	local cur prev

	COMPREPLY=()
	cur=${COMP_WORDS[COMP_CWORD]}
	prev=${COMP_WORDS[COMP_CWORD-1]}

	local T=$ANDROID_BUILD_TOP
	if [ ! "$T" ]; then
		echo -e "\nCouldn't locate the top of the tree. Trying to source build/envsetup.sh." >&2
		if [ -e "build/envsetup.sh" ]; then
			source build/envsetup.sh
		else
			echo "Cannot locate setup script. Source manually."
		fi
		kill -INT ${$}
	fi
	
	if [ $COMP_CWORD -eq 1 ]; then
		COMPREPLY=( $(compgen -W "lineage omni" -- $cur) )
	elif [ $COMP_CWORD -eq 2 ]; then
		case "$prev" in
			"lineage")
				local products=$(for x in `grep -ohP 'lineage_\K\w+' $T/device/*/*/vendorsetup.sh`; do echo ${x}; done )
				COMPREPLY=( $(compgen -W "${products}" -- ${cur}) )
				;;
			"omni")
				local products=$(for x in `grep -ohP 'omni_\K\w+' $T/device/*/*/vendorsetup.sh`; do echo ${x}; done )
				COMPREPLY=( $(compgen -W "${products}" -- ${cur}) )
				;;
			*)
				;;
		esac
	elif [ $COMP_CWORD -eq 3 ]; then
		COMPREPLY=( $(compgen -W "user userdebug eng" -- ${cur}) )
	fi

	return 0
} &&
	complete -F _bld_complete bld

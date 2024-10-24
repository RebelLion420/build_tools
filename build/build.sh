#!/bin/bash
set -o errexit -o pipefail
#
# Build Personalization
#
kname=RebelKernel
export KBUILD_BUILD_USER=rebel
export KBUILD_BUILD_HOST=pride
#
# MEGA Folder Paths
#
kern=/Root/RK
kernbeta=/Root/RK/Beta
kernrel=/Root/RK/Release
#
# Environment
#
kdir="$PWD"
ak3="$kdir"/AK3
out="$kdir"/out
logs="$kdir/logs"
kernels="$kdir"/../kernels
tc="$kdir"/../toolchain
cur_time=$(date +"%m%d%y-%H%M%S")
logfile="build_${cur_time}.log"
errors="errors_${cur_time}.txt"
#
# Colors
#
red="$(tput setaf 1)$(tput bold)"
die="$(tput setaf 1)$(tput bold)$(tput blink)"
grn="$(tput setaf 2)$(tput bold)"
wrn="$(tput setaf 3)$(tput bold)"
blinkgrn="$(tput setaf 2)$(tput bold)$(tput blink)"
mag="$(tput setaf 5)$(tput bold)"
cyn="$(tput setaf 6)$(tput bold)"
blinkcyn="$(tput setaf 6)$(tput bold)$(tput blink)"
rst="$(tput sgr0)"
#
# Decorators
#
top="${cyn}╔════════════════════════════════════════════════════┅┄${rst}"
mid="${cyn}║${rst}"
end="${cyn}╚════════════════════════════════════════════════════┅┄${rst}"
#
# Printf alias-functions
fvars() {
	printf "\n%-6s${mag}%-12s ${cyn}%s${rst}\n" "" "${@}"
}
fargs () {
	printf "\n${mid}%5s${grn}%-25s ${cyn}%s" "" "${@}"
}
fmsg () {
	printf "\n${cyn}%-2s ${grn}%s${rst}\n" "::" "${@}"
}
ferr () {
	printf "\n${wrn}%-2s ${wrn}%s${rst}\n\n" "::" "${@}"
}
fdie () {
	printf "\n${red}%-2s ${die}%-5s ${wrn}%s${rst}\n\n" "::" "error:" "${@}"
}
#
# Core functions
#
usage() {
	printf "${top}\n${mid}%15s${blinkgrn}%s${rst}\n${end}" "" "MISSING ARGUMENTS (AT LEAST 2)"
	printf "\n%-2s${grn}%s${rst}\n\n%-6s${grn}%s ${mag}%s ${cyn}%s" "" "usage:" "" "bash ${0}" "-adjtv"
	printf "\n\n%-2s${grn}%s${rst}\n" "" "Arguments:"
	fvars "-a <arch>" "either 'arm' or 'arm64'"
	fvars "-d <device>" "name of target device's defconfig"
	fvars "-j <jobs>" "# threads, 'all', or blank for auto"
	fvars "-t <type>" "'release' or 'beta' for uploading, or user preference"
	fvars "-v <version>"
	echo ""
}
greplog() {
    grep -A2 -iE 'error:|crash|fail|failed|fatal|missing|not found| W | D | E ' ${logfile} &> ${errors}
    printf "${top}\n${mid}%s\n${mid}\n${end}\n\n" "$(sed -e 's/^/\║    /' ${errors})"
}
runtime() {
	endtime=$(date +%s)
	totaltime=$((endtime-start))
	diff=$(printf '%dm:%ds' $((totaltime%3600/60)) $((totaltime%60)))
	fmsg "Build ran for ${diff}"
}
lsconfigs() {
	fdie "Target device not found. Choose a valid defconfig."
	if [ "$arch" = arm ]; then
		ferr "Listing available configs:"
		find arch/arm/configs -maxdepth 1 -mindepth 1 -name "*_defconfig"|sed -e 's/^/\	/'|sort
	elif [ "$arch" = arm64 ]; then
		ferr "Listing available configs:"
		find arch/arm64/configs -maxdepth 1 -mindepth 1 -name "*_defconfig"|sed -e 's/^/\	/'|sort
	fi
}
run_build() {
	cmd="make ${1}"
	make O="$out" makeflags="$flags" -j"$threads" "${@}" |& tee -a "$logfile"
	if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
		fdie "${cmd} failed, compilation terminated"
		greplog
		runtime
		exit 1
	else
		fmsg "${cmd} successful"
	fi
}
#
# Check if script was started in bash subshell
#
if [[ "${BASH_SOURCE[0]}" != "$(basename -- "${0}")" ]]; then
	echo -e "\n${red}do not source this script!\n\nusage:${rst} bash $(basename -- "${0}")\n"
	kill -INT ${$}
fi
#
# Arguments
#
if [[ ${#} -lt 2 ]]; then
    usage
    exit 4
fi
arch="" device="" jobs="" type="" version=""
while getopts a:d:j:t:v: flag
do
	case "${flag}" in
		a) arch=${OPTARG};;
		d) device=${OPTARG};;
        j) jobs=${OPTARG};;
        t) type=${OPTARG};;
        v) version=${OPTARG};;
		*) ;;
	esac
done
shift $((OPTIND - 1))
#
# Checks
#
[[ -f $logfile || -f $errors ]] && rm $kdir/errors_*.log $kdir/build_*.txt
[[ ! -d $out ]] && mkdir -p "$out"
[[ ! -d $kernels ]] && mkdir "$kernels"
#
# Variables
#
if [[ -n $type && -n $version ]]; then
	final="${kname}-${device}-${type}_${version}.zip"
elif [[ -n $type && ! -n $version ]]; then
	final="${kname}-${device}-${type}_${cur_time}.zip"
elif [[ ! -n $type && ! -n $version ]]; then
    final="${kname}-${device}_${cur_time}.zip"
fi
case "$arch" in
	"arm")
		img=zImage
		export ARCH=arm
		[ -d "$tc"/bin ] && export CROSS_COMPILE="$tc"/bin/arm-linux-gnueabi- || {
			fdie "Toolchain not found!"
			fdie "Move or symlink toolchain folder to '<kernel_source>/../toolchain'"
			exit 1
		}
		;;
	"arm64")
		img=Image.gz
		export ARCH=arm64
		[ -d "$tc"/bin ] && export CROSS_COMPILE="$tc"/bin/aarch64-linux-gnu- || {
			fdie "Toolchain not found!"
			fdie "Move or symlink toolchain folder to '<kernel_source>/../toolchain'"
			exit 1
		}
		;;
	*)
		fdie "-a is either arm or arm64"
		exit 1
		;;
esac
if [[ "$jobs" == "all" ]]; then
	threads=$(nproc --all)
elif [[ -n "$jobs" ]]; then
	threads="$jobs"
else
	threads=$(($(nproc --all) - 2))
fi
export SUBARCH="$arch"
export DEVICE="$device"
# Ccache
if command -v ccache >/dev/null 2>&1; then
	export CCACHE_SLOPPINESS=pch_defines,file_macro,locale,time_macros
	export CFLAGS="-fpch-preprocess"
	export CPPFLAGS="-fpch-preprocess"
    export CROSS_COMPILE="ccache ${CROSS_COMPILE}"
fi
gccv=$(${CROSS_COMPILE}gcc -v 2>&1 | tail -1 | cut -d ' ' -f 3)
# Checksum
[[ -f "$out"/defconfsha ]] && defconfsha=$(awk '{print $1}' "$out"/defconfsha)
#
# Begin Build Process
#
start=$(date +%s)
printf "\n%s" "$top"
fargs "ARCHITECTURE:" "$arch"
fargs "DEVICE:" "$device"
fargs "THREADS:" "$threads"
[ -n "$type" ] && fargs "TYPE:" "$type"
[ -n "$version" ] && fargs "VERSION:" "$version"
fargs "GCC VERSION:" "$gccv"
fargs "TOOLCHAIN:" "$CROSS_COMPILE"
printf "\n%s\n" "${mid}${rst}"
printf "${mid}%5s${grn}%-25s ${cyn}%s\n${end}\n${rst}" "" "Build script by " "RebelLion420"
sleep 1
fmsg "Building Kernel Image"
if [[ -f "$out"/.config ]]; then
	if echo "${defconfsha} arch/${arch}/configs/${device}_defconfig"|sha1sum -c --quiet; then
		fmsg "Skipping generate config"
    fi
else
	if make O="$out" "$device"_defconfig |& tee -a "$logfile"; then
		fmsg "make ${device}_defconfig successful"
		shasum arch/"$arch"/configs/"$device"_defconfig > "$out"/defconfsha
	else
		fdie "make ${device}_defconfig failed!"
		greplog
		exit 1
	fi
fi
run_build "$img"
fmsg "Building DTBs"
run_build dtbs
fmsg "Building Modules"
run_build modules
find ./ -name "*.ko" -exec ${CROSS_COMPILE}strip --strip-unneeded {} \;
#find ./ -name "*.ko" -exec "$out"/scripts/sign-file sha512 out/certs/signing_key.pem out/certs/signing_key.x509 {} \;
echo ""
printf "\n${top}\n${mid}\n${mid}%5s ${blinkcyn}%s${rst}\n${mid}\n${end}\n" "" "Build Process Complete!"
runtime
greplog
#
# End Build Process
#
# Sanity Check
#
if [[ ! -d $ak3 ]]; then 
    ferr "AK3 not found, no zip created"
    ferr "Check out/ folder for results"
    exit 0
fi
for f in "$ak3"/*Image*; do
[[ -e "$f" ]] && {
        rm -f "$ak3"/*Image*
        rm -f "$ak3"/*.zip
        rm -f "$ak3"/*.dtb
        rm -f "$ak3"/modules/system/lib/modules/*.ko
}
done
#
# Zip Process
#
fmsg "Checking for files"
if find out/ -name "*.ko" -exec cp '{}' "${ak3}/modules/system/lib/modules/" \; ; then
	fmsg "Modules found"
else
	ferr "No modules found!"
fi
if find "$out"/arch/"$arch"/boot/dts/ -name '*.dtb' -type f -exec cp '{}' "$ak3/" \; ; then
	fmsg "DTBs found"
else
	ferr "No DTBs found!"
fi
fmsg "Creating Flashable Zip"
cp  $out/arch/$arch/boot/$img $ak3
cd $ak3
if zip -r9 $final ./* -x .git README.md *placeholder > /dev/null; then
	fmsg "Zip Created"
    cp $final $kernels
    fmsg "$final copied to $kernels"
else
	fdie "Zip Creation Failed"
	exit 1
fi
#
# Upload to MEGA
#
if command -v megaput >/dev/null 2>&1 || command -v megatools >/dev/null 2>&1 && [[ -f "$final" ]]; then
	echo ""
	read -rp "Upload kernel zip to MEGA?  " ul
	if [ "${ul,,}" == "y" ]; then
		fmsg "Uploading kernel zip to MEGA"
		case "$type" in
			"beta*")
				fmsg "${final} --> ${kernbeta}"
				megaput --path "$kernbeta" "$final"
				;;
			"release*")
				fmsg "${final} --> ${kernrel}"
				megaput --path "$kernrel" "$final"
				;;
			*)
				fmsg "${final} --> ${kern}"
				megaput --path "$kern" "$final"
				;;
		esac
		if [ "$?" != 0 ]; then
			fdie "Upload failed"
			exit 1
		else
			fmsg "Upload succeeded!"
		fi
	fi
else
	fdie "Final zip not found or megatools not installed."
	exit 1
fi
exit 0


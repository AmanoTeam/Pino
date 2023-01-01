#!/bin/bash

set -eu

declare -r app_directory="$(realpath "$(( [ -n "${BASH_SOURCE}" ] && dirname "$(realpath "${BASH_SOURCE[0]}")" ) || dirname "$(realpath "${0}")")")"

declare -ra triplets=(
	'aarch64-linux-android'
	'i686-linux-android'
	'arm-linux-androideabi'
	'x86_64-linux-android'
)

set +u

declare sdk_root=''

if [ -n "${ANDROID_HOME}" ]; then
	declare sdk_root="${ANDROID_HOME}"
else
	declare sdk_root="${ANDROID_SDK_ROOT}"
fi

if [ -z "${sdk_root}" ] || ! [ -d "${sdk_root}" ]; then
	echo 'fatal error: unable to find SDK location: please define ANDROID_HOME or ANDROID_SDK_ROOT' 2>&1
	exit '1'
fi

set -u

for directory in "${sdk_root}/ndk/"*; do
	declare source="${app_directory}/clang"
	declare destination="${directory}/toolchains/llvm/prebuilt/linux-x86_64/bin/clang"
	
	if [[ "$(readlink "${destination}")" = "${source}" ]]; then
		continue
	fi
	
	echo "- Symlinking ${source} to ${destination}"
	
	ln \
		--symbolic \
		--force \
		"${source}" \
		"${destination}"
	
	source+='++'
	destination+='++'
	
	echo "- Symlinking ${source} to ${destination}"
	
	ln \
		--symbolic \
		--force \
		"${source}" \
		"${destination}"
	
	for triplet in "${triplets[@]}"; do
		declare library="${directory}/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/lib/${triplet}/libc++_shared.so"
		
		[ -f "${library}" ] || continue
		
		echo "- Removing ${library}"
		
		unlink "${library}"
	done
done

echo -e '+ Done'

exit '0'

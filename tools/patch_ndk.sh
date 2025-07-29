#!/bin/bash

set -eu

declare -r app_directory="$(realpath "$(( [ -n "${BASH_SOURCE}" ] && dirname "$(realpath "${BASH_SOURCE[0]}")" ) || dirname "$(realpath "${0}")")")"

declare -ra versions=(
	'14'
	'15'
	'16'
	'17'
	'18'
	'19'
	'20'
	'21'
	'22'
	'23'
	'24'
	'25'
	'26'
	'27'
	'28'
	'29'
	'30'
	'31'
	'32'
	'33'
	'34'
	'35'
)

declare -ra triplets=(
	'aarch64-linux-android'
	'i686-linux-android'
	'arm-linux-androideabi'
	'x86_64-linux-android'
	'mips64el-linux-android'
	'mipsel-linux-android'
	'riscv64-linux-android'
)

set +u

declare sdk_root=''
declare ndk_root=''

declare directories=()

# Android SDK
if [ -z "${sdk_root}" ]; then
	declare sdk_root="${ANDROID_HOME}"
fi

if [ -z "${sdk_root}" ]; then
	declare sdk_root="${ANDROID_SDK_ROOT}"
fi

# Android NDK
if [ -z "${ndk_root}" ]; then
	declare ndk_root="${ANDROID_NDK_HOME}"
fi

if [ -z "${ndk_root}" ]; then
	declare ndk_root="${ANDROID_NDK_ROOT}"
fi

if [ -z "${ndk_root}" ]; then
	declare ndk_root="${NDK_HOME}"
fi

if [ -z "${ndk_root}" ]; then
	declare ndk_root="${ANDROID_NDK}"
fi

if [ -z "${ndk_root}" ]; then
	declare ndk_root="${ANDROID_NDK}"
fi

if [ -z "${ndk_root}" ]; then
	declare ndk_root="${NDK}"
fi

set -u

if [ -n "${sdk_root}" ] && [ -d "${sdk_root}" ]; then
	echo "- Found Android SDK at ${sdk_root}"
	
	for directory in "${sdk_root}/ndk/"*; do
		directories+=("${directory}")
	done
elif [ -n "${ndk_root}" ] && [ -d "${ndk_root}" ]; then
	echo "- Found Android NDK at ${ndk_root}"
	
	directories+=("${ndk_root}")
else
	echo 'fatal error: unable to find SDK location: please define ANDROID_HOME or ANDROID_SDK_ROOT' 2>&1
	echo 'fatal error: you can also explicitly set the NDK location with ANDROID_NDK_HOME or ANDROID_NDK_ROOT' 2>&1
	exit '1'
fi

for directory in "${directories[@]}"; do
	declare source="${app_directory}/clang"
	declare destination="${directory}/toolchains/llvm/prebuilt/linux-x86_64/bin/clang"
	
	if [[ "$(readlink "${destination}")" != "${source}" ]]; then
		echo "- Symlinking ${source} to ${destination}"
		
		ln \
			--symbolic \
			--force \
			"${source}" \
			"${destination}"
	fi
	
	source+='++'
	destination+='++'
	
	if [[ "$(readlink "${destination}")" != "${source}" ]]; then
		echo "- Symlinking ${source} to ${destination}"
		
		ln \
			--symbolic \
			--force \
			"${source}" \
			"${destination}"
	fi
	
	for triplet in "${triplets[@]}"; do
		declare library="${directory}/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/lib/${triplet}/libc++_shared.so"
		
		if [ -f "${library}" ]; then
			echo "- Removing ${library}"
			unlink "${library}"
		fi
		
		if [ "${triplet}" = 'arm-linux-androideabi' ]; then
			triplet='armv7a-linux-androideabi'
		fi
		
		for version in "${versions[@]}"; do
			declare a="${triplet/-linux/-unknown-linux}"
			a="${a/armv7a/armv7}"
			
			declare source="${app_directory}/${a}${version}-clang"
			declare destination="${directory}/toolchains/llvm/prebuilt/linux-x86_64/bin/${triplet}${version}-clang"
			
			if ! [ -f "${source}" ]; then
				continue
			fi
			
			if [[ "$(readlink "${destination}")" != "${source}" ]]; then
				echo "- Symlinking ${source} to ${destination}"
				
				ln \
					--symbolic \
					--force \
					"${source}" \
					"${destination}"
			fi
			
			source+='++'
			destination+='++'
			
			if [[ "$(readlink "${destination}")" != "${source}" ]]; then
				echo "- Symlinking ${source} to ${destination}"
				
				ln \
					--symbolic \
					--force \
					"${source}" \
					"${destination}"
			fi
		done
	done
done

echo -e '+ Done'

exit '0'

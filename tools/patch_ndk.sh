#!/bin/bash

set -eu

declare -r app_directory="$(realpath "$(( [ -n "${BASH_SOURCE}" ] && dirname "$(realpath "${BASH_SOURCE[0]}")" ) || dirname "$(realpath "${0}")")")"

declare -ra binutils=(
	'addr2line'
	'ar'
	'as'
	'c++filt'
	'cpp'
	'elfedit'
	'dwp'
	'gcc-ar'
	'gcc-nm'
	'gcc-ranlib'
	'gcov'
	'gcov-dump'
	'gcov-tool'
	'gprof'
	'ld'
	'ld.bfd'
	'ld.gold'
	'lto-dump'
	'nm'
	'objcopy'
	'objdump'
	'ranlib'
	'readelf'
	'size'
	'strings'
	'strip'
)

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

declare -r os="$(uname -o)"

declare symlink_options='--symbolic --force'
declare slug='linux-x86_64'

if [ "${os}" = 'Darwin' ]; then
	slug='darwin-x86_64'
	symlink_options='-s -f'
fi

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
		if ! [ -d "${directory}" ]; then
			continue
		fi
		
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
	declare destination="${directory}/toolchains/llvm/prebuilt/${slug}/bin/clang"
	
	declare toolchains_directory="${directory}/toolchains"
	
	if [[ "$(readlink "${destination}")" != "${source}" ]]; then
		echo "- Symlinking ${source} to ${destination}"
		ln ${symlink_options} "${source}" "${destination}"
	fi
	
	source+='++'
	destination+='++'
	
	if [[ "$(readlink "${destination}")" != "${source}" ]]; then
		echo "- Symlinking ${source} to ${destination}"
		ln ${symlink_options} "${source}" "${destination}"
	fi
	
	source="${source/clang++/llvm-strip}"
	destination="${destination/clang++/llvm-strip}"
	
	if [[ "$(readlink "${destination}")" != "${source}" ]]; then
		echo "- Symlinking ${source} to ${destination}"
		ln ${symlink_options} "${source}" "${destination}"
	fi
	
	source="${source/llvm-strip/llvm-objcopy}"
	destination="${destination/llvm-strip/llvm-objcopy}"
	
	if [[ "$(readlink "${destination}")" != "${source}" ]]; then
		echo "- Symlinking ${source} to ${destination}"
		ln ${symlink_options} "${source}" "${destination}"
	fi
	
	for triplet in "${triplets[@]}"; do
		declare original_triplet="${triplet}"
		
		if [ "${triplet}" = 'arm-linux-androideabi' ]; then
			triplet='armv7a-linux-androideabi'
		fi
		
		declare canonical_triplet="${triplet/-linux/-unknown-linux}"
		canonical_triplet="${canonical_triplet/armv7a/armv7}"
		
		for name in "${binutils[@]}"; do
			declare source="${app_directory}/${canonical_triplet}-${name}"
			declare destination="${directory}/toolchains/llvm/prebuilt/${slug}/bin/${triplet}-${name}"
			
			if ! [ -f "${source}" ]; then
				continue
			fi
			
			if [[ "$(readlink "${destination}")" != "${source}" ]]; then
				echo "- Symlinking ${source} to ${destination}"
				ln ${symlink_options} "${source}" "${destination}"
			fi
			
			declare subdirectory=''
			
			if [ "${original_triplet}" = 'aarch64-linux-android' ]; then
				subdirectory="${toolchains_directory}/${original_triplet}-4.9"
			elif [ "${original_triplet}" = 'arm-linux-androideabi' ]; then
				subdirectory="${toolchains_directory}/${original_triplet}-4.9"
			elif [ "${original_triplet}" = 'x86_64-linux-android' ]; then
				subdirectory="${toolchains_directory}/x86_64-4.9"
			elif [ "${original_triplet}" = 'i686-linux-android' ]; then
				subdirectory="${toolchains_directory}/x86-4.9"
			fi
			
			if [ -d "${subdirectory}" ]; then
				subdirectory+="/prebuilt/${slug}/bin"
				destination="${subdirectory}/${original_triplet}-${name}"
				
				if [[ "$(readlink "${destination}")" != "${source}" ]]; then
					echo "- Symlinking ${source} to ${destination}"
					ln ${symlink_options} "${source}" "${destination}"
				fi
			fi
			
			if [ "${original_triplet}" = "${triplet}" ]; then
				continue
			fi
			
			destination="${directory}/toolchains/llvm/prebuilt/${slug}/bin/${original_triplet}-${name}"
			
			if [[ "$(readlink "${destination}")" != "${source}" ]]; then
				echo "- Symlinking ${source} to ${destination}"
				ln ${symlink_options} "${source}" "${destination}"
			fi
		done
		
		for version in "${versions[@]}"; do
			declare source="${app_directory}/${canonical_triplet}${version}-clang"
			declare destination="${directory}/toolchains/llvm/prebuilt/${slug}/bin/${triplet}${version}-clang"
			
			if ! [ -f "${source}" ]; then
				continue
			fi
			
			if [[ "$(readlink "${destination}")" != "${source}" ]]; then
				echo "- Symlinking ${source} to ${destination}"
				ln ${symlink_options} "${source}" "${destination}"
			fi
			
			source+='++'
			destination+='++'
			
			if [[ "$(readlink "${destination}")" != "${source}" ]]; then
				echo "- Symlinking ${source} to ${destination}"
				ln ${symlink_options} "${source}" "${destination}"
			fi
		done
	done
done

echo -e '+ Done'

exit '0'

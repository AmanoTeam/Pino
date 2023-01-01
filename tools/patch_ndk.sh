#!/bin/bash

set -eu

declare -r app_directory="$(realpath "$(( [ -n "${BASH_SOURCE}" ] && dirname "$(realpath "${BASH_SOURCE[0]}")" ) || dirname "$(realpath "${0}")")")"

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
	
	echo "- Patching ${destination}"
	
	ln \
		--symbolic \
		--force \
		"${source}" \
		"${destination}"
	
	source+='++'
	destination+='++'
	
	echo "- Patching ${destination}"
	
	ln \
		--symbolic \
		--force \
		"${source}" \
		"${destination}"
done

echo -e '\n+ Patch applied!\n'

echo '* Please run "./gradlew clean" in the root directory of your project at least once before compiling it.'
echo '* Due to incompatibilities between Clang and GCC, you might need to adapt your code for it to properly compile with GCC.'

exit '0'

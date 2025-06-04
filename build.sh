#!/bin/bash

set -eu

declare -r toolchain_directory='/tmp/pino'
declare -r share_directory="${toolchain_directory}/usr/local/share/pino"

declare -r workdir="${PWD}"

declare -r revision="$(git rev-parse --short HEAD)"

declare -r gmp_tarball='/tmp/gmp.tar.xz'
declare -r gmp_directory='/tmp/gmp-6.3.0'

declare -r mpfr_tarball='/tmp/mpfr.tar.xz'
declare -r mpfr_directory='/tmp/mpfr-4.2.2'

declare -r mpc_tarball='/tmp/mpc.tar.gz'
declare -r mpc_directory='/tmp/mpc-1.3.1'

declare -r isl_tarball='/tmp/isl.tar.xz'
declare -r isl_directory='/tmp/isl-0.27'

declare -r binutils_tarball='/tmp/binutils.tar.xz'
declare -r binutils_directory='/tmp/binutils-with-gold-2.44'

declare -r gcc_tarball='/tmp/gcc.tar.xz'
declare -r gcc_directory='/tmp/gcc-releases-gcc-15'

declare -r max_jobs='30'

declare -r pieflags='-fPIE'
declare -r optflags='-w -O2 -Xlinker --allow-multiple-definition'
declare -r linkflags='-Xlinker -s'

declare -ra asan_libraries=(
	'libasan'
	'libhwasan'
	'liblsan'
	'libtsan'
	'libubsan'
)

declare -ra plugin_libraries=(
	'libcc1plugin'
	'libcp1plugin'
)

declare -ra targets=(
	'aarch64-unknown-linux-android'
	# 'x86_64-unknown-linux-android'
	# 'i686-unknown-linux-android'
	# 'arm-unknown-linux-androideabi'
)

export \
	ac_cv_func_aligned_alloc=no \
	ac_cv_func__aligned_malloc=no \
	ac_cv_func_memalign=no \
	ac_cv_c_bigendian=no

declare build_type="${1}"

if [ -z "${build_type}" ]; then
	build_type='native'
fi

declare is_native='0'

if [ "${build_type}" = 'native' ]; then
	is_native='1'
fi

declare CROSS_COMPILE_TRIPLET=''

if ! (( is_native )); then
	source "./submodules/obggcc/toolchains/${build_type}.sh"
fi

declare -r \
	build_type \
	is_native

if ! [ -f "${gmp_tarball}" ]; then
	curl \
		--url 'https://ftp.gnu.org/gnu/gmp/gmp-6.3.0.tar.xz' \
		--retry '30' \
		--retry-all-errors \
		--retry-delay '0' \
		--retry-max-time '0' \
		--location \
		--silent \
		--output "${gmp_tarball}"
	
	tar \
		--directory="$(dirname "${gmp_directory}")" \
		--extract \
		--file="${gmp_tarball}"
fi

if ! [ -f "${mpfr_tarball}" ]; then
	curl \
		--url 'https://ftp.gnu.org/gnu/mpfr/mpfr-4.2.2.tar.xz' \
		--retry '30' \
		--retry-all-errors \
		--retry-delay '0' \
		--retry-max-time '0' \
		--location \
		--silent \
		--output "${mpfr_tarball}"
	
	tar \
		--directory="$(dirname "${mpfr_directory}")" \
		--extract \
		--file="${mpfr_tarball}"
fi

if ! [ -f "${mpc_tarball}" ]; then
	curl \
		--url 'https://ftp.gnu.org/gnu/mpc/mpc-1.3.1.tar.gz' \
		--retry '30' \
		--retry-all-errors \
		--retry-delay '0' \
		--retry-max-time '0' \
		--location \
		--silent \
		--output "${mpc_tarball}"
	
	tar \
		--directory="$(dirname "${mpc_directory}")" \
		--extract \
		--file="${mpc_tarball}"
fi

if ! [ -f "${isl_tarball}" ]; then
	curl \
		--url 'https://libisl.sourceforge.io/isl-0.27.tar.xz' \
		--retry '30' \
		--retry-all-errors \
		--retry-delay '0' \
		--retry-max-time '0' \
		--location \
		--silent \
		--output "${isl_tarball}"
	
	tar \
		--directory="$(dirname "${isl_directory}")" \
		--extract \
		--file="${isl_tarball}"
fi

if ! [ -f "${binutils_tarball}" ]; then
	curl \
		--url 'https://ftp.gnu.org/gnu/binutils/binutils-with-gold-2.44.tar.xz' \
		--retry '30' \
		--retry-all-errors \
		--retry-delay '0' \
		--retry-max-time '0' \
		--location \
		--silent \
		--output "${binutils_tarball}"
	
	tar \
		--directory="$(dirname "${binutils_directory}")" \
		--extract \
		--file="${binutils_tarball}"
	
	patch --directory="${binutils_directory}" --strip='1' --input="${workdir}/submodules/obggcc/patches/0001-Revert-gold-Use-char16_t-char32_t-instead-of-uint16_.patch"
	patch --directory="${binutils_directory}" --strip='1' --input="${workdir}/submodules/obggcc/patches/0001-Disable-annoying-linker-warnings.patch"
fi

if ! [ -f "${gcc_tarball}" ]; then
	curl \
		--url 'https://github.com/gcc-mirror/gcc/archive/refs/heads/releases/gcc-15.tar.gz' \
		--retry '30' \
		--retry-all-errors \
		--retry-delay '0' \
		--retry-max-time '0' \
		--location \
		--silent \
		--output "${gcc_tarball}"
	
	tar \
		--directory="$(dirname "${gcc_directory}")" \
		--extract \
		--file="${gcc_tarball}"
	
	for name in "${workdir}/submodules/tur/tur/gcc-15/"*'.patch'; do
		patch --directory="${gcc_directory}" --strip='1' --input="${name}"
	done
	
	patch --directory="${gcc_directory}" --strip='1' --input="${workdir}/patches/0001-a.patch"
	patch --directory="${gcc_directory}" --strip='1' --input="${workdir}/submodules/obggcc/patches/0001-Fix-libgcc-build-on-arm.patch"
	patch --directory="${gcc_directory}" --strip='1' --input="${workdir}/submodules/obggcc/patches/0001-Change-the-default-language-version-for-C-compilatio.patch"
	patch --directory="${gcc_directory}" --strip='1' --input="${workdir}/submodules/obggcc/patches/0001-Turn-Wimplicit-int-back-into-an-warning.patch"
	patch --directory="${gcc_directory}" --strip='1' --input="${workdir}/submodules/obggcc/patches/0001-Turn-Wint-conversion-back-into-an-warning.patch"
	patch --directory="${gcc_directory}" --strip='1' --input="${workdir}/submodules/obggcc/patches/0001-Revert-GCC-change-about-turning-Wimplicit-function-d.patch"
fi

[ -d "${gmp_directory}/build" ] || mkdir "${gmp_directory}/build"

cd "${gmp_directory}/build"

../configure \
	--host="${CROSS_COMPILE_TRIPLET}" \
	--prefix="${toolchain_directory}" \
	--enable-shared \
	--disable-static \
	CFLAGS="${optflags}" \
	CXXFLAGS="${optflags}" \
	LDFLAGS="${linkflags}"

make all --jobs
make install

[ -d "${mpfr_directory}/build" ] || mkdir "${mpfr_directory}/build"

cd "${mpfr_directory}/build"

../configure \
	--host="${CROSS_COMPILE_TRIPLET}" \
	--prefix="${toolchain_directory}" \
	--with-gmp="${toolchain_directory}" \
	--enable-shared \
	--disable-static \
	CFLAGS="${optflags}" \
	CXXFLAGS="${optflags}" \
	LDFLAGS="${linkflags}"

make all --jobs
make install

[ -d "${mpc_directory}/build" ] || mkdir "${mpc_directory}/build"

cd "${mpc_directory}/build"

../configure \
	--host="${CROSS_COMPILE_TRIPLET}" \
	--prefix="${toolchain_directory}" \
	--with-gmp="${toolchain_directory}" \
	--enable-shared \
	--disable-static \
	CFLAGS="${optflags}" \
	CXXFLAGS="${optflags}" \
	LDFLAGS="${linkflags}"

make all --jobs
make install

[ -d "${isl_directory}/build" ] || mkdir "${isl_directory}/build"

cd "${isl_directory}/build"
rm --force --recursive ./*

../configure \
	--host="${CROSS_COMPILE_TRIPLET}" \
	--prefix="${toolchain_directory}" \
	--with-gmp-prefix="${toolchain_directory}" \
	--enable-shared \
	--disable-static \
	CFLAGS="${pieflags} ${optflags}" \
	CXXFLAGS="${pieflags} ${optflags}" \
	LDFLAGS="-Xlinker -rpath-link -Xlinker ${toolchain_directory}/lib ${linkflags}"

make all --jobs
make install

for triplet in "${targets[@]}"; do
	declare extra_configure_flags=''
	
	if [ "${triplet}" = 'arm-unknown-linux-androideabi' ]; then
		extra_configure_flags+=' --with-arch=armv7-a --with-float=soft --with-fpu=vfp'
	elif [ "${triplet}" = 'aarch64-unknown-linux-android' ]; then
		extra_configure_flags+=' --enable-fix-cortex-a53-835769 --enable-fix-cortex-a53-843419'
	elif [ "${triplet}" = 'i686-unknown-linux-android' ]; then
		extra_configure_flags+=' --with-arch=i686 --with-fpmath=sse'
		#specs+="\n*link_emulation:\nelf_i386\n\n*dynamic_linker:\n/system/bin/linker\n"
	elif [ "${triplet}" = 'x86_64-unknown-linux-android' ]; then
		extra_configure_flags+=' --with-arch=x86-64 --with-fpmath=sse'
	fi
	
	[ -d "${binutils_directory}/build" ] || mkdir "${binutils_directory}/build"
	
	cd "${binutils_directory}/build"
	rm --force --recursive ./*
	
	../configure \
		--host="${CROSS_COMPILE_TRIPLET}" \
		--target="${triplet}" \
		--prefix="${toolchain_directory}" \
		--disable-gold \
		--enable-ld \
		--disable-lto \
		--disable-gprofng \
		--with-static-standard-libraries \
		--with-sysroot="${toolchain_directory}/${triplet}" \
		CFLAGS="${optflags}" \
		CXXFLAGS="${optflags}" \
		LDFLAGS="${linkflags}"
	
	make all --jobs="${max_jobs}"
	make install
	
	cd "$(mktemp --directory)"
	
	declare sysroot_url="https://github.com/AmanoTeam/android-sysroot/releases/latest/download/${triplet}.tar.xz"
	declare sysroot_file="${PWD}/${triplet}.tar.xz"
	declare sysroot_directory="${PWD}/${triplet}"
	
	curl \
		--url "${sysroot_url}" \
		--retry '30' \
		--retry-all-errors \
		--retry-delay '0' \
		--retry-max-time '0' \
		--location \
		--silent \
		--output "${sysroot_file}"
	
	tar \
		--extract \
		--file="${sysroot_file}"
	
	echo 'INPUT(-lc)' > "${sysroot_directory}/lib/libpthread.so"
	
	cp --recursive "${sysroot_directory}" "${toolchain_directory}"
	
	rm --force --recursive ./*
	
	# %{Oz:-Os} %>Oz
	# %>Werror=unguarded-availability-new
	
	declare specs="$(
		cat <<- specs | tr '\n' ' '
			%{!fno-common:%{!fcommon:-fcommon}}
			%{,c++:%{!fno-rtti:%{!frtti:-frtti}}}
			-D__ANDROID_API__=21
			-Xlinker --eh-frame-hdr
		specs
	)"
	
	if [ "${triplet}" = 'aarch64-unknown-linux-android' ] ||  "${triplet}" = 'arm-unknown-linux-androideabi' ]; then
		specs+=' -Xlinker -z -Xlinker max-page-size=16384'
	fi
	
	if [ "${triplet}" = 'aarch64-unknown-linux-android' ]; then
		specs+=' -ffixed-x18'
	fi
	
	if (( is_native )); then
		extra_configure_flags+=' --disable-libsanitizer'
	else
		extra_configure_flags+=' --enable-libsanitizer'
	fi
	
	[ -d "${gcc_directory}/build" ] || mkdir "${gcc_directory}/build"
	
	cd "${gcc_directory}/build"
	
	rm --force --recursive ./*
	
	../configure \
		--host="${CROSS_COMPILE_TRIPLET}" \
		--target="${triplet}" \
		--prefix="${toolchain_directory}" \
		--with-linker-hash-style='gnu' \
		--with-gmp="${toolchain_directory}" \
		--with-mpc="${toolchain_directory}" \
		--with-mpfr="${toolchain_directory}" \
		--with-isl="${toolchain_directory}" \
		--with-bugurl='https://github.com/AmanoTeam/Pino/issues' \
		--with-gcc-major-version-only \
		--with-pkgversion="Pino v0.1-${revision}" \
		--with-sysroot="${toolchain_directory}/${triplet}" \
		--with-native-system-header-dir='/include' \
		--with-default-libstdcxx-abi='new' \
		--includedir="${toolchain_directory}/${triplet}/include" \
		--enable-__cxa_atexit \
		--enable-cet='auto' \
		--enable-checking='release' \
		--enable-default-pie \
		--enable-default-ssp \
		--enable-gnu-indirect-function \
		--enable-gnu-unique-object \
		--enable-languages='c,c++' \
		--enable-libstdcxx-backtrace \
		--enable-libstdcxx-filesystem-ts \
		--enable-libstdcxx-static-eh-pool \
		--with-libstdcxx-zoneinfo='static' \
		--with-libstdcxx-lock-policy='atomic' \
		--enable-link-serialization='1' \
		--enable-linker-build-id \
		--enable-lto \
		--enable-plugin \
		--enable-shared \
		--enable-threads='posix' \
		--enable-libstdcxx-threads \
		--enable-libssp \
		--enable-ld \
		--enable-gold \
		--enable-cxx-flags="${linkflags}" \
		--enable-host-pie \
		--enable-host-shared \
		--enable-version-specific-runtime-libs \
		--enable-eh-frame-hdr-for-static \
		--enable-initfini-array \
		--with-specs="${specs}" \
		--disable-tls \
		--disable-fixincludes \
		--disable-libstdcxx-pch \
		--disable-werror \
		--disable-libgomp \
		--disable-bootstrap \
		--disable-multilib \
		--without-headers \
		${extra_configure_flags} \
		CFLAGS="${optflags}" \
		CXXFLAGS="${optflags}" \
		LDFLAGS="${linkflags}"
	
	LD_LIBRARY_PATH="${toolchain_directory}/lib" PATH="${PATH}:${toolchain_directory}/bin" make \
		CFLAGS_FOR_TARGET="${optflags} ${linkflags}" \
		CXXFLAGS_FOR_TARGET="${optflags} ${linkflags}" \
		all --jobs="${max_jobs}"
	make install
	
	pushd "${toolchain_directory}/${triplet}/lib"
	
	unlink './libstdc++.so'
	
	for library in "../../lib/gcc/${triplet}/"*'/lib'*.{so,a,1}; do
		name="$(basename "${library}")"
		
		[ -f "${name}" ] && unlink "${name}"
		
		ln --symbolic "${library}" './'
	done
	
	pushd
	
	patchelf --add-rpath '$ORIGIN/../../../../lib' "${toolchain_directory}/libexec/gcc/${triplet}/"*"/cc1"
	patchelf --add-rpath '$ORIGIN/../../../../lib' "${toolchain_directory}/libexec/gcc/${triplet}/"*"/cc1plus"
	patchelf --add-rpath '$ORIGIN/../../../../lib' "${toolchain_directory}/libexec/gcc/${triplet}/"*"/lto1"
	
	for library in "${asan_libraries[@]}"; do
		patchelf --set-rpath '$ORIGIN' "${toolchain_directory}/lib"*"/${library}.so" || true
		patchelf --set-rpath '$ORIGIN' "${toolchain_directory}/${triplet}/lib"*"/${library}.so" || true
	done
	
	for library in "${plugin_libraries[@]}"; do
		patchelf --set-rpath "\$ORIGIN/../../../../../${triplet}/lib64:\$ORIGIN/../../../../../${triplet}/lib:\$ORIGIN/../../../../../lib64:\$ORIGIN/../../../../../lib" "${toolchain_directory}/lib/gcc/${triplet}/"*"/plugin/${library}.so"
	done
done

mkdir --parent "${share_directory}"

# cp --recursive "${workdir}/tools/dev/"* "${share_directory}"

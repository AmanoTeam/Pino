#!/bin/bash

set -eu

declare -r toolchain_directory='/tmp/pino'
declare -r share_directory="${toolchain_directory}/usr/local/share/pino"

declare -r environment="LD_LIBRARY_PATH=${toolchain_directory}/lib PATH=${PATH}:${toolchain_directory}/bin"

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

declare -r zstd_tarball='/tmp/zstd.tar.gz'
declare -r zstd_directory='/tmp/zstd-dev'

declare -r nz_tarball='/tmp/nz.tar.xz'
declare -r nz_directory='/tmp/nouzen'

declare nz='1'

declare -r max_jobs='30'

declare -r pieflags='-fPIE'
declare -r optflags='-w -O2'
declare -r linkflags='-Xlinker -s'

declare -ra targets=(
	'riscv64-unknown-linux-android'
	'x86_64-unknown-linux-android'
	'i686-unknown-linux-android'
	'arm-unknown-linux-androideabi'
	'aarch64-unknown-linux-android'
)

declare -ra versions=(
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

declare -r gcc_wrapper='/tmp/gcc-wrapper'

declare -ra symlink_tools=(
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

declare -ra libraries=(
	'libstdc++'
	'libatomic'
	'libssp'
	'libitm'
	'libsupc++'
	'libgcc'
	'libm2cor'
	'libm2iso'
	'libm2log'
	'libm2min'
	'libm2pim'
	'libobjc'
	'libgfortran'
	'libasan'
	'libhwasan'
	'liblsan'
	'libtsan'
	'libubsan'
)

declare -ra bits=(
	''
	'64'
)

declare -r PKG_CONFIG_PATH="${toolchain_directory}/lib/pkgconfig"

export PKG_CONFIG_PATH

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

set +u

if [ -z "${CROSS_COMPILE_TRIPLET}" ]; then
	declare CROSS_COMPILE_TRIPLET=''
fi

set -u

declare -r \
	build_type \
	is_native

if ! [ -f "${gmp_tarball}" ]; then
	curl \
		--url 'https://mirrors.kernel.org/gnu/gmp/gmp-6.3.0.tar.xz' \
		--retry '30' \
		--retry-delay '0' \
		--retry-all-errors \
		--retry-max-time '0' \
		--location \
		--silent \
		--output "${gmp_tarball}"
	
	tar \
		--directory="$(dirname "${gmp_directory}")" \
		--extract \
		--file="${gmp_tarball}"
	
	patch --directory="${gmp_directory}" --strip='1' --input="${workdir}/submodules/obggcc/patches/0001-Remove-hardcoded-RPATH-and-versioned-SONAME-from-libgmp.patch"
fi

if ! [ -f "${mpfr_tarball}" ]; then
	curl \
		--url 'https://mirrors.kernel.org/gnu/mpfr/mpfr-4.2.2.tar.xz' \
		--retry '30' \
		--retry-delay '0' \
		--retry-all-errors \
		--retry-max-time '0' \
		--location \
		--silent \
		--output "${mpfr_tarball}"
	
	tar \
		--directory="$(dirname "${mpfr_directory}")" \
		--extract \
		--file="${mpfr_tarball}"
	
	patch --directory="${mpfr_directory}" --strip='1' --input="${workdir}/submodules/obggcc/patches/0001-Remove-hardcoded-RPATH-and-versioned-SONAME-from-libmpfr.patch"
fi

if ! [ -f "${mpc_tarball}" ]; then
	curl \
		--url 'https://mirrors.kernel.org/gnu/mpc/mpc-1.3.1.tar.gz' \
		--retry '30' \
		--retry-delay '0' \
		--retry-all-errors \
		--retry-max-time '0' \
		--location \
		--silent \
		--output "${mpc_tarball}"
	
	tar \
		--directory="$(dirname "${mpc_directory}")" \
		--extract \
		--file="${mpc_tarball}"
	
	patch --directory="${mpc_directory}" --strip='1' --input="${workdir}/submodules/obggcc/patches/0001-Remove-hardcoded-RPATH-and-versioned-SONAME-from-libmpc.patch"
fi

if ! [ -f "${isl_tarball}" ]; then
	curl \
		--url 'https://sourceforge.net/projects/libisl/files/isl-0.27.tar.xz' \
		--retry '30' \
		--retry-delay '0' \
		--retry-all-errors \
		--retry-max-time '0' \
		--location \
		--silent \
		--output "${isl_tarball}"
	
	tar \
		--directory="$(dirname "${isl_directory}")" \
		--extract \
		--file="${isl_tarball}"
	
	patch --directory="${isl_directory}" --strip='1' --input="${workdir}/submodules/obggcc/patches/0001-Remove-hardcoded-RPATH-and-versioned-SONAME-from-libisl.patch"
fi

if ! [ -f "${binutils_tarball}" ]; then
	curl \
		--url 'https://mirrors.kernel.org/gnu/binutils/binutils-with-gold-2.44.tar.xz' \
		--retry '30' \
		--retry-delay '0' \
		--retry-all-errors \
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
	patch --directory="${binutils_directory}" --strip='1' --input="${workdir}/submodules/obggcc/patches/0001-Add-relative-RPATHs-to-binutils-host-tools.patch"
fi

if ! [ -f "${zstd_tarball}" ]; then
	curl \
		--url 'https://github.com/facebook/zstd/archive/refs/heads/dev.tar.gz' \
		--retry '30' \
		--retry-delay '0' \
		--retry-all-errors \
		--retry-max-time '0' \
		--location \
		--silent \
		--output "${zstd_tarball}"
	
	tar \
		--directory="$(dirname "${zstd_directory}")" \
		--extract \
		--file="${zstd_tarball}"
fi

if ! [ -f "${gcc_tarball}" ]; then
	curl \
		--url 'https://github.com/gcc-mirror/gcc/archive/refs/heads/releases/gcc-15.tar.gz' \
		--retry '30' \
		--retry-delay '0' \
		--retry-all-errors \
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
	
	patch --directory="${gcc_directory}" --strip='1' --input="${workdir}/patches/0001-Avoid-relying-on-dynamic-shadow-when-building-libsan.patch"
	patch --directory="${gcc_directory}" --strip='1' --input="${workdir}/patches/0001-Fix-declarations-of-fgetpos-and-fsetpos.patch"
	patch --directory="${gcc_directory}" --strip='1' --input="${workdir}/patches/0001-Fix-declaration-of-posix_memalign-on-x86.patch"
	patch --directory="${gcc_directory}" --strip='1' --input="${workdir}/patches/0001-Disable-SONAME-versioning-for-all-target-libraries.patch"
	patch --directory="${gcc_directory}" --strip='1' --input="${workdir}/patches/0001-Change-GCC-s-C-standard-library-name-to-libestdc.patch"
	patch --directory="${gcc_directory}" --strip='1' --input="${workdir}/patches/0001-Rename-GCC-s-libgcc-library-to-libegcc.patch"
	patch --directory="${gcc_directory}" --strip='1' --input="${workdir}/patches/0001-Ignore-pragma-weak-when-the-declaration-is-private-o.patch"
	patch --directory="${gcc_directory}" --strip='1' --input="${workdir}/patches/0001-Add-support-to-riscv64.patch"
	
	patch --directory="${gcc_directory}" --strip='1' --input="${workdir}/submodules/obggcc/patches/0001-Fix-libgcc-build-on-arm.patch"
	patch --directory="${gcc_directory}" --strip='1' --input="${workdir}/submodules/obggcc/patches/0001-Change-the-default-language-version-for-C-compilatio.patch"
	patch --directory="${gcc_directory}" --strip='1' --input="${workdir}/submodules/obggcc/patches/0001-Turn-Wimplicit-int-back-into-an-warning.patch"
	patch --directory="${gcc_directory}" --strip='1' --input="${workdir}/submodules/obggcc/patches/0001-Turn-Wint-conversion-back-into-an-warning.patch"
	patch --directory="${gcc_directory}" --strip='1' --input="${workdir}/submodules/obggcc/patches/0001-Revert-GCC-change-about-turning-Wimplicit-function-d.patch"
	patch --directory="${gcc_directory}" --strip='1' --input="${workdir}/submodules/obggcc/patches/0001-Add-relative-RPATHs-to-GCC-host-tools.patch"
	
	if [[ "${CROSS_COMPILE_TRIPLET}" == *'-openbsd'* ]]; then
		patch --directory="${gcc_directory}" --strip='1' --input="${workdir}/submodules/obggcc/patches/0001-Fix-missing-stdint.h-include-when-compiling-host-tools-on-OpenBSD.patch"
	fi
fi

# Follow Debian's approach for removing hardcoded RPATH from binaries
# https://wiki.debian.org/RpathIssue
sed \
	--in-place \
	--regexp-extended \
	's/(hardcode_into_libs)=.*$/\1=no/' \
	"${isl_directory}/configure" \
	"${mpc_directory}/configure" \
	"${mpfr_directory}/configure" \
	"${gmp_directory}/configure" \
	"${gcc_directory}/libsanitizer/configure"

# Fix Autotools mistakenly detecting shared libraries as not supported on OpenBSD
while read file; do
	sed \
		--in-place \
		--regexp-extended \
		's|test -f /usr/libexec/ld.so|true|g' \
		"${file}"
done <<< "$(find '/tmp' -type 'f' -name 'configure')"

# Force GCC and binutils to prefix host tools with the target triplet even in native builds
sed \
	--in-place \
	's/test "$host_noncanonical" = "$target_noncanonical"/false/' \
	"${gcc_directory}/configure" \
	"${binutils_directory}/configure"

if ! [ -f "${nz_tarball}" ]; then
	declare target="${build_type}"
	
	if [ "${target}" = 'native' ]; then
		target='x86_64-unknown-linux-gnu'
	fi
	
	declare url="https://github.com/AmanoTeam/Nouzen/releases/latest/download/${target}.tar.xz"
	declare directory="/tmp/${target}"
	
	rm --force --recursive "${directory}"
	
	echo "- Fetching data from '${url}'"
	
	curl \
		--url "${url}" \
		--retry '30' \
		--retry-all-errors \
		--retry-delay '0' \
		--retry-max-time '0' \
		--location \
		--silent \
		--output "${nz_tarball}"
	
	tar \
		--directory="$(dirname "${directory}")" \
		--extract \
		--file="${nz_tarball}" 2>/dev/null || nz='0'
	
	if (( nz )); then
		mv "${directory}" "${nz_directory}" 
	fi
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

[ -d "${zstd_directory}/.build" ] || mkdir "${zstd_directory}/.build"

cd "${zstd_directory}/.build"
rm --force --recursive ./*

cmake \
	-S "${zstd_directory}/build/cmake" \
	-B "${PWD}" \
	-DCMAKE_C_FLAGS="-DZDICT_QSORT=ZDICT_QSORT_MIN ${optflags}" \
	-DCMAKE_INSTALL_PREFIX="${toolchain_directory}" \
	-DBUILD_SHARED_LIBS=ON \
	-DZSTD_BUILD_PROGRAMS=OFF \
	-DZSTD_BUILD_TESTS=OFF \
	-DZSTD_BUILD_STATIC=OFF \
	-DCMAKE_PLATFORM_NO_VERSIONED_SONAME=ON

cmake --build "${PWD}"
cmake --install "${PWD}" --strip

declare cc='gcc'

if ! (( is_native )); then
	cc="${CC}"
fi

"${cc}" \
	"${workdir}/submodules/obggcc/tools/gcc-wrapper/"*'/'*'.c' \
	"${workdir}/submodules/obggcc/tools/gcc-wrapper/"*".c" \
	-I "${workdir}/submodules/obggcc/tools/gcc-wrapper" \
	${optflags} \
	${linkflags} \
	-D PINO \
	-o "${gcc_wrapper}"

# We prefer symbolic links over hard links.
cp "${workdir}/submodules/obggcc/tools/ln.sh" '/tmp/ln'

export PATH="/tmp:${PATH}"

# The gold linker build incorrectly detects ffsll() as unsupported.
if [[ "${CROSS_COMPILE_TRIPLET}" == *'-android'* ]]; then
	export ac_cv_func_ffsll=yes
fi

for triplet in "${targets[@]}"; do
	declare extra_configure_flags=''
	declare base_version='21'
	
	if [ "${triplet}" = 'riscv64-unknown-linux-android' ]; then
		base_version='35'
	fi
	
	if [ "${triplet}" = 'arm-unknown-linux-androideabi' ]; then
		extra_configure_flags+=' --with-arch=armv7-a --with-float=soft --with-fpu=neon'
	elif [ "${triplet}" = 'aarch64-unknown-linux-android' ]; then
		extra_configure_flags+=' --enable-fix-cortex-a53-835769 --enable-fix-cortex-a53-843419'
	elif [ "${triplet}" = 'i686-unknown-linux-android' ]; then
		extra_configure_flags+=' --with-arch=i686 --with-fpmath=sse'
	elif [ "${triplet}" = 'x86_64-unknown-linux-android' ]; then
		extra_configure_flags+=' --with-arch=x86-64 --with-fpmath=sse'
	elif [ "${triplet}" = 'riscv64-unknown-linux-android' ]; then
		extra_configure_flags+=' --with-arch=rv64gc --with-abi=lp64d'
	fi
	
	[ -d "${binutils_directory}/build" ] || mkdir "${binutils_directory}/build"
	
	cd "${binutils_directory}/build"
	rm --force --recursive ./*
	
	../configure \
		--host="${CROSS_COMPILE_TRIPLET}" \
		--target="${triplet}" \
		--prefix="${toolchain_directory}" \
		--enable-gold \
		--enable-ld \
		--enable-lto \
		--enable-separate-code \
		--enable-rosegment \
		--enable-relro \
		--enable-compressed-debug-sections='all' \
		--enable-default-compressed-debug-sections-algorithm='zstd' \
		--disable-gprofng \
		--disable-default-execstack \
		--without-static-standard-libraries \
		--with-sysroot="${toolchain_directory}/${triplet}" \
		--with-zstd="${toolchain_directory}" \
		CFLAGS="${optflags}" \
		CXXFLAGS="${optflags}" \
		LDFLAGS="${linkflags}"
	
	make all --jobs="${max_jobs}"
	make install
	
	cd "$(mktemp --directory)"
	
	declare sysroot_url="https://github.com/AmanoTeam/android-sysroot/releases/latest/download/${triplet}${base_version}.tar.xz"
	declare sysroot_file="${PWD}/${triplet}.tar.xz"
	declare sysroot_directory="${PWD}/${triplet}"
	
	curl \
		--url "${sysroot_url}" \
		--retry '30' \
		--retry-delay '0' \
		--retry-all-errors \
		--retry-max-time '0' \
		--location \
		--silent \
		--output "${sysroot_file}"
	
	tar \
		--extract \
		--file="${sysroot_file}"
	
	mv "${PWD}/${triplet}${base_version}" "${sysroot_directory}"
	
	rm --force --recursive "${toolchain_directory}/${triplet}/include/c++/v1"
	
	echo 'INPUT(-lc)' > "${sysroot_directory}/lib/libpthread.so"
	
	cp --recursive "${sysroot_directory}" "${toolchain_directory}"
	
	rm --force --recursive "${toolchain_directory}/${triplet}/include/c++/v1"
	
	rm --force --recursive ./*
	
	declare specs="$(
		cat <<- specs | tr '\n' ' '
			%{!fno-common:%{!fcommon:-fcommon}}
			%{,c++:%{!fno-rtti:%{!frtti:-frtti}}}
			-Xlinker --undefined-version
		specs
	)"
	
	if [ "${triplet}" = 'aarch64-unknown-linux-android' ] || [ "${triplet}" = 'arm-unknown-linux-androideabi' ]; then
		specs+=' -Xlinker -z -Xlinker max-page-size=16384 -fno-signed-char'
	fi
	
	if [ "${triplet}" = 'aarch64-unknown-linux-android' ]; then
		specs+=' -ffixed-x18'
	fi
	
	if (( is_native )) && [ "${triplet}" = 'riscv64-unknown-linux-android' ]; then
		patch --directory="${toolchain_directory}/${triplet}" --strip='1' --input="${workdir}/patches/0001-Match-the-NDK-sigcontext-struct-with-glibc-s.patch"
	fi
	
	if ! (( is_native )); then
		specs+=' %{!fno-plt:%{!fplt:-fno-plt}}'
	fi
	
	if ! (( is_native )); then
		extra_configure_flags+=" --with-cross-host=${CROSS_COMPILE_TRIPLET}"
		extra_configure_flags+=" --with-toolexeclibdir=${toolchain_directory}/${triplet}/lib/"
	fi
	
	rm "${toolchain_directory}/${triplet}/"{lib,lib64}'/lib'{compiler,stdc++,c++}* || true
	
	[ -d "${gcc_directory}/build" ] || mkdir "${gcc_directory}/build"
	
	cd "${gcc_directory}/build"
	
	rm --force --recursive ./*
	
	../configure \
		--host="${CROSS_COMPILE_TRIPLET}" \
		--target="${triplet}" \
		--prefix="${toolchain_directory}" \
		--with-linker-hash-style='both' \
		--with-gmp="${toolchain_directory}" \
		--with-mpc="${toolchain_directory}" \
		--with-mpfr="${toolchain_directory}" \
		--with-isl="${toolchain_directory}" \
		--with-zstd="${toolchain_directory}" \
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
		--disable-gnu-unique-object \
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
		--enable-libstdcxx-time='yes' \
		--enable-shared \
		--enable-threads='posix' \
		--enable-libstdcxx-threads \
		--enable-libssp \
		--enable-standard-branch-protection \
		--enable-cxx-flags="${linkflags}" \
		--enable-host-pie \
		--enable-host-shared \
		--enable-eh-frame-hdr-for-static \
		--enable-initfini-array \
		--enable-libgomp \
		--enable-libsanitizer \
		--with-specs="${specs}" \
		--disable-tls \
		--disable-fixincludes \
		--disable-libstdcxx-pch \
		--disable-werror \
		--disable-bootstrap \
		--disable-multilib \
		--disable-symvers \
		--without-headers \
		--without-static-standard-libraries \
		${extra_configure_flags} \
		CFLAGS="${optflags}" \
		CXXFLAGS="${optflags}" \
		LDFLAGS="${linkflags}"
	
	declare args=''
	
	if (( is_native )); then
		args+="${environment}"
	fi
	
	env ${args} make \
		CFLAGS_FOR_TARGET="-D __ANDROID_API__=${base_version} ${optflags} ${linkflags}" \
		CXXFLAGS_FOR_TARGET="-fuse-ld=bfd -D __ANDROID_API__=${base_version} ${optflags} ${linkflags}" \
		gcc_cv_objdump="${CROSS_COMPILE_TRIPLET}-objdump" \
		all --jobs="${max_jobs}"
	make install
	
	cp "${workdir}/submodules/obggcc/tools/pkg-config.sh" "${toolchain_directory}/bin/${triplet}-pkg-config"
	sed --in-place 's/OBGGCC/PINO/g' "${toolchain_directory}/bin/${triplet}-pkg-config"
	
	rm "${toolchain_directory}/bin/${triplet}-${triplet}-"* 2>/dev/null || true
	
	if ! (( is_native )); then
		rm "${toolchain_directory}/${triplet}/lib/"*.o
	fi
	
	cd "${toolchain_directory}/lib/bfd-plugins"
	
	if ! [ -f './liblto_plugin.so' ]; then
		ln --symbolic "../../libexec/gcc/${triplet}/"*'/liblto_plugin.so' './'
	fi
	
	cd "${toolchain_directory}/${triplet}/lib64" 2>/dev/null || cd "${toolchain_directory}/${triplet}/lib"
	
	[ -f './libiberty.a' ] && unlink './libiberty.a'
	
	if ! (( is_native )); then
		ln --symbolic './libestdc++.so' './libstdc++.so'
		ln --symbolic './libestdc++.a' './libstdc++.a'
		ln --symbolic './libegcc.so' './libgcc_s.so.1'
	fi
		
	for version in "${versions[@]}"; do
		declare sysroot_url="https://github.com/AmanoTeam/android-sysroot/releases/latest/download/${triplet}${version}.tar.xz"
		declare sysroot_directory="${toolchain_directory}/${triplet}${version}"
		
		if [ "${triplet}" = 'riscv64-unknown-linux-android' ] && [ "${version}" != '35' ]; then
			continue
		fi
		
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
			--directory="${toolchain_directory}" \
			--extract \
			--file="${sysroot_file}"
		
		cd "${sysroot_directory}"
		
		rm --force --recursive './include'
		
		ln --symbolic "../${triplet}/include" './'
		
		cd "${sysroot_directory}/lib"
		
		rm lib{compiler,stdc++,c++}* || true
		
		mkdir 'gcc'
		
		for library in "../../${triplet}/"{lib,lib64}'/lib'*.{so,a,1}; do
			declare name="$(basename "${library}")"
			
			if [[ "${name}" == *'*'* ]]; then
				continue
			fi
			
			if [ -f "${name}" ]; then
				continue
			fi
			
			ln --symbolic "${library}" './'
			ln --symbolic --relative "${library}" './gcc'
		done
		
		cp "${gcc_wrapper}" "${toolchain_directory}/bin/${triplet}${version}-gcc"
		cp "${gcc_wrapper}" "${toolchain_directory}/bin/${triplet}${version}-g++"
		cp "${gcc_wrapper}" "${toolchain_directory}/bin/${triplet}${version}-c++"
		cp "${gcc_wrapper}" "${toolchain_directory}/bin/${triplet}${version}-clang"
		cp "${gcc_wrapper}" "${toolchain_directory}/bin/${triplet}${version}-clang++"
		
		if (( nz )) && [ "${triplet}" != 'riscv64-unknown-linux-android' ]; then
			if (( version > 21 && version < 24 )); then
				ln --symbolic "../../${triplet}21/lib/nouzen" './'
			elif (( version > 24 )); then
				ln --symbolic "../../${triplet}24/lib/nouzen" './'
			else
				mkdir 'nouzen'
				
				cp --recursive "${nz_directory}/"* './nouzen'
				mkdir --parent './nouzen/etc/nouzen/sources.list'
				
				declare repository='https://packages.termux.dev/apt/termux-main/'
				declare release='stable'
				declare resource='main'
				declare architecture=''
				
				if (( version < 24 )); then
					repository='https://packages.termux.dev/termux-main-21/'
				fi
				
				if [ "${triplet}" = 'aarch64-unknown-linux-android' ]; then
					architecture='aarch64'
				elif [ "${triplet}" = 'arm-unknown-linux-androideabi' ]; then
					architecture='arm'
				elif [ "${triplet}" = 'i686-unknown-linux-android' ]; then
					architecture='i686'
				elif [ "${triplet}" = 'x86_64-unknown-linux-android' ]; then
					architecture='x86_64'
				else
					architecture='none'
				fi
				
				echo -e "repository = ${repository}\nrelease = ${release}\nresource = ${resource}\narchitecture = ${architecture}" > './nouzen/etc/nouzen/sources.list/pino.conf'
				
				sed \
					--in-place \
					's|symlink-prefix = none|symlink-prefix = data/data/com.termux/files|g' \
					'./nouzen/etc/nouzen/options.conf'
			fi
		fi
		
		if (( nz )); then
			mkdir '../bin'
			ln --symbolic --relative './nouzen/bin/'* '../bin'
		fi
		
		if (( nz )); then
			ln --symbolic --relative "${toolchain_directory}/${triplet}${version}/bin/nz" "${toolchain_directory}/bin/${triplet}${version}-nz"
			ln --symbolic --relative "${toolchain_directory}/${triplet}${version}/bin/apt" "${toolchain_directory}/bin/${triplet}${version}-apt"
			ln --symbolic --relative "${toolchain_directory}/${triplet}${version}/bin/apt-get" "${toolchain_directory}/bin/${triplet}${version}-apt-get"
		fi
		
		cd "${toolchain_directory}/bin"
		
		for name in "${symlink_tools[@]}"; do
			source="./${triplet}-${name}"
			destination="./${triplet}${version}-${name}"
			
			if ! [ -f "${source}" ]; then
				continue
			fi
			
			echo "- Symlinking '${source}' to '${destination}'"
			
			ln --symbolic "${source}" "${destination}"
		done
	done
done

cp "${gcc_wrapper}" "${toolchain_directory}/bin/clang"
cp "${gcc_wrapper}" "${toolchain_directory}/bin/clang++"

cp "${workdir}/tools/patch_ndk.sh" "${toolchain_directory}/bin/ndk-patch"

# Delete libtool files and other unnecessary files GCC installs
rm --force --recursive "${toolchain_directory}/share"

find \
	"${toolchain_directory}" \
	-name '*.la' -delete -o \
	-name '*.py' -delete -o \
	-name '*.json' -delete

declare cc='gcc'
declare readelf='readelf'

if ! (( is_native )); then
	cc="${CC}"
	readelf="${READELF}"
fi

# Bundle both libstdc++ and libgcc within host tools
if ! (( is_native )); then
	[ -d "${toolchain_directory}/lib" ] || mkdir "${toolchain_directory}/lib"
	
	# libstdc++
	declare name=$(realpath $("${cc}" --print-file-name='libstdc++.so'))
	
	# libestdc++
	if ! [ -f "${name}" ]; then
		declare name=$(realpath $("${cc}" --print-file-name='libestdc++.so'))
	fi
	
	declare soname=$("${readelf}" -d "${name}" | grep 'SONAME' | sed --regexp-extended 's/.+\[(.+)\]/\1/g')
	
	cp "${name}" "${toolchain_directory}/lib/${soname}"
	
	# OpenBSD does not have a libgcc library
	if [[ "${CROSS_COMPILE_TRIPLET}" != *'-openbsd'* ]]; then
		# libgcc_s
		declare name=$(realpath $("${cc}" --print-file-name='libgcc_s.so.1'))
		
		# libegcc
		if ! [ -f "${name}" ]; then
			declare name=$(realpath $("${cc}" --print-file-name='libegcc.so'))
		fi
		
		declare soname=$("${readelf}" -d "${name}" | grep 'SONAME' | sed --regexp-extended 's/.+\[(.+)\]/\1/g')
		
		cp "${name}" "${toolchain_directory}/lib/${soname}"
	fi
fi

mkdir --parent "${share_directory}"

cp --recursive "${workdir}/tools/dev/"* "${share_directory}"


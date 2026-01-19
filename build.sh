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

declare -r iconv_tarball='/tmp/iconv.tar.gz'
declare -r iconv_directory='/tmp/libiconv-1.18'

declare -r binutils_tarball='/tmp/binutils.tar.xz'
declare -r binutils_directory='/tmp/binutils'

declare -r gcc_major='15'

declare gcc_url='https://github.com/gcc-mirror/gcc/archive/master.tar.gz'
declare -r gcc_tarball='/tmp/gcc.tar.xz'
declare gcc_directory='/tmp/gcc-master'

declare -r zlib_tarball='/tmp/zlib.tar.gz'
declare -r zlib_directory='/tmp/zlib-develop'

declare -r zstd_tarball='/tmp/zstd.tar.gz'
declare -r zstd_directory='/tmp/zstd-dev'

declare -r yasm_tarball='/tmp/yasm.tar.gz'
declare -r yasm_directory='/tmp/yasm-1.3.0'

declare -r ninja_tarball='/tmp/ninja.tar.gz'
declare -r ninja_directory='/tmp/ninja-1.12.1'

declare -r nz_directory="${workdir}/submodules/nz"
declare -r nz_prefix='/tmp/nz'

declare -r cxx_bits='/tmp/cxx-bits'
declare -r include_unified_directory="${toolchain_directory}/include/bionic"

declare -r max_jobs='20'

declare -r pieflags='-fPIE'
declare -r ccflags='-w -O2'
declare -r linkflags='-Xlinker -s'

declare -ra targets=(
	'aarch64-unknown-linux-android'
	'armv5-unknown-linux-androideabi'
	'riscv64-unknown-linux-android'
	'mipsel-unknown-linux-android'
	'i686-unknown-linux-android'
	'armv7-unknown-linux-androideabi'
	'x86_64-unknown-linux-android'
	'mips64el-unknown-linux-android'
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

declare -r gcc_wrapper='/tmp/gcc-wrapper'
declare -r binutils_wrapper='/tmp/binutils-wrapper'

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

declare languages='c,c++,fortran,objc,obj-c++'

declare -r PKG_CONFIG_PATH="${toolchain_directory}/lib/pkgconfig"
declare -r PKG_CONFIG_LIBDIR="${PKG_CONFIG_PATH}"
declare -r PKG_CONFIG_SYSROOT_DIR="${toolchain_directory}"

declare -r pkg_cv_ZSTD_CFLAGS="-I${toolchain_directory}/include"
declare -r pkg_cv_ZSTD_LIBS="-L${toolchain_directory}/lib -lzstd"
declare -r ZSTD_CFLAGS="-I${toolchain_directory}/include"
declare -r ZSTD_LIBS="-L${toolchain_directory}/lib -lzstd"

export \
	PKG_CONFIG_PATH \
	PKG_CONFIG_LIBDIR \
	PKG_CONFIG_SYSROOT_DIR \
	pkg_cv_ZSTD_CFLAGS \
	pkg_cv_ZSTD_LIBS \
	ZSTD_CFLAGS \
	ZSTD_LIBS

export \
	ac_cv_header_stdc='yes' \
	ac_cv_header_sys_statvfs_h='no'
	libat_cv_have_ifunc='no'

export MACOSX_DEPLOYMENT_TARGET='11.3'

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
	
	echo -e 'all:\ninstall:' > "${gmp_directory}/tests/Makefile.in"
	echo -e 'all:\ninstall:' > "${gmp_directory}/demos/Makefile.in"
	echo -e 'all:\ninstall:' > "${gmp_directory}/doc/Makefile.in"
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
		--url 'https://deb.debian.org/debian/pool/main/i/isl/isl_0.27.orig.tar.xz' \
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

if ! [ -f "${iconv_tarball}" ]; then
	curl \
		--url 'https://mirrors.kernel.org/gnu/libiconv/libiconv-1.18.tar.gz' \
		--retry '30' \
		--retry-delay '0' \
		--retry-all-errors \
		--retry-max-time '0' \
		--location \
		--silent \
		--output "${iconv_tarball}"
	
	tar \
		--directory="$(dirname "${iconv_directory}")" \
		--extract \
		--file="${iconv_tarball}"
fi

if ! [ -f "${binutils_tarball}" ]; then
	curl \
		--url 'https://github.com/AmanoTeam/binutils-snapshots/releases/latest/download/binutils.tar.xz' \
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
	
	if [[ "${CROSS_COMPILE_TRIPLET}" = *'-darwin'* ]]; then
		sed \
			--in-place \
			's/$$ORIGIN/@loader_path/g' \
			"${workdir}/submodules/obggcc/patches/0001-Add-relative-RPATHs-to-binutils-host-tools.patch"
	fi
	
	if [[ "${CROSS_COMPILE_TRIPLET}" = *'bsd'* ]] || [[ "${CROSS_COMPILE_TRIPLET}" = *'dragonfly' ]] then
		sed \
			--in-place \
			's/-Xlinker -rpath/-Xlinker -z -Xlinker origin -Xlinker -rpath/g' \
			"${workdir}/submodules/obggcc/patches/0001-Add-relative-RPATHs-to-binutils-host-tools.patch"
	fi
	
	patch --directory="${binutils_directory}" --strip='1' --input="${workdir}/submodules/obggcc/patches/0001-Add-relative-RPATHs-to-binutils-host-tools.patch"
	patch --directory="${binutils_directory}" --strip='1' --input="${workdir}/submodules/obggcc/patches/0001-Don-t-warn-about-local-symbols-within-the-globals.patch"
	patch --directory="${binutils_directory}" --strip='1' --input="${workdir}/patches/0001-Fix-assertion-failure-when-linking-code-with-STT_GNU.patch"
fi

if ! [ -f "${zlib_tarball}" ]; then
	curl \
		--url 'https://github.com/madler/zlib/archive/develop.tar.gz' \
		--retry '30' \
		--retry-all-errors \
		--retry-delay '0' \
		--retry-max-time '0' \
		--location \
		--silent \
		--output "${zlib_tarball}"
	
	tar \
		--directory="$(dirname "${zlib_directory}")" \
		--extract \
		--file="${zlib_tarball}"
	
	patch --directory="${zlib_directory}" --strip='1' --input="${workdir}/submodules/obggcc/patches/0001-Remove-versioned-SONAME-from-libz.patch"
fi

if ! [ -f "${zstd_tarball}" ]; then
	curl \
		--url 'https://github.com/facebook/zstd/archive/dev.tar.gz' \
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

if ! [ -f "${yasm_tarball}" ]; then
	curl \
		--url 'https://deb.debian.org/debian/pool/main/y/yasm/yasm_1.3.0.orig.tar.gz' \
		--retry '30' \
		--retry-delay '0' \
		--retry-all-errors \
		--retry-max-time '0' \
		--location \
		--silent \
		--output "${yasm_tarball}"
	
	tar \
		--directory="$(dirname "${yasm_directory}")" \
		--extract \
		--file="${yasm_tarball}"
	
	cd "${yasm_directory}"
	autoreconf --force --install
fi

if ! [ -f "${ninja_tarball}" ]; then
	curl \
		--url 'https://deb.debian.org/debian/pool/main/n/ninja-build/ninja-build_1.12.1.orig.tar.gz' \
		--retry '30' \
		--retry-delay '0' \
		--retry-all-errors \
		--retry-max-time '0' \
		--location \
		--silent \
		--output "${ninja_tarball}"
	
	tar \
		--directory="$(dirname "${ninja_directory}")" \
		--extract \
		--file="${ninja_tarball}"
fi

if ! [ -f "${gcc_tarball}" ]; then
	if [ "${gcc_major}" != '16' ]; then
		gcc_url='https://github.com/gcc-mirror/gcc/archive/releases/gcc-15.tar.gz'
		gcc_directory="/tmp/gcc-releases-gcc-${gcc_major}"
	fi
	
	curl \
		--url "${gcc_url}" \
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
	
	if [[ "${CROSS_COMPILE_TRIPLET}" = *'-darwin'* ]]; then
		sed \
			--in-place \
			's/$$ORIGIN/@loader_path/g' \
			"${workdir}/submodules/obggcc/patches/0007-Add-relative-RPATHs-to-GCC-host-tools.patch"
	fi
	
	if [[ "${CROSS_COMPILE_TRIPLET}" = *'bsd'* ]] || [[ "${CROSS_COMPILE_TRIPLET}" = *'dragonfly' ]] then
		sed \
			--in-place \
			's/-Xlinker -rpath/-Xlinker -z -Xlinker origin -Xlinker -rpath/g' \
			"${workdir}/submodules/obggcc/patches/0007-Add-relative-RPATHs-to-GCC-host-tools.patch"
	fi
	
	patch --directory="${gcc_directory}" --strip='1' --input="${workdir}/patches/0001-GCC-15.patch"
	
	patch --directory="${gcc_directory}" --strip='1' --input="${workdir}/patches/0001-Avoid-relying-on-dynamic-shadow-when-building-libsan.patch"
	patch --directory="${gcc_directory}" --strip='1' --input="${workdir}/patches/0001-Skip-FILE64_FLAGS-for-Android-MIPS-targets.patch"
	patch --directory="${gcc_directory}" --strip='1' --input="${workdir}/patches/0001-Disable-SONAME-versioning-for-all-target-libraries.patch"
	patch --directory="${gcc_directory}" --strip='1' --input="${workdir}/patches/0001-Add-relative-RPATHs-to-GCC-target-libraries.patch" || true
	patch --directory="${gcc_directory}" --strip='1' --input="${workdir}/patches/0001-Change-GCC-s-C-standard-library-name-to-libestdc.patch"
	patch --directory="${gcc_directory}" --strip='1' --input="${workdir}/patches/0001-Rename-GCC-s-libgcc-library-to-libegcc.patch"
	patch --directory="${gcc_directory}" --strip='1' --input="${workdir}/patches/0001-Ignore-pragma-weak-when-the-declaration-is-private-o.patch"
	
	patch --directory="${gcc_directory}" --strip='1' --input="${workdir}/submodules/obggcc/patches/0001-Turn-Wimplicit-function-declaration-back-into-an-warning.patch"
	patch --directory="${gcc_directory}" --strip='1' --input="${workdir}/submodules/obggcc/patches/0002-Fix-libsanitizer-build-on-older-platforms.patch"
	patch --directory="${gcc_directory}" --strip='1' --input="${workdir}/submodules/obggcc/patches/0003-Change-the-default-language-version-for-C-compilation-from-std-gnu23-to-std-gnu17.patch"
	
	if [ "${gcc_major}" = '16' ]; then
		patch --directory="${gcc_directory}" --strip='1' --input="${workdir}/submodules/obggcc/patches/0004-Turn-Wimplicit-int-back-into-an-warning.patch"
	else
		patch --directory="${gcc_directory}" --strip='1' --input="${workdir}/submodules/obggcc/patches/gcc-15/0004-Turn-Wimplicit-int-back-into-an-warning.patch"
	fi
	
	patch --directory="${gcc_directory}" --strip='1' --input="${workdir}/submodules/obggcc/patches/0005-Turn-Wint-conversion-back-into-an-warning.patch"
	
	if [ "${gcc_major}" = '16' ]; then
		patch --directory="${gcc_directory}" --strip='1' --input="${workdir}/submodules/obggcc/patches/0006-Turn-Wincompatible-pointer-types-back-into-an-warning.patch"
	else
		patch --directory="${gcc_directory}" --strip='1' --input="${workdir}/submodules/obggcc/patches/gcc-15/0006-Turn-Wincompatible-pointer-types-back-into-an-warning.patch"
	fi
	
	patch --directory="${gcc_directory}" --strip='1' --input="${workdir}/submodules/obggcc/patches/0007-Add-relative-RPATHs-to-GCC-host-tools.patch"
	
	if [ "${gcc_major}" = '16' ]; then
		patch --directory="${gcc_directory}" --strip='1' --input="${workdir}/submodules/obggcc/patches/0011-Revert-configure-Always-add-pre-installed-header-directories-to-search-path.patch"
		patch --directory="${gcc_directory}" --strip='1' --input="${workdir}/submodules/obggcc/patches/0001-Revert-x86-Fixes-for-AMD-znver5-enablement.patch"
	fi
	
	patch --directory="${gcc_directory}" --strip='1' --input="${workdir}/submodules/obggcc/patches/0001-AArch64-enable-libquadmath.patch"
	
	if [ "${gcc_major}" = '15' ]; then
		patch --directory="${gcc_directory}" --strip='1' --input="${workdir}/submodules/obggcc/patches/gcc-15/0001-Enable-automatic-linking-of-libatomic.patch"
		patch --directory="${gcc_directory}" --strip='1' --input="${workdir}/submodules/obggcc/patches/gcc-15/0001-Use-latomic_asneeded-or-lgcc_s_asneeded-to-workaround-libtool-issues-PR123396.patch"
	fi
	
	patch --directory="${gcc_directory}" --strip='1' --input="${workdir}/submodules/obggcc/patches/0001-Enable-automatic-linking-of-libiconv.patch"
	patch --directory="${gcc_directory}" --strip='1' --input="${workdir}/submodules/obggcc/patches/0001-Disable-FDSan-File-Descriptor-Sanitizer-for-the-GCOBOL-compiler-on-Android.patch"
	patch --directory="${gcc_directory}" --strip='1' --input="${workdir}/submodules/obggcc/patches/0001-Prevent-libstdc-from-trying-to-implement-math-stubs.patch"
fi

# Follow Debian's approach to remove hardcoded RPATHs from binaries
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

# Avoid using absolute hardcoded install_name values on macOS
sed \
	--in-place \
	's|-install_name \\$rpath/\\$soname|-install_name @rpath/\\$soname|g' \
	"${isl_directory}/configure" \
	"${mpc_directory}/configure" \
	"${mpfr_directory}/configure" \
	"${gmp_directory}/configure"

# Force GCC and binutils to prefix host tools with the target triplet even in native builds
sed \
	--in-place \
	's/test "$host_noncanonical" = "$target_noncanonical"/false/' \
	"${gcc_directory}/configure" \
	"${binutils_directory}/configure"

declare disable_assembly='--disable-assembly'

if [[ "${CROSS_COMPILE_TRIPLET}" != 'mips64el-'* ]]; then
	disable_assembly=''
fi

[ -d "${gmp_directory}/build" ] || mkdir "${gmp_directory}/build"

cd "${gmp_directory}/build"

../configure \
	--host="${CROSS_COMPILE_TRIPLET}" \
	--prefix="${toolchain_directory}" \
	--enable-shared \
	--disable-static \
	${disable_assembly} \
	CFLAGS="${ccflags}" \
	CXXFLAGS="${ccflags}" \
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
	CFLAGS="${ccflags} -DMPFR_LCONV_DPTS=0" \
	CXXFLAGS="${ccflags}" \
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
	CFLAGS="${ccflags}" \
	CXXFLAGS="${ccflags}" \
	LDFLAGS="${linkflags}"

make all --jobs
make install

[ -d "${isl_directory}/build" ] || mkdir "${isl_directory}/build"

cd "${isl_directory}/build"
rm --force --recursive ./*

declare isl_ldflags=''

if [[ "${CROSS_COMPILE_TRIPLET}" != *'-darwin'* ]]; then
	isl_ldflags+=" -Xlinker -rpath-link -Xlinker ${toolchain_directory}/lib"
fi

../configure \
	--host="${CROSS_COMPILE_TRIPLET}" \
	--prefix="${toolchain_directory}" \
	--with-gmp-prefix="${toolchain_directory}" \
	--enable-shared \
	--disable-static \
	--with-pic \
	CFLAGS="${ccflags}" \
	CXXFLAGS="${ccflags}" \
	LDFLAGS="${linkflags} ${isl_ldflags}"

make all --jobs
make install

[ -d "${zlib_directory}/build" ] || mkdir "${zlib_directory}/build"

cd "${zlib_directory}/build"
rm --force --recursive ./*

../configure \
	--host="${CROSS_COMPILE_TRIPLET}" \
	--prefix="${toolchain_directory}" \
	CFLAGS="${ccflags}" \
	CXXFLAGS="${ccflags}" \
	LDFLAGS="${linkflags}"

make all --jobs
make install

[ -d "${yasm_directory}/build" ] || mkdir "${yasm_directory}/build"

cd "${yasm_directory}/build"

../configure \
	--host="${CROSS_COMPILE_TRIPLET}" \
	--prefix="${toolchain_directory}" \
	--enable-shared \
	--disable-static \
	CFLAGS="${ccflags}" \
	CXXFLAGS="${ccflags}" \
	LDFLAGS="${linkflags}"

make all --jobs
make install

unlink "${toolchain_directory}/lib/libz.a"

[ -d "${zstd_directory}/.build" ] || mkdir "${zstd_directory}/.build"

cd "${zstd_directory}/.build"
rm --force --recursive ./*

cmake \
	-S "${zstd_directory}/build/cmake" \
	-B "${PWD}" \
	-DCMAKE_C_FLAGS="-DZDICT_QSORT=ZDICT_QSORT_MIN ${ccflags}" \
	-DCMAKE_INSTALL_PREFIX="${toolchain_directory}" \
	-DBUILD_SHARED_LIBS=ON \
	-DZSTD_BUILD_PROGRAMS=OFF \
	-DZSTD_BUILD_TESTS=OFF \
	-DZSTD_BUILD_STATIC=OFF \
	-DCMAKE_PLATFORM_NO_VERSIONED_SONAME=ON

cmake --build "${PWD}"
cmake --install "${PWD}" --strip

[ -d "${ninja_directory}/build" ] || mkdir "${ninja_directory}/build"

cd "${ninja_directory}/build"
rm --force --recursive ./*

cmake \
	-S "${ninja_directory}" \
	-B "${PWD}" \
	-DBUILD_TESTING='OFF' \
	-DCMAKE_POLICY_VERSION_MINIMUM='3.5' \
	-DCMAKE_INSTALL_PREFIX="${toolchain_directory}" \
	-DCMAKE_INSTALL_RPATH='$ORIGIN/../lib'

if [[ "${CROSS_COMPILE_TRIPLET}" != *'-android'* ]]; then
	cmake --build "${PWD}"
	cmake --install "${PWD}" --strip
fi

[ -d "${nz_directory}/build" ] || mkdir "${nz_directory}/build"

cd "${nz_directory}/build"
rm --force --recursive ./*

cmake \
	-S "${nz_directory}" \
	-B "${PWD}" \
	-DCMAKE_C_FLAGS="${ccflags}" \
	-DCMAKE_CXX_FLAGS="${ccflags}" \
	-DCMAKE_INSTALL_PREFIX="${nz_prefix}"

cmake --build "${PWD}" -- --jobs='1'
cmake --install "${PWD}" --strip

mkdir --parent "${toolchain_directory}/lib/nouzen"
mv "${nz_prefix}/lib/"* "${toolchain_directory}/lib/nouzen"
rmdir "${nz_prefix}/lib"

declare cc='gcc'

if ! (( is_native )); then
	cc="${CC}"
fi

sed \
	--in-place \
	--regexp-extended \
	"s/(GCC_MAJOR_VERSION\[\] = )\"[0-9]+\"/\1\"${gcc_major}\"/g" \
	"${workdir}/submodules/obggcc/tools/gcc-wrapper/gcc.c"

sed \
	--in-place \
	--regexp-extended \
	's/description = .*/description = "A GCC cross-compiler targeting Android",/' \
	"${workdir}/submodules/obggcc/tools/program-help.h.py"

sed \
	--in-place \
	's/--obggcc/--pino/' \
	"${workdir}/submodules/obggcc/tools/gcc-wrapper/obggcc.h"

make \
	-C "${workdir}/submodules/obggcc/tools/gcc-wrapper" \
	PREFIX="$(dirname "${gcc_wrapper}")" \
	CFLAGS="${ccflags}" \
	CXXFLAGS="${ccflags}" \
	LDFLAGS="${linkflags}" \
	FLAVOR='PINO' \
	all

# We prefer symbolic links over hard links.
cp "${workdir}/submodules/obggcc/tools/ln.sh" '/tmp/ln'

export PATH="/tmp:${PATH}"

if [[ "${CROSS_COMPILE_TRIPLET}" = 'arm'*'-android'* ]] || [[ "${CROSS_COMPILE_TRIPLET}" = 'i686-'*'-android'* ]] || [[ "${CROSS_COMPILE_TRIPLET}" = 'mipsel-'*'-android'* ]]; then
	export \
		ac_cv_func_fseeko='no' \
		ac_cv_func_ftello='no'
fi

if [[ "${CROSS_COMPILE_TRIPLET}" = 'armv5'*'-android'* ]]; then
	export PINO_ARM_MODE='true'
fi

if [[ "${CROSS_COMPILE_TRIPLET}" = *'-haiku' ]]; then
	export ac_cv_c_bigendian='no'
fi

if [ "${gcc_major}" = '15' ]; then
	if (( is_native )) || [[ "${CROSS_COMPILE_TRIPLET}" = *'-linux'* ]] || [[ "${CROSS_COMPILE_TRIPLET}" = *'-freebsd' ]]; then
		languages+=',cobol'
	fi
fi

for triplet in "${targets[@]}"; do
	declare extra_configure_flags=''
	declare extra_binutils_flags=''
	declare base_version='14'
	declare abi64='0'
	declare hash_style='both'
	
	enable_libsanitizer='--enable-libsanitizer'
	enable_libgcobol=''
	
	if [[ "${languages}" = *'cobol'* ]] && (( is_native )); then
		enable_libgcobol='--disable-libgcobol'
	fi
	
	if [ "${triplet}" = 'riscv64-unknown-linux-android' ] || [ "${triplet}" = 'aarch64-unknown-linux-android' ] || [ "${triplet}" = 'x86_64-unknown-linux-android' ] || [ "${triplet}" = 'mips64el-unknown-linux-android' ]; then
		abi64='1'
	fi
	
	if [ "${triplet}" = 'riscv64-unknown-linux-android' ]; then
		base_version='35'
	fi
	
	if [ "${triplet}" = 'aarch64-unknown-linux-android' ] || [ "${triplet}" = 'x86_64-unknown-linux-android' ] || [ "${triplet}" = 'mips64el-unknown-linux-android' ]; then
		base_version='21'
	fi
	
	if [ "${triplet}" = 'mipsel-unknown-linux-android' ] || [ "${triplet}" = 'mips64el-unknown-linux-android' ]; then
		hash_style='sysv'
	fi
	
	if [ "${triplet}" = 'armv7-unknown-linux-androideabi' ]; then
		extra_configure_flags+=' --with-arch=armv7-a --with-float=softfp --with-fpu=vfpv3-d16 --with-mode=thumb'
	elif [ "${triplet}" = 'armv5-unknown-linux-androideabi' ]; then
		extra_configure_flags+=' --with-arch=armv5te --with-tune=xscale --with-float=soft --with-fpu=vfpv2 --with-mode=thumb'
	elif [ "${triplet}" = 'aarch64-unknown-linux-android' ]; then
		extra_configure_flags+=' --enable-fix-cortex-a53-835769 --enable-fix-cortex-a53-843419'
	elif [ "${triplet}" = 'i686-unknown-linux-android' ]; then
		extra_configure_flags+=' --with-arch=i686 --with-tune=intel --with-fpmath=sse'
	elif [ "${triplet}" = 'x86_64-unknown-linux-android' ]; then
		extra_configure_flags+=' --with-arch=x86-64 --with-tune=intel --with-fpmath=sse'
	elif [ "${triplet}" = 'riscv64-unknown-linux-android' ]; then
		extra_configure_flags+=' --with-arch=rv64gc --with-abi=lp64d'
	elif [ "${triplet}" = 'mipsel-unknown-linux-android' ]; then
		extra_configure_flags+=' --with-arch=mips32r2 --with-abi=32 --with-float=hard --with-llsc --without-synci --with-nan=legacy'
	elif [ "${triplet}" = 'mips64el-unknown-linux-android' ]; then
		extra_configure_flags+=' --with-arch=mips64r6 --with-abi=64 --with-float=hard --with-llsc --with-synci --with-nan=2008'
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
		--enable-compressed-debug-sections='all' \
		--enable-default-compressed-debug-sections-algorithm='zstd' \
		--disable-gprofng \
		--without-static-standard-libraries \
		--with-sysroot="${toolchain_directory}/${triplet}" \
		--with-zstd="${toolchain_directory}" \
		--with-system-zlib \
		${extra_binutils_flags} \
		CFLAGS="-I${toolchain_directory}/include ${ccflags}" \
		CXXFLAGS="-I${toolchain_directory}/include ${ccflags}" \
		LDFLAGS="-L${toolchain_directory}/lib ${linkflags}"
	
	make all --jobs="${max_jobs}"
	make install
	
	cd "$(mktemp --directory)"
	
	declare sysroot_url="https://github.com/AmanoTeam/android-sysroot/releases/latest/download/${triplet}${base_version}.tar.xz"
	declare tarball="${PWD}/${triplet}.tar.xz"
	declare sysroot_directory="${PWD}/${triplet}"
	
	echo "Fetching system root from '${sysroot_url}'"
	
	curl \
		--url "${sysroot_url}" \
		--retry '30' \
		--retry-delay '0' \
		--retry-all-errors \
		--retry-max-time '0' \
		--location \
		--silent \
		--output "${tarball}"
	
	tar \
		--extract \
		--file="${tarball}"
	
	mv "${PWD}/${triplet}${base_version}" "${sysroot_directory}"
	
	echo 'INPUT(-lc)' > "${sysroot_directory}/lib/libpthread.so"
	
	mkdir --parent "${sysroot_directory}/lib/ldscripts"
	
	echo 'GROUP ( ../libm.so AS_NEEDED ( ../libm.a ) )' > "${sysroot_directory}/lib/ldscripts/libm.so"
	echo 'GROUP ( ../libc.so AS_NEEDED ( ../libc.a ) )' > "${sysroot_directory}/lib/ldscripts/libc.so"
	
	touch "${sysroot_directory}/lib/libiconv.so"
	touch "${sysroot_directory}/lib/libcharset.so"
	touch "${sysroot_directory}/lib/libc.a"
	
	cp "${workdir}/submodules/libpino/complex.h" "${sysroot_directory}/include/pino_complex.h"
	cp "${workdir}/submodules/libpino/math.h" "${sysroot_directory}/include/pino_math.h"
	
	cp --recursive "${sysroot_directory}" "${toolchain_directory}"
	
	rm --force --recursive ./*
	
	declare specs=''
	
	specs+=' %{!Wno-complain-wrong-lang: %{!Wcomplain-wrong-lang: -Wno-complain-wrong-lang}}'
	specs+=' %{!Wno-psabi: %{!Wpsabi: -Wno-psabi}}'
	specs+=' %{!Qy: -Qn}'
	
	specs="$(xargs <<< "${specs}")"
	
	if ! (( is_native )); then
		extra_configure_flags+=" --with-cross-host=${CROSS_COMPILE_TRIPLET}"
		extra_configure_flags+=" --with-toolexeclibdir=${toolchain_directory}/${triplet}/lib/"
	fi
	
	if [[ "${CROSS_COMPILE_TRIPLET}" != *'-darwin'* ]]; then
		extra_configure_flags+=' --enable-host-bind-now'
	fi
	
	if [[ "${triplet}" = 'armv5-'* ]]; then
		enable_libsanitizer='--disable-libsanitizer'
	fi
	
	[ -d "${gcc_directory}/build" ] || mkdir "${gcc_directory}/build"
	
	cd "${gcc_directory}/build"
	
	rm --force --recursive ./*
	
	../configure \
		--host="${CROSS_COMPILE_TRIPLET}" \
		--target="${triplet}" \
		--prefix="${toolchain_directory}" \
		--with-linker-hash-style="${hash_style}" \
		--with-gmp="${toolchain_directory}" \
		--with-mpc="${toolchain_directory}" \
		--with-mpfr="${toolchain_directory}" \
		--with-isl="${toolchain_directory}" \
		--with-zstd="${toolchain_directory}" \
		--with-system-zlib \
		--with-gcc-major-version-only \
		--with-sysroot="${toolchain_directory}/${triplet}" \
		--with-android-version-min="${base_version}" \
		--with-native-system-header-dir='/include' \
		--with-default-libstdcxx-abi='new' \
		--with-pic \
		--with-specs="${specs}" \
		--with-gnu-ld \
		--with-gnu-as \
		--includedir="${toolchain_directory}/${triplet}/include" \
		--enable-clocale='gnu' \
		--enable-__cxa_atexit \
		--enable-cet='auto' \
		--enable-checking='release' \
		--enable-default-ssp \
		--enable-gnu-indirect-function \
		--enable-languages="${languages}" \
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
		--enable-cxx-flags="${linkflags}" \
		--enable-host-pie \
		--enable-host-shared \
		--enable-initfini-array \
		--enable-libgomp \
		--enable-autolink-libiconv \
		${enable_libsanitizer} \
		${enable_libgcobol} \
		--disable-gnu-unique-object \
		--disable-libstdcxx-verbose \
		--disable-frame-pointer \
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
		LDFLAGS="-L${toolchain_directory}/lib ${linkflags}"
	
	declare args=''
	
	if (( is_native )); then
		args+="${environment}"
	fi
	
	declare target_cflags="${ccflags/-O2/} ${linkflags} -L${toolchain_directory}/${triplet}/lib/ldscripts"
	declare target_cxxflags="${target_cflags} -D_ABIN32=2"
	
	env ${args} make \
		CFLAGS_FOR_TARGET="${target_cflags}" \
		CXXFLAGS_FOR_TARGET="${target_cxxflags}" \
		LDFLAGS_FOR_TARGET="${linkflags}" \
		gcc_cv_objdump="${CROSS_COMPILE_TRIPLET}-objdump" \
		all --jobs="${max_jobs}"
	env ${args} make install
	
	if [[ "${languages}" = *'cobol'* ]]; then
		sed \
			--in-place \
			"s|/gcobol}|/${triplet}-gcobol}|g" \
			"${toolchain_directory}/bin/${triplet}-gcobc"
	fi
	
	cp "${workdir}/submodules/obggcc/tools/pkg-config.sh" "${toolchain_directory}/bin/${triplet}-pkg-config"
	sed --in-place 's/OBGGCC/PINO/g' "${toolchain_directory}/bin/${triplet}-pkg-config"
	
	rm "${toolchain_directory}/bin/${triplet}-${triplet}-"* 2>/dev/null || true
	
	cd "${toolchain_directory}/lib/bfd-plugins"
	
	if ! [ -f './liblto_plugin.so' ]; then
		ln --symbolic "../../libexec/gcc/${triplet}/"*'/liblto_plugin.so' './'
	fi
	
	cd "${toolchain_directory}/${triplet}/lib64" 2>/dev/null || cd "${toolchain_directory}/${triplet}/lib"
	
	if [[ "$(basename "${PWD}")" = 'lib64' ]]; then
		mv ./* '../lib' || true
		rmdir "${PWD}"
		cd '../lib'
	fi
	
	[ -f './libiberty.a' ] && unlink './libiberty.a'
	
	echo 'INPUT(-lestdc++)' > './libstdc++.so'
	echo 'INPUT(-lestdc++-static)' > './libstdc++.a'
	echo 'INPUT(-legcc)' > './libgcc_s.so.1'
	
	echo 'INPUT (-lgcc -lgcc_eh)' > './libunwind.a'
	echo 'INPUT (-lgcc_s -lgcc_eh)' > './libunwind.so'
	
	if ! [ -d "${include_unified_directory}" ]; then
		cp --recursive "${toolchain_directory}/${triplet}/include" "${include_unified_directory}"
		rm --force --recursive "${include_unified_directory}/asm"*
		rm --force --recursive "${include_unified_directory}/c++/${gcc_major}/${triplet}"*
	fi
	
	declare cxx_directory="${toolchain_directory}/${triplet}/include/c++/${gcc_major}"
	
	rm --force --recursive "${cxx_bits}"
	mv "${cxx_directory}/${triplet}" "${cxx_bits}"
	
	for name in "${toolchain_directory}/${triplet}/include/"*; do
		if [[ "${name}" = *'/asm'* ]]; then
			continue
		fi
		
		rm --force --recursive "${name}"
	done
	
	for name in "${include_unified_directory}/"*; do
		if [[ "${name}" = *'/c++' ]]; then
			mkdir --parent "${cxx_directory}"
			mv "${cxx_bits}/"* "${cxx_directory}"
			
			for subname in "${name}/${gcc_major}/"*; do
				if [[ "${subname}" = *'/ext' ]]; then
					ln --symbolic --relative "${subname}/"* "${cxx_directory}/ext"
				elif [[ "${subname}" = *'/bits' ]]; then
					ln --symbolic --relative "${subname}/"* "${cxx_directory}/bits"
				else
					ln --symbolic --relative "${subname}" "${cxx_directory}"
				fi
			done
		else
			ln --symbolic --relative "${name}" "${toolchain_directory}/${triplet}/include"
		fi
	done
	
	args=''
	bindir=''
	
	if (( is_native )); then
		bindir="${toolchain_directory}/bin/"
	fi
	
	args+="CC=${bindir}${triplet}-gcc "
	args+="CXX=${bindir}${triplet}-g++ "
	args+="AR=${bindir}${triplet}-ar "
	args+="AS=${bindir}${triplet}-as "
	args+="LD=${bindir}${triplet}-ld "
	args+="NM=${bindir}${triplet}-nm "
	args+="RANLIB=${bindir}${triplet}-ranlib "
	args+="STRIP=${bindir}${triplet}-strip "
	args+="OBJCOPY=${bindir}${triplet}-objcopy "
	args+="READELF=${bindir}${triplet}-readelf "
	
	[ -d "${iconv_directory}/build" ] || mkdir "${iconv_directory}/build"
	
	cd "${iconv_directory}/build"
	
	rm --force --recursive ./*
	
	env ${args} ../configure \
		--host="${triplet}" \
		--prefix="${toolchain_directory}/${triplet}" \
		--enable-static \
		--enable-shared \
		--enable-extra-encodings \
		CFLAGS="${ccflags}" \
		CXXFLAGS="${ccflags}" \
		LDFLAGS="${linkflags}"
	
	make all --jobs
	make install
	
	rm --force --recursive "${toolchain_directory}/${triplet}/share"
	
	if ! (( is_native )); then
		mv "${toolchain_directory}/${triplet}/include/iconv.h" "${include_unified_directory}"
		mv "${toolchain_directory}/${triplet}/include/libcharset.h" "${include_unified_directory}"
		mv "${toolchain_directory}/${triplet}/include/localcharset.h" "${include_unified_directory}"
	fi
	
	for version in "${versions[@]}"; do
		declare sysroot_url="https://github.com/AmanoTeam/android-sysroot/releases/latest/download/${triplet}${version}.tar.xz"
		declare sysroot_directory="${toolchain_directory}/${triplet}${version}"
		
		echo "Fetching system root from '${sysroot_url}'"
		
		curl \
			--url "${sysroot_url}" \
			--retry '30' \
			--retry-all-errors \
			--retry-delay '0' \
			--retry-max-time '0' \
			--location \
			--silent \
			--output "${tarball}"
		
		tar \
			--directory="${toolchain_directory}" \
			--extract \
			--file="${tarball}" 2>/dev/null || continue
		
		cd "${sysroot_directory}"
		
		rm --force --recursive './include'
		
		mkdir './lib/ldscripts'
		
		ln --symbolic --relative "${toolchain_directory}/${triplet}/include" './'
		ln --symbolic --relative "${toolchain_directory}/${triplet}/lib/ldscripts/"* './lib/ldscripts'
		
		cd "${sysroot_directory}/lib"
		
		rm --force './ldscripts/libm.so'
		echo 'GROUP ( ../libm.so AS_NEEDED ( ../libm.a ) )' > './ldscripts/libm.so'
		
		rm --force './ldscripts/libc.so'
		[ -f './libc.a' ] && echo 'GROUP ( ../libc.so AS_NEEDED ( ../libc.a ) )' > './ldscripts/libc.so'
		
		mkdir 'gcc' 'static'
		
		ln --symbolic --relative './lib'*'.'{so,a} './static'
		ln --symbolic --relative './crt'*'.o' './static'
		ln --symbolic --relative './ldscripts' './static'
		
		for library in "../../${triplet}/lib/lib"*.{so,a,1,spec}; do
			declare name="$(basename "${library}")"
			
			if [[ "${name}" = *'*'* ]]; then
				continue
			fi
			
			if [ -f "${name}" ]; then
				continue
			fi
			
			if [[ "${name}" = *'.a' ]]; then
				libname="$(basename "${name}" '.a')"
				
				declare static="./${libname}-static.a"
				declare shared="./${libname}.so"
				
				if [ -f "${shared}" ] && ! [ -f "${static}" ]; then
					ln --symbolic "${library}" "${static}"
				fi
				
				ln --symbolic --relative "${library}" './static'
			elif [[ "${name}" = 'libgcc_s.so'* ]] || [[ "${name}" = 'libegcc.so'* ]]; then
				ln --symbolic --relative "${library}" './static'
			fi
			
			ln --symbolic "${library}" './'
			ln --symbolic --relative "${library}" './gcc'
		done
		
		cp "${gcc_wrapper}" "${toolchain_directory}/bin/${triplet}${version}-gcc"
		cp "${gcc_wrapper}" "${toolchain_directory}/bin/${triplet}${version}-g++"
		cp "${gcc_wrapper}" "${toolchain_directory}/bin/${triplet}${version}-c++"
		cp "${gcc_wrapper}" "${toolchain_directory}/bin/${triplet}${version}-clang"
		cp "${gcc_wrapper}" "${toolchain_directory}/bin/${triplet}${version}-clang++"
		cp "${gcc_wrapper}" "${toolchain_directory}/bin/${triplet}${version}-gfortran"
		cp "${gcc_wrapper}" "${toolchain_directory}/bin/${triplet}${version}-gcobc"
		cp "${gcc_wrapper}" "${toolchain_directory}/bin/${triplet}${version}-gcobol"
		
		declare termux='1'
		
		[ "${triplet}" = 'riscv64-unknown-linux-android' ] && termux='0'
		[ "${triplet}" = 'mipsel-unknown-linux-android' ] && termux='0'
		[ "${triplet}" = 'mips64el-unknown-linux-android' ] && termux='0'
		[ "${triplet}" = 'armv5-unknown-linux-androideabi' ] && termux='0'
		
		status='0'
		
		(( termux && version >= 21 )) && status='1'
		
		if (( status )); then
			if (( version > 21 && version < 24 )); then
				ln --symbolic "../../${triplet}21/lib/nouzen" './'
			elif (( version > 24 )); then
				ln --symbolic "../../${triplet}24/lib/nouzen" './'
			else
				mkdir 'nouzen'
				
				cp --recursive "${nz_prefix}/"* "${PWD}/nouzen"
				
				mkdir \
					--parent \
					"${PWD}/nouzen/lib" \
					"${PWD}/nouzen/etc/nouzen/sources.list"
				
				ln \
					--symbolic \
					--relative \
					"${toolchain_directory}/lib/nouzen/lib"* \
					"${PWD}/nouzen/lib"
				
				declare repository='https://packages.termux.dev/apt/termux-main/'
				declare release='stable'
				declare resource='main'
				declare architecture=''
				
				if (( version < 24 )); then
					repository='https://packages.termux.dev/termux-main-21/'
				fi
				
				if [ "${triplet}" = 'aarch64-unknown-linux-android' ]; then
					architecture='aarch64'
				elif [ "${triplet}" = 'armv7-unknown-linux-androideabi' ]; then
					architecture='arm'
				elif [ "${triplet}" = 'i686-unknown-linux-android' ]; then
					architecture='i686'
				elif [ "${triplet}" = 'x86_64-unknown-linux-android' ]; then
					architecture='x86_64'
				else
					architecture='none'
				fi
				
				cp "${nz_directory}/options.conf" "${PWD}/nouzen/etc/nouzen"
				
				echo -e "repository = ${repository}\nrelease = ${release}\nresource = ${resource}\narchitecture = ${architecture}" > './nouzen/etc/nouzen/sources.list/pino.conf'
				
				sed \
					--in-place \
					's|symlink-prefix = none|symlink-prefix = data/data/com.termux/files|g' \
					"${PWD}/nouzen/etc/nouzen/options.conf"
			fi
		fi
		
		if (( status )); then
			mkdir '../bin'
			ln --symbolic --relative './nouzen/bin/'* '../bin'
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

cp "${workdir}/submodules/obggcc/tools/update-gcc-wrapper.sh" "${toolchain_directory}/bin/update-wrapper"
sed --in-place 's/OBGGCC/PINO/g' "${toolchain_directory}/bin/update-wrapper"

cp "${gcc_wrapper}" "${toolchain_directory}/bin/clang"
cp "${gcc_wrapper}" "${toolchain_directory}/bin/clang++"
cp "${binutils_wrapper}" "${toolchain_directory}/bin/llvm-strip"
cp "${binutils_wrapper}" "${toolchain_directory}/bin/llvm-objcopy"

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
if ! (( is_native )) && [[ "${CROSS_COMPILE_TRIPLET}" != *'-darwin'* ]]; then
	[ -d "${toolchain_directory}/lib" ] || mkdir "${toolchain_directory}/lib"
	
	# libestdc++
	declare name=$(realpath $("${cc}" --print-file-name='libestdc++.so'))
	
	# libstdc++
	if ! [ -f "${name}" ]; then
		declare name=$(realpath $("${cc}" --print-file-name='libstdc++.so'))
	fi
	
	declare soname=$("${readelf}" -d "${name}" | grep 'SONAME' | sed --regexp-extended 's/.+\[(.+)\]/\1/g')
	
	cp "${name}" "${toolchain_directory}/lib/${soname}"
	
	ln \
		--symbolic \
		--relative \
		"${toolchain_directory}/lib/${soname}" \
		"${toolchain_directory}/lib/nouzen"
	
	# libegcc
	declare name=$(realpath $("${cc}" --print-file-name='libegcc.so'))
	
	if ! [ -f "${name}" ]; then
		# libgcc_s
		declare name=$(realpath $("${cc}" --print-file-name='libgcc_s.so.1'))
	fi
	
	declare soname=$("${readelf}" -d "${name}" | grep 'SONAME' | sed --regexp-extended 's/.+\[(.+)\]/\1/g')
	
	cp "${name}" "${toolchain_directory}/lib/${soname}"
	
	ln \
		--symbolic \
		--relative \
		"${toolchain_directory}/lib/${soname}" \
		"${toolchain_directory}/lib/nouzen"
	
	# libatomic
	declare name=$(realpath $("${cc}" --print-file-name='libatomic.so'))
	
	declare soname=$("${readelf}" -d "${name}" | grep 'SONAME' | sed --regexp-extended 's/.+\[(.+)\]/\1/g')
	
	cp "${name}" "${toolchain_directory}/lib/${soname}"
	
	ln \
		--symbolic \
		--relative \
		"${toolchain_directory}/lib/${soname}" \
		"${toolchain_directory}/lib/nouzen"
	
	# libiconv
	declare name=$(realpath $("${cc}" --print-file-name='libiconv.so'))
	
	if [ -f "${name}" ]; then
		declare soname=$("${readelf}" -d "${name}" | grep 'SONAME' | sed --regexp-extended 's/.+\[(.+)\]/\1/g')
		cp "${name}" "${toolchain_directory}/lib/${soname}"
		
		ln \
			--symbolic \
			--relative \
			"${toolchain_directory}/lib/${soname}" \
			"${toolchain_directory}/lib/nouzen"
	fi
	
	# libcharset
	declare name=$(realpath $("${cc}" --print-file-name='libcharset.so'))
	
	if [ -f "${name}" ]; then
		declare soname=$("${readelf}" -d "${name}" | grep 'SONAME' | sed --regexp-extended 's/.+\[(.+)\]/\1/g')
		cp "${name}" "${toolchain_directory}/lib/${soname}"
		
		ln \
			--symbolic \
			--relative \
			"${toolchain_directory}/lib/${soname}" \
			"${toolchain_directory}/lib/nouzen"
	fi
	
	for source in "${toolchain_directory}/lib/"{atomic,*gcc*,*stdc++,charset,iconv}.*; do
		if ! [ -f "${source}" ]; then
			continue
		fi
		
		for destination in "${toolchain_directory}/"*'-unknown-linux-android'*'/lib/nouzen/lib'; do
			echo "- Symlinking '${source}' to '${destination}'"
		
			ln \
				--symbolic \
				--relative \
				"${source}" \
				"${destination}" 2>/dev/null || true
		done
	done
fi

mkdir --parent "${share_directory}"

cp --recursive "${workdir}/tools/dev/"* "${share_directory}"

[ -d "${toolchain_directory}/build" ] || mkdir "${toolchain_directory}/build"

ln \
	--symbolic \
	--relative \
	"${share_directory}/"* \
	"${toolchain_directory}/build"

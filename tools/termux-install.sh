#!/data/data/com.termux/files/usr/bin/bash

set -eu

declare abi="$(uname -m)"
declare api_level='-1'

declare max_api_level='35'

declare triplet='none'
declare bindir="${PREFIX}/bin"

declare pino_tarball="${TMPDIR}/pino.tar.xz"
declare pino_directory="${HOME}/.local/pino"

declare wrapper="$(
	cat <<- text
		#!/data/data/com.termux/files/usr/bin/bash
		
		export PINO_RUNTIME_RPATH='true'
		export PINO_NEON='true'
		
		export PINO_SYSTEM_PREFIX=\"\$(dirname \"\${PREFIX}\")\"
		export PINO_SYSTEM_LIBRARIES='true'
		
		export LD_LIBRARY_PATH=\"%s:\${LD_LIBRARY_PATH}\"
		
		eval '%s' \${@}
	text
)"

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

[ -f '/system/bin/getprop' ] && api_level="$(getprop 'ro.build.version.sdk')"

if [ "${api_level}" = '-1' ]; then
	# We are probably running inside termux-docker; assume API level 24
	api_level='24'
fi

case "${abi}" in
	aarch64)
		triplet='aarch64-unknown-linux-android'
		;;
	armv7l)
		triplet='armv7-unknown-linux-androideabi'
		;;
	i686)
		triplet='i686-unknown-linux-android'
		;;
	x86_64)
		triplet='x86_64-unknown-linux-android'
		;;
	mips64)
		triplet='mips64el-unknown-linux-android'
		;;
	mips)
		triplet='mipsel-unknown-linux-android'
		;;
	riscv64)
		triplet='riscv64-unknown-linux-android'
		;;
esac

if [ "${triplet}" = 'none' ]; then
	echo "fatal error: unknown ABI: ${abi}" 1>&2
	exit '1'
fi

if [[ "${triplet}" = 'mips'*'-unknown-linux-android' ]]; then
	max_api_level='27'
fi

if [ "${api_level}" -gt "${max_api_level}" ]; then
	api_level="${max_api_level}"
fi

declare url="https://github.com/AmanoTeam/Pino/releases/latest/download/${triplet}.tar.xz"

[ -d "${pino_directory}" ] || mkdir --parent "${pino_directory}"

echo "- Fetching archive from '${url}' to '${pino_tarball}'"

curl \
	--url "${url}" \
	--retry '5' \
	--retry-all-errors \
	--retry-delay '0' \
	--retry-max-time '0' \
	--location \
	--output "${pino_tarball}"

echo "- Removing '${pino_directory}'"

rm --force --recursive "${pino_directory}"

echo "- Unpacking tarball from '${pino_tarball}' to '${pino_directory}'"

tar \
	--directory="$(dirname "${pino_directory}")" \
	--extract \
	--file="${pino_tarball}"

rm \
	--force \
	"${pino_directory}/include/bionic/"{zconf,zlib}'.h' \
	"${pino_directory}/"*'-unknown-linux-android'*'/include/'{zconf,zlib}'.h' \
	"${pino_directory}/"*'-unknown-linux-android'*'/lib/libz.so' \
	"${pino_directory}/"*'-unknown-linux-android'*'/lib/static/libz.so'

echo "- Symlinking host tools to '${bindir}'"

for name in "${pino_directory}/bin/"*'-unknown-'*; do
	ln \
		--symbolic \
		--force \
		"${name}" \
		"${bindir}"
done

for name in "${binutils[@]}"; do
	ln \
		--symbolic \
		--force \
		"${pino_directory}/bin/${triplet}-${name}" \
		"${bindir}/e${name}"
done

printf "${wrapper}" "${pino_directory}/lib" "${pino_directory}/bin/${triplet}${api_level}-gcc" > "${bindir}/egcc"
chmod 700 "${bindir}/egcc"

printf "${wrapper}" "${pino_directory}/lib" "${pino_directory}/bin/${triplet}${api_level}-g++" > "${bindir}/eg++"
chmod 700 "${bindir}/eg++"

echo "- Removing '${pino_tarball}'"

unlink "${pino_tarball}"

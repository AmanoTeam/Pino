#/bin/bash

kopt="${-}"

set +u
set -e

if [ -z "${LOKI_HOME}" ]; then
	LOKI_HOME="$(realpath "$(( [ -n "${BASH_SOURCE}" ] && dirname "$(realpath "${BASH_SOURCE[0]}")" ) || dirname "$(realpath "${0}")")""/../../../../..")"
fi

set -u

CROSS_COMPILE_TRIPLET='powerpc64-unknown-freebsd12.3'
CROSS_COMPILE_SYSTEM='freebsd'
CROSS_COMPILE_ARCHITECTURE='powerpc64'
CROSS_COMPILE_SYSROOT="${LOKI_HOME}/${CROSS_COMPILE_TRIPLET}"

CC="${LOKI_HOME}/bin/${CROSS_COMPILE_TRIPLET}-gcc"
CXX="${LOKI_HOME}/bin/${CROSS_COMPILE_TRIPLET}-g++"
AR="${LOKI_HOME}/bin/${CROSS_COMPILE_TRIPLET}-ar"
AS="${LOKI_HOME}/bin/${CROSS_COMPILE_TRIPLET}-as"
LD="${LOKI_HOME}/bin/${CROSS_COMPILE_TRIPLET}-ld"
NM="${LOKI_HOME}/bin/${CROSS_COMPILE_TRIPLET}-nm"
RANLIB="${LOKI_HOME}/bin/${CROSS_COMPILE_TRIPLET}-ranlib"
STRIP="${LOKI_HOME}/bin/${CROSS_COMPILE_TRIPLET}-strip"
OBJCOPY="${LOKI_HOME}/bin/${CROSS_COMPILE_TRIPLET}-objcopy"
READELF="${LOKI_HOME}/bin/${CROSS_COMPILE_TRIPLET}-readelf"

export \
	CROSS_COMPILE_TRIPLET \
	CROSS_COMPILE_SYSTEM \
	CROSS_COMPILE_ARCHITECTURE \
	CROSS_COMPILE_SYSROOT \
	CC \
	CXX \
	AR \
	AS \
	LD \
	NM \
	RANLIB \
	STRIP \
	OBJCOPY \
	READELF

[[ "${kopt}" = *e*  ]] || set +e
[[ "${kopt}" = *u*  ]] || set +u

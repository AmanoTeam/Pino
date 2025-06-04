#!/bin/bash

set -eu

declare -r PINO_HOME='/tmp/pino-toolchain'

if [ -d "${PINO_HOME}" ]; then
	PATH+=":${PINO_HOME}/bin"
	export PINO_HOME \
		PATH
	return 0
fi

declare -r PINO_CROSS_TAG="$(jq --raw-output '.tag_name' <<< "$(curl --retry 10 --retry-delay 3 --silent --url 'https://api.github.com/repos/AmanoTeam/Pino/releases/latest')")"
declare -r PINO_CROSS_TARBALL='/tmp/pino.tar.xz'
declare -r PINO_CROSS_URL="https://github.com/AmanoTeam/Pino/releases/download/${PINO_CROSS_TAG}/x86_64-unknown-linux-gnu.tar.xz"

curl --retry 10 --retry-delay 3 --silent --location --url "${PINO_CROSS_URL}" --output "${PINO_CROSS_TARBALL}"
tar --directory="$(dirname "${PINO_CROSS_TARBALL}")" --extract --file="${PINO_CROSS_TARBALL}"

rm "${PINO_CROSS_TARBALL}"

mv '/tmp/pino' "${PINO_HOME}"

PATH+=":${PINO_HOME}/bin"

export PINO_HOME \
	PATH

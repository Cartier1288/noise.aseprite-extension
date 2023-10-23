#!/bin/bash

NOISE_PACKAGE_NAME=noise
EXT=aseprite-extension
ARCHIVER="7z a -tzip"

if [ $# -ge 1 ]; then
	NOISE_PACKAGE_NAME=$1
fi

if [ $# -ge 2 ]; then
	EXT=$2
fi

if [ -x "$(command -v zip)" ]; then
	ARCHIVER="zip -r"
fi

${ARCHIVER} ${NOISE_PACKAGE_NAME}.${EXT} "./noise-plugin.lua" "./package.json" \
	"./scripts" "./bin"

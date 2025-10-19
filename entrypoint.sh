#!/bin/bash

set -e          # Exit on error
set -u          # Exit on undefined variable
set -o pipefail # Exit on pipeline error

PACK_ARGS=(pack)
if [ -n "$INPUT_EXTRA_SOURCE" ]; then PACK_ARGS+=(--extra-source "$INPUT_EXTRA_SOURCE"); fi
if [ "$INPUT_FORCE" = "true" ]; then PACK_ARGS+=(--force); fi
if [ -n "$INPUT_GETTEXT_DOMAIN" ]; then PACK_ARGS+=(--gettext-domain "$INPUT_GETTEXT_DOMAIN"); fi
if [ -n "$INPUT_OUTPUT_DIR" ]; then PACK_ARGS+=(--out-dir "$INPUT_OUTPUT_DIR"); fi
if [ -n "$INPUT_PODIR" ]; then PACK_ARGS+=(--podir "$INPUT_PODIR"); fi
if [ -n "$INPUT_SCHEMA" ]; then PACK_ARGS+=(--schema "$INPUT_SCHEMA"); fi
PACK_ARGS+=("$INPUT_SOURCE_DIR")

gnome-extensions "${PACK_ARGS[@]}"

if [ -n "$INPUT_USERNAME" ] && [ -n "$INPUT_PASSWORD" ]; then
	OUTPUT_DIR="${INPUT_OUTPUT_DIR:-.}"
	ZIP_FILE=$(find "$OUTPUT_DIR" -maxdepth 1 -name "*.shell-extension.zip" -print -quit)

	if [ -z "$ZIP_FILE" ]; then
		echo "Error: No .shell-extension.zip file found in $OUTPUT_DIR"
		exit 1
	fi

	UPLOAD_ARGS=(upload)
	UPLOAD_ARGS+=(--user "$INPUT_USERNAME")
	UPLOAD_ARGS+=(--password "$INPUT_PASSWORD")
	if [ "$INPUT_ACCEPT_TOS" = "true" ]; then UPLOAD_ARGS+=(--accept-tos); fi
	UPLOAD_ARGS+=("$ZIP_FILE")

	gnome-extensions "${UPLOAD_ARGS[@]}"
fi

#!/bin/bash

set -e          # Exit on error
set -u          # Exit on undefined variable
set -o pipefail # Exit on pipeline error

docker compose -f docker-compose.test.yml run --env INPUT_SOURCE_DIR=./test-extension --env INPUT_OUTPUT_DIR=./dist --rm --build --remove-orphans upload
docker compose -f docker-compose.test.yml down --remove-orphans
test -f ./dist/test-extension@example.com.shell-extension.zip
tmpdir=$(mktemp -d)
mkdir -p $tmpdir/extracted
unzip -q ./dist/test-extension@example.com.shell-extension.zip -d $tmpdir/extracted
diff -r ./test-extension $tmpdir/extracted

echo "All tests passed!"

rm -rf $tmpdir

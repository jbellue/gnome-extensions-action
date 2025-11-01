#!/bin/bash

set -e          # Exit on error
set -u          # Exit on undefined variable
set -o pipefail # Exit on pipeline error

cleanup() {
	echo "Cleaning up..."
	docker compose -f docker-compose.test.yml down --remove-orphans 2>/dev/null || true
	if [ -n "${tmpdir:-}" ]; then rm -rf "$tmpdir"; fi
	if [ -d "./dist" ]; then rm -rf ./dist; fi
	if [ -d "./test-output" ]; then rm -rf ./test-output; fi
}
trap cleanup EXIT

# Run the action with optional environment variables and flags
run_action() {
	mkdir -p ./dist
	docker compose -f docker-compose.test.yml run --rm --remove-orphans "$@" action
}

# Verify the zip file exists
verify_zip_exists() {
	test -f ./dist/test-extension@example.com.shell-extension.zip
}

# Extract zip to temp directory
extract_zip() {
	tmpdir=$(mktemp -d)
	mkdir -p "$tmpdir/extracted"
	unzip -q ./dist/test-extension@example.com.shell-extension.zip -d "$tmpdir/extracted"
}

# Verify wiremock received request count
verify_wiremock_count() {
	local method=$1
	local url_path=$2
	local expected_count=$3
	local description=$4

	local count=$(curl -s -k -X POST https://localhost:8443/__admin/requests/count \
		-H "Content-Type: application/json" \
		-d "{\"method\": \"$method\", \"urlPath\": \"$url_path\"}" | jq -r '.count')

	if [ "$count" -ne "$expected_count" ]; then
		echo "ERROR: Expected $expected_count $description, got $count"
		exit 1
	fi
}

echo "Building docker image..."
docker compose -f docker-compose.test.yml build

echo "Testing basic package and GITHUB_OUTPUT..."
mkdir -p ./test-output
run_action -v "./test-output:/test-output" --env INPUT_SOURCE_DIR=./test-extension --env INPUT_OUTPUT_DIR=./dist --env GITHUB_OUTPUT=/test-output/github_output.txt
verify_zip_exists
# Verify GITHUB_OUTPUT contains zip-file path
github_output="./test-output/github_output.txt"
if ! grep -q "zip-file=./dist/test-extension@example.com.shell-extension.zip" "$github_output"; then
	echo "ERROR: GITHUB_OUTPUT missing or incorrect"
	cat "$github_output"
	exit 1
fi
rm -rf ./test-output
extract_zip
# Verify extra files are NOT included in basic package
test ! -f "$tmpdir/extracted/extra-1.js"
test ! -f "$tmpdir/extracted/extra-2.js"

echo "Testing extra sources..."
INPUT_EXTRA_SOURCE="
./extra-1.js
./extra-2.js
"
run_action --env INPUT_SOURCE_DIR=./test-extension --env INPUT_OUTPUT_DIR=./dist --env INPUT_EXTRA_SOURCE="$INPUT_EXTRA_SOURCE"
verify_zip_exists
extract_zip
diff -r ./test-extension "$tmpdir/extracted"

echo "Testing upload with credentials..."
run_action --env INPUT_SOURCE_DIR=./test-extension --env INPUT_OUTPUT_DIR=./dist --env INPUT_USERNAME=test-user --env INPUT_PASSWORD=test-password
verify_zip_exists
verify_wiremock_count "POST" "/api/v1/accounts/login/" 1 "login request"
verify_wiremock_count "POST" "/api/v1/extensions" 1 "upload request"

echo "All tests passed!"

#!/bin/sh
# Flutter 3.27.0 HTML renderer build. macOS BSD sed needs a backup suffix.
set -eu
build_output_dir=$1
base_path=$2
if [ -z "$build_output_dir" ] || [ -z "$base_path" ]; then
  echo "usage: sh build_web.sh <output-dir> <base-href>" >&2
  exit 1
fi
FLUTTER_BIN=${FLUTTER_BIN:-flutter}
version=$("$FLUTTER_BIN" --version --machine 2>/dev/null || "$FLUTTER_BIN" --version)
printf '%s\n' "$version" | grep -q '"flutterVersion": *"3.27.0"\|Flutter 3.27.0' || {
  echo "flutter_version_mismatch:expected_3.27.0" >&2
  exit 1
}
echo "flutter build web --web-renderer=html --output=$build_output_dir --base-href=$base_path --release --tree-shake-icons"
"$FLUTTER_BIN" build web --web-renderer=html --output="$build_output_dir" --base-href="$base_path" --release --tree-shake-icons
stamp=$(date +%Y%m%d%H%M%S)
if sed --version >/dev/null 2>&1; then
  sed -i "s/ttVersion123456/$stamp/" "$build_output_dir/index.html"
else
  sed -i '' "s/ttVersion123456/$stamp/" "$build_output_dir/index.html"
fi
echo "Build web successfully"

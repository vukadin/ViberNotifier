#!/bin/bash
set -euo pipefail
project_root="$(cd "$(dirname "$0")/.." && pwd)"
build_dir="${TMPDIR:-/tmp}/ViberNotifier-release"
output_dir="$project_root/dist"

xcodebuild -project "$project_root/ViberNotifier.xcodeproj" \
    -scheme 'Viber Notifier' -configuration Release \
    -derivedDataPath "$build_dir" CODE_SIGNING_ALLOWED=NO build

mkdir -p "$output_dir"
ditto "$build_dir/Build/Products/Release/Viber Notifier.app" "$output_dir/Viber Notifier.app"
codesign --force --deep --sign - --identifier com.njenja.viber-notifier "$output_dir/Viber Notifier.app"
codesign --verify --deep --strict "$output_dir/Viber Notifier.app"
ditto -c -k --sequesterRsrc --keepParent "$output_dir/Viber Notifier.app" "$output_dir/Viber Notifier.zip"
printf 'Built %s\n' "$output_dir/Viber Notifier.app"

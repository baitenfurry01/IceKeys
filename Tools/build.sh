#!/bin/bash
set -euo pipefail
project_dir="$(cd "$(dirname "$0")/.." && pwd)"
build_dir="$(mktemp -d /private/tmp/icekeys-build.XXXXXX)"
xcodebuild -project "$project_dir/IceKeys.xcodeproj" -scheme IceKeys -configuration Debug -derivedDataPath "$build_dir" -destination "platform=macOS,arch=$(uname -m)" ENABLE_DEBUG_DYLIB=NO build
app_source="$build_dir/Build/Products/Debug/IceKeys.app"
app_destination="$project_dir/../IceKeys.app"
ditto --norsrc --noextattr "$app_source" "$app_destination"
printf '\nApp: %s\n' "$app_destination"

#!/bin/bash

# ABOUTME: Parallel export script for all configured Godot export presets
# ABOUTME: Runs Windows, Linux, Web, and Android exports simultaneously

set -e

echo "Starting parallel export of all platforms..."

# Create export directories
mkdir -p export/{win,linux,web,android}

# Run all exports in parallel
(
    echo "Exporting Windows Desktop..."
    godot --export-release "Windows Desktop" --headless 2>&1 | sed 's/^/[WIN] /'
) &

(
    echo "Exporting Linux..."
    godot --export-release "Linux" --headless 2>&1 | sed 's/^/[LINUX] /'
) &

(
    echo "Exporting Web..."
    godot --export-release "Web" --headless 2>&1 | sed 's/^/[WEB] /'
) &

(
    echo "Exporting Android..."
    godot --export-release "Android" export/android/gmtk25-secondary.apk --headless 2>&1 | sed 's/^/[ANDROID] /'
) &

# Wait for all background jobs to complete
wait

echo ""
echo "All exports completed!"
echo ""
echo "Export results:"
echo "- Windows: export/win/"
echo "- Linux: export/linux/"
echo "- Web: export/web/"
echo "- Android: export/android/"
echo ""

# Show file sizes
if command -v du >/dev/null 2>&1; then
    echo "Export sizes:"
    du -sh export/*/
fi
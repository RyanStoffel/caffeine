#!/bin/bash
# Builds Caffeine.app. Pass --install to copy it into /Applications.
set -euo pipefail

cd "$(dirname "$0")"

APP=".build/Caffeine.app"

swift build -c release --arch arm64 --arch x86_64

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp Resources/Info.plist "$APP/Contents/Info.plist"
if [ -f Resources/AppIcon.icns ]; then
	cp Resources/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
fi
cp .build/apple/Products/Release/Caffeine "$APP/Contents/MacOS/Caffeine"
codesign --force --sign - "$APP"

echo "Built $PWD/$APP"

if [[ "${1:-}" == "--install" ]]; then
	rm -rf /Applications/Caffeine.app
	cp -R "$APP" /Applications/Caffeine.app

	# Ensure no custom Finder icon override exists
	swift - <<'EOF'
import AppKit
let appPath = "/Applications/Caffeine.app"
_ = NSWorkspace.shared.setIcon(nil, forFile: appPath, options: [])
EOF

	/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f /Applications/Caffeine.app
	touch /Applications/Caffeine.app

	echo "Installed /Applications/Caffeine.app"
fi

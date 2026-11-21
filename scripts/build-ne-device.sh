#!/bin/zsh
set -euo pipefail
cd /Users/sonoma/Desktop/VPNDemo

LOG=/tmp/vpndemo-ne-gui-build.log
echo "=== build start $(date) ===" | tee "$LOG"

xcodebuild -workspace VPNDemo.xcworkspace -scheme VPNDemo \
  -destination 'generic/platform=iOS' \
  -configuration Debug \
  -allowProvisioningUpdates \
  -allowProvisioningDeviceRegistration \
  DEVELOPMENT_TEAM=7TNL83WLRC \
  CODE_SIGN_STYLE=Automatic \
  build 2>&1 | tee -a "$LOG"

if rg -q "BUILD SUCCEEDED" "$LOG"; then
  APP=$(find ~/Library/Developer/Xcode/DerivedData -path '*/Build/Products/Debug-iphoneos/VPNDemo.app' | head -1)
  echo "APP=$APP" | tee -a "$LOG"
  # Prefer physical device if unlocked
  xcrun devicectl device install app --device 00008110-0012295E01F2401E "$APP" 2>&1 | tee -a "$LOG" || true
  xcrun devicectl device process launch --device 00008110-0012295E01F2401E com.yutianduan.vpndemo 2>&1 | tee -a "$LOG" || true
  echo "=== done $(date) ===" | tee -a "$LOG"
else
  echo "=== BUILD FAILED ===" | tee -a "$LOG"
  exit 1
fi

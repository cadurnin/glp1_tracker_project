---
name: feedback_build_environment
description: xcodebuild cannot resolve destinations due to CoreSimulator version mismatch; swiftc type-check is the available fallback
metadata:
  type: feedback
---

`xcodebuild -destination 'generic/platform=iOS Simulator'` fails with "CoreSimulator is out of date" (installed 1051.50.0, build requires 1051.54.0). No simulator or device destination resolves.

**Why:** The macOS system CoreSimulator is behind the Xcode version installed.

**How to apply:** Use `swiftc -sdk <iPhoneOS.sdk path> -target arm64-apple-ios17.0 -typecheck $(find ... -name "*.swift")` for type-checking. Available SDK: `/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk`.

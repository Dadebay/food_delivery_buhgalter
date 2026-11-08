# A7-TAGAM Accountant

A Flutter companion for A7-TAGAM staff to review cash days, monthly reports, orders, handoffs, and audit events. It reads the server's accounting figures from `https://a7-tagam.com.tm/api/v1`; it does not recalculate balances on the device. Authorized accountants can confirm submitted cash handoffs. Super administrators can also create handoffs and mark eligible order cash as returned.

The app supports Russian and Turkmen. Sign-in uses a staff phone number and a one-time code; access is limited to active `ACCOUNTANT` and `SUPER_ADMIN` accounts. The related [accounting web page](https://a7-tagam.com.tm/accounting) is operated separately.

## Development

Install a current stable Flutter SDK with Dart 3.3 or newer, Android SDK tools, and Xcode/CocoaPods for iOS. Then run:

```sh
flutter pub get
flutter run
```

Quality checks:

```sh
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug
# macOS with Xcode:
flutter build ios --simulator --no-codesign
```

Android builds use Gradle with JDK 17. No test account, signing key, or backend secret belongs in this repository.

## Distribution

There is **no verified Google Play listing** or public signed download for this app yet, so this README does not link to one. The Android application ID and iOS bundle ID still use `com.example` identifiers; choose and verify production identifiers before a store submission. Release signing must use this app's own private key outside Git. Debug-signed builds are for development only.

When a signed version is distributed, publish a GitHub Release from the exact source commit and add its verified download and store links here. Until then, the source and debug build instructions above are the available installation paths.

## Operational notes

The backend and accounting website are separate deployments. A backend owner must verify API compatibility, service health, backups, credentials, and rollback procedures before any production rollout. This repository does not contain those server operations or signing secrets.

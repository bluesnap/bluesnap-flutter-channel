# Integration tests

`app_smoke_test.dart` launches the example app with the real plugin. It checks
that the native plugin registers, loads the BlueSnap SDK classes and asks Dart for
a token (`onGenerateToken`). This catches native SDK regressions, such as classes
or methods missing after an SDK upgrade, that crash the app at startup. It needs
no sandbox credentials. Without credentials, the native `BlueSnapService.setup()`
is not reached; it runs only when a real sandbox token is returned.

All commands run from `example/`. The app reads `assets/credentials.json`
(gitignored). For the smoke test an empty object is enough:

```sh
mkdir -p assets && [ -f assets/credentials.json ] || echo '{}' > assets/credentials.json
```

## On a connected device, emulator or Android Studio Device Streaming

Device Streaming devices (Firebase-hosted, started from Android Studio's Device
Manager) show up in `adb devices` like a local device.

```sh
flutter devices                                   # find the device id
flutter test integration_test/app_smoke_test.dart -d <device-id>
```

## On Firebase Test Lab

`android/app/src/androidTest/.../MainActivityTest.java` runs the Dart tests as
instrumentation tests.

```sh
flutter build apk --debug --config-only   # generates android/gradlew, the wrapper jar and android/local.properties (all gitignored)
cd android
./gradlew app:assembleAndroidTest
./gradlew app:assembleDebug -Ptarget=integration_test/app_smoke_test.dart
cd ..
gcloud firebase test android run --type instrumentation \
  --app build/app/outputs/apk/debug/app-debug.apk \
  --test build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk \
  --device model=MediumPhone.arm,version=35 \
  --timeout 10m
```

`flutter pub get` alone creates `local.properties` but not `gradlew`.

Android requirements: JDK 17, and an Android device or image at API 29 or higher
(bluesnap-android 2.8.1 requires minSdk 29).

## On an iOS simulator

Requirements: Xcode with an iOS simulator runtime, and CocoaPods. Tested with
Xcode 27 on iOS 27.0 and 26.5 simulators.

```sh
xcrun simctl list devices available               # pick a simulator id
xcrun simctl boot <simulator-id>
flutter test integration_test/app_smoke_test.dart -d <simulator-id>
```

`ios/RunnerTests` holds native unit tests (XCTest) for the plugin's method
handling, and checks that the example app hosts Flutter in a
`UINavigationController`. Run `flutter build ios --config-only` first: after
`flutter test integration_test/...`, the generated Xcode config still points at
the test's temporary entry point, and the Xcode build fails.

```sh
flutter build ios --config-only --simulator --debug
cd ios
xcodebuild test -workspace Runner.xcworkspace -scheme Runner \
  -destination 'platform=iOS Simulator,id=<simulator-id>' \
  -only-testing:RunnerTests -collect-test-diagnostics never
```

Without `-collect-test-diagnostics never`, a failing run spends about 10 more
minutes collecting a sysdiagnose.
`xcodebuild test` runs on a clone of the simulator and can leave the original
shut down. Boot it again before the next `flutter test`.

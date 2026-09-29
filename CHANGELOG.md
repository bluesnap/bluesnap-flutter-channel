## 0.1.0

**Breaking (Android):** apps must set `minSdk` 29 or higher and build with JDK 17 or newer.

* Android: bridge bluesnap-android v2.8.1 (was v2.5.2), adapting to its Kotlin API (`BlueSnapService.instance`, `TaxCalculator` interface, non-null `setup()` parameters, `getSdkResult()`).
* Android: raise the plugin `minSdk` from 24 to 29, because bluesnap-android 2.8.1 requires it. Apps below 29, including Flutter's default of 24, fail with `Manifest merger failed : uses-sdk:minSdkVersion 24 cannot be smaller than version 29 declared in library [:bluesnap_sdk]`.
* Android: compile for Java 17, `compileSdk`/`targetSdk` 36, and declare the `namespace` required by Android Gradle Plugin 8+.
* Android: ship consumer R8 rules so release builds compile and the checkout result maps keep their keys.
* Android: `merchantStoreCurrency` defaults to USD when omitted, as in the native SDK.
* Android: removed debug logging.
* `pubspec.yaml`: the `flutter` constraint is now `>=3.10.6`, the lowest version the Dart SDK constraint (`>=3.0.6`) already allowed. Android builds also need the toolchain listed under README, "Android requirements".
* Unchanged: apps still need the JitPack and Cardinal Commerce Maven repositories and `tools:replace="android:label"` (now documented in README, "Android requirements").
* Example: migrate to the Flutter 3.47 Android template (AGP 9.1.0, Gradle 9.3.1, Kotlin 2.4.0, JDK 17). Upgrade fluttertoast to ^10, which requires Flutter 3.44 / Dart 3.12 or later. Add an integration smoke test in `example/integration_test`.
* iOS: still bridges BluesnapSDK 2.0.5 (iOS 13.0). Removed debug logging from `checkoutCard`.
* Example (iOS): adopt the UIScene lifecycle, which Flutter requires on iOS 27, and apply Flutter 3.47's iOS project migrations (iOS 15.0 minimum; Swift Package Manager for the plugins that support it). The Flutter view stays inside a `UINavigationController`, now set up in `Main.storyboard`. Replace the placeholder native unit test with XCTests for the plugin's method handling. README documents the iOS requirements, and `example/integration_test/README.md` explains how to run the iOS tests.

## 0.0.2

* Bridges bluesnap-android v2.5.2 (Android minSdk 24) and BluesnapSDK (iOS) 2.0.5 (iOS 13.0).

# bluesnap-flutter-channel

### This is a work in progress

This project provides Flutter channels implementation and example to demonstrate how to use Bluesnap Native SDKs for Android and iOS in Flutter apps

## Supported native SDKs

| Platform | Native SDK | Minimum OS |
|---|---|---|
| Android | `com.github.bluesnap:bluesnap-android:v2.8.1` | Android 10 (API 29) |
| iOS | `BluesnapSDK` 2.0.5 (CocoaPods) | iOS 13.0 |

The native SDK versions are fixed by this plugin (`android/build.gradle`, `ios/bluesnap_sdk.podspec`). Changing them without changing the plugin code is not supported. For example, bluesnap-android 2.7 moved `BlueSnapService` and `TaxCalculator` to Kotlin, which required plugin changes.

### Android requirements

Tested with Flutter 3.47.5 (Android Gradle Plugin 9.1.0, Gradle 9.3.1, Kotlin 2.4.0, JDK 17).

1. **minSdk 29 or higher.** Flutter's default `flutter.minSdkVersion` (24) is too low. In `android/app/build.gradle.kts` set `android { defaultConfig { minSdk = 29 } }` (Groovy: `minSdkVersion 29`). Otherwise the build fails with `Manifest merger failed : uses-sdk:minSdkVersion 24 cannot be smaller than version 29 declared in library [:bluesnap_sdk]`. Do not use `tools:overrideLibrary`: bluesnap-android itself declares minSdk 29.
2. **JDK 17 or newer.** The plugin and bluesnap-android 2.8.1 are compiled for Java 17. Use `flutter config --jdk-dir=<jdk-17>` if needed. compileSdk 36 is recommended; a lower value only produces a warning.
3. **Maven repositories.** bluesnap-android is published on JitPack. Its 3-D Secure dependency `org.jfrog.cardinalcommerce.gradle:cardinalmobilesdk` is published in Cardinal Commerce's repository. Repositories declared inside the plugin do not apply to your app, so add both to `android/build.gradle.kts` in the form below (see `example/android/build.gradle` for the read-only credentials):

   ```kotlin
   allprojects {
       repositories {
           google()
           mavenCentral()
           maven { url = uri("https://jitpack.io") }
           maven {
               url = uri("https://cardinalcommerceprod.jfrog.io/artifactory/android")
               credentials {
                   username = "bluesnap_sdk_users"
                   password = "<password from example/android/build.gradle>"
               }
           }
       }
   }
   ```

   Without them the build fails with `Could not find com.github.bluesnap:bluesnap-android:v2.8.1` or `Could not find org.jfrog.cardinalcommerce.gradle:cardinalmobilesdk:2.2.7-5`.
4. **Manifest label.** The Cardinal SDK declares `android:label` on `<application>`. In `android/app/src/main/AndroidManifest.xml`, add `xmlns:tools="http://schemas.android.com/tools"` to `<manifest>` and `tools:replace="android:label"` to `<application>`.
5. **Android Gradle Plugin 9:** keep `android.builtInKotlin=false` and `android.newDsl=false` in `android/gradle.properties`. The Flutter 3.47 template and Flutter's migrator add both. The plugin still applies the Kotlin Gradle plugin, so Flutter prints a warning about it.

Release builds need no extra R8/ProGuard rules: the plugin ships consumer rules for the SDK.

### iOS requirements

1. **Navigation controller.** The plugin shows the BlueSnap screens by pushing them onto the app's root `UINavigationController`, so the Flutter view must be inside one. In `ios/Runner/Base.lproj/Main.storyboard`, make a `UINavigationController` with a hidden navigation bar the initial view controller, with the `FlutterViewController` as its root, as `example/ios/Runner/Base.lproj/Main.storyboard` does.
2. **UIScene lifecycle.** Flutter requires the UIScene lifecycle on iOS 27 and later ([migration guide](https://flutter.dev/to/uiscene-migration)). The storyboard setup above works with it; the example uses Flutter 3.47's `AppDelegate` and `SceneDelegate` templates.

### Additional SDKS
Each native sdk implementation contains additional dependencies which are required for 3DS and and anti-fraud detection. CardinalSDK and Kount. 

## Example application

This project include a sample application for demonstration purposes in `example/`
It demonstrates both built-in UI implementation and a customized UI from the Example flutter application.

Installation

1. Clone the Repository:

   git clone https://github.com/bluesnap/bluesnap-flutter-channel
   cd bluesnap-flutter-channel/example

2. Install Dependencies:

   flutter pub get

3. Add Your Credentials:

   Create a `credentials.json` file in the `assets` directory with the following format:

   {
   "username": "your_username",
   "password": "your_password"
   }

4. Run the Application:

   flutter run

Steps for BlueSnap SDK Integration

1. Listen to `onGenerateToken` and Create a Request to the Server:
    - Set up a listener for the BlueSnap SDK's `onGenerateToken` event.
    - This event triggers when a token needs to be generated for a transaction.

2. Connect to the Server and Finalize Token:
    - Within the `onGenerateToken` callback, send a request to your server to generate a BlueSnap payment token.
    - Once the token is returned from the server, call `finalizeToken` on the BlueSnap SDK to complete the tokenization.

3. Initialize BlueSnap SDK:
    - Call `initBluesnap` with necessary parameters like `bsToken`, `initKount`, and `merchantStoreCurrency` to initialize the SDK.

4. Set SDK Parameters Before Checkout:
    - Use `setSDKRequest` to configure the SDK with the transaction details, including amount, currency, and 3DS activation.

5. Start Checkout:
    - Native UI: Use the `showCheckout` method to initiate the checkout process using the native BlueSnap UI.
    - Flutter Custom UI: Use the `checkoutCard` method to process the payment within your custom Flutter UI.



How to run example:
- Go to example folder ->  run command `flutter pub get`
- Create credentials.json to example/assets
- Enter `username`  and `password` into credentials.json 
```
{
    "username": "",
    "password": ""
}

```
- Add assets/credentials.json to pubspec.yaml
```
  assets:
    - assets/credentials.json
```
- Run example/main.dart by running the command `flutter run`
- Press the `Show checkout` button to start payment flow with native UI (ios/android)
- Fill input and press `Checkout` to payment with a custom Flutter UI that does not show the built-in native UI.



### Note
Even a custom Ui will show 3DS confirmation UI if required.

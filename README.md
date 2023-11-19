# bluesnap-sdk-flutter

### This is a work in progress

This project provides Flutter channels implementation and example to demonstrate how to use Bluesnap Native SDKs for Android and iOS in Flutter apps
The Native SDKs are regularly updated and the versions are not automatically updated here so you might want to verify the most recent version of the Bluesnap SDK Cocoapod and Android aar by examining the following:


- File: `ios/bluesnap_sdk.podspec` `  s.dependency "BluesnapSDK",`
- File: `example/android/app/build.gradle ` `implementation "com.github.bluesnap:bluesnap-android-int"`

### Additional SDKS
Each native sdk implementation contains additional dependencies which are required for 3DS and and anti-fraud detection. CardinalSDK and Kount. 

## Example application

This project include a sample application for demonstration purposes in `example/`
It demonstrates both built-in UI implementation and a customized UI from the Example flutter application.


How to run the example manually:

- Use flutter version 3.10.6
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


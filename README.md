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

Installation

1. Clone the Repository:

   git clone https://github.com/intrinisec/bluesnap-sdk-flutter
   cd example

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

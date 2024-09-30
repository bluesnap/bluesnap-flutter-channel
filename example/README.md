Overview

This Flutter application demonstrates how to integrate the BlueSnap payment gateway using the `bluesnap_sdk`. The app covers initializing the BlueSnap SDK, generating payment tokens, and processing payments via both native and custom Flutter UIs.

Features

- BlueSnap SDK Integration: Initialization and use of the BlueSnap SDK for handling payments.
- UI Options: Choose between a native payment UI and a custom Flutter UI.
- Secure Token Generation: Generate payment tokens securely.
- Asynchronous Operations: Handle API calls and SDK initialization asynchronously.
- User Feedback: Error handling with `FlutterToast` and loading indicators with `FlutterEasyLoading`.

Prerequisites

- Software:
  - Flutter 3.22.3
  - Dart SDK 3.4.4
- Accounts:
  - BlueSnap account
- Credentials:
  - A `credentials.json` file located in the `assets` directory containing your BlueSnap API credentials.

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

Project Structure

- `main.dart`: Entry point of the application. Initializes the BlueSnap SDK and sets up the main app structure.
- `CheckOutCard` widget: Custom Flutter widget that provides a form for users to enter their payment details and process payments using BlueSnap.
- Services:
  - `ApiService`: Handles API requests using the `Dio` package.
  - `AssetService`: Loads assets like the credentials JSON file.

Usage

Initializing BlueSnap SDK

The SDK is initialized within the `initState` method of the `_MyAppState` class. The `initBluesnap` method is called with necessary parameters, such as `bsToken`, `initKount`, `fraudSessionId`, and `merchantStoreCurrency`.

Generating Payment Token

The `getGenerateToken` method generates a payment token by making an API request to the BlueSnap server. The token is then passed to the BlueSnap SDK for finalization.

Processing Payments

You can process payments in two ways:

1. Native UI: Triggered by the "Show checkout" button, which opens the native BlueSnap payment UI.
2. Custom Flutter UI: Provides a form for users to enter their payment details and process the payment.

Error Handling

Errors during SDK initialization or payment processing are caught and displayed using `FlutterToast`. Loading indicators during asynchronous operations are shown using `FlutterEasyLoading`.

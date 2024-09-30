
Prerequisites
- Software:
  - Flutter 3.22.3
  - Dart SDK 3.4.4

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
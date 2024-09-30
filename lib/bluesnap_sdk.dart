import 'bluesnap_sdk_platform_interface.dart';

class BluesnapSdk {
  Stream<dynamic> get onGenerateToken =>
      BluesnapSdkPlatform.instance.onGenerateToken;

  Stream<String> get onError => BluesnapSdkPlatform.instance.onError;

  Future<void> initBluesnap({
    String? bsToken,
    required bool initKount,
    String? fraudSessionId,
    String? applePayMerchantIdentifier,
    String? merchantStoreCurrency,
  }) =>
      BluesnapSdkPlatform.instance.initBluesnap(
        initKount: initKount,
        applePayMerchantIdentifier: applePayMerchantIdentifier,
        fraudSessionId: fraudSessionId,
        merchantStoreCurrency: merchantStoreCurrency,
        bsToken: bsToken,
      );

  Future<void> finalizeToken(String token) =>
      BluesnapSdkPlatform.instance.finalizeToken(token);

  Future<void> setSDKRequest({
    required bool withEmail,
    required bool withShipping,
    required bool fullBilling,
    required double amount,
    required double taxAmount,
    required String currency,
    required bool activate3DS,
  }) =>
      BluesnapSdkPlatform.instance.setSDKRequest(
        withEmail: withEmail,
        withShipping: withShipping,
        fullBilling: fullBilling,
        amount: amount,
        taxAmount: taxAmount,
        currency: currency,
        activate3DS: activate3DS,
      );

  Future<Map<String, dynamic>> showCheckout() =>
      BluesnapSdkPlatform.instance.showCheckout();

  Future<Map<String, dynamic>> checkoutCard({
    required String cardNumber,
    required String expirationDate,
    required String cvv,
    required String name,
    required String billingZip,
    String? email,
  }) =>
      BluesnapSdkPlatform.instance.checkoutCard(
        cardNumber: cardNumber,
        expirationDate: expirationDate,
        cvv: cvv,
        name: name,
        billingZip: billingZip,
        email: email,
      );
}

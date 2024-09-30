import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'bluesnap_sdk_method_channel.dart';

abstract class BluesnapSdkPlatform extends PlatformInterface {
  /// Constructs a BluesnapSdkPlatform.
  BluesnapSdkPlatform() : super(token: _token);

  static final Object _token = Object();

  static BluesnapSdkPlatform _instance = MethodChannelBluesnapSdk();

  /// The default instance of [BluesnapSdkPlatform] to use.
  ///
  /// Defaults to [MethodChannelBluesnapSdk].
  static BluesnapSdkPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [BluesnapSdkPlatform] when
  /// they register themselves.
  static set instance(BluesnapSdkPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Stream<dynamic> get onGenerateToken;

  Stream<String> get onError;

  Future<void> initBluesnap({
    String? bsToken,
    required bool initKount,
    String? fraudSessionId,
    String? applePayMerchantIdentifier,
    String? merchantStoreCurrency,
  });

  Future<void> finalizeToken(String token);

  Future<void> setSDKRequest({
    required bool withEmail,
    required bool withShipping,
    required bool fullBilling,
    required double amount,
    required double taxAmount,
    required String currency,
    required bool activate3DS,
  });

  Future<Map<String, dynamic>> showCheckout();

  Future<Map<String, dynamic>> checkoutCard({
    required String cardNumber,
    /**
   * Recommended format: MM/YY
   */
    required String expirationDate,
    required String cvv,
    required String name,
    required String billingZip,
    String? email,
  });
}

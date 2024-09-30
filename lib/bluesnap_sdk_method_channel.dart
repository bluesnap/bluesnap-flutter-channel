import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:rxdart/subjects.dart';

import 'bluesnap_sdk_platform_interface.dart';

/// An implementation of [BluesnapSdkPlatform] that uses method channels.
class MethodChannelBluesnapSdk extends BluesnapSdkPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('bluesnap_sdk');

  final PublishSubject<dynamic> _publishGenerateTokenSubject =
      PublishSubject<dynamic>();
  final PublishSubject<String> _publishErrorSubject = PublishSubject<String>();
  @override
  Future<void> initBluesnap({
    String? bsToken,
    required bool initKount,
    String? fraudSessionId,
    String? applePayMerchantIdentifier,
    String? merchantStoreCurrency,
  }) async {

    methodChannel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'generateToken':
          _publishGenerateTokenSubject.sink.add(call.arguments);
          break;
        case 'error':
          _publishErrorSubject.sink.add(call.arguments);
          break;
      }
    });

    await methodChannel.invokeMethod('initBluesnap', {
      'bsToken': bsToken,
      'initKount': initKount,
      'fraudSessionId': fraudSessionId,
      'applePayMerchantIdentifier': applePayMerchantIdentifier,
      'merchantStoreCurrency': merchantStoreCurrency,
    });
  }

  @override
  Stream get onGenerateToken => _publishGenerateTokenSubject.stream;

  @override
  Future<void> finalizeToken(String token) async {
    await methodChannel.invokeMethod('finalizeToken', token);
  }

  @override
  Stream<String> get onError => _publishErrorSubject.stream;

  @override
  Future<void> setSDKRequest({
    required bool withEmail,
    required bool withShipping,
    required bool fullBilling,
    required double amount,
    required double taxAmount,
    required String currency,
    required bool activate3DS,
  }) async {
    await methodChannel.invokeMethod('setSDKRequest', {
      'withEmail': withEmail,
      'withShipping': withShipping,
      'fullBilling': fullBilling,
      'amount': amount,
      'taxAmount': taxAmount,
      'currency': currency,
      'activate3DS': activate3DS,
    });
  }

  @override
  Future<Map<String, dynamic>> showCheckout() async {
    final result = await methodChannel.invokeMethod('showCheckout');

    return Map<String, dynamic>.from(result);
  }

  @override
  Future<Map<String, dynamic>> checkoutCard({
    required String cardNumber,
    required String expirationDate,
    required String cvv,
    required String name,
    required String billingZip,
    String? email,
  }) async {
    final result = await methodChannel.invokeMethod('checkoutCard', {
      'cardNumber': cardNumber,
      'expirationDate': expirationDate,
      'cvv': cvv,
      'name': name,
      'billingZip': billingZip,
      'email': email,
    });
    return Map<String, dynamic>.from(result);
  }
}

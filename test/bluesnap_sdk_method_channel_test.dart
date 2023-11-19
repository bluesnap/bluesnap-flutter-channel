import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bluesnap_sdk/bluesnap_sdk_method_channel.dart';

extension MethodChannelMock on MethodChannel {
  Future<void> invokeNativeMethod(String method, dynamic arguments) async {
    const codec = StandardMethodCodec();
    final data = codec.encodeMethodCall(MethodCall(method, arguments));
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(name, data, (data) {});
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelBluesnapSdk platform = MethodChannelBluesnapSdk();
  const MethodChannel channel = MethodChannel('bluesnap_sdk');

  setUp(() {
    Map<String, dynamic> sdkRequestMap = {};
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'initBluesnap':
            channel.invokeNativeMethod('generateToken', null);
            break;
          case 'setSDKRequest':
            sdkRequestMap = Map<String, dynamic>.from(methodCall.arguments);
            break;
          case 'finalizeToken':
            break;
          case 'checkoutCard':
            return methodCall.arguments;

          case 'showCheckout':
            return sdkRequestMap;

          default:
        }

        return null;
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('initBluesnap', () async {
    Completer<void> completer = Completer<void>();
    platform.onGenerateToken.listen((event) async {
      await platform.finalizeToken('token');

      if (!completer.isCompleted) {
        completer.complete();
      }
    });

    await platform.initBluesnap(
      initKount: false,
    );

    await completer.future;
  });

  test('showCheckout', () async {
    Completer<void> completer = Completer<void>();
    platform.onGenerateToken.listen((event) async {
      await platform.finalizeToken('token');

      if (!completer.isCompleted) {
        completer.complete();
      }
    });
    await platform.initBluesnap(
      initKount: false,
    );

    await completer.future;
    await platform.setSDKRequest(
      withEmail: false,
      withShipping: false,
      fullBilling: false,
      amount: 1,
      taxAmount: 0,
      currency: 'USD',
      activate3DS: false,
    );

    final result = await platform.showCheckout();
    final withEmail = result['withEmail'];
    expect(withEmail, false);
  });

  test('checkoutCard', () async {
    Completer<void> completer = Completer<void>();
    platform.onGenerateToken.listen((event) async {
      await platform.finalizeToken('token');

      if (!completer.isCompleted) {
        completer.complete();
      }
    });
    await platform.initBluesnap(
      initKount: false,
    );

    await completer.future;
    await platform.setSDKRequest(
      withEmail: false,
      withShipping: false,
      fullBilling: false,
      amount: 1,
      taxAmount: 0,
      currency: 'USD',
      activate3DS: false,
    );

    final result = await platform.checkoutCard(
      cardNumber: '4242424242424242',
      billingZip: '',
      cvv: '445',
      expirationDate: '',
      name: '',
      email: '',
    );
    final cardNumber = result['cardNumber'];
    expect(cardNumber, '4242424242424242');
  });
}

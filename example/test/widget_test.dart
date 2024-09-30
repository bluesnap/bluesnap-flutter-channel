// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:convert';

import 'package:bluesnap_sdk/bluesnap_sdk.dart';
import 'package:bluesnap_sdk_example/service/api_serivce.dart';
import 'package:bluesnap_sdk_example/service/asset_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bluesnap_sdk_example/main.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:rxdart/rxdart.dart';

import 'widget_test.mocks.dart';

@GenerateMocks([
  BluesnapSdk,
  AssetService,
  ApiService,
])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final mockBluesnapSdk = MockBluesnapSdk();
  final mockAssetService = MockAssetService();
  final mockApiService = MockApiService();

  final result = <String, dynamic>{"checkout": "124", "": ""};
  final PublishSubject<Map<String, dynamic>> publishGenerateTokenSubject =
      PublishSubject<Map<String, dynamic>>();

  setUp(() {
    when(mockBluesnapSdk.initBluesnap(
      bsToken: 'bsToken',
      initKount: true,
      fraudSessionId: '',
      applePayMerchantIdentifier: 'merchant.com.example.bluesnap',
      merchantStoreCurrency: 'USD',
    )).thenAnswer(
      (realInvocation) {
        publishGenerateTokenSubject.sink.add({});
        return Future.value();
      },
    );

    when(mockApiService.post(
      any,
      data: anyNamed("data"),
      cancelToken: anyNamed("cancelToken"),
      onReceiveProgress: anyNamed("onReceiveProgress"),
      onSendProgress: anyNamed("onSendProgress"),
      options: anyNamed("options"),
      queryParameters: anyNamed("queryParameters"),
    )).thenAnswer(
      (realInvocation) {
        return Future.value(Response(
          headers: Headers.fromMap(
            {
              'location': [''],
            },
          ),
          requestOptions: RequestOptions(),
        ));
      },
    );

    when(mockBluesnapSdk.onGenerateToken).thenAnswer(
      (realInvocation) {
        return publishGenerateTokenSubject.stream;
      },
    );

    when(mockBluesnapSdk.finalizeToken(any)).thenAnswer(
      (realInvocation) {
        return Future.value();
      },
    );

    when(mockAssetService.loadString(any)).thenAnswer(
      (realInvocation) {
        return Future.value(jsonEncode({"username": "1", "password": "1!"}));
      },
    );
    when(mockBluesnapSdk.setSDKRequest(
      activate3DS: anyNamed("activate3DS"),
      amount: anyNamed("amount"),
      currency: anyNamed("currency"),
      fullBilling: anyNamed("fullBilling"),
      taxAmount: anyNamed("taxAmount"),
      withEmail: anyNamed("withEmail"),
      withShipping: anyNamed("withShipping"),
    )).thenAnswer(
      (realInvocation) {
        return Future.value();
      },
    );
    when(mockBluesnapSdk.checkoutCard(
      billingZip: anyNamed("billingZip"),
      cardNumber: anyNamed("cardNumber"),
      cvv: anyNamed("cvv"),
      expirationDate: anyNamed("expirationDate"),
      name: anyNamed("name"),
      email: anyNamed("email"),
    )).thenAnswer(
      (realInvocation) {
        return Future.value(result);
      },
    );

    when(mockBluesnapSdk.showCheckout()).thenAnswer(
      (realInvocation) {
        return Future.value(result);
      },
    );
  });

  tearDown(() {
    publishGenerateTokenSubject.close();
  });

  testWidgets('Show native UI checkout', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp(
      bluesnapSdkPlugin: mockBluesnapSdk,
      assetService: mockAssetService,
      apiService: mockApiService,
    ));

    // Find the button by its key
    const buttonKey = Key('nativeCheckout');

    final buttonFinder = find.byKey(buttonKey);

    // Simulate a button click
    await tester.tap(buttonFinder);

    // Trigger a frame to rebuild the widget after the state has changed.
    await tester.pump();

    // Find the Text widget by its key
    const textKey = Key('result');

    find.byKey(textKey);

    expect(find.text(json.encode(result)),
        findsOneWidget); // Assuming the initial text is 'Initial Text'
  });

  testWidgets('Show flutter UI checkout', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp(
      bluesnapSdkPlugin: mockBluesnapSdk,
      assetService: mockAssetService,
      apiService: mockApiService,
    ));

    // Find the button by its key
    const buttonKey = Key('flutterCheckout');

    // Scroll until the widget is visible
    await tester.ensureVisible(
      find.byKey(buttonKey),
    );

    // Trigger a frame to rebuild the widget after the state has changed.
    await tester.pump();

    final buttonFinder = find.byKey(buttonKey);

    // Simulate a button click
    await tester.tap(buttonFinder);

    // Trigger a frame to rebuild the widget after the state has changed.
    await tester.pump();

    // Find the Text widget by its key
    const textKey = Key('result');

    find.byKey(textKey);

    expect(find.text(json.encode(result)),
        findsOneWidget); // Assuming the initial text is 'Initial Text'
  });
}

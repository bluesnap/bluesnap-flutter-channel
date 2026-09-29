import 'package:bluesnap_sdk/bluesnap_sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:bluesnap_sdk_example/main.dart' as app;

/// Device smoke test: launches the example app with the real plugin and checks
/// that the native plugin registered, loaded the BlueSnap SDK classes
/// (BlueSnapService.instance in the plugin constructor) and called back into
/// Dart with generateToken. Without sandbox credentials no token is issued, so
/// BlueSnapService.setup() is not reached.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('example app starts and native plugin requests a token',
      (WidgetTester tester) async {
    // Same singleton platform stream the app listens to; completes when the
    // native plugin's initBluesnap asks Dart for a token.
    final tokenRequested = BluesnapSdk().onGenerateToken.first;

    app.main();

    // initBluesnap runs in a post-frame callback behind a loading overlay whose
    // spinner never settles, so pump for a fixed time instead of pumpAndSettle.
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }

    expect(find.text('Plugin example app'), findsOneWidget);
    expect(find.byKey(const Key('nativeCheckout')), findsOneWidget);
    expect(find.byKey(const Key('flutterCheckout')), findsOneWidget);
    expect(
        await tokenRequested.timeout(const Duration(seconds: 10)), isA<Map>());
  });
}

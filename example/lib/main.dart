import 'dart:convert';
import 'dart:core';
import 'package:flutter/material.dart';
import 'package:bluesnap_sdk/bluesnap_sdk.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:dio/dio.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _bluesnapSdkPlugin = BluesnapSdk();
  final _dio = Dio();

  String? _result;

  @override
  void initState() {

    ///listen onGenerateToken in bluesnap native sdk
    _bluesnapSdkPlugin.onGenerateToken.listen((data) {
      Fluttertoast.showToast(
        msg: 'data: $data',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.blue,
        textColor: Colors.white,
      );

      getGenerateToken(Map<String, dynamic>.from(data));
    });

    ///init bluesnap
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      EasyLoading.show(status: 'loading...');

      try {
        await _bluesnapSdkPlugin.initBluesnap(
          bsToken: 'bsToken',
          initKount: true,
          fraudSessionId: '',
          applePayMerchantIdentifier: 'merchant.com.example.bluesnap',
          merchantStoreCurrency: 'USD',
        );
      } catch (e) {
        Fluttertoast.showToast(
          msg: 'error: $e',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
      EasyLoading.dismiss();
    });
    super.initState();
  }

  ///Create token to payment
  void getGenerateToken(Map<String, dynamic> data) async {
    String urlStr =
        'https://sandbox.bluesnap.com/services/2/payment-fields-tokens';

    final shopperID = data['shopperID'];
    if (shopperID != null) {
      urlStr += '?shopperId=$shopperID';
    }

    final credentials = await readCredentials();

    final credentialBase64 =
        stringToBase64('${credentials['username']}:${credentials['password']}');

    _dio.options.headers = {
      'Content-Type': 'text/xml',
      'Authorization': 'Basic $credentialBase64',
    };
    final response = await _dio.post(urlStr, data: '');

    final location = response.headers['location'];

    if (location != null) {
      final token = location.first.split('/').last;

      _bluesnapSdkPlugin.finalizeToken(token);
    }
  }

  /// Show check out payment in native UI
  Future<void> _showCheckout() async {
    EasyLoading.show(status: 'loading...');

    setState(() {
      _result = '';
    });

    try {
      await _bluesnapSdkPlugin.setSDKRequest(
        withEmail: false,
        withShipping: false,
        fullBilling: false,
        amount: 2.0,
        taxAmount: 1.1,
        currency: 'USD',
        activate3DS: true,
      );

      final result = await _bluesnapSdkPlugin.showCheckout();

      setState(() {
        _result = json.encode(result);
      });
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'error: $e',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }

    EasyLoading.dismiss();
  }

  ///Check out payment
  Future<void> _checkout(
    String cardNumber,
    String expirationDate,
    String cvv,
    String name,
    String billingZip,
    String? email,
  ) async {
    EasyLoading.show(status: 'loading...');

    setState(() {
      _result = '';
    });

    try {
      await _bluesnapSdkPlugin.setSDKRequest(
        withEmail: false,
        withShipping: false,
        fullBilling: false,
        amount: 2.0,
        taxAmount: 1.1,
        currency: 'USD',
        activate3DS: true,
      );

      final result = await _bluesnapSdkPlugin.checkoutCard(
        cardNumber: cardNumber.isEmpty ? '4000000000001026' : cardNumber,
        expirationDate: expirationDate.isEmpty ? '01/26' : expirationDate, //TODO: use the current year +3
        cvv: cvv.isEmpty ? '445' : cvv,
        name: name.isEmpty ? 'User Name' : name,
        billingZip: billingZip.isEmpty ? '4465' : billingZip,
        email: email,
      );

      setState(() {
        _result = json.encode(result);
      });
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'error: $e',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
    EasyLoading.dismiss();
  }

  ///Convert string to base64
  String stringToBase64(String input) {
    // Encode the input string to Base64
    List<int> bytes = utf8.encode(input); // Encode the string as UTF-8 bytes
    String base64String = base64.encode(bytes); // Convert bytes to Base64

    return base64String;
  }

  ///Read credentials file to generate token
  Future<Map<String, dynamic>> readCredentials() async {
    // Load the JSON file from the assets directory
    String jsonString = await rootBundle.loadString('assets/credentials.json');

    // Parse the JSON string into a Map or List
    Map<String, dynamic> jsonData = json.decode(jsonString);

    return jsonData;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Builder(builder: (context) {
          return Column(
            children: [
              const SizedBox(height: 50),
              const Text(
                'Native UI',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: ElevatedButton(
                  onPressed: () => _showCheckout(),
                  child: const SizedBox(
                    height: 40,
                    width: 200,
                    child: Center(
                      child: Text('Show checkout'),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 25),
              const Divider(),
              const SizedBox(height: 25),
              const Text(
                'Flutter Custom UI',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: SingleChildScrollView(
                  child: CheckOutCard(
                    result: _result,
                    onCheckout: (
                      String cardNumber,
                      String expirationDate,
                      String cvv,
                      String name,
                      String billingZip,
                      String? email,
                    ) async =>
                        _checkout(cardNumber, expirationDate, cvv, name,
                            billingZip, email),
                  ),
                ),
              ),
            ],
          );
        }),
      ),
      builder: EasyLoading.init(),
    );
  }
}

class CheckOutCard extends StatefulWidget {
  const CheckOutCard({super.key, this.onCheckout, this.result});
  final String? result;
  final Function(
    String cardNumber,
    String expirationDate,
    String cvv,
    String name,
    String billingZip,
    String? email,
  )? onCheckout;
  @override
  State<CheckOutCard> createState() => _CheckOutCardState();
}

class _CheckOutCardState extends State<CheckOutCard> {
  final _cardNumberController = TextEditingController();
  final _monthController = TextEditingController();
  final _yearController = TextEditingController();
  final _ccvController = TextEditingController();
  final _nameController = TextEditingController();
  final _billingZipController = TextEditingController();

  @override
  void dispose() {
    _cardNumberController.dispose();
    _monthController.dispose();
    _yearController.dispose();
    _ccvController.dispose();
    _nameController.dispose();
    _billingZipController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant CheckOutCard oldWidget) {
    if (widget.result != oldWidget.result) {
      setState(() {});
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: 50,
            child: TextField(
              maxLength: 16,
              controller: _cardNumberController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: 'cardNumber'),
            ),
          ),
          const Divider(),
          Row(
            children: [
              Expanded(
                flex: 1,
                child: SizedBox(
                  height: 50,
                  child: TextField(
                    maxLength: 2,
                    controller: _monthController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: 'month'),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 1,
                child: SizedBox(
                  height: 50,
                  child: TextField(
                    maxLength: 2,
                    controller: _yearController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: 'year'),
                  ),
                ),
              ),
              const Expanded(
                flex: 1,
                child: SizedBox(),
              ),
              Expanded(
                flex: 1,
                child: SizedBox(
                  height: 50,
                  child: TextField(
                    maxLength: 4,
                    controller: _ccvController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: 'ccv'),
                  ),
                ),
              ),
            ],
          ),
          const Divider(),
          SizedBox(
            height: 50,
            child: TextField(
              controller: _nameController,
              decoration: const InputDecoration(hintText: 'name'),
            ),
          ),
          const Divider(),
          SizedBox(
            height: 50,
            child: TextField(
              controller: _billingZipController,
              decoration: const InputDecoration(hintText: 'billingZip'),
            ),
          ),
          const SizedBox(height: 50),
          Center(
            child: ElevatedButton(
              onPressed: () async {
                widget.onCheckout?.call(
                  _cardNumberController.text,
                  _monthController.text.isEmpty || _yearController.text.isEmpty
                      ? ''
                      : '${_monthController.text}/${_yearController.text}',
                  _ccvController.text,
                  _nameController.text,
                  _billingZipController.text,
                  null,
                );
              },
              child: const SizedBox(
                height: 40,
                width: 200,
                child: Center(
                  child: Text('Checkout'),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (widget.result != null) Text(widget.result!)
        ],
      ),
    );
  }
}

import 'package:flutter/services.dart';

abstract class AssetService {
  Future<String> loadString(String asset);
}

class DefaultAssetService implements AssetService {
  @override
  Future<String> loadString(String asset) => rootBundle.loadString(asset);
}

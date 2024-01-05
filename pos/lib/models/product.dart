import 'package:flutter/foundation.dart';

class Product with ChangeNotifier {
  int _productId;
  String _productName;
  double _price;

  Product(int index, {
    required int productId,
    required String productName,
    required double price,
  })  : _productId = productId,
        _productName = productName,
        _price = price;

  int get productId => _productId;
  String get productName => _productName;
  double get price => _price;

  get name => null;

  get id => null;

  get stock => null;

  set productName(String newName) {
    _productName = newName;
    notifyListeners();
  }

  set price(double newPrice) {
    _price = newPrice;
    notifyListeners();
  }


}

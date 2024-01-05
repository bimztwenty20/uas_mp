import 'package:flutter/foundation.dart';

class Order with ChangeNotifier {
  int _orderId;
  String _customerName;
  List<Product> _products;

  Order({
    required int orderId,
    required String customerName,
    required List<Product> products,
  })  : _orderId = orderId,
        _customerName = customerName,
        _products = products;

  int get orderId => _orderId;
  String get customerName => _customerName;
  List<Product> get products => _products;

  get orders => null;

  set customerName(String newName) {
    _customerName = newName;
    notifyListeners();
  }

}

class Product {
  final String productName;
  final double price;

  Product(int index, {
    required this.productName,
    required this.price, required id, required name, required stock,
  });

  get name => null;

  get stock => null;

  get id => null;

  get quantity => null;
}

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Product {
  final String id;
  String name;
  int price;
  int stock;
  int hpp;
  int quantity;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
    required this.hpp,
    this.quantity = 1,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      price: json['price'],
      stock: json['stock'],
      hpp: json['hpp'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'stock': stock,
      'quantity': quantity,
    };
  }
}

class ProductSelectionPage extends StatefulWidget {
  final void Function(List<Product>) onProductsSelected;

  ProductSelectionPage({required this.onProductsSelected});

  @override
  _ProductSelectionPageState createState() => _ProductSelectionPageState();
}

class _ProductSelectionPageState extends State<ProductSelectionPage> {
  List<Product> availableProducts = [];
  List<Product> selectedProducts = [];

  @override
  void initState() {
    super.initState();
    _fetchAvailableProducts();
  }

  Future<void> _fetchAvailableProducts() async {
    try {
      final response = await http.get(
        Uri.parse('https://6559a7e96981238d054cc117.mockapi.io/product'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          availableProducts = data.map((item) => Product.fromJson(item)).toList();
          availableProducts = availableProducts.where((product) => product.stock > 0).toList();
        });
      } else {
        throw Exception('Failed to load products. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching available products: $e');
    }
  }

  Future<void> _removeProductsFromDatabase(List<Product> products) async {
    try {
      for (final product in products) {
        if (product.stock == 0) {
          await _deleteProductFromDatabase(product.id);
          // Remove the product from the UI
          setState(() {
            availableProducts.remove(product);
            selectedProducts.remove(product);
          });
        }
      }
    } catch (e) {
      print('Error removing products from the database: $e');
    }
  }

  Future<void> _deleteProductFromDatabase(String productId) async {
    try {
      final response = await http.delete(
        Uri.parse('https://6559a7e96981238d054cc117.mockapi.io/product/$productId'),
      );

      print('Delete response status code: ${response.statusCode}');
      print('Delete response body: ${response.body}');

      if (response.statusCode == 200) {
        print('Product successfully deleted from the database');
      } else {
        throw Exception('Failed to delete product. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error deleting product: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Product Selection'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Available Products',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: availableProducts.length,
                itemBuilder: (context, index) {
                  final product = availableProducts[index];
                  return Card(
                    elevation: 3,
                    margin: EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: Text(product.name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Price: ${product.price}'),
                          Text('Stock: ${product.stock}'),
                          Row(
                            children: [
                              Text('Quantity: '),
                              IconButton(
                                icon: Icon(Icons.remove),
                                onPressed: () {
                                  _updateQuantity(product, -1);
                                },
                              ),
                              Text('${product.quantity}'),
                              IconButton(
                                icon: Icon(Icons.add),
                                onPressed: () {
                                  _updateQuantity(product, 1);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          selectedProducts.contains(product)
                              ? Icons.check_circle
                              : Icons.add_circle,
                        ),
                        onPressed: () {
                          _toggleProductSelection(product);
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await _removeProductsFromDatabase(selectedProducts);
                widget.onProductsSelected(selectedProducts);
                Navigator.pop(context, selectedProducts);
              },
              child: Text('Done'),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleProductSelection(Product product) {
    setState(() {
      if (selectedProducts.contains(product)) {
        selectedProducts.remove(product);
      } else {
        if (product.stock > 0) {
          selectedProducts.add(product);
        }
      }
    });
  }

  void _updateQuantity(Product product, int change) {
    setState(() {
      final int newQuantity = product.quantity + change;

      if (newQuantity >= 0 && newQuantity <= product.stock) {
        product.quantity = newQuantity;
      }
    });
  }
}
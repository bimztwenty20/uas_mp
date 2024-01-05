import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'product_selection.dart';

class OrderProcessingPage extends StatefulWidget {
  @override
  _OrderProcessingPageState createState() => _OrderProcessingPageState();
}

class _OrderProcessingPageState extends State<OrderProcessingPage> {
  List<Product> selectedProducts = [];
  String selectedPaymentMethod = 'Cash';
  List<String> paymentMethods = ['Cash','Dana','QRIS'];

  @override
  void initState() {
    super.initState();
    _fetchPaymentMethods();
  }

  Future<void> _fetchPaymentMethods() async {
    final response = await http.get(Uri.parse('https://example.com/payment-methods'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      setState(() {
        paymentMethods = data.map((dynamic item) => item.toString()).toList();
      });
    } else {
      throw Exception('Failed to load payment methods');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order Processing'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Selected Products',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: selectedProducts.length,
                itemBuilder: (context, index) {
                  return Card(
                    elevation: 3,
                    margin: EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Name: ${selectedProducts[index].name}'),
                          Text('Price: ${selectedProducts[index].price}'),
                          Text('Quantity: ${selectedProducts[index].quantity}'),
                        ],
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () {
                          _removeProduct(index);
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _navigateAndSelectProducts(context);
              },
              child: Text('Select Products'),
            ),
            SizedBox(height: 16),
            _buildPaymentMethodOptions(),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _processOrder();
              },
              child: Text('Process Order'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Method',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        DropdownButton<String>(
          value: selectedPaymentMethod,
          onChanged: (String? value) {
            setState(() {
              selectedPaymentMethod = value!;
            });
          },
          items: paymentMethods.map((String method) {
            return DropdownMenuItem<String>(
              value: method,
              child: Text(method),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _removeProduct(int index) {
    setState(() {
      selectedProducts.removeAt(index);
    });
  }

  Future<void> _processOrder() async {
    if (selectedProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select products before processing the order.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    print('Processing order for selected products: $selectedProducts');
    bool canProcessOrder = true;

    for (final product in selectedProducts) {
      if (product.quantity > product.stock) {
        canProcessOrder = false;
        break;
      }
    }

    if (canProcessOrder) {
      final bool success = await _updateInventory(selectedProducts);

      if (success) {
        final int totalQuantity = calculateTotalOrderQuantity(selectedProducts);
        final int totalPrice = calculateTotalOrderAmount(selectedProducts);
        final List<String> productNames = getProductNames(selectedProducts);
        final int totalHPP = calculateTotalOrder(selectedProducts);
        final String? paymentMethod = await _saveSalesData(selectedProducts, totalQuantity, totalPrice, totalHPP);

        _showTotalOrderDialog(productNames, getProductQuantities(selectedProducts), totalQuantity, totalPrice, paymentMethod);

        setState(() {
          selectedProducts.clear();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order processed successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order processing failed. Please try again.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order processing failed. Insufficient stock.'),
          duration: Duration(seconds: 2),
        ),
      );
    }

    print('Selected Payment Method: $selectedPaymentMethod');
  }

  Future<bool> _updateInventory(List<Product> products) async {
    try {
      for (final product in products) {
        final response = await http.put(
          Uri.parse('https://6559a7e96981238d054cc117.mockapi.io/product/${product.id}'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'stock': product.stock - product.quantity,
          }),
        );

        if (response.statusCode == 200) {
          print('Stock updated for product ${product.id}');
        } else {
          throw Exception('Failed to update stock. Status code: ${response.statusCode}');
        }
      }

      return true;
    } catch (e) {
      print('Error updating stock: $e');
      return false;
    }
  }

  Future<String?> _saveSalesData(List<Product> products, int totalQuantity, int totalPrice, int totalHPP) async {
    try {
      final response = await http.post(
        Uri.parse('https://6559a7e96981238d054cc117.mockapi.io/sales'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'date': DateTime.now().toIso8601String(),
          'products': products.map((product) => {
            'productId': product.id,
            'productName': product.name,
            'quantitySold': product.quantity,
            'price': product.price,
            'hpp': product.hpp,
          }).toList(),
          'totalQuantity': totalQuantity,
          'totalPrice': totalPrice,
          'paymentMethod': selectedPaymentMethod,
        }),
      );

      if (response.statusCode == 201) {
        print('Sales data saved successfully');
        return selectedPaymentMethod;
      } else {
        throw Exception('Failed to save sales data. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error saving sales data: $e');
      return null;
    }
  }

  void _navigateAndSelectProducts(BuildContext context) async {
    final result = await Navigator.push<List<Product>>(
      context,
      MaterialPageRoute(
        builder: (context) => ProductSelectionPage(
          onProductsSelected: (selectedProducts) {
            setState(() {
              this.selectedProducts = selectedProducts;
            });
          },
        ),
      ),
    );

    if (result != null) {}
  }

  int calculateTotalOrderQuantity(List<Product> products) {
    int totalQuantity = 0;
    for (final product in products) {
      totalQuantity += product.quantity;
    }
    return totalQuantity;
  }

  int calculateTotalOrderAmount(List<Product> products) {
    int totalPrice = 0;
    for (final product in products) {
      totalPrice += (product.quantity * product.price);
    }
    return totalPrice;
  }

  int calculateTotalOrder(List<Product> products) {
    int totalHPP = 0;
    for (final product in products) {
      totalHPP += (product.quantity * product.hpp);
    }
    return totalHPP;
  }

  List<String> getProductNames(List<Product> products) {
    return products.map((product) => product.name).toList();
  }

  void _showTotalOrderDialog(List<String> productNames, List<int> productQuantities, int totalQuantity, int totalPrice, String? paymentMethod) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      DateTime now = DateTime.now();
      String formattedDate = "${now.day}-${now.month}-${now.year}";

      String storeName = "WarKun";

      return AlertDialog(
        title: Text('Invoice'),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$formattedDate'),
            Text('$storeName'),
            SizedBox(height: 10),
            Text('Products:'),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(productNames.length, (index) {
                return Text('- ${productNames[index]}     (${productQuantities[index]})');
              }),
            ),
            SizedBox(height: 10),
            Text('Total Quantity: $totalQuantity'),
            Text('Total Price: Rp$totalPrice'),
            Text('Payment Method: ${paymentMethod ?? 'N/A'}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Print'),
          ),
        ],
      );
    },
  );
}

}

List<int> getProductQuantities(List<Product> products) {
  return products.map((product) => product.quantity).toList();
}
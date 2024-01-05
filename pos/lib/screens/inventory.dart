import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Product {
  final String id;
  String name;
  int price;
  int stock;
  int hpp;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
    required this.hpp,

  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      price: json['price'],
      stock: json['stock'],
      hpp: json['hpp']
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'stock': stock,
      'hpp' : hpp,
    };
  }
}

class ProductForm extends StatefulWidget {
  final Product product;
  final void Function(Product) onSubmit;

  ProductForm({required this.product, required this.onSubmit});

  @override
  _ProductFormState createState() => _ProductFormState();
}

class _ProductFormState extends State<ProductForm> {
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;
  late TextEditingController _hppController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.name);
    _priceController = TextEditingController(text: widget.product.price.toString());
    _stockController = TextEditingController(text: widget.product.stock.toString());
    _hppController = TextEditingController(text: widget.product.hpp.toString());
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(labelText: 'Name'),
          ),
          TextField(
            controller: _priceController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'Price'),
          ),
          TextField(
            controller: _stockController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'Stock'),
          ),
          TextField(
            controller: _hppController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'HPP'),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              final updatedProduct = Product(
                id: widget.product.id,
                name: _nameController.text,
                price: int.parse(_priceController.text),
                stock: int.parse(_stockController.text),
                hpp: int.parse(_hppController.text),
              );
              widget.onSubmit(updatedProduct);
            },
            child: Text('Add'),
          ),
          SizedBox(height: 8),
           TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _hppController.dispose();
    super.dispose();
  }
}

class InventoryPage extends StatefulWidget {
  @override
  _InventoryPageState createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  List<Product> products = [];
  List<Product> filteredProducts = [];

  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchProducts().then((_) {
      print('Products fetched successfully in initState');
      filteredProducts = List.from(products);
    });
  }

  
  Future<void> _fetchProducts() async {
    try {
      final response = await http.get(Uri.parse('https://6559a7e96981238d054cc117.mockapi.io/product'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          products = data.map((item) => Product.fromJson(item)).toList();
          filteredProducts = List.from(products);
        });
      } else {
        throw Exception('Failed to load products. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching products: $e');
    }
  }

   Future<void> _addProductToDatabase(Product product) async {
  try {
    if (products.any((existingProduct) => existingProduct.name == product.name)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Product with the same name already exists.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final response = await http.post(
      Uri.parse('https://6559a7e96981238d054cc117.mockapi.io/product'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(product.toJson()),
    );
    if (response.statusCode == 201) {
      final Map<String, dynamic> data = json.decode(response.body);
      setState(() {
        products.add(Product.fromJson(data));
        filteredProducts = List.from(products); // Update filteredProducts
      });
    } else {
      throw Exception('Failed to add product. Status code: ${response.statusCode}');
    }
  } catch (e) {
    print('Error adding product: $e');
  }
}
  Future<void> _updateProductInDatabase(int index, String newName, int newStock, int newPrice, int newHPP) async {
  try {
    final product = products[index];
    final updatedProduct = Product(
      id: product.id,
      name: newName,
      price: newPrice,
      stock: newStock,
      hpp: newHPP,
    );

    if (newStock == 0) {
      await _deleteProductFromDatabase(index);
    } else {
      final response = await http.put(
        Uri.parse(
          'https://6559a7e96981238d054cc117.mockapi.io/product/${product.id}'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(updatedProduct.toJson()),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to update product. Status code: ${response.statusCode}');
      }
    }

    setState(() {
      if (newStock == 0) {
        products.removeAt(index);
      } else {
        products[index].name = newName;
        products[index].stock = newStock;
        products[index].price = newPrice;
        products[index].hpp = newHPP;
      }
    });
  } catch (e) {
    print('Error updating product: $e');
  }
}



  Future<void> _deleteProductFromDatabase(int index) async {
    try {
      final response = await http.delete(
        Uri.parse('https://6559a7e96981238d054cc117.mockapi.io/product/${products[index].id}'),
      );
      if (response.statusCode == 200) {
        setState(() {
          products.removeAt(index);
        });
      } else {
        throw Exception('Failed to delete product. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error deleting product: $e');
    }
  }

  void _addProduct() {
    final newProduct = Product(
      id: '',
      name: '',
      price: 0,
      stock: 0,
      hpp: 0
    );
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Product'),
          content: ProductForm(
            product: newProduct,
            onSubmit: (product) {
              _addProductToDatabase(product);
              Navigator.pop(context);
            },
          ),
        );
      },
    );
  }


  void _filterProducts(String query) {
  setState(() {
    filteredProducts = products.where((product) => 
      product.stock > 0 && 
      product.name.toLowerCase().contains(query.toLowerCase())
    ).toList();
  });
}

  void _editProduct(int index) {
    final product = products[index];
    TextEditingController nameController = TextEditingController(text: product.name);
    TextEditingController priceController = TextEditingController(text: product.price.toString());
    TextEditingController stockController = TextEditingController(text: product.stock.toString());
    TextEditingController hppController = TextEditingController(text: product.hpp.toString());
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Product'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Price'),
              ),
              TextField(
                controller: stockController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Stock'),
              ),
              TextField(
                controller: hppController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'HPP'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final newName = nameController.text;
                final newStock = int.parse(stockController.text);
                final newPrice = int.parse(priceController.text);
                final newHPP = int.parse(hppController.text);
                _updateProductInDatabase(index, newName, newStock, newPrice, newHPP);
                Navigator.pop(context);
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _deleteProduct(int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete Product'),
          content: Text('Are you sure you want to delete this product?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _deleteProductFromDatabase(index);
                Navigator.pop(context);
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Inventory'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            TextField(
              controller: searchController,
              onChanged: _filterProducts,
              decoration: InputDecoration(
                labelText: 'Search',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Product List',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: filteredProducts.length,
                itemBuilder: (context, index) {
                  return Card(
                    elevation: 3,
                    margin: EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Name: ${filteredProducts[index].name}'),
                          Text('Price: Rp${filteredProducts[index].price}'),
                          Text('Stock: ${filteredProducts[index].stock}'),
                          Text('HPP: Rp${filteredProducts[index].hpp}'),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () {
                              _editProduct(index);
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () {
                              _deleteProduct(index);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addProduct,
        child: Icon(Icons.add),
      ),
    );
  }
}
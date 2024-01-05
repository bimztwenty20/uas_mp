import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';

class SalesRecap {
  static Widget buildSalesTable(List<dynamic> salesData, DateTime fromDate, DateTime toDate) {
    final filteredSalesData = salesData.where((sale) {
      final saleDate = DateTime.parse(sale['date']);
      return saleDate.isAfter(fromDate) && saleDate.isBefore(toDate);
    }).toList();

    int totalQuantitySold = 0;
    int totalPrice = 0;
    int totalHPP = 0;
    int totalProfit = 0;

    Map<String, int> productFrequency = {};

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DataTable(
            columns: [
              DataColumn(label: Text('Date')),
              DataColumn(label: Text('Sale ID')),
              DataColumn(label: Text('Products')),
              DataColumn(label: Text('Total Item')),
              DataColumn(label: Text('Total Quantity')),
              DataColumn(label: Text('Total Price')),
              DataColumn(label: Text('Total HPP')),        
              DataColumn(label: Text('Payment Method')),
            ],
            rows: filteredSalesData.map<DataRow>((sale) {
              final List<dynamic> products = sale['products'];

              int saleQuantitySold = 0;
              int saleTotalPrice = 0;
              int saleTotalHPP = 0;
              List<String> productNames = [];
              List<int> quantityProduct = [];
              Set<String> uniqueProducts = Set();

              for (final product in products) {
                final String productName = product['productName'] as String;
                final int quantitySold = product['quantitySold'] as int;
                final int price = product['price'] as int;
                final int hpp = product['hpp'] as int;

                saleQuantitySold += quantitySold;
                saleTotalPrice += quantitySold * price;
                saleTotalHPP += quantitySold * hpp;

                productNames.add(productName);
                quantityProduct.add(quantitySold);
                uniqueProducts.add(productName);

                productFrequency[productName] = (productFrequency[productName] ?? 0) + quantitySold;
              }

              totalQuantitySold += saleQuantitySold;
              totalPrice += saleTotalPrice;
              totalHPP += saleTotalHPP;
              totalProfit += (saleTotalPrice - saleTotalHPP);

              return DataRow(
                cells: [
                  DataCell(Text(sale['date'])),
                  DataCell(Text(sale['saleId'].toString())), 
                  DataCell(
                    SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (int i = 0; i < productNames.length; i++)
                            Text('${productNames[i]}: ${quantityProduct[i]}'),
                        ],
                      ),
                    ),
                  ),
                  DataCell(Text('${uniqueProducts.length}')),
                  DataCell(Text(saleQuantitySold.toString())),
                  DataCell(Text('\Rp$saleTotalPrice')),
                  DataCell(Text('\Rp$saleTotalHPP')),
                  DataCell(Text(sale['paymentMethod'])),
                ],
              );
            }).toList(),
          ),
          SizedBox(height: 25),
          Text(
            'Most Sold Product: ${getMostSoldProduct(productFrequency)}',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),
          Text(
            'Total Quantity Sold: $totalQuantitySold',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),
          Text(
            'Total Price: \Rp$totalPrice',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),
          Text(
            'Total HPP: \Rp$totalHPP',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),
          Text(
            'Total Profit: \Rp$totalProfit',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),

        ],
      ),
    );
  }

  static String getMostSoldProduct(Map<String, int> productFrequency) {
    if (productFrequency.isEmpty) {
      return 'No sales data available';
    }

    String mostSoldProduct = productFrequency.keys.first;
    int maxFrequency = productFrequency[mostSoldProduct] ?? 0;

    productFrequency.forEach((product, frequency) {
      if (frequency > maxFrequency) {
        mostSoldProduct = product;
        maxFrequency = frequency;
      }
    });

    return mostSoldProduct;
  }


  static Future<List<dynamic>> _fetchSalesData() async {
    try {
      final responseSales = await http.get(
        Uri.parse('https://6559a7e96981238d054cc117.mockapi.io/sales'),
      );

      final responseInventory = await http.get(
        Uri.parse('https://6559a7e96981238d054cc117.mockapi.io/product'),
      );

      if (responseSales.statusCode == 200 && responseInventory.statusCode == 200) {
        final List<dynamic> salesData = json.decode(responseSales.body);
        final List<dynamic> inventoryData = json.decode(responseInventory.body);

        final Map<String, int> hppMap = {};

        for (final inventoryItem in inventoryData) {
          final String productId = inventoryItem['id'];
          final int hpp = inventoryItem['hpp'];
          hppMap[productId] = hpp;
        }

        for (final sale in salesData) {
          final List<dynamic> products = sale['products'];

          for (final product in products) {
            final String productId = product['productId'];
            final int hpp = hppMap[productId] ?? 0;
            product['hpp'] = hpp;
          }
        }

        return salesData;
      } else {
        throw Exception(
            'Failed to fetch sales or inventory data. Status codes: ${responseSales.statusCode}, ${responseInventory.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching sales or inventory data: $e');
    }
  }
}

class SalesPage extends StatefulWidget {
  @override
  _SalesPageState createState() => _SalesPageState();
}

class _SalesPageState extends State<SalesPage> {
  DateTime fromDate = DateTime.now().subtract(Duration(days: 7));
  DateTime toDate = DateTime.now();
  String selectedPaymentMethod = 'All';


  static Future<void> _downloadPDF(List<dynamic> salesData) async {
  final pdf = pw.Document();
  pdf.addPage(
    pw.MultiPage(
      build: (context) => [
        pw.Table.fromTextArray(
          headers: ['Date', 'Sale ID', 'Products', 'Total Item', 'Total Quantity', 'Total Price', 'Total HPP', 'Payment Method'],
          data: salesData.map((sale) => [
            sale['date'].toString(),
            sale['saleId'].toString(),
            sale['products'].map<String>((product) => product['productName'] as String).join('\n'),
            sale['item'].toString(),
            sale['totalQuantity'].toString(),      
            'Rp${sale['totalPrice']}',
            'Rp${sale['totalHPP']}',
            sale['paymentMethod'].toString(),
          ]).toList(),
        ),
      ],
    ),
  );

  final directory = await getExternalStorageDirectory();
  final file = File('${directory?.path}/sales_recap.pdf');
  await file.writeAsBytes(await pdf.save());

  OpenFile.open(file.path);
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sales Recap'),
        actions: [
          IconButton(
            icon: Icon(Icons.download),
            onPressed: () async {
              final salesData = await SalesRecap._fetchSalesData();
              await _downloadPDF(salesData);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Text('From:'),
                SizedBox(width: 8),
                TextButton(
                  onPressed: () async {
                    final selectedDate = await showDatePicker(
                      context: context,
                      initialDate: fromDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );

                    if (selectedDate != null && selectedDate != fromDate) {
                      setState(() {
                        fromDate = selectedDate;
                      });
                    }
                  },
                  child: Text('${fromDate.toLocal()}'.split(' ')[0]),
                ),
                SizedBox(width: 16),
                Text('To:'),
                SizedBox(width: 8),
                TextButton(
                  onPressed: () async {
                    final selectedDate = await showDatePicker(
                      context: context,
                      initialDate: toDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );

                    if (selectedDate != null && selectedDate != toDate) {
                      setState(() {
                        toDate = selectedDate;
                      });
                    }
                  },
                  child: Text('${toDate.toLocal()}'.split(' ')[0]),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Text('Payment Method:'),
                SizedBox(width: 8),
                DropdownButton<String>(
                  value: selectedPaymentMethod,
                  items: ['All', 'Cash', 'Dana', 'QRIS'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedPaymentMethod = newValue ?? 'All';
                    });
                  },
                ),
              ],
            ),
            SizedBox(height: 16),
            FutureBuilder(
              future: SalesRecap._fetchSalesData(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else {
                  final List<dynamic> salesData = snapshot.data as List<dynamic>;

                  final filteredSalesData = selectedPaymentMethod == 'All'
                      ? salesData
                      : salesData
                          .where((sale) => sale['paymentMethod'] == selectedPaymentMethod)
                          .toList();

                  return SalesRecap.buildSalesTable(filteredSalesData, fromDate, toDate);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

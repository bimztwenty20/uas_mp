import 'package:flutter/material.dart';
import 'package:connectivity/connectivity.dart';
import 'screens/home.dart';
import 'screens/login.dart';
import 'screens/sales.dart';
import 'screens/order_processing.dart';
import 'screens/inventory.dart';
import 'offline_mode.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'POS System',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: LoginPage(),
      routes: {
        '/login': (context) => LoginPage(),
        '/home': (context) => ConnectivityWrapper(
          onlineChild: HomePage(),
          offlineChild: OfflineModePage(),
        ),
        '/sales': (context) => ConnectivityWrapper(
          onlineChild: SalesPage(),
          offlineChild: OfflineModePage(),
        ),
        '/inventory': (context) => ConnectivityWrapper(
          onlineChild: InventoryPage(),
          offlineChild: OfflineModePage(),
        ),
        '/order_processing': (context) => ConnectivityWrapper(
          onlineChild: OrderProcessingPage(),
          offlineChild: OfflineModePage(),
        ),
      },
    );
  }
}

class ConnectivityWrapper extends StatefulWidget {
  final Widget onlineChild;
  final Widget offlineChild;

  ConnectivityWrapper({required this.onlineChild, required this.offlineChild});

  @override
  _ConnectivityWrapperState createState() => _ConnectivityWrapperState();
}

class _ConnectivityWrapperState extends State<ConnectivityWrapper> {
  late bool isOnline;

  @override
  void initState() {
    super.initState();
    isOnline = true;
    checkConnectivity();
    Connectivity().onConnectivityChanged.listen((result) {
      setState(() {
        isOnline = result != ConnectivityResult.none;
      });
    });
  }

  Future<void> checkConnectivity() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      isOnline = connectivityResult != ConnectivityResult.none;
    });
  }

  @override
  Widget build(BuildContext context) {
    return isOnline ? widget.onlineChild : widget.offlineChild;
  }
}

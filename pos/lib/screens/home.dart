import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'POS',
              style: TextStyle(
                fontSize: 50,
              ),
            ),
            SizedBox(height: 10), 
            Text(
              'Point Of Sales',
              style: TextStyle(
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'POS System',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              title: Text('Sales'),
              onTap: () {
                Navigator.pushNamed(context, '/sales');
              },
            ),
            ListTile(
              title: Text('Inventory'),
              onTap: () {
                Navigator.pushNamed(context, '/inventory');
              },
            ),
            ListTile(
              title: Text('Order Processing'),
              onTap: () {
                Navigator.pushNamed(context, '/order_processing');
              },
            ),
            ListTile(
              title: Text('Logout'),
              onTap: () {
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        ),
      ),
    );
  }
}

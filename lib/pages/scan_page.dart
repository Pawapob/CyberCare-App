import 'package:flutter/material.dart';

class ScanPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Scan")),
      body: Center(
        child: Text(
          "This is the Scan Page",
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}

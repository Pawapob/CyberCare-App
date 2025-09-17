import 'package:flutter/material.dart';

class MyAppsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("My Apps")),
      body: Center(
        child: Text(
          "This is the My Apps Page",
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}

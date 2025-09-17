import 'package:flutter/material.dart';

class NotificationsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Notifications")),
      body: Center(
        child: Text(
          "This is the Notifications Page",
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}

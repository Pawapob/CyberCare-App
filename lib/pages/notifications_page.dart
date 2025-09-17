import 'package:flutter/material.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Icon(Icons.search),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilterChip(label: Text("All"), onSelected: (_) {}, selected: true),
              SizedBox(width: 8),
              FilterChip(label: Text("Read only"), onSelected: (_) {}, selected: false),
              SizedBox(width: 8),
              FilterChip(label: Text("Unread only"), onSelected: (_) {}, selected: false),
            ],
          ),
          const SizedBox(height: 32),
          const Center(child: Text("No notification yet")),
        ],
      ),
    );
  }
}

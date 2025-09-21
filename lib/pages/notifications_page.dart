import 'package:flutter/material.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Notifications")),
      body: Column(
        children: [
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilterChip(label: const Text("All"), onSelected: (_) {}, selected: true),
              const SizedBox(width: 8),
              FilterChip(label: const Text("Read only"), onSelected: (_) {}, selected: false),
              const SizedBox(width: 8),
              FilterChip(label: const Text("Unread only"), onSelected: (_) {}, selected: false),
            ],
          ),
          const SizedBox(height: 40),
          const Center(child: Text("No notification yet")),
        ],
      ),
    );
  }
}

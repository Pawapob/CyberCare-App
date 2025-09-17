import 'package:flutter/material.dart';

class MyAppsPage extends StatelessWidget {
  const MyAppsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Application")),
      body: Column(
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Hinted search text",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                filled: true,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilterChip(label: Text("All"), onSelected: (_) {}, selected: true),
              SizedBox(width: 8),
              FilterChip(label: Text("Alerts On"), onSelected: (_) {}, selected: false),
              SizedBox(width: 8),
              FilterChip(label: Text("Alerts Off"), onSelected: (_) {}, selected: false),
            ],
          ),
          const SizedBox(height: 32),
          const Center(child: Text("There is no app\nyou have to scan first", textAlign: TextAlign.center)),
        ],
      ),
    );
  }
}

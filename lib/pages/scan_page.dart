import 'package:flutter/material.dart';

class ScanPage extends StatelessWidget {
  const ScanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan")),
      body: Column(
        children: [
          const SizedBox(height: 16),
          const Text("App list scan only — no files or personal data are checked"),
          const SizedBox(height: 32),
          Center(
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(40),
                shape: const CircleBorder(),
              ),
              child: const Text("SCAN", style: TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(height: 32),
          ListTile(
            title: const Text("Recently installed"),
            trailing: TextButton(onPressed: () {}, child: const Text("View all")),
            subtitle: const Text("Not yet scanned"),
          )
        ],
      ),
    );
  }
}

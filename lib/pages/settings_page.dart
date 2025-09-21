import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _selectedLang = "English";
  bool _alertEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: ListView(
        children: [
          ListTile(
            title: const Text("Language"),
            subtitle: Text(_selectedLang),
            trailing: DropdownButton<String>(
              value: _selectedLang,
              items: const [
                DropdownMenuItem(value: "English", child: Text("English")),
                DropdownMenuItem(value: "ไทย", child: Text("ไทย")),
              ],
              onChanged: (val) {
                setState(() {
                  _selectedLang = val!;
                });
              },
            ),
          ),
          SwitchListTile(
            title: const Text("Alerts"),
            subtitle: const Text("Enable or disable notifications"),
            value: _alertEnabled,
            onChanged: (val) {
              setState(() {
                _alertEnabled = val;
              });
            },
          ),
        ],
      ),
    );
  }
}

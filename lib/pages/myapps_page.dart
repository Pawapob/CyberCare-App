import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

// ====== ENUM ======
enum AlertStatus { on, off }

class AppItem {
  final String id;
  final String name;
  final DateTime installedAt;
  final AlertStatus alertStatus;
  final String? icon;

  const AppItem({
    required this.id,
    required this.name,
    required this.installedAt,
    required this.alertStatus,
    this.icon,
  });
}

enum _MyAppsTab { all, alertOn, alertOff }

class MyAppsPage extends StatefulWidget {
  const MyAppsPage({super.key});

  @override
  State<MyAppsPage> createState() => _MyAppsPageState();
}

class _MyAppsPageState extends State<MyAppsPage> {
  List<AppItem> apps = [];
  _MyAppsTab _tab = _MyAppsTab.all;

  @override
  void initState() {
    super.initState();
    loadAppsFromCache();
  }

  Future<void> loadAppsFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString("recent_apps");
    if (cachedData != null) {
      final List decoded = jsonDecode(cachedData);
      setState(() {
        apps = decoded.map<AppItem>((a) {
          final installedTime = a["installed_time"] ?? 0;
          return AppItem(
            id: a["package_name"] ?? "",
            name: a["app_name"] ?? "",
            installedAt: DateTime.fromMillisecondsSinceEpoch(installedTime),
            alertStatus: AlertStatus.on,
            icon: a["icon"],
          );
        }).toList();
      });
    }
  }

  List<AppItem> byTab() {
    switch (_tab) {
      case _MyAppsTab.alertOn:
        return apps.where((a) => a.alertStatus == AlertStatus.on).toList();
      case _MyAppsTab.alertOff:
        return apps.where((a) => a.alertStatus == AlertStatus.off).toList();
      default:
        return apps;
    }
  }

  // ✅ อัปเดตสถานะใน backend
  Future<void> updateAlertStatus(String packageName, String alertStatus) async {
    final prefs = await SharedPreferences.getInstance();
    final deviceId = prefs.getString("device_id");
    if (deviceId == null) return;

    final url = Uri.parse("http://10.0.2.2:5000/update_alert_status");
    final body = jsonEncode({
      "device_id": deviceId,
      "package_name": packageName,
      "alert_status": alertStatus,
    });

    try {
      final res = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );
      print("Update status response: ${res.body}");
    } catch (e) {
      print("Error updating alert status: $e");
    }
  }

  void toggle(AppItem app) async {
    final newStatus =
    app.alertStatus == AlertStatus.on ? AlertStatus.off : AlertStatus.on;

    setState(() {
      final i = apps.indexWhere((e) => e.id == app.id);
      if (i != -1) {
        apps[i] = AppItem(
          id: app.id,
          name: app.name,
          installedAt: app.installedAt,
          alertStatus: newStatus,
          icon: app.icon,
        );
      }
    });

    await updateAlertStatus(app.id, newStatus == AlertStatus.on ? "on" : "off");
  }

  @override
  Widget build(BuildContext context) {
    final items = byTab();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('My Applications',
            style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          // Filter Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _FilterChip(
                  label: 'All',
                  selected: _tab == _MyAppsTab.all,
                  onTap: () => setState(() => _tab = _MyAppsTab.all),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Alerts On',
                  selected: _tab == _MyAppsTab.alertOn,
                  onTap: () => setState(() => _tab = _MyAppsTab.alertOn),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Alerts Off',
                  selected: _tab == _MyAppsTab.alertOff,
                  onTap: () => setState(() => _tab = _MyAppsTab.alertOff),
                ),
              ],
            ),
          ),

          Expanded(
            child: apps.isEmpty
                ? const Center(
              child: Text(
                "No apps found\nTry scanning first",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
            )
                : ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) =>
              const Divider(height: 1, color: Colors.black12),
              itemBuilder: (context, i) {
                final app = items[i];
                final daysAgo =
                    DateTime.now().difference(app.installedAt).inDays;

                return ListTile(
                  leading: (app.icon != null)
                      ? Image.memory(base64Decode(app.icon!),
                      width: 40, height: 40)
                      : const Icon(Icons.android, color: Colors.green),
                  title: Text(app.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w500, fontSize: 15)),
                  subtitle: Text('Installed $daysAgo days ago',
                      style: const TextStyle(
                          fontSize: 12, color: Colors.black45)),
                  trailing: Switch(
                    value: app.alertStatus == AlertStatus.on,
                    onChanged: (_) => toggle(app),
                    activeColor: Colors.white,
                    activeTrackColor: Colors.blue,
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: Colors.grey,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      labelStyle: TextStyle(
        color: Colors.black87,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
      ),
      backgroundColor: Colors.grey.shade200,
      selectedColor: Colors.blue.shade100,
      side: BorderSide(color: selected ? Colors.blue : Colors.black12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}

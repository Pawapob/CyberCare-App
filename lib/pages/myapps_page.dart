import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../language_provider.dart';

// ===================== Localized Strings =====================
Map<String, Map<String, String>> myAppsStrings = {
  "en": {
    "title": "My Applications",
    "searchHint": "Hinted search text",
    "all": "All",
    "alertsOn": "Alerts On",
    "alertsOff": "Alerts Off",
    "openAll": "Open All",
    "closeAll": "Close All",
    "noApps": "No apps found\nTry scanning first",
    "installedDaysAgo": "Installed {days} days ago",
    "installedToday": "Installed today",
    "installedYesterday": "Installed yesterday",
  },
  "th": {
    "title": "แอปของฉัน",
    "searchHint": "ค้นหาแอป...",
    "all": "ทั้งหมด",
    "alertsOn": "เปิดแจ้งเตือน",
    "alertsOff": "ปิดแจ้งเตือน",
    "openAll": "เปิดทั้งหมด",
    "closeAll": "ปิดทั้งหมด",
    "noApps": "ไม่พบแอป\nโปรดลองสแกนก่อน",
    "installedDaysAgo": "ติดตั้งเมื่อ {days} วันที่แล้ว",
    "installedToday": "ติดตั้งวันนี้",
    "installedYesterday": "ติดตั้งเมื่อวานนี้",
  }
};

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

  AppItem copyWith({AlertStatus? alertStatus}) {
    return AppItem(
      id: id,
      name: name,
      installedAt: installedAt,
      alertStatus: alertStatus ?? this.alertStatus,
      icon: icon,
    );
  }
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
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    loadAppsFromCache();
  }

  // ✅ โหลดข้อมูลแอปจาก SharedPreferences + ดึงสถานะจริงจาก DB
  Future<void> loadAppsFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString("recent_apps");
    final deviceId = prefs.getString("device_id");

    if (cachedData == null || deviceId == null) return;

    final List decoded = jsonDecode(cachedData);
    final url =
    Uri.parse("http://10.0.2.2:5000/get_alert_status?device_id=$deviceId");

    try {
      final res = await http.get(url);
      Map<String, String> statusMap = {};
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        for (var d in data) {
          statusMap[d["package_name"]] = d["alert_status"];
        }
      }

      setState(() {
        apps = decoded.map<AppItem>((a) {
          final pkg = a["package_name"] ?? "";
          final installedTime = a["installed_time"] ?? 0;
          final status = statusMap[pkg] == "off"
              ? AlertStatus.off
              : AlertStatus.on;

          return AppItem(
            id: pkg,
            name: a["app_name"] ?? "",
            installedAt: DateTime.fromMillisecondsSinceEpoch(installedTime),
            alertStatus: status,
            icon: a["icon"],
          );
        }).toList();
      });
    } catch (e) {
      print("Error loading apps: $e");
    }
  }

  List<AppItem> byTab() {
    List<AppItem> filtered = [];
    switch (_tab) {
      case _MyAppsTab.alertOn:
        filtered = apps.where((a) => a.alertStatus == AlertStatus.on).toList();
        break;
      case _MyAppsTab.alertOff:
        filtered = apps.where((a) => a.alertStatus == AlertStatus.off).toList();
        break;
      default:
        filtered = apps;
    }

    if (searchQuery.isNotEmpty) {
      filtered = filtered
          .where((a) => a.name.toLowerCase().contains(searchQuery.toLowerCase()))
          .toList();
    }
    return filtered;
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
      final res = await http.post(url,
          headers: {"Content-Type": "application/json"}, body: body);
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
      if (i != -1) apps[i] = apps[i].copyWith(alertStatus: newStatus);
    });

    await updateAlertStatus(app.id, newStatus == AlertStatus.on ? "on" : "off");
  }

  Future<void> toggleAll(bool turnOn) async {
    final items = byTab();
    for (final app in items) {
      final newStatus = turnOn ? AlertStatus.on : AlertStatus.off;
      await updateAlertStatus(app.id, turnOn ? "on" : "off");
      setState(() {
        final i = apps.indexWhere((e) => e.id == app.id);
        if (i != -1) apps[i] = apps[i].copyWith(alertStatus: newStatus);
      });
    }
  }

  String installedText(int daysAgo, Map<String, String> text) {
    if (daysAgo == 0) return text["installedToday"]!;
    if (daysAgo == 1) return text["installedYesterday"]!;
    return text["installedDaysAgo"]!.replaceAll("{days}", daysAgo.toString());
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context).lang;
    final text = myAppsStrings[lang]!;
    final items = byTab();
    final showBulkButtons =
        _tab == _MyAppsTab.alertOn || _tab == _MyAppsTab.alertOff;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(text["title"]!,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: TextField(
              decoration: InputDecoration(
                hintText: text["searchHint"]!,
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding:
                const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none),
              ),
              onChanged: (val) => setState(() => searchQuery = val),
            ),
          ),

          // Filter Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _FilterChip(
                    label: text["all"]!,
                    selected: _tab == _MyAppsTab.all,
                    onTap: () => setState(() => _tab = _MyAppsTab.all)),
                const SizedBox(width: 8),
                _FilterChip(
                    label: text["alertsOn"]!,
                    selected: _tab == _MyAppsTab.alertOn,
                    onTap: () => setState(() => _tab = _MyAppsTab.alertOn)),
                const SizedBox(width: 8),
                _FilterChip(
                    label: text["alertsOff"]!,
                    selected: _tab == _MyAppsTab.alertOff,
                    onTap: () => setState(() => _tab = _MyAppsTab.alertOff)),
              ],
            ),
          ),

          Expanded(
            child: apps.isEmpty
                ? Center(
              child: Text(text["noApps"]!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black54)),
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
                  subtitle: Text(installedText(daysAgo, text),
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

          // ✅ ปุ่ม Open All / Close All
          if (showBulkButtons)
            SafeArea(
              child: Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    if (_tab == _MyAppsTab.alertOn)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => toggleAll(false),
                          style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.blue,
                              side: const BorderSide(color: Colors.blue),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              padding:
                              const EdgeInsets.symmetric(vertical: 14)),
                          child: Text(text["closeAll"]!),
                        ),
                      ),
                    if (_tab == _MyAppsTab.alertOff)
                      Expanded(
                        child: FilledButton(
                          onPressed: () => toggleAll(true),
                          style: FilledButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              padding:
                              const EdgeInsets.symmetric(vertical: 14)),
                          child: Text(text["openAll"]!),
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ===================== Filter Chip Widget =====================
class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      labelStyle: TextStyle(
          color: Colors.black87,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500),
      backgroundColor: Colors.grey.shade200,
      selectedColor: Colors.blue.shade100,
      side: BorderSide(color: selected ? Colors.blue : Colors.black12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}

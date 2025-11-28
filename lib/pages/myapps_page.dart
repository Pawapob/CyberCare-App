import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import '../language_provider.dart';
import '../config.dart'; // 🔥 1. Import ไฟล์ Config

// ===================== Localized Strings =====================
Map<String, Map<String, String>> myAppsStrings = {
  "en": {
    "title": "My Applications",
    "searchHint": "Type to search apps",
    "all": "All",
    "alertsOn": "Alerts On",
    "alertsOff": "Alerts Off",
    "openAll": "Open All",
    "closeAll": "Close All",
    "noApps": "No apps found\nTry scanning first",
    "installedDaysAgo": "Installed {days} days ago",
    "installedToday": "Installed today",
    "installedYesterday": "Installed yesterday",
    "tutorialSearchTitle": "Search Apps",
    "tutorialSearchDesc": "Type here to quickly find specific applications in your list.",
    "tutorialSwitchTitle": "Control Alerts",
    "tutorialSwitchDesc": "Toggle this switch to Enable or Disable security notifications for this specific app.",
    "tutorialSkip": "SKIP",
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
    "tutorialSearchTitle": "ค้นหาแอปพลิเคชัน",
    "tutorialSearchDesc": "พิมพ์ชื่อแอปตรงนี้เพื่อค้นหาแอปที่คุณต้องการอย่างรวดเร็ว",
    "tutorialSwitchTitle": "จัดการการแจ้งเตือน",
    "tutorialSwitchDesc": "กดที่สวิตช์นี้เพื่อ เปิด หรือ ปิด การแจ้งเตือนสำหรับแอปนี้",
    "tutorialSkip": "ข้าม",
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

class _MyAppsPageState extends State<MyAppsPage> with WidgetsBindingObserver {
  List<AppItem> apps = [];
  _MyAppsTab _tab = _MyAppsTab.all;
  String searchQuery = "";

  // Keys for tutorial focus
  final GlobalKey searchBarKey = GlobalKey();
  final GlobalKey firstSwitchKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    loadAppsFromCache();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      loadAppsFromCache();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void markTutorialAsSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenMyAppsTutorial', true);
  }

  void checkTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    bool hasSeen = prefs.getBool('hasSeenMyAppsTutorial') ?? false;
    if (!hasSeen && apps.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) showTutorial();
      });
    }
  }

  void showTutorial() {
    final lang = Provider.of<LanguageProvider>(context, listen: false).lang;
    final text = myAppsStrings[lang]!;

    TutorialCoachMark(
      targets: [
        TargetFocus(
          identify: "SearchBar",
          keyTarget: searchBarKey,
          shape: ShapeLightFocus.RRect,
          radius: 20,
          contents: [
            TargetContent(
              align: ContentAlign.bottom,
              builder: (context, controller) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(text["tutorialSearchTitle"]!,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Text(text["tutorialSearchDesc"]!,
                        style: const TextStyle(color: Colors.white, fontSize: 16)),
                  ],
                );
              },
            ),
          ],
        ),
        TargetFocus(
          identify: "AlertSwitch",
          keyTarget: firstSwitchKey,
          shape: ShapeLightFocus.Circle,
          alignSkip: Alignment.topLeft,
          contents: [
            TargetContent(
              align: ContentAlign.left,
              builder: (context, controller) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(text["tutorialSwitchTitle"]!,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Text(text["tutorialSwitchDesc"]!,
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                        textAlign: TextAlign.right),
                  ],
                );
              },
            ),
          ],
        ),
      ],
      colorShadow: Colors.black,
      textSkip: myAppsStrings[Provider.of<LanguageProvider>(context, listen: false).lang]!["tutorialSkip"]!,
      paddingFocus: 10,
      opacityShadow: 0.85,
      onFinish: () => markTutorialAsSeen(),
      onSkip: () {
        markTutorialAsSeen();
        return true;
      },
    ).show(context: context);
  }

  // ===== Helper: read backend base URL =====
  Future<String> readBaseUrl() async {
    // 🔥 2. แก้ให้ใช้ URL จาก Config
    return Config.baseUrl;
  }

  // Load apps from SharedPreferences
  Future<void> loadAppsFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString("recent_apps");
    final deviceId = prefs.getString("device_id");

    if (cachedData == null || deviceId == null) {
      if (mounted) {
        setState(() {
          apps = [];
        });
      }
      return;
    }

    final List decoded = jsonDecode(cachedData);

    // 🔥 3. แก้ไขจุดนี้: อ่านค่า alert_status ที่บันทึกไว้ แทนที่จะบังคับ On
    final List<AppItem> localList = decoded.map<AppItem>((a) {
      final pkg = a["package_name"] ?? "";
      final installedTime = (a["installed_time"] ?? 0) as int;

      // อ่านค่าเดิมจาก Cache ถ้าไม่มีให้เป็น "on"
      final savedStatus = a["alert_status"] ?? "on";

      return AppItem(
        id: pkg,
        name: a["app_name"] ?? pkg,
        installedAt: DateTime.fromMillisecondsSinceEpoch(installedTime),
        // แปลงค่าเป็น Enum
        alertStatus: savedStatus == "off" ? AlertStatus.off : AlertStatus.on,
        icon: a["icon"],
      );
    }).toList();

    if (!mounted) return;
    setState(() {
      apps = localList;
    });

    // fetch actual alert status in background (Sync ข้อมูลกับ Server)
    try {
      final baseUrl = await readBaseUrl();
      final url = Uri.parse("$baseUrl/get_alert_status?device_id=$deviceId");

      // เพิ่ม Header Ngrok กันเหนียว
      final res = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "ngrok-skip-browser-warning": "true",
        },
      ).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        Map<String, String> statusMap = {};
        for (var d in data) {
          if (d is Map && d.containsKey("package_name")) {
            statusMap[d["package_name"]] = d["alert_status"] ?? "on";
          }
        }

        // อัปเดตข้อมูลใหม่จาก Server แล้วเซฟทับลง Cache ทันที
        final updatedApps = apps.map((app) {
          final status = statusMap[app.id] == "off" ? AlertStatus.off : AlertStatus.on;
          return app.copyWith(alertStatus: status);
        }).toList();

        if (!mounted) return;
        setState(() {
          apps = updatedApps;
        });

        // 🔥 บันทึก Cache ล่าสุดลงเครื่องทันที
        final List<Map<String, dynamic>> toCache = updatedApps.map((app) {
          var originalItem = decoded.firstWhere((element) => element['package_name'] == app.id, orElse: () => {});
          originalItem['alert_status'] = app.alertStatus == AlertStatus.on ? "on" : "off";
          return originalItem as Map<String, dynamic>;
        }).toList();

        await prefs.setString("recent_apps", jsonEncode(toCache));

      } else {
        debugPrint("get_alert_status returned ${res.statusCode}");
      }
    } catch (e) {
      debugPrint("Error fetching alert status: $e");
    }

    checkTutorial();
  }

  List<AppItem> byTab() {
    List<AppItem> filtered;
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

  // Update alert status on backend and update local cache
  Future<bool> updateAlertStatus(String packageName, String alertStatus) async {
    final prefs = await SharedPreferences.getInstance();
    final deviceId = prefs.getString("device_id");
    if (deviceId == null) return false;

    try {
      final baseUrl = await readBaseUrl();
      final url = Uri.parse("$baseUrl/update_alert_status");
      final body = jsonEncode({
        "device_id": deviceId,
        "package_name": packageName,
        "alert_status": alertStatus,
      });

      // ส่ง Header Ngrok ไปด้วย
      final res = await http.post(url,
          headers: {
            "Content-Type": "application/json",
            "ngrok-skip-browser-warning": "true"
          },
          body: body).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        // update local cached recent_apps so UI persists
        final cached = prefs.getString("recent_apps");
        if (cached != null) {
          final List decoded = jsonDecode(cached);
          for (var item in decoded) {
            if (item is Map && item["package_name"] == packageName) {
              item["alert_status"] = alertStatus;
              break;
            }
          }
          await prefs.setString("recent_apps", jsonEncode(decoded));
        }
        return true;
      } else {
        debugPrint("update_alert_status failed: ${res.statusCode} ${res.body}");
        return false;
      }
    } catch (e) {
      debugPrint("Error updateAlertStatus: $e");
      return false;
    }
  }

  // optimistic toggle with rollback and snackbar on failure
  void toggle(AppItem app) async {
    final newStatus = app.alertStatus == AlertStatus.on ? AlertStatus.off : AlertStatus.on;

    if (!mounted) return;
    // optimistic update
    setState(() {
      final i = apps.indexWhere((e) => e.id == app.id);
      if (i != -1) apps[i] = apps[i].copyWith(alertStatus: newStatus);
    });

    final success = await updateAlertStatus(app.id, newStatus == AlertStatus.on ? "on" : "off");
    if (!success) {
      // rollback
      if (!mounted) return;
      setState(() {
        final i = apps.indexWhere((e) => e.id == app.id);
        if (i != -1) apps[i] = apps[i].copyWith(alertStatus: app.alertStatus);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to update alert status")));
      }
    }
  }

  Future<void> toggleAll(bool turnOn) async {
    final items = byTab();
    for (final app in items) {
      final newStatus = turnOn ? AlertStatus.on : AlertStatus.off;
      final success = await updateAlertStatus(app.id, turnOn ? "on" : "off");
      if (success) {
        if (!mounted) return;
        setState(() {
          final i = apps.indexWhere((e) => e.id == app.id);
          if (i != -1) apps[i] = apps[i].copyWith(alertStatus: newStatus);
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to update ${app.name}")));
        }
      }
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
    final showBulkButtons = _tab == _MyAppsTab.alertOn || _tab == _MyAppsTab.alertOff;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(text["title"]!, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: TextField(
              key: searchBarKey,
              decoration: InputDecoration(
                hintText: text["searchHint"]!,
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
              ),
              onChanged: (val) {
                if (!mounted) return;
                setState(() => searchQuery = val);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _FilterChip(label: text["all"]!, selected: _tab == _MyAppsTab.all, onTap: () => setState(() => _tab = _MyAppsTab.all)),
                const SizedBox(width: 8),
                _FilterChip(label: text["alertsOn"]!, selected: _tab == _MyAppsTab.alertOn, onTap: () => setState(() => _tab = _MyAppsTab.alertOn)),
                const SizedBox(width: 8),
                _FilterChip(label: text["alertsOff"]!, selected: _tab == _MyAppsTab.alertOff, onTap: () => setState(() => _tab = _MyAppsTab.alertOff)),
              ],
            ),
          ),
          Expanded(
            child: apps.isEmpty
                ? Center(
              child: Text(text["noApps"]!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54)),
            )
                : ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.black12),
              itemBuilder: (context, i) {
                final app = items[i];
                final daysAgo = DateTime.now().difference(app.installedAt).inDays;
                return ListTile(
                  leading: (app.icon != null) ? Image.memory(base64Decode(app.icon!), width: 40, height: 40) : const Icon(Icons.android, color: Colors.green),
                  title: Text(app.name, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
                  subtitle: Text(installedText(daysAgo, text), style: const TextStyle(fontSize: 12, color: Colors.black45)),
                  trailing: Switch(
                    key: i == 0 ? firstSwitchKey : null,
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
          if (showBulkButtons)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    if (_tab == _MyAppsTab.alertOn)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => toggleAll(false),
                          style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.blue,
                              side: const BorderSide(color: Colors.blue),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              padding: const EdgeInsets.symmetric(vertical: 14)),
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
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              padding: const EdgeInsets.symmetric(vertical: 14)),
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      labelStyle: TextStyle(color: selected ? Colors.white : Colors.black87, fontWeight: selected ? FontWeight.w600 : FontWeight.w500),
      backgroundColor: Colors.grey.shade200,
      selectedColor: Colors.blue,
      side: BorderSide(color: selected ? Colors.blue : Colors.grey),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
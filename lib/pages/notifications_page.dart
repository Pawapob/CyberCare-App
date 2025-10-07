import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// ================== Model ==================
class NotiItem {
  final int id;
  final String appName;
  final String packageName;
  final String riskLevel;
  final String? cveId;
  final String message;
  bool isRead;
  final DateTime timestamp;

  NotiItem({
    required this.id,
    required this.appName,
    required this.packageName,
    required this.riskLevel,
    this.cveId,
    required this.message,
    required this.isRead,
    required this.timestamp,
  });

  factory NotiItem.fromJson(Map<String, dynamic> j) {
    return NotiItem(
      id: j['id'],
      appName: j['app_name'] ?? '',
      packageName: j['package_name'] ?? '',
      riskLevel: j['risk_level'] ?? 'Low',
      cveId: j['cve_id'],
      message: j['message'] ?? '',
      isRead: (j['is_read'] ?? 0) == 1,
      timestamp: DateTime.tryParse(j['timestamp'] ?? '') ?? DateTime.now(),
    );
  }
}

enum _Tab { all, read, unread }

// ================== Page ==================
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final String baseUrl = "http://10.0.2.2:5000";
  List<NotiItem> all = [];
  _Tab tab = _Tab.all;

  // cache จาก MyApps
  Map<String, Map<String, dynamic>> cacheApps = {};

  @override
  void initState() {
    super.initState();
    _loadCacheAndFetch();
  }

  Future<String> _getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("device_id") ?? "";
  }

  Future<void> _loadCacheAndFetch() async {
    await _loadAppsCache();
    await _fetchNotifications();
  }

  Future<void> _loadAppsCache() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString("recent_apps");
    cacheApps.clear();
    if (raw != null) {
      final List decoded = jsonDecode(raw);
      for (final a in decoded) {
        final pkg = a["package_name"] ?? "";
        if (pkg.isEmpty) continue;
        cacheApps[pkg] = {
          "app_name": a["app_name"] ?? pkg,
          "icon": a["icon"],
        };
      }
    }
  }

  Future<void> _fetchNotifications() async {
    final deviceId = await _getDeviceId();
    if (deviceId.isEmpty) return;

    final url = Uri.parse("$baseUrl/get_notifications?device_id=$deviceId");
    final res = await http.get(url);

    if (res.statusCode != 200) {
      setState(() => all = []);
      return;
    }

    final List data = jsonDecode(res.body);

    // ✅ กรองด้วย app_name หรือ package_name
    final list = data
        .map((e) => NotiItem.fromJson(e))
        .where((n) {
      final byPackage = cacheApps.containsKey(n.packageName);
      final byAppName = cacheApps.values.any((a) =>
      (a["app_name"] as String).toLowerCase() ==
          n.appName.toLowerCase());
      return byPackage || byAppName;
    })
        .toList();

    setState(() => all = list);
  }

  List<NotiItem> get filtered {
    switch (tab) {
      case _Tab.read:
        return all.where((e) => e.isRead).toList();
      case _Tab.unread:
        return all.where((e) => !e.isRead).toList();
      default:
        return all;
    }
  }

  Future<void> _markAsRead(NotiItem n) async {
    final url = Uri.parse("$baseUrl/mark_as_read");
    await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"id": n.id}),
    );

    setState(() {
      final idx = all.indexWhere((e) => e.id == n.id);
      if (idx != -1) all[idx].isRead = true;
    });
  }

  Widget _riskChip(String level) {
    Color bg, fg;
    switch (level.toLowerCase()) {
      case "high":
        bg = const Color(0xfffde7e9);
        fg = const Color(0xffd32f2f);
        break;
      case "medium":
        bg = const Color(0xfffff4e5);
        fg = const Color(0xffef6c00);
        break;
      default:
        bg = const Color(0xffe8f5e9);
        fg = const Color(0xff2e7d32);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration:
      BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(level,
          style: TextStyle(
              color: fg, fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCacheAndFetch,
            tooltip: "Reload",
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadCacheAndFetch,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _FilterChip(
                  label: "All",
                  selected: tab == _Tab.all,
                  onTap: () => setState(() => tab = _Tab.all),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: "Read only",
                  selected: tab == _Tab.read,
                  onTap: () => setState(() => tab = _Tab.read),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: "Unread only",
                  selected: tab == _Tab.unread,
                  onTap: () => setState(() => tab = _Tab.unread),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text("No notifications yet"))
                  : ListView.separated(
                itemCount: filtered.length,
                separatorBuilder: (_, __) =>
                const SizedBox(height: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                itemBuilder: (context, i) {
                  final n = filtered[i];

                  // ✅ หา icon จาก cache ทั้ง package_name และ app_name
                  Map<String, dynamic>? appInfo =
                  cacheApps[n.packageName];
                  if (appInfo == null) {
                    appInfo = cacheApps.values.firstWhere(
                          (a) =>
                      (a["app_name"] as String).toLowerCase() ==
                          n.appName.toLowerCase(),
                      orElse: () => {},
                    );
                  }

                  final base64Icon = appInfo?["icon"];
                  final appTitle = n.appName.isNotEmpty
                      ? n.appName
                      : (appInfo?["app_name"] ?? n.packageName);

                  return InkWell(
                    onTap: () async => _markAsRead(n),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black12,
                              blurRadius: 6,
                              spreadRadius: 0.5,
                              offset: const Offset(0, 2))
                        ],
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.grey.shade200,
                            child: (base64Icon != null)
                                ? ClipOval(
                              child: Image.memory(
                                base64Decode(base64Icon),
                                width: 36,
                                height: 36,
                                fit: BoxFit.cover,
                              ),
                            )
                                : const Icon(Icons.apps,
                                color: Colors.green),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        appTitle,
                                        style: const TextStyle(
                                            fontWeight:
                                            FontWeight.w600),
                                      ),
                                    ),
                                    _riskChip(n.riskLevel),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  n.message,
                                  style: const TextStyle(
                                      color: Colors.black87),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (!n.isRead)
                            const Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Icon(Icons.circle,
                                  size: 10, color: Colors.blue),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============== FilterChip widget ===============
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
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      ),
      backgroundColor: Colors.grey.shade200,
      selectedColor: Colors.blue.shade100,
      side: BorderSide(color: selected ? Colors.blue : Colors.black12),
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}

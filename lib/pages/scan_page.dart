import 'dart:async';
import 'package:flutter/material.dart';
import 'package:device_apps/device_apps.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage>
    with AutomaticKeepAliveClientMixin {
  bool isScanning = false;
  bool scanCompleted = false;
  bool hasScannedOnce = false; // <<< flag ว่าเคยสแกนแล้ว
  double progress = 0.0;
  int checkedApps = 0;
  int totalApps = 0;
  List<Application> installedApps = [];

  @override
  bool get wantKeepAlive => true; // <<< ทำให้ state ไม่ reset เวลาเปลี่ยนแท็บ

  void startScan() async {
    // ดึงแอปมาดูก่อนว่ามีกี่ตัว
    List<Application> apps = await DeviceApps.getInstalledApplications(
      includeAppIcons: true,
      includeSystemApps: false,
      onlyAppsWithLaunchIntent: true,
    );

    // กรองไม่ให้เจอแอปตัวเอง
    apps = apps
        .where((app) => app.packageName != "com.example.cybercare_app")
        .toList();

    setState(() {
      totalApps = apps.length;
      isScanning = true;
      scanCompleted = false;
      progress = 0.0;
      checkedApps = 0;
      // ❌ ห้ามล้าง installedApps = [];
    });

    Timer.periodic(const Duration(milliseconds: 120), (timer) {
      setState(() {
        progress += 1 / (totalApps == 0 ? 1 : totalApps);
        checkedApps = (progress * totalApps).clamp(0, totalApps).toInt();

        if (progress >= 1.0) {
          progress = 1.0;
          timer.cancel();

          Future.delayed(const Duration(seconds: 1), () async {
            await getInstalledApps();
            setState(() {
              isScanning = false;
              scanCompleted = true;
              hasScannedOnce = true; // <<< mark ว่าเคยสแกนแล้ว
            });
          });
        }
      });
    });
  }

  Future<void> getInstalledApps() async {
    List<Application> apps = await DeviceApps.getInstalledApplications(
      includeAppIcons: true,
      includeSystemApps: false,
      onlyAppsWithLaunchIntent: true,
    );

    // กรองไม่ให้เจอแอปตัวเอง
    apps = apps
        .where((app) => app.packageName != "com.example.cybercare_app")
        .toList();

    // เรียงจากใหม่ไปเก่า
    apps.sort((a, b) => b.installTimeMillis.compareTo(a.installTimeMillis));

    setState(() {
      installedApps = apps;
    });
  }

  String _installedText(int daysAgo) {
    if (daysAgo == 0) return "Installed today";
    if (daysAgo == 1) return "Installed yesterday";
    return "Installed $daysAgo days ago";
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // <<< ต้องมี เพื่อให้ keepAlive ทำงาน

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          "Scan",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 25,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          const Text(
            "App list scan only — no files or personal data are checked",
            style: TextStyle(fontSize: 14, color: Colors.black87),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),

          // วงกลมตรงกลาง
          Center(
            child: isScanning
                ? SizedBox(
              width: 220,
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 200,
                    height: 200,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 10,
                      color: Colors.blue,
                      backgroundColor: Colors.blue.withOpacity(0.1),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "${(progress * 100).toInt()}%",
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Scanning...",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        "Checking apps: $checkedApps/$totalApps",
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  )
                ],
              ),
            )
                : scanCompleted
                ? SizedBox(
              width: 200,
              height: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(
                        color: Colors.blue,
                        width: 3,
                      ),
                    ),
                  ),
                  const Icon(Icons.check,
                      size: 100, color: Colors.blue),
                ],
              ),
            )
                : GestureDetector(
              onTap: startScan,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      spreadRadius: 20,
                      blurRadius: 40,
                    ),
                  ],
                  border: Border.all(
                    color: Colors.blue,
                    width: 3,
                  ),
                ),
                child: const Center(
                  child: Text(
                    "SCAN",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 30),

          // Recently installed
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Recently installed",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: () {
                          if (installedApps.isNotEmpty) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    AllAppsPage(apps: installedApps),
                              ),
                            );
                          }
                        },
                        child: const Text(
                          "View all",
                          style: TextStyle(color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: hasScannedOnce
                      ? ListView.builder(
                    itemCount: installedApps.length < 3
                        ? installedApps.length
                        : 3,
                    itemBuilder: (context, index) {
                      final app = installedApps[index];
                      final installedDate =
                      DateTime.fromMillisecondsSinceEpoch(
                          app.installTimeMillis);
                      final daysAgo =
                          DateTime.now().difference(installedDate).inDays;

                      return ListTile(
                        leading: app is ApplicationWithIcon
                            ? Image.memory(app.icon,
                            width: 40, height: 40)
                            : const Icon(Icons.android),
                        title: Text(app.appName),
                        subtitle: Text(_installedText(daysAgo)),
                      );
                    },
                  )
                      : const Center(
                    child: Text(
                      "Not yet scanned",
                      style: TextStyle(
                          fontSize: 14, color: Colors.black54),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------ หน้า View All ------------------
class AllAppsPage extends StatelessWidget {
  final List<Application> apps;

  const AllAppsPage({super.key, required this.apps});

  String _installedText(int daysAgo) {
    if (daysAgo == 0) return "Installed today";
    if (daysAgo == 1) return "Installed yesterday";
    return "Installed $daysAgo days ago";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("All Installed Apps"),
        centerTitle: true,
      ),
      body: ListView.builder(
        itemCount: apps.length,
        itemBuilder: (context, index) {
          final app = apps[index];
          final installedDate =
          DateTime.fromMillisecondsSinceEpoch(app.installTimeMillis);
          final daysAgo = DateTime.now().difference(installedDate).inDays;

          return ListTile(
            leading: app is ApplicationWithIcon
                ? Image.memory(app.icon, width: 40, height: 40)
                : const Icon(Icons.android),
            title: Text(app.appName),
            subtitle: Text(_installedText(daysAgo)),
          );
        },
      ),
    );
  }
}

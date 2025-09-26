import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:device_apps/device_apps.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ------------------ Scan Page ------------------
class ScanPage extends StatefulWidget {
  final bool isActive;
  const ScanPage({super.key, required this.isActive});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage>
    with AutomaticKeepAliveClientMixin {
  bool isScanning = false;
  bool scanCompleted = false;
  bool hasScannedOnce = false;
  double progress = 0.0;
  int checkedApps = 0;
  int totalApps = 0;
  List<dynamic> installedApps = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    loadCache(); // โหลด cache ตอนเข้าแอป
  }

  @override
  void didUpdateWidget(covariant ScanPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // ✅ Reset state ถ้าออกจากหน้านี้
    if (!widget.isActive && oldWidget.isActive) {
      setState(() {
        isScanning = false;
        scanCompleted = false;
      });
    }
  }

  // โหลด cache ที่เคยเก็บไว้
  Future<void> loadCache() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString("recent_apps");
    if (cachedData != null) {
      final List decoded = jsonDecode(cachedData);
      setState(() {
        installedApps = decoded;
        hasScannedOnce = true;
      });
    }
  }

  // บันทึกลง cache หลังสแกนเสร็จ
  Future<void> saveCache() async {
    final prefs = await SharedPreferences.getInstance();
    final data = installedApps.map((a) {
      if (a is ApplicationWithIcon) {
        return {
          "app_name": a.appName,
          "package_name": a.packageName,
          "installed_time": a.installTimeMillis,
          "icon": base64Encode(a.icon), // 🔥 เก็บ icon เป็น base64
        };
      } else {
        return a; // ถ้าเป็น Map จาก cache ก็เก็บตรง ๆ
      }
    }).toList();
    await prefs.setString("recent_apps", jsonEncode(data));
  }

  void startScan() async {
    List<Application> apps = await DeviceApps.getInstalledApplications(
      includeAppIcons: true,
      includeSystemApps: false,
      onlyAppsWithLaunchIntent: true,
    );

    apps = apps
        .where((app) => app.packageName != "com.example.cybercare_app")
        .toList();

    setState(() {
      totalApps = apps.length;
      isScanning = true;
      scanCompleted = false;
      progress = 0.0;
      checkedApps = 0;
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
            await saveCache(); // ✅ เซฟ cache หลังสแกนเสร็จ
            setState(() {
              isScanning = false;
              scanCompleted = true;
              hasScannedOnce = true;
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

    apps = apps
        .where((app) => app.packageName != "com.example.cybercare_app")
        .toList();

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
    super.build(context);

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

          // Scan Circle
          Center(
            child: isScanning
                ? _buildProgress()
                : scanCompleted
                ? _buildSuccess()
                : _buildScanButton(),
          ),

          const SizedBox(height: 30),

          // Recently Installed
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
                      String appName;
                      int installTime;
                      Uint8List? iconBytes;

                      if (app is ApplicationWithIcon) {
                        appName = app.appName;
                        installTime = app.installTimeMillis;
                        iconBytes = app.icon;
                      } else {
                        appName = app['app_name'];
                        installTime = app['installed_time'];
                        if (app['icon'] != null) {
                          iconBytes = base64Decode(app['icon']);
                        }
                      }

                      final installedDate =
                      DateTime.fromMillisecondsSinceEpoch(installTime);
                      final daysAgo =
                          DateTime.now().difference(installedDate).inDays;

                      return ListTile(
                        leading: iconBytes != null
                            ? Image.memory(iconBytes,
                            width: 40, height: 40)
                            : const Icon(Icons.android,
                            color: Colors.green),
                        title: Text(appName),
                        subtitle: Text(_installedText(daysAgo)),
                      );
                    },
                  )
                      : const Center(
                    child: Text(
                      "Not yet scanned",
                      style:
                      TextStyle(fontSize: 14, color: Colors.black54),
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

  Widget _buildProgress() => SizedBox(
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
  );

  Widget _buildSuccess() => SizedBox(
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
        const Icon(Icons.check, size: 100, color: Colors.blue),
      ],
    ),
  );

  Widget _buildScanButton() => GestureDetector(
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
  );
}

// ------------------ หน้า View All ------------------
class AllAppsPage extends StatelessWidget {
  final List<dynamic> apps;
  const AllAppsPage({super.key, required this.apps});

  String _installedText(int daysAgo) {
    if (daysAgo == 0) return "Installed today";
    if (daysAgo == 1) return "Installed yesterday";
    return "Installed $daysAgo days ago";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("All Installed Apps"), centerTitle: true),
      body: ListView.builder(
        itemCount: apps.length,
        itemBuilder: (context, index) {
          final app = apps[index];
          String appName;
          int installTime;
          Uint8List? iconBytes;

          if (app is ApplicationWithIcon) {
            appName = app.appName;
            installTime = app.installTimeMillis;
            iconBytes = app.icon;
          } else {
            appName = app['app_name'];
            installTime = app['installed_time'];
            if (app['icon'] != null) {
              iconBytes = base64Decode(app['icon']);
            }
          }

          final installedDate =
          DateTime.fromMillisecondsSinceEpoch(installTime);
          final daysAgo = DateTime.now().difference(installedDate).inDays;

          return ListTile(
            leading: iconBytes != null
                ? Image.memory(iconBytes, width: 40, height: 40)
                : const Icon(Icons.android, color: Colors.green),
            title: Text(appName),
            subtitle: Text(_installedText(daysAgo)),
          );
        },
      ),
    );
  }
}

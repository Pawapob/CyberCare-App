import 'dart:async';
import 'package:flutter/material.dart';
import 'package:device_apps/device_apps.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  bool isScanning = false;
  bool scanCompleted = false;
  double progress = 0.0;
  int checkedApps = 0;
  final int totalApps = 58; // สมมุติว่ามี 58 app ไว้โชว์ progress
  List<Application> installedApps = [];

  void startScan() {
    setState(() {
      isScanning = true;
      scanCompleted = false;
      progress = 0.0;
      checkedApps = 0;
      installedApps = [];
    });

    Timer.periodic(const Duration(milliseconds: 120), (timer) {
      setState(() {
        progress += 0.02;
        checkedApps = (progress * totalApps).clamp(0, totalApps).toInt();

        if (progress >= 1.0) {
          progress = 1.0;
          timer.cancel();

          Future.delayed(const Duration(seconds: 1), () async {
            await getInstalledApps();
            setState(() {
              isScanning = false;
              scanCompleted = true;
            });
          });
        }
      });
    });
  }

  Future<void> getInstalledApps() async {
    List<Application> apps = await DeviceApps.getInstalledApplications(
      includeAppIcons: true,
      includeSystemApps: false, // ← ไม่เอาระบบ
      onlyAppsWithLaunchIntent: false, // ← ให้โชว์เฉพาะแอปที่ user เปิดได้
    );

    // filter เฉพาะที่ไม่ใช่ systemApp
    apps = apps.where((app) => !(app.systemApp ?? false)).toList();

    apps.sort((a, b) => a.appName.compareTo(b.appName));

    setState(() {
      installedApps = apps;
    });
  }


  @override
  Widget build(BuildContext context) {
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

          // ส่วนวงกลมตรงกลาง
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
                        onPressed: () {},
                        child: const Text(
                          "View all",
                          style: TextStyle(color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                ),

                // ถ้ายังไม่ scan → ข้อความ
                // ถ้า scan เสร็จ → list แอพจริง
                Expanded(
                  child: scanCompleted
                      ? ListView.builder(
                    itemCount: installedApps.length,
                    itemBuilder: (context, index) {
                      final app = installedApps[index];
                      return ListTile(
                        leading: app is ApplicationWithIcon
                            ? Image.memory(app.icon,
                            width: 40, height: 40)
                            : const Icon(Icons.android),
                        title: Text(app.appName),
                        subtitle: Text("Package: ${app.packageName}"),
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

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:device_apps/device_apps.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:provider/provider.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import '../language_provider.dart';
import '../config.dart'; // 🔥 1. Import ไฟล์ Config เข้ามา

// ===================== Localized Strings =====================
Map<String, Map<String, String>> scanStrings = {
  "en": {
    "scanTitle": "Scan",
    "scanSubtitle": "App list scan only — no files or personal data are checked",
    "scanButton": "SCAN",
    "scanning": "Scanning...",
    "preparing": "Preparing...",
    "checkingApps": "Checking apps",
    "success": "Scan completed",
    "recentlyInstalled": "Recently installed",
    "notYetScanned": "Not yet scanned",
    "viewAll": "View all",
    "installedToday": "Installed today",
    "installedYesterday": "Installed yesterday",
    "installedDaysAgo": "Installed {days} days ago",
    "tutorialTitle": "Tap to Scan",
    "tutorialDesc": "Press this button to scan for apps on the device. (Note: This is not a virus scan.)",
    "tutorialViewAllTitle": "See All Apps",
    "tutorialViewAllDesc": "Tap here to view the full list of installed apps.",
    "tutorialSkip": "SKIP",
  },
  "th": {
    "scanTitle": "สแกน",
    "scanSubtitle": "การสแกนเก็บรายชื่อแอปเท่านั้น – ไม่ตรวจสอบไฟล์หรือข้อมูลส่วนตัว",
    "scanButton": "สแกน",
    "scanning": "กำลังสแกน...",
    "preparing": "กำลังเตรียมข้อมูล...",
    "checkingApps": "ตรวจสอบแอป",
    "success": "สแกนเสร็จสิ้น",
    "recentlyInstalled": "ติดตั้งล่าสุด",
    "notYetScanned": "ยังไม่ได้สแกน",
    "viewAll": "ดูทั้งหมด",
    "installedToday": "ติดตั้งวันนี้",
    "installedYesterday": "ติดตั้งเมื่อวาน",
    "installedDaysAgo": "ติดตั้ง {days} วันที่แล้ว",
    "tutorialTitle": "เริ่มสแกนตรงนี้",
    "tutorialDesc": "กดปุ่มเพื่อสแกนหาแอปในเครื่อง (ไม่ใช่สแกนไวรัส)",
    "tutorialViewAllTitle": "ดูแอปทั้งหมด",
    "tutorialViewAllDesc": "กดตรงนี้เพื่อดูรายชื่อแอปทั้งหมดในเครื่อง",
    "tutorialSkip": "ข้าม",
  }
};

// ===================== Scan Page =====================
class ScanPage extends StatefulWidget {
  final bool isActive;
  const ScanPage({super.key, required this.isActive});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage>
    with AutomaticKeepAliveClientMixin {
  bool isScanning = false;
  bool isPreparing = false; // 🔥 เช็คสถานะเตรียมข้อมูล
  bool scanCompleted = false;
  bool hasScannedOnce = false;
  double progress = 0.0;
  int checkedApps = 0;
  int totalApps = 0;
  List<dynamic> installedApps = [];

  // 🔥 Keys สำหรับ Tutorial
  final GlobalKey scanButtonKey = GlobalKey();
  final GlobalKey viewAllButtonKey = GlobalKey();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    loadCache();
    checkScanTutorial();
  }

  // ------------------ Tutorial Logic ------------------
  void markTutorialAsSeen(String key) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, true);
  }

  void checkScanTutorial() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool hasSeen = prefs.getBool('hasSeenScanTutorial') ?? false;

    if (!hasSeen) {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) showScanTutorial();
      });
    }
  }

  void showScanTutorial() {
    final lang = Provider.of<LanguageProvider>(context, listen: false).lang;
    final text = scanStrings[lang]!;

    TutorialCoachMark(
      targets: [
        TargetFocus(
          identify: "ScanButton",
          keyTarget: scanButtonKey,
          alignSkip: Alignment.topRight,
          shape: ShapeLightFocus.Circle,
          contents: [
            TargetContent(
              align: ContentAlign.bottom,
              builder: (context, controller) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      text["tutorialTitle"]!,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      text["tutorialDesc"]!,
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ],
      colorShadow: Colors.black,
      textSkip: text["tutorialSkip"]!,
      paddingFocus: 10,
      opacityShadow: 0.85,
      onFinish: () => markTutorialAsSeen('hasSeenScanTutorial'),
      onSkip: () {
        markTutorialAsSeen('hasSeenScanTutorial');
        return true;
      },
    ).show(context: context);
  }

  void checkViewAllTutorial() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool hasSeen = prefs.getBool('hasSeenViewAllTutorial') ?? false;

    if (!hasSeen) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) showViewAllTutorial();
      });
    }
  }

  void showViewAllTutorial() {
    final lang = Provider.of<LanguageProvider>(context, listen: false).lang;
    final text = scanStrings[lang]!;

    TutorialCoachMark(
      targets: [
        TargetFocus(
          identify: "ViewAllButton",
          keyTarget: viewAllButtonKey,
          alignSkip: Alignment.topLeft,
          shape: ShapeLightFocus.RRect,
          contents: [
            TargetContent(
              align: ContentAlign.top,
              builder: (context, controller) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      text["tutorialViewAllTitle"]!,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      text["tutorialViewAllDesc"]!,
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                      textAlign: TextAlign.right,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ],
      colorShadow: Colors.black,
      textSkip: text["tutorialSkip"]!,
      paddingFocus: 5,
      opacityShadow: 0.85,
      onFinish: () => markTutorialAsSeen('hasSeenViewAllTutorial'),
      onSkip: () {
        markTutorialAsSeen('hasSeenViewAllTutorial');
        return true;
      },
    ).show(context: context);
  }

  @override
  void didUpdateWidget(covariant ScanPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isActive && oldWidget.isActive) {
      setState(() {
        isScanning = false;
        scanCompleted = false;
      });
    }
  }

  // ------------------ Backend & Logic ------------------

  Future<String> getOrCreateDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? id = prefs.getString("device_id");
    if (id == null || id.isEmpty) {
      id = const Uuid().v4();
      await prefs.setString("device_id", id);
    }
    return id;
  }

  Future<void> uploadToBackend(String deviceId, List<Application> apps) async {
    // 🔥 ใช้ URL จาก Config
    final String baseUrl = Config.baseUrl;

    final registerUrl = Uri.parse("$baseUrl/register_device");
    final uploadUrl = Uri.parse("$baseUrl/upload_apps");

    try {
      debugPrint("=== START UPLOAD ===");
      debugPrint("DeviceID = $deviceId");
      debugPrint("Apps count = ${apps.length}");

      // ---------- REGISTER DEVICE ----------
      final registerResp = await http.post(
        registerUrl,
        headers: {
          "Content-Type": "application/json",
          "ngrok-skip-browser-warning": "1",
        },
        body: jsonEncode({"device_id": deviceId}),
      );

      debugPrint("REGISTER -> code=${registerResp.statusCode}");
      debugPrint("REGISTER body -> ${registerResp.body}");

      // ---------- UPLOAD APPS ----------
      final body = {
        "device_id": deviceId,
        "apps": apps.map((a) {
          return {
            "app_name": a.appName,
            "package_name": a.packageName,
            "installed_time": a.installTimeMillis,
          };
        }).toList(),
      };

      final uploadResp = await http.post(
        uploadUrl,
        headers: {
          "Content-Type": "application/json",
          "ngrok-skip-browser-warning": "1",
        },
        body: jsonEncode(body),
      );

      debugPrint("UPLOAD -> code=${uploadResp.statusCode}");
      debugPrint("UPLOAD body -> ${uploadResp.body}");
    } catch (e) {
      debugPrint("❌ ERROR SENDING DATA TO BACKEND");
      debugPrint(e.toString());
    }
  }


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

  Future<void> saveCache() async {
    final prefs = await SharedPreferences.getInstance();
    final data = installedApps.map((a) {
      if (a is ApplicationWithIcon) {
        return {
          "app_name": a.appName,
          "package_name": a.packageName,
          "installed_time": a.installTimeMillis,
          "icon": base64Encode(a.icon),
        };
      } else {
        return a;
      }
    }).toList();
    await prefs.setString("recent_apps", jsonEncode(data));
  }

  // 🔥 แก้ไข logic สแกนให้ UI ไม่ค้าง
  void startScan() async {
    // 1. เปลี่ยนหน้าจอเป็น Loading ทันที
    setState(() {
      isScanning = true;
      isPreparing = true;
      scanCompleted = false;
      progress = 0.0;
      checkedApps = 0;
      totalApps = 0;
    });

    // 2. พักให้ UI วาดวงกลมแป๊บนึง
    await Future.delayed(const Duration(milliseconds: 100));

    // 3. เริ่มดึงข้อมูลแอป
    List<Application> apps = await DeviceApps.getInstalledApplications(
      includeAppIcons: true,
      includeSystemApps: false,
      onlyAppsWithLaunchIntent: true,
    );

    apps = apps
        .where((app) => app.packageName != "com.example.cybercare_app")
        .toList();

    if (!mounted) return;
    setState(() {
      isPreparing = false;
      totalApps = apps.length;
    });

    // 4. เริ่มนับ % หลอกๆ
    Timer.periodic(const Duration(milliseconds: 120), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        progress += 1 / (totalApps == 0 ? 1 : totalApps);
        checkedApps = (progress * totalApps).clamp(0, totalApps).toInt();

        if (progress >= 1.0) {
          progress = 1.0;
          timer.cancel();

          Future.delayed(const Duration(seconds: 1), () async {
            if (!mounted) return;

            setState(() {
              installedApps = apps;
            });
            await saveCache();

            final deviceId = await getOrCreateDeviceId();
            await uploadToBackend(deviceId, installedApps.cast<Application>());

            if (mounted) {
              setState(() {
                isScanning = false;
                scanCompleted = true;
                hasScannedOnce = true;
              });
              checkViewAllTutorial();
            }
          });
        }
      });
    });
  }

  // ใช้เฉพาะตอน init (ไม่เรียกใน startScan แล้ว)
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

  String installedText(int daysAgo, Map<String, String> text) {
    if (daysAgo == 0) return text["installedToday"]!;
    if (daysAgo == 1) return text["installedYesterday"]!;
    return text["installedDaysAgo"]!.replaceAll("{days}", daysAgo.toString());
  }

  // ------------------ UI Build ------------------
  @override
  Widget build(BuildContext context) {
    super.build(context);

    final lang = Provider.of<LanguageProvider>(context).lang;
    final text = scanStrings[lang]!;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          text["scanTitle"]!,
          style: const TextStyle(
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              text["scanSubtitle"]!,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 30),
          Center(
            child: isScanning
                ? _buildProgress(text)
                : scanCompleted
                ? _buildSuccess(text)
                : _buildScanButton(text),
          ),
          const SizedBox(height: 30),
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
                      Text(
                        text["recentlyInstalled"]!,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        key: viewAllButtonKey,
                        onPressed: () {
                          if (installedApps.isNotEmpty) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AllAppsPage(
                                    apps: installedApps, lang: lang),
                              ),
                            );
                          }
                        },
                        child: Text(
                          text["viewAll"]!,
                          style: const TextStyle(color: Colors.blue),
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
                      DateTime.fromMillisecondsSinceEpoch(
                          installTime);
                      final daysAgo = DateTime.now()
                          .difference(installedDate)
                          .inDays;
                      return ListTile(
                        leading: iconBytes != null
                            ? Image.memory(iconBytes,
                            width: 40, height: 40)
                            : const Icon(Icons.android,
                            color: Colors.green),
                        title: Text(appName),
                        subtitle: Text(installedText(daysAgo, text)),
                      );
                    },
                  )
                      : Center(
                    child: Text(
                      text["notYetScanned"]!,
                      style: const TextStyle(
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

  Widget _buildProgress(Map<String, String> text) => SizedBox(
    width: 220,
    height: 220,
    child: Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 200,
          height: 200,
          child: CircularProgressIndicator(
            value: isPreparing ? null : progress,
            strokeWidth: 10,
            color: Colors.blue,
            backgroundColor: Colors.blue.withOpacity(0.1),
          ),
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isPreparing ? "..." : "${(progress * 100).toInt()}%",
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isPreparing
                  ? (text["preparing"] ?? "Preparing...")
                  : text["scanning"]!,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Text(
              isPreparing
                  ? ""
                  : "${text["checkingApps"]!}: $checkedApps/$totalApps",
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

  Widget _buildSuccess(Map<String, String> text) => SizedBox(
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

  Widget _buildScanButton(Map<String, String> text) => GestureDetector(
    key: scanButtonKey,
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
      child: Center(
        child: Text(
          text["scanButton"]!,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
      ),
    ),
  );
}

// ===================== All Apps Page =====================
class AllAppsPage extends StatelessWidget {
  final List<dynamic> apps;
  final String lang;

  const AllAppsPage({super.key, required this.apps, required this.lang});

  String installedText(int daysAgo, Map<String, String> text) {
    if (daysAgo == 0) return text["installedToday"]!;
    if (daysAgo == 1) return text["installedYesterday"]!;
    return text["installedDaysAgo"]!.replaceAll("{days}", daysAgo.toString());
  }

  @override
  Widget build(BuildContext context) {
    final text = scanStrings[lang]!;

    return Scaffold(
      appBar: AppBar(title: Text(text["viewAll"]!), centerTitle: true),
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

          final installedDate = DateTime.fromMillisecondsSinceEpoch(installTime);
          final daysAgo = DateTime.now().difference(installedDate).inDays;

          return ListTile(
            leading: iconBytes != null
                ? Image.memory(iconBytes, width: 40, height: 40)
                : const Icon(Icons.android, color: Colors.green),
            title: Text(appName),
            subtitle: Text(installedText(daysAgo, text)),
          );
        },
      ),
    );
  }
}
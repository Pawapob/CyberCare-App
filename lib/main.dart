import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'language_provider.dart';
import 'pages/notifications_page.dart';
import 'pages/scan_page.dart';
import 'pages/myapps_page.dart';
import 'pages/settings_page.dart'; // ✅ จำเป็นต้อง import เพื่อใช้ updatePreferences

// ===================== Localized Strings =====================
Map<String, Map<String, String>> navStrings = {
  "en": {
    "notifications": "Notifications",
    "scan": "Scan",
    "myApps": "My apps",
    "settings": "Setting",
  },
  "th": {
    "notifications": "การแจ้งเตือน",
    "scan": "สแกน",
    "myApps": "แอปของฉัน",
    "settings": "การตั้งค่า",
  }
};

// ===================== MAIN APP =====================
void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => LanguageProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
      ),
      home: const HomePage(),
    );
  }
}

// ===================== HOME PAGE =====================
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 1; // default (เดี๋ยวจะถูกเปลี่ยนใน initState)
  late List<Widget> _pages;

  // 🔥 ตัวแปรเช็คความพร้อม
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    // เช็คสถานะการใช้งาน (ครั้งแรก หรือ ครั้งต่อมา)
    _checkAppLaunchStatus();
  }

  // ---------------------------------------------------------
  // 🔥 Logic เช็คสถานะการเข้าแอป
  // ---------------------------------------------------------
  Future<void> _checkAppLaunchStatus() async {
    final prefs = await SharedPreferences.getInstance();
    bool hasSelectedLang = prefs.getBool('hasSelectedLanguage') ?? false;

    if (!hasSelectedLang) {
      // 🟢 กรณีเข้าครั้งแรก (ยังไม่เคยเลือกภาษา)
      // ให้รอเลือกภาษา -> แล้วค่อยไปหน้า Scan (index 1)
      _selectedIndex = 1;

      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
      _showLanguageDialog();

    } else {
      // 🔵 กรณีเข้าครั้งต่อๆ ไป (เคยเลือกภาษาแล้ว)
      // ให้ไปหน้า Notifications (index 0) ทันที
      _selectedIndex = 0;

      _initPages();
      setState(() {
        _isReady = true;
      });
    }
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: Colors.white,
            title: const Column(
              children: [
                Icon(Icons.language, size: 50, color: Colors.blue),
                SizedBox(height: 15),
                Text("Welcome / ยินดีต้อนรับ",
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center
                ),
              ],
            ),
            content: const Text(
              "Please select your language\nกรุณาเลือกภาษาของคุณ",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  side: const BorderSide(color: Colors.grey),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                onPressed: () => _setLanguageAndStart('en'),
                child: const Text("English 🇺🇸"),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                onPressed: () => _setLanguageAndStart('th'),
                child: const Text("ไทย 🇹🇭"),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _setLanguageAndStart(String langCode) async {
    // 1. เปลี่ยนภาษา
    Provider.of<LanguageProvider>(context, listen: false).setLang(langCode);

    // 2. บันทึกว่าเลือกแล้ว + บันทึกภาษาลงเครื่อง
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSelectedLanguage', true);
    await prefs.setString('lang', langCode);

    // 3. ส่งไป Backend
    try {
      final deviceId = await getOrCreateDeviceId();
      await updatePreferences(
        deviceId: deviceId,
        language: langCode,
        enabled3Times: true,
        includeCyberAttack: false, // 🔥✅ เพิ่มบรรทัดนี้แล้ว (Error จะหายไป)
        times: null,
      );
    } catch (e) {
      print("Error saving language to backend: $e");
    }

    // 4. ปิด Popup
    if (mounted) Navigator.pop(context);

    // 5. เริ่มโหลดหน้า Scan (เพราะเป็นครั้งแรก)
    _initPages();
    setState(() {
      _isReady = true;
    });
  }
  // ---------------------------------------------------------

  void _initPages() {
    _pages = [
      const NotificationsPage(),
      // ส่ง isActive ตาม index
      ScanPage(isActive: _selectedIndex == 1),
      const MyAppsPage(),
      const SettingsPage(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;

      if (index == 1) {
        _pages[1] = ScanPage(key: UniqueKey(), isActive: true);
      }
      if (index == 2) {
        _pages[2] = MyAppsPage(key: UniqueKey());
      }
      if (index == 3) {
        _pages[3] = const SettingsPage();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        final lang = languageProvider.lang;
        final text = navStrings[lang]!;

        return Scaffold(
          body: _pages[_selectedIndex], // แสดงหน้าตาม index ที่กำหนดไว้ตอนแรก

          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: Colors.blue,
            unselectedItemColor: Colors.black54,
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.notifications),
                label: text["notifications"],
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.add_circle_outline),
                label: text["scan"],
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.list),
                label: text["myApps"],
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.settings),
                label: text["settings"],
              ),
            ],
          ),
        );
      },
    );
  }
}
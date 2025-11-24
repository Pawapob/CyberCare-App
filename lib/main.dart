import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'language_provider.dart';
import 'pages/notifications_page.dart';
import 'pages/scan_page.dart';
import 'pages/myapps_page.dart';
import 'pages/settings_page.dart';

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
  int _selectedIndex = 1; // default หน้า Scan
  late List<Widget> _pages;

  // 🔥 ตัวแปรเช็คว่าเลือกภาษาเสร็จหรือยัง (ถ้ายัง ห้ามโหลดหน้าแอป)
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    // เช็คภาษาเป็นอย่างแรกก่อนทำอย่างอื่น
    _checkFirstTimeLanguage();
  }

  // ---------------------------------------------------------
  // 🔥 Logic เช็คและบังคับเลือกภาษา (First Time Language)
  // ---------------------------------------------------------
  Future<void> _checkFirstTimeLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    bool hasSelectedLang = prefs.getBool('hasSelectedLanguage') ?? false;

    if (!hasSelectedLang) {
      // ถ้ายังไม่เคยเลือก -> รอแป๊บนึงให้ context พร้อม แล้วเด้ง Popup
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
      _showLanguageDialog();
    } else {
      // ถ้าเคยเลือกแล้ว -> โหลดหน้าแอปปกติ
      _initPages();
      setState(() {
        _isReady = true;
      });
    }
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // 🔒 ล็อกห้ามกดปิด ต้องเลือกเท่านั้น
      builder: (context) {
        // 🔒 WillPopScope ห้ามกดปุ่ม Back ที่เครื่อง
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
              // ปุ่มภาษาอังกฤษ
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
                child: const Text("English 🇺k"),
              ),
              const SizedBox(width: 10),
              // ปุ่มภาษาไทย
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
    // 1. เปลี่ยนภาษาทั้งแอป
    Provider.of<LanguageProvider>(context, listen: false).setLang(langCode);

    // 2. บันทึกว่าเลือกแล้ว
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSelectedLanguage', true);

    // 3. ปิด Popup
    if (mounted) Navigator.pop(context);

    // 4. เริ่มโหลดหน้า Scan (ตอนนี้ ScanPage จะเริ่มทำงาน และ Popup สอนจะเด้งตามมา)
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

      // รีเซตหน้า Scan เมื่อกดเข้ามาใหม่
      if (index == 1) {
        _pages[1] = ScanPage(key: UniqueKey(), isActive: true);
      }
      // รีเซตหน้า MyApps เมื่อกดเข้ามาใหม่
      if (index == 2) {
        _pages[2] = MyAppsPage(key: UniqueKey());
      }
      // รีเซตหน้า Settings เมื่อกดเข้ามาใหม่
      if (index == 3) {
        _pages[3] = const SettingsPage();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 🔥 ถ้ายังเลือกภาษาไม่เสร็จ ให้โชว์หน้า Loading รอไปก่อน
    if (!_isReady) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // ใช้ Consumer เพื่อให้หน้า Home อัปเดตภาษาทันทีที่เลือกใน Popup
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        final lang = languageProvider.lang;
        final text = navStrings[lang]!;

        return Scaffold(
          // แก้ตรงนี้: เปลี่ยนจาก IndexedStack เป็นการเรียกหน้าโดยตรง
          body: _pages[_selectedIndex],

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
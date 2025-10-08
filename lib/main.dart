import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // ✅ ดึงค่าภาษาออกมาจาก Provider
    final lang = Provider.of<LanguageProvider>(context).lang;
    final text = navStrings[lang]!;

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          const NotificationsPage(),
          ScanPage(isActive: _selectedIndex == 1),
          const MyAppsPage(),
          const SettingsPage(),
        ],
      ),
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
  }
}

import 'package:flutter/material.dart';
import 'pages/notifications_page.dart';
import 'pages/scan_page.dart';
import 'pages/myapps_page.dart';
import 'pages/settings_page.dart';

void main() {
  runApp(const MyApp());
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

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 1; // default หน้า Scan

  final List<Widget> _pages = const [
    NotificationsPage(),
    ScanPage(),
    MyAppsPage(),
    SettingsPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white, // พื้นหลังขาว
        selectedItemColor: Colors.blue, // สีฟ้าเข้มตอนเลือก
        unselectedItemColor: Colors.black54, // สีเทาอ่อนตอนยังไม่เลือก
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            label: 'Scan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'My apps',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Alter setting',
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LanguageProvider extends ChangeNotifier {
  String _lang = "en"; // ✅ ค่าเริ่มต้นภาษาอังกฤษ
  String get lang => _lang;

  LanguageProvider() {
    _loadLang(); // ✅ โหลดค่าภาษาเดิมตอนเปิดแอป
  }

  // =====================================================
  // โหลดค่าภาษาเดิมจาก SharedPreferences
  // =====================================================
  void _loadLang() async {
    final prefs = await SharedPreferences.getInstance();
    _lang = prefs.getString("lang") ?? "en";
    notifyListeners();
  }

  // =====================================================
  // เปลี่ยนภาษา + เก็บค่าใน SharedPreferences + ส่งไป backend
  // =====================================================
  Future<void> setLang(String newLang) async {
    _lang = newLang;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("lang", newLang);

    // ดึง device_id จาก local storage
    final deviceId = prefs.getString("device_id");
    if (deviceId != null) {
      try {
        final url = Uri.parse("http://10.0.2.2:5000/update_preferences");
        final body = jsonEncode({
          "device_id": deviceId,
          "language": newLang,
        });

        await http.post(
          url,
          headers: {"Content-Type": "application/json"},
          body: body,
        );
      } catch (e) {
        print("❌ Failed to sync language with backend: $e");
      }
    } else {
      print("⚠️ No device_id found — skipped backend sync");
    }
  }
}

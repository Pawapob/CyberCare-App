import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'config.dart'; // 🔥 1. Import ไฟล์ Config (อยู่โฟลเดอร์เดียวกัน)

class LanguageProvider extends ChangeNotifier {
  String _lang = "en";
  String get lang => _lang;

  LanguageProvider() {
    _loadLang();
  }

  // โหลดค่าภาษาที่เคยบันทึกไว้ (ครั้งแรกตอนเปิดแอป)
  Future<void> _loadLang() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString("lang");
      if (saved != null) {
        _lang = saved;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("LOAD LANGUAGE ERROR: $e");
    }
  }

  // เปลี่ยนภาษาแบบไม่ค้าง UI (Optimistic UI)
  void setLang(String newLang) {
    // 1) อัปเดตหน้าจอทันที
    _lang = newLang;
    notifyListeners();

    // 2) งานหนักทำหลังไมค์ (ไม่ await)
    Future.microtask(() async {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("lang", newLang);

        final deviceId = prefs.getString("device_id");
        if (deviceId != null) {
          _syncToBackend(deviceId, newLang);
        }
      } catch (e) {
        debugPrint("SAVE LANGUAGE ERROR: $e");
      }
    });
  }

  // ส่งค่าภาษาไป backend แบบเงียบ ๆ
  Future<void> _syncToBackend(String deviceId, String lang) async {
    try {
      // 🔥 2. แก้ให้ใช้ URL จาก Config
      final url = Uri.parse("${Config.baseUrl}/update_preferences");

      final body = jsonEncode({
        "device_id": deviceId,
        "language": lang,
        "mode": "realtime",
        "include_cyber_attack": false,
        "time1": null,
        "time2": null,
        "time3": null,
      });

      final resp = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "ngrok-skip-browser-warning": "1",
        },
        body: body,
      ).timeout(const Duration(seconds: 5));

      debugPrint("LANG SYNC -> ${resp.statusCode} | ${resp.body}");
    } catch (e) {
      debugPrint("LANG SYNC ERROR: $e");
    }
  }
}
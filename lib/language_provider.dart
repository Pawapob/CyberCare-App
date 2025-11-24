import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LanguageProvider extends ChangeNotifier {
  String _lang = "en";
  String get lang => _lang;

  LanguageProvider() {
    _loadLang();
  }

  // ✅ โหลดค่าภาษาอย่างรวดเร็ว และ notify ทันทีที่ได้ค่า
  Future<void> _loadLang() async {
    final prefs = await SharedPreferences.getInstance();
    // ถ้าเคยเลือกภาษาไว้แล้ว ให้ใช้ค่านั้น ถ้าไม่เคยให้เป็น 'en'
    String? savedLang = prefs.getString("lang");

    if (savedLang != null) {
      _lang = savedLang;
      // แจ้งเตือน UI ว่าค่าเปลี่ยนแล้วนะ (สำคัญมาก!)
      notifyListeners();
    }
  }

  // ✅ เปลี่ยนภาษา + บันทึก + ส่ง Backend
  Future<void> setLang(String newLang) async {
    // 1. อัปเดตค่าในตัวแปรทันทีเพื่อให้ UI เปลี่ยนไวที่สุด
    _lang = newLang;
    notifyListeners();

    // 2. บันทึกลงเครื่อง
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("lang", newLang);

    // 3. ส่งไป Backend (ทำเงียบๆ ไม่ต้องรอ)
    final deviceId = prefs.getString("device_id");
    if (deviceId != null) {
      _syncToBackend(deviceId, newLang);
    }
  }

  // แยกฟังก์ชัน sync ออกมาเพื่อให้โค้ดสะอาดและไม่บล็อก UI
  Future<void> _syncToBackend(String deviceId, String langCode) async {
    try {
      final url = Uri.parse("http://10.0.2.2:5000/update_preferences");
      // ส่งเฉพาะภาษา ส่วนอื่นๆ ให้ Backend ใช้ค่าเดิม (ถ้า Backend รองรับ)
      // หรือถ้า Backend บังคับส่งครบ ต้องระวังตรงนี้ (แต่ตามโค้ด Backend ที่ให้ไปล่าสุด มันรองรับการ update บางค่าได้)
      final body = jsonEncode({
        "device_id": deviceId,
        "language": langCode,
        // ส่งค่า default ไปกันเหนียว ถ้า backend ต้องการ
        "mode": "3-times",
        "time1": null,
        "time2": null,
        "time3": null,
      });

      await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );
    } catch (e) {
      print("❌ Failed to sync language with backend: $e");
    }
  }
}
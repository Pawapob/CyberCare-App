import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../language_provider.dart';

// ===================== Localized Strings =====================
Map<String, Map<String, String>> localizedStrings = {
  "en": {
    "settingsTitle": "Settings",
    "language": "Language",
    "alerts": "Alerts",
    "alertsSubtitle": "Notification time preferences",
    "timeSetting": "Time Setting",
    "timesDay": "3 times/day mode (recommended)",
    "onMode": "ON = Select up to 3 times/day",
    "offMode": "OFF = Real-time mode",
    "alertMode": "Alert Mode",
    "alertHybrid":
    "Hybrid: Severe alerts notify in real-time, others follow the selected schedule",
    "alertRealtime": "Will send notifications in real-time",
    "resetButton": "Reset to recommended (07:00 - 12:30 - 20:30)",
    "setTime": "Set Time",
    "cancel": "Cancel",
    "save": "Save",
  },
  "th": {
    "settingsTitle": "การตั้งค่า",
    "language": "ภาษา",
    "alerts": "การแจ้งเตือน",
    "alertsSubtitle": "การตั้งค่าการแจ้งเตือน",
    "timeSetting": "การตั้งค่าเวลา",
    "timesDay": "3 ครั้ง/วัน (แนะนำ)",
    "onMode": "เปิด = เลือกเวลาได้สูงสุด 3 ครั้ง/วัน",
    "offMode": "ปิด = โหมดเรียลไทม์",
    "alertMode": "โหมดแจ้งเตือน",
    "alertHybrid":
    "ไฮบริด: การแจ้งเตือนรุนแรงจะแจ้งทันที ส่วนอื่น ๆ จะส่งตามเวลาที่ตั้งไว้",
    "alertRealtime": "ระบบจะแจ้งเตือนแบบเรียลไทม์",
    "resetButton": "รีเซ็ตเป็นค่าแนะนำ (07:00 - 12:30 - 20:30)",
    "setTime": "ตั้งเวลา",
    "cancel": "ยกเลิก",
    "save": "บันทึก",
  }
};

// ===================== Helper Functions =====================
Future<String> getOrCreateDeviceId() async {
  final prefs = await SharedPreferences.getInstance();
  String? id = prefs.getString("device_id");
  if (id == null) {
    id = DateTime.now().millisecondsSinceEpoch.toString();
    await prefs.setString("device_id", id);
  }
  return id;
}

Future<void> updatePreferences({
  required String deviceId,
  required String language,
  required bool enabled3Times,
  List<TimeOfDay>? times,
}) async {
  final url = Uri.parse("http://10.0.2.2:5000/update_preferences");

  final body = {
    "device_id": deviceId,
    "language": language,
    "mode": enabled3Times ? "3-times" : "realtime",
  };

  if (enabled3Times && times != null && times.length == 3) {
    body["time1"] = "${times[0].hour}:${times[0].minute}:00";
    body["time2"] = "${times[1].hour}:${times[1].minute}:00";
    body["time3"] = "${times[2].hour}:${times[2].minute}:00";
  }

  final res = await http.post(
    url,
    headers: {"Content-Type": "application/json"},
    body: jsonEncode(body),
  );

  print("Update Preferences response: ${res.body}");
}

// ===================================================
// Settings Page
// ===================================================
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context).lang;
    final text = localizedStrings[lang]!;

    return Scaffold(
      appBar: AppBar(
        title: Text(text["settingsTitle"]!),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.white,
          statusBarIconBrightness: Brightness.dark,
        ),
      ),
      body: ListView(
        children: [
          // ---------- Language ----------
          ListTile(
            title: Text(text["language"]!),
            subtitle: Text(lang == "en" ? "English" : "ไทย"),
            trailing: DropdownButton<String>(
              value: lang,
              items: const [
                DropdownMenuItem(value: "en", child: Text("English")),
                DropdownMenuItem(value: "th", child: Text("ไทย")),
              ],
              onChanged: (val) async {
                if (val != null) {
                  Provider.of<LanguageProvider>(context, listen: false)
                      .setLang(val);

                  final deviceId = await getOrCreateDeviceId();
                  await updatePreferences(
                    deviceId: deviceId,
                    language: val,
                    enabled3Times: true,
                    times: [
                      const TimeOfDay(hour: 7, minute: 0),
                      const TimeOfDay(hour: 12, minute: 30),
                      const TimeOfDay(hour: 20, minute: 30),
                    ],
                  );
                }
              },
            ),
          ),

          // ---------- Alerts / Time Setting ----------
          ListTile(
            leading: const Icon(Icons.notifications),
            title: Text(text["alerts"]!),
            subtitle: Text(text["alertsSubtitle"]!),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TimeSettingPage(lang: lang),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ===================================================
// Time Setting Page
// ===================================================
class TimeSettingPage extends StatefulWidget {
  final String lang;
  const TimeSettingPage({super.key, required this.lang});

  @override
  State<TimeSettingPage> createState() => _TimeSettingPageState();
}

class _TimeSettingPageState extends State<TimeSettingPage> {
  bool _enabled = true;
  List<TimeOfDay> _times = [
    const TimeOfDay(hour: 7, minute: 0),
    const TimeOfDay(hour: 12, minute: 30),
    const TimeOfDay(hour: 20, minute: 30),
  ];

  // ✅ โหลดค่าจาก backend
  Future<void> loadPreferences() async {
    final deviceId = await getOrCreateDeviceId();
    final url =
    Uri.parse("http://10.0.2.2:5000/get_preferences?device_id=$deviceId");

    try {
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        setState(() {
          _enabled = (data["mode"] == "3-times");
          if (_enabled && data["time1"] != null) {
            _times = [
              _parseTime(data["time1"]),
              _parseTime(data["time2"]),
              _parseTime(data["time3"]),
            ];
          }
        });
      } else {
        print("No preferences found or server error: ${res.body}");
      }
    } catch (e) {
      print("Error loading preferences: $e");
    }
  }

  TimeOfDay _parseTime(String t) {
    final parts = t.split(":");
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  @override
  void initState() {
    super.initState();
    loadPreferences(); // ✅ โหลดค่าจาก database ตอนเปิดหน้า
  }

  Future<void> _pickTimeCupertino(int index, Map<String, String> text) async {
    TimeOfDay newTime = _times[index];
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      builder: (BuildContext builder) {
        return SizedBox(
          height: 300,
          child: Column(
            children: [
              // ปุ่ม Save / Cancel
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(text["cancel"]!,
                        style: const TextStyle(color: Colors.blue)),
                  ),
                  Text(text["setTime"]!,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () async {
                      setState(() {
                        _times[index] = newTime;
                      });

                      final deviceId = await getOrCreateDeviceId();
                      await updatePreferences(
                        deviceId: deviceId,
                        language: widget.lang,
                        enabled3Times: _enabled,
                        times: _times,
                      );

                      Navigator.pop(context);
                    },
                    child: Text(text["save"]!,
                        style: const TextStyle(color: Colors.blue)),
                  ),
                ],
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  initialDateTime: DateTime(
                    2023,
                    1,
                    1,
                    _times[index].hour,
                    _times[index].minute,
                  ),
                  use24hFormat: false,
                  onDateTimeChanged: (DateTime newDateTime) {
                    newTime = TimeOfDay.fromDateTime(newDateTime);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatTime(TimeOfDay t) => t.format(context);

  @override
  Widget build(BuildContext context) {
    var text = localizedStrings[widget.lang]!;

    return Scaffold(
      appBar: AppBar(
        title: Text(text["timeSetting"]!),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Toggle
            SwitchListTile(
              title: Text(text["timesDay"]!),
              subtitle: Text(
                _enabled ? text["onMode"]! : text["offMode"]!,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              value: _enabled,
              onChanged: (val) async {
                setState(() {
                  _enabled = val;
                });

                final deviceId = await getOrCreateDeviceId();
                await updatePreferences(
                  deviceId: deviceId,
                  language: widget.lang,
                  enabled3Times: _enabled,
                  times: _times,
                );
              },
            ),

            if (_enabled) ...[
              Wrap(
                spacing: 8,
                children: List.generate(_times.length, (index) {
                  final t = _times[index];
                  return ElevatedButton(
                    onPressed: () => _pickTimeCupertino(index, text),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      elevation: 2,
                      shadowColor: Colors.grey.withOpacity(0.4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(_formatTime(t)),
                  );
                }),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () async {
                  setState(() {
                    _times = [
                      const TimeOfDay(hour: 7, minute: 0),
                      const TimeOfDay(hour: 12, minute: 30),
                      const TimeOfDay(hour: 20, minute: 30),
                    ];
                  });

                  final deviceId = await getOrCreateDeviceId();
                  await updatePreferences(
                    deviceId: deviceId,
                    language: widget.lang,
                    enabled3Times: true,
                    times: _times,
                  );
                },
                icon: const Icon(Icons.refresh, color: Colors.blue),
                label: Text(
                  text["resetButton"]!,
                  style: const TextStyle(color: Colors.blue),
                ),
              ),
            ],

            const SizedBox(height: 16),

            Card(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  _enabled
                      ? "${text["alertMode"]}\n${text["alertHybrid"]} "
                      "(${_times.map((t) => _formatTime(t)).join(" – ")})."
                      : "${text["alertMode"]}\n${text["alertRealtime"]}",
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

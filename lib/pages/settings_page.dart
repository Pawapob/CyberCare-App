import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';

// =========================================
// Localized Strings (EN + TH)
// =========================================
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

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _selectedLang = "en";

  @override
  Widget build(BuildContext context) {
    var text = localizedStrings[_selectedLang]!;

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
            subtitle: Text(_selectedLang == "en" ? "English" : "ไทย"),
            trailing: DropdownButton<String>(
              value: _selectedLang,
              items: const [
                DropdownMenuItem(value: "en", child: Text("English")),
                DropdownMenuItem(value: "th", child: Text("ไทย")),
              ],
              onChanged: (val) {
                setState(() {
                  _selectedLang = val!;
                });
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
                  builder: (context) => TimeSettingPage(lang: _selectedLang),
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

  // picker แบบ iOS โทนฟ้า-ขาว
  Future<void> _pickTimeCupertino(int index, Map<String, String> text) async {
    TimeOfDay newTime = _times[index];
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white, // ✅ พื้นหลัง bottom sheet ขาว
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
                    onPressed: () {
                      setState(() {
                        _times[index] = newTime;
                      });
                      Navigator.pop(context);
                    },
                    child: Text(text["save"]!,
                        style: const TextStyle(color: Colors.blue)),
                  ),
                ],
              ),
              Expanded(
                child: CupertinoTheme(
                  data: const CupertinoThemeData(
                    brightness: Brightness.light,
                    primaryColor: Colors.blue,
                    scaffoldBackgroundColor: Colors.white,
                    barBackgroundColor: Colors.white,
                  ),
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.time,
                    initialDateTime: DateTime(
                      2023, 1, 1, _times[index].hour, _times[index].minute,
                    ),
                    use24hFormat: false,
                    onDateTimeChanged: (DateTime newDateTime) {
                      newTime = TimeOfDay.fromDateTime(newDateTime);
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatTime(TimeOfDay t) {
    return t.format(context);
  }

  @override
  Widget build(BuildContext context) {
    var text = localizedStrings[widget.lang]!;

    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        switchTheme: SwitchThemeData(
          thumbColor: MaterialStateProperty.resolveWith<Color>(
                (states) => states.contains(MaterialState.selected)
                ? Colors.blue
                : Colors.grey,
          ),
          trackColor: MaterialStateProperty.resolveWith<Color>(
                (states) => states.contains(MaterialState.selected)
                ? Colors.blue.shade200
                : Colors.grey.shade400,
          ),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text(text["timeSetting"]!),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.white,
            statusBarIconBrightness: Brightness.dark,
          ),
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
                onChanged: (val) {
                  setState(() {
                    _enabled = val;
                  });
                },
              ),

              // ✅ ON = 3 ปุ่ม active, OFF = ไม่มีปุ่มเลย
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
                  onPressed: () {
                    setState(() {
                      _times = [
                        const TimeOfDay(hour: 7, minute: 0),
                        const TimeOfDay(hour: 12, minute: 30),
                        const TimeOfDay(hour: 20, minute: 30),
                      ];
                    });
                  },
                  icon: const Icon(Icons.refresh, color: Colors.blue),
                  label: Text(
                    text["resetButton"]!,
                    style: const TextStyle(color: Colors.blue),
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // การ์ด Alert Mode
              Card(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    _enabled
                        ? "${text["alertMode"]}\n"
                        "${text["alertHybrid"]} "
                        "(${_times.map((t) => _formatTime(t)).join(" – ")})."
                        : "${text["alertMode"]}\n"
                        "${text["alertRealtime"]}",
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

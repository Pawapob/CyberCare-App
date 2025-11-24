import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
// 🔥 1. Import Tutorial Package
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import '../language_provider.dart';

// ===================== Localized Strings =====================
Map<String, Map<String, String>> localizedStrings = {
  "en": {
    "settingsTitle": "Settings",
    "language": "Language",
    "alerts": "Alerts",
    "alertsSubtitle": "Notification time preferences",
    "timeSetting": "Time Setting",
    "timesDay": "Scheduled Mode",
    "onMode": "ON = Notifications at set times",
    "offMode": "OFF = Real-time mode",
    "frequency": "Frequency per day",
    "times": "time(s)",
    "resetButton": "Reset to default (3 times)",
    "alertMode": "Alert Mode",
    "alertHybrid": "Hybrid: Severe alerts notify in real-time, others follow the selected schedule",
    "alertRealtime": "Will send notifications in real-time",
    "setTime": "Set Time",
    "cancel": "Cancel",
    "save": "Save",
    // --- Tutorial Settings Page ---
    "tutorialLangTitle": "Change Language",
    "tutorialLangDesc": "Tap here to switch between Thai and English.",
    "tutorialAlertTitle": "Notification Settings",
    "tutorialAlertDesc": "Tap here to configure when you want to receive security alerts.",
    // 🔥 --- Tutorial TimeSetting Page ---
    "tutorialRealtimeTitle": "Real-time vs Scheduled",
    "tutorialRealtimeDesc": "Toggle OFF for immediate alerts. Toggle ON to schedule summaries.",
    "tutorialFreqTitle": "Select Frequency",
    "tutorialFreqDesc": "Choose how many times per day (1-3) you want to receive notifications.",
    "tutorialSkip": "SKIP",
  },
  "th": {
    "settingsTitle": "การตั้งค่า",
    "language": "ภาษา",
    "alerts": "การแจ้งเตือน",
    "alertsSubtitle": "การตั้งค่าการแจ้งเตือน",
    "timeSetting": "การตั้งค่าเวลา",
    "timesDay": "โหมดตั้งเวลาแจ้งเตือน",
    "onMode": "เปิด = แจ้งเตือนตามเวลาที่กำหนด",
    "offMode": "ปิด = โหมดเรียลไทม์ (แจ้งทันที)",
    "frequency": "จำนวนครั้งต่อวัน",
    "times": "ครั้ง",
    "resetButton": "รีเซ็ตเป็นค่าเริ่มต้น (3 ครั้ง)",
    "alertMode": "โหมดแจ้งเตือน",
    "alertHybrid": "ไฮบริด: การแจ้งเตือนรุนแรงจะแจ้งทันที ส่วนอื่น ๆ จะส่งตามเวลาที่ตั้งไว้",
    "alertRealtime": "ระบบจะแจ้งเตือนแบบเรียลไทม์",
    "setTime": "ตั้งเวลา",
    "cancel": "ยกเลิก",
    "save": "บันทึก",
    // --- Tutorial Settings Page ---
    "tutorialLangTitle": "เปลี่ยนภาษา",
    "tutorialLangDesc": "กดตรงนี้เพื่อเปลี่ยนภาษาของแอปพลิเคชัน (ไทย/English)",
    "tutorialAlertTitle": "ตั้งค่าการแจ้งเตือน",
    "tutorialAlertDesc": "กดตรงนี้เพื่อเข้าไปกำหนดเวลาในการรับการแจ้งเตือนความปลอดภัย",
    // 🔥 --- Tutorial TimeSetting Page ---
    "tutorialRealtimeTitle": "โหมดเรียลไทม์",
    "tutorialRealtimeDesc": "ปิดสวิตช์: แจ้งเตือนทันทีเมื่อมีภัยคุกคาม (Real-time)\nเปิดสวิตช์: แจ้งเตือนตามเวลาที่กำหนด",
    "tutorialFreqTitle": "เลือกความถี่",
    "tutorialFreqDesc": "คุณสามารถเลือกให้แจ้งเตือนได้ 1, 2 หรือ 3 ครั้งต่อวัน",
    "tutorialSkip": "ข้าม",
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
    "time1": null,
    "time2": null,
    "time3": null,
  };

  if (enabled3Times && times != null) {
    if (times.isNotEmpty) body["time1"] = "${times[0].hour}:${times[0].minute}:00";
    if (times.length >= 2) body["time2"] = "${times[1].hour}:${times[1].minute}:00";
    if (times.length >= 3) body["time3"] = "${times[2].hour}:${times[2].minute}:00";
  }

  try {
    final res = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );
    print("Update Preferences response: ${res.body}");
  } catch (e) {
    print("Error updating preferences: $e");
  }
}

TimeOfDay _parseTime(String t) {
  final parts = t.split(":");
  return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
}

// ===================================================
// Settings Page
// ===================================================
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final GlobalKey languageKey = GlobalKey();
  final GlobalKey alertKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    checkTutorial();
  }

  void markTutorialAsSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenSettingsTutorial', true);
  }

  void checkTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    bool hasSeen = prefs.getBool('hasSeenSettingsTutorial') ?? false;

    if (!hasSeen) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) showTutorial();
      });
    }
  }

  void showTutorial() {
    final lang = Provider.of<LanguageProvider>(context, listen: false).lang;
    final text = localizedStrings[lang]!;

    TutorialCoachMark(
      targets: [
        TargetFocus(
          identify: "LanguageSetting",
          keyTarget: languageKey,
          shape: ShapeLightFocus.RRect,
          radius: 5,
          contents: [
            TargetContent(
              align: ContentAlign.bottom,
              builder: (context, controller) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      text["tutorialLangTitle"]!,
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      text["tutorialLangDesc"]!,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        TargetFocus(
          identify: "AlertSetting",
          keyTarget: alertKey,
          shape: ShapeLightFocus.RRect,
          radius: 5,
          contents: [
            TargetContent(
              align: ContentAlign.bottom,
              builder: (context, controller) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      text["tutorialAlertTitle"]!,
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      text["tutorialAlertDesc"]!,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
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
      onFinish: () => markTutorialAsSeen(),
      onSkip: () {
        markTutorialAsSeen();
        return true;
      },
    ).show(context: context);
  }

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
          ListTile(
            key: languageKey,
            title: Text(text["language"]!),
            subtitle: Text(lang == "en" ? "English" : "ไทย"),
            trailing: DropdownButton<String>(
              value: lang,
              dropdownColor: Colors.white,
              style: const TextStyle(color: Colors.black),
              items: const [
                DropdownMenuItem(value: "en", child: Text("English")),
                DropdownMenuItem(value: "th", child: Text("ไทย")),
              ],
              onChanged: (val) async {
                if (val != null) {
                  Provider.of<LanguageProvider>(context, listen: false).setLang(val);
                  final deviceId = await getOrCreateDeviceId();
                  await updatePreferences(
                    deviceId: deviceId,
                    language: val,
                    enabled3Times: true, // Dummy value, updated properly in TimeSettingPage
                    times: null,
                  );
                }
              },
            ),
          ),
          ListTile(
            key: alertKey,
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
// 🔥 Time Setting Page (With Tutorial)
// ===================================================
class TimeSettingPage extends StatefulWidget {
  final String lang;
  const TimeSettingPage({super.key, required this.lang});

  @override
  State<TimeSettingPage> createState() => _TimeSettingPageState();
}

class _TimeSettingPageState extends State<TimeSettingPage> {
  bool _enabled = true;
  int _frequency = 3;
  List<TimeOfDay> _times = [
    const TimeOfDay(hour: 7, minute: 0),
    const TimeOfDay(hour: 12, minute: 30),
    const TimeOfDay(hour: 20, minute: 30),
  ];

  // 🔥 Keys for Tutorial
  final GlobalKey timeSwitchKey = GlobalKey();
  final GlobalKey frequencyKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    loadPreferences();
    checkTutorial();
  }

  // --- Tutorial Logic ---
  void checkTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    // ใช้คนละ Key กับหน้าหลัก
    bool hasSeen = prefs.getBool('hasSeenTimeSettingTutorial') ?? false;

    if (!hasSeen) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) showTutorial();
      });
    }
  }

  void showTutorial() {
    final text = localizedStrings[widget.lang]!;

    List<TargetFocus> targets = [];

    // 1. สอนสวิตช์เปิด/ปิด (Real-time)
    targets.add(
      TargetFocus(
        identify: "TimeSwitch",
        keyTarget: timeSwitchKey,
        shape: ShapeLightFocus.RRect,
        radius: 5,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(text["tutorialRealtimeTitle"]!,
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text(text["tutorialRealtimeDesc"]!,
                      style: const TextStyle(color: Colors.white, fontSize: 16)),
                ],
              );
            },
          ),
        ],
      ),
    );

    // 2. สอนเลือกความถี่ (ถ้าเปิดอยู่)
    if (_enabled) {
      targets.add(
        TargetFocus(
          identify: "Frequency",
          keyTarget: frequencyKey,
          shape: ShapeLightFocus.RRect,
          radius: 5,
          contents: [
            TargetContent(
              align: ContentAlign.bottom,
              builder: (context, controller) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(text["tutorialFreqTitle"]!,
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Text(text["tutorialFreqDesc"]!,
                        style: const TextStyle(color: Colors.white, fontSize: 16)),
                  ],
                );
              },
            ),
          ],
        ),
      );
    }

    TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.black,
      textSkip: text["tutorialSkip"]!,
      paddingFocus: 10,
      opacityShadow: 0.85,
      onFinish: () => markTutorialAsSeen(),
      onSkip: () {
        markTutorialAsSeen();
        return true;
      },
    ).show(context: context);
  }

  void markTutorialAsSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenTimeSettingTutorial', true);
  }
  // --- End Tutorial Logic ---

  Future<void> loadPreferences() async {
    final deviceId = await getOrCreateDeviceId();
    final url = Uri.parse("http://10.0.2.2:5000/get_preferences?device_id=$deviceId");

    try {
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _enabled = (data["mode"] == "3-times");
          List<TimeOfDay> loadedTimes = [];
          if (data["time1"] != null) loadedTimes.add(_parseTime(data["time1"]));
          if (data["time2"] != null) loadedTimes.add(_parseTime(data["time2"]));
          if (data["time3"] != null) loadedTimes.add(_parseTime(data["time3"]));

          if (loadedTimes.isNotEmpty) {
            _frequency = loadedTimes.length;
            for (int i = 0; i < loadedTimes.length; i++) {
              _times[i] = loadedTimes[i];
            }
          } else {
            _frequency = 3;
          }
        });
      }
    } catch (e) {
      print("Error loading preferences: $e");
    }
  }

  Future<void> _saveConfig() async {
    final deviceId = await getOrCreateDeviceId();
    List<TimeOfDay> activeTimes = _times.sublist(0, _frequency);
    await updatePreferences(
      deviceId: deviceId,
      language: widget.lang,
      enabled3Times: _enabled,
      times: activeTimes,
    );
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(text["cancel"]!, style: const TextStyle(color: Colors.blue)),
                  ),
                  Text(text["setTime"]!, style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () async {
                      setState(() {
                        _times[index] = newTime;
                      });
                      await _saveConfig();
                      Navigator.pop(context);
                    },
                    child: Text(text["save"]!, style: const TextStyle(color: Colors.blue)),
                  ),
                ],
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  initialDateTime: DateTime(2023, 1, 1, _times[index].hour, _times[index].minute),
                  use24hFormat: false,
                  onDateTimeChanged: (DateTime t) {
                    newTime = TimeOfDay.fromDateTime(t);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

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
            SwitchListTile(
              key: timeSwitchKey,
              title: Text(text["timesDay"]!, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                _enabled ? text["onMode"]! : text["offMode"]!,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              value: _enabled,
              activeColor: Colors.blue,
              activeTrackColor: Colors.blue[200],
              onChanged: (val) async {
                setState(() => _enabled = val);
                await _saveConfig();
              },
            ),

            if (_enabled) ...[
              const Divider(),
              const SizedBox(height: 10),

              Row(
                key: frequencyKey,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(text["frequency"]!, style: const TextStyle(fontSize: 16)),
                  DropdownButton<int>(
                    value: _frequency,
                    dropdownColor: Colors.white,
                    items: [1, 2, 3].map((int val) {
                      return DropdownMenuItem<int>(
                        value: val,
                        child: Text("$val ${text['times']}"),
                      );
                    }).toList(),
                    onChanged: (val) async {
                      if (val != null) {
                        setState(() => _frequency = val);
                        await _saveConfig();
                      }
                    },
                  ),
                ],
              ),

              const SizedBox(height: 15),

              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: List.generate(_frequency, (index) {
                  final t = _times[index];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Time ${index + 1}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 4),
                      ElevatedButton(
                        onPressed: () => _pickTimeCupertino(index, text),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          elevation: 1,
                          side: const BorderSide(color: Colors.blueAccent),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          // 🔥 เปลี่ยนตรงนี้ครับ เป็นมุมโค้ง 30
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        child: Text(
                          t.format(context),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  );
                }),
              ),

              const SizedBox(height: 30),

              Center(
                child: TextButton.icon(
                  onPressed: () async {
                    setState(() {
                      _frequency = 3;
                      _times = [
                        const TimeOfDay(hour: 7, minute: 0),
                        const TimeOfDay(hour: 12, minute: 30),
                        const TimeOfDay(hour: 20, minute: 30),
                      ];
                    });
                    await _saveConfig();
                  },
                  icon: const Icon(Icons.refresh, color: Colors.grey),
                  label: Text(text["resetButton"]!, style: const TextStyle(color: Colors.grey)),
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
                      "(${_times.sublist(0, _frequency).map((t) => t.format(context)).join(" – ")})."
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
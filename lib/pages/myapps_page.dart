import 'package:flutter/material.dart';

/// ====== ข้อมูล/ชนิดในไฟล์เดียว ======
enum AlertStatus { on, off }

class AppItem {
  final String id;
  final String name;
  final String packageName;
  final DateTime installedAt;
  final bool scanned;
  final AlertStatus alertStatus;

  const AppItem({
    required this.id,
    required this.name,
    required this.packageName,
    required this.installedAt,
    required this.scanned,
    required this.alertStatus,
  });

  AppItem copyWith({
    String? id,
    String? name,
    String? packageName,
    DateTime? installedAt,
    bool? scanned,
    AlertStatus? alertStatus,
  }) {
    return AppItem(
      id: id ?? this.id,
      name: name ?? this.name,
      packageName: packageName ?? this.packageName,
      installedAt: installedAt ?? this.installedAt,
      scanned: scanned ?? this.scanned,
      alertStatus: alertStatus ?? this.alertStatus,
    );
  }
}

enum _MyAppsTab { all, alertOn, alertOff }

class _Store {
  List<AppItem> apps = [];
  String query = '';

  bool get hasScanned => apps.isNotEmpty && apps.every((e) => e.scanned);

  void seed() {
    final now = DateTime.now();
    apps = [
      AppItem(
        id: '1',
        name: 'Facebook',
        packageName: 'com.facebook.katana',
        installedAt: now.subtract(const Duration(days: 7)),
        scanned: true, // เปิดให้เห็นรายการตอนพัฒนา
        alertStatus: AlertStatus.on,
      ),
      AppItem(
        id: '2',
        name: 'LINE',
        packageName: 'jp.naver.line.android',
        installedAt: now.subtract(const Duration(days: 3)),
        scanned: true,
        alertStatus: AlertStatus.off,
      ),
      AppItem(
        id: '3',
        name: 'Chrome',
        packageName: 'com.android.chrome',
        installedAt: now.subtract(const Duration(days: 20)),
        scanned: true,
        alertStatus: AlertStatus.off,
      ),
    ];
  }

  List<AppItem> _byQuery(List<AppItem> list) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return list;
    return list
        .where((a) =>
    a.name.toLowerCase().contains(q) ||
        a.packageName.toLowerCase().contains(q))
        .toList();
  }

  List<AppItem> byTab(_MyAppsTab tab) {
    final base = _byQuery(apps);
    switch (tab) {
      case _MyAppsTab.all:
        return base;
      case _MyAppsTab.alertOn:
        return base.where((e) => e.alertStatus == AlertStatus.on).toList();
      case _MyAppsTab.alertOff:
        return base.where((e) => e.alertStatus == AlertStatus.off).toList();
    }
  }

  void toggle(AppItem app) {
    final i = apps.indexWhere((e) => e.id == app.id);
    if (i == -1) return;
    apps[i] = app.copyWith(
      alertStatus:
      app.alertStatus == AlertStatus.on ? AlertStatus.off : AlertStatus.on,
    );
  }

  void openAllInTab(_MyAppsTab tab) {
    final ids = byTab(tab).map((e) => e.id).toSet();
    apps = apps
        .map((a) =>
    ids.contains(a.id) ? a.copyWith(alertStatus: AlertStatus.on) : a)
        .toList();
  }

  void closeAllInTab(_MyAppsTab tab) {
    final ids = byTab(tab).map((e) => e.id).toSet();
    apps = apps
        .map((a) =>
    ids.contains(a.id) ? a.copyWith(alertStatus: AlertStatus.off) : a)
        .toList();
  }
}

/// ====== หน้า My Apps ======
class MyAppsPage extends StatefulWidget {
  const MyAppsPage({super.key});
  @override
  State<MyAppsPage> createState() => _MyAppsPageState();
}

class _MyAppsPageState extends State<MyAppsPage> {
  final _store = _Store();
  _MyAppsTab _tab = _MyAppsTab.all;

  @override
  void initState() {
    super.initState();
    _store.seed();
  }

  @override
  Widget build(BuildContext context) {
    final items = _store.byTab(_tab);

    return Scaffold(
      backgroundColor: Colors.white, // พื้นหลังขาว
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        title: const Text('My Application'),
      ),
      body: Column(
        children: [
          // ====== Search bar : ไอคอนแว่นอยู่ขวา ======
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(.08),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.black12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              height: 44,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (v) => setState(() => _store.query = v),
                      decoration: const InputDecoration(
                        hintText: 'Hinted search text',
                        border: InputBorder.none,
                        isCollapsed: true,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => FocusScope.of(context).unfocus(),
                    icon: const Icon(Icons.search),
                    splashRadius: 20,
                  ),
                ],
              ),
            ),
          ),

          // ====== ฟิลเตอร์ชิปโทนฟ้า-ขาว ======
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _FilterChip(
                  label: 'All',
                  selected: _tab == _MyAppsTab.all,
                  onTap: () => setState(() => _tab = _MyAppsTab.all),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Alerts On',
                  selected: _tab == _MyAppsTab.alertOn,
                  onTap: () => setState(() => _tab = _MyAppsTab.alertOn),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Alerts Off',
                  selected: _tab == _MyAppsTab.alertOff,
                  onTap: () => setState(() => _tab = _MyAppsTab.alertOff),
                ),
              ],
            ),
          ),

          // ====== รายการแบบ iOS-style: พื้นหลังขาว + Divider ======
          Expanded(
            child: !_store.hasScanned
                ? const _EmptyState(
              textTop: 'There is no app',
              textBottom: 'you have to scan first',
            )
                : items.isEmpty
                ? const _EmptyState(
              textTop: 'No apps found',
              textBottom: 'try adjusting your search',
            )
                : ListView.separated(
              itemCount: items.length,
              separatorBuilder: (context, _) =>
              const Divider(height: 1, color: Colors.black12),
              itemBuilder: (ctx, i) {
                final app = items[i];
                final installedAgo =
                    DateTime.now().difference(app.installedAt).inDays;
                return ListTile(
                  tileColor: Colors.white,
                  title: Text(
                    app.name,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    'Installed ~ $installedAgo d • ${app.packageName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 13,
                    ),
                  ),
                  // ไม่มีโลโก้/ไอคอนนำหน้า ตามที่ขอ
                  trailing: Switch(
                    value: app.alertStatus == AlertStatus.on,
                    onChanged: (_) =>
                        setState(() => _store.toggle(app)),

                    // ====== โทนสีสวิตช์แบบ iOS ======
                    activeColor: Colors.white,        // ปุ่มวงกลมตอน ON
                    activeTrackColor: Colors.blue,    // แถบเมื่อ ON = ฟ้า
                    inactiveThumbColor: Colors.white, // ปุ่มวงกลมตอน OFF
                    inactiveTrackColor: Colors.grey,  // แถบเมื่อ OFF = เทา
                  ),
                );
              },
            ),
          ),
        ],
      ),

      // ====== ปุ่ม Open All / Close All (โทนฟ้า) ======
      bottomNavigationBar: _showBulkButtons(items)
          ? SafeArea(
        child: Padding(
          padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              if (_tab == _MyAppsTab.alertOn)
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                      side: const BorderSide(color: Colors.blue),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      setState(() => _store.closeAllInTab(_tab));
                      _toast(context, 'Closed all alerts');
                    },
                    child: const Text('Close All'),
                  ),
                ),
              if (_tab == _MyAppsTab.alertOn &&
                  _tab == _MyAppsTab.alertOff)
                const SizedBox(width: 12),
              if (_tab == _MyAppsTab.alertOff)
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      setState(() => _store.openAllInTab(_tab));
                      _toast(context, 'Opened all alerts');
                    },
                    child: const Text('Open All'),
                  ),
                ),
            ],
          ),
        ),
      )
          : null,
    );
  }

  bool _showBulkButtons(List<AppItem> items) {
    if (!_store.hasScanned) return false;
    if (items.isEmpty) return false;
    return _tab == _MyAppsTab.alertOn || _tab == _MyAppsTab.alertOff;
  }

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}

/// ====== Widgets ย่อย ======
class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      labelStyle: TextStyle(
        color: Colors.black87,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
      ),
      backgroundColor: Colors.grey.shade200,
      selectedColor: Colors.blue.shade100,
      side: BorderSide(color: selected ? Colors.blue : Colors.black12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String textTop;
  final String textBottom;
  const _EmptyState({required this.textTop, required this.textBottom});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '$textTop\n$textBottom',
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.black54),
      ),
    );
  }
}

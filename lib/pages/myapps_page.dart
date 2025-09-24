import 'package:flutter/material.dart';

/// ====== โมเดล/ชนิดข้อมูล (อยู่ไฟล์นี้ไฟล์เดียว) ======
enum AlertStatus { on, off }

class AppItem {
  final String id;
  final String name;
  final String packageName;
  final DateTime installedAt;
  final bool scanned; // true = แอปนี้ถูกนับว่า "สแกนแล้ว"
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

/// ====== หน้า My Apps (รวมทั้ง UI + ระบบภายใน) ======
class MyAppsPage extends StatefulWidget {
  const MyAppsPage({super.key});

  @override
  State<MyAppsPage> createState() => _MyAppsPageState();
}

enum _MyAppsTab { all, alertOn, alertOff }

class _MyAppsStateStore {
  /// เก็บรายการแอปทั้งหมดในเครื่อง (mock ไว้ทดสอบ UI)
  List<AppItem> apps = [];

  /// คีย์เวิร์ดค้นหา
  String query = '';

  /// ถือสถานะรวม "สแกนแล้วหรือยัง" = ต้องเป็น true ทั้งลิสต์จึงจะถือว่าสแกนเสร็จ
  bool get hasScanned => apps.isNotEmpty && apps.every((a) => a.scanned);

  /// รีเฟรช mock เริ่มต้น
  void seed() {
    final now = DateTime.now();
    apps = [
      AppItem(
        id: '1',
        name: 'Facebook',
        packageName: 'com.facebook.katana',
        installedAt: now.subtract(const Duration(days: 7)),
        scanned: false, // เริ่มแบบ "ยังไม่สแกน"
        alertStatus: AlertStatus.on,
      ),
      AppItem(
        id: '2',
        name: 'LINE',
        packageName: 'jp.naver.line.android',
        installedAt: now.subtract(const Duration(days: 3)),
        scanned: false,
        alertStatus: AlertStatus.off,
      ),
      AppItem(
        id: '3',
        name: 'Chrome',
        packageName: 'com.android.chrome',
        installedAt: now.subtract(const Duration(days: 20)),
        scanned: false,
        alertStatus: AlertStatus.on,
      ),
      AppItem(
        id: '4',
        name: 'YouTube',
        packageName: 'com.google.android.youtube',
        installedAt: now.subtract(const Duration(days: 2)),
        scanned: false,
        alertStatus: AlertStatus.off,
      ),
    ];
  }

  /// ค้นหาตามชื่อ/แพ็กเกจ
  List<AppItem> filterByQuery(List<AppItem> list) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return list;
    return list
        .where((a) =>
    a.name.toLowerCase().contains(q) ||
        a.packageName.toLowerCase().contains(q))
        .toList();
  }

  /// คืนลิสต์ตามแท็บ
  List<AppItem> byTab(_MyAppsTab tab) {
    final base = filterByQuery(apps);
    switch (tab) {
      case _MyAppsTab.all:
        return base;
      case _MyAppsTab.alertOn:
        return base.where((a) => a.alertStatus == AlertStatus.on).toList();
      case _MyAppsTab.alertOff:
        return base.where((a) => a.alertStatus == AlertStatus.off).toList();
    }
  }

  /// Toggle แจ้งเตือนรายแอป
  void toggleAlert(AppItem app) {
    final idx = apps.indexWhere((e) => e.id == app.id);
    if (idx == -1) return;
    final to =
    app.alertStatus == AlertStatus.on ? AlertStatus.off : AlertStatus.on;
    apps[idx] = app.copyWith(alertStatus: to);
  }

  /// ทำให้ "ทุกแอปที่อยู่ในแท็บปัจจุบัน" เปิดแจ้งเตือน
  void openAllInTab(_MyAppsTab tab) {
    final ids = byTab(tab).map((e) => e.id).toSet();
    apps = apps
        .map((a) => ids.contains(a.id) ? a.copyWith(alertStatus: AlertStatus.on) : a)
        .toList();
  }

  /// ทำให้ "ทุกแอปที่อยู่ในแท็บปัจจุบัน" ปิดแจ้งเตือน
  void closeAllInTab(_MyAppsTab tab) {
    final ids = byTab(tab).map((e) => e.id).toSet();
    apps = apps
        .map((a) => ids.contains(a.id) ? a.copyWith(alertStatus: AlertStatus.off) : a)
        .toList();
  }

  /// จำลองสแกนสำเร็จ (ทุกแอปถูก mark scanned)
  void markScanned() {
    apps = apps.map((a) => a.copyWith(scanned: true)).toList();
  }

  /// รีเซ็ตกลับเป็น "ยังไม่สแกน"
  void resetUnscanned() {
    apps = apps.map((a) => a.copyWith(scanned: false)).toList();
  }
}

class _MyAppsPageState extends State<MyAppsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _store = _MyAppsStateStore();
  _MyAppsTab _tab = _MyAppsTab.all;

  @override
  void initState() {
    super.initState();
    _store.seed();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      setState(() => _tab = _MyAppsTab.values[_tabController.index]);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// ปุ่มล่าง (Open All / Close All) จะแสดงเฉพาะเมื่อ:
  /// - สแกนแล้ว และ
  /// - อยู่แท็บ Alert-on (โชว์ Close All) หรือ Alert-off (โชว์ Open All) และ
  /// - ลิสต์ในแท็บนั้นไม่ว่าง
  bool get _showBulkButtons {
    if (!_store.hasScanned) return false;
    final list = _store.byTab(_tab);
    if (list.isEmpty) return false;
    return _tab == _MyAppsTab.alertOn || _tab == _MyAppsTab.alertOff;
  }

  @override
  Widget build(BuildContext context) {
    final list = _store.byTab(_tab);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Apps'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Alert-on'),
            Tab(text: 'Alert-off'),
          ],
        ),
        actions: [
          // View All = กลับแท็บ All + ล้าง search
          TextButton(
            onPressed: () {
              setState(() {
                _tabController.animateTo(0);
                _tab = _MyAppsTab.all;
                _store.query = '';
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Showing all apps')),
              );
            },
            child: const Text('View All'),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () async {
              final text = await showSearch<String>(
                context: context,
                delegate: _AppSearchDelegate(initial: _store.query),
              );
              if (text != null) {
                setState(() => _store.query = text);
              }
            },
          ),
          PopupMenuButton<String>(
            tooltip: 'Developer',
            onSelected: (v) {
              setState(() {
                if (v == 'scan') _store.markScanned();
                if (v == 'unscan') _store.resetUnscanned();
              });
            },
            itemBuilder: (ctx) => const [
              PopupMenuItem(value: 'scan', child: Text('Mark Scanned')),
              PopupMenuItem(value: 'unscan', child: Text('Reset Unscanned')),
            ],
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTabList(_MyAppsTab.all),
          _buildTabList(_MyAppsTab.alertOn),
          _buildTabList(_MyAppsTab.alertOff),
        ],
      ),
      bottomNavigationBar: _showBulkButtons
          ? SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
          child: Row(
            children: [
              if (_tab == _MyAppsTab.alertOn)
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: () {
                      setState(() => _store.closeAllInTab(_tab));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Closed all alerts in this tab')),
                      );
                    },
                    child: const Text('Close All'),
                  ),
                ),
              if (_tab == _MyAppsTab.alertOff)
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      setState(() => _store.openAllInTab(_tab));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Opened all alerts in this tab')),
                      );
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

  Widget _buildTabList(_MyAppsTab tab) {
    // ยังไม่สแกน → แสดง empty state ตามสเปก
    if (!_store.hasScanned) {
      return _EmptyState(
        icon: Icons.shield_moon_outlined,
        title: 'No data yet',
        message: 'Please scan your device first to see your apps.',
        actionLabel: 'Go to Scan',
        onAction: () {
          // ปล่อยให้ main/เพื่อนจัดการหน้า Scan; ที่นี่ปิดหน้าปัจจุบันพอ
          Navigator.of(context).maybePop();
        },
      );
    }

    final items = _store.byTab(tab);
    if (items.isEmpty) {
      return _EmptyState(
        icon: Icons.apps_outlined,
        title: tab == _MyAppsTab.alertOn
            ? 'No apps with alerts ON'
            : tab == _MyAppsTab.alertOff
            ? 'No apps with alerts OFF'
            : 'No apps found',
        message: tab == _MyAppsTab.all
            ? 'Try adjusting your search.'
            : 'Use the bulk button below to switch all.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 96),
      itemCount: items.length,
      itemBuilder: (ctx, i) {
        final app = items[i];
        final installedAgo = DateTime.now().difference(app.installedAt).inDays;
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListTile(
            leading: CircleAvatar(
              child: Text(app.name.isNotEmpty ? app.name[0] : '?'),
            ),
            title: Text(app.name, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(
              'Installed ~ $installedAgo d • ${app.packageName}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Switch(
              value: app.alertStatus == AlertStatus.on,
              onChanged: (_) {
                setState(() => _store.toggleAlert(app));
              },
            ),
          ),
        );
      },
    );
  }
}

/// ====== คอมโพเนนต์ประกอบ (อยู่ไฟล์นี้ไฟล์เดียว) ======

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Search delegate (ค้นหาโดยไม่ต้องมีไฟล์อื่น)
class _AppSearchDelegate extends SearchDelegate<String> {
  final String initial;
  _AppSearchDelegate({required this.initial}) {
    query = initial;
  }

  @override
  List<Widget> buildActions(BuildContext context) => [
    if (query.isNotEmpty)
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      ),
  ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: () => close(context, initial),
  );

  @override
  Widget buildResults(BuildContext context) => Center(
    child: ElevatedButton(
      onPressed: () => close(context, query),
      child: const Text('Apply Search'),
    ),
  );

  @override
  Widget buildSuggestions(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Text('Search apps with keyword: $query'),
  );
}

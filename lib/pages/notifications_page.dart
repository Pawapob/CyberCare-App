import 'package:flutter/material.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  // ฟังก์ชันสำหรับแสดงรายละเอียดเมื่อกดปุ่ม Details
  void _showDetailsPopup(BuildContext context, String appName, String risk, Color riskColor) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          contentPadding: EdgeInsets.zero,
          content: Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.blue.withOpacity(0.1),
                          child: const Icon(Icons.facebook, color: Colors.blue), // แทนที่ด้วยไอคอนจริง
                        ),
                        const SizedBox(width: 8),
                        Text(
                          appName,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: riskColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "Risk : $risk",
                        style: TextStyle(
                          color: riskColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  "CVE-XXXX-XXXX",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                const Text("Your installed version is affected update to-450.1 or later."),
                const SizedBox(height: 16),
                const Text(
                  "Installed 450.0 . Fixed in 450.1",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Recommended next steps",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                const Text("1. Update to 450.1 or later from the app's official source.\n2. Until patched, avoid sensitive actions inside this app.\n3. Review permissions (e.g., SMS, Contacts) and revoke anything unnecessary.\n4. Turn on auto-updates and re-scan after updating."),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Notifications",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search functionality
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilterChip(
                    label: const Text("All"),
                    onSelected: (_) {},
                    selected: true,
                    showCheckmark: false,
                    shape: const StadiumBorder(
                      side: BorderSide.none,
                    ),
                    selectedColor: Colors.blue,
                    labelStyle: const TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilterChip(
                    label: const Text("Read only"),
                    onSelected: (_) {},
                    selected: false,
                    showCheckmark: false,
                    shape: const StadiumBorder(
                      side: BorderSide(color: Colors.blue),
                    ),
                    backgroundColor: Colors.blue.withOpacity(0.1),
                    labelStyle: const TextStyle(
                      color: Colors.blue,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilterChip(
                    label: const Text("Unread only"),
                    onSelected: (_) {},
                    selected: false,
                    showCheckmark: false,
                    shape: const StadiumBorder(
                      side: BorderSide(color: Colors.blue),
                    ),
                    backgroundColor: Colors.blue.withOpacity(0.1),
                    labelStyle: const TextStyle(
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView(
                children: [
                  const Text("Today", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  NotificationCard(
                    appName: "Facebook",
                    icon: Icons.facebook,
                    vulnerability: "CVE-XXXX-XXXX",
                    risk: "High",
                    riskColor: Colors.red,
                    time: "2 h",
                    onDetailsPressed: () => _showDetailsPopup(context, "Facebook", "High", Colors.red),
                  ),
                  const SizedBox(height: 8),
                  NotificationCard(
                    appName: "Line",
                    icon: Icons.chat_bubble_outline,
                    vulnerability: "CVE-XXXX-XXXX",
                    risk: "Medium",
                    riskColor: Colors.orange,
                    time: "2 h",
                    onDetailsPressed: () => _showDetailsPopup(context, "Line", "Medium", Colors.orange),
                  ),
                  const SizedBox(height: 24),
                  const Text("Earlier", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  NotificationCard(
                    appName: "Capcut",
                    icon: Icons.cut,
                    vulnerability: "CVE-XXXX-XXXX",
                    risk: "Low",
                    riskColor: Colors.green,
                    time: "10 d",
                    onDetailsPressed: () => _showDetailsPopup(context, "Capcut", "Low", Colors.green),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NotificationCard extends StatelessWidget {
  final String appName;
  final IconData icon;
  final String vulnerability;
  final String risk;
  final Color riskColor;
  final String time;
  final VoidCallback onDetailsPressed;

  const NotificationCard({
    required this.appName,
    required this.icon,
    required this.vulnerability,
    required this.risk,
    required this.riskColor,
    required this.time,
    required this.onDetailsPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: Colors.blue[50],
            child: Icon(icon, color: Colors.blue),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Found a vulnerability $vulnerability",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text("in $appName"),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: riskColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "Risk : $risk",
                  style: TextStyle(
                    color: riskColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(time, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: onDetailsPressed,
                child: const Text(
                  "Details",
                  style: TextStyle(
                      color: Colors.blue
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
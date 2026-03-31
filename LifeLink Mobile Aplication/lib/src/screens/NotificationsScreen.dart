import 'package:flutter/material.dart';
import 'HospitalDashboardScreen.dart';
import 'PatientRequestsScreen.dart';
import 'AvailableDonorsScreen.dart';
import 'NotificationsScreen.dart';
import 'HospitalProfileScreen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedBottomTab = 3; // Notifications selected

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Today notifications
  final List<_Notification> _todayNotifs = [
    const _Notification(
      iconBg: Color(0xFFFFEBEE),
      icon: Icons.add,
      iconColor: Color(0xFFE53935),
      title: 'Emergency Request Received',
      subtitle: 'High Priority Alert',
      subtitleColor: Color(0xFFE53935),
      body: '3 units of O- needed immediately.',
      bodyItalic: true,
      timeAgo: '2M\nAGO',
      isUnread: true,
      isHighlighted: true,
    ),
    const _Notification(
      iconBg: Color(0xFFDDE8FA),
      icon: Icons.location_on_outlined,
      iconColor: Color(0xFF2979FF),
      title: 'Donor Accepted Request',
      subtitle: 'Status: En route',
      subtitleColor: Color(0xFF2979FF),
      body: 'David Smith is on his way for Request #492.',
      bodyItalic: false,
      timeAgo: '15M AGO',
      isUnread: true,
      isHighlighted: true,
    ),
    const _Notification(
      iconBg: Color(0xFFEEF2F7),
      icon: Icons.inventory_2_outlined,
      iconColor: Color(0xFF6B7280),
      title: 'Low Stock Warning',
      subtitle: 'Inventory Alert',
      subtitleColor: Color(0xFF9E9E9E),
      body: 'A+ inventory is below 10 units.',
      bodyItalic: false,
      timeAgo: '1H AGO',
      isUnread: false,
      isHighlighted: false,
    ),
  ];

  // Yesterday notifications
  final List<_Notification> _yesterdayNotifs = [
    const _Notification(
      iconBg: Color(0xFFEEF2F7),
      icon: Icons.check_circle_outline_rounded,
      iconColor: Color(0xFF6B7280),
      title: 'Monthly Report Ready',
      subtitle: '',
      subtitleColor: Colors.transparent,
      body: 'September statistics have been generated.',
      bodyItalic: false,
      timeAgo: '1D AGO',
      isUnread: false,
      isHighlighted: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            _buildTabBar(),
            Expanded(
              child: ListView(
                children: [
                  ..._todayNotifs.map((n) => _NotifTile(notif: n)),
                  const _SectionHeader(label: 'YESTERDAY'),
                  ..._yesterdayNotifs.map((n) => _NotifTile(notif: n)),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ── Top Bar ──────────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Notifications',
            style: TextStyle(
              color: Color(0xFF1A2340),
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          GestureDetector(
            onTap: () {},
            child: const Text(
              'Mark all as read',
              style: TextStyle(
                color: Color(0xFF2979FF),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab Bar ──────────────────────────────────────────────────────────────

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      labelColor: const Color(0xFF2979FF),
      unselectedLabelColor: const Color(0xFF9E9E9E),
      labelStyle: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
      unselectedLabelStyle: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      indicatorColor: const Color(0xFF2979FF),
      indicatorWeight: 2.5,
      indicatorSize: TabBarIndicatorSize.label,
      dividerColor: const Color(0xFFEEF2F7),
      tabs: const [
        Tab(text: 'All'),
        Tab(text: 'Unread'),
        Tab(text: 'Important'),
      ],
    );
  }

  // ── Bottom Nav ───────────────────────────────────────────────────────────

  Widget _buildBottomNav() {
    final tabs = [
      const _NavItem(Icons.dashboard_rounded, 'Dashboard'),
      const _NavItem(Icons.water_drop_outlined, 'Requests'),
      const _NavItem(Icons.people_alt_outlined, 'Donors'),
      const _NavItem(Icons.notifications_rounded, 'Notifications'),
      const _NavItem(Icons.person_outline_rounded, 'Profile'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: tabs.asMap().entries.map((entry) {
              final i = entry.key;
              final tab = entry.value;
              final selected = i == _selectedBottomTab;
              return GestureDetector(
               onTap: () {
  setState(() => _selectedBottomTab = i);

  if (i == 0) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const HospitalDashboardScreen(),
      ),
    );
  } 
  else if (i == 1) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const PatientRequestsScreen(),
      ),
    );
  } 
  else if (i == 2) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const AvailableDonorsScreen(),
      ),
    );
  } 
  else if (i == 3) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const NotificationsScreen(),
      ),
    );
  } 
  else if (i == 4) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const HospitalProfileScreen(),
      ),
    );
  }
},
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      tab.icon,
                      color: selected
                          ? const Color(0xFF2979FF)
                          : const Color(0xFFB0BEC5),
                      size: 22,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tab.label,
                      style: TextStyle(
                        color: selected
                            ? const Color(0xFF2979FF)
                            : const Color(0xFFB0BEC5),
                        fontSize: 10,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// ── Data model ────────────────────────────────────────────────────────────────

class _Notification {
  final Color iconBg;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Color subtitleColor;
  final String body;
  final bool bodyItalic;
  final String timeAgo;
  final bool isUnread;
  final bool isHighlighted;

  const _Notification({
    required this.iconBg,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.subtitleColor,
    required this.body,
    required this.bodyItalic,
    required this.timeAgo,
    required this.isUnread,
    required this.isHighlighted,
  });
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFF5F7FA),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF9E9E9E),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  final _Notification notif;
  const _NotifTile({required this.notif});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: notif.isHighlighted
          ? const Color(0xFFF0F5FF)
          : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Icon badge ────────────────────────────────────────────
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: notif.iconBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(notif.icon, color: notif.iconColor, size: 24),
          ),

          const SizedBox(width: 14),

          // ── Content ───────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notif.title,
                  style: const TextStyle(
                    color: Color(0xFF1A2340),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
                if (notif.subtitle.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    notif.subtitle,
                    style: TextStyle(
                      color: notif.subtitleColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  notif.body,
                  style: TextStyle(
                    color: const Color(0xFF6B7280),
                    fontSize: 13,
                    fontStyle: notif.bodyItalic
                        ? FontStyle.italic
                        : FontStyle.normal,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // ── Time + unread dot ─────────────────────────────────────
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                notif.timeAgo,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: Color(0xFF9E9E9E),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
              ),
              if (notif.isUnread) ...[
                const SizedBox(height: 6),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2979FF),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
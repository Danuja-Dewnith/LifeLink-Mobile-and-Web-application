import 'package:flutter/material.dart';
import 'HospitalDashboardScreen.dart';
import 'PatientRequestsScreen.dart';
import 'AvailableDonorsScreen.dart';
import 'NotificationsScreen.dart';
import 'HospitalProfileScreen.dart';

class PatientRequestsScreen extends StatefulWidget {
  const PatientRequestsScreen({super.key});

  @override
  State<PatientRequestsScreen> createState() => _PatientRequestsScreenState();
}

class _PatientRequestsScreenState extends State<PatientRequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTab = 1; // bottom nav: Requests selected

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  final List<_Request> _requests = [
    const _Request(
      name: 'Sarah Johnson',
      avatarUrl:
          'https://randomuser.me/api/portraits/women/44.jpg',
      hospital: 'City Central Hospital',
      required: 'O+ Blood',
      units: 3,
      status: 'Searching for Donors',
      statusColor: Color(0xFF2979FF),
      priority: 'CRITICAL',
      priorityColor: Color(0xFFE53935),
    ),
    const _Request(
      name: 'Michael Chen',
      avatarUrl:
          'https://randomuser.me/api/portraits/men/32.jpg',
      hospital: "St. Mary's Trauma Center",
      required: 'A- Blood',
      units: 5,
      status: '2 Donors Found',
      statusColor: Color(0xFF2979FF),
      priority: 'CRITICAL',
      priorityColor: Color(0xFFE53935),
    ),
    const _Request(
      name: 'Elena Rodriguez',
      avatarUrl:
          'https://randomuser.me/api/portraits/women/68.jpg',
      hospital: 'Westside General',
      required: 'B+ Plasma',
      units: 2,
      status: 'Pending Approval',
      statusColor: Color(0xFFFB8C00),
      priority: 'NORMAL',
      priorityColor: Color(0xFF6B7280),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECEFF4),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            _buildTabBar(),
            _buildFilterChips(),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                itemCount: _requests.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, i) =>
                    _RequestCard(request: _requests[i]),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xFF2979FF),
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ── Top Bar ──────────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: const Icon(Icons.arrow_back,
                color: Color(0xFF1A2340), size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Patient Requests',
              style: TextStyle(
                color: Color(0xFF1A2340),
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.search,
                color: Color(0xFF1A2340), size: 22),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.filter_list_rounded,
                color: Color(0xFF1A2340), size: 22),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  // ── Tab Bar ──────────────────────────────────────────────────────────────

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: const Color(0xFF2979FF),
        unselectedLabelColor: const Color(0xFF9E9E9E),
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        indicatorColor: const Color(0xFF2979FF),
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.label,
        tabs: const [
          Tab(text: 'All Requests'),
          Tab(text: 'Active'),
          Tab(text: 'Emergency'),
          Tab(text: 'Completed'),
        ],
      ),
    );
  }

  // ── Filter Chips ─────────────────────────────────────────────────────────

  Widget _buildFilterChips() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: const Row(
        children: [
          _FilterChip(
            label: 'BLOOD TYPE: O+',
            active: true,
            trailing: Icons.close,
          ),
          SizedBox(width: 10),
          _FilterChip(
            label: 'DISTANCE: < 5KM',
            active: false,
            trailing: Icons.keyboard_arrow_down_rounded,
          ),
        ],
      ),
    );
  }

  // ── Bottom Nav ───────────────────────────────────────────────────────────

  Widget _buildBottomNav() {
    final tabs = [
      const _NavTab(Icons.dashboard_rounded, 'Dashboard'),
      const _NavTab(Icons.description_rounded, 'Requests'),
      const _NavTab(Icons.people_alt_outlined, 'Donors'),
      const _NavTab(Icons.notifications_outlined, 'Alerts'),
      const _NavTab(Icons.person_outline_rounded, 'Profile'),
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
              final selected = i == _selectedTab;
              return GestureDetector(
                onTap: () {
  setState(() => _selectedTab = i);

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
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          tab.icon,
                          color: selected
                              ? const Color(0xFF2979FF)
                              : const Color(0xFFB0BEC5),
                          size: 22,
                        ),
                        // notification dot on Alerts
                        if (i == 3)
                          Positioned(
                            right: -2,
                            top: -2,
                            child: Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: Color(0xFFE53935),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
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

// ── Data model ───────────────────────────────────────────────────────────────

class _Request {
  final String name;
  final String avatarUrl;
  final String hospital;
  final String required;
  final int units;
  final String status;
  final Color statusColor;
  final String priority;
  final Color priorityColor;

  const _Request({
    required this.name,
    required this.avatarUrl,
    required this.hospital,
    required this.required,
    required this.units,
    required this.status,
    required this.statusColor,
    required this.priority,
    required this.priorityColor,
  });
}

class _NavTab {
  final IconData icon;
  final String label;
  const _NavTab(this.icon, this.label);
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final IconData trailing;

  const _FilterChip({
    required this.label,
    required this.active,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: active
            ? const Color(0xFFE8F0FE)
            : const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: active
              ? const Color(0xFF2979FF).withOpacity(0.4)
              : const Color(0xFFDDE3ED),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: active
                  ? const Color(0xFF2979FF)
                  : const Color(0xFF6B7280),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(width: 6),
          Icon(
            trailing,
            size: 14,
            color: active
                ? const Color(0xFF2979FF)
                : const Color(0xFF6B7280),
          ),
        ],
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final _Request request;
  const _RequestCard({required this.request});

  @override
  Widget build(BuildContext context) {
    final isPriorityColored =
        request.priority == 'CRITICAL';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ─────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Image.network(
                  request.avatarUrl,
                  width: 52,
                  height: 52,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 52,
                    height: 52,
                    color: const Color(0xFFDDE8FA),
                    child: const Icon(Icons.person,
                        color: Color(0xFF2979FF), size: 28),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Name & hospital
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.name,
                      style: const TextStyle(
                        color: Color(0xFF1A2340),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 12,
                            color: Color(0xFF9E9E9E)),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            request.hospital,
                            style: const TextStyle(
                              color: Color(0xFF9E9E9E),
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Priority badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isPriorityColored
                      ? request.priorityColor
                      : const Color(0xFFEEF2F7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  request.priority,
                  style: TextStyle(
                    color: isPriorityColored
                        ? Colors.white
                        : const Color(0xFF6B7280),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(color: Color(0xFFEEF2F7), height: 1),
          const SizedBox(height: 14),

          // ── Info row ────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'REQUIRED',
                      style: TextStyle(
                        color: Color(0xFF9E9E9E),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      request.required,
                      style: const TextStyle(
                        color: Color(0xFF2979FF),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'UNITS NEEDED',
                      style: TextStyle(
                        color: Color(0xFF9E9E9E),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${request.units} Units',
                      style: const TextStyle(
                        color: Color(0xFF1A2340),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(color: Color(0xFFEEF2F7), height: 1),
          const SizedBox(height: 12),

          // ── Status row ──────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'STATUS',
                    style: TextStyle(
                      color: Color(0xFF9E9E9E),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: request.statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        request.status,
                        style: const TextStyle(
                          color: Color(0xFF1A2340),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(
                height: 38,
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF2979FF)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  child: const Text(
                    'View Details',
                    style: TextStyle(
                      color: Color(0xFF2979FF),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
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
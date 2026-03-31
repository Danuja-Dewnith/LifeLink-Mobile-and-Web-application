import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'PatientRequestsScreen.dart';
import 'AvailableDonorsScreen.dart';
import 'NotificationsScreen.dart';
import 'HospitalProfileScreen.dart';
import 'UpdateBloodStockScreen.dart';
import 'package:lifelink_app/src/models/blood_stock.dart';

class HospitalDashboardScreen extends StatefulWidget {
  const HospitalDashboardScreen({super.key});

  @override
  State<HospitalDashboardScreen> createState() =>
      _HospitalDashboardScreenState();
}

class _HospitalDashboardScreenState extends State<HospitalDashboardScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  int _selectedTab = 0;

  // ✅ FIX 1: Hospital name — initialized with empty string, set from API
  String _hospitalName = '';
  String? regNumber;

  List<BloodStock> _stocks = [];
  List<_PatientRequest> _patientRequests = [];
  List<_NearbyDonor> _donors = [];
  List<_Instruction> _instructions = [];
  List<_SystemAlert> _alerts = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null || token.isEmpty) {
        setState(() {
          _errorMessage = "Not logged in. Please login again.";
          _isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('http://10.168.30.196:3000/hospital/dashboard'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          // ✅ FIX 1: Read hospital name from API response
          _hospitalName = (data['hospitalName'] ?? '').toString();

          // ✅ FIX 2: Correctly map bloodStocks — server sends bloodType field
          _stocks = (data['bloodStocks'] as List? ?? []).map((s) {
            final bloodType =
                (s['bloodType'] ?? s['type'] ?? '').toString().trim();
            final units = (s['units'] ?? 0) as int;
            final statusStr =
                (s['status'] ?? s['label'] ?? 'NORMAL').toString();
            return BloodStock(
              bloodType,
              units,
              statusStr,
              _getStatusLevel(statusStr),
            );
          }).toList();

          // Patient Requests
          _patientRequests = (data['patientRequests'] as List? ?? [])
              .map((r) => _PatientRequest(
                    name: r['name'] ?? '',
                    timeAgo: r['timeAgo'] ?? '',
                    bloodType: r['bloodType'] ?? '',
                    units: r['units'] ?? 0,
                    status: r['status'] ?? '',
                    statusColor: Color(int.parse(
                        (r['statusColor'] ?? '0xFFE53935')
                            .replaceFirst('0x', '0x'))),
                    actionLabel: r['actionLabel'] ?? 'View Details',
                  ))
              .toList();

          // Nearby Donors
          _donors = (data['nearbyDonors'] as List? ?? [])
              .map((d) => _NearbyDonor(
                    d['name'] ?? '',
                    d['bloodType'] ?? '',
                    d['distance'] ?? '',
                  ))
              .toList();

          // Instructions
          _instructions = (data['instructions'] as List? ?? [])
              .map((i) => _Instruction(
                    i['title'] ?? '',
                    i['meta'] ?? '',
                  ))
              .toList();

          // System Alerts
          _alerts = (data['alerts'] as List? ?? [])
              .map((a) => _SystemAlert(
                    icon: _getIconData(a['icon'] ?? 'check_circle'),
                    iconColor: Color(int.parse((a['iconColor'] ?? '0xFF43A047')
                        .replaceFirst('0x', '0x'))),
                    message: a['message'] ?? '',
                    time: a['time'] ?? '',
                  ))
              .toList();

          _isLoading = false;
        });
      } else if (response.statusCode == 401) {
        setState(() {
          _errorMessage = "Session expired. Please login again.";
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = "Failed to load dashboard (${response.statusCode})";
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Connection error: $e";
          _isLoading = false;
        });
      }
    }
  }

  StatusLevel _getStatusLevel(String? status) {
    switch (status?.toUpperCase()) {
      case 'LOW':
        return StatusLevel.low;
      case 'CRITICAL':
        return StatusLevel.critical;
      default:
        return StatusLevel.normal;
    }
  }

  IconData _getIconData(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'sync':
        return Icons.sync_rounded;
      case 'warning':
        return Icons.warning_amber_rounded;
      default:
        return Icons.check_circle_rounded;
    }
  }

  Future<void> _refreshData() async => await _loadDashboardData();

  // ══════════════════════════════════════════════════════════════════════════
  // Build
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECEFF4),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? _buildErrorState()
                      : RefreshIndicator(
                          onRefresh: _refreshData,
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 16),
                                _buildBloodStorageOverview(),
                                const SizedBox(height: 14),
                                _buildCriticalShortageAlert(),
                                const SizedBox(height: 14),
                                _buildIncomingUrgentRequests(),
                                const SizedBox(height: 14),
                                _buildActivePatientRequests(),
                                const SizedBox(height: 14),
                                _buildNearbyDonors(),
                                const SizedBox(height: 14),
                                _buildDoctorInstructions(),
                                const SizedBox(height: 14),
                                _buildRecentSystemAlerts(),
                                const SizedBox(height: 40),
                              ],
                            ),
                          ),
                        ),
            ),
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  // ── Top Bar ──────────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    // ✅ FIX 1: Use _hospitalName from API; fallback only when truly empty
    final displayName = _hospitalName.isNotEmpty
        ? _hospitalName
        : (_isLoading ? 'Loading...' : 'LifeLink Partner');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF2979FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    color: Color(0xFF1A2340),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Text(
                  'LIFELINK PARTNER',
                  style: TextStyle(
                    color: Color(0xFF2979FF),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined,
                    color: Color(0xFF1A2340), size: 22),
                onPressed: () {},
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE53935),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFF2979FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  // ── Error state ───────────────────────────────────────────────────────────

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 64, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? "Something went wrong",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.redAccent),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _loadDashboardData,
              icon: const Icon(Icons.refresh),
              label: const Text("Try Again"),
            ),
          ],
        ),
      ),
    );
  }

  // ── Blood Storage Overview ────────────────────────────────────────────────

  Widget _buildBloodStorageOverview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Blood Storage Overview',
                style: TextStyle(
                    color: Color(0xFF1A2340),
                    fontSize: 15,
                    fontWeight: FontWeight.w700),
              ),
              GestureDetector(
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          UpdateBloodStockScreen(currentStocks: _stocks),
                    ),
                  );
                  if (result == true) _loadDashboardData();
                },
                child: const Row(
                  children: [
                    Icon(Icons.edit_outlined,
                        color: Color(0xFF2979FF), size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Update',
                      style: TextStyle(
                          color: Color(0xFF2979FF),
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _stocks.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'No blood stock data available.\nTap Update to add stock.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Color(0xFF9E9E9E), fontSize: 13, height: 1.5),
                  ),
                )
              : GridView.builder(
                  itemCount: _stocks.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4, // 4 per row — fits all 8 types neatly
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 0.85,
                  ),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) =>
                      _BloodStockCard(stock: _stocks[index]),
                ),
        ],
      ),
    );
  }

  // ── Critical Shortage Alert ───────────────────────────────────────────────

  Widget _buildCriticalShortageAlert() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFCDD2)),
      ),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
                color: Color(0xFFFFEBEE), shape: BoxShape.circle),
            child: const Icon(Icons.campaign_rounded,
                color: Color(0xFFE53935), size: 22),
          ),
          const SizedBox(height: 10),
          const Text(
            'Critical Shortage Alert',
            style: TextStyle(
                color: Color(0xFFE53935),
                fontSize: 16,
                fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          const Text(
            'Notify all eligible donors within 5km radius for urgent blood collection.',
            textAlign: TextAlign.center,
            style:
                TextStyle(color: Color(0xFF6B7280), fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon:
                  const Icon(Icons.bolt_rounded, color: Colors.white, size: 18),
              label: const Text(
                'Trigger Emergency Donor Alert',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Incoming Urgent Requests ──────────────────────────────────────────────

  Widget _buildIncomingUrgentRequests() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: Color(0xFFE53935), size: 20),
            SizedBox(width: 8),
            Text('Incoming Urgent Requests',
                style: TextStyle(
                    color: Color(0xFF1A2340),
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 2,
            itemBuilder: (context, index) => const _UrgentRequestCard(
              badge: 'IMMEDIATE (15M)',
              badgeColor: Color(0xFFE53935),
              reqNumber: '#REQ-492',
              title: 'O- Negative Blood',
              subtitle: "St. Mary's ER • 3 Units Needed",
              dark: true,
            ),
          ),
        ),
      ],
    );
  }

  // ── Active Patient Requests ───────────────────────────────────────────────

  Widget _buildActivePatientRequests() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Active Patient Requests',
            style: TextStyle(
                color: Color(0xFF1A2340),
                fontSize: 15,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        ..._patientRequests.map((r) => _PatientRequestCard(request: r)),
      ],
    );
  }

  // ── Nearby Available Donors ───────────────────────────────────────────────

  Widget _buildNearbyDonors() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Nearby Available Donors',
                style: TextStyle(
                    color: Color(0xFF1A2340),
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F0FE),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('24 Active',
                  style: TextStyle(
                      color: Color(0xFF2979FF),
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            children: _donors
                .map((d) => Column(
                      children: [
                        _DonorRow(donor: d),
                        if (d != _donors.last)
                          const Divider(
                              color: Color(0xFFEEF2F7), height: 1, indent: 16),
                      ],
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

  // ── Doctor Instructions ───────────────────────────────────────────────────

  Widget _buildDoctorInstructions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Doctor Instructions',
                style: TextStyle(
                    color: Color(0xFF1A2340),
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
            GestureDetector(
              onTap: () {},
              child: const Row(
                children: [
                  Icon(Icons.add_circle_outline,
                      color: Color(0xFF2979FF), size: 16),
                  SizedBox(width: 4),
                  Text('Add',
                      style: TextStyle(
                          color: Color(0xFF2979FF),
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            children: _instructions
                .map((i) => Column(
                      children: [
                        _InstructionRow(instruction: i),
                        if (i != _instructions.last)
                          const Divider(
                              color: Color(0xFFEEF2F7), height: 1, indent: 16),
                      ],
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

  // ── Recent System Alerts ──────────────────────────────────────────────────

  Widget _buildRecentSystemAlerts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Recent System Alerts',
            style: TextStyle(
                color: Color(0xFF1A2340),
                fontSize: 15,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            children: _alerts
                .map((a) => Column(
                      children: [
                        _SystemAlertRow(alert: a),
                        if (a != _alerts.last)
                          const Divider(
                              color: Color(0xFFEEF2F7), height: 1, indent: 16),
                      ],
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

  // ── Bottom Nav ────────────────────────────────────────────────────────────

  Widget _buildBottomNav() {
    final tabs = [
      const _NavTab(Icons.dashboard_rounded, 'Dashboard'),
      const _NavTab(Icons.swap_horiz_rounded, 'Requests'),
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
              offset: const Offset(0, -2)),
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
                            builder: (_) => const HospitalDashboardScreen()));
                  } else if (i == 1) {
                    Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const PatientRequestsScreen()));
                  } else if (i == 2) {
                    Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AvailableDonorsScreen()));
                  } else if (i == 3) {
                    Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const NotificationsScreen()));
                  } else if (i == 4) {
                    Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const HospitalProfileScreen()));
                  }
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(tab.icon,
                        color: selected
                            ? const Color(0xFF2979FF)
                            : const Color(0xFFB0BEC5),
                        size: 22),
                    const SizedBox(height: 4),
                    Text(
                      tab.label,
                      style: TextStyle(
                        color: selected
                            ? const Color(0xFF2979FF)
                            : const Color(0xFFB0BEC5),
                        fontSize: 10,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w400,
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

// ══════════════════════════════════════════════════════════════════════════════
// ✅ FIX 2: _BloodStockCard — always shows blood type label + units
// ══════════════════════════════════════════════════════════════════════════════

class _BloodStockCard extends StatelessWidget {
  final BloodStock stock;
  const _BloodStockCard({required this.stock});

  Color get _statusColor {
    if (stock.units <= 5) return const Color(0xFFE53935);
    if (stock.units <= 10) return const Color(0xFFFB8C00);
    return const Color(0xFF43A047);
  }

  Color get _bgColor {
    if (stock.units <= 5) return const Color(0xFFFFF5F5);
    if (stock.units <= 10) return const Color(0xFFFFF8F0);
    return const Color(0xFFF1F8F1);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _statusColor.withOpacity(0.35)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Blood type badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: _statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              stock.type.isNotEmpty ? stock.type : '—',
              style: TextStyle(
                color: _statusColor,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${stock.units}',
            style: TextStyle(
              color: _statusColor,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            'units',
            style: TextStyle(
              color: _statusColor.withOpacity(0.7),
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Data models
// ══════════════════════════════════════════════════════════════════════════════

class _PatientRequest {
  final String name, timeAgo, bloodType, status, actionLabel;
  final int units;
  final Color statusColor;
  const _PatientRequest({
    required this.name,
    required this.timeAgo,
    required this.bloodType,
    required this.units,
    required this.status,
    required this.statusColor,
    required this.actionLabel,
  });
}

class _NearbyDonor {
  final String name, bloodType, distance;
  const _NearbyDonor(this.name, this.bloodType, this.distance);
}

class _Instruction {
  final String title, meta;
  const _Instruction(this.title, this.meta);
}

class _SystemAlert {
  final IconData icon;
  final Color iconColor;
  final String message, time;
  const _SystemAlert(
      {required this.icon,
      required this.iconColor,
      required this.message,
      required this.time});
}

class _NavTab {
  final IconData icon;
  final String label;
  const _NavTab(this.icon, this.label);
}

// ══════════════════════════════════════════════════════════════════════════════
// Sub-widgets (unchanged from original)
// ══════════════════════════════════════════════════════════════════════════════

class _UrgentRequestCard extends StatelessWidget {
  final String badge, reqNumber, title, subtitle;
  final Color badgeColor;
  final bool dark;
  const _UrgentRequestCard({
    required this.badge,
    required this.badgeColor,
    required this.reqNumber,
    required this.title,
    required this.subtitle,
    required this.dark,
  });

  @override
  Widget build(BuildContext context) {
    final bg = dark ? const Color(0xFF1A2340) : Colors.white;
    final titleColor = dark ? Colors.white : const Color(0xFF1A2340);
    final subColor = dark ? Colors.white60 : const Color(0xFF6B7280);
    return Container(
      width: 230,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: badgeColor, borderRadius: BorderRadius.circular(4)),
                child: Text(badge,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4)),
              ),
              Text(reqNumber,
                  style: TextStyle(
                      color: dark ? Colors.white54 : const Color(0xFF6B7280),
                      fontSize: 11)),
            ],
          ),
          const Spacer(),
          Text(title,
              style: TextStyle(
                  color: titleColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  height: 1.2)),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(color: subColor, fontSize: 11)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                  child: SizedBox(
                      height: 32,
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                              color: dark
                                  ? Colors.white38
                                  : const Color(0xFFDDE3ED)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          padding: EdgeInsets.zero,
                        ),
                        child: Text('Accept',
                            style: TextStyle(
                                color: dark
                                    ? Colors.white
                                    : const Color(0xFF1A2340),
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ))),
              const SizedBox(width: 8),
              Expanded(
                  child: SizedBox(
                      height: 32,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              dark ? Colors.white24 : const Color(0xFF2979FF),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          padding: EdgeInsets.zero,
                        ),
                        child: const Text('View',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ))),
            ],
          ),
        ],
      ),
    );
  }
}

class _PatientRequestCard extends StatelessWidget {
  final _PatientRequest request;
  const _PatientRequestCard({required this.request});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(request.name,
                  style: const TextStyle(
                      color: Color(0xFF1A2340),
                      fontSize: 14,
                      fontWeight: FontWeight.w700)),
              Text(request.timeAgo,
                  style:
                      const TextStyle(color: Color(0xFF9E9E9E), fontSize: 11)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _Tag(
                  icon: Icons.water_drop_outlined,
                  iconColor: const Color(0xFF2979FF),
                  label: request.bloodType),
              const SizedBox(width: 8),
              _Tag(
                  icon: Icons.bloodtype_outlined,
                  iconColor: const Color(0xFF1A2340),
                  label: '${request.units} Units'),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: request.statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20)),
                child: Row(
                  children: [
                    Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                            color: request.statusColor,
                            shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    Text(request.status,
                        style: TextStyle(
                            color: request.statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 36,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF2979FF)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(request.actionLabel,
                  style: const TextStyle(
                      color: Color(0xFF2979FF),
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  const _Tag(
      {required this.icon, required this.iconColor, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 13),
        const SizedBox(width: 3),
        Text(label,
            style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 12,
                fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _DonorRow extends StatelessWidget {
  final _NearbyDonor donor;
  const _DonorRow({required this.donor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: const Color(0xFFEEF2F7),
                borderRadius: BorderRadius.circular(10)),
            child: Center(
                child: Text(donor.bloodType,
                    style: const TextStyle(
                        color: Color(0xFF1A2340),
                        fontSize: 13,
                        fontWeight: FontWeight.w700))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(donor.name,
                    style: const TextStyle(
                        color: Color(0xFF1A2340),
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        color: Color(0xFF9E9E9E), size: 12),
                    const SizedBox(width: 2),
                    Text(donor.distance,
                        style: const TextStyle(
                            color: Color(0xFF9E9E9E), fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(
            height: 32,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2979FF),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: const Text('Request',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

class _InstructionRow extends StatelessWidget {
  final _Instruction instruction;
  const _InstructionRow({required this.instruction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: const Color(0xFFEEF2F7),
                borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.description_outlined,
                color: Color(0xFF6B7280), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(instruction.title,
                    style: const TextStyle(
                        color: Color(0xFF1A2340),
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(instruction.meta,
                    style: const TextStyle(
                        color: Color(0xFF9E9E9E), fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SystemAlertRow extends StatelessWidget {
  final _SystemAlert alert;
  const _SystemAlertRow({required this.alert});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: alert.iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(alert.icon, color: alert.iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(alert.message,
                    style: const TextStyle(
                        color: Color(0xFF1A2340),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        height: 1.4)),
                const SizedBox(height: 3),
                Text(alert.time,
                    style: const TextStyle(
                        color: Color(0xFF9E9E9E), fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

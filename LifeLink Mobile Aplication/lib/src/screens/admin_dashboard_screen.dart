import 'package:flutter/material.dart';
import 'dart:convert';

import '../services/auth_service.dart';
import '../services/api_service.dart';

import 'admin_users_screen.dart';
import 'admin_requests_screen.dart';
import 'admin_reports_screen.dart';
import 'admin_profile_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const DashboardContent(),
    const AdminUsersScreenContent(),
    const AdminRequestsScreenContent(),
    const AdminReportsScreenContent(),
    const AdminProfileScreenContent(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF1E88E5),
        unselectedItemColor: const Color(0xFF94A3B8),
        backgroundColor: Colors.white,
        elevation: 8,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard), label: "Dashboard"),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: "Users"),
          BottomNavigationBarItem(
              icon: Icon(Icons.compare_arrows), label: "Requests"),
          BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart), label: "Reports"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}

class DashboardContent extends StatefulWidget {
  const DashboardContent({super.key});

  @override
  State<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
  bool _isLoading = true;
  String totalDonors = "0";
  String totalPatients = "0";
  String totalHospitals = "0";
  String activeRequests = "0";
  String errorMessage = "";

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    setState(() {
      _isLoading = true;
      errorMessage = "";
    });

    try {
      final api = ApiService();
      final data = await api.get('/api/admin/stats');

      if (data['success'] == true && data['stats'] != null) {
        final stats = data['stats'];
        setState(() {
          totalDonors = stats['totalDonors']?.toString() ?? "0";
          totalPatients = stats['totalPatients']?.toString() ?? "0";
          totalHospitals = stats['totalHospitals']?.toString() ?? "0";
          activeRequests = stats['activeRequests']?.toString() ?? "0";
          _isLoading = false;
        });
        print("✅ Real stats loaded from database");
      } else {
        setState(() {
          errorMessage = "Failed to load statistics";
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Dashboard error: $e");
      setState(() {
        errorMessage =
            "Could not connect to server.\nPlease check your internet.";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _fetchStats,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            _buildTopBar(),
            const SizedBox(height: 8),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(),
                  const SizedBox(height: 16),
                  _isLoading
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(80),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : errorMessage.isNotEmpty
                          ? Center(
                              child: Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(30),
                                    child: Text(
                                      errorMessage,
                                      style: const TextStyle(
                                          color: Colors.red, fontSize: 16),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: _fetchStats,
                                    child: const Text("Retry"),
                                  ),
                                ],
                              ),
                            )
                          : _buildOverviewGrid(),
                  const SizedBox(height: 16),
                  _buildCriticalAlertCard(),
                  const SizedBox(height: 28),
                  _buildPendingApprovalsHeader(),
                  const SizedBox(height: 14),
                  _buildPendingApprovalCard(
                    icon: Icons.person_add_alt_1,
                    title: "New Donor: John Doe",
                    subtitle: "O+ Blood Group • 2 mins ago",
                  ),
                  const SizedBox(height: 12),
                  _buildPendingApprovalCard(
                    icon: Icons.description_outlined,
                    title: "Organ Request: Heart",
                    subtitle: "St. Mary's Hospital • 15 mins ago",
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    "Recent Emergency Alerts",
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827)),
                  ),
                  const SizedBox(height: 16),
                  _buildEmergencyAlertsCard(),
                  const SizedBox(height: 30),
                  const Text(
                    "System Activity Feed",
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827)),
                  ),
                  const SizedBox(height: 16),
                  _buildActivityFeedItem(
                    icon: Icons.verified_outlined,
                    title:
                        "Admin Sarah verified 12 new blood donors from the Mumbai regional camp.",
                    time: "30 mins ago",
                  ),
                  const SizedBox(height: 16),
                  _buildActivityFeedItem(
                    icon: Icons.local_shipping_outlined,
                    title:
                        "Shipment #502 (Plasma) has reached destination: Apex Clinic.",
                    time: "2 hours ago",
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== UI Methods (All your original design) ====================

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
                color: const Color(0xFFE8F1FB),
                borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.monitor_heart,
                color: Color(0xFF1E88E5), size: 28),
          ),
          const SizedBox(width: 12),
          const Expanded(
              child: Text("LifeLink Admin",
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827)))),
          Stack(
            children: [
              const Icon(Icons.notifications,
                  color: Color(0xFF374151), size: 26),
              Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                          color: Colors.red, shape: BoxShape.circle))),
            ],
          ),
          const SizedBox(width: 16),
          const CircleAvatar(
              radius: 20,
              backgroundColor: Color(0xFFE5E7EB),
              child: Icon(Icons.person, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text("System Overview",
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
              color: const Color(0xFFEAF3FF),
              borderRadius: BorderRadius.circular(10)),
          child: const Text("Live Data",
              style: TextStyle(
                  color: Color(0xFF1E88E5),
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _buildOverviewGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: 1.15,
      children: [
        _buildOverviewCard(
            icon: Icons.people_alt_outlined,
            iconColor: const Color(0xFF1E88E5),
            value: totalDonors,
            label: "Total Donors"),
        _buildOverviewCard(
            icon: Icons.escalator_warning_outlined,
            iconColor: const Color(0xFFFF4D4F),
            value: totalPatients,
            label: "Total Patients"),
        _buildOverviewCard(
            icon: Icons.apartment_outlined,
            iconColor: const Color(0xFF2563EB),
            value: totalHospitals,
            label: "Hospitals"),
        _buildOverviewCard(
            icon: Icons.medical_services_outlined,
            iconColor: const Color(0xFFFF7A00),
            value: activeRequests,
            label: "Active Requests"),
      ],
    );
  }

  Widget _buildOverviewCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 28),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827))),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(fontSize: 16, color: Color(0xFF6B7280))),
        ],
      ),
    );
  }

  Widget _buildCriticalAlertCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFC9C9)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
                color: const Color(0xFFFF4D4F),
                borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.notifications_active, color: Colors.white),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("3 Critical Alerts Today",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827))),
                SizedBox(height: 4),
                Text("Immediate dispatch required",
                    style: TextStyle(color: Color(0xFF6B7280), fontSize: 14)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF4D4F),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("REVIEW",
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingApprovalsHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: const [
        Text("Pending Approvals",
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827))),
        Text("View All",
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E88E5))),
      ],
    );
  }

  Widget _buildPendingApprovalCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
                color: const Color(0xFFF3F6FB),
                borderRadius: BorderRadius.circular(23)),
            child: Icon(icon, color: const Color(0xFF1E88E5)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827))),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 14, color: Color(0xFF6B7280))),
              ],
            ),
          ),
          IconButton(
              onPressed: () {},
              icon: const Icon(Icons.close, color: Color(0xFFFF4D4F))),
          IconButton(
              onPressed: () {},
              icon: const Icon(Icons.check, color: Color(0xFF22C55E))),
        ],
      ),
    );
  }

  Widget _buildEmergencyAlertsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          _buildEmergencyAlertItem(
            dotColor: const Color(0xFFFF4D4F),
            title: "Emergency Blood Required (AB-)",
            subtitle: "City General Hospital, Trauma Wing",
            tagText: "URGENT",
            tagColor: const Color(0xFFFF4D4F),
            time: "5 mins ago",
            showBottomBorder: true,
          ),
          _buildEmergencyAlertItem(
            dotColor: const Color(0xFFFF7A00),
            title: "Kidney Match Found",
            subtitle: "LifeCare Center to Central Hospital",
            tagText: "PENDING",
            tagColor: const Color(0xFFF59E0B),
            time: "1 hour ago",
            showBottomBorder: false,
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyAlertItem({
    required Color dotColor,
    required String title,
    required String subtitle,
    required String tagText,
    required Color tagColor,
    required String time,
    required bool showBottomBorder,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: showBottomBorder
            ? const Border(bottom: BorderSide(color: Color(0xFFE5E7EB)))
            : null,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                  width: 10,
                  height: 10,
                  decoration:
                      BoxDecoration(color: dotColor, shape: BoxShape.circle)),
              const SizedBox(width: 14),
              Expanded(
                  child: Text(title,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827)))),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                    color: tagColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8)),
                child: Text(tagText,
                    style: TextStyle(
                        color: tagColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: Align(
                alignment: Alignment.centerLeft,
                child: Text(subtitle,
                    style: const TextStyle(
                        fontSize: 15, color: Color(0xFF6B7280)))),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: Align(
                alignment: Alignment.centerLeft,
                child: Text(time,
                    style: const TextStyle(
                        fontSize: 14, color: Color(0xFF94A3B8)))),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityFeedItem({
    required IconData icon,
    required String title,
    required String time,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(width: 2, height: 22, color: const Color(0xFFBFDBFE)),
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                  color: Color(0xFF1E88E5), shape: BoxShape.circle),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827))),
                const SizedBox(height: 10),
                Text(time,
                    style: const TextStyle(
                        fontSize: 14, color: Color(0xFF94A3B8))),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

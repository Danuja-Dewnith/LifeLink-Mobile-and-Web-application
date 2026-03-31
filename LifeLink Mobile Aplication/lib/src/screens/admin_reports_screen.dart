import 'package:flutter/material.dart';

class AdminReportsScreenContent extends StatelessWidget {
  const AdminReportsScreenContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 80), // Add padding for bottom nav
          child: Column(
            children: [
              _buildTopBar(),
              const Divider(height: 1, color: Color(0xFFE5E7EB)),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildFilterRow(context),
                    const SizedBox(height: 18),
                    _buildTopStats(),
                    const SizedBox(height: 18),
                    _buildDonationVolumeCard(context),
                    const SizedBox(height: 18),
                    _buildDemandByBloodTypeCard(),
                    const SizedBox(height: 18),
                    _buildRequestStatusCard(),
                    const SizedBox(height: 18),
                    _buildTopHospitalsCard(context),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        children: [
          Icon(Icons.menu, size: 30, color: Color(0xFF111827)),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              "Reports & Analytics",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
          ),
          Icon(Icons.notifications, size: 28, color: Color(0xFF111827)),
        ],
      ),
    );
  }

  Widget _buildFilterRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              _showDateRangePicker(context);
            },
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFF1E88E5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Last 30 Days",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 18),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: () {
              _showTypeSelector(context);
            },
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "All Types",
                    style: TextStyle(
                      color: Color(0xFF334155),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(Icons.tune, color: Color(0xFF334155), size: 16),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: () {
              _exportReport(context);
            },
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Export",
                    style: TextStyle(
                      color: Color(0xFF334155),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(Icons.download, color: Color(0xFF334155), size: 16),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showDateRangePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Select Date Range",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildDateOption(context, "Last 7 Days"),
              _buildDateOption(context, "Last 30 Days"),
              _buildDateOption(context, "Last 90 Days"),
              _buildDateOption(context, "This Year"),
              _buildDateOption(context, "Custom Range"),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDateOption(BuildContext context, String label) {
    return ListTile(
      title: Text(label),
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Selected: $label')),
        );
      },
    );
  }

  void _showTypeSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Select Report Type",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildTypeOption(context, "All Types"),
              _buildTypeOption(context, "Blood Donations"),
              _buildTypeOption(context, "Organ Donations"),
              _buildTypeOption(context, "Hospital Requests"),
              _buildTypeOption(context, "Emergency Alerts"),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTypeOption(BuildContext context, String label) {
    return ListTile(
      title: Text(label),
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Selected: $label')),
        );
      },
    );
  }

  void _exportReport(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Export Report",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildExportOption(context, "PDF", Icons.picture_as_pdf),
              _buildExportOption(context, "Excel", Icons.table_chart),
              _buildExportOption(context, "CSV", Icons.grid_on),
              _buildExportOption(context, "Print", Icons.print),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExportOption(BuildContext context, String format, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF1E88E5)),
      title: Text(format),
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Exporting as $format...')),
        );
      },
    );
  }

  Widget _buildTopStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: "TOTAL DONATIONS",
            value: "4,821",
            change: "↗ +12.5%",
            changeColor: const Color(0xFF16A34A),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            title: "BLOOD UNITS USED",
            value: "3,140",
            change: "↗ +4.2%",
            changeColor: const Color(0xFFEF4444),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String change,
    required Color changeColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              letterSpacing: 1.2,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            change,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: changeColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDonationVolumeCard(BuildContext context) {
    return _buildWhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Donation Volume",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Monthly trend for 2024",
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('View Details - Coming Soon')),
                  );
                },
                child: const Text(
                  "View Details",
                  style: TextStyle(
                    color: Color(0xFF1E88E5),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildBar(60, const Color(0xFFC5D9F1), "Jan", 60),
                _buildBar(90, const Color(0xFFC5D9F1), "Feb", 90),
                _buildBar(110, const Color(0xFF1E88E5), "Mar", 110, selected: true),
                _buildBar(75, const Color(0xFFC5D9F1), "Apr", 75),
                _buildBar(40, const Color(0xFFC5D9F1), "May", 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBar(double height, Color color, String label, double value, {bool selected = false}) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: height,
            width: double.infinity,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: selected ? const Color(0xFF1E88E5) : const Color(0xFF64748B),
              fontWeight: selected ? FontWeight.bold : FontWeight.w500,
              fontSize: 11,
            ),
          ),
          if (value > 0)
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: 9,
                color: selected ? const Color(0xFF1E88E5) : const Color(0xFF94A3B8),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDemandByBloodTypeCard() {
    return _buildWhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Demand by Blood Type",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 18),
          _buildProgressRow("O Negative", "42%", 0.42),
          const SizedBox(height: 14),
          _buildProgressRow("A Positive", "28%", 0.28),
          const SizedBox(height: 14),
          _buildProgressRow("B Positive", "18%", 0.18),
          const SizedBox(height: 14),
          _buildProgressRow("AB Positive", "12%", 0.12),
        ],
      ),
    );
  }

  Widget _buildProgressRow(String label, String percent, double value) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF111827),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              percent,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF111827),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            minHeight: 8,
            value: value,
            backgroundColor: const Color(0xFFE5EAF1),
            valueColor: const AlwaysStoppedAnimation<Color>(
              Color(0xFF1E88E5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRequestStatusCard() {
    return _buildWhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Request Status",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: CircularProgressIndicator(
                        value: 0.86,
                        strokeWidth: 12,
                        backgroundColor: const Color(0xFFE5EAF1),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF1E88E5),
                        ),
                      ),
                    ),
                    const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "86%",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF111827),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          "SUCCESS",
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  children: [
                    _LegendItem(
                      color: Color(0xFF1E88E5),
                      text: "Completed: 1,240",
                    ),
                    SizedBox(height: 12),
                    _LegendItem(
                      color: Color(0xFFD1D5DB),
                      text: "Active: 198",
                    ),
                    SizedBox(height: 12),
                    _LegendItem(
                      color: Color(0xFFF97316),
                      text: "Pending: 45",
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopHospitalsCard(BuildContext context) {
    return _buildWhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Top Active Hospitals",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('View All Hospitals')),
                  );
                },
                child: const Text(
                  "View All",
                  style: TextStyle(
                    color: Color(0xFF1E88E5),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildHospitalRow(
            context,
            name: "Central Medical Center",
            subtitle: "412 Requests • High Load",
            badgeText: "CRITICAL",
            badgeBg: const Color(0xFFFFE4E6),
            badgeColor: const Color(0xFFE11D48),
          ),
          const SizedBox(height: 14),
          _buildHospitalRow(
            context,
            name: "St. Mary Children's",
            subtitle: "289 Requests • Normal",
            badgeText: "STABLE",
            badgeBg: const Color(0xFFDDF7E7),
            badgeColor: const Color(0xFF059669),
          ),
          const SizedBox(height: 14),
          _buildHospitalRow(
            context,
            name: "City General Hospital",
            subtitle: "156 Requests • Low Load",
            badgeText: "NORMAL",
            badgeBg: const Color(0xFFE5E7EB),
            badgeColor: const Color(0xFF6B7280),
          ),
        ],
      ),
    );
  }

  Widget _buildHospitalRow(
    BuildContext context, {
    required String name,
    required String subtitle,
    required String badgeText,
    required Color badgeBg,
    required Color badgeColor,
  }) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Viewing details for $name')),
        );
      },
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF3FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.local_hospital, color: Color(0xFF1E88E5), size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              badgeText,
              style: TextStyle(
                color: badgeColor,
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhiteCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String text;

  const _LegendItem({
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF334155),
            ),
          ),
        ),
      ],
    );
  }
}
import 'package:flutter/material.dart';

class AdminRequestsScreenContent extends StatefulWidget {
  const AdminRequestsScreenContent({super.key});

  @override
  State<AdminRequestsScreenContent> createState() => _AdminRequestsScreenContentState();
}

class _AdminRequestsScreenContentState extends State<AdminRequestsScreenContent> {
  String selectedTab = "All Requests";

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildTopBar(),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildTabs(),
                const SizedBox(height: 18),
                ..._buildRequestCards(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        children: [
          const Icon(Icons.menu, size: 30, color: Color(0xFF111827)),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              "All Requests",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
          ),
          Stack(
            children: [
              const Icon(Icons.notifications, size: 28, color: Color(0xFF111827)),
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    final tabs = ["All Requests", "Blood Requests", "Organ Requests"];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tabs.map((tab) {
          final isSelected = selectedTab == tab;
          return GestureDetector(
            onTap: () {
              setState(() {
                selectedTab = tab;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF1E88E5)
                    : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                tab,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : const Color(0xFF334155),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  List<Widget> _buildRequestCards() {
    List<Widget> cards = [];

    if (selectedTab == "All Requests" || selectedTab == "Blood Requests") {
      cards.add(
        _buildRequestCard(
          priority: "EMERGENCY • HIGH PRIORITY",
          name: "Johnathan Doe",
          badgeText: "PENDING",
          badgeBg: const Color(0xFFEF4444),
          badgeColor: Colors.white,
          needLabel: "Need",
          needValue: "Blood O+",
          unitsLabel: "Units",
          unitsValue: "3 Units",
          unitsColor: const Color(0xFFDC2626), // Fixed: Use Color directly
          hospitalLabel: "Hospital",
          hospitalValue: "St. Mary's General Hospital",
          buttonText: "Review Request  →",
          buttonColor: const Color(0xFFEF2222),
          borderColor: const Color(0xFFF8B4B4),
          priorityColor: const Color(0xFFDC2626),
        ),
      );
      cards.add(const SizedBox(height: 18));
    }

    if (selectedTab == "All Requests" || selectedTab == "Organ Requests") {
      cards.add(
        _buildRequestCard(
          priority: "ORGAN REQUEST • ROUTINE",
          name: "Sarah Jenkins",
          badgeText: "MATCHING",
          badgeBg: const Color(0xFFE5E7EB),
          badgeColor: const Color(0xFF64748B),
          needLabel: "Organ",
          needValue: "Kidney",
          unitsLabel: "Type",
          unitsValue: "Live Donor",
          hospitalLabel: "Hospital",
          hospitalValue: "City Health Center",
          buttonText: "Review Request  →",
          buttonColor: const Color(0xFFE5F0FF),
          buttonTextColor: const Color(0xFF1E88E5),
          priorityColor: const Color(0xFF1E88E5),
        ),
      );
      cards.add(const SizedBox(height: 18));
    }

    if (selectedTab == "All Requests" || selectedTab == "Blood Requests") {
      cards.add(
        _buildRequestCard(
          priority: "URGENT • MEDIUM PRIORITY",
          name: "Michael Ross",
          badgeText: "PROCESSING",
          badgeBg: const Color(0xFFFFF1D6),
          badgeColor: const Color(0xFFD97706),
          needLabel: "Need",
          needValue: "Blood AB-",
          unitsLabel: "Units",
          unitsValue: "2 Units",
          hospitalLabel: "Hospital",
          hospitalValue: "Regional Medical Center",
          buttonText: "Review Request  →",
          buttonColor: const Color(0xFFE5F0FF),
          buttonTextColor: const Color(0xFF1E88E5),
          priorityColor: const Color(0xFFF97316),
        ),
      );
      cards.add(const SizedBox(height: 18));
    }

    if (selectedTab == "All Requests" || selectedTab == "Blood Requests") {
      cards.add(
        _buildRequestCard(
          priority: "COMPLETED",
          name: "Emily Watts",
          badgeText: "DISPATCHED",
          badgeBg: const Color(0xFFDDF7E7),
          badgeColor: const Color(0xFF16A34A),
          needLabel: "Need",
          needValue: "Plasma",
          unitsLabel: "Hospital",
          unitsValue: "Sunrise Clinic",
          hospitalLabel: "",
          hospitalValue: "",
          buttonText: "View Details  👁",
          buttonColor: const Color(0xFFF1F5F9),
          buttonTextColor: const Color(0xFF94A3B8),
          priorityColor: const Color(0xFF22C55E),
        ),
      );
    }

    return cards;
  }

  Widget _buildRequestCard({
    required String priority,
    required String name,
    required String badgeText,
    required Color badgeBg,
    required Color badgeColor,
    required String needLabel,
    required String needValue,
    required String unitsLabel,
    required String unitsValue,
    Color? unitsColor, // Changed to Color? type
    required String hospitalLabel,
    required String hospitalValue,
    required String buttonText,
    required Color buttonColor,
    Color buttonTextColor = Colors.white,
    Color borderColor = const Color(0xFFE2E8F0),
    required Color priorityColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  priority,
                  style: TextStyle(
                    color: priorityColor,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    fontSize: 13,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    color: badgeColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            name,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildInfoItem(needLabel, needValue)),
              Expanded(
                child: _buildInfoItem(
                  unitsLabel,
                  unitsValue,
                  valueColor: unitsColor, // Now passing Color directly
                ),
              ),
            ],
          ),
          if (hospitalLabel.isNotEmpty) ...[
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: _buildInfoItem(hospitalLabel, hospitalValue),
            ),
          ],
          const SizedBox(height: 22),
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Clicked: $buttonText for $name')),
              );
            },
            child: Container(
              height: 58,
              decoration: BoxDecoration(
                color: buttonColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  buttonText,
                  style: TextStyle(
                    color: buttonTextColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, {Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: valueColor ?? const Color(0xFF111827),
          ),
        ),
      ],
    );
  }
}
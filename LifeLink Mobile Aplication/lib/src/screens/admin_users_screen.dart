import 'package:flutter/material.dart';

class AdminUsersScreenContent extends StatefulWidget {
  const AdminUsersScreenContent({super.key});

  @override
  State<AdminUsersScreenContent> createState() => _AdminUsersScreenContentState();
}

class _AdminUsersScreenContentState extends State<AdminUsersScreenContent> {
  String selectedTab = "Donors";

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
                _buildSearchBar(),
                const SizedBox(height: 20),
                _buildTabs(),
                const SizedBox(height: 18),
                ..._buildUserCards(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
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
              "Users",
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

  Widget _buildSearchBar() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        children: [
          Icon(Icons.search, size: 32, color: Color(0xFF64748B)),
          SizedBox(width: 14),
          Expanded(
            child: Text(
              "Search by name, organization or role",
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF64748B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    final tabs = ["Donors", "Patients", "Hospitals / Blood Banks"];

    return Row(
      children: tabs.map((tab) {
        final isSelected = selectedTab == tab;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                selectedTab = tab;
              });
            },
            child: Column(
              children: [
                Text(
                  tab,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? const Color(0xFF1E88E5)
                        : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  height: 3,
                  color: isSelected
                      ? const Color(0xFF1E88E5)
                      : Colors.transparent,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  List<Widget> _buildUserCards() {
    if (selectedTab == "Donors") {
      return [
        _buildUserCard(
          avatarIcon: Icons.person,
          avatarColor: const Color(0xFF1E88E5),
          name: "Johnathan Smith",
          subTitle: "O+ DONOR • OCT 2023",
          statusText: "ACTIVE",
          statusBg: const Color(0xFFDDF7E7),
          statusColor: const Color(0xFF047857),
          verificationText: "Verified",
          verificationColor: const Color(0xFF059669),
          verificationIcon: Icons.verified,
          leftButtonText: "View",
          leftButtonColor: const Color(0xFF1E88E5),
          leftButtonTextColor: Colors.white,
          leftIcon: Icons.remove_red_eye,
          rightButtonText: "Disable",
          rightButtonColor: Colors.white,
          rightButtonTextColor: const Color(0xFF111827),
        ),
        const SizedBox(height: 18),
        _buildUserCard(
          avatarIcon: Icons.person,
          avatarColor: const Color(0xFF1E88E5),
          name: "Mark Thompson",
          subTitle: "A- DONOR • DEC 2023",
          statusText: "ACTIVE",
          statusBg: const Color(0xFFDDF7E7),
          statusColor: const Color(0xFF047857),
          verificationText: "Verified",
          verificationColor: const Color(0xFF059669),
          verificationIcon: Icons.verified,
          leftButtonText: "View",
          leftButtonColor: const Color(0xFF1E88E5),
          leftButtonTextColor: Colors.white,
          leftIcon: Icons.remove_red_eye,
          rightButtonText: "Disable",
          rightButtonColor: Colors.white,
          rightButtonTextColor: const Color(0xFF111827),
        ),
      ];
    }

    if (selectedTab == "Patients") {
      return [
        _buildUserCard(
          avatarIcon: Icons.person,
          avatarColor: const Color(0xFF94A3B8),
          name: "Sarah Williams",
          subTitle: "PATIENT • SEP 2023",
          statusText: "SUSPENDED",
          statusBg: const Color(0xFFE5E7EB),
          statusColor: const Color(0xFF6B7280),
          verificationText: "Unverified",
          verificationColor: const Color(0xFF64748B),
          verificationIcon: Icons.cancel,
          leftButtonText: "View Profile",
          leftButtonColor: const Color(0xFF4B5563),
          leftButtonTextColor: Colors.white,
          rightButtonText: "Enable",
          rightButtonColor: Colors.white,
          rightButtonTextColor: const Color(0xFF1E88E5),
        ),
      ];
    }

    // Hospitals / Blood Banks tab
    return [
      _buildUserCard(
        avatarIcon: Icons.local_hospital,
        avatarColor: const Color(0xFF1E88E5),
        name: "City Central Blood Bank",
        subTitle: "HOSPITAL • NOV 2023",
        statusText: "PENDING",
        statusBg: const Color(0xFFFFF1D6),
        statusColor: const Color(0xFFB45309),
        verificationText: "Verification Pending",
        verificationColor: const Color(0xFFD97706),
        verificationIcon: Icons.hourglass_bottom,
        leftButtonText: "Approve",
        leftButtonColor: const Color(0xFFE5F0FF),
        leftButtonTextColor: const Color(0xFF1E88E5),
        rightButtonText: "Reject",
        rightButtonColor: const Color(0xFFFFEEF0),
        rightButtonTextColor: const Color(0xFFE11D48),
      ),
      const SizedBox(height: 18),
      _buildUserCard(
        avatarIcon: Icons.local_hospital,
        avatarColor: const Color(0xFF1E88E5),
        name: "St. Mary's Medical Center",
        subTitle: "HOSPITAL • DEC 2023",
        statusText: "ACTIVE",
        statusBg: const Color(0xFFDDF7E7),
        statusColor: const Color(0xFF047857),
        verificationText: "Verified",
        verificationColor: const Color(0xFF059669),
        verificationIcon: Icons.verified,
        leftButtonText: "View",
        leftButtonColor: const Color(0xFF1E88E5),
        leftButtonTextColor: Colors.white,
        leftIcon: Icons.remove_red_eye,
        rightButtonText: "Manage",
        rightButtonColor: Colors.white,
        rightButtonTextColor: const Color(0xFF1E88E5),
      ),
    ];
  }

  Widget _buildUserCard({
    required IconData avatarIcon,
    required Color avatarColor,
    required String name,
    required String subTitle,
    required String statusText,
    required Color statusBg,
    required Color statusColor,
    required String verificationText,
    required Color verificationColor,
    required IconData verificationIcon,
    required String leftButtonText,
    required Color leftButtonColor,
    required Color leftButtonTextColor,
    IconData? leftIcon,
    required String rightButtonText,
    required Color rightButtonColor,
    required Color rightButtonTextColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF3FF),
                  shape: BoxShape.circle,
                ),
                child: Icon(avatarIcon, size: 38, color: avatarColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subTitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(verificationIcon, size: 18, color: verificationColor),
                        const SizedBox(width: 6),
                        Text(
                          verificationText,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: verificationColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$leftButtonText clicked for $name')),
                    );
                  },
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: leftButtonColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (leftIcon != null) ...[
                          Icon(leftIcon, color: leftButtonTextColor, size: 18),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          leftButtonText,
                          style: TextStyle(
                            color: leftButtonTextColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$rightButtonText clicked for $name')),
                    );
                  },
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: rightButtonColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFD1D5DB)),
                    ),
                    child: Center(
                      child: Text(
                        rightButtonText,
                        style: TextStyle(
                          color: rightButtonTextColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
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
// admin_profile_screen.dart
import 'package:flutter/material.dart';
import 'login_screen.dart';

class AdminProfileScreen extends StatelessWidget {
  const AdminProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: const AdminProfileScreenContent(),
    );
  }
}

class AdminProfileScreenContent extends StatelessWidget {
  const AdminProfileScreenContent({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildTopBar(context),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const SizedBox(height: 18),
                _buildProfileHeader(),
                const SizedBox(height: 28),
                _buildSectionTitle("ACCOUNT SETTINGS"),
                const SizedBox(height: 12),
                _buildSettingsGroup([
                  _buildSettingTile(Icons.person, "Edit Profile", () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Edit Profile - Coming Soon')),
                    );
                  }),
                  _buildDivider(),
                  _buildSettingTile(Icons.lock, "Change Password", () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Change Password - Coming Soon')),
                    );
                  }),
                ]),
                const SizedBox(height: 26),
                _buildSectionTitle("SYSTEM SETTINGS"),
                const SizedBox(height: 12),
                _buildSettingsGroup([
                  _buildSettingTile(Icons.shield_outlined, "Manage Roles & Permissions", () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Manage Roles - Coming Soon')),
                    );
                  }),
                  _buildDivider(),
                  _buildSettingTile(Icons.notifications, "Notification Preferences", () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Notification Preferences - Coming Soon')),
                    );
                  }),
                ]),
                const SizedBox(height: 26),
                _buildSectionTitle("SUPPORT & LOGS"),
                const SizedBox(height: 12),
                _buildSettingsGroup([
                  _buildSettingTile(Icons.list_alt, "View System Logs", () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('System Logs - Coming Soon')),
                    );
                  }),
                  _buildDivider(),
                  _buildSettingTile(Icons.headset_mic, "Contact Support", () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Contact Support - Coming Soon')),
                    );
                  }),
                ]),
                const SizedBox(height: 28),
                _buildLogoutButton(context),
                const SizedBox(height: 26),
                const Text(
                  "LifeLink Admin v4.2.0-stable",
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF94A3B8),
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F1FB),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.person,
              color: Color(0xFF1E88E5),
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              "Admin Profile",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
          ),
          Stack(
            children: [
              const Icon(
                Icons.notifications,
                color: Color(0xFF374151),
                size: 26,
              ),
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
          const SizedBox(width: 16),
          const CircleAvatar(
            radius: 20,
            backgroundColor: Color(0xFFE5E7EB),
            child: Icon(Icons.person, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF3B82F6), width: 3),
                color: const Color(0xFFEAF3FF),
              ),
              child: const Icon(
                Icons.admin_panel_settings,
                size: 80,
                color: Color(0xFF3B82F6),
              ),
            ),
            Positioned(
              right: 6,
              bottom: 8,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E88E5),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: const Icon(Icons.edit, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        const Text(
          "Admin User",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          "SYSTEM ADMINISTRATOR",
          style: TextStyle(
            fontSize: 14,
            letterSpacing: 2,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E88E5),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          "admin@lifelink.com",
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF6B7280),
          fontWeight: FontWeight.w800,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(List<Widget> children) {
    return Container(
      width: double.infinity,
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
      child: Column(children: children),
    );
  }

  Widget _buildSettingTile(IconData icon, String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF3FF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: const Color(0xFF1E88E5), size: 28),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  color: Color(0xFF111827),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, size: 28, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, color: Color(0xFFE5E7EB));
  }

  Widget _buildLogoutButton(BuildContext context) {
    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Logout'),
              content: const Text('Are you sure you want to logout?'),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                      (route) => false,
                    );
                  },
                  child: const Text('Logout', style: TextStyle(color: Colors.red)),
                ),
              ],
            );
          },
        );
      },
      child: Container(
        width: double.infinity,
        height: 74,
        decoration: BoxDecoration(
          color: const Color(0xFFFFF5F5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF8B4B4)),
        ),
        child: const Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout, color: Colors.red, size: 28),
              SizedBox(width: 10),
              Text(
                "Logout",
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
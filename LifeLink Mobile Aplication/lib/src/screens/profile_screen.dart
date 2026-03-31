import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'map_screen.dart';
import 'notifications_screen.dart';
import 'donate_screen.dart';
import 'EditProfileScreen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _selectedNavIndex = 4; // Profile is active

  bool _isLoading = true;
  String? _errorMessage;

  String? fullName;
  String? bloodGroup;
  String? email;
  String? phone;
  String? city;
  String? gender;
  String? age;
  String? nic;
  String? donationPref;
  String? avatarUrl;

  // Donation Stats
  int totalDonations = 0;
  String lastDonationDate = "Never";

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null || token.trim().isEmpty) {
        setState(() {
          _errorMessage = 'Please login to view your profile';
          _isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('http://10.168.30.196:3000/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          fullName = data['fullName'] ?? data['name'] ?? 'User';
          bloodGroup = data['bloodGroup'] ?? 'Unknown';
          email = data['email'] ?? 'Not set';
          phone = data['phone'] ?? 'Not set';
          city = data['city'] ?? 'Not set';
          gender = data['gender'] ?? '';
          age = data['age'] ?? '';
          nic = data['nic'] ?? '';
          donationPref = data['donationPref'] ?? 'Not specified';

          // Avatar
          avatarUrl = (data['avatarUrl']?.toString().isNotEmpty ?? false)
              ? data['avatarUrl']
              : 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400';

          // Donation Statistics from backend
          totalDonations = data['totalDonations'] ?? 0;
          lastDonationDate = data['lastDonationDate'] ?? "Never";

          _isLoading = false;
        });
      } else if (response.statusCode == 401) {
        setState(() {
          _errorMessage = 'Session expired. Please login again.';
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load profile (${response.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Profile loading error: $e');
      setState(() {
        _errorMessage = 'Connection error. Please check your internet.';
        _isLoading = false;
      });
    }
  }

  void _onNavTap(int index) {
    if (index == 0) {
      Navigator.pop(context);
      return;
    }
    if (index == 1) {
      Navigator.push(
              context, MaterialPageRoute(builder: (_) => const MapScreen()))
          .then((_) => setState(() => _selectedNavIndex = 4));
      return;
    }
    if (index == 3) {
      Navigator.push(context,
              MaterialPageRoute(builder: (_) => const NotificationsScreen()))
          .then((_) => setState(() => _selectedNavIndex = 4));
      return;
    }

    setState(() => _selectedNavIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: Color(0xFF2979FF)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Profile',
          style: TextStyle(
              color: Color(0xFF1A2340),
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(_errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 16),
                        textAlign: TextAlign.center),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  child: Column(
                    children: [
                      // Avatar + Name + Blood Group
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 124,
                            height: 124,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: const Color(0xFF2979FF), width: 3.5),
                              boxShadow: [
                                BoxShadow(
                                    color: const Color(0xFF2979FF)
                                        .withOpacity(0.18),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6))
                              ],
                            ),
                            child: ClipOval(
                              child: Image.network(
                                avatarUrl ?? '',
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                    Icons.person,
                                    size: 70,
                                    color: Colors.grey),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        fullName ?? 'User',
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1A2340)),
                      ),
                      const SizedBox(height: 8),

                      // Blood Group Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                            color: const Color(0xFF2979FF),
                            borderRadius: BorderRadius.circular(30)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.water_drop_rounded,
                                color: Colors.white, size: 20),
                            const SizedBox(width: 6),
                            Text(bloodGroup ?? 'Unknown',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Donation Summary - Now showing real data
                      _buildSectionCard(
                        title: 'DONATION SUMMARY',
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildStatColumn(
                                  '$totalDonations', 'Total Donations'),
                              Container(
                                  width: 1,
                                  height: 50,
                                  color: const Color(0xFFF0F0F0)),
                              _buildStatColumn(
                                  lastDonationDate, 'Last Donation Date'),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Contact Information
                      _buildSectionCard(
                        title: 'CONTACT INFORMATION',
                        children: [
                          _buildInfoRow(Icons.email_rounded, 'Email Address',
                              email ?? 'Not set'),
                          const Divider(height: 32),
                          _buildInfoRow(Icons.phone_rounded, 'Phone Number',
                              phone ?? 'Not set'),
                          const Divider(height: 32),
                          _buildInfoRow(Icons.location_on_rounded, 'Location',
                              city ?? 'Not set'),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Health & Eligibility
                      _buildSectionCard(
                        title: 'HEALTH & ELIGIBILITY',
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Eligible Organs',
                                        style: TextStyle(
                                            color: Color(0xFF9E9E9E),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 6),
                                    Text(donationPref ?? 'Not specified',
                                        style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF1A2340))),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Health Score',
                                      style: TextStyle(
                                        color: Color(0xFF9E9E9E),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(height: 6),
                                    Text(
                                      '98% Optimal',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF43A047),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Donation Summary
                      _buildSectionCard(
                        title: 'DONATION SUMMARY',
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildStatColumn(
                                  '$totalDonations', 'Total Donations'),
                              Container(
                                width: 1,
                                height: 50,
                                color: const Color(0xFFF0F0F0),
                              ),
                              _buildStatColumn(
                                lastDonationDate ?? 'Never',
                                'Last Donation Date',
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Action Buttons
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final updated = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EditProfileScreen(
                                  initialData: {
                                    'fullName': fullName,
                                    'phone': phone,
                                    'city': city,
                                    'age': age,
                                    'bloodGroup': bloodGroup,
                                    'gender': gender,
                                    'donationPref': donationPref,
                                    'avatarUrl': avatarUrl,
                                  },
                                ),
                              ),
                            );
                            if (updated == true) _loadProfileData();
                          },
                          icon: const Icon(Icons.edit_rounded, size: 20),
                          label: const Text('Edit Profile',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w700)),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2979FF),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14))),
                        ),
                      ),

                      const SizedBox(height: 16),

                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.remove('jwt_token');
                            Navigator.popUntil(
                                context, (route) => route.isFirst);
                          },
                          icon: const Icon(Icons.logout_rounded,
                              color: Color(0xFFE53935), size: 20),
                          label: const Text('Logout',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFE53935))),
                          style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                  color: Color(0xFFE53935), width: 2),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14))),
                        ),
                      ),
                    ],
                  ),
                ),
      floatingActionButton: _buildDonateFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  // Helper Widgets
  Widget _buildSectionCard(
      {required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: Color(0xFF1A2340),
                  fontSize: 15,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF2979FF), size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      color: Color(0xFF9E9E9E),
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(value,
                  style: const TextStyle(
                      color: Color(0xFF1A2340),
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatColumn(String value, String label) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A2340))),
        const SizedBox(height: 6),
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w600),
            textAlign: TextAlign.center),
      ],
    );
  }

  Widget _buildDonateFAB() {
    return GestureDetector(
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => const DonateScreen())),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFFE53935),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                    color: const Color(0xFFE53935).withOpacity(0.38),
                    blurRadius: 14,
                    offset: const Offset(0, 5))
              ],
            ),
            child: const Icon(Icons.favorite_rounded,
                color: Colors.white, size: 28),
          ),
          const SizedBox(height: 2),
          const Text('Donate',
              style: TextStyle(
                  color: Color(0xFFE53935),
                  fontSize: 10,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return BottomAppBar(
      color: Colors.white,
      elevation: 14,
      shadowColor: Colors.black.withOpacity(0.10),
      notchMargin: 6,
      shape: const CircularNotchedRectangle(),
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(icon: Icons.home_rounded, label: 'Home', index: 0),
            _buildNavItem(icon: Icons.map_outlined, label: 'Map', index: 1),
            const SizedBox(width: 58),
            _buildNavItemWithBadge(
                icon: Icons.notifications_outlined, label: 'Alerts', index: 3),
            _buildNavItem(
                icon: Icons.person_rounded, label: 'Profile', index: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
      {required IconData icon, required String label, required int index}) {
    final active = _selectedNavIndex == index;
    return GestureDetector(
      onTap: () => _onNavTap(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 58,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                color:
                    active ? const Color(0xFF2979FF) : const Color(0xFFB0BEC5),
                size: 24),
            const SizedBox(height: 3),
            Text(label,
                style: TextStyle(
                    color: active
                        ? const Color(0xFF2979FF)
                        : const Color(0xFFB0BEC5),
                    fontSize: 10,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItemWithBadge(
      {required IconData icon, required String label, required int index}) {
    final active = _selectedNavIndex == index;
    return GestureDetector(
      onTap: () => _onNavTap(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 58,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon,
                    color: active
                        ? const Color(0xFF2979FF)
                        : const Color(0xFFB0BEC5),
                    size: 24),
                if (!active)
                  Positioned(
                      top: -2,
                      right: -3,
                      child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                              color: Color(0xFFE53935),
                              shape: BoxShape.circle))),
              ],
            ),
            const SizedBox(height: 3),
            Text(label,
                style: TextStyle(
                    color: active
                        ? const Color(0xFF2979FF)
                        : const Color(0xFFB0BEC5),
                    fontSize: 10,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

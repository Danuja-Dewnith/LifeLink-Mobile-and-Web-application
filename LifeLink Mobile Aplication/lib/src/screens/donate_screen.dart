import 'package:flutter/material.dart';
import 'donor_dash.dart';
import 'map_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'donate_form_screen.dart';
import 'donation_history_screen.dart'; // ← New screen for all history

import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:lifelink_app/src/utils/auth_helper.dart';

const String baseUrl = 'http://10.168.30.196:3000';

class DonateScreen extends StatefulWidget {
  const DonateScreen({super.key});

  @override
  State<DonateScreen> createState() => _DonateScreenState();
}

class _DonateScreenState extends State<DonateScreen> {
  int _selectedNavIndex = 2;

  List<dynamic> _donationHistory = [];
  bool _isHistoryLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDonationHistory();
  }

  Future<void> _loadDonationHistory() async {
    final token = await AuthHelper.getToken();
    if (token == null || token.isEmpty) {
      setState(() => _isHistoryLoading = false);
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/donations/my-donations'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _donationHistory =
              (data['donations'] ?? []).take(3).toList(); // Only latest 3
        });
      }
    } catch (e) {
      print('Error loading donation history: $e');
    } finally {
      if (mounted) setState(() => _isHistoryLoading = false);
    }
  }

  void _goToDonateForm() {
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => const DonateFormScreen()));
  }

  void _goToAllHistory() {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => const DonationHistoryScreen()));
  }

  void _onNavTap(int index) {
    if (index == 0) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const DashboardScreen()));
      return;
    }
    if (index == 1) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const MapScreen()));
      return;
    }
    if (index == 3) {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const NotificationsScreen()));
      return;
    }
    if (index == 4) {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
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
            icon:
                const Icon(Icons.arrow_back_rounded, color: Color(0xFF2979FF)),
            onPressed: () => Navigator.pop(context)),
        title: const Text('Donate Now',
            style: TextStyle(
                color: Color(0xFF1A2340),
                fontSize: 20,
                fontWeight: FontWeight.w800)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded,
                color: Color(0xFF2979FF)),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Doctor\'s guidelines available below'))),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 30, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Hero Donate Button
            GestureDetector(
              onTap: _goToDonateForm,
              child: Container(
                width: 230,
                height: 230,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                      colors: [Color(0xFFE53935), Color(0xFFFF5252)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight),
                  boxShadow: [
                    BoxShadow(
                        color: const Color(0xFFE53935).withOpacity(0.6),
                        blurRadius: 40,
                        spreadRadius: 8,
                        offset: const Offset(0, 20))
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(115),
                    onTap: _goToDonateForm,
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.favorite_rounded,
                            color: Colors.white, size: 85),
                        SizedBox(height: 12),
                        Text('DONATE NOW',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5)),
                        Text('Save a Life Today',
                            style: TextStyle(
                                color: Colors.white70,
                                fontSize: 15,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 60),

            // Doctor's Instructions
            _buildInfoCard(
              title: "Doctor's Instructions",
              icon: Icons.medical_services_rounded,
              iconColor: const Color(0xFFE53935),
              children: const [
                Text('• Stay hydrated and eat a light meal before donation.',
                    style: TextStyle(fontSize: 15.5)),
                SizedBox(height: 10),
                Text('• Avoid heavy exercise for 24 hours after donation.',
                    style: TextStyle(fontSize: 15.5)),
                SizedBox(height: 10),
                Text('• Bring your NIC or valid ID.',
                    style: TextStyle(fontSize: 15.5)),
                SizedBox(height: 10),
                Text('• Rest for at least 10-15 minutes after donation.',
                    style: TextStyle(fontSize: 15.5)),
                SizedBox(height: 10),
                Text('• If you feel dizzy, inform the staff immediately.',
                    style: TextStyle(fontSize: 15.5)),
              ],
            ),

            const SizedBox(height: 30),

            // Donation History - Latest 3 only
            _buildInfoCard(
              title: "Recent Donation History",
              icon: Icons.history_rounded,
              iconColor: const Color(0xFF2979FF),
              children: _isHistoryLoading
                  ? [
                      const Center(
                          child: Padding(
                              padding: EdgeInsets.all(30),
                              child: CircularProgressIndicator()))
                    ]
                  : _donationHistory.isEmpty
                      ? [
                          const Padding(
                              padding: EdgeInsets.all(20),
                              child: Text(
                                  'No donations yet.\nYour donations will appear here.',
                                  textAlign: TextAlign.center))
                        ]
                      : _donationHistory
                          .map((d) => Column(
                                children: [
                                  ListTile(
                                    leading: const Icon(Icons.history,
                                        color: Color(0xFF2979FF)),
                                    title: Text(
                                        '${d['donationType']} • ${d['date']}'),
                                    subtitle: Text(
                                        '${d['hospitalName']} • ${d['units']}'),
                                    dense: true,
                                  ),
                                  const Divider(height: 8),
                                ],
                              ))
                          .toList(),
            ),

            // View All History Button
            if (_donationHistory.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: TextButton.icon(
                  onPressed: _goToAllHistory,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('View All History',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF2979FF)),
                ),
              ),

            const SizedBox(height: 60),
          ],
        ),
      ),
      floatingActionButton: _buildDonateFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildInfoCard(
      {required String title,
      required IconData icon,
      required Color iconColor,
      required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, 8))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 30),
              const SizedBox(width: 14),
              Text(title,
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A2340))),
            ],
          ),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }

  // FAB and Bottom Navigation (unchanged)
  Widget _buildDonateFAB() {
    /* your existing code */
    return Column(
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
              ]),
          child:
              const Icon(Icons.favorite_rounded, color: Colors.white, size: 28),
        ),
        const SizedBox(height: 2),
        const Text('Donate',
            style: TextStyle(
                color: Color(0xFFE53935),
                fontSize: 10,
                fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildBottomNavBar() {
    /* your existing code */
    return BottomAppBar(
      color: Colors.white,
      elevation: 14,
      shadowColor: Colors.black.withOpacity(0.10),
      notchMargin: 6,
      shape: const CircularNotchedRectangle(),
      child: SizedBox(
          height: 60,
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _buildNavItem(icon: Icons.home_rounded, label: 'HOME', index: 0),
            _buildNavItem(icon: Icons.map_rounded, label: 'MAP', index: 1),
            const SizedBox(width: 58),
            _buildNavItemWithBadge(
                icon: Icons.notifications_rounded, label: 'ALERTS', index: 3),
            _buildNavItem(
                icon: Icons.person_rounded, label: 'PROFILE', index: 4),
          ])),
    );
  }

  // Keep your _buildNavItem and _buildNavItemWithBadge as they are
  Widget _buildNavItem(
      {required IconData icon, required String label, required int index}) {
    /* your existing code */
    final bool active = _selectedNavIndex == index;
    return GestureDetector(
      onTap: () => _onNavTap(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
          width: 58,
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
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
          ])),
    );
  }

  Widget _buildNavItemWithBadge(
      {required IconData icon, required String label, required int index}) {
    /* your existing code */
    final bool active = _selectedNavIndex == index;
    return GestureDetector(
      onTap: () => _onNavTap(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
          width: 58,
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Stack(clipBehavior: Clip.none, children: [
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
                            color: Color(0xFFE53935), shape: BoxShape.circle))),
            ]),
            const SizedBox(height: 3),
            Text(label,
                style: TextStyle(
                    color: active
                        ? const Color(0xFF2979FF)
                        : const Color(0xFFB0BEC5),
                    fontSize: 10,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500)),
          ])),
    );
  }
}

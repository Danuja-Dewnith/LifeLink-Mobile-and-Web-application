import 'dart:async'; // ← Add this import for Timer
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import 'notifications_screen.dart';
import 'map_screen.dart';
import 'donate_screen.dart';
import 'profile_screen.dart';
import 'donation_history_screen.dart';
import 'ai_chat_screen.dart'; // ← Your Gemini Chat Screen

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  // Profile Data
  bool _isLoadingProfile = true;
  String? fullName;
  String? bloodGroup;
  String? avatarUrl;
  String? donationPref;

  // Donation Status Data
  String lastDonationDate = "Never";
  String nextEligibilityDate = "In 90 Days";
  bool isEligibleNow = false;
  DateTime? lastDonationDateTime;
  Timer? _countdownTimer;
  Duration _remainingTime = Duration.zero;

  // Donation History Data (Latest 2)
  List<dynamic> recentDonations = [];

  // AI Chat Popup State
  bool _isChatOpen = false;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
    _loadRecentDonations();
    _startCountdownTimer();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdownTimer() {
    _countdownTimer?.cancel();

    if (lastDonationDateTime != null) {
      final eligibilityDate =
          lastDonationDateTime!.add(const Duration(days: 90));
      final now = DateTime.now();

      if (now.isBefore(eligibilityDate)) {
        _remainingTime = eligibilityDate.difference(now);
        _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            if (_remainingTime.inSeconds > 0) {
              _remainingTime = _remainingTime - const Duration(seconds: 1);
            } else {
              timer.cancel();
              _updateEligibilityStatus();
            }
          });
        });
      }
    }
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoadingProfile = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null || token.trim().isEmpty) {
        setState(() => _isLoadingProfile = false);
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
          donationPref = data['donationPref'] ?? 'Kidney, Liver';

          avatarUrl = (data['avatarUrl']?.toString().isNotEmpty ?? false)
              ? data['avatarUrl']
              : null;

          lastDonationDate = data['lastDonationDate'] ?? "Never";

          // Parse last donation date if available
          if (lastDonationDate != "Never") {
            try {
              if (lastDonationDate.contains(",")) {
                lastDonationDateTime =
                    DateFormat("MMM dd, HH:mm").parse(lastDonationDate);
              } else {
                lastDonationDateTime = DateTime.parse(lastDonationDate);
              }
            } catch (e) {
              lastDonationDateTime = null;
            }
          }

          _calculateNextEligibility(lastDonationDate);
          _isLoadingProfile = false;
        });

        _startCountdownTimer();
      } else {
        setState(() => _isLoadingProfile = false);
      }
    } catch (e) {
      print('Dashboard profile loading error: $e');
      setState(() => _isLoadingProfile = false);
    }
  }

  void _updateEligibilityStatus() {
    setState(() {
      isEligibleNow = true;
      nextEligibilityDate = "You can donate now";
    });
  }

  void _calculateNextEligibility(String lastDateStr) {
    if (lastDateStr == "Never") {
      nextEligibilityDate = "You can donate now";
      isEligibleNow = true;
      return;
    }

    try {
      DateTime lastDonation;
      if (lastDateStr.contains(",")) {
        lastDonation = DateFormat("MMM dd, HH:mm").parse(lastDateStr);
      } else {
        lastDonation = DateTime.parse(lastDateStr);
      }

      DateTime eligibilityDate = lastDonation.add(const Duration(days: 90));

      if (DateTime.now().isAfter(eligibilityDate)) {
        nextEligibilityDate = "You can donate now";
        isEligibleNow = true;
      } else {
        final daysLeft = eligibilityDate.difference(DateTime.now()).inDays;
        final hoursLeft =
            eligibilityDate.difference(DateTime.now()).inHours % 24;
        final minutesLeft =
            eligibilityDate.difference(DateTime.now()).inMinutes % 60;

        if (daysLeft > 0) {
          nextEligibilityDate = "In $daysLeft days";
        } else if (hoursLeft > 0) {
          nextEligibilityDate = "In $hoursLeft hours";
        } else if (minutesLeft > 0) {
          nextEligibilityDate = "In $minutesLeft minutes";
        } else {
          nextEligibilityDate = "In 90 Days";
        }

        isEligibleNow = false;
      }
    } catch (e) {
      nextEligibilityDate = "In 90 Days";
      isEligibleNow = false;
    }
  }

  String _formatRemainingTime() {
    if (_remainingTime.inSeconds <= 0) {
      return "You can donate now";
    }

    final days = _remainingTime.inDays;
    final hours = _remainingTime.inHours % 24;
    final minutes = _remainingTime.inMinutes % 60;
    final seconds = _remainingTime.inSeconds % 60;

    if (days > 0) {
      return "In $days days, $hours hours";
    } else if (hours > 0) {
      return "In $hours hours, $minutes min";
    } else if (minutes > 0) {
      return "In $minutes min, $seconds sec";
    } else {
      return "In $seconds sec";
    }
  }

  Future<void> _loadRecentDonations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null || token.trim().isEmpty) return;

      final response = await http.get(
        Uri.parse('http://10.168.30.196:3000/donations/my-donations'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          recentDonations = (data['donations'] ?? []).take(2).toList();
        });
      }
    } catch (e) {
      print('Error loading recent donations: $e');
    }
  }

  Future<void> _recordDonation() async {
    // Navigate to donate screen and wait for result
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const DonateScreen()),
    );

    if (result == true) {
      // Donation recorded successfully
      _loadProfileData(); // Reload profile to get updated last donation date
      _loadRecentDonations(); // Reload donation history

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Donation recorded! 90-day countdown started.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // New method to manually start the 90-day countdown
  void _startManualCountdown() {
    setState(() {
      // Set last donation date to current time
      final now = DateTime.now();
      lastDonationDateTime = now;
      lastDonationDate = DateFormat("MMM dd, HH:mm").format(now);

      // Calculate eligibility date (90 days from now)
      final eligibilityDate = now.add(const Duration(days: 90));

      // Update the countdown
      _remainingTime = eligibilityDate.difference(now);
      isEligibleNow = false;
      nextEligibilityDate = "In 90 days";

      // Start the countdown timer
      _startCountdownTimer();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              '✅ 90-day countdown started! You can donate after this period.'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 3),
        ),
      );
    });
  }

  // ── Central nav tap handler ─────────────────────────────────────────────────
  void _onNavTap(int index) {
    if (index == 1) {
      _goToMap();
      return;
    }
    if (index == 3) {
      _goToNotifications();
      return;
    }
    if (index == 4) {
      _goToProfile();
      return;
    }
    setState(() => _selectedIndex = index);
  }

  void _goToMap() {
    setState(() => _selectedIndex = 1);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MapScreen()),
    ).then((_) => setState(() => _selectedIndex = 0));
  }

  void _goToNotifications() {
    setState(() => _selectedIndex = 3);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    ).then((_) => setState(() => _selectedIndex = 0));
  }

  void _goToProfile() {
    setState(() => _selectedIndex = 4);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    ).then((_) {
      _loadProfileData();
      setState(() => _selectedIndex = 0);
    });
  }

  // Toggle AI Chat Popup
  void _toggleAIChat() {
    setState(() {
      _isChatOpen = !_isChatOpen;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F8),
      appBar: _buildAppBar(),
      body: _isLoadingProfile
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildUserCard(),
                      const SizedBox(height: 20),
                      _buildDonationStatus(),
                      const SizedBox(height: 20),
                      _buildEmergencyAlerts(),
                      const SizedBox(height: 20),
                      _buildNearbyRequests(),
                      const SizedBox(height: 20),
                      _buildNearbyDonationPoints(),
                      const SizedBox(height: 20),
                      _buildDoctorInstructions(),
                      const SizedBox(height: 20),
                      _buildDonationHistory(),
                      const SizedBox(height: 20),
                      _buildRecentNotifications(),
                      const SizedBox(height: 20),
                      _buildManualCountdownButton(), // New button added here
                      const SizedBox(height: 160), // Increased bottom padding
                    ],
                  ),
                ),

                // ==================== BEAUTIFUL AI CHAT POPUP ====================
                if (_isChatOpen)
                  Positioned(
                    bottom: 100,
                    right: 16,
                    child: Material(
                      elevation: 20,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.88,
                        height: MediaQuery.of(context).size.height * 0.72,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.35),
                              blurRadius: 30,
                              offset: const Offset(0, 15),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Chat Header
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              decoration: const BoxDecoration(
                                color: Color(0xFF4F46E5),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  topRight: Radius.circular(20),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.smart_toy_rounded,
                                      color: Colors.white, size: 26),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Text(
                                      'LifeLink AI Assistant',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close,
                                        color: Colors.white, size: 26),
                                    onPressed: _toggleAIChat,
                                  ),
                                ],
                              ),
                            ),
                            // Chat Content
                            Expanded(
                              child: ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(20),
                                  bottomRight: Radius.circular(20),
                                ),
                                child: const ChatScreen(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // ==================== BEAUTIFUL FLOATING CHAT BUTTON ====================
                Positioned(
                  bottom: 85, // Raised higher so it sits nicely above nav bar
                  right: 20,
                  child: GestureDetector(
                    onTap: _toggleAIChat,
                    child: Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4F46E5).withOpacity(0.5),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.chat_bubble_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                ),
              ],
            ),
      floatingActionButton: _buildDonateFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  // New widget for the manual countdown button
  Widget _buildManualCountdownButton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Start Countdown',
            style: TextStyle(
                color: Color(0xFF1A2340),
                fontSize: 16,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _startManualCountdown,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4F46E5).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.timer_outlined,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Start 90-Day Countdown',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Click to begin your donation eligibility countdown',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==================== All your existing methods remain unchanged below ====================

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      leading: Padding(
        padding: const EdgeInsets.all(10),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFE3EEFF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.add, color: Color(0xFF2979FF), size: 22),
        ),
      ),
      title: const Text(
        'LifeLink',
        style: TextStyle(
          color: Color(0xFF1A2340),
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 14),
          child: GestureDetector(
            onTap: _goToNotifications,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF0F0F0),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.notifications_outlined,
                    color: Color(0xFF1A2340),
                    size: 20,
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
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
          ),
        ),
      ],
    );
  }

  Widget _buildUserCard() {
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
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(40),
            child: avatarUrl != null
                ? Image.network(
                    avatarUrl!,
                    width: 62,
                    height: 62,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildDefaultAvatar(),
                  )
                : _buildDefaultAvatar(),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName ?? 'User',
                  style: const TextStyle(
                      color: Color(0xFF1A2340),
                      fontSize: 17,
                      fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _buildBadge(bloodGroup ?? 'Unknown',
                        const Color(0xFFFFEBEB), const Color(0xFFE53935)),
                    const SizedBox(width: 8),
                    _buildBadge('Optimal Health', const Color(0xFFE8F5E9),
                        const Color(0xFF43A047)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Organs: ${donationPref ?? "Kidney, Liver"}',
                  style:
                      const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      width: 62,
      height: 62,
      color: const Color(0xFFB0BEC5),
      child: const Icon(Icons.person, color: Colors.white, size: 38),
    );
  }

  Widget _buildBadge(String label, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: TextStyle(
              color: text, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }

  Widget _buildDonationStatus() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Donation Status',
                style: TextStyle(
                    color: Color(0xFF1A2340),
                    fontSize: 16,
                    fontWeight: FontWeight.w800)),
            Container(
              width: 26,
              height: 26,
              decoration: const BoxDecoration(
                  color: Color(0xFFE3EEFF), shape: BoxShape.circle),
              child: const Icon(Icons.info_outline,
                  color: Color(0xFF2979FF), size: 16),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatusCard(
                label: 'LAST DONATION',
                labelColor: const Color(0xFF2979FF),
                value: lastDonationDate,
                subtitle: 'Whole Blood',
                showProgress: false,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatusCard(
                label: 'NEXT ELIGIBILITY',
                labelColor: isEligibleNow
                    ? const Color(0xFF43A047)
                    : const Color(0xFFE53935),
                value: _remainingTime.inSeconds > 0 && !isEligibleNow
                    ? _formatRemainingTime()
                    : nextEligibilityDate,
                subtitle: isEligibleNow ? 'You are eligible now!' : '',
                showProgress: !isEligibleNow && _remainingTime.inSeconds > 0,
                progressValue: _remainingTime.inSeconds > 0
                    ? 1 - (_remainingTime.inSeconds / (90 * 24 * 3600))
                    : 0,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusCard({
    required String label,
    required Color labelColor,
    required String value,
    required String subtitle,
    required bool showProgress,
    double progressValue = 0,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  color: labelColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8)),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                  color: Color(0xFF1A2340),
                  fontSize: 18,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          if (subtitle.isNotEmpty)
            Text(subtitle,
                style: TextStyle(
                    color: isEligibleNow
                        ? const Color(0xFF43A047)
                        : const Color(0xFF9E9E9E),
                    fontSize: 12)),
          if (showProgress) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progressValue.clamp(0.0, 1.0),
                backgroundColor: const Color(0xFFFFCDD2),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Color(0xFFE53935)),
                minHeight: 5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${((progressValue * 100).toInt()).clamp(0, 100)}% completed',
              style: const TextStyle(
                color: Color(0xFF9E9E9E),
                fontSize: 9,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDonationHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Donation History',
                style: TextStyle(
                    color: Color(0xFF1A2340),
                    fontSize: 16,
                    fontWeight: FontWeight.w800)),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const DonationHistoryScreen()),
                );
              },
              child: const Text('See all',
                  style: TextStyle(
                      color: Color(0xFF2979FF),
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2))
            ],
          ),
          child: recentDonations.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: Text('No recent donations')),
                )
              : Column(
                  children: recentDonations.asMap().entries.map((entry) {
                    final d = entry.value;
                    final isLast = entry.key == recentDonations.length - 1;
                    return _buildHistoryItem(
                      icon: Icons.water_drop_rounded,
                      iconBg: const Color(0xFFE3EEFF),
                      iconColor: const Color(0xFF2979FF),
                      title: '${d['donationType'] ?? 'Blood Donation'}',
                      subtitle:
                          '${d['hospitalName'] ?? 'Unknown'} • ${d['date'] ?? ''}',
                      isLast: isLast,
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildHistoryItem({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isLast,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: Color(0xFFF0F0F0), width: 1)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
              color: iconBg, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Text(title,
            style: const TextStyle(
                color: Color(0xFF1A2340),
                fontSize: 14,
                fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle,
            style: const TextStyle(
                color: Color(0xFF9E9E9E), fontSize: 11, letterSpacing: 0.3)),
        trailing: const Icon(Icons.chevron_right_rounded,
            color: Color(0xFFBDBDBD), size: 22),
      ),
    );
  }

  Widget _buildEmergencyAlerts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Emergency Alerts',
                style: TextStyle(
                    color: Color(0xFF1A2340),
                    fontSize: 16,
                    fontWeight: FontWeight.w800)),
            GestureDetector(
              onTap: _goToNotifications,
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                        color: Color(0xFFE53935), shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  const Text('Live',
                      style: TextStyle(
                          color: Color(0xFFE53935),
                          fontSize: 13,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _goToNotifications,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: const Border(
                  left: BorderSide(color: Color(0xFFE53935), width: 4)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2))
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEB),
                      borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.campaign_rounded,
                      color: Color(0xFFE53935), size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Critical: O- Blood Needed',
                          style: TextStyle(
                              color: Color(0xFF1A2340),
                              fontSize: 14,
                              fontWeight: FontWeight.w800)),
                      SizedBox(height: 4),
                      Text(
                          'City General Hospital requires O-negative blood urgently for surgery.',
                          style: TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 12,
                              height: 1.5)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right_rounded,
                    color: Color(0xFFBDBDBD), size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNearbyRequests() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Nearby Requests',
                style: TextStyle(
                    color: Color(0xFF1A2340),
                    fontSize: 16,
                    fontWeight: FontWeight.w800)),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              child: const Text('View all',
                  style: TextStyle(
                      color: Color(0xFF2979FF),
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04),
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
                  const Text('Red Cross Center',
                      style: TextStyle(
                          color: Color(0xFF1A2340),
                          fontSize: 15,
                          fontWeight: FontWeight.w800)),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: const Color(0xFFFFF3CD),
                        borderRadius: BorderRadius.circular(6)),
                    child: const Text('URGENT',
                        style: TextStyle(
                            color: Color(0xFFE65100),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text('2.4 km away • 15 mins',
                  style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 12)),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2979FF),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            elevation: 0),
                        child: const Text('Accept',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                                color: Color(0xFFE0E0E0), width: 1.5),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10))),
                        child: const Text('Details',
                            style: TextStyle(
                                color: Color(0xFF1A2340),
                                fontWeight: FontWeight.w700,
                                fontSize: 14)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNearbyDonationPoints() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Nearby Donation Points',
            style: TextStyle(
                color: Color(0xFF1A2340),
                fontSize: 16,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _goToMap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                Container(
                  height: 180,
                  width: double.infinity,
                  color: const Color(0xFF1A6DA8),
                  child: Image.network(
                    'https://upload.wikimedia.org/wikipedia/commons/thumb/8/80/World_map_-_low_resolution.svg/1200px-World_map_-_low_resolution.svg.png',
                    fit: BoxFit.cover,
                    color: const Color(0xFF1A6DA8),
                    colorBlendMode: BlendMode.multiply,
                    errorBuilder: (_, __, ___) => const Icon(Icons.map_rounded,
                        color: Colors.white54, size: 60),
                  ),
                ),
                Positioned(
                    top: 40,
                    left: 80,
                    child: _buildMapPin(const Color(0xFFE53935))),
                Positioned(
                    top: 60,
                    right: 100,
                    child: _buildMapPin(const Color(0xFF2979FF))),
                Positioned(
                    top: 30,
                    right: 60,
                    child: _buildMapPin(const Color(0xFFE53935))),
                Positioned(
                    top: 80,
                    left: 160,
                    child: _buildMapPin(const Color(0xFF43A047))),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    color: Colors.black.withOpacity(0.55),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('3 Centers available nearby',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                        ElevatedButton(
                          onPressed: _goToMap,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2979FF),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 6),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              elevation: 0),
                          child: const Text('OPEN MAP',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMapPin(Color color) =>
      Icon(Icons.location_on_rounded, color: color, size: 28);

  Widget _buildDoctorInstructions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Doctor Instructions',
            style: TextStyle(
                color: Color(0xFF1A2340),
                fontSize: 16,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildInstructionCard(
                icon: Icons.restaurant_rounded,
                iconColor: const Color(0xFF2979FF),
                iconBg: const Color(0xFFE3EEFF),
                title: 'Pre-Donation',
                titleColor: const Color(0xFF2979FF),
                body:
                    'Eat a healthy meal and drink plenty of water (500ml) 2 hours before donation.',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInstructionCard(
                icon: Icons.nightlight_round,
                iconColor: const Color(0xFF43A047),
                iconBg: const Color(0xFFE8F5E9),
                title: 'Post-Donation',
                titleColor: const Color(0xFF43A047),
                body:
                    'Rest for 15 mins. Avoid intense exercise for the next few hours.',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInstructionCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required Color titleColor,
    required String body,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                    color: iconBg, borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 8),
              Text(title,
                  style: TextStyle(
                      color: titleColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 10),
          Text(body,
              style: const TextStyle(
                  color: Color(0xFF6B7280), fontSize: 12, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildRecentNotifications() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Recent Notifications',
                style: TextStyle(
                    color: Color(0xFF1A2340),
                    fontSize: 16,
                    fontWeight: FontWeight.w800)),
            TextButton(
              onPressed: _goToNotifications,
              style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              child: const Text('See all',
                  style: TextStyle(
                      color: Color(0xFF2979FF),
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2))
            ],
          ),
          child: Column(
            children: [
              _buildNotificationItem(
                dot: const Color(0xFF2979FF),
                text: 'Your donation helped save 3 lives!',
                time: '2 days ago',
                isLast: false,
              ),
              _buildNotificationItem(
                dot: const Color(0xFFBDBDBD),
                text: 'Health report for Oct 12 is now available.',
                time: '1 week ago',
                isLast: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationItem({
    required Color dot,
    required String text,
    required String time,
    required bool isLast,
  }) {
    return GestureDetector(
      onTap: _goToNotifications,
      child: Padding(
        padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(text,
                      style: const TextStyle(
                          color: Color(0xFF1A2340),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          height: 1.4)),
                  const SizedBox(height: 4),
                  Text(time,
                      style: const TextStyle(
                          color: Color(0xFF9E9E9E), fontSize: 11)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: Color(0xFFBDBDBD), size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDonateFAB() {
    return GestureDetector(
      onTap: _recordDonation, // This now records donation and starts countdown
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
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Icon(Icons.favorite_rounded,
                color: Colors.white, size: 28),
          ),
          const SizedBox(height: 2),
          const Text(
            'Donate',
            style: TextStyle(
              color: Color(0xFFE53935),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
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
                icon: Icons.person_outline_rounded, label: 'Profile', index: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
      {required IconData icon, required String label, required int index}) {
    final bool active = _selectedIndex == index;
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
    final bool active = _selectedIndex == index;
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
                Positioned(
                  top: -2,
                  right: -3,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                        color: Color(0xFFE53935), shape: BoxShape.circle),
                  ),
                ),
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

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lifelink_app/src/screens/patient_map_screen.dart';
import 'patient_profile_screen.dart';
import 'my_requests_screen.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  int _selectedNavIndex = 3;
  int _selectedTab = 0;
  String _userRole = '';
  String _userName = '';

  bool _isLoading = true;
  List<Map<String, dynamic>> _alerts = [];
  List<Map<String, dynamic>> _donationMatchAlerts = [];
  List<Map<String, dynamic>> _readAlerts = [];
  int _unreadCount = 0;

  final List<Map<String, dynamic>> _tabs = [
    {'label': 'All', 'filter': 'all'},
    {'label': 'Donation Match', 'filter': 'donation_match'},
    {'label': 'Read', 'filter': 'read'},
  ];

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadAlerts();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userRole = prefs.getString('user_role') ?? '';
      _userName = prefs.getString('user_name') ?? '';
    });
  }

  Future<void> _loadAlerts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final filter = _tabs[_selectedTab]['filter'];
      final response = await http.get(
        Uri.parse('http://10.168.30.196:3000/api/alerts?filter=$filter'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final alerts = List<Map<String, dynamic>>.from(data['alerts']);

        setState(() {
          _alerts = alerts.map((alert) => _formatAlert(alert)).toList();
          _donationMatchAlerts =
              _alerts.where((a) => a['type'] == 'Donation Match').toList();
          _readAlerts = _alerts.where((a) => a['isRead'] == true).toList();
          _unreadCount = data['unreadCount'] ?? 0;
          _isLoading = false;
        });

        print('✅ Loaded ${_alerts.length} alerts, $_unreadCount unread');
        print('   Donation Match: ${_donationMatchAlerts.length}');
      } else {
        print('❌ Failed to load alerts: ${response.statusCode}');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading alerts: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic> _formatAlert(Map<String, dynamic> alert) {
    final type = alert['type'];
    final isMatch = type == 'Donation Match';

    String badge = '';
    String iconName = '';
    Color iconColor = const Color(0xFF2979FF);
    Color badgeColor = const Color(0xFF2979FF);
    List<Map<String, dynamic>> actions = [];

    if (isMatch) {
      badge = 'DONOR FOUND! 🎉';
      badgeColor = const Color(0xFF2E7D32);
      iconName = 'water_drop';
      iconColor = const Color(0xFF2E7D32);
      actions = [
        {
          'label': 'View Donor Details',
          'color': const Color(0xFF2979FF),
          'isBorderOnly': true,
        },
        {
          'label': 'Contact Donor',
          'color': const Color(0xFF4CAF50),
        },
        {
          'label': 'Mark Read',
          'color': const Color(0xFF6B7280),
        },
      ];
    } else if (type == 'Emergency') {
      badge = 'URGENT';
      badgeColor = const Color(0xFFE53935);
      iconName = 'warning';
      iconColor = const Color(0xFFE53935);
      actions = [
        {
          'label': 'View Details',
          'color': const Color(0xFF2979FF),
          'isBorderOnly': true,
        },
        {
          'label': 'Mark Read',
          'color': const Color(0xFF6B7280),
        },
      ];
    } else if (type == 'Certificate Ready') {
      badge = 'CERTIFICATE';
      badgeColor = const Color(0xFF2E7D32);
      iconName = 'medical_services';
      iconColor = const Color(0xFF2E7D32);
      actions = [
        {
          'label': 'Download Certificate',
          'color': const Color(0xFF2979FF),
          'isBorderOnly': true,
          'fullWidth': true,
        },
      ];
    }

    return {
      'id': alert['id'],
      'type': type,
      'badge': badge,
      'badgeColor': badgeColor,
      'time': alert['createdAtFormatted'] ?? 'Just now',
      'title': alert['title'],
      'description': alert['description'],
      'iconName': iconName,
      'iconColor': iconColor,
      'isCritical': alert['isCritical'] ?? false,
      'isRead': alert['isRead'] ?? false,
      'request': alert['request'],
      'donor': alert['donor'],
      'actions': actions,
    };
  }

  Future<void> _markAsRead(String alertId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null) return;

      await http.post(
        Uri.parse('http://10.168.30.196:3000/api/alerts/mark-read'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'alertId': alertId}),
      );

      setState(() {
        final index = _alerts.indexWhere((a) => a['id'] == alertId);
        if (index != -1) {
          _alerts[index]['isRead'] = true;
          _unreadCount = _alerts.where((a) => !a['isRead']).length;
        }
      });
    } catch (e) {
      print('Error marking as read: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null) return;

      await http.post(
        Uri.parse('http://10.168.30.196:3000/api/alerts/mark-read'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({}),
      );

      setState(() {
        for (var alert in _alerts) {
          alert['isRead'] = true;
        }
        _unreadCount = 0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All alerts marked as read'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Error marking all as read: $e');
    }
  }

  void _viewDonorDetails(Map<String, dynamic> alert) {
    final donor = alert['donor'];
    if (donor != null) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.volunteer_activism_rounded,
                        color: Color(0xFF2E7D32),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Donor Information',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A2340),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildDetailRow('Name', donor['name'] ?? 'N/A'),
                _buildDetailRow('Blood Group', donor['bloodGroup'] ?? 'N/A'),
                _buildDetailRow('Phone', donor['phone'] ?? 'Not provided'),
                _buildDetailRow('Email', donor['email'] ?? 'Not provided'),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 16, color: Color(0xFF1976D2)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Please contact the donor to coordinate the donation details. Thank you for your patience!',
                          style:
                              TextStyle(fontSize: 12, color: Color(0xFF1976D2)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _contactDonor(donor);
                        },
                        icon: const Icon(Icons.phone, size: 18),
                        label: const Text('Contact'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF4CAF50)),
                          foregroundColor: const Color(0xFF4CAF50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2979FF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Close'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  void _contactDonor(Map<String, dynamic> donor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Contact Donor',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📞 Phone',
                    style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                  ),
                  Text(
                    donor['phone'] ?? 'Not available',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A2340),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '📧 Email',
                    style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                  ),
                  Text(
                    donor['email'] ?? 'Not available',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF1A2340),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Please contact the donor to coordinate:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text('• Date and time for donation'),
            const Text('• Hospital location'),
            const Text('• Any pre-donation requirements'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '💡 Tip: Be polite and thank the donor for their generosity!',
                style: TextStyle(fontSize: 12, color: Color(0xFFE65100)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (donor['phone'] != null && donor['phone'] != 'Not provided')
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Opening dialer... (Feature coming soon)'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.phone),
              label: const Text('Call Now'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
              ),
            ),
        ],
      ),
    );
  }

  void _viewRequestDetails(Map<String, dynamic> alert) {
    final request = alert['request'];
    if (request != null) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.bloodtype_rounded,
                        color: Color(0xFF2E7D32),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Request Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildDetailRow('Request Type', request['type'] ?? 'N/A'),
                if (request['bloodGroup'] != null)
                  _buildDetailRow('Blood Group', request['bloodGroup']),
                if (request['organType'] != null)
                  _buildDetailRow('Organ Type', request['organType']),
                _buildDetailRow('Hospital', request['hospitalName']),
                _buildDetailRow(
                    'Units Needed', '${request['unitsNeeded']} units'),
                _buildDetailRow('Urgency', request['urgencyLevel']),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2979FF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A2340),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIcon(String iconName) {
    switch (iconName) {
      case 'warning':
        return Icons.warning_rounded;
      case 'water_drop':
        return Icons.water_drop_rounded;
      case 'business':
        return Icons.business_rounded;
      case 'medical_services':
        return Icons.medical_services_rounded;
      default:
        return Icons.notifications_active_rounded;
    }
  }

  Color _getIconBgColor(String iconName) {
    switch (iconName) {
      case 'warning':
        return const Color(0xFFFFE0E0);
      case 'water_drop':
        return const Color(0xFFDDF6E8);
      case 'business':
        return const Color(0xFFF0F2F5);
      case 'medical_services':
        return const Color(0xFFDDF6E8);
      default:
        return const Color(0xFFF0F2F5);
    }
  }

  void _onNavTap(int index) {
    if (index == 0) {
      Navigator.pop(context);
      return;
    }
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PatientMapScreen()),
      );
      return;
    }
    if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MyRequestsScreen()),
      );
      return;
    }
    if (index == 4) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProfileScreen()),
      );
      return;
    }
    setState(() => _selectedNavIndex = index);
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
            _buildNavItem(Icons.home_rounded, 'Home', 0),
            _buildNavItem(Icons.map_outlined, 'Map', 1),
            _buildNavItemWithBadge(
                Icons.notifications_active_rounded, 'Alerts', 3, _unreadCount),
            _buildNavItem(Icons.person_outline_rounded, 'Profile', 4),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final active = _selectedNavIndex == index;
    return GestureDetector(
      onTap: () => _onNavTap(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 58,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: active ? const Color(0xFF2979FF) : const Color(0xFFB0BEC5),
              size: 24,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color:
                    active ? const Color(0xFF2979FF) : const Color(0xFFB0BEC5),
                fontSize: 10,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItemWithBadge(
      IconData icon, String label, int index, int badgeCount) {
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
                Icon(
                  icon,
                  color: active
                      ? const Color(0xFF2979FF)
                      : const Color(0xFFB0BEC5),
                  size: 24,
                ),
                if (badgeCount > 0 && !active)
                  Positioned(
                    top: -2,
                    right: -3,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      constraints:
                          const BoxConstraints(minWidth: 14, minHeight: 14),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE53935),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          badgeCount > 9 ? '9+' : '$badgeCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color:
                    active ? const Color(0xFF2979FF) : const Color(0xFFB0BEC5),
                fontSize: 10,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentAlerts = _selectedTab == 0
        ? _alerts
        : _selectedTab == 1
            ? _donationMatchAlerts
            : _readAlerts;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F8),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back Button and Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Color(0xFF1A2340),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Text(
                    'Alerts & Notifications',
                    style: TextStyle(
                      color: Color(0xFF1A2340),
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  if (_unreadCount > 0)
                    TextButton(
                      onPressed: _markAllAsRead,
                      child: const Text(
                        'Mark all read',
                        style: TextStyle(
                          color: Color(0xFF2979FF),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Get notified when donors respond to your requests.',
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
              ),
            ),

            const SizedBox(height: 6),
            const Divider(color: Color(0xFFE0E4EA), thickness: 1),
            const SizedBox(height: 14),

            // Filter tabs - Styled like MyRequestsScreen
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: List.generate(_tabs.length, (i) {
                  final tab = _tabs[i];
                  final isSelected = _selectedTab == i;
                  final count = i == 0
                      ? _alerts.length
                      : i == 1
                          ? _donationMatchAlerts.length
                          : _readAlerts.length;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedTab = i);
                        _loadAlerts();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF2979FF)
                              : const Color(0xFFE4E8F0),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          children: [
                            Text(
                              tab['label'] as String,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF6B7280),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (tab['label'] == 'Donation Match' &&
                                _donationMatchAlerts.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFF2E7D32),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${count}',
                                    style: TextStyle(
                                      color: isSelected
                                          ? const Color(0xFF2E7D32)
                                          : Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: 18),

            // Alert cards list
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : currentAlerts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.notifications_off_rounded,
                                size: 64,
                                color: const Color(0xFFB0BEC5),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No alerts to show',
                                style: TextStyle(
                                  color: Color(0xFF9E9E9E),
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _selectedTab == 0
                                    ? 'When donors respond to your requests, you\'ll see them here'
                                    : 'No ${_tabs[_selectedTab]['label']} alerts',
                                style: const TextStyle(
                                  color: Color(0xFFB0BEC5),
                                  fontSize: 12,
                                ),
                              ),
                              if (_selectedTab == 1 &&
                                  _donationMatchAlerts.isEmpty)
                                const SizedBox(height: 16),
                              if (_selectedTab == 1 &&
                                  _donationMatchAlerts.isEmpty)
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 32),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE3F2FD),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Column(
                                    children: [
                                      Icon(Icons.volunteer_activism,
                                          color: Color(0xFF1976D2), size: 32),
                                      SizedBox(height: 8),
                                      Text(
                                        'When a donor accepts your request, you\'ll get a notification here.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF1976D2)),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.only(
                            left: 16,
                            right: 16,
                            bottom: 100,
                          ),
                          children: currentAlerts
                              .map((alert) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _AlertCard(
                                      id: alert['id'],
                                      type: alert['badge'],
                                      typeColor: alert['badgeColor'],
                                      time: alert['time'],
                                      iconBg:
                                          _getIconBgColor(alert['iconName']),
                                      iconWidget: Icon(
                                        _getIcon(alert['iconName']),
                                        color: alert['iconColor'],
                                        size: 24,
                                      ),
                                      isCritical: alert['isCritical'],
                                      title: alert['title'],
                                      description: alert['description'],
                                      isUnread: !alert['isRead'],
                                      actions: (alert['actions'] as List)
                                          .map<_AlertAction>((action) =>
                                              _AlertAction(
                                                label: action['label'],
                                                color: action['color'],
                                                bgColor: action.containsKey(
                                                            'isBorderOnly') &&
                                                        action['isBorderOnly']
                                                    ? Colors.transparent
                                                    : const Color(0xFFF0F2F5),
                                                isBorderOnly:
                                                    action.containsKey(
                                                            'isBorderOnly') &&
                                                        action['isBorderOnly'],
                                                fullWidth: action.containsKey(
                                                        'fullWidth') &&
                                                    action['fullWidth'],
                                                onTap: () {
                                                  if (action['label'] ==
                                                      'View Donor Details') {
                                                    _viewDonorDetails(alert);
                                                  } else if (action['label'] ==
                                                      'Contact Donor') {
                                                    _contactDonor(
                                                        alert['donor']);
                                                  } else if (action['label'] ==
                                                      'Mark Read') {
                                                    _markAsRead(alert['id']);
                                                  } else if (action['label'] ==
                                                      'View Details') {
                                                    _viewRequestDetails(alert);
                                                  }
                                                },
                                              ))
                                          .toList(),
                                    ),
                                  ))
                              .toList(),
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MyRequestsScreen()),
        ),
        backgroundColor: const Color(0xFF2979FF),
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 26,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }
}

// Alert action model
class _AlertAction {
  final String label;
  final IconData? icon;
  final Color color, bgColor;
  final VoidCallback onTap;
  final bool isBorderOnly, isIconOnly, fullWidth;

  _AlertAction({
    required this.label,
    this.icon,
    required this.color,
    required this.bgColor,
    required this.onTap,
    this.isBorderOnly = false,
    this.isIconOnly = false,
    this.fullWidth = false,
  });
}

// Alert card widget
class _AlertCard extends StatelessWidget {
  final String id;
  final String type, time, title, description;
  final Color typeColor, iconBg;
  final Widget iconWidget;
  final bool isCritical, isUnread;
  final List<_AlertAction> actions;

  const _AlertCard({
    required this.id,
    required this.type,
    required this.typeColor,
    required this.time,
    required this.iconBg,
    required this.iconWidget,
    required this.isCritical,
    required this.title,
    required this.description,
    required this.isUnread,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isUnread ? const Color(0xFFF0F5FF) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isCritical
            ? Border.all(color: const Color(0xFFE53935), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconBg,
                    shape: BoxShape.circle,
                  ),
                  child: Center(child: iconWidget),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            type,
                            style: TextStyle(
                              color: typeColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                            ),
                          ),
                          const Spacer(),
                          if (isUnread)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFFE53935),
                                shape: BoxShape.circle,
                              ),
                            ),
                          const SizedBox(width: 6),
                          Text(
                            time,
                            style: const TextStyle(
                              color: Color(0xFF9E9E9E),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        title,
                        style: const TextStyle(
                          color: Color(0xFF1A2340),
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              description,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 13,
                height: 1.4,
              ),
            ),
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: actions.map((action) {
                  if (action.fullWidth) {
                    return SizedBox(
                      width: double.infinity,
                      child: _buildButton(action),
                    );
                  }
                  return _buildButton(action);
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildButton(_AlertAction action) {
    if (action.isIconOnly) {
      return GestureDetector(
        onTap: action.onTap,
        child: Container(
          width: 40,
          height: 38,
          decoration: BoxDecoration(
            color: action.bgColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(action.icon, color: action.color, size: 18),
        ),
      );
    }
    return GestureDetector(
      onTap: action.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: action.isBorderOnly ? Colors.transparent : action.bgColor,
          borderRadius: BorderRadius.circular(10),
          border: action.isBorderOnly
              ? Border.all(color: action.color.withOpacity(0.3), width: 1.5)
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (action.icon != null) ...[
              Icon(action.icon, color: action.color, size: 16),
              const SizedBox(width: 6),
            ],
            Text(
              action.label,
              style: TextStyle(
                color: action.color,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

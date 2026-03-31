import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lifelink_app/src/screens/patient_map_screen.dart';
import 'package:lifelink_app/src/screens/Patient_profile_screen.dart';
import 'package:lifelink_app/src/screens/patient_alerts_screen.dart';
import 'patient_create_request_screen.dart';

class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
  int _selectedIndex = 2;
  String _selectedFilter = 'all';
  bool _isLoading = true;
  String _errorMessage = '';

  final List<String> _filters = ['all', 'active', 'completed'];
  final Map<String, String> _filterLabels = {
    'all': 'All',
    'active': 'Active',
    'completed': 'Completed',
  };

  List<Map<String, dynamic>> _requests = [];
  static const String baseUrl = 'http://10.168.30.196:3000';

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null) {
        throw Exception('Not authenticated. Please login first.');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/requests/my-requests?filter=$_selectedFilter'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true && data['requests'] != null) {
          setState(() {
            _requests = List<Map<String, dynamic>>.from(data['requests']);
            _isLoading = false;
          });
        } else {
          throw Exception('Invalid response format');
        }
      } else if (response.statusCode == 401) {
        await _clearAuth();
        throw Exception('Session expired. Please login again.');
      } else {
        throw Exception('Failed to load requests: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );

        if (e.toString().contains('Not authenticated') ||
            e.toString().contains('Session expired')) {
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              Navigator.pushReplacementNamed(context, '/login');
            }
          });
        }
      }
    }
  }

  Future<void> _clearAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('user_role');
    await prefs.remove('user_name');
    await prefs.remove('user_id');
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
    if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AlertsScreen()),
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
    setState(() => _selectedIndex = index);
  }

  void _createNewRequest() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateRequestScreen()),
    );

    if (result != null && result == true) {
      _fetchRequests();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request created successfully!'),
          backgroundColor: Color(0xFF2E7D32),
        ),
      );
    }
  }

  void _onFilterChanged(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
    _fetchRequests();
  }

  // ✅ COMPLETE VIEW DETAILS POPUP
  Future<void> _viewRequestDetails(Map<String, dynamic> request) async {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with gradient background
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: _getHeaderGradientColors(request),
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(28),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                  child: Column(
                    children: [
                      // Icon with status badge
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _getIconForRequest(request),
                              size: 48,
                              color: Colors.white,
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: _getStatusColor(request),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                _getStatusIcon(request),
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        request['title'] ?? 'Request Details',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          request['badge'] ?? 'NORMAL',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Body content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Patient Name
                        _buildDetailRow(
                          icon: Icons.person_rounded,
                          label: 'Patient Name',
                          value: request['patientName'] ?? 'N/A',
                          iconColor: const Color(0xFF2979FF),
                        ),
                        const SizedBox(height: 16),
                        // Request Type
                        _buildDetailRow(
                          icon: _getTypeIcon(request),
                          label: 'Request Type',
                          value: request['type'] ?? 'N/A',
                          iconColor: _getTypeColor(request),
                        ),
                        const SizedBox(height: 16),
                        // Hospital
                        _buildDetailRow(
                          icon: Icons.local_hospital_rounded,
                          label: 'Hospital',
                          value: request['hospital'] ?? 'N/A',
                          iconColor: const Color(0xFF4CAF50),
                        ),
                        const SizedBox(height: 16),
                        // Date
                        _buildDetailRow(
                          icon: Icons.calendar_today_rounded,
                          label: 'Request Date',
                          value: request['date'] ?? 'N/A',
                          iconColor: const Color(0xFF9E9E9E),
                        ),
                        const SizedBox(height: 16),
                        // Units/Organ needed
                        _buildDetailRow(
                          icon: Icons.bloodtype_rounded,
                          label: request['title']?.contains('Blood') == true
                              ? 'Units Needed'
                              : 'Organ Type',
                          value: request['title']?.contains('Blood') == true
                              ? request['hospital']?.split('•')[1]?.trim() ??
                                  'N/A'
                              : request['title']?.replaceAll(' Request', '') ??
                                  'N/A',
                          iconColor: request['title']?.contains('Blood') == true
                              ? const Color(0xFFE53935)
                              : const Color(0xFF4CAF50),
                        ),
                        const SizedBox(height: 16),
                        // Status with color
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _getStatusBackgroundColor(request),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _getStatusIcon(request),
                                color: _getStatusColor(request),
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Current Status',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF6B7280),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      request['status'] ?? 'Unknown',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: _getStatusColor(request),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                    color: Color(0xFFE0E4EA),
                                    width: 1.5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                                child: const Text(
                                  'Close',
                                  style: TextStyle(
                                    color: Color(0xFF6B7280),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  if (request['rawStatus'] != 'Cancelled' &&
                                      request['rawStatus'] != 'Completed') {
                                    _showCancelConfirmation(request['id']);
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _canCancel(request)
                                      ? const Color(0xFFE53935)
                                      : const Color(0xFFE0E4EA),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                                child: Text(
                                  _canCancel(request)
                                      ? 'Cancel Request'
                                      : 'Completed',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 20,
            color: iconColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF9E9E9E),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A2340),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Color> _getHeaderGradientColors(Map<String, dynamic> request) {
    final urgency = request['badge']?.toUpperCase() ?? 'NORMAL';
    switch (urgency) {
      case 'CRITICAL':
        return [const Color(0xFFE53935), const Color(0xFFC62828)];
      case 'URGENT':
        return [const Color(0xFFE65100), const Color(0xFFBF360C)];
      default:
        return [const Color(0xFF2979FF), const Color(0xFF0D47A1)];
    }
  }

  IconData _getIconForRequest(Map<String, dynamic> request) {
    final type = request['type']?.toUpperCase() ?? '';
    if (type.contains('EMERGENCY')) {
      return Icons.bloodtype_rounded;
    }
    return Icons.favorite_rounded;
  }

  IconData _getTypeIcon(Map<String, dynamic> request) {
    final type = request['type']?.toUpperCase() ?? '';
    if (type.contains('EMERGENCY')) {
      return Icons.bloodtype_rounded;
    }
    return Icons.favorite_rounded;
  }

  Color _getTypeColor(Map<String, dynamic> request) {
    final type = request['type']?.toUpperCase() ?? '';
    if (type.contains('EMERGENCY')) {
      return const Color(0xFFE53935);
    }
    return const Color(0xFF4CAF50);
  }

  IconData _getStatusIcon(Map<String, dynamic> request) {
    final status = request['status']?.toLowerCase() ?? '';
    if (status.contains('found')) return Icons.check_circle_rounded;
    if (status.contains('waiting')) return Icons.hourglass_bottom_rounded;
    if (status.contains('completed')) return Icons.check_circle_rounded;
    if (status.contains('cancelled')) return Icons.cancel_rounded;
    if (status.contains('matched')) return Icons.people_rounded;
    return Icons.pending_rounded;
  }

  Color _getStatusColor(Map<String, dynamic> request) {
    final status = request['status']?.toLowerCase() ?? '';
    if (status.contains('found')) return const Color(0xFF2E7D32);
    if (status.contains('waiting')) return const Color(0xFFE65100);
    if (status.contains('completed')) return const Color(0xFF2E7D32);
    if (status.contains('cancelled')) return const Color(0xFFE53935);
    if (status.contains('matched')) return const Color(0xFF2979FF);
    return const Color(0xFF9E9E9E);
  }

  Color _getStatusBackgroundColor(Map<String, dynamic> request) {
    final status = request['status']?.toLowerCase() ?? '';
    if (status.contains('found'))
      return const Color(0xFF2E7D32).withOpacity(0.1);
    if (status.contains('waiting'))
      return const Color(0xFFE65100).withOpacity(0.1);
    if (status.contains('completed'))
      return const Color(0xFF2E7D32).withOpacity(0.1);
    if (status.contains('cancelled'))
      return const Color(0xFFE53935).withOpacity(0.1);
    if (status.contains('matched'))
      return const Color(0xFF2979FF).withOpacity(0.1);
    return const Color(0xFF9E9E9E).withOpacity(0.1);
  }

  bool _canCancel(Map<String, dynamic> request) {
    final status = request['rawStatus']?.toLowerCase() ?? '';
    return status != 'cancelled' && status != 'completed';
  }

  void _showCancelConfirmation(String requestId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Cancel Request',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to cancel this request? This action cannot be undone.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'No',
              style: TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              // Show loading indicator
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );
              await _performCancelRequest(requestId);
              if (mounted) {
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text(
              'Yes, Cancel',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _performCancelRequest(String requestId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http
          .delete(
            Uri.parse('$baseUrl/api/requests/$requestId'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: json.encode({
              'reason': 'Cancelled by user',
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Request cancelled successfully'),
              backgroundColor: Color(0xFF2E7D32),
              duration: Duration(seconds: 2),
            ),
          );
          _fetchRequests();
        }
      } else if (response.statusCode == 403) {
        throw Exception('You are not authorized to cancel this request');
      } else if (response.statusCode == 404) {
        throw Exception('Request not found');
      } else if (response.statusCode == 400) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Cannot cancel this request');
      } else {
        throw Exception('Failed to cancel request: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
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
            _navItem(Icons.home_rounded, 'Home', 0),
            _navItem(Icons.map_outlined, 'Map', 1),
            const SizedBox(width: 58),
            _navBadgeItem(Icons.notifications_outlined, 'Alerts', 3),
            _navItem(Icons.person_outline_rounded, 'Profile', 4),
          ],
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    final active = _selectedIndex == index;
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

  Widget _navBadgeItem(IconData icon, String label, int index) {
    final active = _selectedIndex == index;
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
                Positioned(
                  top: -2,
                  right: -3,
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

  Widget _buildRequestCard(Map<String, dynamic> request) {
    IconData getIcon(String iconName) {
      switch (iconName) {
        case 'emergency_rounded':
          return Icons.emergency_rounded;
        case 'shield_outlined':
          return Icons.shield_outlined;
        case 'check_circle_rounded':
          return Icons.check_circle_rounded;
        case 'hourglass_bottom_rounded':
          return Icons.hourglass_bottom_rounded;
        case 'people_rounded':
          return Icons.people_rounded;
        case 'cancel_rounded':
          return Icons.cancel_rounded;
        default:
          return Icons.assignment_rounded;
      }
    }

    Color getColor(String colorHex) {
      return Color(int.parse(colorHex.substring(1, 7), radix: 16) + 0xFF000000);
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: getColor(request['typeBg']),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  getIcon(request['typeIcon']),
                  color: getColor(request['typeColor']),
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  request['type'],
                  style: TextStyle(
                    color: getColor(request['typeColor']),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
                const Spacer(),
                Text(
                  request['date'],
                  style: const TextStyle(
                    color: Color(0xFF9E9E9E),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        request['title'],
                        style: const TextStyle(
                          color: Color(0xFF1A2340),
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: getColor(request['badgeBg']),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        request['badge'],
                        style: TextStyle(
                          color: getColor(request['badgeColor']),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.add_box_outlined,
                      color: Color(0xFF6B7280),
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        request['hospital'],
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      getIcon(request['statusIcon']),
                      color: getColor(request['statusIconColor']),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      request['status'],
                      style: TextStyle(
                        color: getColor(request['statusColor']),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: ElevatedButton(
                          onPressed: () {
                            _viewRequestDetails(request);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2979FF),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'View Details',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: OutlinedButton(
                          onPressed: () {
                            if (_canCancel(request)) {
                              _showCancelConfirmation(request['id']);
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: Color(0xFFDDE3ED),
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            _canCancel(request)
                                ? 'Cancel Request'
                                : 'Completed',
                            style: const TextStyle(
                              color: Color(0xFF1A2340),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F8),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                    'My Requests',
                    style: TextStyle(
                      color: Color(0xFF1A2340),
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _createNewRequest,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2979FF),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 18,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'New',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Track your blood and organ requests in real-time.',
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
              ),
            ),
            const SizedBox(height: 6),
            const Divider(color: Color(0xFFE0E4EA), thickness: 1),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: _filters.map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: GestureDetector(
                      onTap: () => _onFilterChanged(filter),
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
                        child: Text(
                          _filterLabels[filter]!,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF6B7280),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewRequest,
        backgroundColor: const Color(0xFF2979FF),
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 28,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Color(0xFFE53935),
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              style: const TextStyle(color: Color(0xFFE53935), fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchRequests,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 64,
              color: const Color(0xFFB0BEC5),
            ),
            const SizedBox(height: 16),
            const Text(
              'No requests found.',
              style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap the + button to create a new request',
              style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: 100,
      ),
      itemCount: _requests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) => _buildRequestCard(_requests[index]),
    );
  }
}

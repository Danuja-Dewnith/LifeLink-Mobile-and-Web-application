import 'dart:math' as Math;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lifelink_app/src/screens/patient_map_screen.dart';
import 'Patient_profile_screen.dart';
import 'my_requests_screen.dart';
import 'home_screen.dart';
import 'patient_alerts_screen.dart';

class PatientDashboardScreen extends StatefulWidget {
  const PatientDashboardScreen({super.key});

  @override
  State<PatientDashboardScreen> createState() => _PatientDashboardScreenState();
}

class _PatientDashboardScreenState extends State<PatientDashboardScreen> {
  int _selectedIndex = 0;
  bool _isLoading = true;
  bool _isSendingEmergency = false;
  Map<String, dynamic> _patientData = {};
  List<Map<String, dynamic>> _activeRequests = [];
  List<Map<String, dynamic>> _requestHistory = [];
  List<Map<String, dynamic>> _recentNotifications = [];
  List<Map<String, dynamic>> _nearbyDonors = [];
  List<Map<String, dynamic>> _recentRequests = [];
  String _errorMessage = '';

  final TextEditingController _emergencyDescriptionController =
      TextEditingController();
  final TextEditingController _unitsNeededController =
      TextEditingController(text: '1');
  String _selectedEmergencyType = 'Blood';
  String _selectedUrgencyLevel = 'Critical';
  String? _selectedBloodGroup;
  String? _selectedOrganType;

  static const String baseUrl = 'http://10.168.30.196:3000';

  final List<String> _bloodGroups = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-'
  ];
  final List<String> _organTypes = [
    'Kidney',
    'Liver',
    'Heart',
    'Lung',
    'Pancreas'
  ];
  final List<Map<String, dynamic>> _urgencyLevels = [
    {'label': 'CRITICAL', 'value': 'Critical', 'color': Colors.red},
    {'label': 'URGENT', 'value': 'Urgent', 'color': Colors.orange},
    {'label': 'NORMAL', 'value': 'Normal', 'color': Colors.green},
  ];

  @override
  void initState() {
    super.initState();
    _initializeDashboard();
  }

  Future<void> _initializeDashboard() async {
    await _loadPatientData();
    await Future.wait([
      _loadActiveRequests(),
      _loadRecentNotifications(),
      _loadNearbyDonors(),
      _loadRecentRequests(),
    ]);
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _emergencyDescriptionController.dispose();
    _unitsNeededController.dispose();
    super.dispose();
  }

  // ── Load patient profile ──────────────────────────────────────────
  Future<void> _loadPatientData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      if (token == null) throw Exception('Not authenticated');

      final response = await http.get(
        Uri.parse('$baseUrl/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _patientData = data;
          _selectedBloodGroup = data['bloodGroup'] ?? 'O+';
        });
      } else if (response.statusCode == 401) {
        await _clearAuth();
        if (mounted) Navigator.pushReplacementNamed(context, '/login');
      } else {
        throw Exception('Failed to load profile');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ── Load active requests ──────────────────────────────────────────
  Future<void> _loadActiveRequests() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      if (token == null) return;

      final response = await http.get(
        Uri.parse('$baseUrl/api/requests/my-requests?filter=active'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['requests'] != null) {
          setState(() {
            _activeRequests = List<Map<String, dynamic>>.from(data['requests']);
          });
        }
      }
    } catch (e) {
      print('Error loading active requests: $e');
    }
  }

  // ── Load recent requests ─────────────────────────────────────────
  Future<void> _loadRecentRequests() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      if (token == null) return;

      final response = await http.get(
        Uri.parse('$baseUrl/api/requests/recent?limit=3'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      print('📋 Recent Requests Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['requests'] != null) {
          final requests = List<Map<String, dynamic>>.from(data['requests']);

          print('📋 Total requests from API: ${requests.length}');

          // ── Helper: hex color string → Color ──────────────────
          Color colorFromHex(dynamic hexColor) {
            if (hexColor == null || hexColor.toString().isEmpty) {
              return const Color(0xFFDDE8FA);
            }
            final hex = hexColor.toString().replaceAll('#', '');
            if (hex.length != 6) return const Color(0xFFDDE8FA);
            return Color(int.parse(hex, radix: 16) + 0xFF000000);
          }

          // ── Helper: icon string → IconData ────────────────────
          IconData iconFromString(dynamic iconName) {
            switch (iconName?.toString()) {
              case 'Icons.check_circle_rounded':
                return Icons.check_circle_rounded;
              case 'Icons.hourglass_bottom_rounded':
                return Icons.hourglass_bottom_rounded;
              case 'Icons.people_rounded':
                return Icons.people_rounded;
              case 'Icons.cancel_rounded':
                return Icons.cancel_rounded;
              case 'Icons.info_rounded':
                return Icons.info_rounded;
              default:
                return Icons.assignment_rounded;
            }
          }

          // ── Helper: urgency badge color ────────────────────────
          Color urgencyBadgeColor(String? urgency) {
            switch (urgency) {
              case 'Critical':
                return const Color(0xFFE53935);
              case 'Urgent':
                return const Color(0xFFE65100);
              default:
                return const Color(0xFF4CAF50);
            }
          }

          // ── Helper: status badge color ─────────────────────────
          Color statusBadgeColor(String? rawStatus) {
            switch (rawStatus) {
              case 'Active':
                return const Color(0xFF2979FF);
              case 'Matched':
                return const Color(0xFF2E7D32);
              case 'Completed':
                return const Color(0xFF4CAF50);
              case 'Cancelled':
                return const Color(0xFFE53935);
              default:
                return const Color(0xFF9E9E9E);
            }
          }

          setState(() {
            // ── Store ALL requests for internal use ──────────────
            _recentRequests = requests.map((item) {
              return {
                'id': item['id'],
                'type': item['type'],
                'icon': iconFromString(item['icon']),
                'iconBg': colorFromHex(item['iconBg']),
                'iconColor': colorFromHex(item['iconColor']),
                'message': item['title'] ?? item['message'],
                'title': item['title'],
                'subtitle': item['subtitle'],
                'date': item['date'],
                'time': item['time'],
                'status': item['status'],
                'rawStatus': item['rawStatus'],
                'donorFound': item['donorFound'],
                'urgencyBadge': item['urgencyBadge'],
                'urgencyColor': colorFromHex(item['urgencyColor']),
                'urgencyBg': colorFromHex(item['urgencyBg']),
                'hospital': item['hospital'],
                'bloodGroup': item['bloodGroup'],
                'organType': item['organType'],
                'unitsNeeded': item['unitsNeeded'],
                'urgencyLevel': item['urgencyLevel'],
                'historyDetails': item['historyDetails'],
              };
            }).toList();

            // ── Active requests (Active / Pending / Matched) ──────
            _activeRequests = requests
                .where((req) =>
                    req['rawStatus'] == 'Active' ||
                    req['rawStatus'] == 'Pending' ||
                    req['rawStatus'] == 'Matched')
                .map((req) => {
                      'title': req['title'],
                      'hospital': req['hospital'],
                      'badge': req['urgencyBadge'],
                      'donorFound': req['donorFound'],
                      'date': req['date'],
                      'bloodGroup': req['bloodGroup'],
                      'organType': req['organType'],
                      'unitsNeeded': req['unitsNeeded'],
                      'urgencyLevel': req['urgencyLevel'],
                    })
                .toList();

            // ────────────────────────────────────────────────────────
            // ✅ FIX: Show ALL recent requests in history, not just
            //    Completed/Cancelled.  Active/Matched ones show their
            //    live status badge so the patient always sees something.
            // ────────────────────────────────────────────────────────
            _requestHistory = requests.map((req) {
              final String rawStatus = req['rawStatus'] ?? '';
              final String reqType = req['type'] ?? 'Blood';
              final String blood = req['bloodGroup'] ?? '';
              final String organ = req['organType'] ?? '';
              final String urgency = req['urgencyLevel'] ?? 'Normal';
              final String hospital = req['hospital'] ?? 'Unknown Hospital';
              final String date = req['date'] ?? '';
              final dynamic units = req['unitsNeeded'] ?? 1;
              final String status = req['status'] ?? rawStatus;

              // Title: "AB+ Blood Request" or "Kidney Donation Request"
              final String title = reqType == 'Blood'
                  ? '${blood.isNotEmpty ? blood : 'Blood'} Blood Request'
                  : '${organ.isNotEmpty ? organ : 'Organ'} Donation Request';

              // Rich subtitle with all key info
              final String urgencyIcon = _getUrgencyIcon(urgency);
              final String unitsLabel =
                  reqType == 'Blood' ? 'units' : 'organ(s)';
              final String subtitle =
                  '$date • $units $unitsLabel • $urgencyIcon $urgency • $status';

              return {
                'title': title,
                'subtitle': subtitle,
                'rawStatus': rawStatus,
                'statusColor': statusBadgeColor(rawStatus),
                'urgencyColor': urgencyBadgeColor(urgency),
                'details': {
                  'date': date,
                  'bloodType': blood,
                  'organType': organ,
                  'units': units,
                  'urgency': urgency,
                  'hospital': hospital,
                  'status': status,
                  'requestType': reqType,
                },
              };
            }).toList();
          });

          print('✅ Loaded ${_recentRequests.length} recent requests');
          print(
              '   Active: ${_activeRequests.length}, History shown: ${_requestHistory.length}');
        }
      } else {
        print('❌ Failed to load recent requests: ${response.statusCode}');
        print('   Body: ${response.body}');
      }
    } catch (e) {
      print('❌ Error loading recent requests: $e');
      setState(() {
        _recentRequests = [];
        _activeRequests = [];
        _requestHistory = [];
      });
    }
  }

  String _getUrgencyIcon(String urgencyLevel) {
    switch (urgencyLevel) {
      case 'Critical':
        return '🚨';
      case 'Urgent':
        return '⚠️';
      default:
        return 'ℹ️';
    }
  }

  // ── Load recent notifications ─────────────────────────────────────
  Future<void> _loadRecentNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null) {
        _useFallbackNotificationsData();
        return;
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/alerts/recent?limit=2'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      print('🔔 Alerts status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          List<Map<String, dynamic>> notifications = [];

          if (data['notifications'] != null && data['notifications'] is List) {
            notifications =
                List<Map<String, dynamic>>.from(data['notifications']);
          } else if (data['alerts'] != null && data['alerts'] is List) {
            notifications = List<Map<String, dynamic>>.from(data['alerts']);
          }

          if (notifications.isNotEmpty) {
            setState(() {
              _recentNotifications = notifications.map((notif) {
                // ── Icon ──────────────────────────────────────────
                IconData getIcon() {
                  final type = notif['type']?.toString().toLowerCase() ?? '';
                  if (type.contains('donation') || type.contains('match')) {
                    return Icons.volunteer_activism_rounded;
                  } else if (type.contains('emergency')) {
                    return Icons.warning_rounded;
                  }
                  return Icons.info_rounded;
                }

                Color getIconBg() {
                  final type = notif['type']?.toString().toLowerCase() ?? '';
                  if (type.contains('donation') || type.contains('match')) {
                    return const Color(0xFFDDF6E8);
                  } else if (type.contains('emergency')) {
                    return const Color(0xFFFFE0E0);
                  }
                  return const Color(0xFFDDE8FA);
                }

                Color getIconColor() {
                  final type = notif['type']?.toString().toLowerCase() ?? '';
                  if (type.contains('donation') || type.contains('match')) {
                    return const Color(0xFF2E7D32);
                  } else if (type.contains('emergency')) {
                    return const Color(0xFFE53935);
                  }
                  return const Color(0xFF2979FF);
                }

                // ── Message ───────────────────────────────────────
                String getMessage() {
                  if (notif['message'] != null &&
                      notif['message'].toString().isNotEmpty) {
                    return notif['message'].toString();
                  } else if (notif['title'] != null &&
                      notif['title'].toString().isNotEmpty) {
                    return notif['title'].toString();
                  } else if (notif['description'] != null &&
                      notif['description'].toString().isNotEmpty) {
                    return notif['description'].toString();
                  }
                  return 'New notification';
                }

                // ── Time (server now sends ISO strings) ───────────
                String getFormattedTime() {
                  // Accept both 'time' and 'createdAt' fields
                  final timeStr = (notif['time'] ??
                          notif['createdAt'] ??
                          notif['createdAtFormatted'] ??
                          '')
                      .toString();

                  if (timeStr.isEmpty) return 'Just now';

                  try {
                    final date = DateTime.parse(timeStr).toLocal();
                    final now = DateTime.now();
                    final diff = now.difference(date);

                    if (diff.inDays > 7) return '${diff.inDays} days ago';
                    if (diff.inDays > 0) {
                      return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
                    }
                    if (diff.inHours > 0) {
                      return '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
                    }
                    if (diff.inMinutes > 0) {
                      return '${diff.inMinutes} minute${diff.inMinutes > 1 ? 's' : ''} ago';
                    }
                    return 'Just now';
                  } catch (e) {
                    print('🔔 Date parse error for "$timeStr": $e');
                    return timeStr;
                  }
                }

                return {
                  'icon': getIcon(),
                  'iconBg': getIconBg(),
                  'iconColor': getIconColor(),
                  'message': getMessage(),
                  'time': getFormattedTime(),
                  'type': notif['type'],
                  'isRead': notif['isRead'] ?? false,
                  'id': notif['id'] ?? notif['_id'],
                };
              }).toList();
            });
            return;
          }
        }
      } else if (response.statusCode == 401) {
        await _clearAuth();
        if (mounted) Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      _useFallbackNotificationsData();
    } catch (e) {
      print('❌ Error in _loadRecentNotifications: $e');
      _useFallbackNotificationsData();
    }
  }

  void _useFallbackNotificationsData() {
    setState(() {
      _recentNotifications = [
        {
          'icon': Icons.check_circle_rounded,
          'iconBg': const Color(0xFFDDF6E8),
          'iconColor': const Color(0xFF2E7D32),
          'message': 'New donor matching your criteria found!',
          'time': '15 minutes ago',
        },
        {
          'icon': Icons.info_rounded,
          'iconBg': const Color(0xFFDDE8FA),
          'iconColor': const Color(0xFF2979FF),
          'message': 'Doctor Smith updated your surgery schedule.',
          'time': '2 hours ago',
        },
      ];
    });
  }

  // ── Load nearby donors ────────────────────────────────────────────
  Future<void> _loadNearbyDonors() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      final patientCity = _patientData['city'];
      final patientBloodGroup = _patientData['bloodGroup'];

      if (token == null || patientCity == null || patientBloodGroup == null) {
        print('Missing patient data for donor search');
        return;
      }

      final response = await http.get(
        Uri.parse(
            '$baseUrl/api/donors/nearby?city=${Uri.encodeComponent(patientCity)}&bloodGroup=${Uri.encodeComponent(patientBloodGroup)}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['donors'] != null) {
          setState(() {
            _nearbyDonors = List<Map<String, dynamic>>.from(data['donors']);
          });
        }
      }
    } catch (e) {
      print('Error loading nearby donors: $e');
      setState(() => _nearbyDonors = []);
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
    if (index == 0) return;
    if (index == 1) {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const PatientMapScreen()));
      return;
    }
    if (index == 3) {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const AlertsScreen()));
      return;
    }
    if (index == 4) {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
      return;
    }
    setState(() => _selectedIndex = index);
  }

  void _showProfileSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: const Color(0xFFDDE3ED),
                  borderRadius: BorderRadius.circular(10)),
            ),
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 30,
              backgroundColor: const Color(0xFFDDE8FA),
              child: _patientData['avatarUrl'] != null
                  ? ClipOval(
                      child: Image.network(
                        _patientData['avatarUrl'],
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                            Icons.person_rounded,
                            color: Color(0xFF2979FF),
                            size: 32),
                      ),
                    )
                  : const Icon(Icons.person_rounded,
                      color: Color(0xFF2979FF), size: 32),
            ),
            const SizedBox(height: 8),
            Text(_patientData['fullName'] ?? 'Patient',
                style: const TextStyle(
                    color: Color(0xFF1A2340),
                    fontSize: 16,
                    fontWeight: FontWeight.w800)),
            Text('Patient ID: ${_patientData['_id']?.substring(0, 8) ?? 'N/A'}',
                style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 12)),
            const SizedBox(height: 16),
            const Divider(color: Color(0xFFEEF2F7)),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const ProfileScreen()));
                },
                icon: const Icon(Icons.person_outline_rounded,
                    color: Colors.white, size: 20),
                label: const Text('View Profile',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2979FF),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await _clearAuth();
                  if (mounted) {
                    Navigator.pop(context);
                    Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const HomeScreen()),
                        (route) => false);
                  }
                },
                icon: const Icon(Icons.logout_rounded,
                    color: Color(0xFFE53935), size: 20),
                label: const Text('Logout',
                    style: TextStyle(
                        color: Color(0xFFE53935),
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFE53935), width: 1.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _openPDFViewer() {
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => const PDFViewerScreen()));
  }

  // ── Emergency dialog ──────────────────────────────────────────────
  void _showEmergencyRequestDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(20),
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            color: const Color(0xFFFFE0E0),
                            borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.warning_amber_rounded,
                            color: Color(0xFFE53935), size: 28),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text('Emergency Blood Request',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFE53935))),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        color: Colors.grey,
                      ),
                    ]),
                    const SizedBox(height: 8),
                    const Text(
                      'Please fill in the emergency request details. This will be sent to all matching donors immediately.',
                      style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                    ),
                    const SizedBox(height: 20),

                    // Request Type
                    const Text('Request Type',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Color(0xFF1A2340))),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                          color: const Color(0xFFF2F4F8),
                          borderRadius: BorderRadius.circular(12)),
                      child: Row(children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setDialogState(
                                () => _selectedEmergencyType = 'Blood'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _selectedEmergencyType == 'Blood'
                                    ? const Color(0xFF2979FF)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.water_drop_rounded,
                                        color: _selectedEmergencyType == 'Blood'
                                            ? Colors.white
                                            : const Color(0xFF6B7280),
                                        size: 18),
                                    const SizedBox(width: 6),
                                    Text('Blood',
                                        style: TextStyle(
                                          color:
                                              _selectedEmergencyType == 'Blood'
                                                  ? Colors.white
                                                  : const Color(0xFF6B7280),
                                          fontWeight: FontWeight.w600,
                                        )),
                                  ]),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setDialogState(
                                () => _selectedEmergencyType = 'Organ'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _selectedEmergencyType == 'Organ'
                                    ? const Color(0xFF2979FF)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.favorite_rounded,
                                        color: _selectedEmergencyType == 'Organ'
                                            ? Colors.white
                                            : const Color(0xFF6B7280),
                                        size: 18),
                                    const SizedBox(width: 6),
                                    Text('Organ',
                                        style: TextStyle(
                                          color:
                                              _selectedEmergencyType == 'Organ'
                                                  ? Colors.white
                                                  : const Color(0xFF6B7280),
                                          fontWeight: FontWeight.w600,
                                        )),
                                  ]),
                            ),
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 16),

                    // Blood group / organ type dropdown
                    if (_selectedEmergencyType == 'Blood') ...[
                      const Text('Blood Group Required',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Color(0xFF1A2340))),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFE0E4EA)),
                            borderRadius: BorderRadius.circular(12)),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedBloodGroup,
                            isExpanded: true,
                            icon: const Icon(Icons.arrow_drop_down),
                            items: _bloodGroups
                                .map((g) =>
                                    DropdownMenuItem(value: g, child: Text(g)))
                                .toList(),
                            onChanged: (v) =>
                                setDialogState(() => _selectedBloodGroup = v),
                          ),
                        ),
                      ),
                    ] else ...[
                      const Text('Organ Type Required',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Color(0xFF1A2340))),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFE0E4EA)),
                            borderRadius: BorderRadius.circular(12)),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedOrganType,
                            isExpanded: true,
                            hint: const Text('Select Organ Type'),
                            icon: const Icon(Icons.arrow_drop_down),
                            items: _organTypes
                                .map((o) =>
                                    DropdownMenuItem(value: o, child: Text(o)))
                                .toList(),
                            onChanged: (v) =>
                                setDialogState(() => _selectedOrganType = v),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),

                    // Units needed
                    const Text('Units Needed',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Color(0xFF1A2340))),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFE0E4EA)),
                          borderRadius: BorderRadius.circular(12)),
                      child: TextFormField(
                        controller: _unitsNeededController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Number of units',
                          suffixText: 'unit(s)',
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Urgency level
                    const Text('Urgency Level',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Color(0xFF1A2340))),
                    const SizedBox(height: 8),
                    Row(
                      children: _urgencyLevels.map((level) {
                        final isSelected =
                            _selectedUrgencyLevel == level['value'];
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setDialogState(
                                () => _selectedUrgencyLevel = level['value']),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? (level['color'] as Color).withOpacity(0.1)
                                    : Colors.transparent,
                                border: Border.all(
                                  color: isSelected
                                      ? level['color'] as Color
                                      : const Color(0xFFE0E4EA),
                                  width: isSelected ? 2 : 1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(level['label'],
                                    style: TextStyle(
                                      color: isSelected
                                          ? level['color'] as Color
                                          : const Color(0xFF6B7280),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    )),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Additional notes
                    const Text('Additional Notes (Optional)',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Color(0xFF1A2340))),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emergencyDescriptionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Any additional details...',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: Color(0xFFE0E4EA))),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: Color(0xFFE0E4EA))),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: Color(0xFF2979FF))),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Action buttons
                    Row(children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _emergencyDescriptionController.clear();
                            _unitsNeededController.text = '1';
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            side: const BorderSide(color: Color(0xFFE0E4EA)),
                          ),
                          child: const Text('Cancel',
                              style: TextStyle(
                                  color: Color(0xFF6B7280),
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isSendingEmergency
                              ? null
                              : () => _sendEmergencyRequest(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE53935),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isSendingEmergency
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.send, size: 18),
                                    SizedBox(width: 8),
                                    Text('Send Emergency Alert',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w700)),
                                  ],
                                ),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 8),

                    // Info box
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: const Color(0xFFFFF3E0),
                          borderRadius: BorderRadius.circular(12)),
                      child: const Row(children: [
                        Icon(Icons.info_outline,
                            color: Color(0xFFFF9800), size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'This alert will be sent to all matching donors in your area. Response time is critical.',
                            style: TextStyle(
                                fontSize: 11, color: Color(0xFFE65100)),
                          ),
                        ),
                      ]),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _sendEmergencyRequest(BuildContext dialogContext) async {
    if (_selectedEmergencyType == 'Blood' && _selectedBloodGroup == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please select a blood group'),
          backgroundColor: Colors.red));
      return;
    }
    if (_selectedEmergencyType == 'Organ' && _selectedOrganType == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please select an organ type'),
          backgroundColor: Colors.red));
      return;
    }

    int unitsNeeded = int.tryParse(_unitsNeededController.text) ?? 1;
    if (unitsNeeded < 1) unitsNeeded = 1;

    setState(() => _isSendingEmergency = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      if (token == null) throw Exception('Not authenticated');

      final hospitalsResponse = await http.get(
        Uri.parse('$baseUrl/api/hospitals'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (hospitalsResponse.statusCode != 200)
        throw Exception('Failed to fetch hospitals');

      final hospitalsData = json.decode(hospitalsResponse.body);
      final hospitals = hospitalsData['hospitals'] as List;
      if (hospitals.isEmpty) throw Exception('No hospitals available');

      final hospital = hospitals[0];
      final requestBody = <String, dynamic>{
        'requestType': _selectedEmergencyType,
        'unitsNeeded': unitsNeeded,
        'urgencyLevel': _selectedUrgencyLevel,
        'hospitalId': hospital['_id'],
        'additionalNotes': _emergencyDescriptionController.text.isNotEmpty
            ? '🚨 EMERGENCY: ${_emergencyDescriptionController.text}'
            : '🚨 EMERGENCY: Immediate assistance required',
      };
      if (_selectedEmergencyType == 'Blood') {
        requestBody['bloodGroup'] = _selectedBloodGroup;
      } else {
        requestBody['organType'] = _selectedOrganType;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/requests'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      setState(() => _isSendingEmergency = false);

      if (response.statusCode == 201) {
        Navigator.pop(dialogContext);
        _emergencyDescriptionController.clear();
        _unitsNeededController.text = '1';

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('🚨 Emergency Alert Sent!',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text(
                  'Matching donors have been notified. You will receive updates shortly.',
                  style: TextStyle(fontSize: 12)),
            ],
          ),
          backgroundColor: const Color(0xFF2E7D32),
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));

        _loadActiveRequests();
        _showEmergencyConfirmation();
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Failed to send emergency request');
      }
    } catch (e) {
      setState(() => _isSendingEmergency = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3)));
    }
  }

  void _showEmergencyConfirmation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                    color: Color(0xFFE8F5E9), shape: BoxShape.circle),
                child: const Icon(Icons.check_circle_rounded,
                    color: Color(0xFF2E7D32), size: 48),
              ),
              const SizedBox(height: 20),
              const Text('Emergency Alert Sent!',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A2340))),
              const SizedBox(height: 12),
              const Text(
                'Your emergency request has been sent to all matching donors in your area.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: const Color(0xFFF0F5FF),
                    borderRadius: BorderRadius.circular(12)),
                child: const Row(children: [
                  Icon(Icons.access_time_rounded,
                      color: Color(0xFF2979FF), size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Donors will contact you shortly. Check the alerts section for updates.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF2979FF)),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AlertsScreen()));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2979FF),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('View Alerts',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Stay on Dashboard',
                    style: TextStyle(color: Color(0xFF6B7280))),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Bottom nav bar ────────────────────────────────────────────────
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

  // ── BUILD ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
          backgroundColor: Color(0xFFECEFF4),
          body: Center(child: CircularProgressIndicator()));
    }

    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFECEFF4),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  size: 64, color: Color(0xFFE53935)),
              const SizedBox(height: 16),
              Text(_errorMessage,
                  style: const TextStyle(color: Color(0xFFE53935)),
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                  onPressed: _initializeDashboard, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final bloodGroup = _patientData['bloodGroup'] ?? 'O+';
    final isCritical = _activeRequests.any((r) => r['badge'] == 'CRITICAL');
    final activeRequest =
        _activeRequests.isNotEmpty ? _activeRequests.first : null;

    return Scaffold(
      backgroundColor: const Color(0xFFECEFF4),
      body: SafeArea(
        child: Column(
          children: [
            // ── App bar ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                      color: const Color(0xFFDDE8FA),
                      borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.water_drop_rounded,
                      color: Color(0xFF2979FF), size: 18),
                ),
                const SizedBox(width: 8),
                const Text('LifeLink',
                    style: TextStyle(
                        color: Color(0xFF2979FF),
                        fontSize: 20,
                        fontWeight: FontWeight.w800)),
                const Spacer(),
                IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.search,
                        color: Color(0xFF1A2340), size: 24)),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: _showProfileSheet,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                        color: const Color(0xFFDDE8FA),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: const Color(0xFF2979FF), width: 1.5)),
                    child: _patientData['avatarUrl'] != null
                        ? ClipOval(
                            child: Image.network(
                              _patientData['avatarUrl'],
                              width: 38,
                              height: 38,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                  Icons.person_rounded,
                                  color: Color(0xFF2979FF),
                                  size: 22),
                            ),
                          )
                        : const Icon(Icons.person_rounded,
                            color: Color(0xFF2979FF), size: 22),
                  ),
                ),
              ]),
            ),

            // ── Scrollable content ───────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Patient info card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2))
                        ],
                      ),
                      child: Column(children: [
                        Row(children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(28),
                            child: Container(
                              width: 56,
                              height: 56,
                              color: const Color(0xFFDDE8FA),
                              child: _patientData['avatarUrl'] != null
                                  ? Image.network(_patientData['avatarUrl'],
                                      width: 56,
                                      height: 56,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(
                                          Icons.person_rounded,
                                          color: Color(0xFF2979FF),
                                          size: 30))
                                  : const Icon(Icons.person_rounded,
                                      color: Color(0xFF2979FF), size: 30),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_patientData['fullName'] ?? 'Patient',
                                    style: const TextStyle(
                                        color: Color(0xFF1A2340),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800)),
                                Text(
                                    'Patient ID: ${_patientData['_id']?.substring(0, 8) ?? 'N/A'}',
                                    style: const TextStyle(
                                        color: Color(0xFF6B7280),
                                        fontSize: 12)),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isCritical
                                        ? const Color(0xFFFFE0E0)
                                        : const Color(0xFFE8F5E9),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    isCritical ? 'HIGH URGENCY' : 'ACTIVE',
                                    style: TextStyle(
                                      color: isCritical
                                          ? const Color(0xFFE53935)
                                          : const Color(0xFF4CAF50),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('REQUIRED',
                                  style: TextStyle(
                                      color: Color(0xFF6B7280),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5)),
                              Text(bloodGroup,
                                  style: const TextStyle(
                                      color: Color(0xFFE53935),
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                      height: 1.1)),
                              const Text('Blood',
                                  style: TextStyle(
                                      color: Color(0xFFE53935),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ]),
                        const SizedBox(height: 12),
                        const Divider(color: Color(0xFFEEF2F7), height: 1),
                        const SizedBox(height: 10),
                        Row(children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: activeRequest != null &&
                                      activeRequest['donorFound'] == true
                                  ? const Color(0xFF2E7D32)
                                  : const Color(0xFF2979FF),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            activeRequest != null
                                ? (activeRequest['donorFound'] == true
                                    ? 'Donor Found! Waiting for confirmation...'
                                    : 'Searching for Donor...')
                                : 'No active requests',
                            style: TextStyle(
                              color: activeRequest != null &&
                                      activeRequest['donorFound'] == true
                                  ? const Color(0xFF2E7D32)
                                  : const Color(0xFF2979FF),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            activeRequest != null
                                ? 'Updated ${activeRequest['date'] ?? 'today'}'
                                : 'Create a request',
                            style: const TextStyle(
                                color: Color(0xFF9E9E9E),
                                fontSize: 11,
                                fontStyle: FontStyle.italic),
                          ),
                        ]),
                      ]),
                    ),

                    const SizedBox(height: 14),

                    // Emergency button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: _showEmergencyRequestDialog,
                        icon: const Icon(Icons.warning_amber_rounded,
                            color: Colors.white, size: 22),
                        label: const Text('SEND EMERGENCY ALERT',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE53935),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Current active request card
                    const _SectionHeader(title: 'CURRENT ACTIVE REQUEST'),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: const Color(0xFF2979FF),
                          borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('ACTIVE REQUEST',
                                      style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 1)),
                                  const SizedBox(height: 4),
                                  Text(
                                    activeRequest != null
                                        ? activeRequest['title'] ??
                                            'No active request'
                                        : 'No Active Requests',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    activeRequest != null
                                        ? (activeRequest['hospital'] ??
                                            'Pending')
                                        : 'Tap + to create a new request',
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const MyRequestsScreen())),
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(10)),
                                child: const Icon(Icons.add,
                                    color: Colors.white, size: 22),
                              ),
                            ),
                          ]),
                          const SizedBox(height: 10),
                          const Row(children: [
                            Icon(Icons.location_on_outlined,
                                color: Colors.white70, size: 14),
                            SizedBox(width: 4),
                            Text('City General Hospital',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 12)),
                          ]),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            height: 42,
                            child: ElevatedButton(
                              onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const MyRequestsScreen())),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                elevation: 0,
                              ),
                              child: Text(
                                activeRequest != null
                                    ? 'View Detailed Progress'
                                    : 'Create New Request',
                                style: const TextStyle(
                                    color: Color(0xFF2979FF),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Nearby donors
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const _SectionHeader(title: 'NEARBY POTENTIAL DONORS'),
                        TextButton(
                          onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const PatientMapScreen())),
                          child: const Text('View Map',
                              style: TextStyle(
                                  color: Color(0xFF2979FF),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_nearbyDonors.isNotEmpty)
                      ..._nearbyDonors.map((donor) => Column(children: [
                            _DonorCard(
                              name: donor['name'],
                              subtitle:
                                  '${donor['bloodGroup'] ?? bloodGroup} Type • ${donor['lastDonated'] ?? 'Available'}',
                              distance: donor['distance'] ?? 'Nearby',
                              status: donor['status'] ?? 'Available',
                              statusColor: donor['status'] == 'Available Now'
                                  ? const Color(0xFF2979FF)
                                  : const Color(0xFF9E9E9E),
                            ),
                            const SizedBox(height: 10),
                          ]))
                    else
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14)),
                        child: const Center(
                          child: Text('No nearby donors found',
                              style: TextStyle(color: Color(0xFF9E9E9E))),
                        ),
                      ),

                    const SizedBox(height: 20),

                    // Instructions + Medical Reports
                    Row(children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: _openPDFViewer,
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 8)
                              ],
                            ),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('INSTRUCTIONS',
                                    style: TextStyle(
                                        color: Color(0xFF9E9E9E),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1)),
                                SizedBox(height: 10),
                                Icon(Icons.description_rounded,
                                    color: Color(0xFF2979FF), size: 28),
                                SizedBox(height: 8),
                                Text('Pre-operation fasting instructions',
                                    style: TextStyle(
                                        color: Color(0xFF1A2340),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        height: 1.3)),
                                SizedBox(height: 8),
                                _ReadMoreBadge(),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {},
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border:
                                    Border.all(color: const Color(0xFFDDE3ED))),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('MEDICAL REPORTS',
                                    style: TextStyle(
                                        color: Color(0xFF9E9E9E),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1)),
                                SizedBox(height: 24),
                                Center(
                                  child: Icon(Icons.upload_file_outlined,
                                      color: Color(0xFFB0BEC5), size: 32),
                                ),
                                SizedBox(height: 8),
                                Center(
                                  child: Text('Upload new laboratory report',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          color: Color(0xFF9E9E9E),
                                          fontSize: 12,
                                          height: 1.3)),
                                ),
                                SizedBox(height: 10),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ]),

                    const SizedBox(height: 20),

                    // Recent notifications
                    const _SectionHeader(title: 'RECENT NOTIFICATIONS'),
                    const SizedBox(height: 10),
                    if (_recentNotifications.isNotEmpty)
                      ..._recentNotifications.map((n) => Column(children: [
                            _NotificationCard(
                              icon: n['icon'],
                              iconBg: n['iconBg'],
                              iconColor: n['iconColor'],
                              message: n['message'],
                              time: n['time'],
                            ),
                            const SizedBox(height: 8),
                          ]))
                    else
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14)),
                        child: const Center(
                          child: Text('No notifications yet',
                              style: TextStyle(color: Color(0xFF9E9E9E))),
                        ),
                      ),

                    const SizedBox(height: 20),

                    // ── REQUEST HISTORY ───────────────────────────
                    const _SectionHeader(title: 'REQUEST HISTORY'),
                    const SizedBox(height: 10),

                    if (_requestHistory.isNotEmpty)
                      Container(
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 8)
                            ]),
                        child: Column(
                          children: List.generate(
                            _requestHistory.length,
                            (index) {
                              final request = _requestHistory[index];
                              final isLast =
                                  index == _requestHistory.length - 1;
                              return Column(children: [
                                _HistoryCard(
                                  title: request['title'] ?? 'Request',
                                  subtitle: request['subtitle'] ??
                                      'No details available',
                                  statusColor: request['statusColor'],
                                  rawStatus: request['rawStatus'],
                                ),
                                if (!isLast)
                                  const Divider(
                                      color: Color(0xFFEEF2F7),
                                      height: 1,
                                      indent: 16,
                                      endIndent: 16),
                              ]);
                            },
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14)),
                        child: const Center(
                          child: Text('No request history',
                              style: TextStyle(color: Color(0xFF9E9E9E))),
                        ),
                      ),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const MyRequestsScreen())),
        backgroundColor: const Color(0xFF2979FF),
        elevation: 4,
        shape: const CircleBorder(),
        child:
            const Icon(Icons.list_alt_rounded, color: Colors.white, size: 26),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }
}

// ── Small READ MORE badge (extracted to avoid const issues) ───────────────────
class _ReadMoreBadge extends StatelessWidget {
  const _ReadMoreBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF2979FF).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text('READ MORE',
          style: TextStyle(
              color: Color(0xFF2979FF),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5)),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: const TextStyle(
            color: Color(0xFF9E9E9E),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2));
  }
}

// ── Donor card ────────────────────────────────────────────────────────────────
class _DonorCard extends StatelessWidget {
  final String name, subtitle, distance, status;
  final Color statusColor;

  const _DonorCard({
    required this.name,
    required this.subtitle,
    required this.distance,
    required this.status,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)
        ],
      ),
      child: Row(children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
              color: const Color(0xFFEEF2F7),
              borderRadius: BorderRadius.circular(20)),
          child: const Icon(Icons.person_outline_rounded,
              color: Color(0xFF9E9E9E), size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name,
                style: const TextStyle(
                    color: Color(0xFF1A2340),
                    fontSize: 14,
                    fontWeight: FontWeight.w700)),
            Text(subtitle,
                style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 11)),
          ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(distance,
              style: TextStyle(
                  color: statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
          Text(status, style: TextStyle(color: statusColor, fontSize: 10)),
        ]),
      ]),
    );
  }
}

// ── Notification card ─────────────────────────────────────────────────────────
class _NotificationCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg, iconColor;
  final String message, time;

  const _NotificationCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.message,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)
        ],
      ),
      child: Row(children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message,
                  style: const TextStyle(
                      color: Color(0xFF1A2340),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.3)),
              const SizedBox(height: 2),
              Text(time,
                  style:
                      const TextStyle(color: Color(0xFF9E9E9E), fontSize: 11)),
            ],
          ),
        ),
      ]),
    );
  }
}

// ── History card ──────────────────────────────────────────────────────────────
class _HistoryCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color? statusColor;
  final String? rawStatus;

  const _HistoryCard({
    required this.title,
    required this.subtitle,
    this.statusColor,
    this.rawStatus,
  });

  @override
  Widget build(BuildContext context) {
    // Status badge color
    final Color badgeColor = statusColor ?? const Color(0xFF9E9E9E);

    // Status label
    final String statusLabel = rawStatus ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: Color(0xFF1A2340),
                      fontSize: 14,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(subtitle,
                  style:
                      const TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
              if (statusLabel.isNotEmpty) ...[
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusLabel.toUpperCase(),
                    style: TextStyle(
                        color: badgeColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5),
                  ),
                ),
              ],
            ],
          ),
        ),
        const Icon(Icons.chevron_right_rounded,
            color: Color(0xFFB0BEC5), size: 20),
      ]),
    );
  }
}

// ── PDF Viewer Screen ─────────────────────────────────────────────────────────
class PDFViewerScreen extends StatelessWidget {
  const PDFViewerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pre-Operation Instructions',
            style: TextStyle(
                color: Color(0xFF1A2340), fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A2340)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Color(0xFF2979FF)),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Share feature coming soon'),
                  duration: Duration(seconds: 2)),
            ),
          ),
        ],
      ),
      body: Container(
        color: const Color(0xFFF5F5F5),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: const Color(0xFF2979FF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.description_rounded,
                    color: Color(0xFF2979FF), size: 28),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pre-Operation and Blood Test',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A2340))),
                    Text('Fasting Instructions',
                        style:
                            TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(20)),
                child: const Text('Medical Guide',
                    style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF2E7D32),
                        fontWeight: FontWeight.w600)),
              ),
            ]),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2))
                ],
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Text(
                        'Pre-Operation and Blood Test\nFasting Instructions',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2979FF)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Divider(color: Color(0xFFE0E4EA)),
                    const SizedBox(height: 20),
                    _buildPDFSection(
                      title: '1. Pre-Operation Fasting Guidelines',
                      icon: Icons.access_time_rounded,
                      color: const Color(0xFFE53935),
                      content:
                          '• Solid foods: Stop at least 6-8 hours before surgery\n• Clear liquids: Allowed up to 2 hours before surgery\n• Alcohol: Avoid at least 24 hours before surgery\n• Smoking: Avoid at least 6-12 hours before surgery\n\n⚠️ Fasting reduces the risk of aspiration during anesthesia.',
                    ),
                    const SizedBox(height: 24),
                    _buildPDFSection(
                      title: '2. Medication Instructions Before Surgery',
                      icon: Icons.medication_rounded,
                      color: const Color(0xFF4CAF50),
                      content:
                          '• Take essential medications with a small sip of water if advised\n• Diabetes medications may need dose adjustment\n• Blood thinners may need to be stopped—only under medical advice',
                    ),
                    const SizedBox(height: 24),
                    _buildPDFSection(
                      title: '3. Fasting Instructions for Blood Tests',
                      icon: Icons.science_rounded,
                      color: const Color(0xFF2196F3),
                      content:
                          '• Fasting blood sugar: Fast 8-10 hours\n• Lipid profile: Fast 9-12 hours\n• Glucose tolerance test: Fast 8-12 hours\n\n💧 Drink water during fasting unless instructed otherwise.',
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE0E4EA))),
                      child: const Row(children: [
                        Icon(Icons.medical_information_rounded,
                            color: Color(0xFF2979FF), size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Please consult your healthcare provider for personalized instructions',
                            style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B7280),
                                fontStyle: FontStyle.italic),
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 20),
                    const Center(
                      child: Text('Last updated: March 2024',
                          style: TextStyle(
                              fontSize: 11, color: Color(0xFF9E9E9E))),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildPDFSection({
    required String title,
    required IconData icon,
    required Color color,
    required String content,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title,
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          ),
        ]),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Text(content,
              style: const TextStyle(
                  fontSize: 13, height: 1.5, color: Color(0xFF4A5568))),
        ),
      ],
    );
  }
}

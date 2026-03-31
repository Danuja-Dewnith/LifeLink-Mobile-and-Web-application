import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'map_screen.dart';
import 'profile_screen.dart';
import 'donor_dash.dart';
import 'donate_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedNavIndex = 3;

  bool _isLoading = true;
  List<Map<String, dynamic>> _allNotifications = [];
  List<Map<String, dynamic>> _emergencyNotifications = [];
  List<Map<String, dynamic>> _updateNotifications = [];
  List<Map<String, dynamic>> _hospitalRequestNotifications = [];
  int _unreadCount = 0;
  String? _donorBloodGroup;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadNotifications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
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

      print('\n========== LOADING NOTIFICATIONS ==========');

      // First, get donor profile to get blood group
      final profileResponse = await http.get(
        Uri.parse('http://10.168.30.196:3000/profile'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (profileResponse.statusCode == 200) {
        final profileData = jsonDecode(profileResponse.body);
        print('✅ Donor Profile Loaded:');
        print('  Name: ${profileData['fullName']}');
        print('  Blood Group: ${profileData['bloodGroup'] ?? 'NOT SET'}');
        print('  Role: ${profileData['role']}');
        print('  Email: ${profileData['email']}');

        setState(() {
          _donorBloodGroup = profileData['bloodGroup'];
        });
      } else {
        print('❌ Failed to load profile: ${profileResponse.statusCode}');
      }

      // Get matching requests
      print('\n🔍 Fetching matching requests...');
      final matchingResponse = await http.get(
        Uri.parse('http://10.168.30.196:3000/api/requests/matching-requests'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      List<Map<String, dynamic>> emergencyRequests = [];

      if (matchingResponse.statusCode == 200) {
        final matchData = jsonDecode(matchingResponse.body);
        print('✅ Matching Response:');
        print('  Success: ${matchData['success']}');
        print('  Count: ${matchData['count']}');
        print('  Donor Blood Group: ${matchData['donorBloodGroup'] ?? 'N/A'}');

        if (matchData['requests'] != null && matchData['requests'].isNotEmpty) {
          print('  Found ${matchData['requests'].length} matching requests:');
          for (var i = 0; i < matchData['requests'].length; i++) {
            final req = matchData['requests'][i];
            print(
                '    ${i + 1}. Patient: ${req['patientName']} - ${req['bloodGroup']} - ${req['hospitalName']}');
          }
          emergencyRequests =
              List<Map<String, dynamic>>.from(matchData['requests']);
        } else {
          print('  No matching requests found');
          print('  Message: ${matchData['message'] ?? 'No message'}');
        }
      } else {
        print(
            '❌ Failed to fetch matching requests: ${matchingResponse.statusCode}');
      }

      // Get all alerts
      print('\n🔔 Fetching alerts...');
      final alertsResponse = await http.get(
        Uri.parse('http://10.168.30.196:3000/api/alerts'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      List<Map<String, dynamic>> alerts = [];
      if (alertsResponse.statusCode == 200) {
        final alertData = jsonDecode(alertsResponse.body);
        alerts = List<Map<String, dynamic>>.from(alertData['alerts'] ?? []);
        print('✅ Alerts: ${alerts.length} found');
        print('  Unread Count: ${alertData['unreadCount']}');
        if (alerts.isNotEmpty) {
          print('  First alert: ${alerts[0]['title']}');
        }
        setState(() {
          _unreadCount = alertData['unreadCount'] ?? 0;
        });
      } else {
        print('❌ Failed to fetch alerts: ${alertsResponse.statusCode}');
      }

      // Get hospital requests (from other hospitals)
      print('\n🏥 Fetching hospital requests...');
      final hospitalRequestsResponse = await http.get(
        Uri.parse('http://10.168.30.196:3000/api/hospital-requests'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      List<Map<String, dynamic>> hospitalRequests = [];
      if (hospitalRequestsResponse.statusCode == 200) {
        final hospitalData = jsonDecode(hospitalRequestsResponse.body);
        hospitalRequests =
            List<Map<String, dynamic>>.from(hospitalData['requests'] ?? []);
        print('✅ Hospital Requests: ${hospitalRequests.length} found');
        if (hospitalRequests.isNotEmpty) {
          print(
              '  First request: ${hospitalRequests[0]['itemName']} from ${hospitalRequests[0]['hospitalName']}');
        }
      } else {
        print(
            '⚠️ Failed to fetch hospital requests: ${hospitalRequestsResponse.statusCode}');
        print('  Response: ${hospitalRequestsResponse.body}');

        // Create sample data for testing when backend is not available
        hospitalRequests = [
          {
            'id': 'sample1',
            'hospitalName': 'City General Hospital',
            'hospitalContact': '+94 112 345 678',
            'itemType': 'Blood',
            'itemName': 'O+ Blood',
            'quantity': 10,
            'fulfilledQuantity': 3,
            'urgency': 'Critical',
            'reason': 'Emergency surgery for accident victim',
            'contactPerson': 'Dr. Sarah Johnson',
            'createdAt': DateTime.now()
                .subtract(const Duration(hours: 2))
                .toIso8601String()
          },
          {
            'id': 'sample2',
            'hospitalName': 'Central Medical Center',
            'hospitalContact': '+94 112 876 543',
            'itemType': 'Medical Supplies',
            'itemName': 'Ventilator',
            'quantity': 5,
            'fulfilledQuantity': 1,
            'urgency': 'Urgent',
            'reason': 'ICU expansion - critical care needed',
            'contactPerson': 'Dr. Michael Chen',
            'createdAt': DateTime.now()
                .subtract(const Duration(hours: 5))
                .toIso8601String()
          },
          {
            'id': 'sample3',
            'hospitalName': 'St. Mary\'s Hospital',
            'hospitalContact': '+94 112 987 654',
            'itemType': 'Equipment',
            'itemName': 'Oxygen Concentrator',
            'quantity': 8,
            'fulfilledQuantity': 2,
            'urgency': 'Normal',
            'reason': 'Regular stock replenishment',
            'contactPerson': 'Dr. Emily Williams',
            'createdAt': DateTime.now()
                .subtract(const Duration(days: 1))
                .toIso8601String()
          }
        ];
      }

      // Convert matching requests to notification format
      final emergencyNotifs = emergencyRequests
          .map((req) => _formatRequestToNotification(req))
          .toList();

      // Convert alerts to notification format
      final alertNotifs =
          alerts.map((alert) => _formatAlertToNotification(alert)).toList();

      // Convert hospital requests to notification format
      final hospitalNotifs = hospitalRequests
          .map((req) => _formatHospitalRequestToNotification(req))
          .toList();

      // Combine all notifications (emergency first, then hospital requests, then alerts)
      final allNotifs = [...emergencyNotifs, ...hospitalNotifs, ...alertNotifs];

      print('\n📱 Summary:');
      print('  Emergency Notifications: ${emergencyNotifs.length}');
      print('  Hospital Request Notifications: ${hospitalNotifs.length}');
      print('  Alert Notifications: ${alertNotifs.length}');
      print('  Total Notifications: ${allNotifs.length}');
      print('==========================================\n');

      setState(() {
        _allNotifications = allNotifs;
        _emergencyNotifications = [
          ...emergencyNotifs,
          ...hospitalNotifs.where((n) =>
              n['type'] == 'hospital_request' && n['urgency'] == 'Critical')
        ];
        _updateNotifications = alertNotifs
            .where((n) =>
                n['type'] == 'update' ||
                n['type'] == 'System' ||
                n['type'] == 'Certificate Ready')
            .toList();
        _hospitalRequestNotifications = hospitalNotifs;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading notifications: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic> _formatHospitalRequestToNotification(
      Map<String, dynamic> request) {
    final urgency = request['urgency'] ?? 'Normal';
    final remainingQuantity =
        (request['quantity'] ?? 0) - (request['fulfilledQuantity'] ?? 0);

    String urgencyLabel = '';
    String urgencyColor = '';
    if (urgency == 'Critical') {
      urgencyLabel = 'CRITICAL';
      urgencyColor = '#E53935';
    } else if (urgency == 'Urgent') {
      urgencyLabel = 'URGENT';
      urgencyColor = '#FB8C00';
    } else {
      urgencyLabel = 'NORMAL';
      urgencyColor = '#1976D2';
    }

    final itemIcon = request['itemType'] == 'Blood'
        ? '🩸'
        : request['itemType'] == 'Medical Supplies'
            ? '💊'
            : '🔧';

    return {
      'id': request['id'],
      'type': 'hospital_request',
      'badge': urgencyLabel,
      'badgeColor': urgencyColor,
      'time': _formatTimeAgo(request['createdAt']),
      'title': '🏥 ${request['hospitalName']} Needs Help',
      'icon': 'hospital',
      'subtitle':
          '${itemIcon} ${request['itemName']} - ${remainingQuantity} of ${request['quantity']} units remaining',
      'primaryBtn': 'Offer Help',
      'secondaryBtn': 'Ignore',
      'primaryStyle': urgency == 'Critical' ? 'red' : 'blue',
      'secondaryStyle': 'outline_grey',
      'extraText': request['reason']?.length > 100
          ? request['reason'].substring(0, 100) + '...'
          : request['reason'],
      'tertiaryBtn': null,
      'isRead': false,
      'isCritical': urgency == 'Critical',
      'request': request,
      'hospitalRequest': true,
      'urgency': urgency,
      'remainingQuantity': remainingQuantity
    };
  }

  String _formatTimeAgo(String? dateString) {
    if (dateString == null) return 'Just now';

    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 1) return 'Just now';
      if (difference.inMinutes < 60) return '${difference.inMinutes} min ago';
      if (difference.inHours < 24) return '${difference.inHours} hours ago';
      if (difference.inDays < 7) return '${difference.inDays} days ago';
      return '${(difference.inDays / 7).floor()} weeks ago';
    } catch (e) {
      return 'Just now';
    }
  }

  Map<String, dynamic> _formatRequestToNotification(
      Map<String, dynamic> request) {
    final isBlood = request['requestType'] == 'Blood';
    final urgency = request['urgencyLevel'] ?? 'Normal';

    String subtitle = '';
    if (isBlood) {
      subtitle =
          '${request['hospitalName']} • ${request['unitsNeeded']} units needed';
    } else {
      subtitle =
          '${request['hospitalName']} • ${request['organType']} donation';
    }

    return {
      'id': request['id'],
      'type': 'emergency',
      'badge': urgency.toUpperCase(),
      'time': request['createdAtFormatted'] ?? 'Just now',
      'title': isBlood
          ? 'Emergency ${request['bloodGroup']} Blood Needed'
          : 'Emergency ${request['organType']} Donation Needed',
      'icon': 'location',
      'subtitle': subtitle,
      'primaryBtn': 'Accept',
      'secondaryBtn': 'Ignore',
      'primaryStyle': 'red',
      'secondaryStyle': 'outline_red',
      'extraText': null,
      'tertiaryBtn': null,
      'isRead': false,
      'isCritical': urgency == 'Critical',
      'request': request,
      'patientInfo': request['patient'],
    };
  }

  Map<String, dynamic> _formatAlertToNotification(Map<String, dynamic> alert) {
    final type = alert['type'];
    final isMatch = type == 'Donation Match';

    String badge = '';
    String primaryBtn = '';
    String secondaryBtn = '';
    String primaryStyle = '';
    String secondaryStyle = '';
    String? extraText;
    String? tertiaryBtn;

    if (isMatch) {
      badge = 'MATCH FOUND';
      primaryBtn = 'View Details';
      secondaryBtn = 'Mark Read';
      primaryStyle = 'blue';
      secondaryStyle = 'grey';
    } else if (type == 'Update') {
      badge = 'UPDATE';
    } else if (type == 'Certificate Ready') {
      badge = 'CERTIFICATE';
      tertiaryBtn = 'View Certificate';
    }

    return {
      'id': alert['id'],
      'type': type == 'Emergency' ? 'emergency' : 'update',
      'badge': badge,
      'time': alert['createdAtFormatted'] ?? 'Just now',
      'title': alert['title'],
      'icon': isMatch ? 'info' : null,
      'subtitle': alert['description'],
      'primaryBtn': primaryBtn,
      'secondaryBtn': secondaryBtn,
      'primaryStyle': primaryStyle,
      'secondaryStyle': secondaryStyle,
      'extraText': extraText,
      'tertiaryBtn': tertiaryBtn,
      'isRead': alert['isRead'] ?? false,
      'isCritical': alert['isCritical'] ?? false,
      'request': alert['request'],
      'donor': alert['donor'],
    };
  }

  Future<void> _markAsRead(String notificationId,
      {bool isRequest = false, bool isHospitalRequest = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null) return;

      // For hospital requests, just update local state
      if (isHospitalRequest) {
        print('📌 Marking hospital request as ignored: $notificationId');
      } else if (!isRequest) {
        // For regular alerts, call the API
        await http.post(
          Uri.parse('http://10.168.30.196:3000/api/alerts/mark-read'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: json.encode({'alertId': notificationId}),
        );
      }

      // Update local state to mark as read/ignored
      setState(() {
        // Update in all notifications list
        final index =
            _allNotifications.indexWhere((n) => n['id'] == notificationId);
        if (index != -1) {
          _allNotifications[index]['isRead'] = true;
        }

        // Update in emergency notifications if present
        final emergencyIndex = _emergencyNotifications
            .indexWhere((n) => n['id'] == notificationId);
        if (emergencyIndex != -1) {
          _emergencyNotifications[emergencyIndex]['isRead'] = true;
        }

        // Update in hospital requests list if present
        final hospitalIndex = _hospitalRequestNotifications
            .indexWhere((n) => n['id'] == notificationId);
        if (hospitalIndex != -1) {
          _hospitalRequestNotifications[hospitalIndex]['isRead'] = true;
        }

        // Update unread count
        _unreadCount =
            _allNotifications.where((n) => !(n['isRead'] ?? true)).length;
      });

      // Show a snackbar to confirm
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification marked as read'),
            duration: Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print('Error marking as read: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      if (token != null) {
        await http.post(
          Uri.parse('http://10.168.30.196:3000/api/alerts/mark-read'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: json.encode({}),
        );

        // Mark all notifications as read locally
        setState(() {
          for (var notification in _allNotifications) {
            notification['isRead'] = true;
          }
          for (var notification in _emergencyNotifications) {
            notification['isRead'] = true;
          }
          for (var notification in _updateNotifications) {
            notification['isRead'] = true;
          }
          for (var notification in _hospitalRequestNotifications) {
            notification['isRead'] = true;
          }
          _unreadCount = 0;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('All notifications marked as read'),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      print('Error marking all as read: $e');
    }
  }

  Future<void> _acceptEmergencyRequest(
      Map<String, dynamic> notification) async {
    final request = notification['request'];
    if (request == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Accept Request',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification['title'],
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Patient: ${request['patientName']}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Hospital: ${request['hospitalName']}',
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Blood Group: ${request['bloodGroup']}',
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Units Needed: ${request['unitsNeeded']}',
                    style: const TextStyle(fontSize: 13),
                  ),
                  if (request['urgencyLevel'] == 'Critical')
                    const SizedBox(height: 4),
                  if (request['urgencyLevel'] == 'Critical')
                    const Text(
                      'CRITICAL URGENCY',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'By accepting, you confirm that you are willing to donate and will be contacted by the hospital.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Accept & Donate'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      setState(() => _isLoading = true);

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null) throw Exception('Not authenticated');

      final response = await http.post(
        Uri.parse(
            'http://10.168.30.196:3000/api/requests/${request['id']}/accept-donor'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  '✓ Request accepted successfully! The patient will contact you.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
          await _loadNotifications();
        }
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to accept request');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _offerHelpForHospitalRequest(
      Map<String, dynamic> notification) async {
    final request = notification['request'];
    if (request == null) return;

    final quantityController = TextEditingController();
    final messageController = TextEditingController();
    int? offeredQuantity;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Offer Help',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification['title'],
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hospital: ${request['hospitalName']}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Contact: ${request['hospitalContact'] ?? 'Not provided'}',
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Item: ${request['itemType']} - ${request['itemName']}',
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Quantity Needed: ${request['quantity']} units',
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Remaining: ${notification['remainingQuantity']} units',
                    style:
                        const TextStyle(fontSize: 13, color: Color(0xFFE53935)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Contact Person: ${request['contactPerson']}',
                    style: const TextStyle(fontSize: 13),
                  ),
                  if (notification['urgency'] == 'Critical')
                    const SizedBox(height: 4),
                  if (notification['urgency'] == 'Critical')
                    const Text(
                      'CRITICAL URGENCY',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'How many units can you offer?',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter quantity',
                labelText: 'Quantity',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: messageController,
              maxLines: 2,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Add a message (optional)',
                labelText: 'Message',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final quantity = int.tryParse(quantityController.text);
              if (quantity != null && quantity > 0) {
                offeredQuantity = quantity;
                Navigator.pop(context, true);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid quantity'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2979FF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Send Offer'),
          ),
        ],
      ),
    );

    if (confirm != true || offeredQuantity == null) return;

    try {
      setState(() => _isLoading = true);

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null) throw Exception('Not authenticated');

      final response = await http.post(
        Uri.parse(
            'http://10.168.30.196:3000/api/hospital-requests/${request['id']}/respond'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'offeredQuantity': offeredQuantity,
          'message': messageController.text.isNotEmpty
              ? messageController.text
              : 'We can help with this request'
        }),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '✓ Offer sent! You offered $offeredQuantity units to ${request['hospitalName']}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
          await _loadNotifications();
        }
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to send offer');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _viewRequestDetails(Map<String, dynamic> notification) {
    final request = notification['request'];
    if (request != null) {
      final isHospitalRequest = notification['hospitalRequest'] == true;

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
                const Text(
                  'Request Details',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                if (isHospitalRequest) ...[
                  _buildDetailRow('Hospital', request['hospitalName']),
                  _buildDetailRow(
                      'Contact', request['hospitalContact'] ?? 'Not provided'),
                  _buildDetailRow('Item Type', request['itemType']),
                  _buildDetailRow('Item Name', request['itemName']),
                  _buildDetailRow(
                      'Quantity Needed', '${request['quantity']} units'),
                  _buildDetailRow('Fulfilled',
                      '${request['fulfilledQuantity'] ?? 0} units'),
                  _buildDetailRow('Remaining',
                      '${(request['quantity'] ?? 0) - (request['fulfilledQuantity'] ?? 0)} units'),
                  _buildDetailRow('Urgency', request['urgency']),
                  _buildDetailRow('Contact Person', request['contactPerson']),
                  if (request['reason'] != null && request['reason'].isNotEmpty)
                    _buildDetailRow('Reason', request['reason']),
                ] else ...[
                  _buildDetailRow('Patient Name', request['patientName']),
                  _buildDetailRow('Blood Group', request['bloodGroup']),
                  _buildDetailRow('Hospital', request['hospitalName']),
                  _buildDetailRow(
                      'Units Needed', '${request['unitsNeeded']} units'),
                  _buildDetailRow('Urgency', request['urgencyLevel']),
                  _buildDetailRow(
                      'Request Date', request['createdAtFormatted']),
                  if (request['additionalNotes'] != null &&
                      request['additionalNotes'].isNotEmpty)
                    _buildDetailRow(
                        'Additional Notes', request['additionalNotes']),
                ],
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

  void _onNavTap(int index) {
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
      return;
    }
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MapScreen()),
      ).then((_) => setState(() => _selectedNavIndex = 3));
      return;
    }
    if (index == 4) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProfileScreen()),
      ).then((_) => setState(() => _selectedNavIndex = 3));
      return;
    }
    setState(() => _selectedNavIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F8),
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildTabBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildNotificationList(_allNotifications),
                      _buildNotificationList(_emergencyNotifications),
                      _buildNotificationList(_updateNotifications),
                      _buildNotificationList(_hospitalRequestNotifications),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: _buildDonateFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      leading: GestureDetector(
        onTap: () => Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        ),
        child: const Icon(
          Icons.arrow_back_ios_rounded,
          color: Color(0xFF2979FF),
          size: 20,
        ),
      ),
      title: Column(
        children: [
          const Text(
            'Notifications',
            style: TextStyle(
              color: Color(0xFF1A2340),
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          if (_donorBloodGroup != null)
            Text(
              'Your Blood Group: $_donorBloodGroup',
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
      actions: [
        // Refresh button
        IconButton(
          icon: const Icon(Icons.refresh, color: Color(0xFF2979FF)),
          onPressed: _loadNotifications,
          tooltip: 'Refresh',
        ),
        if (_unreadCount > 0)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: _markAllAsRead,
              child: const Icon(
                Icons.done_all_rounded,
                color: Color(0xFF2979FF),
                size: 24,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: const Color(0xFF2979FF),
        unselectedLabelColor: const Color(0xFF9E9E9E),
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        unselectedLabelStyle:
            const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        indicatorColor: const Color(0xFF2979FF),
        indicatorWeight: 2.5,
        indicatorSize: TabBarIndicatorSize.label,
        tabs: const [
          Tab(text: 'All'),
          Tab(text: 'Emergency'),
          Tab(text: 'Updates'),
          Tab(text: 'Hospital Req'),
        ],
      ),
    );
  }

  Widget _buildNotificationList(List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off_outlined,
                color: const Color(0xFFBDBDBD), size: 56),
            const SizedBox(height: 12),
            const Text('No notifications',
                style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 14)),
            const SizedBox(height: 8),
            if (_donorBloodGroup != null)
              Text(
                'Matching requests for blood group $_donorBloodGroup will appear here',
                style: const TextStyle(color: Color(0xFFB0BEC5), fontSize: 12),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadNotifications,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2979FF),
              ),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _buildNotificationCard(items[i]),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> data) {
    final bool isEmergency = data['type'] == 'emergency';
    final bool isHospitalRequest = data['type'] == 'hospital_request';
    final bool isUnread = !(data['isRead'] ?? true);

    Color cardBg = Colors.white;
    if (isHospitalRequest && data['urgency'] == 'Critical') {
      cardBg = const Color(0xFFFFF5F5);
    } else if (isUnread) {
      cardBg = const Color(0xFFF0F5FF);
    } else if (isEmergency) {
      cardBg = const Color(0xFFFFF5F5);
    }

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: isHospitalRequest && data['urgency'] == 'Critical'
            ? Border.all(color: const Color(0xFFE53935), width: 1.5)
            : Border.all(color: const Color(0xFFF0F0F0), width: 1),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTypeBadge(data['badge'], isEmergency, isHospitalRequest,
                  data['urgency']),
              Text(
                data['time'],
                style: const TextStyle(
                    color: Color(0xFF9E9E9E),
                    fontSize: 12,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            data['title'],
            style: const TextStyle(
                color: Color(0xFF1A2340),
                fontSize: 17,
                fontWeight: FontWeight.w800,
                height: 1.2),
          ),
          if (data['subtitle'] != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  data['icon'] == 'location'
                      ? Icons.location_on_outlined
                      : data['icon'] == 'hospital'
                          ? Icons.local_hospital_outlined
                          : Icons.info_outline_rounded,
                  color: const Color(0xFF9E9E9E),
                  size: 14,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    data['subtitle'],
                    style:
                        const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                  ),
                ),
              ],
            ),
          ],
          if (data['extraText'] != null) ...[
            const SizedBox(height: 8),
            Text(
              data['extraText'],
              style: const TextStyle(
                  color: Color(0xFF6B7280), fontSize: 13, height: 1.55),
            ),
          ],
          if (data['primaryBtn'] != null && data['primaryBtn'].isNotEmpty) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _buildPrimaryButton(
                    label: data['primaryBtn'],
                    style: data['primaryStyle'],
                    onPressed: () {
                      if (data['primaryBtn'] == 'Accept') {
                        _acceptEmergencyRequest(data);
                      } else if (data['primaryBtn'] == 'Offer Help') {
                        _offerHelpForHospitalRequest(data);
                      } else if (data['primaryBtn'] == 'View Details') {
                        _viewRequestDetails(data);
                      }
                    },
                  ),
                ),
                if (data['secondaryBtn'] != null &&
                    data['secondaryBtn'].isNotEmpty) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildSecondaryButton(
                      label: data['secondaryBtn'],
                      style: data['secondaryStyle'],
                      onPressed: () {
                        // Handle ignore button
                        if (data['type'] == 'hospital_request') {
                          _markAsRead(data['id'], isHospitalRequest: true);
                        } else {
                          _markAsRead(data['id'],
                              isRequest: data['type'] == 'emergency');
                        }
                      },
                    ),
                  ),
                ],
              ],
            ),
          ],
          if (data['tertiaryBtn'] != null) ...[
            const SizedBox(height: 12),
            const Divider(color: Color(0xFFF0F0F0), height: 1),
            const SizedBox(height: 12),
            Center(
              child: GestureDetector(
                onTap: () {},
                child: Text(
                  data['tertiaryBtn'],
                  style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 14,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypeBadge(
      String label, bool isEmergency, bool isHospitalRequest, String? urgency) {
    if (label.isEmpty) return const SizedBox.shrink();

    Color bgColor;
    Color textColor;

    if (label == 'CRITICAL' || (isHospitalRequest && urgency == 'Critical')) {
      bgColor = const Color(0xFFE53935);
      textColor = Colors.white;
    } else if (label == 'URGENT' ||
        (isHospitalRequest && urgency == 'Urgent')) {
      bgColor = const Color(0xFFE65100);
      textColor = Colors.white;
    } else if (label == 'MATCH FOUND') {
      bgColor = const Color(0xFF2979FF);
      textColor = Colors.white;
    } else if (isEmergency) {
      bgColor = const Color(0xFFE53935);
      textColor = Colors.white;
    } else if (isHospitalRequest) {
      bgColor = const Color(0xFFE3EEFF);
      textColor = const Color(0xFF2979FF);
    } else {
      bgColor = const Color(0xFFE3EEFF);
      textColor = const Color(0xFF2979FF);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: textColor,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required String style,
    required VoidCallback onPressed,
  }) {
    final bool isRed = style == 'red';
    return SizedBox(
      height: 44,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isRed ? const Color(0xFFE53935) : const Color(0xFF2979FF),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0,
        ),
        child: Text(label,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14)),
      ),
    );
  }

  Widget _buildSecondaryButton({
    required String label,
    required String style,
    required VoidCallback onPressed,
  }) {
    final bool isOutlineRed = style == 'outline_red';
    final bool isGrey = style == 'grey';
    return SizedBox(
      height: 44,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(
              color: isOutlineRed
                  ? const Color(0xFFE53935)
                  : const Color(0xFFE0E0E0),
              width: 1.5),
          backgroundColor: isGrey ? const Color(0xFFF5F5F5) : Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(label,
            style: TextStyle(
                color: isOutlineRed
                    ? const Color(0xFFE53935)
                    : const Color(0xFF6B7280),
                fontWeight: FontWeight.w700,
                fontSize: 14)),
      ),
    );
  }

  Widget _buildDonateFAB() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DonateScreen()),
        );
      },
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
            child: const Icon(
              Icons.favorite_rounded,
              color: Colors.white,
              size: 28,
            ),
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
                icon: Icons.notifications_rounded,
                label: 'Alerts',
                index: 3,
                badgeCount: _unreadCount),
            _buildNavItem(
                icon: Icons.person_outline_rounded, label: 'Profile', index: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final bool active = _selectedNavIndex == index;
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

  Widget _buildNavItemWithBadge({
    required IconData icon,
    required String label,
    required int index,
    required int badgeCount,
  }) {
    final bool active = _selectedNavIndex == index;
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

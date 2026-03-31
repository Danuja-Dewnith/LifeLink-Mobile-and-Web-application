import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lifelink_app/src/screens/patient_map_screen.dart';
import 'home_screen.dart';
import 'my_requests_screen.dart';
import 'patient_alerts_screen.dart';
import 'edit_patient_profile_screen.dart';
import 'package:path/path.dart' as path;
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

// ── NEW IMPORTS ───────────────────────────────────────────────────────────────
import 'password_security_screen.dart';
import 'notification_preferences_screen.dart';
import 'privacy_settings_screen.dart';
// ─────────────────────────────────────────────────────────────────────────────

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _selectedIndex = 4;

  Map<String, dynamic>? _patientData;
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _medicalReports = [];

  // Statistics variables
  int _totalRequests = 0;
  int _activeRequests = 0;
  int _completedRequests = 0;
  bool _isLoadingStats = false;

  @override
  void initState() {
    super.initState();
    _loadPatientProfile();
  }

  Future<void> _loadPatientProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null) {
        setState(() {
          _isLoading = false;
          _error = 'Please login first';
        });
        return;
      }

      final profileResponse = await http.get(
        Uri.parse('http://10.168.30.196:3000/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (profileResponse.statusCode == 200) {
        final data = jsonDecode(profileResponse.body);

        if (data['role'] != 'Patient') {
          throw Exception('This profile is not for a patient account');
        }

        if (mounted) {
          setState(() {
            _patientData = data;
          });
        }

        await _loadMedicalReports(token, data['_id']);
        await _loadRequestStats(token);
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _error = profileResponse.statusCode == 401
                ? 'Session expired. Please login again.'
                : 'Failed to load profile (${profileResponse.body})';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Error: $e';
        });
      }
    }
  }

  Future<void> _loadMedicalReports(String token, String userId) async {
    try {
      final response = await http.get(
        Uri.parse('http://10.168.30.196:3000/api/medical-reports/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _medicalReports =
                List<Map<String, dynamic>>.from(data['medicalReports'] ?? []);
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error loading medical reports: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadRequestStats(String token) async {
    try {
      setState(() {
        _isLoadingStats = true;
      });

      final statsResponse = await http.get(
        Uri.parse('http://10.168.30.196:3000/api/requests/stats'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (statsResponse.statusCode == 200) {
        final statsData = jsonDecode(statsResponse.body);
        if (statsData['success'] == true) {
          final stats = statsData['stats'];

          if (mounted) {
            setState(() {
              _totalRequests = stats['total'] ?? 0;
              _activeRequests = stats['active'] ?? 0;
              _completedRequests = stats['completed'] ?? 0;
            });
          }
        }
      }
    } catch (e) {
      print('Error loading stats: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingStats = false;
        });
      }
    }
  }

  Future<void> _deleteMedicalReport(String reportId, String fileName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Delete Report',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete "$fileName"? This action cannot be undone.',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF6B7280)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      final userId = _patientData?['_id'];

      if (token == null || userId == null) {
        throw Exception('Not authenticated');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Deleting report...'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 1),
          ),
        );
      }

      final response = await http.delete(
        Uri.parse('http://10.168.30.196:3000/api/medical-reports/$reportId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'userId': userId}),
      );

      if (response.statusCode == 200) {
        await _loadMedicalReports(token, userId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('"$fileName" deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Failed to delete report');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadMedicalReport() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'heic'],
      );

      if (result != null && result.files.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('jwt_token');
        final userId = _patientData?['_id'];

        if (token == null || userId == null)
          throw Exception('Not authenticated');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Uploading files...'),
              backgroundColor: Colors.blue,
              duration: Duration(seconds: 2),
            ),
          );
        }

        for (var file in result.files) {
          var request = http.MultipartRequest(
            'POST',
            Uri.parse('http://10.168.30.196:3000/upload-medical-report'),
          );
          request.headers['Authorization'] = 'Bearer $token';
          request.fields['userId'] = userId;
          request.files.add(
            await http.MultipartFile.fromPath(
              'medicalReport',
              file.path!,
              filename: path.basename(file.path!),
            ),
          );
          var response = await request.send();
          if (response.statusCode != 200) {
            throw Exception('Failed to upload ${file.name}');
          }
        }

        await _loadMedicalReports(token, userId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('${result.files.length} file(s) uploaded successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openDocument(String fileUrl, String fileName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null) {
        throw Exception('Not authenticated');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Opening ${path.basename(fileName)}...'),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      Uri url;

      if (fileUrl.startsWith('http://') || fileUrl.startsWith('https://')) {
        url = Uri.parse(fileUrl);
      } else {
        url = Uri.parse('http://10.168.30.196:3000$fileUrl');
      }

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final directory = await getTemporaryDirectory();
        final file = File('${directory.path}/$fileName');

        await file.writeAsBytes(response.bodyBytes);

        final result = await OpenFile.open(file.path);

        if (result.type == ResultType.done) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Document opened successfully'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        } else {
          throw Exception('Could not open file: ${result.message}');
        }
      } else {
        throw Exception('Failed to download file: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening document: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _viewReports() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E4EA),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Medical Reports',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A2340),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Color(0xFF9E9E9E)),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(color: Color(0xFFF0F2F5)),
              Expanded(
                child: _medicalReports.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.folder_open_rounded,
                                size: 64, color: const Color(0xFFB0BEC5)),
                            const SizedBox(height: 16),
                            const Text('No reports uploaded yet',
                                style: TextStyle(
                                    color: Color(0xFF9E9E9E), fontSize: 16)),
                            const SizedBox(height: 8),
                            const Text(
                                'Tap the "UPLOAD LAB" button to add reports',
                                style: TextStyle(
                                    color: Color(0xFFB0BEC5), fontSize: 12)),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _uploadMedicalReport();
                              },
                              icon: const Icon(Icons.upload_file_rounded),
                              label: const Text('Upload Now'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2979FF),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _medicalReports.length,
                        itemBuilder: (context, index) {
                          final report = _medicalReports[index];
                          final fileName = report['fileName'] ?? 'Unknown';
                          final fileUrl = report['url'] ?? '';
                          final reportId = report['_id'] ?? index.toString();
                          final uploadedAt = report['uploadedAt'] != null
                              ? DateTime.parse(report['uploadedAt'])
                              : DateTime.now();

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border:
                                  Border.all(color: const Color(0xFFE0E4EA)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _openDocument(fileUrl, fileName),
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: _getFileColor(fileName)
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Icon(
                                          _getFileIcon(fileName),
                                          color: _getFileColor(fileName),
                                          size: 28,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(fileName,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF1A2340),
                                                ),
                                                maxLines: 1,
                                                overflow:
                                                    TextOverflow.ellipsis),
                                            const SizedBox(height: 4),
                                            Text(_formatDateString(uploadedAt),
                                                style: const TextStyle(
                                                    fontSize: 11,
                                                    color: Color(0xFF9E9E9E))),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _getFileColor(fileName)
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          _getFileExtension(fileName)
                                              .toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: _getFileColor(fileName),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline_rounded,
                                          color: Color(0xFFE53935),
                                          size: 20,
                                        ),
                                        onPressed: () => _deleteMedicalReport(
                                            reportId, fileName),
                                        tooltip: 'Delete',
                                      ),
                                      const Icon(Icons.chevron_right_rounded,
                                          color: Color(0xFFB0BEC5)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              if (_medicalReports.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _uploadMedicalReport,
                      icon: const Icon(Icons.add_rounded, size: 20),
                      label: const Text('Upload New Report'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2979FF),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateString(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  IconData _getFileIcon(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    if (ext == 'pdf') return Icons.picture_as_pdf_rounded;
    if (['jpg', 'jpeg', 'png', 'heic'].contains(ext))
      return Icons.image_rounded;
    return Icons.insert_drive_file_rounded;
  }

  Color _getFileColor(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    if (ext == 'pdf') return const Color(0xFFE53935);
    if (['jpg', 'jpeg', 'png', 'heic'].contains(ext))
      return const Color(0xFF4CAF50);
    return const Color(0xFF2979FF);
  }

  String _getFileExtension(String fileName) => fileName.split('.').last;

  String _getValue(String key, {String defaultValue = 'Not provided'}) {
    final value = _patientData?[key]?.toString();
    return (value != null && value.isNotEmpty) ? value : defaultValue;
  }

  String _formatDate(String key, {String defaultValue = 'Not provided'}) {
    final raw = _patientData?[key]?.toString();
    if (raw == null || raw.isEmpty) return defaultValue;
    try {
      final dt = DateTime.parse(raw);
      final months = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December'
      ];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    } catch (_) {
      return defaultValue;
    }
  }

  String _getFullAddress() {
    final street = _patientData?['street']?.toString() ?? '';
    final city = _patientData?['city']?.toString() ?? '';
    final zip = _patientData?['zip']?.toString() ?? '';
    final parts = [
      if (street.isNotEmpty) street,
      if (city.isNotEmpty) city,
      if (zip.isNotEmpty) zip,
    ];
    return parts.isEmpty ? 'Not provided' : parts.join(', ');
  }

  Future<void> _goToEditProfile() async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
    );
    if (mounted) _loadPatientProfile();
  }

  void _onNavTap(int index) {
    if (index == 0) {
      Navigator.pop(context);
      return;
    }
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
    setState(() => _selectedIndex = index);
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
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                )),
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
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final avatarUrl = _patientData?['avatarUrl']?.toString();
    final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F8),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back,
                        color: Color(0xFF1A2340), size: 24),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text('Patient Profile',
                          style: TextStyle(
                            color: Color(0xFF1A2340),
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          )),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {},
                    child: const Icon(Icons.settings_outlined,
                        color: Color(0xFF1A2340), size: 24),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline_rounded,
                                  color: Colors.red, size: 48),
                              const SizedBox(height: 16),
                              Text(_error!,
                                  style: const TextStyle(
                                      color: Colors.red, fontSize: 16),
                                  textAlign: TextAlign.center),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: _loadPatientProfile,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Retry'),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2979FF)),
                              ),
                            ],
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: [
                              const SizedBox(height: 8),
                              Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  CircleAvatar(
                                    radius: 52,
                                    backgroundColor: const Color(0xFF1A2340),
                                    child: ClipOval(
                                      child: hasAvatar
                                          ? Image.network(
                                              avatarUrl,
                                              width: 104,
                                              height: 104,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  const Icon(
                                                      Icons.person_rounded,
                                                      color: Colors.white,
                                                      size: 50),
                                            )
                                          : const Icon(Icons.person_rounded,
                                              color: Colors.white, size: 50),
                                    ),
                                  ),
                                  Container(
                                    width: 26,
                                    height: 26,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF2979FF),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.verified_rounded,
                                        color: Colors.white, size: 16),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Text(
                                _getValue('fullName'),
                                style: const TextStyle(
                                  color: Color(0xFF1A2340),
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.local_hospital_rounded,
                                      color: Color(0xFFE53935), size: 14),
                                  SizedBox(width: 4),
                                  Text('Patient',
                                      style: TextStyle(
                                        color: Color(0xFFE53935),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      )),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.location_on_outlined,
                                      color: Color(0xFF9E9E9E), size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    _patientData?['city'] != null &&
                                            _patientData!['city']
                                                .toString()
                                                .isNotEmpty
                                        ? '${_patientData!['city']}, Sri Lanka'
                                        : 'Sri Lanka',
                                    style: const TextStyle(
                                        color: Color(0xFF9E9E9E), fontSize: 13),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                height: 54,
                                child: ElevatedButton.icon(
                                  onPressed: _goToEditProfile,
                                  icon: const Icon(Icons.edit,
                                      color: Colors.white, size: 20),
                                  label: const Text('Edit Profile',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      )),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2979FF),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    elevation: 0,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 16, horizontal: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: _isLoadingStats
                                    ? const Padding(
                                        padding:
                                            EdgeInsets.symmetric(vertical: 12),
                                        child: Center(
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2),
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          _StatItem(
                                            label: 'REQUESTS',
                                            value: _totalRequests
                                                .toString()
                                                .padLeft(2, '0'),
                                          ),
                                          Container(
                                            width: 1,
                                            height: 40,
                                            color: const Color(0xFFEEF2F7),
                                          ),
                                          _StatItem(
                                            label: 'ACTIVE',
                                            value: _activeRequests
                                                .toString()
                                                .padLeft(2, '0'),
                                          ),
                                        ],
                                      ),
                              ),
                              const SizedBox(height: 24),
                              _InfoCard(
                                icon: Icons.person_outline_rounded,
                                iconColor: const Color(0xFF2979FF),
                                title: 'Personal Information',
                                child: Column(
                                  children: [
                                    _InfoRow(
                                        label: 'NIC Number',
                                        value: _getValue('nic')),
                                    const Divider(
                                        color: Color(0xFFF0F2F5), height: 20),
                                    _InfoRow(
                                        label: 'Age', value: _getValue('age')),
                                    const Divider(
                                        color: Color(0xFFF0F2F5), height: 20),
                                    _InfoRow(
                                        label: 'Date of Birth',
                                        value: _formatDate('dob')),
                                    const Divider(
                                        color: Color(0xFFF0F2F5), height: 20),
                                    _InfoRow(
                                        label: 'Gender',
                                        value: _getValue('gender')),
                                    const Divider(
                                        color: Color(0xFFF0F2F5), height: 20),
                                    _InfoRow(
                                        label: 'Phone',
                                        value: _getValue('phone')),
                                    const Divider(
                                        color: Color(0xFFF0F2F5), height: 20),
                                    _InfoRow(
                                        label: 'Email',
                                        value: _getValue('email')),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              _InfoCard(
                                icon: Icons.medical_services_outlined,
                                iconColor: const Color(0xFFE53935),
                                title: 'Medical Information',
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFF0F0),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'REQUIRED BLOOD GROUP',
                                                  style: TextStyle(
                                                    color: Color(0xFFE53935),
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w700,
                                                    letterSpacing: 1,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  _getValue('bloodGroup'),
                                                  style: const TextStyle(
                                                    color: Color(0xFFE53935),
                                                    fontSize: 22,
                                                    fontWeight: FontWeight.w900,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const Icon(Icons.water_drop_rounded,
                                              color: Color(0xFFE53935),
                                              size: 32),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    _InfoRow(
                                      label: 'Medical Condition',
                                      value: _getValue('donationPref'),
                                    ),
                                    const SizedBox(height: 10),
                                    const Divider(
                                        color: Color(0xFFF0F2F5), height: 1),
                                    const SizedBox(height: 10),
                                    _InfoRow(
                                      label: 'Primary Hospital',
                                      value: _getValue('hospital'),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              _InfoCard(
                                icon: Icons.location_on_outlined,
                                iconColor: const Color(0xFF2979FF),
                                title: 'Address Details',
                                child: Column(
                                  children: [
                                    _InfoRow(
                                        label: 'Street',
                                        value: _getValue('street')),
                                    const Divider(
                                        color: Color(0xFFF0F2F5), height: 20),
                                    _InfoRow(
                                        label: 'City',
                                        value: _getValue('city')),
                                    const Divider(
                                        color: Color(0xFFF0F2F5), height: 20),
                                    _InfoRow(
                                        label: 'ZIP Code',
                                        value: _getValue('zip')),
                                    const Divider(
                                        color: Color(0xFFF0F2F5), height: 20),
                                    _InfoRow(
                                        label: 'Full Address',
                                        value: _getFullAddress()),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      child: _QuickActionCard(
                                        icon: Icons.folder_shared_rounded,
                                        label: 'REPORTS',
                                        reportCount: _medicalReports.length,
                                        onTap: _viewReports,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _QuickActionCard(
                                        icon: Icons.upload_file_rounded,
                                        label: 'UPLOAD LAB',
                                        onTap: _uploadMedicalReport,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),

                              // ── SETTINGS SECTION (NOW CONNECTED) ──────────
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    _SettingsRow(
                                      icon: Icons.lock_outline_rounded,
                                      label: 'Password & Security',
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const PasswordSecurityScreen(),
                                        ),
                                      ),
                                    ),
                                    const Divider(
                                        color: Color(0xFFF0F2F5), height: 1),
                                    _SettingsRow(
                                      icon: Icons.notifications_outlined,
                                      label: 'Notification Preferences',
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const NotificationPreferencesScreen(),
                                        ),
                                      ),
                                    ),
                                    const Divider(
                                        color: Color(0xFFF0F2F5), height: 1),
                                    _SettingsRow(
                                      icon: Icons.shield_outlined,
                                      label: 'Privacy Settings',
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const PrivacySettingsScreen(),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // ─────────────────────────────────────────────

                              const SizedBox(height: 24),
                              GestureDetector(
                                onTap: () => Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const HomeScreen()),
                                  (route) => false,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.logout_rounded,
                                        color: Color(0xFFE53935), size: 20),
                                    SizedBox(width: 8),
                                    Text('Logout',
                                        style: TextStyle(
                                          color: Color(0xFFE53935),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        )),
                                  ],
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
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MyRequestsScreen()),
        ),
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

// ── Reusable widgets ──────────────────────────────────────────────────────────

class _StatItem extends StatelessWidget {
  final String label, value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(label,
              style: const TextStyle(
                color: Color(0xFF9E9E9E),
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              )),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                color: Color(0xFF2979FF),
                fontSize: 22,
                fontWeight: FontWeight.w900,
              )),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget child;

  const _InfoCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                    color: Color(0xFF1A2340),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  )),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 13)),
        const SizedBox(width: 12),
        Flexible(
          child: Text(value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: Color(0xFF1A2340),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              )),
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int? reportCount;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
    this.reportCount,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 96),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10),
          ],
        ),
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: const Color(0xFF2979FF), size: 30),
                    const SizedBox(height: 8),
                    Text(
                      label,
                      style: const TextStyle(
                        color: Color(0xFF1A2340),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (reportCount != null && reportCount! > 0)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53935),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$reportCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SettingsRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: const Color(0xFF6B7280), size: 22),
      title: Text(label,
          style: const TextStyle(
            color: Color(0xFF1A2340),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          )),
      trailing: const Icon(Icons.chevron_right_rounded,
          color: Color(0xFFB0BEC5), size: 20),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }
}

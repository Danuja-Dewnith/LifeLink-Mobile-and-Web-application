import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CreateRequestScreen extends StatefulWidget {
  const CreateRequestScreen({super.key});

  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  // Form fields
  String _requestType = 'Blood';
  String? _selectedBloodGroup;
  String? _selectedOrganType;
  int _unitsNeeded = 1;
  String _urgencyLevel = 'Normal';
  String? _selectedHospitalId;
  String? _selectedHospitalName;
  final TextEditingController _notesController = TextEditingController();
  bool _isConfirmed = false;
  bool _isLoading = false;
  bool _isLoadingHospitals = true;
  String _errorMessage = '';

  // Lists
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

  List<Map<String, dynamic>> _hospitals = [];

  final Map<String, Color> _urgencyColors = {
    'Normal': const Color(0xFF4CAF50),
    'Urgent': const Color(0xFFFF9800),
    'Critical': const Color(0xFFE53935),
  };

  static const String baseUrl = 'http://10.168.30.196:3000';

  @override
  void initState() {
    super.initState();
    _fetchHospitals();
  }

  Future<void> _fetchHospitals() async {
    setState(() {
      _isLoadingHospitals = true;
      _errorMessage = '';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token'); // ← Using jwt_token

      print('=== FETCHING HOSPITALS ===');
      print(
          'Token from SharedPreferences: ${token != null ? 'Present' : 'NULL'}');

      if (token == null) {
        throw Exception('Not authenticated. Please login first.');
      }

      print(
          'Token preview: ${token.substring(0, token.length > 20 ? 20 : token.length)}...');
      print('URL: $baseUrl/api/hospitals');

      final response = await http.get(
        Uri.parse('$baseUrl/api/hospitals'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true && data['hospitals'] != null) {
          final hospitalList =
              List<Map<String, dynamic>>.from(data['hospitals']);

          setState(() {
            _hospitals = hospitalList;
            _isLoadingHospitals = false;
          });

          print('✅ Loaded ${_hospitals.length} hospitals');

          if (_hospitals.isEmpty) {
            setState(() {
              _errorMessage = 'No hospitals found in database.';
            });
          }
        } else {
          throw Exception('Invalid response format: ${data.toString()}');
        }
      } else if (response.statusCode == 401) {
        print('🔒 Token invalid - clearing auth');
        await _clearAuth();
        throw Exception('Session expired. Please login again.');
      } else {
        throw Exception(
            'Server error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      setState(() {
        _isLoadingHospitals = false;
        _errorMessage = e.toString();
      });
      print('❌ Error fetching hospitals: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
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

  bool _isFormValid() {
    if (_requestType == 'Blood' && _selectedBloodGroup == null) return false;
    if (_requestType == 'Organ' && _selectedOrganType == null) return false;
    if (_selectedHospitalId == null) return false;
    if (!_isConfirmed) return false;
    return true;
  }

  Future<void> _submitRequest() async {
    if (!_isFormValid()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token'); // ← Using jwt_token

      if (token == null) {
        throw Exception('Not authenticated. Please login again.');
      }

      final requestData = {
        'requestType': _requestType,
        'bloodGroup': _requestType == 'Blood' ? _selectedBloodGroup : null,
        'organType': _requestType == 'Organ' ? _selectedOrganType : null,
        'unitsNeeded': _unitsNeeded,
        'urgencyLevel': _urgencyLevel,
        'hospitalId': _selectedHospitalId,
        'additionalNotes': _notesController.text,
      };

      print('=== SUBMITTING REQUEST ===');
      print('Request data: $requestData');

      final response = await http
          .post(
            Uri.parse('$baseUrl/api/requests'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: json.encode(requestData),
          )
          .timeout(const Duration(seconds: 10));

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      setState(() => _isLoading = false);

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(data['message'] ?? 'Request submitted successfully!'),
              backgroundColor: const Color(0xFF2E7D32),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else if (response.statusCode == 401) {
        await _clearAuth();
        throw Exception('Session expired. Please login again.');
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Failed to submit request');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print('❌ Error: $e');

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A2340)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'New Request',
          style: TextStyle(
            color: Color(0xFF1A2340),
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF2979FF)),
            onPressed: _fetchHospitals,
            tooltip: 'Refresh hospitals',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: const Color(0xFFE0E4EA),
          ),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Submit a critical life-link request',
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Request Type Section
                  _buildSectionTitle('REQUEST TYPE'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildRequestTypeCard('Blood', Icons.water_drop),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildRequestTypeCard('Organ', Icons.favorite),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Requirement Details
                  _buildSectionTitle('REQUIREMENT DETAILS'),
                  const SizedBox(height: 12),

                  if (_requestType == 'Blood') ...[
                    _buildDropdown(
                      hint: 'Select Blood Group',
                      value: _selectedBloodGroup,
                      items: _bloodGroups,
                      onChanged: (value) {
                        setState(() {
                          _selectedBloodGroup = value;
                        });
                      },
                    ),
                  ] else ...[
                    _buildDropdown(
                      hint: 'Select Organ Type',
                      value: _selectedOrganType,
                      items: _organTypes,
                      onChanged: (value) {
                        setState(() {
                          _selectedOrganType = value;
                        });
                      },
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Units Needed
                  _buildUnitsSelector(),
                  const SizedBox(height: 24),

                  // Urgency Level
                  _buildSectionTitle('URGENCY LEVEL'),
                  const SizedBox(height: 12),
                  _buildUrgencySelector(),
                  const SizedBox(height: 12),
                  _buildUrgencyInfo(),
                  const SizedBox(height: 24),

                  // Target Hospital
                  _buildSectionTitle('TARGET HOSPITAL'),
                  const SizedBox(height: 12),
                  _buildHospitalDropdown(),
                  const SizedBox(height: 24),

                  // Additional Notes
                  _buildSectionTitle('ADDITIONAL NOTES'),
                  const SizedBox(height: 12),
                  _buildNotesField(),
                  const SizedBox(height: 24),

                  // Confirmation Checkbox
                  _buildConfirmationCheckbox(),
                  const SizedBox(height: 32),

                  // Submit Button
                  _buildSubmitButton(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFF6B7280),
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildRequestTypeCard(String type, IconData icon) {
    final isSelected = _requestType == type;
    return GestureDetector(
      onTap: () => setState(() => _requestType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2979FF) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isSelected ? const Color(0xFF2979FF) : const Color(0xFFE0E4EA),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : const Color(0xFF6B7280),
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              type,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF1A2340),
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String hint,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E4EA)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(
            hint,
            style: const TextStyle(color: Color(0xFF9E9E9E)),
          ),
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF2979FF)),
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(
                item,
                style: const TextStyle(
                  color: Color(0xFF1A2340),
                  fontSize: 16,
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildUnitsSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E4EA)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'UNITS NEEDED',
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove, color: Color(0xFF2979FF)),
                onPressed: () {
                  if (_unitsNeeded > 1) {
                    setState(() => _unitsNeeded--);
                  }
                },
              ),
              Container(
                width: 40,
                alignment: Alignment.center,
                child: Text(
                  '$_unitsNeeded',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A2340),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add, color: Color(0xFF2979FF)),
                onPressed: () {
                  setState(() => _unitsNeeded++);
                },
              ),
              const Text(
                '+',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A2340),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUrgencySelector() {
    final levels = ['Normal', 'Urgent', 'Critical'];
    return Row(
      children: levels.map((level) {
        final isSelected = _urgencyLevel == level;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _urgencyLevel = level),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? _urgencyColors[level]?.withOpacity(0.1)
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? _urgencyColors[level]!
                      : const Color(0xFFE0E4EA),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  level,
                  style: TextStyle(
                    color: isSelected
                        ? _urgencyColors[level]
                        : const Color(0xFF6B7280),
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildUrgencyInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFFE65100), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${_urgencyLevel} requests are processed within ${_getUrgencyTime(_urgencyLevel)} delivery windows.',
              style: const TextStyle(
                color: Color(0xFFE65100),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHospitalDropdown() {
    if (_isLoadingHospitals) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE0E4EA)),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text(
              'Loading hospitals...',
              style: TextStyle(color: Color(0xFF9E9E9E)),
            ),
          ],
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE0E4EA)),
        ),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 40),
            const SizedBox(height: 12),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFE53935),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _fetchHospitals,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2979FF),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_hospitals.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE0E4EA)),
        ),
        child: const Column(
          children: [
            Icon(Icons.business_outlined, color: Color(0xFF9E9E9E), size: 40),
            SizedBox(height: 12),
            Text(
              'No hospitals available',
              style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
            ),
            Text(
              'Please contact administrator',
              style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 12),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E4EA)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedHospitalId,
          hint: const Text(
            'Select a hospital...',
            style: TextStyle(color: Color(0xFF9E9E9E)),
          ),
          isExpanded: true,
          icon: const Icon(Icons.search, color: Color(0xFF2979FF)),
          items: _hospitals
              .map((hospital) {
                final hospitalId = hospital['_id']?.toString();
                final hospitalName =
                    hospital['name']?.toString() ?? 'Unknown Hospital';

                if (hospitalId == null) {
                  return null;
                }

                return DropdownMenuItem(
                  value: hospitalId,
                  child: Text(
                    hospitalName,
                    style: const TextStyle(
                      color: Color(0xFF1A2340),
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              })
              .whereType<DropdownMenuItem<String>>()
              .toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedHospitalId = value;
                final hospital = _hospitals.firstWhere(
                  (h) => h['_id']?.toString() == value,
                  orElse: () => {},
                );
                _selectedHospitalName = hospital['name']?.toString();
                print('✅ Selected hospital: $_selectedHospitalName');
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildNotesField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E4EA)),
      ),
      child: TextField(
        controller: _notesController,
        maxLines: 3,
        decoration: const InputDecoration(
          hintText: 'Special handling instructions, wing number, etc...',
          hintStyle: TextStyle(color: Color(0xFF9E9E9E), fontSize: 13),
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildConfirmationCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: _isConfirmed,
          onChanged: (value) {
            setState(() {
              _isConfirmed = value ?? false;
            });
          },
          activeColor: const Color(0xFF2979FF),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        const Expanded(
          child: Text(
            'I confirm this is an accurate medical request and I have the authority to initiate this LifeLink protocol.',
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isFormValid() && !_isLoading ? _submitRequest : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2979FF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          disabledBackgroundColor: const Color(0xFFB0BEC5),
        ),
        child: const Text(
          'Submit Request',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  String _getUrgencyTime(String urgency) {
    switch (urgency) {
      case 'Normal':
        return 'standard 24-hour';
      case 'Urgent':
        return '12-hour';
      case 'Critical':
        return 'immediate 4-hour';
      default:
        return 'standard 24-hour';
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }
}

int min(int a, int b) => a < b ? a : b;

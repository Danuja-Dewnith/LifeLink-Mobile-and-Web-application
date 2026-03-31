import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';

class DonorPatientRegisterScreen extends StatefulWidget {
  const DonorPatientRegisterScreen({super.key});

  @override
  State<DonorPatientRegisterScreen> createState() =>
      _DonorPatientRegisterScreenState();
}

class _DonorPatientRegisterScreenState
    extends State<DonorPatientRegisterScreen> {
  final _fullNameController = TextEditingController();
  final _nicController = TextEditingController();
  final _ageController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _donationPrefController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _selectedGender = 'Male';
  String _selectedBloodGroup = '';
  String _selectedCity = '';
  String _selectedRole = 'Donor';
  bool _confirmed = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  bool _isUploading = false;

  // File upload variables
  List<File> _selectedFiles = [];
  List<String> _uploadedFileUrls = [];
  String? _userId;

  final List<String> _genders = ['Male', 'Female', 'Other'];
  final List<String> _bloodGroups = [
    'A+',
    'A-',
    'B+',
    'B-',
    'O+',
    'O-',
    'AB+',
    'AB-',
  ];
  final List<String> _cities = [
    'Colombo',
    'Kandy',
    'Galle',
    'Negombo',
    'Jaffna',
    'Other',
  ];

  @override
  void dispose() {
    _fullNameController.dispose();
    _nicController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _donationPrefController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // File picker method
  Future<void> _pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'heic'],
      );

      if (result != null) {
        setState(() {
          _selectedFiles = result.paths.map((path) => File(path!)).toList();
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${_selectedFiles.length} file(s) selected'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking files: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Upload files to server
  Future<bool> _uploadFiles() async {
    if (_selectedFiles.isEmpty) return true;

    setState(() => _isUploading = true);

    try {
      for (var file in _selectedFiles) {
        var request = http.MultipartRequest(
          'POST',
          Uri.parse('http://10.168.30.196:3000/upload-medical-report'),
        );

        request.files.add(
          await http.MultipartFile.fromPath(
            'medicalReport',
            file.path,
            filename: path.basename(file.path),
          ),
        );

        if (_userId != null) {
          request.fields['userId'] = _userId!;
        }

        print('Uploading file: ${path.basename(file.path)}');

        var response = await request.send();

        if (response.statusCode != 200) {
          var responseData = await response.stream.bytesToString();
          print('Upload failed: $responseData');
          throw Exception('Failed to upload ${path.basename(file.path)}');
        }

        var responseData = await response.stream.bytesToString();
        var jsonResponse = json.decode(responseData);

        if (jsonResponse['success'] == true) {
          setState(() {
            _uploadedFileUrls.add(jsonResponse['fileUrl']);
          });
          print('Uploaded: ${jsonResponse['fileUrl']}');
        }
      }

      return true;
    } catch (e) {
      print('Error uploading files: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading files: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    } finally {
      setState(() => _isUploading = false);
    }
  }

  // Remove selected file
  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  // Validation helpers
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool _isValidPhone(String phone) {
    final clean = phone.replaceAll(RegExp(r'[\s\-]'), '');
    return RegExp(r'^(?:0|94|\+94)?[0-9]{9,10}$').hasMatch(clean);
  }

  bool _isValidNIC(String nic) {
    return RegExp(r'^[0-9]{9}[VvXx]$|^[0-9]{12}$').hasMatch(nic);
  }

  bool _isValidAge(String age) {
    if (age.isEmpty) return false;
    final num = int.tryParse(age);
    return num != null && num >= 18 && num <= 100;
  }

  bool _validateForm() {
    final fullName = _fullNameController.text.trim();
    final nic = _nicController.text.trim();
    final age = _ageController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (fullName.isEmpty) {
      _showError('Full name is required');
      return false;
    }

    if (!_isValidNIC(nic)) {
      _showError('Enter a valid NIC (e.g. 123456789V or 200012345678)');
      return false;
    }

    if (!_isValidAge(age)) {
      _showError('Age must be between 18 and 100');
      return false;
    }

    if (!_isValidPhone(phone)) {
      _showError(
          'Enter a valid phone number (e.g. +94771234567 or 0771234567)');
      return false;
    }

    if (!_isValidEmail(email)) {
      _showError('Enter a valid email address');
      return false;
    }

    if (_selectedBloodGroup.isEmpty) {
      _showError('Please select blood group');
      return false;
    }

    if (_selectedCity.isEmpty) {
      _showError('Please select city');
      return false;
    }

    if (password.isEmpty || password.length < 8) {
      _showError('Password must be at least 8 characters');
      return false;
    }

    if (password != confirm) {
      _showError('Passwords do not match');
      return false;
    }

    if (!_confirmed) {
      _showError('Please accept the terms and conditions');
      return false;
    }

    return true;
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _submitUserRegistration() async {
    if (!_validateForm()) return;

    setState(() => _isLoading = true);

    final data = {
      'fullName': _fullNameController.text.trim(),
      'nic': _nicController.text.trim(),
      'age': _ageController.text.trim(),
      'gender': _selectedGender,
      'phone': _phoneController.text.trim(),
      'email': _emailController.text.trim(),
      'role': _selectedRole,
      'bloodGroup': _selectedBloodGroup,
      'donationPref': _donationPrefController.text.trim(),
      'city': _selectedCity,
      'password': _passwordController.text,
    };

    try {
      final response = await http.post(
        Uri.parse('http://10.168.30.196:3000/register-user'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (!mounted) return;

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        _userId = responseData['userId'];

        print('User registered with ID: $_userId');

        // Wait a moment for the user to be fully saved in DB
        await Future.delayed(const Duration(milliseconds: 500));

        // If files are selected, upload them
        if (_selectedFiles.isNotEmpty && _userId != null) {
          print('Uploading ${_selectedFiles.length} files...');
          final uploadSuccess = await _uploadFiles();
          if (!uploadSuccess) {
            _showError('User registered but some files failed to upload');
          } else {
            print('All files uploaded successfully');
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ $_selectedRole registered successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration failed: ${response.body}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connection error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECEFF4),
      body: SafeArea(
        child: Column(
          children: [
            // App bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Color(0xFF1A2340),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'LifeLink',
                    style: TextStyle(
                      color: Color(0xFF1A2340),
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Page heading
                    const Text(
                      'Register as Donor /\nPatient',
                      style: TextStyle(
                        color: Color(0xFF1A2340),
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Join and save lives or request support',
                      style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                    ),

                    const SizedBox(height: 16),

                    // Hero image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        height: 160,
                        width: double.infinity,
                        color: const Color(0xFFDDE8FA),
                        child: Image.network(
                          'https://images.unsplash.com/photo-1527613426441-4da17471b66d?w=600&q=80',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.people_alt_rounded,
                            color: Color(0xFF2979FF),
                            size: 60,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Personal Info
                    _SectionCard(
                      icon: Icons.person_outline_rounded,
                      iconColor: const Color(0xFF2979FF),
                      title: 'Personal Info',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _FieldLabel('Full Name *'),
                          _InputField(
                            controller: _fullNameController,
                            hint: 'Enter full name',
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _FieldLabel('NIC Number *'),
                                    _InputField(
                                      controller: _nicController,
                                      hint: '123456789V or 200012345678',
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _FieldLabel('Age *'),
                                    _InputField(
                                      controller: _ageController,
                                      hint: '18–100',
                                      keyboardType: TextInputType.number,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _FieldLabel('Gender *'),
                          _DropdownField(
                            value: _selectedGender,
                            items: _genders,
                            onChanged: (v) =>
                                setState(() => _selectedGender = v!),
                          ),
                          const SizedBox(height: 12),
                          _FieldLabel('Phone Number *'),
                          _InputField(
                            controller: _phoneController,
                            hint: '+94 77 123 4567',
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 12),
                          _FieldLabel('Email *'),
                          _InputField(
                            controller: _emailController,
                            hint: 'example@gmail.com',
                            keyboardType: TextInputType.emailAddress,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Your Role
                    _SectionCard(
                      icon: Icons.group_outlined,
                      iconColor: const Color(0xFF2979FF),
                      title: 'Your Role *',
                      child: Row(
                        children: ['Donor', 'Patient'].map((role) {
                          final isSelected = _selectedRole == role;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedRole = role),
                              child: Container(
                                margin: EdgeInsets.only(
                                  right: role == 'Donor' ? 8 : 0,
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF2979FF)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF2979FF)
                                        : const Color(0xFFDDE3ED),
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    role,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : const Color(0xFF6B7280),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Medical Details
                    _SectionCard(
                      icon: Icons.medical_services_outlined,
                      iconColor: const Color(0xFFE53935),
                      title: 'Medical Details',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _FieldLabel('Blood Group *'),
                          _DropdownField(
                            value: _selectedBloodGroup.isEmpty
                                ? null
                                : _selectedBloodGroup,
                            hint: 'Select blood group',
                            items: _bloodGroups,
                            onChanged: (v) =>
                                setState(() => _selectedBloodGroup = v!),
                          ),
                          const SizedBox(height: 12),
                          _FieldLabel('Donation Preference / Request'),
                          _InputField(
                            controller: _donationPrefController,
                            hint: 'e.g. Kidney, Plasma, Blood',
                          ),
                          const SizedBox(height: 12),
                          _FieldLabel('Location (City) *'),
                          _DropdownField(
                            value: _selectedCity.isEmpty ? null : _selectedCity,
                            hint: 'Select City',
                            items: _cities,
                            onChanged: (v) =>
                                setState(() => _selectedCity = v!),
                            prefixIcon: Icons.location_on_outlined,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Account Access
                    _SectionCard(
                      icon: Icons.lock_outline_rounded,
                      iconColor: const Color(0xFF2979FF),
                      title: 'Account Access',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _FieldLabel('Password * (min 8 characters)'),
                          _PasswordField(
                            controller: _passwordController,
                            obscure: _obscurePassword,
                            onToggle: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                          const SizedBox(height: 12),
                          _FieldLabel('Confirm Password *'),
                          _PasswordField(
                            controller: _confirmPasswordController,
                            obscure: _obscureConfirm,
                            onToggle: () => setState(
                                () => _obscureConfirm = !_obscureConfirm),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Medical Reports
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFDDE3ED)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                            child: Row(
                              children: const [
                                Icon(Icons.upload_file_rounded,
                                    color: Color(0xFF2979FF), size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Medical Reports (Optional)',
                                  style: TextStyle(
                                    color: Color(0xFF1A2340),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // File picker button
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: GestureDetector(
                              onTap: _pickFiles,
                              child: Container(
                                width: double.infinity,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 28),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF4F8FF),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: const Color(0xFFB0C4DE)),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      _selectedFiles.isEmpty
                                          ? Icons.cloud_upload_rounded
                                          : Icons.check_circle_rounded,
                                      color: _selectedFiles.isEmpty
                                          ? const Color(0xFF2979FF)
                                          : const Color(0xFF2E7D32),
                                      size: 36,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _selectedFiles.isEmpty
                                          ? 'Click to upload files'
                                          : '${_selectedFiles.length} file(s) selected',
                                      style: TextStyle(
                                        color: _selectedFiles.isEmpty
                                            ? const Color(0xFF2979FF)
                                            : const Color(0xFF2E7D32),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'PDF, JPG, PNG up to 10MB each',
                                      style: TextStyle(
                                          color: Color(0xFFB0BEC5),
                                          fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Display selected files
                          if (_selectedFiles.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Column(
                                children: [
                                  ..._selectedFiles
                                      .asMap()
                                      .entries
                                      .map((entry) {
                                    int index = entry.key;
                                    File file = entry.value;
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8F9FA),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: const Color(0xFFE0E4EA),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.insert_drive_file,
                                            color: Color(0xFF2979FF),
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  path.basename(file.path),
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                    color: Color(0xFF1A2340),
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                Text(
                                                  '${(file.lengthSync() / 1024).toStringAsFixed(1)} KB',
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    color: Color(0xFF9E9E9E),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.close_rounded,
                                              color: Color(0xFFE53935),
                                              size: 18,
                                            ),
                                            onPressed: () => _removeFile(index),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 12),

                          // Info message
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0F4FF),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: const [
                                  Icon(Icons.info_outline,
                                      color: Color(0xFF2979FF), size: 16),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Reports will be analyzed to determine eligibility and urgency. Our AI ensures top-tier validation.',
                                      style: TextStyle(
                                        color: Color(0xFF6B7280),
                                        fontSize: 11,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Confirm checkbox
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: _confirmed,
                          activeColor: const Color(0xFF2979FF),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4)),
                          onChanged: (v) => setState(() => _confirmed = v!),
                        ),
                        const Expanded(
                          child: Text(
                            'I confirm that all the information provided is accurate and correct to my knowledge.',
                            style: TextStyle(
                                color: Color(0xFF6B7280), fontSize: 12),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Register button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: (_isLoading || _isUploading)
                            ? null
                            : _submitUserRegistration,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2979FF),
                          disabledBackgroundColor: const Color(0xFFB0C4DE),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: _isLoading || _isUploading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3,
                                ),
                              )
                            : const Text(
                                'Register Now',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared helper widgets ────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget child;

  const _SectionCard({
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
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: iconColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF1A2340),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;

  const _InputField({
    required this.controller,
    required this.hint,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Color(0xFF1A2340), fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFB0BEC5), fontSize: 13),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFDDE3ED)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFDDE3ED)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF2979FF), width: 1.5),
        ),
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  final String? value;
  final String? hint;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final IconData? prefixIcon;

  const _DropdownField({
    required this.items,
    required this.onChanged,
    this.value,
    this.hint,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFDDE3ED)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          hint: Row(
            children: [
              if (prefixIcon != null) ...[
                Icon(prefixIcon, color: const Color(0xFFB0BEC5), size: 16),
                const SizedBox(width: 8),
              ],
              Text(
                hint ?? 'Select',
                style: const TextStyle(color: Color(0xFFB0BEC5), fontSize: 13),
              ),
            ],
          ),
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: Color(0xFFB0BEC5)),
          style: const TextStyle(color: Color(0xFF1A2340), fontSize: 13),
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggle;

  const _PasswordField({
    required this.controller,
    required this.obscure,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Color(0xFF1A2340), fontSize: 13),
      decoration: InputDecoration(
        hintText: '••••••••',
        hintStyle: const TextStyle(color: Color(0xFFB0BEC5), fontSize: 13),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            color: const Color(0xFFB0BEC5),
            size: 18,
          ),
          onPressed: onToggle,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFDDE3ED)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFDDE3ED)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF2979FF), width: 1.5),
        ),
      ),
    );
  }
}

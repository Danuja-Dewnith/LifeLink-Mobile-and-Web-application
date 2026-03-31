import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> initialData;

  const EditProfileScreen({
    super.key,
    required this.initialData,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _fullNameController;
  late TextEditingController _phoneController;
  late TextEditingController _cityController;
  late TextEditingController _ageController;

  String? _selectedBloodGroup;
  String? _selectedGender;
  String? _selectedDonationPref;

  Uint8List? _selectedImageBytes;
  File? _selectedImageFile;
  String? _currentProfileUrl;

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  final List<String> bloodGroups = [
    'A+',
    'A-',
    'B+',
    'B-',
    'O+',
    'O-',
    'AB+',
    'AB-'
  ];
  final List<String> genders = ['Male', 'Female', 'Other', 'Prefer not to say'];
  final List<String> donationPreferences = [
    'Whole Blood',
    'Platelets',
    'Plasma',
    'Any (All types)',
    'Not sure yet',
  ];

  @override
  void initState() {
    super.initState();

    _fullNameController =
        TextEditingController(text: widget.initialData['fullName'] ?? '');
    _phoneController =
        TextEditingController(text: widget.initialData['phone'] ?? '');
    _cityController =
        TextEditingController(text: widget.initialData['city'] ?? '');
    _ageController = TextEditingController(
        text: widget.initialData['age']?.toString() ?? '');

    _selectedBloodGroup =
        bloodGroups.contains(widget.initialData['bloodGroup']?.toString())
            ? widget.initialData['bloodGroup'].toString()
            : null;

    _selectedGender = genders.contains(widget.initialData['gender']?.toString())
        ? widget.initialData['gender'].toString()
        : null;

    _selectedDonationPref = donationPreferences
            .contains(widget.initialData['donationPref']?.toString())
        ? widget.initialData['donationPref'].toString()
        : null;

    _currentProfileUrl = widget.initialData['avatarUrl']?.toString();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 75,
        maxWidth: 800,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();

        setState(() {
          _selectedImageBytes = bytes;
          if (!kIsWeb) {
            _selectedImageFile = File(pickedFile.path);
          }
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to pick image: $e';
      });
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null || token.isEmpty) {
        setState(() {
          _errorMessage = 'Session expired. Please login again.';
          _isLoading = false;
        });
        return;
      }

      var request = http.MultipartRequest(
        'PATCH', // ← Changed to PATCH to match backend
        Uri.parse(
            'http://10.168.30.196:3000/profile'), // or 10.0.2.2:3000 for emulator
      );

      request.headers['Authorization'] = 'Bearer $token';

      // Text fields
      request.fields['fullName'] = _fullNameController.text.trim();
      request.fields['phone'] = _phoneController.text.trim();
      request.fields['city'] = _cityController.text.trim();
      request.fields['age'] = _ageController.text.trim();

      if (_selectedBloodGroup != null)
        request.fields['bloodGroup'] = _selectedBloodGroup!;
      if (_selectedGender != null) request.fields['gender'] = _selectedGender!;
      if (_selectedDonationPref != null)
        request.fields['donationPref'] = _selectedDonationPref!;

      // Add avatar if selected
      if (_selectedImageBytes != null) {
        var multipartFile = http.MultipartFile.fromBytes(
          'avatar', // ← Changed to 'avatar' to match backend multer.single('avatar')
          _selectedImageBytes!,
          filename: 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        request.files.add(multipartFile);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        setState(() {
          _successMessage = 'Profile updated successfully!';
          _isLoading = false;
        });

        Future.delayed(const Duration(milliseconds: 1400), () {
          if (mounted) Navigator.pop(context, true);
        });
      } else {
        setState(() {
          _errorMessage =
              'Update failed (${response.statusCode})\n${response.body}';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Update error: $e');
      setState(() {
        _errorMessage = 'Connection error: $e';
        _isLoading = false;
      });
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
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: Color(0xFF2979FF)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: Color(0xFF1A2340),
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: const Color(0xFF2979FF), width: 3),
                          ),
                          child: ClipOval(
                            child: _selectedImageBytes != null
                                ? Image.memory(
                                    _selectedImageBytes!,
                                    fit: BoxFit.cover,
                                    width: 120,
                                    height: 120,
                                  )
                                : (_currentProfileUrl != null &&
                                        _currentProfileUrl!.isNotEmpty)
                                    ? Image.network(
                                        _currentProfileUrl!,
                                        fit: BoxFit.cover,
                                        width: 120,
                                        height: 120,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(
                                          Icons.person,
                                          size: 60,
                                          color: Colors.grey,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.person,
                                        size: 70,
                                        color: Colors.grey,
                                      ),
                          ),
                        ),
                        const Positioned(
                          bottom: 4,
                          right: 4,
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: Color(0xFF2979FF),
                            child: Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Center(
                  child: Text(
                    'Tap photo to change',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 32),
                _buildSectionTitle('PERSONAL INFORMATION'),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _fullNameController,
                  label: 'Full Name',
                  icon: Icons.person,
                  validator: (v) =>
                      v?.trim().isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                _buildDropdown(
                  value: _selectedGender,
                  label: 'Gender',
                  icon: Icons.transgender,
                  items: genders,
                  onChanged: (v) => setState(() => _selectedGender = v),
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _ageController,
                  label: 'Age',
                  icon: Icons.calendar_today,
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v?.trim().isEmpty ?? true) return 'Required';
                    final ageVal = int.tryParse(v!);
                    if (ageVal == null || ageVal < 17) return 'Must be 17+';
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('CONTACT INFORMATION'),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _phoneController,
                  label: 'Phone Number',
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                  validator: (v) =>
                      v?.trim().isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _cityController,
                  label: 'City',
                  icon: Icons.location_on,
                  validator: (v) =>
                      v?.trim().isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('HEALTH & DONATION PREFERENCE'),
                const SizedBox(height: 12),
                _buildDropdown(
                  value: _selectedBloodGroup,
                  label: 'Blood Group',
                  icon: Icons.water_drop,
                  items: bloodGroups,
                  onChanged: (v) => setState(() => _selectedBloodGroup = v),
                  validator: (v) => v == null ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                _buildDropdown(
                  value: _selectedDonationPref,
                  label: 'Preferred Donation Type',
                  icon: Icons.favorite,
                  items: donationPreferences,
                  onChanged: (v) => setState(() => _selectedDonationPref = v),
                ),
                const SizedBox(height: 40),
                if (_successMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      _successMessage!,
                      style: const TextStyle(
                          color: Color(0xFF43A047),
                          fontWeight: FontWeight.w700),
                      textAlign: TextAlign.center,
                    ),
                  ),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                          color: Colors.red, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _updateProfile,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5),
                          )
                        : const Icon(Icons.save_rounded, size: 20),
                    label: Text(
                      _isLoading ? 'SAVING...' : 'SAVE CHANGES',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2979FF),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Helper widgets ──────────────────────────────────────────────────────────
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFF1A2340),
        fontSize: 15,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF2979FF)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2979FF), width: 2),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String label,
    required IconData icon,
    required List<String> items,
    required void Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      onChanged: onChanged,
      validator: validator,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF2979FF)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2979FF), width: 2),
        ),
      ),
      items: items.map((item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList(),
    );
  }
}

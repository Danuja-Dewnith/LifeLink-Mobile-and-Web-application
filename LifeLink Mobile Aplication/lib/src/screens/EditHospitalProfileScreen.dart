import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // ✅ needed for MediaType
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

class EditHospitalProfileScreen extends StatefulWidget {
  final Map<String, String?> initialData;

  const EditHospitalProfileScreen({
    super.key,
    required this.initialData,
  });

  @override
  State<EditHospitalProfileScreen> createState() =>
      _EditHospitalProfileScreenState();
}

class _EditHospitalProfileScreenState extends State<EditHospitalProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _regController;
  late TextEditingController _addressController;
  late TextEditingController _contactController;
  late TextEditingController _emailController;

  Uint8List? _selectedImageBytes; // preview bytes
  String? _selectedImagePath; // ✅ path needed to derive correct MIME type
  String? _currentImageUrl; // existing URL from server

  // ✅ FIX 3: UniqueKey forces Image.network to reload after save
  Key _avatarKey = UniqueKey();

  bool _isSaving = false;
  String? _errorMessage;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();

    _nameController =
        TextEditingController(text: widget.initialData['name'] ?? '');
    _regController =
        TextEditingController(text: widget.initialData['regNumber'] ?? '');
    _addressController =
        TextEditingController(text: widget.initialData['address'] ?? '');
    _contactController =
        TextEditingController(text: widget.initialData['contact'] ?? '');
    _emailController =
        TextEditingController(text: widget.initialData['email'] ?? '');

    // ✅ FIX 1: read 'avatarUrl' — caller now passes this key correctly
    _currentImageUrl = widget.initialData['avatarUrl'];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _regController.dispose();
    _addressController.dispose();
    _contactController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────
  // PICK IMAGE
  // ─────────────────────────────────────────────────────────────────
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 800,
      );
      if (image != null && mounted) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
          _selectedImagePath = image.path; // ✅ save for MIME detection
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error picking image: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // VALIDATION
  // ─────────────────────────────────────────────────────────────────
  bool _validateForm() {
    final name = _nameController.text.trim();
    final reg = _regController.text.trim();
    final address = _addressController.text.trim();
    final contact = _contactController.text.trim();
    final email = _emailController.text.trim();

    if (name.isEmpty) {
      _showError('Hospital name is required');
      return false;
    }
    if (reg.isEmpty) {
      _showError('Registration number is required');
      return false;
    }
    if (address.isEmpty) {
      _showError('Address is required');
      return false;
    }
    if (contact.isEmpty) {
      _showError('Contact number is required');
      return false;
    }
    if (email.isEmpty || !_isValidEmail(email)) {
      _showError('Please enter a valid email address');
      return false;
    }
    if (!RegExp(r'^(?:0|94|\+94)?[0-9]{9,10}$')
        .hasMatch(contact.replaceAll(RegExp(r'[\s\-]'), ''))) {
      _showError('Please enter a valid phone number (e.g. 0771234567)');
      return false;
    }
    return true;
  }

  bool _isValidEmail(String email) =>
      RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3)),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // SAVE PROFILE
  // ─────────────────────────────────────────────────────────────────
  Future<void> _saveProfile() async {
    if (!_validateForm()) return;
    if (!mounted) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null || token.isEmpty) {
        _showError('Session expired. Please login again.');
        setState(() => _isSaving = false);
        return;
      }

      final request = http.MultipartRequest(
        'PATCH',
        Uri.parse('http://10.168.30.196:3000/profile'),
      );

      request.headers['Authorization'] = 'Bearer $token';

      // ── Text fields ──────────────────────────────────────────────
      request.fields['name'] = _nameController.text.trim();
      request.fields['regNumber'] = _regController.text.trim();
      request.fields['address'] = _addressController.text.trim();
      request.fields['contact'] = _contactController.text.trim();
      request.fields['email'] = _emailController.text.trim();

      // ── Avatar — with explicit MIME type ────────────────────────
      if (_selectedImageBytes != null) {
        // ✅ FIX 2: derive correct MIME subtype from file extension.
        // Without MediaType, Flutter sends 'application/octet-stream'
        // which fails multer's fileFilter → "Only JPEG, PNG… allowed".
        final ext = _selectedImagePath != null
            ? p.extension(_selectedImagePath!).toLowerCase().replaceAll('.', '')
            : 'jpg';

        final mimeSubtype = ext == 'png'
            ? 'png'
            : ext == 'webp'
                ? 'webp'
                : 'jpeg';

        request.files.add(
          http.MultipartFile.fromBytes(
            'avatar',
            _selectedImageBytes!,
            filename: 'avatar_${DateTime.now().millisecondsSinceEpoch}.$ext',
            contentType: MediaType('image', mimeSubtype), // ✅ explicit MIME
          ),
        );
      }

      final streamed =
          await request.send().timeout(const Duration(seconds: 25));
      final response = await http.Response.fromStream(streamed);

      if (!mounted) return;

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // ✅ FIX 3: update displayed URL from response + reset cache key
        try {
          final data = jsonDecode(response.body);
          final newUrl = data['user']?['avatarUrl']?.toString();
          if (newUrl != null && newUrl.isNotEmpty) {
            setState(() {
              _currentImageUrl = newUrl;
              _selectedImageBytes = null;
              _selectedImagePath = null;
              _avatarKey = UniqueKey(); // force Image.network reload
            });
          }
        } catch (_) {}

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.pop(context, true);
      } else {
        // ✅ Show clean JSON error — not raw HTML stack trace
        String errorMsg = 'Failed to update (${response.statusCode})';
        try {
          final decoded = jsonDecode(response.body);
          errorMsg = decoded['error'] ?? errorMsg;
        } catch (_) {
          final preMatch = RegExp(r'<pre>(.*?)</pre>', dotAll: true)
              .firstMatch(response.body);
          if (preMatch != null) {
            errorMsg =
                preMatch.group(1)?.replaceAll(RegExp(r'<[^>]+>'), '').trim() ??
                    errorMsg;
          }
        }
        setState(() => _errorMessage = errorMsg);
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = 'Connection error: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECEFF4),
      appBar: AppBar(
        backgroundColor: const Color(0xFFECEFF4),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A2340)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: Color(0xFF1A2340),
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Profile Picture ────────────────────────────────────
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                                color: const Color(0xFFDDE3ED), width: 3),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(21),
                            child: _selectedImageBytes != null
                                // local preview
                                ? Image.memory(
                                    _selectedImageBytes!,
                                    fit: BoxFit.cover,
                                    width: 110,
                                    height: 110,
                                  )
                                : (_currentImageUrl != null &&
                                        _currentImageUrl!.trim().isNotEmpty)
                                    // ✅ FIX 3: UniqueKey avoids stale cache
                                    ? Image.network(
                                        _currentImageUrl!,
                                        key: _avatarKey,
                                        fit: BoxFit.cover,
                                        loadingBuilder: (ctx, child, progress) {
                                          if (progress == null) return child;
                                          return const Center(
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Color(0xFF2979FF),
                                            ),
                                          );
                                        },
                                        errorBuilder: (_, __, ___) =>
                                            _defaultIcon(),
                                      )
                                    : _defaultIcon(),
                          ),
                        ),
                        Positioned(
                          bottom: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Color(0xFF2979FF),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.camera_alt,
                                  color: Colors.white, size: 20),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Tap the camera icon to change photo',
                      style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ── Form Fields ────────────────────────────────────────
              _FieldSection(
                title: 'Organization Details',
                children: [
                  _LabeledField(
                    label: 'Hospital / Blood Bank Name *',
                    controller: _nameController,
                    hint: 'Official name',
                  ),
                  _LabeledField(
                    label: 'Registration Number *',
                    controller: _regController,
                    hint: 'HL-XXXXXX or similar',
                  ),
                  _LabeledField(
                    label: 'Complete Address *',
                    controller: _addressController,
                    hint: 'Street, City, District, Postal Code',
                    maxLines: 3,
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _LabeledField(
                          label: 'Contact Number *',
                          controller: _contactController,
                          hint: '+94 77 123 4567',
                          keyboardType: TextInputType.phone,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _LabeledField(
                          label: 'Official Email *',
                          controller: _emailController,
                          hint: 'admin@hospital.lk',
                          keyboardType: TextInputType.emailAddress,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // ── Error message ──────────────────────────────────────
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── Save Button ────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveProfile,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Icon(Icons.save_rounded, size: 20),
                  label: Text(
                    _isSaving ? 'Saving...' : 'Save Changes',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2979FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _defaultIcon() {
    return Container(
      color: const Color(0xFFDDE8FA),
      alignment: Alignment.center,
      child: const Icon(Icons.business, color: Color(0xFF2979FF), size: 48),
    );
  }
}

// ── Reusable sub-widgets ────────────────────────────────────────────────────

class _FieldSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _FieldSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: Color(0xFF9E9E9E),
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 12),
        Container(
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
          padding: const EdgeInsets.all(16),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final int? maxLines;

  const _LabeledField({
    required this.label,
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
              color: Color(0xFF1A2340),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            )),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFFB0BEC5), fontSize: 13),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
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
              borderSide:
                  const BorderSide(color: Color(0xFF2979FF), width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

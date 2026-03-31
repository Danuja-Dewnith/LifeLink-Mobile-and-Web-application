import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _dobController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _zipController = TextEditingController();
  final _chronicConditionsController = TextEditingController();

  String? _selectedBloodGroup;
  String? _selectedPrimaryHospital;
  String? _avatarUrl; // live URL from server
  File? _pickedImageFile; // local file picked but not yet uploaded
  String? _displayName;
  String? _patientId;

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingAvatar = false;
  String? _errorMessage;

  // ✅ FIX BUG 4: cache-bust key — changes every time a new URL is received
  // so Flutter's Image.network drops the cached version and loads the new one.
  Key _avatarImageKey = UniqueKey();

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
  final List<String> hospitals = [
    'National Hospital - Colombo',
    "St. Mary's Gene",
    'Teaching Hospital - Kandy',
    'Other',
  ];

  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _loadCurrentProfile();
  }

  // ─────────────────────────────────────────────────────────────
  // LOAD PROFILE
  // ─────────────────────────────────────────────────────────────
  Future<void> _loadCurrentProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Please login first';
        });
        return;
      }

      final response = await http.get(
        Uri.parse('http://10.168.30.196:3000/profile'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        DateTime? parsedDob;
        if (data['dob'] != null && data['dob'].toString().isNotEmpty) {
          try {
            parsedDob = DateTime.parse(data['dob']);
          } catch (_) {}
        }

        final backendHospital = data['hospital']?.toString() ?? '';
        final resolvedHospital = hospitals.contains(backendHospital)
            ? backendHospital
            : (backendHospital.isNotEmpty ? 'Other' : null);

        setState(() {
          _displayName = data['fullName'] ?? data['name'] ?? '';
          _patientId = data['_id'] ?? '';

          _fullNameController.text = data['fullName'] ?? data['name'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          _emailController.text = data['email'] ?? '';
          _chronicConditionsController.text = data['donationPref'] ?? '';

          _selectedBloodGroup = (data['bloodGroup'] != null &&
                  bloodGroups.contains(data['bloodGroup']))
              ? data['bloodGroup']
              : null;

          _selectedPrimaryHospital = resolvedHospital;
          _selectedDate = parsedDob;
          _dobController.text = parsedDob != null
              ? DateFormat('MM/dd/yyyy').format(parsedDob)
              : '';

          _streetController.text = data['street'] ?? '';
          _cityController.text = data['city'] ?? '';
          _zipController.text = data['zip'] ?? '';

          final url = data['avatarUrl']?.toString() ?? '';
          _avatarUrl = url.isNotEmpty ? url : null;

          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load profile';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: $e';
      });
    }
  }

  // ─────────────────────────────────────────────────────────────
  // PICK IMAGE — Gallery or Camera
  // ─────────────────────────────────────────────────────────────
  Future<void> _pickImage() async {
    // ✅ FIX BUG 3: Use a bool flag to detect "Remove" vs null-dismiss.
    // The bottom sheet returns:
    //   ImageSource value  → user chose gallery or camera
    //   null               → user dismissed the sheet (swiped away)
    // "Remove photo" is handled by its own dedicated onTap → _removePhoto()
    // so it never goes through this return value at all.

    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Upload Profile Photo',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFE3F2FD),
                child:
                    Icon(Icons.photo_library_rounded, color: Color(0xFF2979FF)),
              ),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFE8F5E9),
                child: Icon(Icons.camera_alt_rounded, color: Color(0xFF43A047)),
              ),
              title: const Text('Take a Photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            // ✅ FIX BUG 3: "Remove photo" calls _removePhoto() directly —
            // it does NOT pop with null so we never confuse it with a dismiss.
            if (_avatarUrl != null || _pickedImageFile != null)
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFFFEBEE),
                  child: Icon(Icons.delete_outline_rounded,
                      color: Color(0xFFE53935)),
                ),
                title: const Text('Remove Photo',
                    style: TextStyle(color: Color(0xFFE53935))),
                onTap: () {
                  Navigator.pop(ctx); // close sheet first
                  _removePhoto(); // then trigger remove flow
                },
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );

    // null means the user swiped the sheet away — do nothing
    if (source == null || !mounted) return;

    final XFile? xfile = await ImagePicker().pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 800,
      maxHeight: 800,
    );

    if (xfile == null || !mounted) return;

    setState(() => _pickedImageFile = File(xfile.path));
    await _uploadAvatar();
  }

  // ─────────────────────────────────────────────────────────────
  // REMOVE PHOTO
  // ─────────────────────────────────────────────────────────────
  Future<void> _removePhoto() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Photo'),
        content: const Text('Remove your profile photo?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _isSaving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      final response = await http.patch(
        Uri.parse('http://10.168.30.196:3000/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'avatarUrl': ''}),
      );

      if (response.statusCode == 200 && mounted) {
        setState(() {
          _avatarUrl = null;
          _pickedImageFile = null;
          _avatarImageKey = UniqueKey(); // reset cache key
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Photo removed'), backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // UPLOAD AVATAR
  // ─────────────────────────────────────────────────────────────
  Future<void> _uploadAvatar() async {
    if (_pickedImageFile == null) return;
    setState(() => _isUploadingAvatar = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      final ext =
          p.extension(_pickedImageFile!.path).toLowerCase().replaceAll('.', '');
      final mimeType = ext == 'png'
          ? 'png'
          : ext == 'webp'
              ? 'webp'
              : 'jpeg';

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('http://10.168.30.196:3000/upload-avatar'),
      )
        ..headers['Authorization'] = 'Bearer $token'
        ..files.add(await http.MultipartFile.fromPath(
          'avatar',
          _pickedImageFile!.path,
          contentType: MediaType('image', mimeType),
        ));

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _avatarUrl = data['avatarUrl'] as String?;
            _pickedImageFile = null;
            // ✅ FIX BUG 4: new UniqueKey forces Image.network to reload
            // even if the hostname is the same — bypasses Flutter's image cache.
            _avatarImageKey = UniqueKey();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Profile photo updated!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception(jsonDecode(response.body)['error'] ?? 'Upload failed');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Upload error: $e'), backgroundColor: Colors.red),
        );
        setState(() => _pickedImageFile = null);
      }
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // DATE PICKER
  // ─────────────────────────────────────────────────────────────
  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(1990),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dobController.text = DateFormat('MM/dd/yyyy').format(picked);
      });
    }
  }

  // ─────────────────────────────────────────────────────────────
  // SAVE PROFILE (text fields only — avatar saved on pick)
  // ─────────────────────────────────────────────────────────────
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final updateData = {
      'fullName': _fullNameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'email': _emailController.text.trim(),
      'bloodGroup': _selectedBloodGroup,
      'donationPref': _chronicConditionsController.text.trim(),
      'dob': _selectedDate?.toIso8601String(),
      'street': _streetController.text.trim(),
      'city': _cityController.text.trim(),
      'zip': _zipController.text.trim(),
      'hospital': _selectedPrimaryHospital ?? '',
    };

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      final response = await http.patch(
        Uri.parse('http://10.168.30.196:3000/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(updateData),
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Profile updated!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      } else {
        throw Exception('Update failed: ${response.body}');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _cancelAndGoBack() => Navigator.pop(context, false);

  // ─────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: _cancelAndGoBack,
        ),
        title:
            const Text('Edit Profile', style: TextStyle(color: Colors.black)),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Color(0xFF2979FF)),
            onPressed: _isSaving ? null : _saveProfile,
          ),
        ],
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_errorMessage!,
                          style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _isLoading = true;
                            _errorMessage = null;
                          });
                          _loadCurrentProfile();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // ── Avatar ──────────────────────────────────────
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              width: 104,
                              height: 104,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.grey[300],
                                border: Border.all(
                                    color: const Color(0xFF2979FF), width: 2.5),
                              ),
                              child: ClipOval(
                                child: _isUploadingAvatar
                                    ? const Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 3,
                                          color: Color(0xFF2979FF),
                                        ),
                                      )
                                    : _pickedImageFile != null
                                        // local preview
                                        ? Image.file(
                                            _pickedImageFile!,
                                            width: 104,
                                            height: 104,
                                            fit: BoxFit.cover,
                                          )
                                        : _avatarUrl != null
                                            // ✅ FIX BUG 4: ValueKey(_avatarImageKey)
                                            // forces widget rebuild when key changes,
                                            // so the new image is fetched even if the
                                            // URL looks the same to the image cache.
                                            ? Image.network(
                                                _avatarUrl!,
                                                key: _avatarImageKey,
                                                width: 104,
                                                height: 104,
                                                fit: BoxFit.cover,
                                                // Show a loading spinner while fetching
                                                loadingBuilder:
                                                    (ctx, child, progress) {
                                                  if (progress == null)
                                                    return child;
                                                  return const Center(
                                                    child:
                                                        CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Color(0xFF2979FF),
                                                    ),
                                                  );
                                                },
                                                errorBuilder: (_, __, ___) =>
                                                    const Icon(Icons.person,
                                                        size: 50,
                                                        color: Colors.white),
                                              )
                                            : const Icon(Icons.person,
                                                size: 50, color: Colors.white),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _isUploadingAvatar ? null : _pickImage,
                                child: Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2979FF),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 2),
                                  ),
                                  child: const Icon(Icons.camera_alt_rounded,
                                      size: 16, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // ── Status / remove link ─────────────────────────
                        if (_isUploadingAvatar)
                          const Text('Uploading photo...',
                              style: TextStyle(
                                  color: Color(0xFF2979FF), fontSize: 12))
                        else if (_avatarUrl != null || _pickedImageFile != null)
                          GestureDetector(
                            onTap: _removePhoto,
                            child: const Text('Remove photo',
                                style: TextStyle(
                                  color: Color(0xFFE53935),
                                  fontSize: 12,
                                  decoration: TextDecoration.underline,
                                )),
                          )
                        else
                          const Text('Tap camera icon to upload a photo',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 12)),

                        const SizedBox(height: 12),

                        Text(_displayName ?? '',
                            style: const TextStyle(
                                fontSize: 22, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),

                        if (_patientId != null && _patientId!.isNotEmpty)
                          Text(
                            'PATIENT ID: ${_patientId!.length > 8 ? _patientId!.substring(_patientId!.length - 8).toUpperCase() : _patientId!.toUpperCase()}',
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 14),
                          ),

                        const SizedBox(height: 32),

                        // ── Personal Information ─────────────────────────
                        _buildSection(
                          icon: Icons.person,
                          title: 'Personal Information',
                          children: [
                            _buildField(
                                'FULL NAME', _fullNameController, 'Full name'),
                            _buildField(
                                'PHONE NUMBER', _phoneController, 'Phone'),
                            _buildFieldWithUpdate('EMAIL ADDRESS',
                                _emailController, 'Email', true),
                            _buildDateField('DATE OF BIRTH', _dobController,
                                () => _selectDate(context)),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // ── Medical Information ──────────────────────────
                        _buildSection(
                          icon: Icons.local_hospital,
                          title: 'Medical Information',
                          children: [
                            _buildDropdown(
                                'BLOOD GROUP',
                                _selectedBloodGroup,
                                bloodGroups,
                                (v) => setState(() => _selectedBloodGroup = v)),
                            _buildDropdown(
                                'PRIMARY HOSPITAL',
                                _selectedPrimaryHospital,
                                hospitals,
                                (v) => setState(
                                    () => _selectedPrimaryHospital = v)),
                            _buildField(
                                'CHRONIC CONDITIONS',
                                _chronicConditionsController,
                                'e.g. Mild Asthma'),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // ── Address Details ──────────────────────────────
                        _buildSection(
                          icon: Icons.location_on,
                          title: 'Address Details',
                          children: [
                            _buildField('STREET ADDRESS', _streetController,
                                'Street address'),
                            Row(
                              children: [
                                Expanded(
                                    child: _buildField(
                                        'CITY', _cityController, 'City')),
                                const SizedBox(width: 16),
                                Expanded(
                                    child: _buildField(
                                        'ZIP CODE', _zipController, 'ZIP')),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 40),

                        // ── Save Button ──────────────────────────────────
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _saveProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2979FF),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _isSaving
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : const Text('Save Changes',
                                    style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600)),
                          ),
                        ),

                        const SizedBox(height: 16),

                        TextButton(
                          onPressed: _cancelAndGoBack,
                          child: const Text('Cancel',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 16)),
                        ),

                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 3,
        selectedItemColor: const Color(0xFF2979FF),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.article), label: 'Records'),
          BottomNavigationBarItem(
              icon: Icon(Icons.monitor_heart), label: 'Vitals'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // HELPER WIDGETS
  // ─────────────────────────────────────────────────────────────
  Widget _buildSection({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, color: const Color(0xFF2979FF)),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildField(
      String label, TextEditingController controller, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
              flex: 2,
              child: Text(label,
                  style: const TextStyle(color: Colors.grey, fontSize: 14))),
          Expanded(
            flex: 3,
            child: TextFormField(
              controller: controller,
              decoration: InputDecoration(
                hintText: hint,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldWithUpdate(String label, TextEditingController controller,
      String hint, bool showUpdate) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
              flex: 2,
              child: Text(label,
                  style: const TextStyle(color: Colors.grey, fontSize: 14))),
          Expanded(
            flex: 3,
            child: Row(children: [
              Expanded(
                child: TextFormField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: hint,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              if (showUpdate)
                TextButton(
                  onPressed: () {},
                  child: const Text('Update',
                      style: TextStyle(color: Color(0xFF2979FF))),
                ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField(
      String label, TextEditingController controller, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
              flex: 2,
              child: Text(label,
                  style: const TextStyle(color: Colors.grey, fontSize: 14))),
          Expanded(
            flex: 3,
            child: GestureDetector(
              onTap: onTap,
              child: AbsorbPointer(
                child: TextFormField(
                  controller: controller,
                  decoration: const InputDecoration(
                    hintText: 'MM/DD/YYYY',
                    border: InputBorder.none,
                    suffixIcon: Icon(Icons.calendar_today, size: 20),
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, String? value, List<String> items,
      ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
              flex: 2,
              child: Text(label,
                  style: const TextStyle(color: Colors.grey, fontSize: 14))),
          Expanded(
            flex: 3,
            child: DropdownButtonFormField<String>(
              initialValue: value,
              decoration: const InputDecoration(border: InputBorder.none),
              hint: const Text('Select'),
              items: items
                  .map((item) =>
                      DropdownMenuItem(value: item, child: Text(item)))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _dobController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _zipController.dispose();
    _chronicConditionsController.dispose();
    super.dispose();
  }
}

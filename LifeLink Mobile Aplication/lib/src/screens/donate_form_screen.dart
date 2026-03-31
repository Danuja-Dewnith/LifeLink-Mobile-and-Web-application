import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:lifelink_app/src/utils/auth_helper.dart';

const String baseUrl = 'http://10.168.30.196 :3000';

class DonateFormScreen extends StatefulWidget {
  const DonateFormScreen({super.key});

  @override
  State<DonateFormScreen> createState() => _DonateFormScreenState();
}

class _DonateFormScreenState extends State<DonateFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _requestTitleController = TextEditingController();
  final _unitsController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedBloodGroup;
  String? _selectedDonationType;
  String? _selectedHospital;

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
  final List<String> _donationTypes = [
    'Whole Blood',
    'Plasma',
    'Platelets',
    'Red Cells',
    'Double Red Cell',
    'Kidney',
    'Liver',
    'Heart',
    'Lungs',
    'Pancreas',
    'Cornea',
    'Bone Marrow',
    'Skin',
    'Heart Valves',
    'Other',
  ];

  List<Map<String, dynamic>> _hospitals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadHospitals();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _requestTitleController.dispose();
    _unitsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    final token = await AuthHelper.getToken();
    if (token == null || token.isEmpty) return;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _fullNameController.text = data['fullName']?.toString() ?? '';
          _phoneController.text = data['phone']?.toString() ?? '';
          _selectedBloodGroup = data['bloodGroup']?.toString();

          String? pref = data['donationPref']?.toString();
          _selectedDonationType =
              _donationTypes.contains(pref) ? pref : 'Whole Blood';
        });
      }
    } catch (e) {
      print('Profile load error: $e');
    }
  }

  Future<void> _loadHospitals() async {
    final token = await AuthHelper.getToken();
    if (token == null || token.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/hospitals'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<Map<String, dynamic>> loaded =
            List<Map<String, dynamic>>.from(data['hospitals'] ?? []);

        setState(() {
          _hospitals = loaded;
          if (_hospitals.isNotEmpty && _selectedHospital == null) {
            _selectedHospital = _hospitals[0]['name'];
          }
        });
      }
    } catch (e) {
      print('Hospitals load error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitDonation() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedHospital == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select a hospital'),
            backgroundColor: Colors.red),
      );
      return;
    }

    final token = await AuthHelper.getToken();
    if (token == null) return;

    final body = {
      "requestTitle": _requestTitleController.text.trim(),
      "hospitalName": _selectedHospital,
      "units": _unitsController.text.trim(),
      "donationType": _selectedDonationType ?? 'Whole Blood',
      "bloodGroup": _selectedBloodGroup,
      "phone": _phoneController.text.trim(),
      "notes": _notesController.text.trim(),
      "fullName": _fullNameController.text.trim(),
    };

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/donations'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('🎉 Donation submitted!'),
              backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: ${response.body}'),
            backgroundColor: Colors.red));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Connection error'), backgroundColor: Colors.red));
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
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF2979FF)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Fill Donation Details',
            style: TextStyle(
                color: Color(0xFF1A2340),
                fontSize: 18,
                fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Your Donation Details',
                        style: TextStyle(
                            color: Color(0xFF1A2340),
                            fontSize: 20,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 20),
                    _buildTextField(
                        controller: _fullNameController,
                        label: 'Full Name',
                        validator: (v) =>
                            v?.trim().isEmpty ?? true ? 'Required' : null),
                    const SizedBox(height: 16),
                    _buildBloodGroupDropdown(),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _phoneController,
                      label: 'Phone Number',
                      hint: 'e.g. +9471 234 5678',
                      keyboardType: TextInputType.phone,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Required'
                          : (v.length < 9 ? 'Too short' : null),
                    ),
                    const SizedBox(height: 16),
                    _buildDonationTypeDropdown(),
                    const SizedBox(height: 16),
                    _buildTextField(
                        controller: _unitsController,
                        label: 'Units / Quantity',
                        validator: (v) =>
                            v?.trim().isEmpty ?? true ? 'Required' : null),
                    const SizedBox(height: 16),
                    _buildHospitalDropdown(),
                    const SizedBox(height: 16),
                    _buildTextField(
                        controller: _requestTitleController,
                        label: 'Request / Reason',
                        validator: (v) =>
                            v?.trim().isEmpty ?? true ? 'Required' : null),
                    const SizedBox(height: 16),
                    _buildTextField(
                        controller: _notesController,
                        label: 'Additional Notes',
                        maxLines: 3),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _submitDonation,
                        icon: const Icon(Icons.check_circle_rounded, size: 22),
                        label: const Text('Confirm & Submit Donation',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2979FF),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // All form widgets (unchanged from your original)
  Widget _buildBloodGroupDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedBloodGroup,
      items: _bloodGroups
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: (val) => setState(() => _selectedBloodGroup = val),
      decoration: _commonInputDecoration('Blood Group'),
      validator: (v) => v == null ? 'Select blood group' : null,
    );
  }

  Widget _buildDonationTypeDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedDonationType,
      items: _donationTypes
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: (val) => setState(() => _selectedDonationType = val),
      decoration: _commonInputDecoration('Donation Type'),
      validator: (v) => v == null ? 'Select type' : null,
    );
  }

  Widget _buildHospitalDropdown() {
    if (_hospitals.isEmpty) {
      return TextFormField(
        enabled: false,
        decoration: _commonInputDecoration('Select Hospital')
            .copyWith(hintText: 'No hospitals available'),
      );
    }

    return DropdownButtonFormField<String>(
      value: _selectedHospital,
      isExpanded: true,
      decoration: _commonInputDecoration('Select Hospital'),
      items: _hospitals.map((hospital) {
        final name = hospital['name']?.toString() ?? 'Unknown';
        final address = hospital['address']?.toString() ?? '';
        return DropdownMenuItem<String>(
          value: name,
          child: Text(address.isNotEmpty ? '$name - $address' : name),
        );
      }).toList(),
      onChanged: (value) => setState(() => _selectedHospital = value),
      validator: (value) => value == null ? 'Please select a hospital' : null,
    );
  }

  InputDecoration _commonInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int? maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: validator,
    );
  }
}

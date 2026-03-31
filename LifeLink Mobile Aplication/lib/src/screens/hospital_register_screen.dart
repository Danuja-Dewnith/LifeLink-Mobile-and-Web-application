import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HospitalRegisterScreen extends StatefulWidget {
  const HospitalRegisterScreen({super.key});

  @override
  State<HospitalRegisterScreen> createState() => _HospitalRegisterScreenState();
}

class _HospitalRegisterScreenState extends State<HospitalRegisterScreen> {
  final _nameController = TextEditingController();
  final _regNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _contactController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _storageCapacityController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _confirmed = false;
  bool _isLoading = false;

  // Blood type: enabled toggle + amount controller
  final List<String> _allBloodTypes = [
    'A+',
    'A-',
    'B+',
    'B-',
    'O+',
    'O-',
    'AB+',
    'AB-',
  ];

  // Which types are toggled on
  final Map<String, bool> _bloodTypeEnabled = {
    'A+': true,
    'A-': false,
    'B+': true,
    'B-': false,
    'O+': true,
    'O-': false,
    'AB+': false,
    'AB-': false,
  };

  // Amount controller per blood type
  final Map<String, TextEditingController> _bloodTypeControllers = {};

  @override
  void initState() {
    super.initState();
    for (final type in ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-']) {
      _bloodTypeControllers[type] = TextEditingController();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _regNumberController.dispose();
    _addressController.dispose();
    _contactController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _storageCapacityController.dispose();
    for (final c in _bloodTypeControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Validation helpers ──────────────────────────────────────────────────────

  bool _isValidEmail(String email) =>
      RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);

  bool _isValidPhone(String phone) {
    final clean = phone.replaceAll(RegExp(r'[\s\-]'), '');
    return RegExp(r'^(?:0|94|\+94)?[0-9]{9,10}$').hasMatch(clean);
  }

  bool _isValidRegNumber(String reg) => reg.trim().length >= 5;

  bool _isValidStorageCapacity(String cap) {
    if (cap.isEmpty) return false;
    final num = int.tryParse(cap);
    return num != null && num > 0;
  }

  bool _validateForm() {
    final name = _nameController.text.trim();
    final regNumber = _regNumberController.text.trim();
    final address = _addressController.text.trim();
    final contact = _contactController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;
    final storage = _storageCapacityController.text.trim();

    if (name.isEmpty) {
      _showError('Hospital / Blood Bank name is required');
      return false;
    }
    if (!_isValidRegNumber(regNumber)) {
      _showError('Enter a valid registration number');
      return false;
    }
    if (address.isEmpty) {
      _showError('Complete address is required');
      return false;
    }
    if (!_isValidPhone(contact)) {
      _showError('Enter a valid contact number (e.g. +94771234567)');
      return false;
    }
    if (!_isValidEmail(email)) {
      _showError('Enter a valid email address');
      return false;
    }

    // At least one blood type must be enabled
    final enabledTypes = _bloodTypeEnabled.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    if (enabledTypes.isEmpty) {
      _showError('Select at least one blood type');
      return false;
    }

    // Every enabled type must have a valid positive amount
    for (final type in enabledTypes) {
      final raw = _bloodTypeControllers[type]!.text.trim();
      final amount = int.tryParse(raw);
      if (amount == null || amount <= 0) {
        _showError('Enter a valid amount (units) for blood type $type');
        return false;
      }
    }

    if (!_isValidStorageCapacity(storage)) {
      _showError('Enter a valid storage capacity (positive number)');
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
      _showError('Please confirm the details are valid');
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

  Future<void> _submitHospitalRegistration() async {
    if (!_validateForm()) return;
    setState(() => _isLoading = true);

    // Build blood inventory map: { "A+": 120, "B+": 80, ... }
    final Map<String, int> bloodInventory = {};
    for (final type in _allBloodTypes) {
      if (_bloodTypeEnabled[type] == true) {
        bloodInventory[type] =
            int.parse(_bloodTypeControllers[type]!.text.trim());
      }
    }

    final data = {
      'name': _nameController.text.trim(),
      'regNumber': _regNumberController.text.trim(),
      'address': _addressController.text.trim(),
      'contact': _contactController.text.trim(),
      'email': _emailController.text.trim(),
      'password': _passwordController.text,
      'storageCapacity': _storageCapacityController.text.trim(),
      'bloodInventory': bloodInventory, // ← new structured field
      'selectedBloodTypes': bloodInventory.keys.toList(), // ← backward-compat
    };

    try {
      final response = await http.post(
        Uri.parse('http://10.168.30.196:3000/register-hospital'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (!mounted) return;

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Hospital / Blood Bank registered successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────────

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
                    child: const Icon(Icons.arrow_back,
                        color: Color(0xFF2979FF), size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Registration',
                    style: TextStyle(
                        color: Color(0xFF1A2340),
                        fontSize: 18,
                        fontWeight: FontWeight.w700),
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
                    // Hero image
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            height: 160,
                            width: double.infinity,
                            color: const Color(0xFFDDE8FA),
                            child: Image.network(
                              'https://images.unsplash.com/photo-1586773860418-d37222d8fce3?w=700&q=80',
                              fit: BoxFit.cover,
                              color: const Color(0xFFDDE8FA).withOpacity(0.5),
                              colorBlendMode: BlendMode.srcOver,
                              errorBuilder: (_, __, ___) =>
                                  Container(color: const Color(0xFFDDE8FA)),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: Center(
                            child: Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: const Color(0xFF2979FF),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.add,
                                  color: Colors.white, size: 32),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      'Hospital / Blood Bank\nRegistration',
                      style: TextStyle(
                        color: Color(0xFF1A2340),
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Register your organization for LifeLink verification to start saving lives.',
                      style: TextStyle(
                          color: Color(0xFF6B7280), fontSize: 13, height: 1.4),
                    ),

                    const SizedBox(height: 20),

                    // ── Organization Details ────────────────────────────────
                    _SectionCard(
                      icon: Icons.business_outlined,
                      iconColor: const Color(0xFF2979FF),
                      title: 'Organization Details',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _FieldLabel('HOSPITAL / BLOOD BANK NAME *'),
                          _InputField(
                              controller: _nameController,
                              hint: 'Enter official name'),
                          const SizedBox(height: 12),
                          const _FieldLabel('REGISTRATION NUMBER *'),
                          _InputField(
                              controller: _regNumberController,
                              hint: 'Govt. Issued Reg No.'),
                          const SizedBox(height: 12),
                          const _FieldLabel('COMPLETE ADDRESS *'),
                          TextField(
                            controller: _addressController,
                            maxLines: 3,
                            style: const TextStyle(
                                color: Color(0xFF1A2340), fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'Street, City, State, Zip',
                              hintStyle: const TextStyle(
                                  color: Color(0xFFB0BEC5), fontSize: 13),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide:
                                    const BorderSide(color: Color(0xFFDDE3ED)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide:
                                    const BorderSide(color: Color(0xFFDDE3ED)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                    color: Color(0xFF2979FF), width: 1.5),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const _FieldLabel('CONTACT NUMBER *'),
                                    _InputField(
                                        controller: _contactController,
                                        hint: '+94 77 123 4567',
                                        keyboardType: TextInputType.phone),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const _FieldLabel('OFFICIAL EMAIL *'),
                                    _InputField(
                                        controller: _emailController,
                                        hint: 'admin@org.com',
                                        keyboardType:
                                            TextInputType.emailAddress),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Account Access ──────────────────────────────────────
                    _SectionCard(
                      icon: Icons.lock_outline_rounded,
                      iconColor: const Color(0xFF2979FF),
                      title: 'Account Access',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _FieldLabel('PASSWORD * (min 8 characters)'),
                          _PasswordField(
                            controller: _passwordController,
                            obscure: _obscurePassword,
                            onToggle: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                          const SizedBox(height: 12),
                          const _FieldLabel('CONFIRM PASSWORD *'),
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

                    // ── Verification Documents ──────────────────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: const Color(0xFF2979FF).withOpacity(0.3)),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.verified_user_outlined,
                                  color: Color(0xFF2979FF), size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Verification Documents',
                                style: TextStyle(
                                    color: Color(0xFF2979FF),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                          SizedBox(height: 6),
                          Text(
                            'These documents will be reviewed and verified by LifeLink Admin before approval.',
                            style: TextStyle(
                                color: Color(0xFF6B7280),
                                fontSize: 11,
                                height: 1.4),
                          ),
                          SizedBox(height: 14),
                          _DocumentUploadRow(
                              icon: Icons.description_outlined,
                              label: 'Govt. Reg Certificate'),
                          Divider(color: Color(0xFFEEF2F7), height: 20),
                          _DocumentUploadRow(
                              icon: Icons.medical_services_outlined,
                              label: 'Medical License'),
                          Divider(color: Color(0xFFEEF2F7), height: 20),
                          _DocumentUploadRow(
                              icon: Icons.badge_outlined,
                              label: 'Authorized Person ID'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Storage Capabilities ────────────────────────────────
                    _SectionCard(
                      icon: Icons.water_drop_outlined,
                      iconColor: const Color(0xFF2979FF),
                      title: 'Storage Capabilities',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Blood type rows with toggle + amount input ──
                          const _FieldLabel(
                              'BLOOD TYPE INVENTORY * (toggle & enter units available)'),
                          const SizedBox(height: 10),
                          ...List.generate(_allBloodTypes.length, (i) {
                            // 2 blood types per row
                            if (i.isOdd) return const SizedBox.shrink();
                            final typeA = _allBloodTypes[i];
                            final typeB = i + 1 < _allBloodTypes.length
                                ? _allBloodTypes[i + 1]
                                : null;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                children: [
                                  Expanded(
                                      child: _BloodTypeAmountRow(
                                    bloodType: typeA,
                                    enabled: _bloodTypeEnabled[typeA]!,
                                    controller: _bloodTypeControllers[typeA]!,
                                    onToggle: (val) => setState(
                                        () => _bloodTypeEnabled[typeA] = val),
                                  )),
                                  const SizedBox(width: 10),
                                  if (typeB != null)
                                    Expanded(
                                        child: _BloodTypeAmountRow(
                                      bloodType: typeB,
                                      enabled: _bloodTypeEnabled[typeB]!,
                                      controller: _bloodTypeControllers[typeB]!,
                                      onToggle: (val) => setState(
                                          () => _bloodTypeEnabled[typeB] = val),
                                    ))
                                  else
                                    const Expanded(child: SizedBox()),
                                ],
                              ),
                            );
                          }),

                          const SizedBox(height: 14),
                          const _FieldLabel('TOTAL STORAGE CAPACITY (UNITS) *'),
                          _InputField(
                            controller: _storageCapacityController,
                            hint: 'e.g. 500',
                            keyboardType: TextInputType.number,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Confirm checkbox
                    Row(
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
                            'I confirm all details provided are valid and represent the official status of the organization.',
                            style: TextStyle(
                                color: Color(0xFF6B7280), fontSize: 12),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed:
                            _isLoading ? null : _submitHospitalRegistration,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2.5),
                              )
                            : const Icon(Icons.arrow_forward_rounded,
                                color: Colors.white, size: 20),
                        label: Text(
                          _isLoading
                              ? 'Submitting...'
                              : 'Submit for Verification',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2979FF),
                          disabledBackgroundColor: const Color(0xFFB0C4DE),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    Center(
                      child: RichText(
                        text: const TextSpan(
                          style:
                              TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                          children: [
                            TextSpan(text: 'Already registered?  '),
                            TextSpan(
                              text: 'Log in here',
                              style: TextStyle(
                                  color: Color(0xFF2979FF),
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
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

// ══════════════════════════════════════════════════════════════════════════════
// Blood Type Amount Row Widget
// ══════════════════════════════════════════════════════════════════════════════

class _BloodTypeAmountRow extends StatelessWidget {
  final String bloodType;
  final bool enabled;
  final TextEditingController controller;
  final ValueChanged<bool> onToggle;

  const _BloodTypeAmountRow({
    required this.bloodType,
    required this.enabled,
    required this.controller,
    required this.onToggle,
  });

  // Map blood type to a subtle tint color
  Color get _typeColor {
    if (bloodType.startsWith('A')) return const Color(0xFFE53935);
    if (bloodType.startsWith('B')) return const Color(0xFF8E24AA);
    if (bloodType.startsWith('O')) return const Color(0xFF1E88E5);
    return const Color(0xFF00897B); // AB
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: enabled ? _typeColor.withOpacity(0.06) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              enabled ? _typeColor.withOpacity(0.4) : const Color(0xFFDDE3ED),
          width: enabled ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          // Toggle chip / badge
          GestureDetector(
            onTap: () => onToggle(!enabled),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 42,
              height: 28,
              decoration: BoxDecoration(
                color: enabled ? _typeColor : const Color(0xFFECEFF4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  bloodType,
                  style: TextStyle(
                    color: enabled ? Colors.white : const Color(0xFF9E9E9E),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Units input
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: TextStyle(
                color:
                    enabled ? const Color(0xFF1A2340) : const Color(0xFFB0BEC5),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: enabled ? 'units' : '—',
                hintStyle: TextStyle(
                  color: enabled
                      ? const Color(0xFFB0BEC5)
                      : const Color(0xFFD0D5DD),
                  fontSize: 12,
                ),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                filled: true,
                fillColor: enabled ? Colors.white : const Color(0xFFF5F6F8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                      color: enabled
                          ? _typeColor.withOpacity(0.3)
                          : const Color(0xFFDDE3ED)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: _typeColor.withOpacity(0.3)),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: _typeColor, width: 1.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Shared helper widgets (unchanged from original)
// ══════════════════════════════════════════════════════════════════════════════

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
        border: Border.all(color: const Color(0xFFEEF2F7)),
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
                style: const TextStyle(
                  color: Color(0xFF1A2340),
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
          color: Color(0xFF9AA3B0),
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;

  const _InputField(
      {required this.controller, required this.hint, this.keyboardType});

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
        isDense: true,
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

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggle;

  const _PasswordField(
      {required this.controller,
      required this.obscure,
      required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Color(0xFF1A2340), fontSize: 13),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        suffixIcon: GestureDetector(
          onTap: onToggle,
          child: Icon(
              obscure
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: const Color(0xFFB0BEC5),
              size: 18),
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

class _DocumentUploadRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _DocumentUploadRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF2979FF), size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label,
              style: const TextStyle(
                  color: Color(0xFF1A2340),
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F4FF),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'Upload',
            style: TextStyle(
                color: Color(0xFF2979FF),
                fontSize: 12,
                fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

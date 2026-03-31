import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PasswordSecurityScreen extends StatefulWidget {
  const PasswordSecurityScreen({super.key});

  @override
  State<PasswordSecurityScreen> createState() => _PasswordSecurityScreenState();
}

class _PasswordSecurityScreenState extends State<PasswordSecurityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;
  bool _biometricEnabled = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null) throw Exception('Not authenticated');

      final response = await http.put(
        Uri.parse('http://192.168.1.4:3000/api/change-password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'currentPassword': _currentPasswordController.text,
          'newPassword': _newPasswordController.text,
        }),
      );

      if (response.statusCode == 200) {
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password changed successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Failed to change password');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F8),
      body: SafeArea(
        child: Column(
          children: [
            // Header
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
                      child: Text(
                        'Password & Security',
                        style: TextStyle(
                          color: Color(0xFF1A2340),
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // Change Password Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.lock_outline_rounded,
                                  color: Color(0xFF2979FF), size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Change Password',
                                style: TextStyle(
                                  color: Color(0xFF1A2340),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                // Current Password
                                TextFormField(
                                  controller: _currentPasswordController,
                                  obscureText: !_showCurrentPassword,
                                  decoration: InputDecoration(
                                    labelText: 'Current Password',
                                    labelStyle: const TextStyle(
                                        color: Color(0xFF9E9E9E), fontSize: 14),
                                    prefixIcon: const Icon(Icons.lock_outline,
                                        color: Color(0xFF9E9E9E), size: 20),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _showCurrentPassword
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        color: const Color(0xFF9E9E9E),
                                        size: 20,
                                      ),
                                      onPressed: () => setState(() =>
                                          _showCurrentPassword =
                                              !_showCurrentPassword),
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFFF8F9FC),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                          color: Color(0xFF2979FF), width: 1.5),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 14),
                                  ),
                                  validator: (v) => (v == null || v.isEmpty)
                                      ? 'Enter current password'
                                      : null,
                                ),
                                const SizedBox(height: 12),

                                // New Password
                                TextFormField(
                                  controller: _newPasswordController,
                                  obscureText: !_showNewPassword,
                                  decoration: InputDecoration(
                                    labelText: 'New Password',
                                    labelStyle: const TextStyle(
                                        color: Color(0xFF9E9E9E), fontSize: 14),
                                    prefixIcon: const Icon(
                                        Icons.lock_reset_outlined,
                                        color: Color(0xFF9E9E9E),
                                        size: 20),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _showNewPassword
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        color: const Color(0xFF9E9E9E),
                                        size: 20,
                                      ),
                                      onPressed: () => setState(() =>
                                          _showNewPassword = !_showNewPassword),
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFFF8F9FC),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                          color: Color(0xFF2979FF), width: 1.5),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 14),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty)
                                      return 'Enter new password';
                                    if (v.length < 6)
                                      return 'Password must be at least 6 characters';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),

                                // Confirm Password
                                TextFormField(
                                  controller: _confirmPasswordController,
                                  obscureText: !_showConfirmPassword,
                                  decoration: InputDecoration(
                                    labelText: 'Confirm New Password',
                                    labelStyle: const TextStyle(
                                        color: Color(0xFF9E9E9E), fontSize: 14),
                                    prefixIcon: const Icon(
                                        Icons.check_circle_outline,
                                        color: Color(0xFF9E9E9E),
                                        size: 20),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _showConfirmPassword
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        color: const Color(0xFF9E9E9E),
                                        size: 20,
                                      ),
                                      onPressed: () => setState(() =>
                                          _showConfirmPassword =
                                              !_showConfirmPassword),
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFFF8F9FC),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                          color: Color(0xFF2979FF), width: 1.5),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 14),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty)
                                      return 'Confirm your new password';
                                    if (v != _newPasswordController.text)
                                      return 'Passwords do not match';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed:
                                        _isLoading ? null : _changePassword,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF2979FF),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                      elevation: 0,
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Text(
                                            'Update Password',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Biometric Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.fingerprint_rounded,
                                  color: Color(0xFF2979FF), size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Biometric Login',
                                style: TextStyle(
                                  color: Color(0xFF1A2340),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      'Use fingerprint or face ID to login',
                                      style: TextStyle(
                                        color: Color(0xFF1A2340),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Faster and more secure access to your account',
                                      style: TextStyle(
                                        color: Color(0xFF9E9E9E),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _biometricEnabled,
                                onChanged: (val) {
                                  setState(() => _biometricEnabled = val);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(val
                                          ? 'Biometric login enabled'
                                          : 'Biometric login disabled'),
                                      backgroundColor:
                                          val ? Colors.green : Colors.orange,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                },
                                activeColor: const Color(0xFF2979FF),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),
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

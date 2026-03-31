import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  bool _profileVisibleToDonors = true;
  bool _shareLocation = true;
  bool _shareMedicalInfo = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadPrivacySettings();
  }

  Future<void> _loadPrivacySettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _profileVisibleToDonors =
          prefs.getBool('privacy_profile_visible') ?? true;
      _shareLocation = prefs.getBool('privacy_share_location') ?? true;
      _shareMedicalInfo = prefs.getBool('privacy_share_medical') ?? false;
    });
  }

  Future<void> _savePrivacySettings() async {
    setState(() => _isSaving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('privacy_profile_visible', _profileVisibleToDonors);
      await prefs.setBool('privacy_share_location', _shareLocation);
      await prefs.setBool('privacy_share_medical', _shareMedicalInfo);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Privacy settings saved!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteAccount() async {
    // Step 1: Confirm dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete Account',
          style:
              TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A2340)),
        ),
        content: const Text(
          'Are you sure you want to permanently delete your account? All your data including medical reports and request history will be removed. This cannot be undone.',
          style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF6B7280))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Step 2: Ask for password confirmation
    final passwordController = TextEditingController();
    final passwordConfirm = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Confirm Password',
          style:
              TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A2340)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter your password to confirm account deletion.',
              style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                filled: true,
                fillColor: const Color(0xFFF8F9FC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF6B7280))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, passwordController.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Confirm Delete'),
          ),
        ],
      ),
    );

    if (passwordConfirm == null || passwordConfirm.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      if (token == null) throw Exception('Not authenticated');

      final response = await http.delete(
        Uri.parse('http://192.168.1.4:3000/api/delete-account'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'password': passwordConfirm}),
      );

      if (response.statusCode == 200) {
        await prefs.clear();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          // Navigate to login/home screen — adjust route name to match your app
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        }
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Failed to delete account');
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
                        'Privacy Settings',
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
                  children: [
                    const SizedBox(height: 8),

                    // Profile Visibility Card
                    _PrivacyCard(
                      icon: Icons.shield_outlined,
                      iconColor: const Color(0xFF2979FF),
                      title: 'Profile Visibility',
                      children: [
                        _PrivacyToggleRow(
                          icon: Icons.people_outline_rounded,
                          iconColor: const Color(0xFF2979FF),
                          title: 'Visible to Donors',
                          subtitle:
                              'Allow blood donors to see your profile and request details',
                          value: _profileVisibleToDonors,
                          onChanged: (val) =>
                              setState(() => _profileVisibleToDonors = val),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Data Sharing Card
                    _PrivacyCard(
                      icon: Icons.share_outlined,
                      iconColor: const Color(0xFF4CAF50),
                      title: 'Data Sharing',
                      children: [
                        _PrivacyToggleRow(
                          icon: Icons.location_on_outlined,
                          iconColor: const Color(0xFFFF9800),
                          title: 'Share Location',
                          subtitle:
                              'Share your location to help nearby donors find you faster',
                          value: _shareLocation,
                          onChanged: (val) =>
                              setState(() => _shareLocation = val),
                        ),
                        const Divider(color: Color(0xFFF0F2F5), height: 1),
                        _PrivacyToggleRow(
                          icon: Icons.medical_information_outlined,
                          iconColor: const Color(0xFFE53935),
                          title: 'Share Medical Info',
                          subtitle:
                              'Share your blood group and medical condition with matched donors',
                          value: _shareMedicalInfo,
                          onChanged: (val) =>
                              setState(() => _shareMedicalInfo = val),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _savePrivacySettings,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2979FF),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Save Settings',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Danger Zone Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: const Color(0xFFFFEBEE), width: 1.5),
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
                              Icon(Icons.warning_amber_rounded,
                                  color: Color(0xFFE53935), size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Danger Zone',
                                style: TextStyle(
                                  color: Color(0xFFE53935),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Permanently delete your account and all associated data. This action is irreversible.',
                            style: TextStyle(
                              color: Color(0xFF9E9E9E),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: OutlinedButton.icon(
                              onPressed: _deleteAccount,
                              icon: const Icon(Icons.delete_forever_rounded,
                                  color: Color(0xFFE53935), size: 18),
                              label: const Text(
                                'Delete My Account',
                                style: TextStyle(
                                  color: Color(0xFFE53935),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                    color: Color(0xFFE53935), width: 1.5),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
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

class _PrivacyCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final List<Widget> children;

  const _PrivacyCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
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
          ),
          const Divider(color: Color(0xFFF0F2F5), height: 1),
          ...children,
        ],
      ),
    );
  }
}

class _PrivacyToggleRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _PrivacyToggleRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF1A2340),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF9E9E9E),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF2979FF),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'HospitalDashboardScreen.dart';
import 'PatientRequestsScreen.dart';
import 'AvailableDonorsScreen.dart';
import 'NotificationsScreen.dart';
import 'EditHospitalProfileScreen.dart';

class HospitalProfileScreen extends StatefulWidget {
  const HospitalProfileScreen({super.key});

  @override
  State<HospitalProfileScreen> createState() => _HospitalProfileScreenState();
}

class _HospitalProfileScreenState extends State<HospitalProfileScreen> {
  int _selectedBottomTab = 4;

  bool _isLoading = true;
  String? _errorMessage;

  String? name;
  String? regNumber;
  String? address;
  String? contact;
  String? email;

  // ✅ FIX 1: renamed from profileImageUrl → avatarUrl (matches backend field)
  // ✅ FIX 2: starts null — no hardcoded placeholder that masks missing data
  String? avatarUrl;

  // ✅ FIX 3: UniqueKey forces Image.network to reload after every profile refresh
  Key _avatarKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null || token.isEmpty) {
        setState(() {
          _errorMessage = 'Not logged in. Please login again.';
          _isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('http://10.168.30.196:3000/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 12));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          name = data['name'] ?? 'Unknown Hospital';
          regNumber = data['regNumber'] ?? '—';
          address = data['address'] ?? 'No address set';
          contact = data['contact'] ?? '—';
          email = data['email'] ?? '—';

          // ✅ FIX 1: read 'avatarUrl' — this is what the backend saves & returns.
          // Old code read 'profilePicture' which never exists in the API response
          // → image was always null/placeholder even after a successful upload.
          final rawUrl = data['avatarUrl']?.toString() ?? '';
          avatarUrl = rawUrl.isNotEmpty ? rawUrl : null;

          // ✅ FIX 3: new key on every load → Image.network re-fetches
          // and ignores Flutter's cached version of the old photo.
          _avatarKey = UniqueKey();

          _isLoading = false;
        });
      } else if (response.statusCode == 401) {
        setState(() {
          _errorMessage = 'Session expired. Please login again.';
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Could not load profile (${response.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Connection error: $e';
          _isLoading = false;
        });
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
            _buildTopBar(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? _buildErrorState()
                      : SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildProfileCard(),
                              const SizedBox(height: 24),
                              _buildSectionLabel('ACCOUNT SETTINGS'),
                              const SizedBox(height: 8),
                              _buildMenuGroup([
                                _MenuItem(
                                    icon: Icons.manage_accounts_outlined,
                                    label: 'Edit Profile'),
                                _MenuItem(
                                    icon: Icons.lock_reset_rounded,
                                    label: 'Change Password'),
                              ]),
                              const SizedBox(height: 20),
                              _buildSectionLabel('COMPLIANCE'),
                              const SizedBox(height: 8),
                              _buildMenuGroup([
                                _MenuItem(
                                    icon: Icons.description_outlined,
                                    label: 'Verification Documents'),
                              ]),
                              const SizedBox(height: 20),
                              _buildSectionLabel('OPERATIONS'),
                              const SizedBox(height: 8),
                              _buildMenuGroup([
                                _MenuItem(
                                    icon: Icons.water_drop_outlined,
                                    label: 'Blood Storage Settings'),
                              ]),
                              const SizedBox(height: 20),
                              _buildSectionLabel('SUPPORT'),
                              const SizedBox(height: 8),
                              _buildMenuGroup([
                                _MenuItem(
                                    icon: Icons.support_agent_rounded,
                                    label: 'Contact Admin'),
                                _MenuItem(
                                    icon: Icons.help_outline_rounded,
                                    label: 'Help Center'),
                              ]),
                              const SizedBox(height: 20),
                              _buildLogoutButton(),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 64, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Something went wrong',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.redAccent),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _loadProfileData,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      color: const Color(0xFFECEFF4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: const Icon(Icons.arrow_back,
                color: Color(0xFF1A2340), size: 22),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'Hospital Profile',
                style: TextStyle(
                  color: Color(0xFF1A2340),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 22),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    final displayName = name?.trim().isNotEmpty == true ? name! : 'Not set';
    final displayReg = regNumber?.trim().isNotEmpty == true ? regNumber! : '—';
    final displayAddress =
        address?.trim().isNotEmpty == true ? address! : 'Not provided';
    final displayContact =
        contact?.trim().isNotEmpty == true ? contact! : 'Not provided';
    final displayEmail =
        email?.trim().isNotEmpty == true ? email! : 'Not provided';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFDDE3ED), width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  // ✅ FIX 1 + 3: show real avatar with UniqueKey cache bust.
                  // Falls back to hospital icon — no hardcoded Unsplash URL.
                  child: avatarUrl != null
                      ? Image.network(
                          avatarUrl!,
                          key: _avatarKey,
                          fit: BoxFit.cover,
                          loadingBuilder: (ctx, child, progress) {
                            if (progress == null) return child;
                            return const Center(
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Color(0xFF2979FF)),
                            );
                          },
                          errorBuilder: (_, __, ___) => _defaultHospitalIcon(),
                        )
                      : _defaultHospitalIcon(),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: const Color(0xFF43A047),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            displayName,
            style: const TextStyle(
              color: Color(0xFF1A2340),
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Reg #: $displayReg',
                  style:
                      const TextStyle(color: Color(0xFF9E9E9E), fontSize: 13)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'VERIFIED',
                  style: TextStyle(
                    color: Color(0xFF43A047),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(color: Color(0xFFEEF2F7), height: 1),
          const SizedBox(height: 16),
          _InfoRow(
            icon: Icons.location_on_rounded,
            iconColor: const Color(0xFF2979FF),
            label: 'Address',
            value: displayAddress,
          ),
          const SizedBox(height: 14),
          _InfoRow(
            icon: Icons.phone_rounded,
            iconColor: const Color(0xFF2979FF),
            label: 'Contact',
            value: displayContact,
          ),
          const SizedBox(height: 14),
          _InfoRow(
            icon: Icons.email_rounded,
            iconColor: const Color(0xFF2979FF),
            label: 'Email',
            value: displayEmail,
          ),
        ],
      ),
    );
  }

  Widget _defaultHospitalIcon() {
    return Container(
      color: const Color(0xFFDDE8FA),
      child: const Icon(Icons.business, color: Color(0xFF2979FF), size: 40),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: Color(0xFF9E9E9E),
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildMenuGroup(List<_MenuItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          return Column(
            children: [
              _MenuRow(
                item: item,
                name: name,
                regNumber: regNumber,
                address: address,
                contact: contact,
                email: email,
                // ✅ FIX 4: pass 'avatarUrl' — EditHospitalProfileScreen reads
                // initialData['avatarUrl'] in initState, not 'profileImageUrl'
                avatarUrl: avatarUrl,
                onProfileUpdated: _loadProfileData,
              ),
              if (i < items.length - 1)
                const Divider(color: Color(0xFFEEF2F7), height: 1, indent: 54),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
              context, '/login', (route) => false);
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF5F5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFFCDD2)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, color: Color(0xFFE53935), size: 20),
            SizedBox(width: 10),
            Text(
              'Logout',
              style: TextStyle(
                color: Color(0xFFE53935),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    final tabs = [
      _NavItem(Icons.dashboard_rounded, 'DASHBOARD'),
      _NavItem(Icons.description_outlined, 'REQUESTS'),
      _NavItem(Icons.people_alt_outlined, 'DONORS'),
      _NavItem(Icons.notifications_outlined, 'NOTIFICATIONS'),
      _NavItem(Icons.person_rounded, 'PROFILE'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: tabs.asMap().entries.map((entry) {
              final i = entry.key;
              final tab = entry.value;
              final selected = i == _selectedBottomTab;
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedBottomTab = i);
                  if (i == 0) {
                    Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const HospitalDashboardScreen()));
                  } else if (i == 1) {
                    Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const PatientRequestsScreen()));
                  } else if (i == 2) {
                    Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AvailableDonorsScreen()));
                  } else if (i == 3) {
                    Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const NotificationsScreen()));
                  }
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        i == 4 && selected
                            ? Container(
                                width: 36,
                                height: 36,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF2979FF),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.person_rounded,
                                    color: Colors.white, size: 20),
                              )
                            : Icon(tab.icon,
                                color: selected
                                    ? const Color(0xFF2979FF)
                                    : const Color(0xFFB0BEC5),
                                size: 22),
                        if (i == 3)
                          Positioned(
                            right: -2,
                            top: -2,
                            child: Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: Color(0xFFE53935),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tab.label,
                      style: TextStyle(
                        color: selected
                            ? const Color(0xFF2979FF)
                            : const Color(0xFFB0BEC5),
                        fontSize: 9,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w400,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// ── Supporting classes ──────────────────────────────────────────────────────

class _MenuItem {
  final IconData icon;
  final String label;
  const _MenuItem({required this.icon, required this.label});
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                    color: Color(0xFF1A2340),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  )),
              const SizedBox(height: 2),
              Text(value,
                  style:
                      const TextStyle(color: Color(0xFF9E9E9E), fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }
}

class _MenuRow extends StatelessWidget {
  final _MenuItem item;
  final String? name;
  final String? regNumber;
  final String? address;
  final String? contact;
  final String? email;
  final String? avatarUrl; // ✅ renamed from profileImageUrl
  final VoidCallback
      onProfileUpdated; // ✅ callback instead of findAncestorStateOfType

  const _MenuRow({
    required this.item,
    required this.onProfileUpdated,
    this.name,
    this.regNumber,
    this.address,
    this.contact,
    this.email,
    this.avatarUrl,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (item.label == 'Edit Profile') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EditHospitalProfileScreen(
                initialData: {
                  'name': name,
                  'regNumber': regNumber,
                  'address': address,
                  'contact': contact,
                  'email': email,
                  // ✅ FIX 4: key must be 'avatarUrl' — that's what
                  // EditHospitalProfileScreen reads in initState
                  'avatarUrl': avatarUrl,
                },
              ),
            ),
          ).then((result) {
            // ✅ FIX 5: use callback — safer than findAncestorStateOfType
            if (result == true) onProfileUpdated();
          });
        } else if (item.label == 'Change Password') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Change Password — coming soon')),
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2F7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(item.icon, color: const Color(0xFF6B7280), size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(item.label,
                  style: const TextStyle(
                    color: Color(0xFF1A2340),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  )),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: Color(0xFFB0BEC5), size: 20),
          ],
        ),
      ),
    );
  }
}

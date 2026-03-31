import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'HospitalDashboardScreen.dart';
import 'PatientRequestsScreen.dart';
import 'NotificationsScreen.dart';
import 'HospitalProfileScreen.dart';

// ── Model ────────────────────────────────────────────────────────────────────

class _Donor {
  final String id;
  final String name;
  final String bloodType;
  final String distance;
  final String lastDonation;
  final String status;     // "Eligible" | "On Cool-Down"
  final bool available;
  final String? avatarUrl;

  const _Donor({
    required this.id,
    required this.name,
    required this.bloodType,
    required this.distance,
    required this.lastDonation,
    required this.status,
    required this.available,
    this.avatarUrl,
  });

  factory _Donor.fromJson(Map<String, dynamic> j) => _Donor(
        id:           j['id']?.toString()          ?? '',
        name:         j['name']?.toString()         ?? 'Unknown',
        bloodType:    j['bloodType']?.toString()    ?? '?',
        distance:     j['distance']?.toString()     ?? '',
        lastDonation: j['lastDonation']?.toString() ?? 'No record',
        status:       j['status']?.toString()       ?? 'Eligible',
        available:    j['available'] == true,
        avatarUrl:    j['avatarUrl']?.toString(),
      );
}

// ── Screen ───────────────────────────────────────────────────────────────────

class AvailableDonorsScreen extends StatefulWidget {
  const AvailableDonorsScreen({super.key});

  @override
  State<AvailableDonorsScreen> createState() => _AvailableDonorsScreenState();
}

class _AvailableDonorsScreenState extends State<AvailableDonorsScreen> {
  static const int _tabIndex = 2;

  final _searchController = TextEditingController();
  String _selectedBloodType = 'All';

  bool _isLoading  = true;
  String? _error;
  List<_Donor> _donors = [];

  // ── Blood type filter chips
  final List<String> _bloodTypeFilters = [
    'All', 'A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'
  ];

  @override
  void initState() {
    super.initState();
    _loadDonors();
    _searchController.addListener(() {
      // Debounce: just reload on every change for simplicity
      _loadDonors();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── API calls ─────────────────────────────────────────────────────────────

  Future<void> _loadDonors() async {
    setState(() { _isLoading = true; _error = null; });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token') ?? '';

      final queryParams = {
        if (_selectedBloodType != 'All') 'bloodType': _selectedBloodType,
        if (_searchController.text.trim().isNotEmpty) 'search': _searchController.text.trim(),
      };

      final uri = Uri.parse('http://192.168.1.6:3000/hospital/donors')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      }).timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _donors = (data['donors'] as List? ?? [])
              .map((d) => _Donor.fromJson(d))
              .toList();
          _isLoading = false;
        });
      } else {
        setState(() { _error = 'Failed to load donors (${response.statusCode})'; _isLoading = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _error = 'Connection error: $e'; _isLoading = false; });
    }
  }

  Future<void> _sendDonationRequest({
    required _Donor donor,
    required String requestTitle,
    required String units,
    required String donationType,
    required String notes,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token') ?? '';

      final response = await http.post(
        Uri.parse('http://192.168.1.6:3000/hospital/request-donation'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'donorId':      donor.id,
          'requestTitle': requestTitle,
          'units':        units,
          'donationType': donationType,
          'notes':        notes,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Donation request sent to ${donor.name}!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        _loadDonors(); // refresh status
      } else {
        final body = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: ${body['error'] ?? response.body}'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connection error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ── Request donation dialog ───────────────────────────────────────────────

  void _showRequestDialog(_Donor donor) {
    final titleController = TextEditingController(text: 'Blood Donation Request');
    final unitsController = TextEditingController(text: '1');
    final notesController = TextEditingController();
    String donationType = 'Whole Blood';
    bool sending = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInner) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: const EdgeInsets.all(20),
          title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F0FE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(child: Text(donor.bloodType,
                  style: const TextStyle(color: Color(0xFF2979FF), fontSize: 14, fontWeight: FontWeight.w800))),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(donor.name,
                  style: const TextStyle(color: Color(0xFF1A2340), fontSize: 15, fontWeight: FontWeight.w700)),
                Text(donor.distance,
                  style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 12)),
              ])),
            ]),
            const SizedBox(height: 4),
            const Divider(),
          ]),
          content: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              const _DialogLabel('REQUEST TITLE'),
              _DialogInput(controller: titleController, hint: 'e.g. Urgent Blood Needed'),
              const SizedBox(height: 12),

              const _DialogLabel('DONATION TYPE'),
              DropdownButtonFormField<String>(
                value: donationType,
                decoration: InputDecoration(
                  filled: true, fillColor: const Color(0xFFF5F7FA),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFDDE3ED))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFDDE3ED))),
                ),
                items: ['Whole Blood', 'Plasma', 'Platelets', 'Red Cells']
                    .map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 13))))
                    .toList(),
                onChanged: (v) => setInner(() => donationType = v!),
              ),
              const SizedBox(height: 12),

              const _DialogLabel('UNITS / AMOUNT'),
              _DialogInput(controller: unitsController, hint: 'e.g. 350 ml or 1',
                keyboardType: TextInputType.text),
              const SizedBox(height: 12),

              const _DialogLabel('NOTES (optional)'),
              TextField(
                controller: notesController,
                maxLines: 3,
                style: const TextStyle(fontSize: 13, color: Color(0xFF1A2340)),
                decoration: InputDecoration(
                  hintText: 'Any special instructions...',
                  hintStyle: const TextStyle(color: Color(0xFFB0BEC5), fontSize: 13),
                  filled: true, fillColor: const Color(0xFFF5F7FA),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFDDE3ED))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFDDE3ED))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF2979FF), width: 1.5)),
                ),
              ),
            ]),
          ),
          actions: [
            TextButton(
              onPressed: sending ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF6B7280))),
            ),
            ElevatedButton(
              onPressed: sending ? null : () async {
                setInner(() => sending = true);
                Navigator.pop(ctx);
                await _sendDonationRequest(
                  donor: donor,
                  requestTitle: titleController.text.trim().isEmpty
                      ? 'Blood Donation Request' : titleController.text.trim(),
                  units:        unitsController.text.trim().isEmpty ? '1' : unitsController.text.trim(),
                  donationType: donationType,
                  notes:        notesController.text.trim(),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2979FF),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: sending
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Send Request',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Navigation ────────────────────────────────────────────────────────────

  void _navigate(int i) {
    if (i == _tabIndex) return;
    Widget screen;
    switch (i) {
      case 0: screen = const HospitalDashboardScreen(); break;
      case 1: screen = const PatientRequestsScreen(); break;
      case 3: screen = const NotificationsScreen(); break;
      case 4: screen = const HospitalProfileScreen(); break;
      default: return;
    }
    Navigator.pushReplacement(context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => screen,
          transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 180),
        ));
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Split into top (eligible) and others
    final eligible = _donors.where((d) => d.available && d.status == 'Eligible').toList();
    final others   = _donors.where((d) => !(d.available && d.status == 'Eligible')).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFECEFF4),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadDonors,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 14),
                      _buildSearchBar(),
                      const SizedBox(height: 12),
                      _buildBloodTypeFilter(),
                      const SizedBox(height: 22),

                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 60),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (_error != null)
                        _buildErrorState()
                      else if (_donors.isEmpty)
                        _buildEmptyState()
                      else ...[
                        // Top eligible donors
                        if (eligible.isNotEmpty) ...[
                          _buildSectionHeader(
                            title: 'Top Nearby Donors',
                            badge: '${eligible.length} Eligible',
                            badgeColor: const Color(0xFF43A047),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            height: 210,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: eligible.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 12),
                              itemBuilder: (_, i) => _TopDonorCard(
                                donor: eligible[i],
                                onRequest: () => _showRequestDialog(eligible[i]),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Other donors
                        if (others.isNotEmpty) ...[
                          _buildSectionHeader(title: 'Other Donors'),
                          const SizedBox(height: 14),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
                                  blurRadius: 10, offset: const Offset(0, 2))],
                            ),
                            child: Column(
                              children: others.map((d) => Column(children: [
                                _OtherDonorRow(
                                  donor: d,
                                  onRequest: d.available ? () => _showRequestDialog(d) : null,
                                ),
                                if (d != others.last)
                                  const Divider(color: Color(0xFFEEF2F7), height: 1, indent: 16, endIndent: 16),
                              ])).toList(),
                            ),
                          ),
                        ],
                      ],

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _AppBottomNav(currentIndex: _tabIndex, onTap: _navigate),
    );
  }

  // ── Sub-widgets ───────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(children: [
        GestureDetector(
          onTap: () => _navigate(0),
          child: Container(width: 40, height: 40,
            decoration: const BoxDecoration(color: Color(0xFFDDE8FA), shape: BoxShape.circle),
            child: const Icon(Icons.arrow_back, color: Color(0xFF2979FF), size: 20)),
        ),
        const Expanded(child: Center(
          child: Text('Available Donors',
              style: TextStyle(color: Color(0xFF1A2340), fontSize: 20, fontWeight: FontWeight.w800)),
        )),
        // Refresh button
        GestureDetector(
          onTap: _loadDonors,
          child: Container(width: 40, height: 40,
            decoration: const BoxDecoration(color: Color(0xFFDDE8FA), shape: BoxShape.circle),
            child: const Icon(Icons.refresh_rounded, color: Color(0xFF2979FF), size: 20)),
        ),
      ]),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 50,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Color(0xFF1A2340), fontSize: 14),
        decoration: const InputDecoration(
          hintText: 'Search donors by name',
          hintStyle: TextStyle(color: Color(0xFFB0BEC5), fontSize: 14),
          prefixIcon: Icon(Icons.search, color: Color(0xFFB0BEC5), size: 20),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildBloodTypeFilter() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _bloodTypeFilters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final bt = _bloodTypeFilters[i];
          final selected = bt == _selectedBloodType;
          return GestureDetector(
            onTap: () {
              setState(() => _selectedBloodType = bt);
              _loadDonors();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF2979FF) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: selected ? const Color(0xFF2979FF) : const Color(0xFFDDE3ED)),
                boxShadow: selected ? [BoxShadow(color: const Color(0xFF2979FF).withOpacity(0.25),
                    blurRadius: 8, offset: const Offset(0, 2))] : [],
              ),
              child: Center(child: Text(bt,
                style: TextStyle(
                  color: selected ? Colors.white : const Color(0xFF6B7280),
                  fontSize: 13, fontWeight: selected ? FontWeight.w700 : FontWeight.w500))),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader({required String title, String? badge, Color? badgeColor}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(title, style: const TextStyle(color: Color(0xFF1A2340), fontSize: 18, fontWeight: FontWeight.w800)),
      if (badge != null)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: (badgeColor ?? const Color(0xFF2979FF)).withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(badge, style: TextStyle(
            color: badgeColor ?? const Color(0xFF2979FF),
            fontSize: 12, fontWeight: FontWeight.w600)),
        ),
    ]);
  }

  Widget _buildEmptyState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 60),
      child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.people_outline, size: 56, color: Color(0xFFB0BEC5)),
        SizedBox(height: 12),
        Text('No donors found', style: TextStyle(color: Color(0xFF6B7280), fontSize: 15, fontWeight: FontWeight.w600)),
        SizedBox(height: 4),
        Text('Try a different filter or search term',
            style: TextStyle(color: Color(0xFFB0BEC5), fontSize: 13)),
      ])),
    );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.error_outline_rounded, size: 56, color: Colors.redAccent),
        const SizedBox(height: 12),
        Text(_error ?? 'Something went wrong',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.redAccent, fontSize: 14)),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _loadDonors,
          icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
        ),
      ])),
    );
  }
}

// ── Top donor card (horizontal scroll) ───────────────────────────────────────

class _TopDonorCard extends StatelessWidget {
  final _Donor donor;
  final VoidCallback onRequest;
  const _TopDonorCard({required this.donor, required this.onRequest});

  @override
  Widget build(BuildContext context) {
    final cardWidth = MediaQuery.of(context).size.width - 48.0;
    return Container(
      width: cardWidth,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          _Avatar(url: donor.avatarUrl, size: 52),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(donor.name,
                style: const TextStyle(color: Color(0xFF1A2340), fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 3),
            Row(children: [
              const Icon(Icons.location_on_outlined, size: 12, color: Color(0xFF9E9E9E)),
              const SizedBox(width: 3),
              Text(donor.distance, style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 12)),
            ]),
          ])),
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(color: const Color(0xFFE8F0FE), borderRadius: BorderRadius.circular(10)),
            child: Center(child: Text(donor.bloodType,
                style: const TextStyle(color: Color(0xFF2979FF), fontSize: 13, fontWeight: FontWeight.w800))),
          ),
        ]),
        const SizedBox(height: 14),
        const Divider(color: Color(0xFFEEF2F7), height: 1),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('LAST DONATION',
                style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
            const SizedBox(height: 3),
            Text(donor.lastDonation,
                style: const TextStyle(color: Color(0xFF1A2340), fontSize: 13, fontWeight: FontWeight.w600)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('STATUS',
                style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
            const SizedBox(height: 3),
            Text(donor.status,
                style: TextStyle(
                  color: donor.status == 'Eligible' ? const Color(0xFF43A047) : const Color(0xFFFB8C00),
                  fontSize: 13, fontWeight: FontWeight.w700)),
          ]),
        ]),
        const Spacer(),
        SizedBox(
          width: double.infinity, height: 44,
          child: ElevatedButton(
            onPressed: onRequest,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2979FF), elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Request Donation',
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
          ),
        ),
      ]),
    );
  }
}

// ── Other donor row (list) ────────────────────────────────────────────────────

class _OtherDonorRow extends StatelessWidget {
  final _Donor donor;
  final VoidCallback? onRequest;
  const _OtherDonorRow({required this.donor, this.onRequest});

  @override
  Widget build(BuildContext context) {
    final canRequest = onRequest != null;
    final statusColor = donor.status == 'Eligible'
        ? const Color(0xFF43A047) : const Color(0xFFFB8C00);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(children: [
        _Avatar(url: donor.avatarUrl, size: 52),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(donor.name,
                style: const TextStyle(color: Color(0xFF1A2340), fontSize: 14, fontWeight: FontWeight.w700))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFFE8F0FE), borderRadius: BorderRadius.circular(8)),
              child: Text(donor.bloodType,
                  style: const TextStyle(color: Color(0xFF2979FF), fontSize: 12, fontWeight: FontWeight.w800)),
            ),
          ]),
          const SizedBox(height: 3),
          Row(children: [
            const Icon(Icons.access_time_rounded, size: 11, color: Color(0xFF9E9E9E)),
            const SizedBox(width: 4),
            Text('${donor.lastDonation} • ${donor.distance}',
                style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 11)),
          ]),
          const SizedBox(height: 6),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(donor.status.toUpperCase(),
                  style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.4)),
            ),
            // Request button
            GestureDetector(
              onTap: onRequest,
              child: Row(children: [
                Text('Request',
                    style: TextStyle(
                      color: canRequest ? const Color(0xFF2979FF) : const Color(0xFFB0BEC5),
                      fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(width: 2),
                Icon(Icons.chevron_right_rounded, size: 16,
                    color: canRequest ? const Color(0xFF2979FF) : const Color(0xFFB0BEC5)),
              ]),
            ),
          ]),
        ])),
      ]),
    );
  }
}

// ── Avatar widget ─────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String? url;
  final double size;
  const _Avatar({this.url, required this.size});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size / 2),
      child: url != null && url!.isNotEmpty
          ? Image.network(url!, width: size, height: size, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _fallback())
          : _fallback(),
    );
  }

  Widget _fallback() => Container(
    width: size, height: size,
    color: const Color(0xFFDDE8FA),
    child: const Icon(Icons.person, color: Color(0xFF2979FF)),
  );
}

// ── Dialog helpers ────────────────────────────────────────────────────────────

class _DialogLabel extends StatelessWidget {
  final String text;
  const _DialogLabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text,
      style: const TextStyle(color: Color(0xFF9AA3B0), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.6)),
  );
}

class _DialogInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  const _DialogInput({required this.controller, required this.hint, this.keyboardType});
  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    keyboardType: keyboardType,
    style: const TextStyle(color: Color(0xFF1A2340), fontSize: 13),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFB0BEC5), fontSize: 13),
      filled: true, fillColor: const Color(0xFFF5F7FA),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFDDE3ED))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFDDE3ED))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF2979FF), width: 1.5)),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// Bottom Nav (unchanged)
// ═══════════════════════════════════════════════════════════════════════════════

class _AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _AppBottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, -2))]),
      child: SafeArea(top: false,
        child: SizedBox(height: 64,
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _navItem(0, Icons.dashboard_rounded, 'DASHBOARD'),
            _navItem(1, Icons.description_outlined, 'REQUESTS'),
            _donorsItem(),
            _navItemWithDot(3, Icons.notifications_outlined, 'NOTIFICATIONS'),
            _profileItem(),
          ]),
        ),
      ),
    );
  }

  Widget _navItem(int i, IconData icon, String label) {
    final sel = i == currentIndex;
    return GestureDetector(onTap: () => onTap(i), behavior: HitTestBehavior.opaque,
      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: sel ? const Color(0xFF2979FF) : const Color(0xFFB0BEC5), size: 22),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(color: sel ? const Color(0xFF2979FF) : const Color(0xFFB0BEC5),
              fontSize: 8, fontWeight: sel ? FontWeight.w700 : FontWeight.w400, letterSpacing: 0.3)),
        ])));
  }

  Widget _navItemWithDot(int i, IconData icon, String label) {
    final sel = i == currentIndex;
    return GestureDetector(onTap: () => onTap(i), behavior: HitTestBehavior.opaque,
      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Stack(clipBehavior: Clip.none, children: [
            Icon(icon, color: sel ? const Color(0xFF2979FF) : const Color(0xFFB0BEC5), size: 22),
            Positioned(right: -2, top: -2,
                child: Container(width: 7, height: 7,
                    decoration: const BoxDecoration(color: Color(0xFFE53935), shape: BoxShape.circle))),
          ]),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(color: sel ? const Color(0xFF2979FF) : const Color(0xFFB0BEC5),
              fontSize: 8, fontWeight: sel ? FontWeight.w700 : FontWeight.w400, letterSpacing: 0.3)),
        ])));
  }

  Widget _donorsItem() {
    final sel = 2 == currentIndex;
    return GestureDetector(onTap: () => onTap(2), behavior: HitTestBehavior.opaque,
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(width: 50, height: 50,
          decoration: BoxDecoration(color: const Color(0xFF2979FF), shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: const Color(0xFF2979FF).withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 4))]),
          child: const Icon(Icons.water_drop_rounded, color: Colors.white, size: 22)),
        const SizedBox(height: 3),
        Text('DONORS', style: TextStyle(color: sel ? const Color(0xFF2979FF) : const Color(0xFFB0BEC5),
            fontSize: 8, fontWeight: sel ? FontWeight.w700 : FontWeight.w400, letterSpacing: 0.3)),
      ]));
  }

  Widget _profileItem() {
    final sel = 4 == currentIndex;
    return GestureDetector(onTap: () => onTap(4), behavior: HitTestBehavior.opaque,
      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          sel ? Container(width: 34, height: 34,
              decoration: const BoxDecoration(color: Color(0xFF2979FF), shape: BoxShape.circle),
              child: const Icon(Icons.person_rounded, color: Colors.white, size: 20))
              : const Icon(Icons.person_outline_rounded, color: Color(0xFFB0BEC5), size: 22),
          const SizedBox(height: 3),
          Text('PROFILE', style: TextStyle(color: sel ? const Color(0xFF2979FF) : const Color(0xFFB0BEC5),
              fontSize: 8, fontWeight: sel ? FontWeight.w700 : FontWeight.w400, letterSpacing: 0.3)),
        ])));
  }
}
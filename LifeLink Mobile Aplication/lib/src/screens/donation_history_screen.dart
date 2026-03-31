import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:lifelink_app/src/utils/auth_helper.dart';

const String baseUrl = 'http://10.168.30.196:3000';

class DonationHistoryScreen extends StatefulWidget {
  const DonationHistoryScreen({super.key});

  @override
  State<DonationHistoryScreen> createState() => _DonationHistoryScreenState();
}

class _DonationHistoryScreenState extends State<DonationHistoryScreen> {
  List<dynamic> _allDonations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllDonations();
  }

  Future<void> _loadAllDonations() async {
    final token = await AuthHelper.getToken();
    if (token == null || token.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/donations/my-donations'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _allDonations = data['donations'] ?? [];
        });
      }
    } catch (e) {
      print('Error loading all donations: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Donation History'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF1A2340),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _allDonations.isEmpty
              ? const Center(child: Text('No donation history found'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _allDonations.length,
                  itemBuilder: (context, index) {
                    final d = _allDonations[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const Icon(Icons.history,
                            color: Color(0xFF2979FF), size: 40),
                        title: Text('${d['donationType']} • ${d['date']}'),
                        subtitle: Text('${d['hospitalName']} • ${d['units']}'),
                        trailing: Text(d['status'] ?? 'Confirmed',
                            style: const TextStyle(color: Colors.green)),
                      ),
                    );
                  },
                ),
    );
  }
}

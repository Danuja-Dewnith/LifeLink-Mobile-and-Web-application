import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'HospitalDashboardScreen.dart';
import '../models/blood_stock.dart';

class UpdateBloodStockScreen extends StatefulWidget {
  final List<BloodStock> currentStocks;

  const UpdateBloodStockScreen({super.key, required this.currentStocks});

  @override
  State<UpdateBloodStockScreen> createState() => _UpdateBloodStockScreenState();
}

class _UpdateBloodStockScreenState extends State<UpdateBloodStockScreen> {
  // ✅ Use a separate controller map to avoid rebuilding controllers on setState
  final Map<String, TextEditingController> _controllers = {};
  late List<BloodStock> stocks;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Deep copy stocks so we don't mutate the dashboard list
    stocks = widget.currentStocks
        .map((s) => BloodStock(s.type, s.units, s.label, s.level))
        .toList();

    // Create one controller per stock, pre-filled with current units
    for (final s in stocks) {
      _controllers[s.type] = TextEditingController(text: s.units.toString());
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Save ─────────────────────────────────────────────────────────────────

  Future<void> _saveAllChanges() async {
    setState(() => _isSaving = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null || token.isEmpty) {
        _showSnack('Not logged in. Please login again.', Colors.red);
        return;
      }

      bool allSuccess = true;

      for (var stock in stocks) {
        final unitsText = _controllers[stock.type]?.text.trim() ?? '0';
        final units = int.tryParse(unitsText) ?? 0;

        print("Sending: '${stock.type}' - $units");

        // ✅ FIX: Updated endpoint to /hospital/blood-stock
        final response = await http.put(
          Uri.parse('http://10.168.30.196:3000/hospital/blood-stock'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'bloodType': stock.type.trim().toUpperCase(),
            'units': units,
          }),
        );

        print(
            "Response [${stock.type}]: ${response.statusCode} - ${response.body}");

        if (response.statusCode != 200 && response.statusCode != 201) {
          allSuccess = false;
          print("❌ Failed for ${stock.type}: ${response.body}");
        }
      }

      if (!mounted) return;

      if (allSuccess) {
        _showSnack('✅ All blood stocks updated successfully!', Colors.green);
        Navigator.pop(context, true); // ← tells dashboard to refresh
      } else {
        _showSnack(
            '⚠️ Some stocks may not have saved. Please retry.', Colors.orange);
      }
    } catch (e) {
      if (mounted) _showSnack('Connection error: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(msg),
          backgroundColor: color,
          duration: const Duration(seconds: 3)),
    );
  }

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECEFF4),
      appBar: AppBar(
        title: const Text(
          'Update Blood Stock',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A2340),
        elevation: 0,
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Summary header
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Text(
              '${stocks.length} blood types · tap a field to edit units',
              style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 12),
            ),
          ),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: stocks.length,
              itemBuilder: (context, index) =>
                  _buildStockCard(stocks[index], index),
            ),
          ),

          // Save button
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveAllChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2979FF),
                  disabledBackgroundColor: const Color(0xFFB0C4DE),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5),
                          ),
                          SizedBox(width: 12),
                          Text('Saving...',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700)),
                        ],
                      )
                    : const Text(
                        'Save All Changes',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockCard(BloodStock stock, int index) {
    final controller = _controllers[stock.type]!;

    // Color logic based on current units
    final units = int.tryParse(controller.text) ?? stock.units;
    final statusColor = units <= 5
        ? const Color(0xFFE53935)
        : units <= 10
            ? const Color(0xFFFB8C00)
            : const Color(0xFF43A047);

    final bgColor = units <= 5
        ? const Color(0xFFFFF5F5)
        : units <= 10
            ? const Color(0xFFFFF8F0)
            : const Color(0xFFF1F8F1);

    final statusLabel = units <= 5
        ? 'CRITICAL'
        : units <= 10
            ? 'LOW'
            : 'NORMAL';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: statusColor.withOpacity(0.25)),
      ),
      color: bgColor,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Blood type badge
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: statusColor.withOpacity(0.3)),
              ),
              child: Center(
                child: Text(
                  stock.type,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Units Available',
                    style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  // Units input
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      filled: true,
                      fillColor: Colors.white,
                      suffixText: 'units',
                      suffixStyle: TextStyle(
                          color: statusColor.withOpacity(0.6), fontSize: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            BorderSide(color: statusColor.withOpacity(0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            BorderSide(color: statusColor.withOpacity(0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: statusColor, width: 1.5),
                      ),
                    ),
                    onChanged: (value) {
                      // Re-render the card with updated color
                      setState(() {});
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  StatusLevel _getStatusLevel(int units) {
    if (units > 15) return StatusLevel.normal;
    if (units > 5) return StatusLevel.low;
    return StatusLevel.critical;
  }
}

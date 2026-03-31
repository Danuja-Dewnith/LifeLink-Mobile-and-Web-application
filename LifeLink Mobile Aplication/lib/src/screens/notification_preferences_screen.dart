import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends State<NotificationPreferencesScreen> {
  bool _bloodRequestAlerts = true;
  bool _donationReminders = true;
  bool _appUpdates = false;
  bool _emailNotifications = true;
  bool _isSaving = false;

  static const String _prefKey = 'notification_prefs';

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _bloodRequestAlerts = prefs.getBool('notif_blood_requests') ?? true;
      _donationReminders = prefs.getBool('notif_donation_reminders') ?? true;
      _appUpdates = prefs.getBool('notif_app_updates') ?? false;
      _emailNotifications = prefs.getBool('notif_email') ?? true;
    });
  }

  Future<void> _savePreferences() async {
    setState(() => _isSaving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notif_blood_requests', _bloodRequestAlerts);
      await prefs.setBool('notif_donation_reminders', _donationReminders);
      await prefs.setBool('notif_app_updates', _appUpdates);
      await prefs.setBool('notif_email', _emailNotifications);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification preferences saved!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving preferences: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
                        'Notification Preferences',
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

                    // Push Notifications Card
                    _NotifCard(
                      icon: Icons.notifications_active_outlined,
                      iconColor: const Color(0xFF2979FF),
                      title: 'Push Notifications',
                      children: [
                        _NotifToggleRow(
                          icon: Icons.water_drop_rounded,
                          iconColor: const Color(0xFFE53935),
                          title: 'Blood Request Alerts',
                          subtitle:
                              'Get notified when blood is urgently needed',
                          value: _bloodRequestAlerts,
                          onChanged: (val) =>
                              setState(() => _bloodRequestAlerts = val),
                        ),
                        const Divider(color: Color(0xFFF0F2F5), height: 1),
                        _NotifToggleRow(
                          icon: Icons.volunteer_activism_rounded,
                          iconColor: const Color(0xFF4CAF50),
                          title: 'Donation Reminders',
                          subtitle: 'Reminders for upcoming donation schedules',
                          value: _donationReminders,
                          onChanged: (val) =>
                              setState(() => _donationReminders = val),
                        ),
                        const Divider(color: Color(0xFFF0F2F5), height: 1),
                        _NotifToggleRow(
                          icon: Icons.campaign_outlined,
                          iconColor: const Color(0xFFFF9800),
                          title: 'App Updates & News',
                          subtitle:
                              'Stay informed about new features and updates',
                          value: _appUpdates,
                          onChanged: (val) => setState(() => _appUpdates = val),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Email Notifications Card
                    _NotifCard(
                      icon: Icons.email_outlined,
                      iconColor: const Color(0xFF9C27B0),
                      title: 'Email Notifications',
                      children: [
                        _NotifToggleRow(
                          icon: Icons.mark_email_unread_outlined,
                          iconColor: const Color(0xFF9C27B0),
                          title: 'Email Notifications',
                          subtitle: 'Receive important updates via email',
                          value: _emailNotifications,
                          onChanged: (val) =>
                              setState(() => _emailNotifications = val),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _savePreferences,
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
                                'Save Preferences',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
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

class _NotifCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final List<Widget> children;

  const _NotifCard({
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

class _NotifToggleRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _NotifToggleRow({
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

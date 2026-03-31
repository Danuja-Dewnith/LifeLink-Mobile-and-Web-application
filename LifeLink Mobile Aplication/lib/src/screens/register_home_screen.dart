import 'package:flutter/material.dart';
import 'donor_patient_register_screen.dart';
import 'hospital_register_screen.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECEFF4),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                // ── Top bar: shield icon + LifeLink title ──────────────
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDDE8FA),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.health_and_safety_rounded,
                        color: Color(0xFF2979FF),
                        size: 26,
                      ),
                    ),
                    const Expanded(
                      child: Center(
                        child: Text(
                          'LifeLink',
                          style: TextStyle(
                            color: Color(0xFF1A2340),
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 44), // balance spacer
                  ],
                ),

                const SizedBox(height: 28),

                // ── Page heading ───────────────────────────────────────
                const Text(
                  'Create an Account',
                  style: TextStyle(
                    color: Color(0xFF1A2340),
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Select your role to continue registration',
                  style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
                ),

                const SizedBox(height: 28),

                // ── Card 1: Donor / Patient ────────────────────────────
                _RoleCard(
                  imageUrl:
                      'https://images.unsplash.com/photo-1576091160550-2173dba999ef?w=600&q=80',
                  imageBgColor: const Color(0xFFDDEEFB),
                  badgeIcon: Icons.volunteer_activism_rounded,
                  badgeColor: const Color(0xFF2979FF),
                  badgeBg: Colors.white,
                  title: 'Donor / Patient',
                  description:
                      'Register as a donor to donate blood or organs, or as a patient to request medical support.',
                  onContinue: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DonorPatientRegisterScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),

                // ── Card 2: Hospital / Blood Bank ──────────────────────
                // _RoleCard(
                //   imageUrl:
                //       'https://images.unsplash.com/photo-1586773860418-d37222d8fce3?w=600&q=80',
                //   imageBgColor: const Color(0xFFFADDDD),
                //   badgeIcon: Icons.business_rounded,
                //   badgeColor: const Color(0xFFE53935),
                //   badgeBg: Colors.white,
                //   title: 'Hospital / Blood Bank',
                //   description:
                //       'Register as a hospital or blood bank to manage blood storage, requests, and emergency alerts.',
                //   onContinue: () {
                //     Navigator.push(
                //       context,
                //       MaterialPageRoute(
                //         builder: (_) => const HospitalRegisterScreen(),
                //       ),
                //     );
                //   },
                // ),

                const SizedBox(height: 36),

                // ── Security footer ────────────────────────────────────
                const Center(
                  child: Column(
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.shield_outlined,
                            color: Color(0xFFB0BEC5),
                            size: 14,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'SECURITY VERIFIED',
                            style: TextStyle(
                              color: Color(0xFFB0BEC5),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.4,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 6),
                      Text(
                        'All registrations will be verified for safety and accuracy',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFFB0BEC5),
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Reusable Role Card widget ────────────────────────────────────────────────
class _RoleCard extends StatelessWidget {
  final String imageUrl;
  final Color imageBgColor;
  final IconData badgeIcon;
  final Color badgeColor;
  final Color badgeBg;
  final String title;
  final String description;
  final VoidCallback onContinue;

  const _RoleCard({
    required this.imageUrl,
    required this.imageBgColor,
    required this.badgeIcon,
    required this.badgeColor,
    required this.badgeBg,
    required this.title,
    required this.description,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image section with badge overlay
          Stack(
            children: [
              // Background image
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: Container(
                  height: 160,
                  width: double.infinity,
                  color: imageBgColor,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    color: imageBgColor.withOpacity(0.35),
                    colorBlendMode: BlendMode.srcOver,
                    errorBuilder: (_, __, ___) =>
                        Container(color: imageBgColor),
                  ),
                ),
              ),
              // Badge icon (bottom-left of image)
              Positioned(
                bottom: 12,
                left: 12,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: badgeBg,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Icon(badgeIcon, color: badgeColor, size: 22),
                ),
              ),
            ],
          ),

          // Text + button section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF1A2340),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),

                // Continue button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: onContinue,
                    icon: const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    label: const Text(
                      'Continue',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2979FF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

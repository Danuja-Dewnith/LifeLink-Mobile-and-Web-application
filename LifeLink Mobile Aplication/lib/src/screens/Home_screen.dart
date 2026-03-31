import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'register_home_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECEFF4),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 16),

                // ── Top row: shield icon + emergency badge ─────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(width: 48),

                    // Shield icon card
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDDE8FA),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.health_and_safety_rounded,
                        color: Color(0xFF2979FF),
                        size: 44,
                      ),
                    ),

                    // Emergency badge
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFD6D6),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text(
                          '',
                          style: TextStyle(
                            color: Color(0xFFE53935),
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // App name
                const Text(
                  'LifeLink',
                  style: TextStyle(
                    color: Color(0xFF1A2340),
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),

                const SizedBox(height: 4),

                // Subtitle
                const Text(
                  'SMART BLOOD & ORGAN DONATION SYSTEM',
                  style: TextStyle(
                    color: Color(0xFF2979FF),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                  ),
                ),

                const SizedBox(height: 20),

                // Hero image with frosted overlay
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        height: 260,
                        width: double.infinity,
                        color: const Color(0xFFB0C4DE),
                        child: Image.network(
                          'https://images.unsplash.com/photo-1615461066841-6116e61058f4?w=600&q=80',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.bloodtype_rounded,
                            color: Colors.white,
                            size: 60,
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Center(
                        child: Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.45),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.6),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 16,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.volunteer_activism_rounded,
                            color: Color(0xFF2979FF),
                            size: 64,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // Headline
                RichText(
                  textAlign: TextAlign.center,
                  text: const TextSpan(
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                      letterSpacing: -0.5,
                    ),
                    children: [
                      TextSpan(
                        text: 'Save Lives with ',
                        style: TextStyle(color: Color(0xFF1A2340)),
                      ),
                      TextSpan(
                        text: 'Smart\nDonation',
                        style: TextStyle(color: Color(0xFF2979FF)),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Description
                const Text(
                  'LifeLink connects donors, patients, hospitals, and doctors in real-time. Upload medical reports, receive emergency alerts, and help save lives faster.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),

                const SizedBox(height: 28),

                // Login button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    icon: const Icon(
                      Icons.login_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    label: const Text(
                      'Login',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2979FF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Register button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RegisterScreen(),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.person_add_rounded,
                      color: Color(0xFFE53935),
                      size: 20,
                    ),
                    label: const Text(
                      'Register',
                      style: TextStyle(
                        color: Color(0xFFE53935),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: Color(0xFFE53935),
                        width: 1.8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Footer
                const Text(
                  'Join the LifeLink network and make a difference',
                  style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 12),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

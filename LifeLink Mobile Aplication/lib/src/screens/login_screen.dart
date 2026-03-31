// login_screen.dart
import 'package:flutter/material.dart';
import 'patient_dashboard_screen.dart';
import 'register_home_screen.dart';
import 'HospitalDashboardScreen.dart';
import 'donor_dash.dart';
import '../services/auth_service.dart';
import 'forgot_password_screen.dart';
import 'admin_dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Simple email validation
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // ── Validation checks ───────────────────────────────────────────────
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter email and password'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    if (!_isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid email address'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password must be at least 6 characters'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // Start loading
    setState(() => _isLoading = true);

    try {
      // Proceed with regular authentication (no hardcoded bypass)
      final result = await AuthService.login(email, password);

      if (result != null && result['success'] == true) {
        final role = result['role'] as String?;

        if (!mounted) return;

        if (role == 'Hospital') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HospitalDashboardScreen()),
          );
        } else if (role == 'Patient') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const PatientDashboardScreen()),
          );
        } else if (role == 'Donor') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const DashboardScreen()),
          );
        } else if (role == 'Admin' || role?.toLowerCase() == 'admin') {
          // Admin role navigation
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unknown user role. Contact support.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid email or password'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login failed: Connection error or server issue'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECEFF4),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),

                // ── Logo + App name row ────────────────────────────────
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 36,
                        height: 36,
                        child: CustomPaint(painter: _MiniHealthPainter()),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'LifeLink',
                        style: TextStyle(
                          color: Color(0xFF1A2340),
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 6),

                const Center(
                  child: Text(
                    'Smart Blood & Organ Management',
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: SizedBox(
                    height: 220,
                    width: double.infinity,
                    child: Image.network(
                      'https://images.unsplash.com/photo-1612349317150-e413f6a5b16d?w=700&q=80',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFF4DB6AC),
                        child: const Icon(
                          Icons.medical_services_rounded,
                          color: Colors.white,
                          size: 60,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                const Text(
                  'Welcome Back',
                  style: TextStyle(
                    color: Color(0xFF1A2340),
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Please enter your details to sign in',
                  style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                ),

                const SizedBox(height: 24),

                const Text(
                  'Email or Username',
                  style: TextStyle(
                    color: Color(0xFF1A2340),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),

                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFDDE3ED)),
                  ),
                  child: TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style:
                        const TextStyle(color: Color(0xFF1A2340), fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'name@example.com',
                      hintStyle: TextStyle(color: Color(0xFFB0BEC5)),
                      prefixIcon: Icon(Icons.email_outlined,
                          color: Color(0xFFB0BEC5), size: 20),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                const Text(
                  'Password',
                  style: TextStyle(
                    color: Color(0xFF1A2340),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),

                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFDDE3ED)),
                  ),
                  child: TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style:
                        const TextStyle(color: Color(0xFF1A2340), fontSize: 14),
                    decoration: InputDecoration(
                      hintText: '••••••••',
                      hintStyle: const TextStyle(color: Color(0xFFB0BEC5)),
                      prefixIcon: const Icon(Icons.lock_outline_rounded,
                          color: Color(0xFFB0BEC5), size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: const Color(0xFFB0BEC5),
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),

                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ForgotPasswordScreen()),
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: Color(0xFF2979FF),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _handleLogin,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5),
                          )
                        : const Icon(Icons.login_rounded,
                            color: Colors.white, size: 20),
                    label: Text(
                      _isLoading ? 'Logging in...' : 'Login',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2979FF),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                      disabledBackgroundColor: const Color(0xFF90CAF9),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                Row(
                  children: [
                    const Expanded(
                        child: Divider(color: Color(0xFFCDD5DF), thickness: 1)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'OR',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const Expanded(
                        child: Divider(color: Color(0xFFCDD5DF), thickness: 1)),
                  ],
                ),

                const SizedBox(height: 20),

                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Don't have an account?  ",
                        style:
                            TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const RegisterScreen()),
                          );
                        },
                        child: const Text(
                          'Register here',
                          style: TextStyle(
                            color: Color(0xFFE53935),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.shield_outlined,
                          color: Color(0xFFB0BEC5), size: 14),
                      SizedBox(width: 6),
                      Text(
                        'SECURE LOGIN TO ACCESS DONATION SERVICES',
                        style: TextStyle(
                          color: Color(0xFFB0BEC5),
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
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

class _MiniHealthPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2979FF)
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;
    final t = w / 3;

    canvas.drawRect(Rect.fromLTWH(0, t, w, t), paint);
    canvas.drawRect(Rect.fromLTWH(t, 0, t, h), paint);

    final linePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.1
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final midY = h / 2;
    path.moveTo(w * 0.05, midY);
    path.lineTo(w * 0.28, midY);
    path.lineTo(w * 0.38, midY - h * 0.22);
    path.lineTo(w * 0.48, midY + h * 0.22);
    path.lineTo(w * 0.58, midY);
    path.lineTo(w * 0.95, midY);
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

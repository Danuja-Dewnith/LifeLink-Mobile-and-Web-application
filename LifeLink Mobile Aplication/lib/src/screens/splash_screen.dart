import 'package:flutter/material.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _progressController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();

    // Fade-in for logo + text
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();

    // Progress bar animation — runs over 5 seconds
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _progressAnimation = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    );
    _progressController.forward();

    // Auto-navigate to HomeScreen after 5 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const HomeScreen(),
            transitionsBuilder: (_, animation, __, child) =>
                FadeTransition(opacity: animation, child: child),
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECEFF4),
      body: SafeArea(
        child: Column(
          children: [
            // ── Top section: logo + title ──────────────────────────────
            Expanded(
              flex: 5,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App icon card with badge
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // White rounded card
                        Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Center(child: _HealthIcon(size: 68)),
                        ),
                        // Link badge (bottom-right)
                        Positioned(
                          bottom: -10,
                          right: -10,
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: const BoxDecoration(
                              color: Color(0xFF2979FF),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0x442979FF),
                                  blurRadius: 12,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.link_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 36),

                    // LifeLink wordmark
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                        children: [
                          TextSpan(
                            text: 'Life',
                            style: TextStyle(color: Color(0xFF1A2340)),
                          ),
                          TextSpan(
                            text: 'Link',
                            style: TextStyle(color: Color(0xFF2979FF)),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Tagline
                    const Text(
                      'Saving Lives Through Smart Donation',
                      style: TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Bottom section: spinner + status bar ──────────────────
            Expanded(
              flex: 2,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Circular progress indicator
                    const SizedBox(
                      width: 36,
                      height: 36,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFFB0BEC5),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // "INITIALISING" label
                    const Text(
                      'INITIALISING',
                      style: TextStyle(
                        color: Color(0xFFB0BEC5),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2.5,
                      ),
                    ),

                    const SizedBox(height: 28),

                    // System status row + progress bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'SYSTEM STATUS',
                                style: TextStyle(
                                  color: Color(0xFF9E9E9E),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.8,
                                ),
                              ),
                              Text(
                                'Secure Connection Active',
                                style: TextStyle(
                                  color: Color(0xFF2979FF),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Animated progress bar
                          AnimatedBuilder(
                            animation: _progressAnimation,
                            builder: (context, _) {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: _progressAnimation.value,
                                  minHeight: 4,
                                  backgroundColor: const Color(0xFFCDD5DF),
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                        Color(0xFF2979FF),
                                      ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
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

/// Custom painter that draws the medical cross with an ECG pulse line through it.
class _HealthIcon extends StatelessWidget {
  final double size;
  const _HealthIcon({required this.size});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size(size, size), painter: _HealthIconPainter());
  }
}

class _HealthIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2979FF)
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    final crossThird = w / 3;

    // Horizontal bar
    canvas.drawRect(Rect.fromLTWH(0, crossThird, w, crossThird), paint);
    // Vertical bar
    canvas.drawRect(Rect.fromLTWH(crossThird, 0, crossThird, h), paint);

    // ECG pulse line cutout
    final cutPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.09
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

    canvas.drawPath(path, cutPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

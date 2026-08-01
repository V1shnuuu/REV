import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/ollama_service.dart';
import '../constants/app_config.dart';
import '../widgets/disclaimer_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _breatheController;
  late AnimationController _fadeInController;
  final OllamaService _ollama = OllamaService();
  bool _ollamaAvailable = false;
  bool _disclaimerShown = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    _fadeInController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _checkOllama();
  }

  Future<void> _checkOllama() async {
    final available = await _ollama.checkAvailability();
    if (mounted) {
      setState(() => _ollamaAvailable = available);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _breatheController.dispose();
    _fadeInController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_disclaimerShown) {
      _disclaimerShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        DisclaimerDialog.show(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: FadeTransition(
        opacity: _fadeInController,
        child: Stack(
          children: [
            // Animated background gradient
            AnimatedBuilder(
              animation: _breatheController,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 1.2 + (_breatheController.value * 0.3),
                      colors: [
                        const Color(0xFFE63946).withValues(alpha: 0.08),
                        const Color(0xFF0A0A0F),
                      ],
                    ),
                  ),
                );
              },
            ),

            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 40),

                  // App title
                  Text(
                    'REVIVE',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE63946).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFE63946).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      'EVERY SECOND COUNTS. EVERY LIFE MATTERS.',
                      style: GoogleFonts.inter(
                        color: const Color(0xFFFF6B6B),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Main START button
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      final scale = 1.0 + (_pulseController.value * 0.05);
                      final glowOpacity = 0.3 + (_pulseController.value * 0.3);

                      return GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, '/triage');
                        },
                        child: Transform.scale(
                          scale: scale,
                          child: Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const RadialGradient(
                                colors: [
                                  Color(0xFFFF4757),
                                  Color(0xFFE63946),
                                  Color(0xFFC0392B),
                                ],
                                center: Alignment(-0.2, -0.3),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFE63946)
                                      .withValues(alpha: glowOpacity),
                                  blurRadius: 50,
                                  spreadRadius: 15,
                                ),
                                BoxShadow(
                                  color: const Color(0xFFE63946)
                                      .withValues(alpha: glowOpacity * 0.5),
                                  blurRadius: 100,
                                  spreadRadius: 30,
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.favorite,
                                  color: Colors.white,
                                  size: 48,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'START',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 4,
                                  ),
                                ),
                                Text(
                                  'CPR',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 32),

                  // Secondary Training Mode Button
                  OutlinedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/guide');
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.school, color: Colors.white70, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'TRAINING MODE',
                          style: GoogleFonts.inter(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Ask Gemma Chat Button
                  OutlinedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/chat');
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      side: BorderSide(color: const Color(0xFFE63946).withValues(alpha: 0.5)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      backgroundColor: const Color(0xFFE63946).withValues(alpha: 0.08),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.smart_toy, color: const Color(0xFFFF6B6B), size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'ASK GEMMA',
                          style: GoogleFonts.inter(
                            color: const Color(0xFFFF6B6B),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Bottom disclaimer
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.white.withValues(alpha: 0.3),
                            size: 18,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'For guidance only. Not a substitute for professional training. Always call ${AppConfig.emergencyNumber} first.',
                              style: GoogleFonts.inter(
                                color: Colors.white.withValues(alpha: 0.3),
                                fontSize: 11,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

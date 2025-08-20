import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'home_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});
  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _bg, _logoScale, _logoFade, _titleSlide, _titleFade, _bar;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400));
    _bg        = CurvedAnimation(parent: _c, curve: const Interval(0.00, 1.00, curve: Curves.easeInOut));
    _logoScale = CurvedAnimation(parent: _c, curve: const Interval(0.05, 0.45, curve: Curves.easeOutBack));
    _logoFade  = CurvedAnimation(parent: _c, curve: const Interval(0.05, 0.45, curve: Curves.easeOut));
    _titleSlide= CurvedAnimation(parent: _c, curve: const Interval(0.35, 0.80, curve: Curves.easeOut));
    _titleFade = CurvedAnimation(parent: _c, curve: const Interval(0.35, 0.80, curve: Curves.easeOut));
    _bar       = CurvedAnimation(parent: _c, curve: const Interval(0.55, 0.95, curve: Curves.easeInOut));
    _c.forward();
    _c.addStatusListener((s) async {
      if (s == AnimationStatus.completed && mounted) {
        await Navigator.of(context).pushReplacement(PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 420),
          pageBuilder: (_, __, ___) => const HomePage(),
          transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
        ));
      }
    });
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.background,
      body: AnimatedBuilder(
        animation: _c,
        builder: (_, __) {
          return Stack(
            children: [
              Positioned.fill(child: CustomPaint(painter: _BubblesPainter(_bg.value, cs))),
              Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Transform.scale(
                    scale: _lerp(0.85, 1.0, _logoScale.value),
                    child: Opacity(
                      opacity: _logoFade.value,
                      child: Container(
                        width: 108, height: 108,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(colors: [cs.primary, cs.tertiary, cs.secondary], begin: Alignment.topLeft, end: Alignment.bottomRight),
                          boxShadow: [BoxShadow(color: cs.primary.withOpacity(0.35), blurRadius: 28, offset: Offset(0,10))],
                        ),
                        alignment: Alignment.center,
                        child: _LogoOrIcon(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Opacity(
                    opacity: _titleFade.value,
                    child: Transform.translate(
                      offset: Offset(0, 24 * (1 - _titleSlide.value)),
                      child: ShaderMask(
                        shaderCallback: (r) {
                          final dx = r.width * (_bg.value * 0.8);
                          return LinearGradient(
                            colors: [cs.onBackground, cs.primary, cs.onBackground],
                            stops: const [0.1, 0.5, 0.9],
                            begin: Alignment(-1 + dx, 0), end: Alignment(1 + dx, 0),
                          ).createShader(r);
                        },
                        blendMode: BlendMode.srcIn,
                        child: Text('English Quiz',
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: cs.onBackground),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: 220, height: 8,
                    decoration: BoxDecoration(color: cs.surfaceVariant.withOpacity(0.5), borderRadius: BorderRadius.circular(999)),
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: (_bar.value).clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [cs.primary, cs.secondary], begin: Alignment.centerLeft, end: Alignment.centerRight),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),
                ]),
              ),
            ],
          );
        },
      ),
    );
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;
}

class _LogoOrIcon extends StatelessWidget {
  final Color color;
  const _LogoOrIcon({required this.color});
  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/logo.png',
      width: 56, height: 56, fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Icon(Icons.menu_book_rounded, size: 48, color: color),
    );
  }
}

class _BubblesPainter extends CustomPainter {
  final double t; final ColorScheme cs;
  _BubblesPainter(this.t, this.cs);
  @override
  void paint(Canvas canvas, Size size) {
    final bubbles = <_Bubble>[
      _Bubble(0.15, 0.80, 80, cs.primary.withOpacity(0.20)),
      _Bubble(0.85, 0.82, 120, cs.secondary.withOpacity(0.18)),
      _Bubble(0.30, 0.25, 140, cs.tertiary.withOpacity(0.14)),
      _Bubble(0.70, 0.20, 90, cs.primary.withOpacity(0.15)),
    ];
    for (var b in bubbles) {
      final dy = math.sin((t * 2 * math.pi) + b.dx * 10) * 0.02;
      final dx = math.cos((t * 2 * math.pi) + b.dy * 10) * 0.02;
      final center = Offset((b.dx + dx) * size.width, (b.dy + dy) * size.height);
      final paint = Paint()
        ..shader = RadialGradient(colors: [b.color, b.color.withOpacity(0.0)], stops: const [0.0, 1.0])
              .createShader(Rect.fromCircle(center: center, radius: b.r));
      canvas.drawCircle(center, b.r, paint);
    }
  }
  @override
  bool shouldRepaint(covariant _BubblesPainter old) => old.t != t || old.cs != cs;
}
class _Bubble { final double dx, dy; final double r; final Color color; _Bubble(this.dx, this.dy, this.r, this.color); }

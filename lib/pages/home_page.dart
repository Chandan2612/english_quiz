// import 'dart:math' as math;
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import '../core/prefs.dart';
// import '../quiz/quiz_bloc.dart';
// import '../theme/theme_cubit.dart';
// import 'round_page.dart';

// // 👇 Single source of truth for UI: 7 questions per round
// const int kQuestionsPerRound = 7;

// class HomePage extends StatefulWidget {
//   const HomePage({super.key});
//   @override
//   State<HomePage> createState() => _HomePageState();
// }

// class _HomePageState extends State<HomePage> {
//   int _currentRound = 1; // 1..500
//   int _stage = 0; // 0..6  (drives ring progress)
//   Set<int> _completed = {};
//   int _streak = 0;

//   @override
//   void initState() {
//     super.initState();
//     _load();
//   }

//   Future<void> _load() async {
//     final r = await Prefs.getCurrentRound();
//     final s = await Prefs.getStage(r);
//     final c = await Prefs.getCompletedRounds();

//     // Clamp any old saved stage (e.g., from 10-question days)
//     final clampedStage = s < 0 ? 0 : (s >= kQuestionsPerRound ? kQuestionsPerRound - 1 : s);

//     if (!mounted) return;
//     setState(() {
//       _currentRound = r;
//       _stage = clampedStage;
//       _completed = c;
//       _streak = _calcStreak(c);
//     });
//   }

//   int _calcStreak(Set<int> done) {
//     int k = 0;
//     while (done.contains(k + 1)) k++;
//     return k;
//   }

//   Future<void> _openRound(int r) async {
//     await Prefs.setCurrentRound(r);
//     context.read<QuizBloc>().add(LoadRound(r));
//     if (!mounted) return;
//     await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RoundPage()));
//     _load(); // refresh after returning
//   }

//   @override
//   Widget build(BuildContext context) {
//     final cs = Theme.of(context).colorScheme;
//     final isDark = context.watch<ThemeCubit>().state;

//     // 🌈 Day = vibrant, Night = subtle
//     final gradientColors = isDark
//         ? [cs.surface, cs.surface]
//         : [
//             cs.primaryContainer.withOpacity(0.65),
//             cs.tertiaryContainer.withOpacity(0.60),
//             cs.secondaryContainer.withOpacity(0.65),
//           ];

//     // 📈 Progress now based on 7 questions (0..6 → up to ~86%)
//     final ringProgress = (_stage / kQuestionsPerRound).clamp(0.0, 1.0);

//     final navIconBrightness =
//         ThemeData.estimateBrightnessForColor(cs.primary) == Brightness.dark ? Brightness.light : Brightness.dark;

//     return Scaffold(
//       appBar: AppBar(
//         elevation: 0,

//         // Status bar (time/battery) + Android nav bar
//         systemOverlayStyle: SystemUiOverlayStyle(
//           // Top status bar
//           statusBarColor: Colors.white, // background
//           statusBarIconBrightness: Brightness.dark, // Android icons: dark
//           statusBarBrightness: Brightness.light, // iOS text/icons: dark

//           // Bottom nav bar (Android)
//           systemNavigationBarColor: cs.primary,
//           systemNavigationBarIconBrightness: navIconBrightness,
//         ),

//         title: const FittedBox(child: Text('Math Quiz')),
//         actions: [
//           _AliveCompletionChip(count: _completed.length, total: 500, cs: cs),
//           const SizedBox(width: 8),
//           Padding(
//             padding: const EdgeInsets.only(right: 6),
//             child: _AliveThemeButton(
//               isDark: isDark,
//               cs: cs,
//               onTap: () => context.read<ThemeCubit>().toggle(),
//               tooltip: isDark ? 'Light mode' : 'Dark mode',
//             ),
//           ),
//         ],
//       ),

//       // ✅ Full-bleed gradient via Container (tight constraints)
//       body: Container(
//         width: double.infinity,
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             colors: gradientColors,
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//           ),
//         ),
//         child: RefreshIndicator(
//           onRefresh: _load,
//           edgeOffset: 30,
//           child: LayoutBuilder(
//             builder: (context, constraints) {
//               return SingleChildScrollView(
//                 physics: const AlwaysScrollableScrollPhysics(),
//                 child: ConstrainedBox(
//                   constraints: BoxConstraints(minHeight: constraints.maxHeight),
//                   child: Padding(
//                     padding: const EdgeInsets.all(20.0),
//                     child: ConstrainedBox(
//                       constraints: const BoxConstraints(maxWidth: 720),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.stretch,
//                         children: [
//                           // 🎴 Hero Card with progress ring
//                           Container(
//                             padding: const EdgeInsets.all(20),
//                             decoration: BoxDecoration(
//                               color: cs.surface,
//                               borderRadius: BorderRadius.circular(24),
//                               boxShadow: [
//                                 BoxShadow(
//                                   color: Colors.black.withOpacity(0.12),
//                                   blurRadius: 22,
//                                   offset: const Offset(0, 10),
//                                 )
//                               ],
//                             ),
//                             child: Row(
//                               children: [
//                                 _RoundProgressRing(progress: ringProgress, cs: cs),
//                                 const SizedBox(width: 16),
//                                 Expanded(
//                                   child: Column(
//                                     crossAxisAlignment: CrossAxisAlignment.start,
//                                     children: [
//                                       Row(children: [
//                                         Icon(Icons.emoji_events_rounded, color: cs.primary),
//                                         const SizedBox(width: 6),
//                                         const Text(
//                                           'Round ',
//                                           style: TextStyle(fontSize: 0), // invisible spacer hack (keeps layout stable)
//                                         ),
//                                         Text(
//                                           'Round $_currentRound of 500',
//                                           style: const TextStyle(fontSize: 20),
//                                           maxLines: 1,
//                                           softWrap: false,
//                                         ),
//                                       ]),
//                                       const SizedBox(height: 8),
//                                       Row(children: [
//                                         Icon(Icons.timelapse_rounded, size: 18, color: cs.onSurfaceVariant),
//                                         const SizedBox(width: 6),
//                                         Text(
//                                           'Stage: Question ${_stage + 1} / $kQuestionsPerRound',
//                                           style: Theme.of(context).textTheme.bodyMedium,
//                                         ),
//                                       ]),
//                                       const SizedBox(height: 12),
//                                       LinearProgressIndicator(
//                                         value: (_completed.length / 500.0).clamp(0.0, 1.0),
//                                         backgroundColor: cs.surfaceContainerHighest.withOpacity(0.5),
//                                       ),
//                                       const SizedBox(height: 6),
//                                       Row(children: [
//                                         Icon(Icons.check_circle_outline, size: 18, color: cs.onSurfaceVariant),
//                                         const SizedBox(width: 6),
//                                         Text('Completed: ${_completed.length} rounds'),
//                                       ]),
//                                     ],
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),

//                           const SizedBox(height: 16),

//                           // 🔹 Quick Stats chips — ICON grows on tap
//                           Wrap(
//                             spacing: 10,
//                             runSpacing: 10,
//                             children: [
//                               _TapGrowStatChip(
//                                 icon: Icons.local_fire_department_rounded,
//                                 iconColor: Colors.orange,
//                                 label: 'Streak',
//                                 value: '$_streak',
//                                 cs: cs,
//                               ),
//                               _TapGrowStatChip(
//                                 icon: Icons.check_circle,
//                                 iconColor: cs.primary,
//                                 label: 'Done',
//                                 value: '${_completed.length}',
//                                 cs: cs,
//                               ),
//                               _TapGrowStatChip(
//                                 icon: Icons.timelapse,
//                                 iconColor: cs.primary,
//                                 label: 'Stage',
//                                 value: '${_stage + 1}/$kQuestionsPerRound',
//                                 cs: cs,
//                               ),
//                             ],
//                           ),

//                           const SizedBox(height: 22),

//                           // 🕑 Recently completed
//                           Row(
//                             children: [
//                               Icon(Icons.history_rounded, color: cs.primary),
//                               const SizedBox(width: 8),
//                               Text('Recently completed', style: Theme.of(context).textTheme.titleMedium),
//                             ],
//                           ),
//                           const SizedBox(height: 10),
//                           Wrap(
//                             spacing: 8,
//                             runSpacing: 8,
//                             children: _recentCompletedChips(cs),
//                           ),

//                           const SizedBox(height: 80), // space before bottom button
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//               );
//             },
//           ),
//         ),
//       ),

//       // ⬇️ Bottom Start/Continue button
//       bottomNavigationBar: SafeArea(
//         minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
//         child: SizedBox(
//           width: double.infinity,
//           child: ElevatedButton.icon(
//             icon: _AlivePlayIcon(cs: cs, size: 36),
//             label: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Text(_stage == 0 ? 'Start Round' : 'Continue Round'),
//                 const SizedBox(width: 6),
//                 Icon(Icons.chevron_right_rounded, size: 20, color: cs.onPrimary.withOpacity(0.90)),
//               ],
//             ),
//             onPressed: () async {
//               context.read<QuizBloc>().add(LoadRound(_currentRound));
//               await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RoundPage()));
//               _load();
//             },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: cs.primary,
//               foregroundColor: cs.onPrimary,
//               minimumSize: const Size.fromHeight(56),
//               elevation: 3,
//               shadowColor: cs.primary.withOpacity(0.35),
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   List<Widget> _recentCompletedChips(ColorScheme cs) {
//     final list = _completed.toList()..sort();
//     final recent = list.reversed.take(12).toList();
//     if (recent.isEmpty) {
//       return [Text('No completed rounds yet', style: TextStyle(color: cs.onSurfaceVariant))];
//     }
//     return recent.map((r) {
//       return SizedBox(
//         width: 120,
//         height: 40,
//         child: ActionChip(
//           avatar: Icon(Icons.check_circle, color: cs.primary, size: 18),
//           label: Text('Round $r'),
//           onPressed: () => _openRound(r),
//           backgroundColor: cs.surface,
//           side: BorderSide(color: cs.outlineVariant),
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         ),
//       );
//     }).toList();
//   }
// }

// // ─────────────────────────────────────────────────────────────────────────────
// // 🌟 LIVE progress ring: tweened progress + rotating shine
// class _RoundProgressRing extends StatefulWidget {
//   final double progress; // 0..1
//   final ColorScheme cs;
//   final double size;
//   final double strokeWidth;
//   const _RoundProgressRing({
//     required this.progress,
//     required this.cs,
//     this.size = 72,
//     this.strokeWidth = 8,
//   });

//   @override
//   State<_RoundProgressRing> createState() => _RoundProgressRingState();
// }

// class _RoundProgressRingState extends State<_RoundProgressRing> with TickerProviderStateMixin {
//   late final AnimationController _spin; // endless rotation for shine
//   late final AnimationController _tween; // progress tween 0..1

//   @override
//   void initState() {
//     super.initState();
//     _spin = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat();
//     _tween = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 450),
//       value: widget.progress.clamp(0.0, 1.0),
//     );
//   }

//   @override
//   void didUpdateWidget(covariant _RoundProgressRing old) {
//     super.didUpdateWidget(old);
//     if (old.progress != widget.progress) {
//       _tween.animateTo(widget.progress.clamp(0.0, 1.0), curve: Curves.easeOutCubic);
//     }
//   }

//   @override
//   void dispose() {
//     _spin.dispose();
//     _tween.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final cs = widget.cs;
//     return SizedBox(
//       width: widget.size,
//       height: widget.size,
//       child: AnimatedBuilder(
//         animation: Listenable.merge([_spin, _tween]),
//         builder: (context, _) {
//           final p = _tween.value.clamp(0.0, 1.0);
//           final rot = _spin.value * 2 * math.pi;
//           return CustomPaint(
//             painter: _RingPainter(
//               progress: p,
//               rotation: rot,
//               color: cs.primary,
//               bg: cs.surfaceContainerHighest.withOpacity(0.35),
//               strokeWidth: widget.strokeWidth,
//             ),
//             child: Center(
//               child: Text(
//                 '${(p * 100).round()}%',
//                 style: const TextStyle(fontWeight: FontWeight.w700),
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }

// class _RingPainter extends CustomPainter {
//   final double progress; // 0..1
//   final double rotation; // radians
//   final double strokeWidth;
//   final Color color;
//   final Color bg;

//   _RingPainter({
//     required this.progress,
//     required this.rotation,
//     required this.strokeWidth,
//     required this.color,
//     required this.bg,
//   });

//   @override
//   void paint(Canvas canvas, Size size) {
//     final center = size.center(Offset.zero);
//     final radius = (size.shortestSide - strokeWidth) / 2;

//     // track
//     final track = Paint()
//       ..color = bg
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = strokeWidth
//       ..strokeCap = StrokeCap.round;
//     canvas.drawCircle(center, radius, track);

//     if (progress <= 0) return;

//     // rotating sweep gradient for moving shine
//     final shader = SweepGradient(
//       startAngle: 0,
//       endAngle: 2 * math.pi,
//       transform: GradientRotation(rotation),
//       colors: [
//         color.withOpacity(0.25),
//         color,
//         color,
//         color.withOpacity(0.25),
//       ],
//       stops: const [0.0, 0.06, 0.86, 1.0],
//     ).createShader(Rect.fromCircle(center: center, radius: radius));

//     final arc = Paint()
//       ..shader = shader
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = strokeWidth
//       ..strokeCap = StrokeCap.round;

//     final start = -math.pi / 2; // 12 o’clock
//     final sweep = 2 * math.pi * progress;
//     canvas.drawArc(Rect.fromCircle(center: center, radius: radius), start, sweep, false, arc);
//   }

//   @override
//   bool shouldRepaint(covariant _RingPainter old) {
//     return old.progress != progress ||
//         old.rotation != rotation ||
//         old.color != color ||
//         old.bg != bg ||
//         old.strokeWidth != strokeWidth;
//   }
// }

// // ─────────────────────────────────────────────────────────────────────────────
// // 🧩 Stat chip where only the ICON pops bigger on tap (no vibration)
// class _TapGrowStatChip extends StatefulWidget {
//   final IconData icon;
//   final Color iconColor;
//   final String label;
//   final String value;
//   final ColorScheme cs;

//   const _TapGrowStatChip({
//     required this.icon,
//     required this.iconColor,
//     required this.label,
//     required this.value,
//     required this.cs,
//   });

//   @override
//   State<_TapGrowStatChip> createState() => _TapGrowStatChipState();
// }

// class _TapGrowStatChipState extends State<_TapGrowStatChip> {
//   double _iconScale = 1.0;

//   Future<void> _bump() async {
//     setState(() => _iconScale = 1.28); // pop
//     await Future.delayed(const Duration(milliseconds: 140));
//     if (!mounted) return;
//     setState(() => _iconScale = 1.0); // settle
//   }

//   @override
//   Widget build(BuildContext context) {
//     final cs = widget.cs;
//     return Material(
//       color: cs.surface,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(25),
//         side: BorderSide(color: cs.outlineVariant),
//       ),
//       child: InkWell(
//         borderRadius: BorderRadius.circular(25),
//         onTap: _bump,
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//           child: Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               AnimatedScale(
//                 duration: const Duration(milliseconds: 140),
//                 curve: Curves.easeOutBack,
//                 scale: _iconScale,
//                 child: Icon(widget.icon, size: 18, color: widget.iconColor),
//               ),
//               const SizedBox(width: 8),
//               Text(widget.label, style: TextStyle(color: cs.onSurface.withOpacity(0.85))),
//               const SizedBox(width: 6),
//               Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                 decoration: BoxDecoration(color: cs.primary.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
//                 child: Text(widget.value, style: TextStyle(fontWeight: FontWeight.w700, color: cs.primary)),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// // ─────────────────────────────────────────────────────────────────────────────
// // ✅ Alive completed chip (gentle pulse so it feels “live”)
// class _AliveCompletionChip extends StatefulWidget {
//   final int count;
//   final int total;
//   final ColorScheme cs;
//   const _AliveCompletionChip({required this.count, required this.total, required this.cs});

//   @override
//   State<_AliveCompletionChip> createState() => _AliveCompletionChipState();
// }

// class _AliveCompletionChipState extends State<_AliveCompletionChip> with SingleTickerProviderStateMixin {
//   late final AnimationController _loop;

//   @override
//   void initState() {
//     super.initState();
//     _loop = AnimationController(vsync: this, duration: const Duration(milliseconds: 2800))..repeat();
//   }

//   @override
//   void dispose() {
//     _loop.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final cs = widget.cs;
//     return AnimatedBuilder(
//       animation: _loop,
//       builder: (_, __) {
//         final t = _loop.value; // 0..1
//         final scale = 1.0 + 0.04 * math.sin(t * 2 * math.pi);
//         final bg = Color.lerp(
//             cs.secondaryContainer, cs.secondaryContainer.withOpacity(0.85), 0.5 + 0.5 * math.sin(t * 2 * math.pi))!;
//         return Transform.scale(
//           scale: scale,
//           child: Container(
//             margin: const EdgeInsets.symmetric(vertical: 8),
//             padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//             decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
//             child: Row(mainAxisSize: MainAxisSize.min, children: [
//               Icon(Icons.verified_rounded, size: 16, color: cs.onSecondaryContainer),
//               const SizedBox(width: 6),
//               Text(
//                 'Completed: ${widget.count} / ${widget.total}',
//                 style: TextStyle(
//                   color: cs.onSecondaryContainer,
//                   fontWeight: FontWeight.w600,
//                   fontSize: 13,
//                 ),
//                 maxLines: 1,
//                 overflow: TextOverflow.ellipsis,
//                 softWrap: false,
//               ),
//             ]),
//           ),
//         );
//       },
//     );
//   }
// }

// // ─────────────────────────────────────────────────────────────────────────────
// // 🌗 Alive theme toggle button (sun rays / moon stars + breathing)
// class _AliveThemeButton extends StatefulWidget {
//   final bool isDark;
//   final VoidCallback onTap;
//   final ColorScheme cs;
//   final String tooltip;

//   const _AliveThemeButton({
//     required this.isDark,
//     required this.onTap,
//     required this.cs,
//     required this.tooltip,
//   });

//   @override
//   State<_AliveThemeButton> createState() => _AliveThemeButtonState();
// }

// class _AliveThemeButtonState extends State<_AliveThemeButton> with SingleTickerProviderStateMixin {
//   late final AnimationController _loop;

//   @override
//   void initState() {
//     super.initState();
//     _loop = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000))..repeat();
//   }

//   @override
//   void dispose() {
//     _loop.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final cs = widget.cs;
//     return AnimatedBuilder(
//       animation: _loop,
//       builder: (_, __) {
//         final t = _loop.value; // 0..1
//         final scale = 1.0 + 0.06 * math.sin(t * 2 * math.pi); // breathing
//         final base = widget.isDark ? cs.tertiary : cs.primary;
//         final glow = base.withOpacity(0.45);

//         return Tooltip(
//           message: widget.tooltip,
//           child: InkResponse(
//             radius: 28,
//             onTap: widget.onTap,
//             child: Transform.scale(
//               scale: scale,
//               child: Container(
//                 width: 40,
//                 height: 40,
//                 decoration: BoxDecoration(
//                   shape: BoxShape.circle,
//                   gradient: RadialGradient(
//                     colors: [
//                       base.withOpacity(0.20),
//                       base.withOpacity(0.05),
//                     ],
//                   ),
//                   boxShadow: [
//                     BoxShadow(
//                       color: glow,
//                       blurRadius: 12 + 6 * (0.5 + 0.5 * math.sin(t * 2 * math.pi)),
//                       spreadRadius: 0.5,
//                     ),
//                   ],
//                 ),
//                 child: Stack(
//                   alignment: Alignment.center,
//                   children: [
//                     // aura (sun rays / moon stars)
//                     CustomPaint(
//                       painter: _ThemeAuraPainter(
//                         isDark: widget.isDark,
//                         t: t,
//                         color: base,
//                       ),
//                       size: const Size(double.infinity, double.infinity),
//                     ),
//                     // icon (sun ↔ moon)
//                     AnimatedSwitcher(
//                       duration: const Duration(milliseconds: 300),
//                       transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
//                       child: widget.isDark
//                           ? Icon(Icons.nightlight_round, key: const ValueKey('moon'), color: cs.onSurface, size: 22)
//                           : Icon(Icons.wb_sunny_rounded, key: const ValueKey('sun'), color: cs.onSurface, size: 22),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }
// }

// class _ThemeAuraPainter extends CustomPainter {
//   final bool isDark;
//   final double t; // 0..1
//   final Color color;
//   _ThemeAuraPainter({required this.isDark, required this.t, required this.color});

//   @override
//   void paint(Canvas canvas, Size size) {
//     final c = size.center(Offset.zero);
//     final r = size.shortestSide / 2 - 4;

//     if (!isDark) {
//       // ☀️ Sun: 8 rotating rays
//       final paint = Paint()
//         ..color = color.withOpacity(0.85)
//         ..strokeWidth = 2
//         ..strokeCap = StrokeCap.round;
//       for (int i = 0; i < 8; i++) {
//         final a = (i * (math.pi / 4)) + (t * 2 * math.pi);
//         final p1 = Offset(c.dx + (r - 8) * math.cos(a), c.dy + (r - 8) * math.sin(a));
//         final p2 = Offset(c.dx + (r - 2) * math.cos(a), c.dy + (r - 2) * math.sin(a));
//         canvas.drawLine(p1, p2, paint);
//       }
//     } else {
//       // 🌙 Moon: 3 orbiting "stars" that twinkle
//       final orbit = r - 6;
//       for (int i = 0; i < 3; i++) {
//         final a = (t * 2 * math.pi) + i * (2 * math.pi / 3);
//         final px = c.dx + orbit * math.cos(a);
//         final py = c.dy + orbit * math.sin(a);
//         final twinkle = 0.6 + 0.4 * (0.5 + 0.5 * math.sin((a * 2) + i));
//         final star = Paint()..color = color.withOpacity(0.85);
//         canvas.drawCircle(Offset(px, py), 1.8 * twinkle, star);
//       }
//     }
//   }

//   @override
//   bool shouldRepaint(covariant _ThemeAuraPainter old) => old.isDark != isDark || old.t != t || old.color != color;
// }

// /// ▶️ Alive play icon for the bottom CTA
// /// - subtle breathing
// /// - rotating shine around the rim
// /// - three tiny orbit dots
// class _AlivePlayIcon extends StatefulWidget {
//   final ColorScheme cs;
//   final double size;
//   const _AlivePlayIcon({required this.cs, this.size = 36});

//   @override
//   State<_AlivePlayIcon> createState() => _AlivePlayIconState();
// }

// class _AlivePlayIconState extends State<_AlivePlayIcon> with SingleTickerProviderStateMixin {
//   late final AnimationController _loop;

//   @override
//   void initState() {
//     super.initState();
//     _loop = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 2200),
//     )..repeat();
//   }

//   @override
//   void dispose() {
//     _loop.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final cs = widget.cs;
//     return AnimatedBuilder(
//       animation: _loop,
//       builder: (_, __) {
//         final t = _loop.value; // 0..1
//         final breathing = 1.0 + 0.06 * math.sin(t * 2 * math.pi);

//         return SizedBox(
//           width: widget.size,
//           height: widget.size,
//           child: Stack(
//             alignment: Alignment.center,
//             children: [
//               // 🟡 orbiting dots
//               CustomPaint(
//                 size: Size(widget.size, widget.size),
//                 painter: _OrbitDotsPainter(
//                   t: t,
//                   color: cs.onPrimary.withOpacity(0.85),
//                 ),
//               ),

//               // ✨ rotating shine on the rim
//               CustomPaint(
//                 size: Size(widget.size, widget.size),
//                 painter: _RotatingShineRingPainter(
//                   t: t,
//                   color: cs.onPrimary.withOpacity(0.9),
//                 ),
//               ),

//               // 🎯 breathing core with gradient
//               Transform.scale(
//                 scale: breathing,
//                 child: Container(
//                   width: widget.size,
//                   height: widget.size,
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     gradient: LinearGradient(
//                       colors: [cs.primary, cs.tertiary, cs.secondary],
//                       begin: Alignment.topLeft,
//                       end: Alignment.bottomRight,
//                     ),
//                     boxShadow: [
//                       BoxShadow(
//                         color: cs.primary.withOpacity(0.35),
//                         blurRadius: 10,
//                         offset: const Offset(0, 4),
//                       ),
//                     ],
//                   ),
//                   alignment: Alignment.center,
//                   child: const Icon(Icons.play_arrow, size: 22, color: Colors.white),
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
// }

// /// paints a thin ring with a rotating sweep-shine
// class _RotatingShineRingPainter extends CustomPainter {
//   final double t; // 0..1
//   final Color color;
//   _RotatingShineRingPainter({required this.t, required this.color});

//   @override
//   void paint(Canvas canvas, Size size) {
//     final center = size.center(Offset.zero);
//     final radius = (size.shortestSide / 2) - 1.5;
//     final rect = Rect.fromCircle(center: center, radius: radius);

//     final paint = Paint()
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 2
//       ..shader = SweepGradient(
//         startAngle: 0,
//         endAngle: 2 * math.pi,
//         transform: GradientRotation(t * 2 * math.pi),
//         colors: [
//           color.withOpacity(0.0),
//           color,
//           color.withOpacity(0.0),
//         ],
//         stops: const [0.35, 0.5, 0.65],
//       ).createShader(rect);

//     canvas.drawArc(rect, 0, 2 * math.pi, false, paint);
//   }

//   @override
//   bool shouldRepaint(covariant _RotatingShineRingPainter old) => old.t != t || old.color != color;
// }

// /// paints three small dots orbiting the button
// class _OrbitDotsPainter extends CustomPainter {
//   final double t; // 0..1
//   final Color color;
//   _OrbitDotsPainter({required this.t, required this.color});

//   @override
//   void paint(Canvas canvas, Size size) {
//     final c = size.center(Offset.zero);
//     final r = (size.shortestSide / 2) - 4;

//     for (int i = 0; i < 3; i++) {
//       final a = (t * 2 * math.pi) + i * (2 * math.pi / 3);
//       final px = c.dx + r * math.cos(a);
//       final py = c.dy + r * math.sin(a);
//       final twinkle = 0.7 + 0.3 * math.sin((a * 2) + i);
//       final paint = Paint()..color = color.withOpacity(0.8);
//       canvas.drawCircle(Offset(px, py), 1.6 * twinkle, paint);
//     }
//   }

//   @override
//   bool shouldRepaint(covariant _OrbitDotsPainter old) => old.t != t || old.color != color;
// }

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/prefs.dart';
import '../quiz/quiz_bloc.dart';
import '../theme/theme_cubit.dart';
import 'round_page.dart';

// 👇 Single source of truth: 7 questions per round
const int kQuestionsPerRound = 7;

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentRound = 1; // 1..500
  int _stage = 0; // 0..6  (drives ring progress)
  Set<int> _completed = {};
  int _streak = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final r = await Prefs.getCurrentRound();
    final s = await Prefs.getStage(r);
    final c = await Prefs.getCompletedRounds();

    // Clamp any old saved stage (e.g., from 10-question days)
    final clampedStage = s < 0 ? 0 : (s >= kQuestionsPerRound ? kQuestionsPerRound - 1 : s);

    if (!mounted) return;
    setState(() {
      _currentRound = r;
      _stage = clampedStage;
      _completed = c;
      _streak = _calcStreak(c);
    });
  }

  int _calcStreak(Set<int> done) {
    int k = 0;
    while (done.contains(k + 1)) k++;
    return k;
  }

  Future<void> _openRound(int r) async {
    if (_completed.contains(r)) {
      await _showStoredResult(r);
      return;
    }
    // await Prefs.setCurrentRound(r);
    // context.read<QuizBloc>().add(LoadRound(r));
    // if (!mounted) return;
    // await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RoundPage()));
    // _load(); // refresh after returning
  }

  Future<void> _showStoredResult(int round) async {
    final res = await Prefs.getRoundResult(round);
    if (!mounted) return;

    if (res == null) {
      // fallback if result wasn’t saved for some reason
      await showModalBottomSheet(
        context: context,
        builder: (_) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Round $round Result', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            const Text('Result not available for this round.'),
            const SizedBox(height: 12),
            FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ]),
        ),
      );
      return;
    }

    final correct = res['correct']!;
    final total = res['total']!;
    final wrong = total - correct;

    await showModalBottomSheet(
      context: context,
      isDismissible: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Round $round • Result', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _resultBadge('✅ Correct', correct, Colors.green),
            _resultBadge('❌ Wrong', wrong, Colors.red),
          ]),
          const SizedBox(height: 16),
          FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ]),
      ),
    );
  }

  Widget _resultBadge(String label, int val, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        Text(label),
        const SizedBox(height: 6),
        Text('$val', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = context.watch<ThemeCubit>().state;

    // 🌈 Day = vibrant, Night = subtle (tweaked dark gradient so the card pops)
    final gradientColors = isDark
        ? [cs.surface, cs.surfaceContainerHighest]
        : [
            cs.primaryContainer.withOpacity(0.65),
            cs.tertiaryContainer.withOpacity(0.60),
            cs.secondaryContainer.withOpacity(0.65),
          ];

    // 📈 Progress based on 7 questions (0..6 → ~86%)
    final ringProgress = (_stage / kQuestionsPerRound).clamp(0.0, 1.0);

    final navIconBrightness =
        ThemeData.estimateBrightnessForColor(cs.primary) == Brightness.dark ? Brightness.light : Brightness.dark;

    // 🎨 Hero card surfaces (so it doesn't blend with dark bg)
    final heroBg = isDark ? Color.alphaBlend(cs.primary.withOpacity(0.08), cs.surfaceContainerHighest) : cs.surface;
    final heroBorder = cs.outlineVariant.withOpacity(isDark ? 0.7 : 1.0);
    final heroShadow = isDark ? Colors.black.withOpacity(0.45) : Colors.black.withOpacity(0.12);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.white,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
          systemNavigationBarColor: cs.primary,
          systemNavigationBarIconBrightness: navIconBrightness,
        ),
        title: const FittedBox(child: Text('Math Quiz')),
        actions: [
          _AliveCompletionChip(count: _completed.length, total: 500, cs: cs),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: _AliveThemeButton(
              isDark: isDark,
              cs: cs,
              onTap: () => context.read<ThemeCubit>().toggle(),
              tooltip: isDark ? 'Light mode' : 'Dark mode',
            ),
          ),
        ],
      ),

      // ✅ Full-bleed gradient via Container (tight constraints)
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: RefreshIndicator(
          onRefresh: _load,
          edgeOffset: 30,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 🎴 Hero Card with progress ring (now clearly visible on dark)
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: heroBg,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: heroBorder),
                              boxShadow: [
                                BoxShadow(
                                  color: heroShadow,
                                  blurRadius: 22,
                                  offset: const Offset(0, 10),
                                )
                              ],
                            ),
                            child: Row(
                              children: [
                                _RoundProgressRing(progress: ringProgress, cs: cs),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(children: [
                                        Icon(Icons.emoji_events_rounded, color: cs.primary),
                                        const SizedBox(width: 6),
                                        const Text(
                                          'Round ',
                                          style: TextStyle(fontSize: 0), // spacer hack
                                        ),
                                        Text(
                                          'Round $_currentRound of 500',
                                          style: const TextStyle(fontSize: 20),
                                          maxLines: 1,
                                          softWrap: false,
                                        ),
                                      ]),
                                      const SizedBox(height: 8),
                                      Row(children: [
                                        Icon(Icons.timelapse_rounded, size: 18, color: cs.onSurfaceVariant),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Stage: Question ${_stage + 1} / $kQuestionsPerRound',
                                          style: Theme.of(context).textTheme.bodyMedium,
                                        ),
                                      ]),
                                      const SizedBox(height: 12),
                                      LinearProgressIndicator(
                                        value: (_completed.length / 500.0).clamp(0.0, 1.0),
                                        backgroundColor: cs.surfaceContainerHighest.withOpacity(0.5),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(children: [
                                        Icon(Icons.check_circle_outline, size: 18, color: cs.onSurfaceVariant),
                                        const SizedBox(width: 6),
                                        Text('Completed: ${_completed.length} rounds'),
                                      ]),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // 🔹 Quick Stats chips — ICON grows on tap
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              _TapGrowStatChip(
                                icon: Icons.local_fire_department_rounded,
                                iconColor: Colors.orange,
                                label: 'Streak',
                                value: '$_streak',
                                cs: cs,
                              ),
                              _TapGrowStatChip(
                                icon: Icons.check_circle,
                                iconColor: cs.primary,
                                label: 'Done',
                                value: '${_completed.length}',
                                cs: cs,
                              ),
                              _TapGrowStatChip(
                                icon: Icons.timelapse,
                                iconColor: cs.primary,
                                label: 'Stage',
                                value: '${_stage + 1}/$kQuestionsPerRound',
                                cs: cs,
                              ),
                            ],
                          ),

                          const SizedBox(height: 22),

                          // 🕑 Recently completed
                          Row(
                            children: [
                              Icon(Icons.history_rounded, color: cs.primary),
                              const SizedBox(width: 8),
                              Text('Recently completed', style: Theme.of(context).textTheme.titleMedium),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _recentCompletedChips(cs),
                          ),

                          const SizedBox(height: 80), // space before bottom button
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),

      // ⬇️ Bottom Start/Continue button
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: _AlivePlayIcon(cs: cs, size: 36),
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_stage == 0 ? 'Start Round' : 'Continue Round'),
                const SizedBox(width: 6),
                Icon(Icons.chevron_right_rounded, size: 20, color: cs.onPrimary.withOpacity(0.90)),
              ],
            ),
            onPressed: () async {
              context.read<QuizBloc>().add(LoadRound(_currentRound));
              await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RoundPage()));
              _load();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.primary,
              foregroundColor: cs.onPrimary,
              minimumSize: const Size.fromHeight(56),
              elevation: 3,
              shadowColor: cs.primary.withOpacity(0.35),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _recentCompletedChips(ColorScheme cs) {
    final list = _completed.toList()..sort();
    final recent = list.reversed.take(12).toList();
    if (recent.isEmpty) {
      return [Text('No completed rounds yet', style: TextStyle(color: cs.onSurfaceVariant))];
    }
    return recent.map((r) {
      return SizedBox(
        width: 120,
        height: 40,
        child: ActionChip(
          avatar: Icon(Icons.check_circle, color: cs.primary, size: 18),
          label: Text('Round $r'),
          onPressed: () => _openRound(r),
          backgroundColor: cs.surface,
          side: BorderSide(color: cs.outlineVariant),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }).toList();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 🌟 LIVE progress ring: tweened progress + rotating shine
class _RoundProgressRing extends StatefulWidget {
  final double progress; // 0..1
  final ColorScheme cs;
  final double size;
  final double strokeWidth;
  const _RoundProgressRing({
    required this.progress,
    required this.cs,
    this.size = 72,
    this.strokeWidth = 8,
  });

  @override
  State<_RoundProgressRing> createState() => _RoundProgressRingState();
}

class _RoundProgressRingState extends State<_RoundProgressRing> with TickerProviderStateMixin {
  late final AnimationController _spin; // endless rotation for shine
  late final AnimationController _tween; // progress tween 0..1

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat();
    _tween = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
      value: widget.progress.clamp(0.0, 1.0),
    );
  }

  @override
  void didUpdateWidget(covariant _RoundProgressRing old) {
    super.didUpdateWidget(old);
    if (old.progress != widget.progress) {
      _tween.animateTo(widget.progress.clamp(0.0, 1.0), curve: Curves.easeOutCubic);
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    _tween.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = widget.cs;
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: Listenable.merge([_spin, _tween]),
        builder: (context, _) {
          final p = _tween.value.clamp(0.0, 1.0);
          final rot = _spin.value * 2 * math.pi;
          return CustomPaint(
            painter: _RingPainter(
              progress: p,
              rotation: rot,
              color: cs.primary,
              bg: cs.surfaceContainerHighest.withOpacity(0.35),
              strokeWidth: widget.strokeWidth,
            ),
            child: Center(
              child: Text(
                '${(p * 100).round()}%',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress; // 0..1
  final double rotation; // radians
  final double strokeWidth;
  final Color color;
  final Color bg;

  _RingPainter({
    required this.progress,
    required this.rotation,
    required this.strokeWidth,
    required this.color,
    required this.bg,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - strokeWidth) / 2;

    // track
    final track = Paint()
      ..color = bg
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, track);

    if (progress <= 0) return;

    // rotating sweep gradient for moving shine
    final shader = SweepGradient(
      startAngle: 0,
      endAngle: 2 * math.pi,
      transform: GradientRotation(rotation),
      colors: [
        color.withOpacity(0.25),
        color,
        color,
        color.withOpacity(0.25),
      ],
      stops: const [0.0, 0.06, 0.86, 1.0],
    ).createShader(Rect.fromCircle(center: center, radius: radius));

    final arc = Paint()
      ..shader = shader
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final start = -math.pi / 2; // 12 o’clock
    final sweep = 2 * math.pi * progress;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), start, sweep, false, arc);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) {
    return old.progress != progress ||
        old.rotation != rotation ||
        old.color != color ||
        old.bg != bg ||
        old.strokeWidth != strokeWidth;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 🧩 Stat chip where only the ICON pops bigger on tap (no vibration)
class _TapGrowStatChip extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final ColorScheme cs;

  const _TapGrowStatChip({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.cs,
  });

  @override
  State<_TapGrowStatChip> createState() => _TapGrowStatChipState();
}

class _TapGrowStatChipState extends State<_TapGrowStatChip> {
  double _iconScale = 1.0;

  Future<void> _bump() async {
    setState(() => _iconScale = 1.28); // pop
    await Future.delayed(const Duration(milliseconds: 140));
    if (!mounted) return;
    setState(() => _iconScale = 1.0); // settle
  }

  @override
  Widget build(BuildContext context) {
    final cs = widget.cs;
    return Material(
      color: cs.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(25),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(25),
        onTap: _bump,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                duration: const Duration(milliseconds: 140),
                curve: Curves.easeOutBack,
                scale: _iconScale,
                child: Icon(widget.icon, size: 18, color: widget.iconColor),
              ),
              const SizedBox(width: 8),
              Text(widget.label, style: TextStyle(color: cs.onSurface.withOpacity(0.85))),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: cs.primary.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                child: Text(widget.value, style: TextStyle(fontWeight: FontWeight.w700, color: cs.primary)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ✅ Alive completed chip (gentle pulse so it feels “live”)
class _AliveCompletionChip extends StatefulWidget {
  final int count;
  final int total;
  final ColorScheme cs;
  const _AliveCompletionChip({required this.count, required this.total, required this.cs});

  @override
  State<_AliveCompletionChip> createState() => _AliveCompletionChipState();
}

class _AliveCompletionChipState extends State<_AliveCompletionChip> with SingleTickerProviderStateMixin {
  late final AnimationController _loop;

  @override
  void initState() {
    super.initState();
    _loop = AnimationController(vsync: this, duration: const Duration(milliseconds: 2800))..repeat();
  }

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = widget.cs;
    return AnimatedBuilder(
      animation: _loop,
      builder: (_, __) {
        final t = _loop.value; // 0..1
        final scale = 1.0 + 0.04 * math.sin(t * 2 * math.pi);
        final bg = Color.lerp(
            cs.secondaryContainer, cs.secondaryContainer.withOpacity(0.85), 0.5 + 0.5 * math.sin(t * 2 * math.pi))!;
        return Transform.scale(
          scale: scale,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.verified_rounded, size: 16, color: cs.onSecondaryContainer),
              const SizedBox(width: 6),
              Text(
                'Completed: ${widget.count} / ${widget.total}',
                style: TextStyle(
                  color: cs.onSecondaryContainer,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
              ),
            ]),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 🌗 Alive theme toggle button (sun rays / moon stars + breathing)
class _AliveThemeButton extends StatefulWidget {
  final bool isDark;
  final VoidCallback onTap;
  final ColorScheme cs;
  final String tooltip;

  const _AliveThemeButton({
    required this.isDark,
    required this.onTap,
    required this.cs,
    required this.tooltip,
  });

  @override
  State<_AliveThemeButton> createState() => _AliveThemeButtonState();
}

class _AliveThemeButtonState extends State<_AliveThemeButton> with SingleTickerProviderStateMixin {
  late final AnimationController _loop;

  @override
  void initState() {
    super.initState();
    _loop = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000))..repeat();
  }

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = widget.cs;
    return AnimatedBuilder(
      animation: _loop,
      builder: (_, __) {
        final t = _loop.value; // 0..1
        final scale = 1.0 + 0.06 * math.sin(t * 2 * math.pi); // breathing
        final base = widget.isDark ? cs.tertiary : cs.primary;
        final glow = base.withOpacity(0.45);

        return Tooltip(
          message: widget.tooltip,
          child: InkResponse(
            radius: 28,
            onTap: widget.onTap,
            child: Transform.scale(
              scale: scale,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      base.withOpacity(0.20),
                      base.withOpacity(0.05),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: glow,
                      blurRadius: 12 + 6 * (0.5 + 0.5 * math.sin(t * 2 * math.pi)),
                      spreadRadius: 0.5,
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // aura (sun rays / moon stars)
                    CustomPaint(
                      painter: _ThemeAuraPainter(
                        isDark: widget.isDark,
                        t: t,
                        color: base,
                      ),
                      size: const Size(double.infinity, double.infinity),
                    ),
                    // icon (sun ↔ moon)
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                      child: widget.isDark
                          ? Icon(Icons.nightlight_round, key: const ValueKey('moon'), color: cs.onSurface, size: 22)
                          : Icon(Icons.wb_sunny_rounded, key: const ValueKey('sun'), color: cs.onSurface, size: 22),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ThemeAuraPainter extends CustomPainter {
  final bool isDark;
  final double t; // 0..1
  final Color color;
  _ThemeAuraPainter({required this.isDark, required this.t, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 - 4;

    if (!isDark) {
      // ☀️ Sun: 8 rotating rays
      final paint = Paint()
        ..color = color.withOpacity(0.85)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      for (int i = 0; i < 8; i++) {
        final a = (i * (math.pi / 4)) + (t * 2 * math.pi);
        final p1 = Offset(c.dx + (r - 8) * math.cos(a), c.dy + (r - 8) * math.sin(a));
        final p2 = Offset(c.dx + (r - 2) * math.cos(a), c.dy + (r - 2) * math.sin(a));
        canvas.drawLine(p1, p2, paint);
      }
    } else {
      // 🌙 Moon: 3 orbiting "stars" that twinkle
      final orbit = r - 6;
      for (int i = 0; i < 3; i++) {
        final a = (t * 2 * math.pi) + i * (2 * math.pi / 3);
        final px = c.dx + orbit * math.cos(a);
        final py = c.dy + orbit * math.sin(a);
        final twinkle = 0.6 + 0.4 * (0.5 + 0.5 * math.sin((a * 2) + i));
        final star = Paint()..color = color.withOpacity(0.85);
        canvas.drawCircle(Offset(px, py), 1.8 * twinkle, star);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ThemeAuraPainter old) => old.isDark != isDark || old.t != t || old.color != color;
}

/// ▶️ Alive play icon for the bottom CTA
/// - subtle breathing
/// - rotating shine around the rim
/// - three tiny orbit dots
class _AlivePlayIcon extends StatefulWidget {
  final ColorScheme cs;
  final double size;
  const _AlivePlayIcon({required this.cs, this.size = 36});

  @override
  State<_AlivePlayIcon> createState() => _AlivePlayIconState();
}

class _AlivePlayIconState extends State<_AlivePlayIcon> with SingleTickerProviderStateMixin {
  late final AnimationController _loop;

  @override
  void initState() {
    super.initState();
    _loop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = widget.cs;
    return AnimatedBuilder(
      animation: _loop,
      builder: (_, __) {
        final t = _loop.value; // 0..1
        final breathing = 1.0 + 0.06 * math.sin(t * 2 * math.pi);

        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 🟡 orbiting dots
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _OrbitDotsPainter(
                  t: t,
                  color: cs.onPrimary.withOpacity(0.85),
                ),
              ),

              // ✨ rotating shine on the rim
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _RotatingShineRingPainter(
                  t: t,
                  color: cs.onPrimary.withOpacity(0.9),
                ),
              ),

              // 🎯 breathing core with gradient
              Transform.scale(
                scale: breathing,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [cs.primary, cs.tertiary, cs.secondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: cs.primary.withOpacity(0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.play_arrow, size: 22, color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// paints a thin ring with a rotating sweep-shine
class _RotatingShineRingPainter extends CustomPainter {
  final double t; // 0..1
  final Color color;
  _RotatingShineRingPainter({required this.t, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide / 2) - 1.5;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: 2 * math.pi,
        transform: GradientRotation(t * 2 * math.pi),
        colors: [
          color.withOpacity(0.0),
          color,
          color.withOpacity(0.0),
        ],
        stops: const [0.35, 0.5, 0.65],
      ).createShader(rect);

    canvas.drawArc(rect, 0, 2 * math.pi, false, paint);
  }

  @override
  bool shouldRepaint(covariant _RotatingShineRingPainter old) => old.t != t || old.color != color;
}

/// paints three small dots orbiting the button
class _OrbitDotsPainter extends CustomPainter {
  final double t; // 0..1
  final Color color;
  _OrbitDotsPainter({required this.t, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = (size.shortestSide / 2) - 4;

    for (int i = 0; i < 3; i++) {
      final a = (t * 2 * math.pi) + i * (2 * math.pi / 3);
      final px = c.dx + r * math.cos(a);
      final py = c.dy + r * math.sin(a);
      final twinkle = 0.7 + 0.3 * math.sin((a * 2) + i);
      final paint = Paint()..color = color.withOpacity(0.8);
      canvas.drawCircle(Offset(px, py), 1.6 * twinkle, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _OrbitDotsPainter old) => old.t != t || old.color != color;
}

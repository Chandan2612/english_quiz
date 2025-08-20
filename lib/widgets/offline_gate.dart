// // lib/widgets/offline_gate.dart
// import 'dart:async';
// import 'dart:ui';
// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:flutter/material.dart';

// /// Wrap your app with [OfflineGate] (MaterialApp.builder is perfect).
// /// It blocks interaction and shows a clean overlay whenever there’s no network.
// class OfflineGate extends StatefulWidget {
//   final Widget child;
//   const OfflineGate({super.key, required this.child});

//   @override
//   State<OfflineGate> createState() => _OfflineGateState();
// }

// class _OfflineGateState extends State<OfflineGate> {
//   final _conn = Connectivity();
//   StreamSubscription<dynamic>? _sub; // compatible with old/new API
//   bool _offline = false;

//   @override
//   void initState() {
//     super.initState();
//     _init();
//   }

//   Future<void> _init() async {
//     final initial = await _conn.checkConnectivity(); // ConnectivityResult or List<ConnectivityResult>
//     _update(initial);
//     _sub = _conn.onConnectivityChanged.listen(_update); // result type varies by plugin version
//   }

//   void _update(dynamic result) {
//     // Normalize to a list for both APIs
//     final List<ConnectivityResult> list =
//         result is List<ConnectivityResult> ? result : <ConnectivityResult>[result as ConnectivityResult];

//     final offline = list.isEmpty || list.every((r) => r == ConnectivityResult.none);

//     if (mounted && offline != _offline) {
//       setState(() => _offline = offline);
//     }
//   }

//   @override
//   void dispose() {
//     _sub?.cancel();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (!_offline) return widget.child;

//     final cs = Theme.of(context).colorScheme;
//     final isDark = Theme.of(context).brightness == Brightness.dark;

//     return Stack(
//       children: [
//         widget.child,

//         // Block all taps & dim the app
//         Positioned.fill(
//           child: AbsorbPointer(
//             absorbing: true,
//             child: Container(
//               color: Colors.black.withOpacity(0.55),
//               child: Center(
//                 child: ClipRRect(
//                   borderRadius: BorderRadius.circular(20),
//                   child: BackdropFilter(
//                     filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
//                     child: Container(
//                       width: 320,
//                       padding: const EdgeInsets.all(20),
//                       decoration: BoxDecoration(
//                         color: isDark ? cs.surfaceContainerHighest : Colors.white,
//                         borderRadius: BorderRadius.circular(20),
//                         border: Border.all(color: cs.outlineVariant),
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.black.withOpacity(0.18),
//                             blurRadius: 24,
//                             offset: const Offset(0, 10),
//                           ),
//                         ],
//                       ),
//                       child: Column(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           // Icon badge
//                           Container(
//                             width: 50,
//                             height: 50,
//                             decoration: BoxDecoration(
//                               color: cs.error.withOpacity(0.12),
//                               shape: BoxShape.circle,
//                             ),
//                             alignment: Alignment.center,
//                             child: Icon(Icons.wifi_off_rounded, color: cs.error, size: 26),
//                           ),
//                           const SizedBox(height: 14),
//                           Text(
//                             "You’re offline",
//                             style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
//                             textAlign: TextAlign.center,
//                           ),
//                           const SizedBox(height: 6),
//                           Text(
//                             "Please check your connection.\nWe’ll reconnect automatically.",
//                             style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
//                             textAlign: TextAlign.center,
//                           ),
//                           const SizedBox(height: 16),

//                           // Simple moving line (indeterminate)
//                           ClipRRect(
//                             borderRadius: BorderRadius.circular(999),
//                             child: LinearProgressIndicator(
//                               minHeight: 4,
//                               backgroundColor: cs.outlineVariant.withOpacity(0.6),
//                               color: cs.primary,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }

// lib/widgets/offline_gate.dart
import 'dart:async';
import 'dart:ui';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

/// Wrap the whole app (MaterialApp.builder) with OfflineGate.
/// Blocks interaction and shows a themed overlay whenever offline.
class OfflineGate extends StatefulWidget {
  final Widget child;
  const OfflineGate({super.key, required this.child});

  @override
  State<OfflineGate> createState() => _OfflineGateState();
}

class _OfflineGateState extends State<OfflineGate> {
  final _conn = Connectivity();
  StreamSubscription<dynamic>? _sub;
  bool _offline = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final initial = await _conn.checkConnectivity();
    _update(initial);
    _sub = _conn.onConnectivityChanged.listen(_update);
  }

  void _update(dynamic result) {
    final List<ConnectivityResult> list =
        result is List<ConnectivityResult> ? result : <ConnectivityResult>[result as ConnectivityResult];

    final offline = list.isEmpty || list.every((r) => r == ConnectivityResult.none);
    if (mounted && offline != _offline) {
      setState(() => _offline = offline);
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_offline) return widget.child;

    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Stack(
      children: [
        widget.child,

        // Themed scrim that blocks all input
        Positioned.fill(
          child: AbsorbPointer(
            absorbing: true,
            child: Container(
              color: cs.scrim.withOpacity(0.55), // uses scheme scrim
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Material(
                      // Use Material so surfaceTint/elevation follow M3
                      color: theme.cardColor, // picks from your theme (light/dark)
                      surfaceTintColor: cs.surfaceTint,
                      elevation: 12,
                      shadowColor: Colors.black.withOpacity(0.25),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 340),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Icon badge with scheme containers
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: cs.errorContainer,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Icon(Icons.wifi_off_rounded, color: cs.onErrorContainer, size: 28),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                "You’re offline",
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: cs.onSurface,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "Please check your connection.\nWe’ll reconnect automatically.",
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),

                              // Indeterminate line — colors from scheme
                              ClipRRect(
                                borderRadius: BorderRadius.circular(999),
                                child: LinearProgressIndicator(
                                  minHeight: 4,
                                  backgroundColor: cs.surfaceContainerHighest,
                                  color: cs.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

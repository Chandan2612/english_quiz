// // // Simulated interstitial ad overlay
// // import 'dart:async';
// // import 'package:flutter/material.dart';

// // class AdOverlay {
// //   static Future<void> show(BuildContext context, {int seconds = 3, required String label}) async {
// //     return showDialog(
// //       context: context,
// //       barrierDismissible: false,
// //       builder: (ctx) => _AdDialog(seconds: seconds, label: label),
// //     );
// //   }
// // }

// // class _AdDialog extends StatefulWidget {
// //   final int seconds; final String label;
// //   const _AdDialog({required this.seconds, required this.label});
// //   @override
// //   State<_AdDialog> createState() => _AdDialogState();
// // }

// // class _AdDialogState extends State<_AdDialog> {
// //   late int _left;
// //   Timer? _t;
// //   @override
// //   void initState() {
// //     super.initState();
// //     _left = widget.seconds;
// //     _t = Timer.periodic(const Duration(seconds: 1), (t) {
// //       if (!mounted) return;
// //       setState(() => _left--);
// //       if (_left <= 0) {
// //         t.cancel();
// //         Navigator.of(context).pop();
// //       }
// //     });
// //   }

// //   @override
// //   void dispose() { _t?.cancel(); super.dispose(); }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Dialog(
// //       insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
// //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
// //       child: Container(
// //         padding: const EdgeInsets.all(20),
// //         child: Column(
// //           mainAxisSize: MainAxisSize.min,
// //           children: [
// //             Text('Advertisement', style: Theme.of(context).textTheme.headlineSmall),
// //             const SizedBox(height: 12),
// //             Text(widget.label),
// //             const SizedBox(height: 12),
// //             const LinearProgressIndicator(),
// //             const SizedBox(height: 12),
// //             Text('Closing in $_left s'),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// // }

// // Simulated interstitial ad overlay
// import 'dart:async';
// import 'package:flutter/material.dart';

// class AdOverlay {
//   static Future<void> show(BuildContext context, {int seconds = 3, required String label}) async {
//     return showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (ctx) => _AdDialog(seconds: seconds, label: label),
//     );
//   }
// }

// class _AdDialog extends StatefulWidget {
//   final int seconds;
//   final String label;
//   const _AdDialog({required this.seconds, required this.label});
//   @override
//   State<_AdDialog> createState() => _AdDialogState();
// }

// class _AdDialogState extends State<_AdDialog> {
//   late int _left;
//   Timer? _t;
//   @override
//   void initState() {
//     super.initState();
//     _left = widget.seconds;
//     _t = Timer.periodic(const Duration(seconds: 1), (t) {
//       if (!mounted) return;
//       setState(() => _left--);
//       if (_left <= 0) {
//         t.cancel();
//         Navigator.of(context).pop();
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _t?.cancel();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Dialog(
//       insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//       child: Container(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text('Advertisement', style: Theme.of(context).textTheme.headlineSmall),
//             const SizedBox(height: 12),
//             Text(widget.label),
//             const SizedBox(height: 12),
//             const LinearProgressIndicator(),
//             const SizedBox(height: 12),
//             Text('Closing in $_left s'),
//           ],
//         ),
//       ),
//     );
//   }
// }


// lib/widgets/ad_overlay.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Simple helper to show interstitials N times in a row.
/// Uses AdMob test IDs. Replace with your real IDs for release.
class AdOverlay {
  // Interstitial test IDs from Google:
  static String get _interstitialId => Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/1033173712' // Android interstitial test
      : 'ca-app-pub-3940256099942544/4411468910'; // iOS interstitial test

  /// Show [times] interstitials back-to-back.
  /// Falls back to a small "thanks" dialog if the ad fails to load/show.
  static Future<void> showInterstitialTimes(
    BuildContext context, {
    required int times,
  }) async {
    for (var i = 0; i < times; i++) {
      final shown = await _showInterstitialOnce();
      if (!shown) {
        await _showFallbackDialog(context,
            label: 'Thanks for supporting us!', seconds: 3);
      }
    }
  }

  /// Loads and shows a single interstitial ad.
  /// Returns true if it was shown and closed, false if it failed.
  static Future<bool> _showInterstitialOnce() async {
    final completer = Completer<bool>();

    InterstitialAd.load(
      adUnitId: _interstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              if (!completer.isCompleted) completer.complete(true);
            },
            onAdFailedToShowFullScreenContent: (ad, err) {
              ad.dispose();
              if (!completer.isCompleted) completer.complete(false);
            },
          );
          ad.show();
        },
        onAdFailedToLoad: (error) {
          if (!completer.isCompleted) completer.complete(false);
        },
      ),
    );

    // Safety timeout so tests/dev don’t hang forever
    return completer.future
        .timeout(const Duration(seconds: 12), onTimeout: () => false);
  }

  // ── Fallback dialog (your old simulated ad) ──────────────────────────────

  /// Keep this for any existing calls like: AdOverlay.show(context, ...)
  static Future<void> show(BuildContext context,
          {int seconds = 3, required String label}) =>
      _showFallbackDialog(context, label: label, seconds: seconds);

  static Future<void> _showFallbackDialog(
    BuildContext context, {
    required String label,
    required int seconds,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _AdDialog(seconds: seconds, label: label),
    );
  }
}

class _AdDialog extends StatefulWidget {
  final int seconds;
  final String label;
  const _AdDialog({required this.seconds, required this.label});

  @override
  State<_AdDialog> createState() => _AdDialogState();
}

class _AdDialogState extends State<_AdDialog> {
  late int _left;
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _left = widget.seconds;
    _t = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _left--);
      if (_left <= 0) {
        t.cancel();
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Advertisement',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(widget.label,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: 16),
            // simple moving line vibe
            const LinearProgressIndicator(),
            const SizedBox(height: 12),
            Text('Closing in $_left s',
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

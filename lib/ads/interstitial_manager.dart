// // import 'dart:async';
// // import 'package:google_mobile_ads/google_mobile_ads.dart';
// // import 'ad_ids.dart';

// // /// Lightweight interstitial loader/show-er with auto-preload.
// // class InterstitialManager {
// //   static InterstitialAd? _ad;
// //   static bool _loading = false;

// //   static void load() {
// //     if (_loading || _ad != null) return;
// //     _loading = true;

// //     InterstitialAd.load(
// //       adUnitId: AdIds.interstitial(),
// //       request: const AdRequest(),
// //       adLoadCallback: InterstitialAdLoadCallback(
// //         onAdLoaded: (ad) {
// //           _ad = ad;
// //           _loading = false;
// //         },
// //         onAdFailedToLoad: (err) {
// //           _ad = null;
// //           _loading = false;
// //         },
// //       ),
// //     );
// //   }

// //   /// Shows the ad if ready. Returns when the ad is dismissed.
// //   static Future<bool> showIfReady() async {
// //     final ad = _ad;
// //     if (ad == null) {
// //       load(); // try to have one ready next time
// //       return false;
// //     }
// //     _ad = null;

// //     final done = Completer<bool>();
// //     ad.fullScreenContentCallback = FullScreenContentCallback(
// //       onAdDismissedFullScreenContent: (ad) {
// //         ad.dispose();
// //         load(); // preload the next one
// //         done.complete(true);
// //       },
// //       onAdFailedToShowFullScreenContent: (ad, err) {
// //         ad.dispose();
// //         load();
// //         done.complete(false);
// //       },
// //     );

// //     await ad.show();
// //     return done.future;
// //   }
// // }


// import 'dart:async';
// import 'package:google_mobile_ads/google_mobile_ads.dart';
// import 'ad_ids.dart';

// /// Lightweight interstitial helper with:
// /// - preload()
// /// - showAndWait() → completes when the ad is closed
// class InterstitialManager {
//   static InterstitialAd? _cached;
//   static bool _isLoading = false;

//   /// Starts loading if nothing cached.
//   static void preload() {
//     if (_cached != null || _isLoading) return;
//     _isLoading = true;

//     InterstitialAd.load(
//       adUnitId: AdIds.interstitial,           // <- String (getter), not function
//       request: const AdRequest(),
//       adLoadCallback: InterstitialAdLoadCallback(
//         onAdLoaded: (ad) {
//           _cached = ad;
//           _isLoading = false;
//           ad.setImmersiveMode(true);
//         },
//         onAdFailedToLoad: (err) {
//           _isLoading = false;
//           _cached = null;
//           // Optional: backoff or retry later
//         },
//       ),
//     );
//   }

//   /// Shows the ad if available and resolves when it’s dismissed.
//   /// If no ad is ready, it quietly preloads and returns immediately.
//   static Future<void> showAndWait() async {
//     final ad = _cached;
//     if (ad == null) {
//       preload();
//       return;
//     }

//     _cached = null; // consume
//     final completer = Completer<void>();

//     ad.fullScreenContentCallback = FullScreenContentCallback(
//       onAdShowedFullScreenContent: (_) {},
//       onAdDismissedFullScreenContent: (ad) {
//         ad.dispose();
//         preload(); // get the next one ready
//         if (!completer.isCompleted) completer.complete();
//       },
//       onAdFailedToShowFullScreenContent: (ad, error) {
//         ad.dispose();
//         preload();
//         if (!completer.isCompleted) completer.complete();
//       },
//     );

//     ad.show();
//     await completer.future;
//   }

//   /// Manual cleanup (usually not necessary).
//   static void dispose() {
//     _cached?.dispose();
//     _cached = null;
//   }
// }


import 'dart:async';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad_ids.dart';

class InterstitialManager {
  static InterstitialAd? _ad;
  static bool _loading = false;
  static Completer<bool>? _loadCompleter;

  static Future<void> preload() async {
    if (_ad != null || _loading) return;
    _loading = true;
    _loadCompleter = Completer<bool>();

    InterstitialAd.load(
      adUnitId: AdIds.interstitial, // your test/prod id
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _ad = ad;
          _loading = false;
          _loadCompleter?.complete(true);
        },
        onAdFailedToLoad: (error) {
          _ad = null;
          _loading = false;
          _loadCompleter?.complete(false);
        },
      ),
    );
  }

  static Future<bool> _waitUntilLoaded({Duration timeout = const Duration(seconds: 6)}) async {
    if (_ad != null) return true;
    if (!_loading) preload();
    final c = _loadCompleter ??= Completer<bool>();
    try {
      return await c.future.timeout(timeout);
    } catch (_) {
      return false;
    }
  }

  /// Shows one interstitial. Returns true if shown, false otherwise.
  static Future<bool> showAndWait() async {
    final ready = await _waitUntilLoaded();
    if (!ready || _ad == null) return false;

    final ad = _ad!;
    _ad = null; // mark as consumed
    final done = Completer<bool>();

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        done.complete(true);
        preload(); // warm up the next one
      },
      onAdFailedToShowFullScreenContent: (ad, err) {
        ad.dispose();
        done.complete(false);
        preload();
      },
    );

    ad.show();
    return done.future;
  }
}


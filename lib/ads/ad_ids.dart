// import 'dart:io';

// /// Keep all Ad Unit IDs in one place.
// /// These are Google TEST IDs. Replace with your real IDs for release.
// class AdIds {
//   static String banner() =>
//       Platform.isAndroid ? 'ca-app-pub-3940256099942544/6300978111'
//                          : 'ca-app-pub-3940256099942544/2934735716';

//   static String interstitial() =>
//       Platform.isAndroid ? 'ca-app-pub-3940256099942544/1033173712'
//                          : 'ca-app-pub-3940256099942544/4411468910';

//   static String rewarded() =>
//       Platform.isAndroid ? 'ca-app-pub-3940256099942544/5224354917'
//                          : 'ca-app-pub-3940256099942544/1712485313';
// }


import 'dart:io';

/// AdMob TEST ad unit IDs (safe for dev).
/// Replace with your real IDs before release.
class AdIds {
  // Use getters → you read them like fields (no parentheses).
  static String get banner => Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/6300978111' // Android banner (TEST)
      : 'ca-app-pub-3940256099942544/2934735716'; // iOS banner (TEST)

  static String get interstitial => Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/1033173712' // Android interstitial (TEST)
      : 'ca-app-pub-3940256099942544/4411468910'; // iOS interstitial (TEST)
}

// // SharedPreferences helpers
// import 'dart:convert';
// import 'package:shared_preferences/shared_preferences.dart';

// class Prefs {
//   static const _kIsDark = 'is_dark';
//   static const _kCurrentRound = 'current_round';
//   static const _kCompletedRounds = 'completed_rounds';
//   static String stageKey(int round) => 'stage_round_$round';
//   static String selectedKey(int round) => 'selected_round_$round';

//   static Future<bool> getIsDark() async => (await SharedPreferences.getInstance()).getBool(_kIsDark) ?? false;
//   static Future<void> setIsDark(bool v) async => (await SharedPreferences.getInstance()).setBool(_kIsDark, v);

//   static Future<int> getCurrentRound() async => (await SharedPreferences.getInstance()).getInt(_kCurrentRound) ?? 1;
//   static Future<void> setCurrentRound(int round) async => (await SharedPreferences.getInstance()).setInt(_kCurrentRound, round);

//   static Future<Set<int>> getCompletedRounds() async {
//     final prefs = await SharedPreferences.getInstance();
//     final list = prefs.getStringList(_kCompletedRounds) ?? <String>[];
//     return list.map(int.parse).toSet();
//     }

//   static Future<void> addCompletedRound(int round) async {
//     final prefs = await SharedPreferences.getInstance();
//     final set = await getCompletedRounds();
//     set.add(round);
//     await prefs.setStringList(_kCompletedRounds, set.map((e) => e.toString()).toList());
//   }

//   static Future<int> getStage(int round) async => (await SharedPreferences.getInstance()).getInt(stageKey(round)) ?? 0;
//   static Future<void> setStage(int round, int idx) async => (await SharedPreferences.getInstance()).setInt(stageKey(round), idx);

//   static Future<Map<int, int>> getSelectedMap(int round) async {
//     final prefs = await SharedPreferences.getInstance();
//     final raw = prefs.getString(selectedKey(round));
//     if (raw == null) return {};
//     final m = (jsonDecode(raw) as Map<String, dynamic>).map((k, v) => MapEntry(int.parse(k), v as int));
//     return m;
//   }

//   static Future<void> setSelectedMap(int round, Map<int, int> map) async {
//     final prefs = await SharedPreferences.getInstance();
//     final enc = jsonEncode(map.map((k, v) => MapEntry(k.toString(), v)));
//     await prefs.setString(selectedKey(round), enc);
//   }

//   static Future<void> clearRoundState(int round) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.remove(stageKey(round));
//     await prefs.remove(selectedKey(round));
//   }
// }


// SharedPreferences helpers
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class Prefs {
  static const _kIsDark = 'is_dark';
  static const _kCurrentRound = 'current_round';
  static const _kCompletedRounds = 'completed_rounds';
  static String stageKey(int round) => 'stage_round_$round';
  static String selectedKey(int round) => 'selected_round_$round';

  static Future<bool> getIsDark() async =>
      (await SharedPreferences.getInstance()).getBool(_kIsDark) ?? false;
  static Future<void> setIsDark(bool v) async =>
      (await SharedPreferences.getInstance()).setBool(_kIsDark, v);

  static Future<int> getCurrentRound() async =>
      (await SharedPreferences.getInstance()).getInt(_kCurrentRound) ?? 1;
  static Future<void> setCurrentRound(int round) async =>
      (await SharedPreferences.getInstance()).setInt(_kCurrentRound, round);

  static Future<Set<int>> getCompletedRounds() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_kCompletedRounds) ?? <String>[];
    return list.map(int.parse).toSet();
  }

  static Future<void> addCompletedRound(int round) async {
    final prefs = await SharedPreferences.getInstance();
    final set = await getCompletedRounds();
    set.add(round);
    await prefs.setStringList(
      _kCompletedRounds,
      set.map((e) => e.toString()).toList(),
    );
  }

  static Future<int> getStage(int round) async =>
      (await SharedPreferences.getInstance()).getInt(stageKey(round)) ?? 0;
  static Future<void> setStage(int round, int idx) async =>
      (await SharedPreferences.getInstance()).setInt(stageKey(round), idx);

  static Future<Map<int, int>> getSelectedMap(int round) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(selectedKey(round));
    if (raw == null) return {};
    final m = (jsonDecode(raw) as Map<String, dynamic>)
        .map((k, v) => MapEntry(int.parse(k), v as int));
    return m;
  }

  static Future<void> setSelectedMap(int round, Map<int, int> map) async {
    final prefs = await SharedPreferences.getInstance();
    final enc = jsonEncode(map.map((k, v) => MapEntry(k.toString(), v)));
    await prefs.setString(selectedKey(round), enc);
  }

  static Future<void> clearRoundState(int round) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(stageKey(round));
    await prefs.remove(selectedKey(round));
  }
}

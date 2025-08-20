// 🎨 ThemeCubit toggle + persistence
import 'package:english_quiz/core/prefs.dart';
import 'package:english_quiz/theme/theme_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';


void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'is_dark': false});
  });

  test('toggle flips theme and persists to Prefs', () async {
    final cubit = ThemeCubit(false);
    expect(cubit.state, false);

    await cubit.toggle();
    expect(cubit.state, true);

    final saved = await Prefs.getIsDark();
    expect(saved, true);
  });
}

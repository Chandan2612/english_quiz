import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/prefs.dart';

class ThemeCubit extends Cubit<bool> {
  ThemeCubit(bool isDark) : super(isDark);
  Future<void> toggle() async {
    final next = !state;
    emit(next);
    await Prefs.setIsDark(next);
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/prefs.dart';
import 'quiz/quiz_bloc.dart';
import 'quiz/quiz_repository.dart';
import 'theme/theme_cubit.dart';
import 'pages/splash_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    // DeviceOrientation.portraitDown,
  ]);
  final isDark = await Prefs.getIsDark();
  runApp(MyApp(isDark: isDark));
}

/// 🌿 Dark color scheme — emerald-forward, readable, and consistent
final ColorScheme darkScheme = const ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xFF16A34A), // 🌿 Emerald (brand primary)
  onPrimary: Color(0xFFFFFFFF),
  primaryContainer: Color(0xFF0B3B22), // 🍃 Deep emerald surface
  onPrimaryContainer: Color(0xFFBFF3D2),

  secondary: Color(0xFF22C55E), // ✅ Accent green
  onSecondary: Color(0xFF071A10),
  secondaryContainer: Color(0xFF113C25),
  onSecondaryContainer: Color(0xFFC6F6D5),

  tertiary: Color(0xFF86EFAC), // 💚 Mint highlight
  onTertiary: Color(0xFF072013),
  tertiaryContainer: Color(0xFF123D2A),
  onTertiaryContainer: Color(0xFFE6FBEF),

  error: Color(0xFFFFB4AB),
  onError: Color(0xFF690005),
  errorContainer: Color(0xFF8C1D18),
  onErrorContainer: Color(0xFFFFDAD6),

  surface: Color(0xFF0F1A15), // 🧊 Card/Sheet base
  onSurface: Color(0xFFDDE7E1),
  surfaceContainerHighest: Color(0xFF1A2B23), // 🧱 Elevated surfaces
  onSurfaceVariant: Color(0xFFB7C8C0),

  outline: Color(0xFF7A8D84),
  outlineVariant: Color(0xFF2A3A33),

  inverseSurface: Color(0xFFDDE7E1),
  onInverseSurface: Color(0xFF11201A),
  inversePrimary: Color(0xFF34D399),

  shadow: Color(0xFF000000),
  scrim: Color(0xFF000000),
  surfaceTint: Color(0xFF16A34A), // ✨ M3 elevation tint
);

class MyApp extends StatelessWidget {
  final bool isDark;
  const MyApp({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final repo = QuizRepository();
    final baseBtnShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    );

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ThemeCubit(isDark)),
        BlocProvider(create: (_) => QuizBloc(repo)),
      ],
      child: BlocBuilder<ThemeCubit, bool>(
        builder: (context, dark) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            themeMode: dark ? ThemeMode.dark : ThemeMode.light,

            // ☀️ LIGHT THEME — uses emerald seed so primary = green
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF16A34A), // 🌿 Emerald seed
              ),
              appBarTheme: const AppBarTheme(
                elevation: 0,
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                centerTitle: false,
              ),
              snackBarTheme: const SnackBarThemeData(
                behavior: SnackBarBehavior.floating,
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  shape: baseBtnShape,
                  minimumSize: const Size(56, 44),
                ),
              ),
              cardTheme: CardThemeData(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),

            // 🌙 DARK THEME — custom green scheme from above
            darkTheme: ThemeData(
              useMaterial3: true,
              colorScheme: darkScheme,
              scaffoldBackgroundColor: darkScheme.surface,
              appBarTheme: const AppBarTheme(
                elevation: 0,
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                centerTitle: false,
              ),
              snackBarTheme: SnackBarThemeData(
                behavior: SnackBarBehavior.floating,
                backgroundColor: darkScheme.surface,
                contentTextStyle: TextStyle(color: darkScheme.onSurface),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  shape: baseBtnShape,
                  minimumSize: const Size(56, 44),
                  backgroundColor: darkScheme.primary, // ✅ green buttons
                  foregroundColor: darkScheme.onPrimary, // ✅ readable text/icons
                ),
              ),
              cardTheme: CardThemeData(
                color: darkScheme.surfaceContainerHighest,
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),

            home: const SplashPage(),
          );
        },
      ),
    );
  }
}

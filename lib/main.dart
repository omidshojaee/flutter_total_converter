import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens.dart';
import 'strings.dart';

void main() => runApp(const ConverterApp());

class ConverterApp extends StatelessWidget {
  const ConverterApp({super.key});

  static const _seed = Color(0xFF0B7A75); // deep teal

  ThemeData _theme(ColorScheme cs) {
    final base = ThemeData(useMaterial3: true, colorScheme: cs);
    final tt = GoogleFonts.vazirmatnTextTheme(base.textTheme);
    return base.copyWith(
      textTheme: tt.copyWith(
        displaySmall: tt.displaySmall?.copyWith(fontWeight: FontWeight.w700),
        titleMedium: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
      scaffoldBackgroundColor: cs.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
      ),
      searchBarTheme: SearchBarThemeData(
        constraints: const BoxConstraints(minHeight: 60),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: S.appTitle,
      debugShowCheckedModeBanner: false,
      locale: const Locale('fa', 'IR'),
      supportedLocales: const [Locale('fa', 'IR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      themeMode: ThemeMode.system,
      theme: _theme(
        ColorScheme.fromSeed(seedColor: _seed, brightness: Brightness.light),
      ),
      darkTheme: _theme(
        ColorScheme.fromSeed(seedColor: _seed, brightness: Brightness.dark),
      ),
      home: const HomeScreen(),
    );
  }
}

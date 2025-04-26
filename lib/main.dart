import 'package:an_app_v1/providers/auth_provider.dart';
import 'package:an_app_v1/screens/login.dart';
import 'package:an_app_v1/screens/main_menu.dart';
import 'package:an_app_v1/providers/theme_provider.dart';
import 'package:an_app_v1/screens/register.dart';
import 'package:an_app_v1/theme/app_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';

// main.dart dosyanızda

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  const isFirstLaunch = true;
  //final isFirstLaunch = prefs.getBool('isFirstLaunch') ?? true;
  try {
    await Firebase.initializeApp();
    if (kDebugMode) {
      print("Firebase başarıyla başlatıldı");
    }
  } catch (e) {
    if (kDebugMode) {
      print("Firebase başlatılamadı: $e");
    }
  }

  runApp(
    ProviderScope(
      child: AuthWrapper(isFirstLaunch: isFirstLaunch),
    ),
  );
}

class AuthWrapper extends ConsumerWidget {
  final bool isFirstLaunch;

  const AuthWrapper({super.key, required this.isFirstLaunch});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider); // theme artık AppThemeType
    final authState = ref.watch(authStateProvider);

    return authState.when(
      loading: () => _buildApp(
        theme,
        const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (err, _) => _buildApp(theme, LoginScreen()),
      data: (user) {
        return _buildApp(
          theme,
          user != null ? MainMenu(user: user) : (isFirstLaunch ? const RegisterScreen() : const LoginScreen()),
        );
      },
    );
  }

  // _buildApp fonksiyonunun parametre tipini AppThemeType olarak değiştirdik.
  MaterialApp _buildApp(AppThemeType theme, Widget homeScreen) {
    // Ortak text style ayarları
    const textStyle = TextStyle(
      fontFamily: 'Quicksand',
      height: 1.2, // Kritik ayar
      fontSize: 16, // Sabit boyut
    );

    return MaterialApp(
      title: 'An',
      theme: lightTheme.copyWith(
        primaryTextTheme: _applyQuicksandFont(lightTheme.primaryTextTheme),
        textTheme: _applyQuicksandFont(lightTheme.textTheme).copyWith(
          bodyMedium: textStyle.copyWith(
            color: lightTheme.extension<AppTheme>()!.textColor,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          isDense: false,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: lightTheme.extension<AppTheme>()!.borderColor,
            ),
          ),
          labelStyle: textStyle,
          hintStyle: textStyle.copyWith(
            color: lightTheme.extension<AppTheme>()!.textColor.withOpacity(0.6),
          ),
          alignLabelWithHint: true,
        ),
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: lightTheme.extension<AppTheme>()!.textColor,
          selectionHandleColor: lightTheme.extension<AppTheme>()!.textColor,
          selectionColor: lightTheme.extension<AppTheme>()!.textColor.withOpacity(0.3),
        ),
      ),
      darkTheme: darkTheme.copyWith(
        primaryTextTheme: _applyQuicksandFont(darkTheme.primaryTextTheme),
        textTheme: _applyQuicksandFont(darkTheme.textTheme).copyWith(
          bodyMedium: textStyle.copyWith(
            color: darkTheme.extension<AppTheme>()!.textColor,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          isDense: false,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: darkTheme.extension<AppTheme>()!.borderColor,
            ),
          ),
          labelStyle: textStyle,
          hintStyle: textStyle.copyWith(
            color: darkTheme.extension<AppTheme>()!.textColor.withOpacity(0.6),
          ),
          alignLabelWithHint: true,
        ),
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: darkTheme.extension<AppTheme>()!.textColor,
          selectionHandleColor: darkTheme.extension<AppTheme>()!.textColor,
          selectionColor: darkTheme.extension<AppTheme>()!.textColor.withOpacity(0.3),
        ),
      ),
      // themeMode'u AppThemeType üzerinden seçiyoruz.
      themeMode: theme == AppThemeType.light ? ThemeMode.light : ThemeMode.dark,
      debugShowCheckedModeBanner: false,
      home: homeScreen,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaleFactor: 1.0,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return OrientationBuilder(
                builder: (context, orientation) {
                  return child!;
                },
              );
            },
          ),
        );
      },
    );
  }

  // Tüm text theme'a fontu uygulayan yardımcı fonksiyon
  TextTheme _applyQuicksandFont(TextTheme textTheme) {
    return textTheme.apply(fontFamily: 'Quicksand');
  }
}

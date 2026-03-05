import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'providers/auth_provider.dart';

class NeuroNavApp extends ConsumerWidget {
  const NeuroNavApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final profile = ref.watch(currentProfileProvider);
    final fontScale = profile?.fontScale ?? 1.0;

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(fontScale),
      ),
      child: MaterialApp.router(
        title: 'NeuroNav',
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(context),
        routerConfig: router,
        locale: const Locale('es', 'MX'),
      ),
    );
  }

  ThemeData _buildTheme(BuildContext context) {
    const primaryColor = Color(0xFF4078D9);
    return ThemeData(
      useMaterial3: true,
      colorSchemeSeed: primaryColor,
      brightness: Brightness.light,
      fontFamily: null,
      cardTheme: CardThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 1,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0.5,
      ),
      navigationBarTheme: NavigationBarThemeData(
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

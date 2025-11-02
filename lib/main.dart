import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/routing/app_router.dart';
import 'shared/services/api_service.dart';

void main() {
  // Initialize API service
  ApiService.initialize();

  runApp(const ProviderScope(child: SahajMobileApp()));
}

class SahajMobileApp extends ConsumerWidget {
  const SahajMobileApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return PopScope(
      canPop: router.canPop(),
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (!didPop && router.canPop()) {
          router.pop();
        }
      },
      child: SafeArea(
        bottom: true,
        top: false,
        left: false,
        right: false,
        child: MaterialApp.router(
          title: 'SAHAJMOBILE',
          theme: AppTheme.lightTheme,
          routerConfig: router,
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}

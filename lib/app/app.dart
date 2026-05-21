import 'package:flutter/material.dart';

import '../shared/providers/app_scope.dart';
import 'main_tab_screen.dart';
import 'theme.dart';

class ChemistryOvenApp extends StatelessWidget {
  const ChemistryOvenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScope(
      child: MaterialApp(
        title: '케미스트리오븐',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        builder: (context, child) {
          final mediaQuery = MediaQuery.of(context);
          return MediaQuery(
            data: mediaQuery.copyWith(textScaler: TextScaler.noScaling),
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: const MainTabScreen(),
      ),
    );
  }
}

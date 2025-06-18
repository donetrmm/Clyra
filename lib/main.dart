import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'core/injection/injection_container.dart';
import 'core/navigation/app_router.dart';
import 'core/widgets/activity_detector.dart';
import 'features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'features/passwords/presentation/viewmodels/password_viewmodel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await InjectionContainer.init();

  runApp(const ClyraApp());
}

class ClyraApp extends StatelessWidget {
  const ClyraApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authViewModel = sl<AuthViewModel>();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthViewModel>.value(value: authViewModel),
        ChangeNotifierProvider<PasswordViewModel>(
          create: (_) => sl<PasswordViewModel>(),
        ),
      ],
      child: ActivityDetector(
        child: MaterialApp.router(
          title: 'Clyra',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark,
          routerConfig: AppRouter.createRouter(authViewModel),
        ),
      ),
    );
  }
}

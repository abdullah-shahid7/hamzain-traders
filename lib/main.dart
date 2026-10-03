import 'package:flutter/material.dart';
import 'package:hamzain_traders/core/constants/app_colors.dart';
import 'package:hamzain_traders/core/navigation/premium_page_route.dart';
import 'package:hamzain_traders/models/user_model.dart';
import 'package:hamzain_traders/screens/auth/login_screen.dart';
import 'package:hamzain_traders/screens/auth/register_screen.dart';
import 'package:hamzain_traders/screens/auth/signup_screen.dart';
import 'package:hamzain_traders/screens/main_shell.dart';
import 'package:hamzain_traders/screens/splash/splash_screen.dart';
import 'package:hamzain_traders/services/session_service.dart';

void main() {
  runApp(const HamZainTradersApp());
}

class HamZainTradersApp extends StatelessWidget {
  const HamZainTradersApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Hum Zen Traders',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: AppColors.surface,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            primary: AppColors.primary,
            surface: AppColors.surface,
          ),
          splashFactory: InkRipple.splashFactory,
        ),
        home: const SplashScreen());
  }
}

/// Decides where the app should land on startup based on whether a
/// session is already saved (previously this was hard-coded to a bare
/// [AppDrawer] with no login gate at all, which was the root cause of
/// "logged in" screens never actually seeing a logged-in user).
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel?>(
      future: SessionService.instance.getUser(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.primary,
            body: Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
        }

        final user = snapshot.data;
        if (user != null) return const MainShell();
        return RegisterScreen(
          onLoginPressed: () => Navigator.of(context).push(
            PremiumPageRoute(page: const LoginScreen()),
          ),
          onSignUpPressed: () => Navigator.of(context).push(
            PremiumPageRoute(page: const SignUpScreen()),
          ),
        );
      },
    );
  }
}

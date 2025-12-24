/// FasalPlanner App Configuration
///
/// This file contains the root MaterialApp configuration
/// with Material 3 theming and route definitions

import 'package:flutter/material.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/app_routes.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/crop/crop_recommendation_screen.dart';
import 'screens/crop/crop_selection_screen.dart';
import 'screens/calendar/farming_calendar_screen.dart';
import 'screens/fertilizer/fertilizer_planner_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/profile/user_input_screen.dart';

class FasalPlannerApp extends StatelessWidget {
  const FasalPlannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FasalPlanner',
      debugShowCheckedModeBanner: false,

      // Material 3 Theme Configuration
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryGreen,
          brightness: Brightness.light,
        ),

        // App Bar Theme
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),

        // Elevated Button Theme
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryGreen,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
        ),

        // Input Decoration Theme
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(
              color: AppColors.primaryGreen,
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),

        // Card Theme
        cardTheme: CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),

      // Initial Route
      initialRoute: AppRoutes.splash,

      // Route Definitions
      routes: {
        AppRoutes.splash: (context) => const SplashScreen(),
        AppRoutes.login: (context) => const LoginScreen(),
        AppRoutes.signup: (context) => const SignupScreen(),
        AppRoutes.dashboard: (context) => const DashboardScreen(),
        AppRoutes.cropRecommendation: (context) =>
            const CropRecommendationScreen(),
        AppRoutes.cropSelection: (context) => const CropSelectionScreen(),
        AppRoutes.farmingCalendar: (context) => const FarmingCalendarScreen(),
        AppRoutes.fertilizerPlanner: (context) =>
            const FertilizerPlannerScreen(),
        AppRoutes.profile: (context) => const ProfileScreen(),
        AppRoutes.userInput: (context) => const UserInputScreen(),
      },
    );
  }
}

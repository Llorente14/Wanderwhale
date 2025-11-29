import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/screens/auth/login_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'screens/main/welcome_screen.dart';
import 'screens/hotel/checkout_hotel.dart';
import 'screens/flight/checkout_flight.dart';


import 'core/navigation/app_routes.dart';
import 'core/theme/app_colors.dart';
import 'screens/chatbot/ai_chat.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/main/home_screen.dart';
import 'screens/trip/trip_list.dart';

import 'core/theme/app_colors.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions
        .currentPlatform, // if you have firebase_options.dart
  );
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions
        .currentPlatform, // if you have firebase_options.dart
  );
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Travel Planner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.white,
        fontFamily: 'SF Pro Display', // Anda bisa ganti dengan font pilihan
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.primaryLight1,
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: AppColors.primary),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.gray1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
      ),
      // initialRoute: AppRoutes.home,
      // routes: {
      //   AppRoutes.home: (_) => const HomeScreen(),
      //   AppRoutes.tripList: (_) => const TripList(),
      //   AppRoutes.aiChat: (_) => const AiChat(),
      // },
      initialRoute: AppRoutes.home, 
      routes: {
        AppRoutes.home: (_) => const HomeScreen(),
        AppRoutes.tripList: (_) => const TripList(),
        AppRoutes.aiChat: (_) => const AiChat(),
        AppRoutes.login: (_) => const LoginScreen(),
        // AppRoutes.checkout: (_) => const CheckoutFlightScreen(),
      },
    );
  }
}
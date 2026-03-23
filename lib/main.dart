import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'onboarding/onboarding_screen.dart';
import 'features/auth/auth_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

await Supabase.initialize(
    url: 'https://ajzbcueablsyljjtdstr.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFqemJjdWVhYmxzeWxqanRkc3RyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjM3NTU4MTMsImV4cCI6MjA3OTMzMTgxM30.FF4RWoPOCnVEIALPqz5AqBlXAEdsRzrWwug0dH3GeUo',
  );

  final prefs = await SharedPreferences.getInstance();
    // : onboarding reset
   await prefs.remove('seen_onboarding');
  final seenOnboarding = prefs.getBool('seen_onboarding') ?? false;

  runApp(MyApp(seenOnboarding: seenOnboarding));
}

class MyApp extends StatelessWidget {
  final bool seenOnboarding;
  const MyApp({super.key, required this.seenOnboarding});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: seenOnboarding ? const AuthScreen() : const OnboardingScreen(),
    );
  }
}

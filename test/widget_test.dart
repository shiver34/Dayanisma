import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://ajzbcueablsyljjtdstr.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFqemJjdWVhYmxzeWxqanRkc3RyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjM3NTU4MTMsImV4cCI6MjA3OTMzMTgxM30.FF4RWoPOCnVEIALPqz5AqBlXAEdsRzrWwug0dH3GeUo',
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(body: Center(child: Text("Giriş yapılmadı"))),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/shop_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ValoCheckApp());
}

class ValoCheckApp extends StatelessWidget {
  const ValoCheckApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ValoCheck Mobile',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F1923),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF4655),
          surface: Color(0xFF1F2B37),
        ),
        textTheme: GoogleFonts.interTextTheme(
          ThemeData.dark().textTheme,
        ),
      ),
      home: const ShopScreen(),
    );
  }
}

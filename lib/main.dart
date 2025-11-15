import 'package:app/screens/login_screen.dart';
import 'package:app/services/firebase_auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/register_pet_screen.dart';

const kBg = Color(0xFFF5F2ED); // creme do mock

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final firebaseAuth = FirebaseAuthService();
  await firebaseAuth.makeLogin("bauercaca@gmail.com", "123456");

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = GoogleFonts.poppinsTextTheme();

    return MaterialApp(
      title: 'ClickVet',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: kBg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8C7A3E),
          brightness: Brightness.light,
        ).copyWith(
          background: kBg,
          surface: kBg,
          onBackground: Colors.black87,
          onSurface: Colors.black87,
        ),
        canvasColor: kBg,
        appBarTheme: const AppBarTheme(
          backgroundColor: kBg,
          elevation: 0,
          foregroundColor: Colors.black87,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: kBg,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
          ),
        ),


        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.lightBlue,
            foregroundColor: Colors.white,
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),

        textTheme: textTheme,
      ),
      home: LoginScreen(),
      routes: {
        RegisterPetScreen.routeName: (_) => const RegisterPetScreen(),
      },
    );
  }
}


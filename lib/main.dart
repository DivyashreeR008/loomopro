import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:loomo/firebase_options.dart';
import 'package:loomo/screens/add_product_screen.dart';
import 'package:loomo/screens/chats_screen.dart';
import 'package:loomo/screens/customer_home_screen.dart';
import 'package:loomo/screens/customer_login_screen.dart';
import 'package:loomo/screens/seller_home_screen.dart';
import 'package:loomo/screens/seller_login_screen.dart';
import 'package:loomo/screens/welcome_screen.dart';

import 'package:loomo/screens/seller_registration_screen.dart';
import 'package:loomo/screens/customer_registration_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Loomo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
        ),
      ),
      home: const WelcomeScreen(),
      routes: {
        '/welcome': (context) => const WelcomeScreen(),
        '/seller-login': (context) => const SellerLoginScreen(),
        '/customer-login': (context) => const CustomerLoginScreen(),
        '/seller-home': (context) => const SellerHomeScreen(),
        '/customer-home': (context) => const CustomerHomeScreen(),
        '/seller-registration': (context) => const SellerRegistrationScreen(),
        '/customer-registration': (context) => const CustomerRegistrationScreen(),
        '/add-product': (context) => const AddProductScreen(),
        '/chats': (context) => const ChatsScreen(),
      },
    );
  }
}
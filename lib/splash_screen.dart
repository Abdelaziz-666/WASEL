import 'dart:async';
import 'package:flutter/material.dart';
import 'auth_gate.dart'; 

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AuthGate()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
         
            Image.asset(
              'assets/images/logo.png',
              width: 130,
              height: 130,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 20),
            const Text(
              'WASEL',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: Color(0xFF1E3A8A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

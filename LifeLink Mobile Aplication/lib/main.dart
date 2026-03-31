import 'package:flutter/material.dart';
import 'package:lifelink_app/src/screens/splash_screen.dart';

void main() {
  runApp(const LifeLinkApp());
}

class LifeLinkApp extends StatelessWidget {
  const LifeLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LifeLink',
      home: SplashScreen(),
    );
  }
}

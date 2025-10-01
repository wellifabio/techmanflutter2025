import 'dart:async';
import 'package:flutter/material.dart';
import 'package:techmanflutter2025/screens/_core/app_colors.dart';
import 'login.dart';

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _fadeController;

  double _scale = 0.0;
  double _opacity = 1.0;

  @override
  void initState() {
    super.initState();

    _scaleController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..addListener(() {
            setState(() {
              _scale = _scaleController.value;
            });
          });

    _fadeController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 800),
        )..addListener(() {
          setState(() {
            _opacity = 1.0 - _fadeController.value;
          });
        });

    _scaleController.forward();

    // Aguarda a animação terminar, depois faz o fade e navega
    Timer(const Duration(seconds: 2), () {
      _fadeController.forward();
    });

    // Navega para a login após fade
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Login()),
      );
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.c7,
      body: Center(
        child: Opacity(
          opacity: _opacity,
          child: Transform.scale(
            scale: _scale,
            child: Image.asset('assets/techman.png', width: 200, height: 200),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:techmanflutter2025/screens/_core/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  Future<void> sair() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_data');
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Login()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Home'), backgroundColor: AppColors.c5),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(onPressed: () => sair(), child: Text('Sair')),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:techmanflutter2025/screens/_core/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'home.dart';
import 'splash.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final String api = 'https://techman-api-2025.vercel.app';
  final ButtonStyle buttonStyle = ElevatedButton.styleFrom(
    backgroundColor: AppColors.c2,
    foregroundColor: AppColors.c6,
    textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    side: BorderSide(color: AppColors.c6, width: 1),
  );

  String senha = '';

  @override
  void initState() {
    super.initState();
    _conferePerfilSalvo();
  }

  Future<void> _conferePerfilSalvo() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('user_perfil')) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Home()),
        );
      }
    }
  }

  void pressButton(String num) {
    setState(() {
      if (num == 'C') {
        senha = '';
      } else {
        senha += num;
      }
    });
  }

  Future<void> toHome(String dados) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', dados);
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Home()),
      );
    }
  }

  Future<void> sendLogin() async {
    final url = Uri.parse('$api/login');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: '{"senha": "$senha"}',
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.c1,
            title: Text('Bem vindo(a)', style: TextStyle(color: AppColors.c5)),
            content: Text(
              data['perfil'] != 2 ? 'Perfil comum!' : 'Perfil admin!',
              style: TextStyle(color: AppColors.c6),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  final Map<String, dynamic> perfilData = json.decode(
                    response.body,
                  );
                  final perfil = perfilData['perfil'];
                  SharedPreferences.getInstance().then((prefs) {
                    prefs.setInt('user_perfil', perfil);
                  });
                  toHome(response.body);
                },
                child: Text('OK', style: TextStyle(color: AppColors.c6)),
              ),
            ],
          ),
        );
      } else {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.c1,
            title: Text('Erro', style: TextStyle(color: AppColors.c5)),
            content: Text(response.body, style: TextStyle(color: AppColors.c7)),
            actions: [
              TextButton(
                onPressed: () => {
                  Navigator.of(context).pop(),
                  setState(() {
                    senha = '';
                  }),
                },
                child: Text('OK', style: TextStyle(color: AppColors.c6)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.c1,
          title: Text('Erro de conexão', style: TextStyle(color: AppColors.c5)),
          content: Text(e.toString(), style: TextStyle(color: AppColors.c5)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK', style: TextStyle(color: AppColors.c5)),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.c1,
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const Splash()),
                  );
                },
                child: Image.asset("assets/techman.png"),
              ),
              SizedBox(height: 12),
              TextField(
                obscureText: true,
                controller: TextEditingController(text: senha),
                enabled: false,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Digite a senha',
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(50.0),
                child: SizedBox(
                  height: 450,
                  child: GridView.count(
                    crossAxisCount: 3,
                    mainAxisSpacing: 28,
                    crossAxisSpacing: 28,
                    children: [
                      ElevatedButton(
                        style: buttonStyle,
                        onPressed: () => pressButton('1'),
                        child: Text('1'),
                      ),
                      ElevatedButton(
                        style: buttonStyle,
                        onPressed: () => pressButton('2'),
                        child: Text('2'),
                      ),
                      ElevatedButton(
                        style: buttonStyle,
                        onPressed: () => pressButton('3'),
                        child: Text('3'),
                      ),
                      ElevatedButton(
                        style: buttonStyle,
                        onPressed: () => pressButton('4'),
                        child: Text('4'),
                      ),
                      ElevatedButton(
                        style: buttonStyle,
                        onPressed: () => pressButton('5'),
                        child: Text('5'),
                      ),
                      ElevatedButton(
                        style: buttonStyle,
                        onPressed: () => pressButton('6'),
                        child: Text('6'),
                      ),
                      ElevatedButton(
                        style: buttonStyle,
                        onPressed: () => pressButton('7'),
                        child: Text('7'),
                      ),
                      ElevatedButton(
                        style: buttonStyle,
                        onPressed: () => pressButton('8'),
                        child: Text('8'),
                      ),
                      ElevatedButton(
                        style: buttonStyle,
                        onPressed: () => pressButton('9'),
                        child: Text('9'),
                      ),
                      ElevatedButton(
                        style: buttonStyle,
                        onPressed: () => pressButton('C'),
                        child: Text('C'),
                      ),
                      ElevatedButton(
                        style: buttonStyle,
                        onPressed: () => pressButton('0'),
                        child: Text('0'),
                      ),
                      ElevatedButton(
                        style: senha.length >= 6
                            ? buttonStyle
                            : ElevatedButton.styleFrom(
                                textStyle: TextStyle(
                                  fontSize: 38,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                        onPressed: senha.length >= 6 ? sendLogin : null,
                        child: Text('↵'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

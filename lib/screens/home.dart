import 'package:flutter/material.dart';
import 'package:techmanflutter2025/screens/_core/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final String api = 'https://techman-api-2025.vercel.app';
  Map<String, dynamic> perfil = {};
  // listarEquipamentos implementada abaixo
  List<dynamic> equipamentos = [];
  bool carregando = true;

  @override
  void initState() {
    super.initState();
    listarEquipamentos();
    obterPerfil();
  }

  Future<void> obterPerfil() async {
    perfil =
        (await SharedPreferences.getInstance()).getInt('perfil')
            as Map<String, dynamic>;
  }

  Future<void> listarEquipamentos() async {
    setState(() {
      carregando = true;
    });
    try {
      final url = Uri.parse('$api/equipamento');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          equipamentos = data;
        });
      } else {
        // Em caso de erro, mantém lista vazia
        setState(() {
          equipamentos = [];
        });
      }
    } catch (e) {
      setState(() {
        equipamentos = [];
      });
    } finally {
      setState(() {
        carregando = false;
      });
    }
  }

  Future<void> _mostrarComentarios(String equipamentoId) async {
    try {
      final url = Uri.parse('$api/comentario/equipamento/$equipamentoId');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> comentarios = json.decode(response.body);
        if (!mounted) return;
        final TextEditingController _controller = TextEditingController();
        showDialog(
          context: context,
          builder: (context) => StatefulBuilder(
            builder: (context, setStateSB) => AlertDialog(
              title: const Text('Comentários'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    comentarios.isEmpty
                        ? const Text('Nenhum comentário encontrado')
                        : Flexible(
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: comentarios.length,
                              itemBuilder: (context, index) {
                                final c = comentarios[index];
                                final perfil = c['perfil'] ?? '';
                                final comentario = c['comentario'] ?? '';
                                return ListTile(
                                  title: Text(perfil.toString()),
                                  subtitle: Text(comentario.toString()),
                                );
                              },
                            ),
                          ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        labelText: 'Novo comentário',
                        border: OutlineInputBorder(),
                      ),
                      minLines: 1,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton(
                          onPressed: () async {
                            final texto = _controller.text.trim();
                            if (texto.isEmpty) return;
                            final ok = await _enviarComentario(
                              equipamentoId,
                              texto,
                            );
                            if (ok) {
                              // atualiza a lista localmente
                              setStateSB(() {
                                comentarios.add({
                                  'perfil': 1,
                                  'comentario': texto,
                                });
                                _controller.clear();
                              });
                            } else {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Erro ao enviar comentário'),
                                  ),
                                );
                              }
                            }
                          },
                          child: const Text('Enviar'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Fechar'),
                ),
              ],
            ),
          ),
        );
      } else {
        // não exibe nada em caso de erro
      }
    } catch (e) {
      // falha de conexão
    }
  }

  Future<bool> _enviarComentario(
    String equipamentoId,
    String comentario,
  ) async {
    try {
      final url = Uri.parse('$api/comentario');
      final equipamentoParsed = int.tryParse(equipamentoId) ?? equipamentoId;
      final body = json.encode({
        'equipamento': equipamentoParsed,
        'comentario': comentario,
        'perfil': perfil['perfil'] ?? 1,
      });
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );
      return response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }

  Future<void> _deletarEquipamento(String equipamentoId) async {
    try {
      final url = Uri.parse('$api/equipamento/$equipamentoId');
      final response = await http.delete(url);
      if (response.statusCode == 200 || response.statusCode == 204) {
        await listarEquipamentos();
      } else {
        // opcional: mostrar erro
      }
    } catch (e) {
      // opcional: tratar erro
    }
  }

  Widget _buildImageWidget(String imagem) {
    final img = imagem.toString().trim();
    const double w = 180, h = 180;
    if (img.isEmpty) {
      return Container(width: w, height: h, color: Colors.grey[300]);
    }
    if (img.startsWith('http://') || img.startsWith('https://')) {
      return Image.network(
        img,
        width: w,
        height: h,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            width: w,
            height: h,
            alignment: Alignment.center,
            child: const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(width: w, height: h, color: Colors.grey[300]);
        },
      );
    }
    // Fallback to local asset (assume filename or path relative to assets/)
    final assetPath = img.startsWith('assets/') ? img : 'assets/$img';
    return Image.asset(assetPath, width: w, height: h, fit: BoxFit.cover);
  }

  Future<void> sair() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_data');
    await prefs.remove('user_perfil');
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
      appBar: AppBar(
        title: Image.asset('assets/techman.png', width: 120, height: 60),
        backgroundColor: AppColors.c5,
        actions: [
          IconButton(
            onPressed: () => sair(),
            icon: Image.asset('assets/logout_sair.png', width: 28, height: 28),
            tooltip: 'Sair',
          ),
        ],
      ),
      body: carregando
          ? const Center(child: CircularProgressIndicator())
          : equipamentos.isEmpty
          ? Center(child: Text('Nenhum equipamento encontrado'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: equipamentos.length,
              itemBuilder: (context, index) {
                final item = equipamentos[index];
                final imagem = item['imagem'] ?? '';
                final equipamento = item['equipamento'] ?? '';
                final descricao = item['descricao'] ?? '';
                final data = item['data'] ?? '';
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildImageWidget(imagem),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                equipamento,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(descricao),
                              const SizedBox(height: 6),
                              Text(
                                data,
                                style: const TextStyle(color: Colors.grey),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    onPressed: () => _mostrarComentarios(
                                      item['id'].toString(),
                                    ),
                                    icon: Image.asset(
                                      'assets/comentario.png',
                                      width: 28,
                                      height: 28,
                                    ),
                                    tooltip: 'Comentários',
                                  ),
                                  IconButton(
                                    onPressed: () async {
                                      // confirmar exclusão
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Confirmar'),
                                          content: const Text(
                                            'Deseja deletar este equipamento?',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.of(
                                                context,
                                              ).pop(false),
                                              child: const Text('Não'),
                                            ),
                                            TextButton(
                                              onPressed: () => Navigator.of(
                                                context,
                                              ).pop(true),
                                              child: const Text('Sim'),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) {
                                        await _deletarEquipamento(
                                          item['id'].toString(),
                                        );
                                      }
                                    },
                                    icon: Image.asset(
                                      'assets/deletar.png',
                                      width: 28,
                                      height: 28,
                                    ),
                                    tooltip: 'Deletar',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

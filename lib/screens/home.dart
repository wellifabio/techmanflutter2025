import 'package:flutter/material.dart';
import 'package:techmanflutter2025/api.dart';
import 'package:techmanflutter2025/screens/_core/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'login.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List<dynamic> equipamentos = [];
  bool carregando = true;
  int? perfil;

  @override
  void initState() {
    super.initState();
    listarEquipamentos();
  }

  Future<void> listarEquipamentos() async {
    setState(() {
      carregando = true;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.containsKey('user_perfil')) {
        setState(() {
          perfil = prefs.getInt('user_perfil');
        });
      }
      final url = Uri.parse('${Api.getEndPoint('equipamento')}');
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
      final url = Uri.parse(
        '${Api.getEndPoint('comentario/equipamento/$equipamentoId')}',
      );
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
                                final perf = c['perfil'] ?? '';
                                final comentario = c['comentario'] ?? '';
                                final rawData = c['data'];
                                String data;
                                try {
                                  if (rawData == null) {
                                    data = '';
                                  } else {
                                    // tenta parsear como ISO8601 e formatar para pt-BR
                                    final dt = DateTime.parse(
                                      rawData.toString(),
                                    );
                                    data = DateFormat(
                                      'dd/MM/yyyy HH:mm',
                                    ).format(dt.toLocal());
                                  }
                                } catch (e) {
                                  // se falhar, mostra o valor cru
                                  data = rawData?.toString() ?? '';
                                }
                                return ListTile(
                                  title: perf != 2
                                      ? Text('Perfil comum')
                                      : Text('Perfil admin'),
                                  subtitle: Text(
                                    'Texto: $comentario\nData: $data',
                                  ),
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
                              setStateSB(() {
                                comentarios.add({
                                  'perfil': perfil,
                                  'comentario': texto,
                                  'data': 'agora',
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
      final url = Uri.parse('${Api.getEndPoint('comentario')}');
      final equipamentoParsed = int.tryParse(equipamentoId) ?? equipamentoId;
      final body = json.encode({
        'equipamento': equipamentoParsed,
        'comentario': comentario,
        'perfil': 1,
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
      final url = Uri.parse('${Api.getEndPoint('equipamento/$equipamentoId')}');
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
    const double w = 300, h = 300;
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

  Future<void> novoEquipamento() async {
    final _formKey = GlobalKey<FormState>();
    final TextEditingController equipamentoCtrl = TextEditingController();
    final TextEditingController imagemCtrl = TextEditingController();
    final TextEditingController descricaoCtrl = TextEditingController();
    bool ativo = true;

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateSB) {
          return AlertDialog(
            title: const Text('Novo equipamento'),
            content: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: equipamentoCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Equipamento',
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Informe o nome'
                          : null,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: imagemCtrl,
                      decoration: const InputDecoration(
                        labelText: 'URL da imagem',
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Informe a URL'
                          : null,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: descricaoCtrl,
                      decoration: const InputDecoration(labelText: 'Descrição'),
                      minLines: 2,
                      maxLines: 4,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Checkbox(
                          value: ativo,
                          onChanged: (v) => setStateSB(() => ativo = v ?? true),
                        ),
                        const SizedBox(width: 8),
                        const Text('Ativo'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (!_formKey.currentState!.validate()) return;
                  final payload = json.encode({
                    'equipamento': equipamentoCtrl.text.trim(),
                    'imagem': imagemCtrl.text.trim(),
                    'descricao': descricaoCtrl.text.trim(),
                    'ativo': ativo ? 1 : 0,
                  });
                  try {
                    final url = Uri.parse('${Api.getEndPoint('equipamento')}');
                    final resp = await http.post(
                      url,
                      headers: {'Content-Type': 'application/json'},
                      body: payload,
                    );
                    if (resp.statusCode == 200 || resp.statusCode == 201) {
                      Navigator.of(context).pop();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Equipamento criado com sucesso'),
                          ),
                        );
                        await listarEquipamentos();
                      }
                    } else {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Erro: ${resp.statusCode}')),
                        );
                      }
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Falha ao conectar com a API'),
                        ),
                      );
                    }
                  }
                },
                child: const Text('Salvar'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Image.asset('assets/techman.png', width: 120, height: 60),
        backgroundColor: AppColors.c5,
        actions: [
          if (perfil == 2)
            IconButton(
              onPressed: () => novoEquipamento(),
              icon: Text(
                'Novo equipamento',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.c3,
                ),
              ),
              tooltip: 'Novo',
            ),
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
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildImageWidget(imagem),
                              Text(
                                equipamento,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                descricao,
                                style: const TextStyle(
                                  fontStyle: FontStyle.italic,
                                ),
                                textAlign: TextAlign.justify,
                              ),
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
                                  // Mostrar botão de deletar apenas para perfil administrador (2)
                                  if (perfil == 2) ...[
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

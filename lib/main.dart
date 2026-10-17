import 'package:flutter/material.dart';
import 'screens/inicio.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const Aplicativo());
}

class Aplicativo extends StatelessWidget {
  const Aplicativo({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
      title: 'Gestão de Manutenção',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const Acesso());
}

class Acesso extends StatefulWidget {
  const Acesso({super.key});
  @override
  State<Acesso> createState() => _AcessoState();
}

class _AcessoState extends State<Acesso> {
  final nome = TextEditingController();
  @override
  void dispose() {
    nome.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      body: Center(
          child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.build_circle_outlined, size: 76),
                    const SizedBox(height: 16),
                    const Text('Gestão de Manutenção',
                        style: TextStyle(
                            fontSize: 25, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 24),
                    TextField(
                        controller: nome,
                        decoration: const InputDecoration(
                            labelText: 'Identificação do usuário',
                            border: OutlineInputBorder())),
                    const SizedBox(height: 16),
                    FilledButton(
                        onPressed: () {
                          if (nome.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Informe seu nome.')));
                            return;
                          }
                          Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      Inicio(usuario: nome.text.trim())));
                        },
                        child: const Text('Entrar'))
                  ])))));
}

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/banco.dart';
import '../models/ordem.dart';

const campos = <String, List<String>>{
  'clientes': ['nome', 'documento', 'telefone', 'email', 'endereco'],
  'tecnicos': ['nome', 'contato', 'especialidade', 'situacao'],
  'equipamentos': [
    'cliente_id',
    'tipo',
    'marca',
    'modelo',
    'serie',
    'patrimonio',
    'observacoes'
  ]
};
const titulos = {
  'clientes': 'Clientes',
  'tecnicos': 'Técnicos',
  'equipamentos': 'Equipamentos'
};
const estados = [
  'Aberta',
  'Atribuída',
  'Em atendimento',
  'Aguardando peça',
  'Concluída',
  'Cancelada'
];
const prioridades = ['Baixa', 'Média', 'Alta', 'Urgente'];
const transicoes = <String, List<String>>{
  'Aberta': ['Atribuída', 'Cancelada'],
  'Atribuída': ['Em atendimento', 'Cancelada'],
  'Em atendimento': ['Aguardando peça', 'Concluída', 'Cancelada'],
  'Aguardando peça': ['Em atendimento', 'Cancelada'],
  'Concluída': [],
  'Cancelada': []
};

class Inicio extends StatefulWidget {
  final String usuario;
  const Inicio({super.key, required this.usuario});
  @override
  State<Inicio> createState() => _InicioState();
}

class _InicioState extends State<Inicio> {
  int pagina = 0;
  int versao = 0;
  void atualizar() => setState(() => versao++);
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: Text('Manutenção • ${widget.usuario}')),
      body: IndexedStack(index: pagina, children: [
        Painel(key: ValueKey('p$versao')),
        ListaOrdens(key: ValueKey('o$versao'), atualizar: atualizar),
        for (final t in campos.keys)
          Cadastro(key: ValueKey('$t$versao'), tabela: t, atualizar: atualizar)
      ]),
      bottomNavigationBar: NavigationBar(
          selectedIndex: pagina,
          onDestinationSelected: (v) => setState(() => pagina = v),
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.dashboard_outlined), label: 'Painel'),
            NavigationDestination(
                icon: Icon(Icons.assignment_outlined), label: 'Ordens'),
            NavigationDestination(
                icon: Icon(Icons.people_outline), label: 'Clientes'),
            NavigationDestination(
                icon: Icon(Icons.engineering_outlined), label: 'Técnicos'),
            NavigationDestination(
                icon: Icon(Icons.devices_outlined), label: 'Equip.')
          ]));
}

class Painel extends StatelessWidget {
  const Painel({super.key});
  @override
  Widget build(BuildContext context) => FutureBuilder(
      future: Banco.instance.listar('ordens'),
      builder: (context, s) {
        if (s.hasError)
          return const Center(
              child: Text('Não foi possível carregar os dados.'));
        if (!s.hasData) return const Center(child: CircularProgressIndicator());
        final os = s.data!.map((e) => Ordem.fromMap(e)).toList();
        final dados = {
          'Total': os.length,
          'Abertas': os.where((o) => o.status == 'Aberta').length,
          'Em atendimento':
              os.where((o) => o.status == 'Em atendimento').length,
          'Aguardando peça':
              os.where((o) => o.status == 'Aguardando peça').length,
          'Concluídas': os.where((o) => o.status == 'Concluída').length,
          'Urgentes': os.where((o) => o.prioridade == 'Urgente').length,
          'Atrasadas': os.where((o) => o.atrasada).length
        };
        return ListView(padding: const EdgeInsets.all(16), children: [
          const Text('Resumo dos atendimentos',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(spacing: 12, runSpacing: 12, children: [
            for (final d in dados.entries)
              Card(
                  child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(children: [
                        Text(d.key),
                        Text('${d.value}',
                            style: const TextStyle(
                                fontSize: 26, fontWeight: FontWeight.bold))
                      ])))
          ]),
          const SizedBox(height: 16),
          Text(
              'Valor total registrado: R\$ ${os.fold<double>(0, (s, o) => s + o.total).toStringAsFixed(2)}')
        ]);
      });
}

class Cadastro extends StatefulWidget {
  final String tabela;
  final VoidCallback atualizar;
  const Cadastro({super.key, required this.tabela, required this.atualizar});
  @override
  State<Cadastro> createState() => _CadastroState();
}

class _CadastroState extends State<Cadastro> {
  Future<void> editar([Map<String, Object?>? item]) async {
    final controles = {
      for (final c in campos[widget.tabela]!)
        c: TextEditingController(text: item?[c]?.toString() ?? '')
    };
    final chave = GlobalKey<FormState>();
    final clientes = await Banco.instance.listar('clientes');
    if (!mounted) return;
    if (widget.tabela == 'equipamentos' && clientes.isEmpty) {
      mensagem(context, 'Cadastre um cliente primeiro.');
      return;
    }
    int? clienteSelecionado = item?['cliente_id'] as int? ??
        (clientes.isNotEmpty ? clientes.first['id'] as int : null);
    final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => StatefulBuilder(
            builder: (ctx, atualizarDialog) => AlertDialog(
                    title: Text(
                        item == null ? 'Novo cadastro' : 'Editar cadastro'),
                    content: SizedBox(
                        width: 420,
                        child: Form(
                            key: chave,
                            child: SingleChildScrollView(
                                child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                  for (final c in campos[widget.tabela]!)
                                    if (c == 'cliente_id')
                                      DropdownButtonFormField<int>(
                                          value: clienteSelecionado,
                                          decoration: const InputDecoration(
                                              labelText: 'Cliente'),
                                          items: [
                                            for (final a in clientes)
                                              DropdownMenuItem(
                                                  value: a['id'] as int,
                                                  child: Text('${a['nome']}'))
                                          ],
                                          onChanged: (v) => atualizarDialog(
                                              () => clienteSelecionado = v))
                                    else
                                      Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 8),
                                          child: TextFormField(
                                              controller: controles[c],
                                              decoration:
                                                  InputDecoration(labelText: c),
                                              validator: (v) {
                                                if ([
                                                      'nome',
                                                      'documento',
                                                      'telefone',
                                                      'tipo',
                                                      'marca',
                                                      'modelo',
                                                      'contato',
                                                      'especialidade',
                                                      'situacao'
                                                    ].contains(c) &&
                                                    (v == null ||
                                                        v.trim().isEmpty))
                                                  return 'Campo obrigatório';
                                                if (c == 'telefone') {
                                                  final digitos = (v ?? '')
                                                      .replaceAll(RegExp(r'\D'), '');
                                                  if (digitos.length != 10 &&
                                                      digitos.length != 11) {
                                                    return 'Telefone inválido. Informe 10 ou 11 dígitos.';
                                                  }
                                                }
                                                if (c == 'email' &&
                                                    v != null &&
                                                    v.isNotEmpty &&
                                                    !v.contains('@'))
                                                  return 'E-mail inválido';
                                                return null;
                                              }))
                                ])))),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancelar')),
                      FilledButton(
                          onPressed: () {
                            if (chave.currentState!.validate())
                              Navigator.pop(ctx, true);
                          },
                          child: const Text('Salvar'))
                    ])));
    if (ok == true) {
      try {
        await Banco.instance.salvar(widget.tabela, {
          'id': item?['id'],
          for (final c in campos[widget.tabela]!)
            c: c == 'cliente_id'
                ? clienteSelecionado
                : controles[c]!.text.trim()
        });
        widget.atualizar();
      } catch (_) {
        if (mounted) mensagem(context, 'Não foi possível salvar o cadastro.');
      }
    }
    for (final c in controles.values) c.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      FutureBuilder<List<Map<String, Object?>>>(
        future: Banco.instance.listar(widget.tabela),
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return const Center(
                child: Text('Não foi possível carregar os registros.'));
          return Scaffold(
            floatingActionButton: FloatingActionButton(
                onPressed: () => editar(), child: const Icon(Icons.add)),
            body: !snapshot.hasData
                ? const Center(child: CircularProgressIndicator())
                : ListView(children: [
                    Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(titulos[widget.tabela]!,
                            style: const TextStyle(
                                fontSize: 22, fontWeight: FontWeight.bold))),
                    for (final item in snapshot.data!)
                      ListTile(
                        title: Text('${item['nome'] ?? item['tipo']}'),
                        subtitle: Text(item.entries
                            .where((e) => e.key != 'id')
                            .map((e) => '${e.key}: ${e.value}')
                            .join(' - ')),
                        trailing: Wrap(children: [
                          IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => editar(item)),
                          IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () async {
                                if (await confirmar(context)) {
                                  try {
                                    await Banco.instance.excluir(
                                        widget.tabela, item['id'] as int);
                                    widget.atualizar();
                                  } catch (_) {
                                    if (context.mounted)
                                      mensagem(context,
                                          'Registro vinculado a outro cadastro.');
                                  }
                                }
                              }),
                        ]),
                      ),
                  ]),
          );
        },
      );
}

Future<bool> confirmar(BuildContext context) async =>
    await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
                title: const Text('Confirmar exclusão?'),
                content: const Text('Esta ação não pode ser desfeita.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancelar')),
                  FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Excluir'))
                ])) ??
    false;
void mensagem(BuildContext context, String texto) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));

class ListaOrdens extends StatefulWidget {
  final VoidCallback atualizar;
  const ListaOrdens({super.key, required this.atualizar});
  @override
  State<ListaOrdens> createState() => _ListaOrdensState();
}

class _ListaOrdensState extends State<ListaOrdens> {
  String busca = '', status = 'Todos', prioridade = 'Todas';
  Future<void> editar([Ordem? ordem]) async {
    await Navigator.push(context,
        MaterialPageRoute(builder: (_) => FormularioOrdem(ordem: ordem)));
    widget.atualizar();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder(
      future: Future.wait([
        Banco.instance.listar('ordens'),
        Banco.instance.listar('clientes'),
        Banco.instance.listar('equipamentos'),
        Banco.instance.listar('tecnicos')
      ]),
      builder: (context, s) {
        if (s.hasError)
          return const Center(
              child: Text('Não foi possível carregar os dados.'));
        if (!s.hasData) return const Center(child: CircularProgressIndicator());
        final listas = s.data!;
        final clientes = {for (final c in listas[1]) c['id']: '${c['nome']}'};
        final equipamentos = {
          for (final c in listas[2]) c['id']: '${c['tipo']} ${c['modelo']}'
        };
        final tecnicos = {for (final c in listas[3]) c['id']: '${c['nome']}'};
        final ordens = listas[0].map(Ordem.fromMap).where((o) {
          final texto =
              '${o.id} ${clientes[o.clienteId]} ${equipamentos[o.equipamentoId]} ${tecnicos[o.tecnicoId]}'
                  .toLowerCase();
          return texto.contains(busca.toLowerCase()) &&
              (status == 'Todos' || o.status == status) &&
              (prioridade == 'Todas' || o.prioridade == prioridade);
        }).toList();
        return Scaffold(
            floatingActionButton: FloatingActionButton.extended(
                onPressed: () => editar(),
                icon: const Icon(Icons.add),
                label: const Text('Nova OS')),
            body: ListView(padding: const EdgeInsets.all(12), children: [
              TextField(
                  decoration: const InputDecoration(
                      labelText:
                          'Buscar número, cliente, equipamento ou técnico',
                      prefixIcon: Icon(Icons.search)),
                  onChanged: (v) => setState(() => busca = v)),
              Wrap(spacing: 12, children: [
                DropdownButton<String>(
                    value: status,
                    items: ['Todos', ...estados]
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => setState(() => status = v!)),
                DropdownButton<String>(
                    value: prioridade,
                    items: ['Todas', ...prioridades]
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => setState(() => prioridade = v!))
              ]),
              for (final o in ordens)
                Card(
                    child: ListTile(
                        title: Text(
                            'OS #${o.id} • ${clientes[o.clienteId] ?? 'Cliente'}'),
                        subtitle: Text(
                            '${equipamentos[o.equipamentoId] ?? 'Equipamento'} • ${o.status} • ${o.prioridade}${o.atrasada ? ' • ATRASADA' : ''}\nTécnico: ${tecnicos[o.tecnicoId] ?? 'Não atribuído'} • R\$ ${o.total.toStringAsFixed(2)}'),
                        isThreeLine: true,
                        onTap: () => editar(o),
                        trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () async {
                              if (await confirmar(context)) {
                                try {
                                  await Banco.instance.excluir('ordens', o.id!);
                                  widget.atualizar();
                                } catch (_) {
                                  if (context.mounted)
                                    mensagem(context,
                                        'Não foi possível excluir a ordem.');
                                }
                              }
                            })))
            ]));
      });
}

class FormularioOrdem extends StatefulWidget {
  final Ordem? ordem;
  const FormularioOrdem({super.key, this.ordem});
  @override
  State<FormularioOrdem> createState() => _FormularioOrdemState();
}

class _FormularioOrdemState extends State<FormularioOrdem> {
  final form = GlobalKey<FormState>();
  late final Map<String, TextEditingController> c;
  int? cliente, equipamento, tecnico;
  late String status, prioridade;
  String imagem = '';
  @override
  void initState() {
    super.initState();
    final o = widget.ordem;
    cliente = o?.clienteId;
    equipamento = o?.equipamentoId;
    tecnico = o?.tecnicoId;
    status = o?.status ?? 'Aberta';
    prioridade = o?.prioridade ?? 'Média';
    imagem = o?.imagem ?? '';
    c = {
      'problema': TextEditingController(text: o?.problema ?? ''),
      'diagnostico': TextEditingController(text: o?.diagnostico ?? ''),
      'solucao': TextEditingController(text: o?.solucao ?? ''),
      'prazo': TextEditingController(text: o?.prazo ?? ''),
      'mao_obra': TextEditingController(text: '${o?.maoObra ?? 0}'),
      'pecas': TextEditingController(text: '${o?.pecas ?? 0}')
    };
  }

  @override
  void dispose() {
    for (final x in c.values) x.dispose();
    super.dispose();
  }

  Future<void> salvar() async {
    if (!form.currentState!.validate()) return;
    if (cliente == null || equipamento == null) {
      mensagem(
          context, 'Cadastre um cliente e um equipamento antes de continuar.');
      return;
    }
    final anterior = widget.ordem?.status;
    if (anterior != null &&
        status != anterior &&
        !(transicoes[anterior] ?? []).contains(status)) {
      mensagem(context, 'Mudança de status não permitida.');
      return;
    }
    if (status == 'Concluída' &&
        c['diagnostico']!.text.trim().isEmpty &&
        c['solucao']!.text.trim().isEmpty) {
      mensagem(context, 'Informe diagnóstico ou solução antes de concluir.');
      return;
    }
    final o = Ordem(
        id: widget.ordem?.id,
        clienteId: cliente!,
        equipamentoId: equipamento!,
        tecnicoId: tecnico,
        problema: c['problema']!.text.trim(),
        diagnostico: c['diagnostico']!.text.trim(),
        solucao: c['solucao']!.text.trim(),
        status: status,
        prioridade: prioridade,
        prazo: c['prazo']!.text.trim(),
        imagem: imagem,
        maoObra: double.parse(c['mao_obra']!.text.replaceAll(',', '.')),
        pecas: double.parse(c['pecas']!.text.replaceAll(',', '.')));
    try {
      final id = await Banco.instance.salvar('ordens', o.toMap());
      if (anterior != status || anterior == null)
        await Banco.instance.registrarStatus(id, status);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted)
        mensagem(context, 'Erro ao salvar. Confira os vínculos e os valores.');
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder(
      future: Future.wait([
        Banco.instance.listar('clientes'),
        Banco.instance.listar('equipamentos'),
        Banco.instance.listar('tecnicos')
      ]),
      builder: (context, s) {
        if (!s.hasData)
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        final dados = s.data!;
        final clientes = dados[0], tecnicos = dados[2];
        if (cliente == null && clientes.isNotEmpty)
          cliente = clientes.first['id'] as int;
        final equipamentos =
            dados[1].where((e) => e['cliente_id'] == cliente).toList();
        if (!equipamentos.any((e) => e['id'] == equipamento))
          equipamento =
              equipamentos.isNotEmpty ? equipamentos.first['id'] as int : null;
        Widget campo(String nome,
                {bool obrigatorio = false, bool numero = false}) =>
            Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextFormField(
                    controller: c[nome],
                    keyboardType: numero
                        ? const TextInputType.numberWithOptions(decimal: true)
                        : TextInputType.text,
                    decoration: InputDecoration(
                        labelText: nome == 'prazo'
                            ? 'Prazo (AAAA-MM-DD)'
                            : nome.replaceAll('_', ' '),
                        border: const OutlineInputBorder()),
                    validator: (v) {
                      if (obrigatorio && (v == null || v.trim().isEmpty))
                        return 'Obrigatório';
                      if (numero &&
                          (double.tryParse((v ?? '').replaceAll(',', '.')) ==
                                  null ||
                              double.parse(v!.replaceAll(',', '.')) < 0))
                        return 'Informe valor válido';
                      if (nome == 'prazo' &&
                          v!.isNotEmpty &&
                          DateTime.tryParse(v) == null) return 'Data inválida';
                      return null;
                    }));
        Widget selecao(
                String rotulo,
                int? valor,
                List<Map<String, Object?>> itens,
                ValueChanged<int?> mudar,
                String Function(Map<String, Object?>) nome) =>
            Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DropdownButtonFormField<int>(
                    value: itens.any((e) => e['id'] == valor) ? valor : null,
                    decoration: InputDecoration(
                        labelText: rotulo, border: const OutlineInputBorder()),
                    items: [
                      for (final i in itens)
                        DropdownMenuItem(
                            value: i['id'] as int, child: Text(nome(i)))
                    ],
                    onChanged: mudar,
                    validator: (v) => rotulo != 'Técnico' && v == null
                        ? 'Obrigatório'
                        : null));
        return Scaffold(
            appBar: AppBar(
                title: Text(widget.ordem == null
                    ? 'Nova ordem de serviço'
                    : 'OS #${widget.ordem!.id}')),
            body: Form(
                key: form,
                child: ListView(padding: const EdgeInsets.all(16), children: [
                  selecao(
                      'Cliente',
                      cliente,
                      clientes,
                      (v) => setState(() {
                            cliente = v;
                            equipamento = null;
                          }),
                      (i) => '${i['nome']}'),
                  selecao(
                      'Equipamento',
                      equipamento,
                      equipamentos,
                      (v) => setState(() => equipamento = v),
                      (i) => '${i['tipo']} • ${i['modelo']}'),
                  selecao(
                      'Técnico',
                      tecnico,
                      tecnicos,
                      (v) => setState(() => tecnico = v),
                      (i) => '${i['nome']}'),
                  campo('problema', obrigatorio: true),
                  campo('diagnostico'),
                  campo('solucao'),
                  campo('prazo'),
                  DropdownButtonFormField<String>(
                      value: prioridade,
                      decoration:
                          const InputDecoration(labelText: 'Prioridade'),
                      items: prioridades
                          .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (v) => setState(() => prioridade = v!)),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                      value: status,
                      decoration: const InputDecoration(labelText: 'Status'),
                      items: estados
                          .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (v) => setState(() => status = v!)),
                  const SizedBox(height: 12),
                  campo('mao_obra', numero: true),
                  campo('pecas', numero: true),
                  OutlinedButton.icon(
                      onPressed: () async {
                        final arquivo = await FilePicker.platform
                            .pickFiles(type: FileType.image);
                        if (arquivo != null &&
                            arquivo.files.single.path != null)
                          setState(() => imagem = arquivo.files.single.path!);
                      },
                      icon: const Icon(Icons.image_outlined),
                      label: Text(imagem.isEmpty
                          ? 'Selecionar imagem'
                          : 'Imagem selecionada')),
                  if (widget.ordem?.id != null)
                    FutureBuilder(
                        future: Banco.instance.historico(widget.ordem!.id!),
                        builder: (context, h) => h.hasData
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                    const Text('Histórico de status',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    for (final x in h.data!)
                                      Text('${x['status']} • ${x['data']}')
                                  ])
                            : const SizedBox.shrink()),
                  const SizedBox(height: 18),
                  FilledButton(
                      onPressed: salvar, child: const Text('Salvar ordem'))
                ])));
      });
}

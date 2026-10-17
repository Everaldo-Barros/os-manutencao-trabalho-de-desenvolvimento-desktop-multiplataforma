class Ordem {
  final int? id;
  final int clienteId;
  final int equipamentoId;
  final int? tecnicoId;
  final String problema,
      diagnostico,
      solucao,
      status,
      prioridade,
      prazo,
      imagem;
  final double maoObra, pecas;
  const Ordem(
      {this.id,
      required this.clienteId,
      required this.equipamentoId,
      this.tecnicoId,
      required this.problema,
      this.diagnostico = '',
      this.solucao = '',
      this.status = 'Aberta',
      this.prioridade = 'Média',
      this.prazo = '',
      this.imagem = '',
      this.maoObra = 0,
      this.pecas = 0});
  double get total => maoObra + pecas;
  bool get atrasada =>
      prazo.isNotEmpty &&
      DateTime.tryParse(prazo) != null &&
      DateTime.parse(prazo).isBefore(DateTime(
          DateTime.now().year, DateTime.now().month, DateTime.now().day)) &&
      status != 'Concluída' &&
      status != 'Cancelada';
  Map<String, Object?> toMap() => {
        'id': id,
        'cliente_id': clienteId,
        'equipamento_id': equipamentoId,
        'tecnico_id': tecnicoId,
        'problema': problema,
        'diagnostico': diagnostico,
        'solucao': solucao,
        'status': status,
        'prioridade': prioridade,
        'prazo': prazo,
        'imagem': imagem,
        'mao_obra': maoObra,
        'pecas': pecas
      };
  factory Ordem.fromMap(Map<String, Object?> m) => Ordem(
      id: m['id'] as int?,
      clienteId: m['cliente_id'] as int,
      equipamentoId: m['equipamento_id'] as int,
      tecnicoId: m['tecnico_id'] as int?,
      problema: m['problema'] as String,
      diagnostico: m['diagnostico'] as String,
      solucao: m['solucao'] as String,
      status: m['status'] as String,
      prioridade: m['prioridade'] as String,
      prazo: m['prazo'] as String,
      imagem: m['imagem'] as String,
      maoObra: (m['mao_obra'] as num).toDouble(),
      pecas: (m['pecas'] as num).toDouble());
}

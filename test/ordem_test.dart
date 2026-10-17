import 'package:flutter_test/flutter_test.dart';
import 'package:gestao_manutencao/models/ordem.dart';
void main(){test('soma peças e mão de obra',(){const o=Ordem(clienteId:1,equipamentoId:1,problema:'Falha',maoObra:120,pecas:35);expect(o.total,155);});}

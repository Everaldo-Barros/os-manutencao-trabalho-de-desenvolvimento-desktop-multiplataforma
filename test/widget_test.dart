import 'package:flutter_test/flutter_test.dart';
import 'package:gestao_manutencao/main.dart';

void main() {
  testWidgets('Exibe a identificação do usuário', (tester) async {
    await tester.pumpWidget(const Aplicativo());
    expect(find.text('Gestão de Manutenção'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
  });
}

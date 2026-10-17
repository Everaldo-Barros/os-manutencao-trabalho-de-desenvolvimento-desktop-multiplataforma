# Gestão de Manutenção

Aplicativo Flutter para controle local de ordens de serviço. Possui identificação inicial, cadastro de clientes, técnicos e equipamentos, abertura e edição de OS, filtros, indicadores, histórico de status, anexação de caminho de imagem e armazenamento SQLite.

## Como executar

1. Instale Flutter SDK e as ferramentas da plataforma de destino.
2. Nesta pasta, execute `flutter create . --platforms=windows,linux,macos,android` para gerar os arquivos nativos correspondentes ao seu ambiente.
3. Execute `flutter pub get`.
4. Execute `flutter run -d windows` (ou substitua pelo dispositivo disponível).

O aplicativo usa `sqflite_common_ffi` no desktop e `sqflite` em dispositivos móveis. O banco é criado automaticamente no diretório de suporte do aplicativo.

## Fluxo da OS

Aberta → Atribuída → Em atendimento → Aguardando peça → Em atendimento → Concluída. O cancelamento é permitido antes da conclusão. A conclusão exige diagnóstico ou solução. Exclusões de cadastros vinculados são bloqueadas pelas chaves estrangeiras.

## Observações

A identificação inicial não substitui autenticação com senha. O anexo armazena o caminho do arquivo escolhido; mover ou apagar a imagem original poderá invalidar a referência. Para uso em produção, recomenda-se copiar anexos para o armazenamento do aplicativo e implementar backup e controle de acesso.

## Validação

Este pacote não foi compilado neste ambiente porque o Flutter SDK não está instalado. Execute `flutter analyze` e `flutter test` após configurar o SDK e faça testes manuais de cadastros, filtros, persistência e fluxo de status antes da entrega.

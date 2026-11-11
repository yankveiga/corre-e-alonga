# AlongaPET
Aplicativo mobile original em Flutter/Dart para Android e iOS. MVP local de treinos intervalados; sem conta e sem servidor.

- Editor de aquecimento, corrida, recuperação entre corridas, repetições e desaquecimento.
- Motor monotônico com pausa, retomada, término e recuperação pausada do último checkpoint.
- Bip original local, TTS do aparelho e feedback tátil configuráveis.
- Drift/SQLite para treinos, preferências e atividades, com finalização transacional.
- GPS opcional com filtro de sinal, percurso local, mapa OSM opcional online, km/milhas e evolução semanal.
- Mapa de território local: circuitos fechados são detectados e sua área aproximada é exibida no aparelho.
- Temas claro/escuro/sistema, navegação GoRouter, injeção Riverpod e camadas separadas.

Nesta versão o treino **pausa ao sair do aplicativo ou bloquear a tela**. GPS em primeiro plano, percurso e mapas estão implementados; notificações e execução contínua em segundo plano ainda não foram entregues. Não usar como versão de produção para corrida sob bloqueio.

O conceito territorial é local no MVP. Disputa entre pessoas, defesa de áreas, clubes, ranking e sincronização exigem um backend ainda não implementado.

## Executar
Requer Flutter estável recente e Dart >=3.11 (consultar versão validada em docs/03-validacao.md).

```sh
flutter pub get
flutter analyze
flutter test --concurrency=1
flutter run
flutter test integration_test/app_test.dart -d <device-id>
flutter build apk --debug
```

iOS requer macOS/Xcode, CocoaPods conforme setup Flutter e assinatura para aparelho. Ao usar Swift Package Manager, execute com `BYPASS_PERMISSION_LOCATION_ALWAYS=1 flutter build ios` conforme o plugin Geolocator; CocoaPods já tem o flag no Podfile. Para o SDK isolado desta sessão, usar `/home/ssd/.local/share/corre-alonga/flutter/bin/flutter`; O SDK fica separado dos outros projetos. O lockfile fixa as dependências resolvidas. O script `tool/build_android_debug.sh` gera APK de depuração ARM64 com SDK Android explícito e memória limitada (defina `ANDROID_HOME` e `FLUTTER_BIN`). Para executar as verificações em sequência, use `FLUTTER_BIN=/home/ssd/.local/share/corre-alonga/flutter/bin/flutter ./tool/check.sh`.

## Documentação
- [Investigação e matriz de evidências](docs/01-investigacao.md)
- [Arquitetura, dependências e próximas etapas](docs/02-arquitetura.md)
- [Resultados e limitações](docs/03-validacao.md)
- [Identidade visual](DESIGN.md)

Nenhum código, marca ou recurso do aplicativo de referência foi copiado. A confirmação de recursos por fontes públicas não representa observação do app em execução.

O workspace do VS Code aponta para o SDK isolado atual. Para usar `flutter run` diretamente, confira também o caminho global do Android SDK (`flutter config --list`); nesta máquina o script de build usa `/home/ssd/Android/Sdk` de forma explícita, preservando a configuração global.

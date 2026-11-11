# Arquitetura e plano

Flutter/Dart; apresentação → controlador → domínio; repositório e áudio por interfaces. Domínio não importa Flutter. Riverpod injeta estado/repositório; GoRouter concentra rotas. Drift/SQLite persiste treinos, preferências, atividades e checkpoint transacional. Banco local, sem backend e sem conta.

## Etapas
1. Investigação documental: matriz em 01-investigacao.md; REA do alvo pendente de acesso.
2. MVP: editor, execução monotônica, pausa/retomada/finalização, sinal sonoro original, TTS, preferências e SQLite. Histórico básico já recebe sessões finalizadas/interrompidas.
3. GPS: Geolocator atrás de LocationService; filtro de precisão/timestamps/saltos, segmentos separados por lacunas, distância e ritmo; permissões durante uso; foreground service em etapa nativa futura. Implementado sem coleta em background; validação física pendente.
4. Mapas flutter_map: atribuição OpenStreetMap e política do provedor; cache não equivale a permissão para baixar tiles em massa. Treino continua offline sem mapa. Mapa offline completo exige provedor/licença/empacotamento adequados.
5. Estatísticas reais a partir de atividades, unidades e gráficos acessíveis; ensaios de bateria, interrupções e publicação.

## Tempo e recuperação
Stopwatch é a referência monotônica durante o processo; Timer.periodic apenas solicita atualização da UI. O motor calcula a fase a partir do total acumulado, inclusive após atrasos longos, sem acumular ticks. Pausa congela tempo. Checkpoint armazena snapshot do treino e tempo ativo, independentemente de edições posteriores. Após reinício, recupera PAUSADO no último checkpoint, sem somar relógio de parede potencialmente alterado. Até o último checkpoint pode ser perdido em encerramento abrupto. Estado salvo em transições e periodicamente. Escritas serializadas; pontos GPS anexados incrementalmente com cursor e checkpoint na mesma transação, sem regravar o percurso a cada segundo; leitura compatível com snapshots antigos; finalização e remoção de checkpoint em transação para impedir atividade duplicada.

## Dependências
Consultar pubspec.lock para versões efetivamente resolvidas e docs/03-validacao.md para resultado da resolução. SDK instalado inicialmente: Flutter 3.19/Dart 3.3, antigo. SDK estável isolado preparado em /home/ssd/.local/share/corre-alonga/flutter para não alterar outros projetos.

| Pacote | Decisão e avaliação |
| --- | --- |
| flutter_riverpod | Adotar; estado e injeção com manutenção ativa; sem codegen obrigatório. https://pub.dev/packages/flutter_riverpod |
| go_router | Adotar; pacote flutter.dev, rotas declarativas. https://pub.dev/packages/go_router |
| drift + drift_flutter | Adotar; SQLite com conexão e migrações versionadas; esquema SQL explícito de documentos JSON no MVP, sem codegen. https://pub.dev/packages/drift |
| flutter_tts | Adotar atrás de interface; depende da voz/idioma instalado; indisponibilidade não encerra treino. https://pub.dev/packages/flutter_tts |
| just_audio | Adotar para WAV local; interrupções dependem da sessão nativa; validar em aparelho. https://pub.dev/packages/just_audio |
| geolocator | Adotado para GPS em primeiro plano; permissões e ajustes específicos por plataforma; adotado para uso em primeiro plano. https://pub.dev/packages/geolocator |
| flutter_map | Adotado para mapas; Android/iOS suportados; tiles dependem de rede/provedor. https://pub.dev/packages/flutter_map |
| flutter_local_notifications | Adiar até entrega de notificações; pacote mantido, requisitos Android recentes precisam validação de build. Não substitui serviço de execução. https://pub.dev/packages/flutter_local_notifications |

Manutenção declarada nos pacotes não substitui testes de compatibilidade. Fixar resolução, rodar analyze/test/build e revisar atualizações antes de publicação.

## Android
Foreground service precisa de notificação visível, tipo/permissões adequados e início permitido; Android 12+ restringe início em background. GPS requer autorização e serviço de tipo location; Android 14+ impõe verificações adicionais. WorkManager e timers Dart não são relógios de intervalos de baixa latência sob Doze. MVP não declara serviço que não implementa e não promete alertas sob bloqueio.
Fontes: https://developer.android.com/develop/background-work/services/fgs ; https://developer.android.com/develop/background-work/services/fgs/restrictions-bg-start

## iOS
App em background pode ser suspenso; Timer Dart não acorda processo. Background audio exige uso legítimo de áudio e sessão apropriada; não reproduzir silêncio para burlar suspensão. Background location exige finalidade real e configuração adequada, não é solução para treino sem GPS. Notificações locais podem auxiliar, mas não garantem execução de TTS nem precisão contínua. Force quit não permite promessa de retomada automática. Assinatura/build e validação requerem macOS/Xcode e dispositivo.
Fontes: https://developer.apple.com/documentation/xcode/configuring-background-execution-modes ; https://developer.apple.com/documentation/corelocation/handling-location-updates-in-the-background

## Critérios antes de produção
Testar tela bloqueada, chamada, headset, perda de áudio, bateria restrita, morte de processo, alteração de relógio, permissão negada e GPS intermitente em Android e iOS reais. MVP exibe limite de execução em primeiro plano e permite recuperação pausada. Compilação de lojas, assinatura e publicação são etapas futuras.

## Estado após etapa GPS
GPS, mapas, unidades e evolução semanal foram implementados em primeiro plano após a primeira suíte do MVP passar. Não há coleta em background; pausa cancela o stream, retomada inicia outro segmento. A permissão é solicitada somente ao ativar GPS na sessão. O Podfile iOS usa o flag documentado BYPASS_PERMISSION_LOCATION_ALWAYS=1; não se pede autorização Always para esta implementação. Revisar no macOS antes de entrega iOS.

Mapa OSM começa sem base online e preserva o traçado local. Ativar tiles é escolha explícita, com aviso de compartilhamento da região visualizada. Política: https://operations.osmfoundation.org/policies/tiles/ . Cache HTTP padrão do flutter_map 8.3.2, identificação do aplicativo, atribuição visível e nenhum download em massa. Distância e ritmo são estimativas filtradas, não medições certificadas.

### Evidência de compatibilidade nativa
A primeira configuração com Flutter 3.47.7/AGP 9.1 mostrou avisos de DSL/Kotlin legado em plugins, incluindo flutter_tts 4.2.5. O template do SDK mantém android.newDsl=false e android.builtInKotlin=false para compatibilidade atual. Não promover AGP 10 ou futuras versões Flutter sem revisar os plugins e repetir builds Android/iOS. A interface AudioService permite trocar o adaptador se o plugin deixar de suportar a toolchain. Aviso de configuração não comprova áudio funcionando em aparelho.

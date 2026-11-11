# Validação e estado da entrega

Ambiente: Linux, Flutter 3.47.7 stable (abaf9c5237), Dart 3.13.5, SDK isolado em /home/ssd/.local/share/corre-alonga/flutter. O primeiro SDK temporário foi perdido após reinício do host; o código e os logs persistiram. Verificações retomadas em sequência para limitar memória. SDK inicial Flutter 3.19 não alterado. Android SDK local existente; sem aparelho conectado e sem imagens de emulador. iOS não pode ser compilado neste host Linux.

## Etapas implementadas
- Investigação documental, identidade da referência confirmada pelo usuário e matriz de evidências. Diagnóstico REA CLI 6.5.0 registrado em rea-doctor.json. Não há evidência REA sobre o binário: nenhum artefato foi fornecido, MCP não conectado e JADX ausente. Reiniciar/reconectar Codex pode disponibilizar o servidor registrado; análise Android exige artefato e provider adequado.
- MVP: editor validado, fases opcionais, repetições, motor monotônico, pausa/retomada, bip WAV original e TTS, persistência e recuperação pausada, histórico e preferências de áudio/tema.
- Etapa GPS em primeiro plano: Geolocator por interface, solicitação contextual de permissão, mensagens para negação/serviço desligado, filtro de precisão de 35m, timestamps, jitter e saltos acima de 12m/s. Lacunas de 30s e pausas iniciam segmentos separados. Não extrapola distância perdida. Filtros são heurísticos, precisam calibração em campo.
- Histórico com percurso persistido, distância estimada e ritmo médio pelo tempo ativo total; preferência km/milhas; resumo de tempo e treinos e evolução por quatro janelas de sete dias.
- flutter_map com traçado local offline. Base OSM habilitada por usuário, com atribuição e cache padrão do flutter_map. Sem prefetch/download de mapas. Endpoint substituível via MAP_TILE_URL. Privacidade: ativar a base compartilha área e IP com o provedor, conforme aviso na UI.

## Testes
Resultados finais estão registrados abaixo. Testes cobrem limites e saltos temporais, pausa longa, recuperação sem hora de parede, validação do domínio, reabertura de SQLite em disco, finalização idempotente e erros de gravação/áudio; widgets exercitam editor e sessão; domínio GPS cobre precisão, jitter, saltos e lacunas. Teste de integração preparado em integration_test/app_test.dart usa SQLite e adaptadores reais, mas ainda requer aparelho.

Falhas intermediárias foram corrigidas: campos de formulário removidos da árvore ao rolar; cancelamento de voz após pausa; seletor de scroll/teclado e ciclo de vida do provider nos testes. Resultados de testes de widgets não demonstram comportamento nativo de GPS/áudio.

## Limitações materiais
- O aplicativo pausa ao ficar inativo, em background ou sob bloqueio. Não há foreground service Android, scheduler de intervalos, notificações locais nem execução contínua garantida no iOS.
- Sem teste físico de GPS, áudio/TTS, chamada, Bluetooth, bateria, permissões e bloqueio; sem build iOS/assinatura/publicação.
- Voz offline depende do idioma instalado. GPS pode operar sem internet com maior tempo de primeira posição. Mapa de base depende de rede/cache e do provedor; traçado e dados continuam locais.
- Recuperação após morte do processo usa último checkpoint (~1 segundo em execução normal) e sempre pausa. O tempo não observado não é estimado; falha de armazenamento pode ampliar perda. Checkpoints de tempo são pequenos; os pontos GPS são anexados incrementalmente na mesma transação, mantendo leitura de checkpoints antigos.
- Banco é SQLite local sem criptografia adicional; não há backend ou sincronização próprios, e a exportação ainda não está implementada. Backups e restauração pelo sistema operacional não foram validados. Revisar privacidade/backup antes de lançamento público.
- Notificações, gravação contínua em background e políticas de loja precisam entrega nativa e ensaios separados, não estão implicitamente resolvidos pelos plugins.

## Próximos passos
Validar APK em Android físico; compilar e testar no macOS/iPhone; implementar serviços de sessão Android e estratégia permitida no iOS, incluindo foco de áudio e notificações. Prosseguir com REA do aplicativo autorizado quando houver artefato/sessão. Medir consumo de bateria, precisão e escrita antes de produção.

## Resultados após retomada
- Flutter analyze: **sem problemas encontrados**.
- Flutter test --concurrency=1: **21 testes aprovados**, incluindo permissões GPS negadas, pausa da coleta, fases curtas com voz, navegação do histórico, checkpoint incremental e rollback em falha de gravação. Log local: tests-final.log.
- Sintaxe dos scripts bash, XML Android e plists iOS validada. Ícone iOS exportado sem canal alpha.
- Prévias de tela são renderizações de widgets, não capturas de aparelho. Fontes são carregadas explicitamente no renderizador de testes; a sessão é aberta de forma determinística para revisão visual.
- adb devices: nenhum dispositivo conectado. Integração nativa e build iOS continuam não executados.

Na retomada, o SDK Android global apontava para /usr/lib/android-sdk. A seleção local foi corrigida para /home/ssd/Android/Sdk no script de build, sem mudar a configuração global. O NDK 28.2.13676358 foi instalado pelo Gradle usando licença já aceita no SDK local; o agente não aceitou novas licenças. Build-Tools 36 também usa a licença existente. O build usa um único worker e heap Java de 768 MB para limitar pressão de memória. O limite de metaspace foi ajustado de 384 para 512 MB após aviso do primeiro build.

## APK Android anterior — primeira identidade
- Build final ARM64: **BUILD SUCCESSFUL em 1min14s**, 27 tarefas executadas e 269 aproveitadas do cache. Primeiro build nativo: 16min58s.
- Artefato local: dist/corre-alonga-0.1.0-arm64-debug.apk; checksum em dist/SHA256SUMS.
- Pacote br.com.correealonga.corre_alonga, nome Corre & Alonga, versão 0.1.0, versionCode 2001 (código ajustado pelo split ABI do Flutter). Android mínimo API 24, alvo API 36, apenas arm64-v8a.
- Assinatura de depuração v2 verificada com apksigner; metadados/ABI conferidos com aapt. WAV, fonte, licença e código do checkpoint incremental presentes no pacote.
- Artefato compilado não substitui execução em aparelho: adb sem dispositivos; integração e comportamento real de GPS/áudio continuam pendentes.
- Prévias finais claro/escuro e sessão em docs/previews; renderizador aprovado.


## Identidade AlongaPET — 18/10/2026

- Logo do projeto aplicada a partir do SVG fornecido; exportação transparente local, sem serviço remoto. Figura humana da marca utilizada nos ícones Android/iOS. Nome visível atualizado; identificador do pacote e banco mantidos para preservar os dados existentes.
- Nova paleta #EF9B0F, marfim e carvão em todos os fluxos. Temas claro, escuro e sistema; redução de movimento respeitada na transição de tema.
- Análise estática sem problemas. **26 testes aprovados**, incluindo contraste mínimo de 4,5:1 para textos principais/secundários e ações, navegação em 320/375dp, paisagem 844×390, tablet 1024×768, fonte ampliada até 2× e redução de movimento. Preferências corrigidas para evitar overflow horizontal.
- Prévias revisadas em `docs/previews/`: início claro/escuro, sessão clara/escura, editor e preferências no escuro. Renderizações de widgets; não são capturas de aparelho.
- Permanecem pendentes execução em aparelho, integração nativa e validação/build de iOS. O comportamento de pausa ao bloquear a tela continua vigente.

- APK AlongaPET: `dist/alongapet-0.1.0-arm64-debug.apk`. Build Android aprovado em 1min35s (31 tarefas executadas, 265 em cache). Logo incluída no pacote e ABI ARM64 conferida; checksums preservados em `dist/SHA256SUMS`.
- Assinatura v2 aprovada pelo apksigner; nome AlongaPET confirmado nos metadados. Arquivos privados das ferramentas de design não estão empacotados no APK.

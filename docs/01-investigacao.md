# Investigação da referência — 17/10/2026

## Identidade e limites
Referência confirmada pelo usuário: INTVL, INTVL PTY LTD, iOS 6472631698 e Android com.intvl.app. Link oficial confirmado pelo usuário nesta sessão. Nenhum APK/IPA ou sessão autorizada foi fornecido. Não há ferramentas REA conectadas nesta sessão. A skill REA foi lida e o diagnóstico CLI 6.5.0 executado (rea-doctor.json): registro Codex alinhado, sessão sem ferramentas conectadas e JADX ausente; isso não equivale a analisar o aplicativo. Não existem Evidence IDs de análise do alvo. Não houve execução, decompilação ou acesso a dados privados.

Fontes públicas consultadas:
- S1: https://www.intvl.com.au/ (site do desenvolvedor)
- S2: https://apps.apple.com/us/app/intvl/id6472631698 (descrição e notas do desenvolvedor, versão listada 4.1.0)
- S3: https://play.google.com/store/apps/details?id=com.intvl.app

“Confirmado” abaixo significa anunciado pelo desenvolvedor, não validado em execução. Ausência de menção não significa ausência do recurso.

| Questão | Classificação | Evidência e lacuna |
| --- | --- | --- |
| Registro de corrida, caminhada e bicicleta | Confirmado documentalmente | S1, S2 |
| GPS e mapa de trajetos | Confirmado documentalmente | S1 captura de territórios; S2 notas sobre sinal GPS |
| Distância, parciais, elevação e tendências | Confirmado documentalmente | S1 Track your performance |
| Ritmo e unidades em milhas | Confirmado documentalmente | S2 correções de ritmo/unidades; fórmula não observada |
| Planos de treino | Confirmado documentalmente | S2 notas sobre vinculação de atividades ao plano |
| Criação e personalização de intervalos | Não confirmado | Sem artefato ou runtime |
| Aquecimento, recuperação, repetições e desaquecimento | Não confirmado | Sem evidência específica |
| Temporizador, pausa e retomada | Não confirmado | Não inferir de outros aplicativos |
| Alertas sonoros e instruções de voz | Não confirmado | Exige observação e configurações |
| Histórico e evolução | Parcialmente confirmado | S1 tendências; S2 atividades anteriores/recordes; telas não observadas |
| Gravação offline | Confirmado documentalmente, escopo limitado | S2 menciona corridas gravadas offline; não comprova todas as funções offline |
| Localização em segundo plano | Capacidade declarada | S2 aviso de localização; não comprova continuidade sob bloqueio/encerramento |
| Comportamento sob bloqueio, chamadas e economia de bateria | Não confirmado | Necessita dispositivos físicos Android e iOS |
| Preferências | Parcialmente confirmado | Tema escuro e milhas em S2; áudio/notificações desconhecidos |
| Navegação e hierarquia de telas | Não confirmado | Feed, clubes e mapa anunciados; ordem das abas não observada |
| Territórios, clubes, ranking e integrações | Confirmado documentalmente | S1, S2; fora do MVP próprio |

## Melhorias propostas para o aplicativo próprio
Editor explícito de quatro fases; temporizador monotônico; recuperação conservadora como pausado após morte do processo; operação local sem conta; controles grandes; acessibilidade; exportação futura e transparência sobre lacunas GPS. São decisões próprias, não características atribuídas ao INTVL.

## Roteiro REA quando houver acesso
1. Confirmar identidade e obter caminho de artefato autorizado, versão e SHA-256.
2. Usar inspect_android_package para APK ou inventário de IPA, sem contornar proteções.
3. Inspecionar manifestos/recursos e pontos relevantes de fluxo, mantendo evidências e limites.
4. Com acesso runtime autorizado, registrar criação de treino, execução, pausa, bloqueio, chamada, sinal perdido e recuperação.
5. Registrar cada resultado com Evidence ID, plataforma/versão e tipo de evidência. Atualizar esta matriz sem transformar inferências em observações.
# Referência corrigida: INTVL do Google Play

O link fornecido pelo usuário identifica `com.intvl.app`, da INTVL PTY LTD. A descrição pública do Google Play confirma uma experiência de jogo geográfico: caminhadas, corridas ou pedaladas em circuitos fechados conquistam território no mapa; áreas podem ser defendidas e há foco em líderes globais e locais. Isso é diferente de um simples temporizador de intervalos.

| Recurso observado na descrição pública | Estado para a referência | Decisão no AlongaPET |
|---|---|---|
| Registrar caminhada, corrida e bicicleta | confirmado | Corrida/GPS no MVP; bicicleta fica proposta |
| Circuito fechado conquista território | confirmado | Identificação local de loop e cálculo de área |
| Defender território e mapa em mudança | confirmado | Proposta para backend/sincronização |
| Líder global, cidade/subúrbio | confirmado | Proposta; não inventar ranking offline |
| Mapas e posição | confirmado | Traçado local + base OSM opcional |
| Intervalos de treino | não confirmado para este alvo | Mantido como recurso complementar do AlongaPET |

Fonte: [página pública do INTVL no Google Play](https://play.google.com/store/apps/details?hl=en_US&id=com.intvl.app). A página pode variar por região e não substitui a observação de um APK autorizado. Não houve APK autorizado do INTVL nem sessão REA conectada nesta etapa; portanto, detalhes de telas, algoritmo de conquista, autenticação, sincronização e regras anti-fraude permanecem desconhecidos.


import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../domain/workout.dart';
import '../domain/session.dart';
import '../domain/location.dart';
import 'providers.dart';
import 'common_ui.dart';
import 'route_map.dart';
import 'app_theme.dart';

class SessionScreen extends ConsumerWidget {
  const SessionScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(trainingProvider);
    final session = c.session;
    if (session == null) {
      return PageFrame(
        title: 'Seu treino',
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_outline, size: 72),
                const SizedBox(height: 20),
                const Text(
                  'Atividade salva. Cada passo conta.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => context.go('/history'),
                  child: const Text('Ver atividades'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final phase = session.phase;
    final paused = session.status == SessionStatus.paused;
    final next = session.phaseIndex + 1 < session.workout.phases.length
        ? session.workout.phases[session.phaseIndex + 1]
        : null;
    return PageFrame(
      title: session.workout.name,
      bottomActions: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton.icon(
                onPressed: c.busy || session.terminal
                    ? null
                    : paused
                    ? c.resume
                    : c.pause,
                icon: Icon(
                  paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                ),
                label: Text(paused ? 'Retomar' : 'Pausar'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: c.busy
                    ? null
                    : () async {
                        await c.pause();
                        if (!context.mounted) return;
                        final end = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Encerrar o treino?'),
                            content: const Text(
                              'O tempo realizado será salvo como atividade interrompida.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Continuar em pausa'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Encerrar'),
                              ),
                            ],
                          ),
                        );
                        if (end == true) await c.finish();
                      },
                child: const Text('Encerrar treino'),
              ),
            ],
          ),
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (c.recovered)
            const Padding(
              padding: EdgeInsets.only(bottom: 20),
              child: Text(
                'Treino recuperado e pausado no último ponto salvo. Confirme quando estiver pronto para continuar.',
              ),
            ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
            decoration: BoxDecoration(
              color: brandCharcoal,
              borderRadius: BorderRadius.circular(32),
            ),
            child: DefaultTextStyle.merge(
              style: const TextStyle(color: Color(0xFFE2DCCD)),
              child: Column(
                children: [
                  Center(
                    child: Icon(
                      phaseIcon(phase.kind),
                      size: 48,
                      color: brandOrange,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      paused ? 'Em pausa' : phase.kind.label,
                      style: Theme.of(
                        context,
                      ).textTheme.headlineMedium?.copyWith(color: Colors.white),
                    ),
                  ),
                  if (phase.repetition != null)
                    Center(
                      child: Text(
                        'Repetição ${phase.repetition} de ${session.workout.repeats}',
                      ),
                    ),
                  const SizedBox(height: 24),
                  Semantics(
                    label: 'Tempo restante na fase ${phase.kind.label}',
                    value: clockText(session.remaining),
                    child: ExcludeSemantics(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          clockText(session.remaining),
                          style: const TextStyle(
                            color: brandOrange,
                            fontSize: 100,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -4,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  LinearProgressIndicator(
                    value:
                        session.elapsed.inMilliseconds /
                        session.workout.total.inMilliseconds,
                    minHeight: 10,
                    borderRadius: BorderRadius.circular(10),
                    semanticsLabel: 'Progresso do treino',
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${clockText(session.elapsed)} de ${clockText(session.workout.total)}',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text(
                    'A SEGUIR',
                    style: TextStyle(letterSpacing: 2, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    next == null
                        ? 'Treino concluído'
                        : '${next.kind.label} · ${clockText(next.duration)}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Seu percurso',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 24,
                    runSpacing: 12,
                    children: [
                      Metric(
                        distanceLabel(c.route.meters, c.preferences.unit),
                        'distância estimada',
                      ),
                      Metric(
                        paceLabel(
                          c.route.meters,
                          session.elapsed,
                          c.preferences.unit,
                        ),
                        'ritmo médio · tempo ativo',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(c.gpsStatus),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: c.gpsBusy
                        ? null
                        : c.gpsEnabled
                        ? c.disableGps
                        : c.enableGps,
                    icon: const Icon(Icons.gps_fixed),
                    label: Text(
                      c.gpsEnabled ? 'Desativar GPS' : 'Ativar GPS durante uso',
                    ),
                  ),
                  const SizedBox(height: 12),
                  RouteMap(points: c.route.points),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Mantenha o aplicativo visível. Bloqueio da tela e troca de aplicativo pausam este MVP.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

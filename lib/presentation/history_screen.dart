import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../domain/workout.dart';
import '../domain/location.dart';
import 'providers.dart';
import 'common_ui.dart';
import 'route_map.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(trainingProvider);
    final complete = c.activities.where((a) => a.completed).length;
    final total = c.activities.fold<int>(0, (sum, a) => sum + a.elapsedMs);
    return PageFrame(
      title: 'Suas atividades',
      selected: 2,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Consistência se constrói.',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Wrap(
                spacing: 32,
                runSpacing: 24,
                children: [
                  Metric('$complete', 'treinos concluídos'),
                  Metric(
                    clockText(Duration(milliseconds: total)),
                    'tempo em atividade',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Últimas 4 semanas',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          for (var week = 3; week >= 0; week--) ...[
            Builder(
              builder: (context) {
                final today = DateTime.now();
                final end = DateTime(
                  today.year,
                  today.month,
                  today.day,
                ).add(Duration(days: 1 - week * 7));
                final start = end.subtract(const Duration(days: 7));
                final activities = c.activities
                    .where(
                      (a) =>
                          !a.startedAt.toLocal().isBefore(start) &&
                          a.startedAt.toLocal().isBefore(end),
                    )
                    .toList();
                final seconds =
                    activities.fold<int>(0, (sum, a) => sum + a.elapsedMs) ~/
                    1000;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${start.day}/${start.month} · ${activities.length} atividades · ${seconds ~/ 60} min',
                      ),
                      const SizedBox(height: 6),
                      LinearProgressIndicator(
                        value: (seconds / 10800).clamp(0, 1),
                        minHeight: 8,
                        semanticsLabel:
                            'Tempo da semana em relação a 180 minutos',
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
          const Text(
            'Escala visual: 180 minutos por semana; não é uma recomendação de treino.',
          ),
          const SizedBox(height: 24),
          if (c.activities.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Text(
                'Seu histórico começa no primeiro passo. As atividades encerradas aparecerão aqui.',
              ),
            ),
          for (final activity in c.activities)
            Card(
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Icon(
                  activity.completed
                      ? Icons.check_circle_outline
                      : Icons.pause_circle_outline,
                ),
                onTap: () => context.push('/activity/${activity.id}'),
                title: Text(activity.name),
                subtitle: Text(
                  '${_date(activity.startedAt.toLocal())} · ${activity.completed ? 'Concluído' : 'Interrompido'}',
                ),
                trailing: Text(
                  clockText(Duration(milliseconds: activity.elapsedMs)),
                ),
              ),
            ),
          const SizedBox(height: 24),
          const Text(
            'Os valores refletem atividades salvas neste aparelho. Distância e ritmo dependem de GPS confiável; trechos sem sinal não são estimados.',
          ),
        ],
      ),
    );
  }

  String _date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class ActivityScreen extends ConsumerWidget {
  final String id;
  const ActivityScreen({super.key, required this.id});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(trainingProvider);
    final matches = c.activities.where((a) => a.id == id);
    if (matches.isEmpty) {
      return const PageFrame(
        title: 'Atividade',
        child: Center(child: Text('Atividade não encontrada.')),
      );
    }
    final a = matches.first;
    return PageFrame(
      title: a.name,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            a.completed ? 'Mais um treino na conta.' : 'Cada passo conta.',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 24,
            runSpacing: 24,
            children: [
              Metric(
                clockText(Duration(milliseconds: a.elapsedMs)),
                'tempo ativo',
              ),
              Metric(
                distanceLabel(a.meters, c.preferences.unit),
                'distância estimada',
              ),
              Metric(
                paceLabel(
                  a.meters,
                  Duration(milliseconds: a.elapsedMs),
                  c.preferences.unit,
                ),
                'ritmo médio',
              ),
            ],
          ),
          const SizedBox(height: 24),
          RouteMap(points: a.points),
          const SizedBox(height: 16),
          const Text(
            'Pausas e lacunas de GPS iniciam trechos separados. Não somamos distância entre esses trechos. O ritmo considera todo o tempo ativo do treino.',
          ),
        ],
      ),
    );
  }
}

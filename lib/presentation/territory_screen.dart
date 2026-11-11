import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/location.dart';
import 'common_ui.dart';
import 'providers.dart';
import 'route_map.dart';

class TerritoryScreen extends ConsumerWidget {
  const TerritoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(trainingProvider);
    final loops = controller.activities
        .where((a) => isClosedLoop(a.points))
        .toList();
    final area = loops.fold<double>(
      0,
      (sum, activity) => sum + enclosedAreaSquareMeters(activity.points),
    );
    return PageFrame(
      title: 'Território',
      selected: 1,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 32),
        children: [
          Text(
            'Seu mapa começa aqui.',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 12),
          Text(
            'Complete um circuito e transforme o caminho percorrido em território local.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: Metric('${loops.length}', 'circuitos fechados'),
                  ),
                  Expanded(child: Metric(_areaLabel(area), 'área mapeada')),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (loops.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.explore_outlined,
                      size: 42,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Ainda não há território conquistado',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Ative o GPS durante uma corrida, volte ao ponto de partida e encerre a atividade. O circuito aparecerá aqui quando estiver fechado.',
                    ),
                  ],
                ),
              ),
            )
          else
            for (final activity in loops) ...[
              Text(
                activity.name,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              RouteMap(points: activity.points),
              const SizedBox(height: 24),
            ],
          const SizedBox(height: 8),
          Text(
            'O território deste MVP é calculado e salvo neste aparelho. Disputa entre pessoas, ranking e sincronização exigem um serviço online e serão adicionados em uma etapa posterior.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  String _areaLabel(double squareMeters) {
    if (squareMeters < 10000) return '${squareMeters.round()} m²';
    return '${(squareMeters / 10000).toStringAsFixed(2)} ha';
  }
}

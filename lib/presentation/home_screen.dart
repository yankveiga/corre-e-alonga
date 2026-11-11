import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../domain/workout.dart';
import 'providers.dart';
import 'common_ui.dart';
import 'app_theme.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(trainingProvider);
    final text = Theme.of(context).textTheme;
    if (!c.loaded) {
      return PageFrame(
        title: 'AlongaPET',
        child: Center(
          child: c.error == null
              ? const CircularProgressIndicator()
              : FilledButton(
                  onPressed: c.initialize,
                  child: const Text('Tentar novamente'),
                ),
        ),
      );
    }
    return PageFrame(
      title: 'AlongaPET',
      selected: 0,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 32),
        children: [
          Text('Seu corpo. Seu ritmo.', style: text.headlineLarge),
          const SizedBox(height: 12),
          Text(
            'Um tempo para se mover e cuidar de você.',
            style: text.bodyLarge,
          ),
          const SizedBox(height: 24),
          if (c.session != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.pause_circle_outline, size: 36),
                    const SizedBox(height: 12),
                    Text(
                      c.recovered
                          ? 'Vamos retomar com calma?'
                          : 'Você tem um treino aberto',
                      style: text.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      c.recovered
                          ? 'Recuperamos o último ponto salvo. O treino está pausado.'
                          : c.session!.workout.name,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => context.push('/session'),
                      child: const Text('Abrir treino'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: brandOrange,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.directions_run_rounded,
                      color: brandCharcoal,
                      size: 28,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'CORRIDA + RECUPERAÇÃO',
                        style: TextStyle(
                          color: brandCharcoal,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Cada passo\nconta.',
                  style: TextStyle(
                    color: brandCharcoal,
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    height: 1.05,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Monte seus intervalos. Encontre seu equilíbrio.',
                  style: TextStyle(
                    color: brandCharcoal,
                    fontSize: 16,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: brandCharcoal,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => context.push('/workout/new'),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Criar treino'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Text('Prontos para começar', style: text.titleLarge),
          const SizedBox(height: 12),
          if (c.workouts.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'Sua pista está livre. Crie o primeiro treino para começar.',
              ),
            ),
          for (final workout in c.workouts)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(workout.name, style: text.titleLarge),
                          ),
                          IconButton(
                            tooltip: 'Editar ${workout.name}',
                            onPressed: () =>
                                context.push('/workout/${workout.id}'),
                            icon: const Icon(Icons.edit_outlined),
                          ),
                        ],
                      ),
                      Text(
                        '${clockText(workout.total)} no total · ${workout.repeats} repetições',
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Row(
                          children: [
                            for (final segment in workout.phases)
                              Expanded(
                                flex: segment.duration.inSeconds,
                                child: Container(
                                  height: 6,
                                  color: phaseColor(segment.kind),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      PhaseChips(workout: workout),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: c.session != null || c.busy
                            ? null
                            : () async {
                                if (await c.start(workout) && context.mounted) {
                                  context.push('/session');
                                }
                              },
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('Iniciar treino'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 12),
          const Text(
            'Feito para funcionar offline. Nesta versão, mantenha o app visível: ao sair ou bloquear a tela, o treino é pausado.',
          ),
        ],
      ),
    );
  }
}

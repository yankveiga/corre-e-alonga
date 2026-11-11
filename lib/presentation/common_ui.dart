import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../domain/workout.dart';
import 'providers.dart';

class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key});
  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/branding/alongapet-logo.png',
    width: 158,
    height: 36,
    fit: BoxFit.contain,
    color: Theme.of(context).colorScheme.onSurface,
    semanticLabel: 'AlongaPET',
  );
}

class PageFrame extends ConsumerWidget {
  final String title;
  final Widget child;
  final int? selected;
  final Widget? bottomActions;
  const PageFrame({
    super.key,
    required this.title,
    required this.child,
    this.selected,
    this.bottomActions,
  });
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(trainingProvider);
    return Scaffold(
      appBar: AppBar(
        title: selected == 0 ? const BrandLogo() : Text(title),
        actions: [
          if (selected != null)
            IconButton(
              tooltip: 'Preferências',
              onPressed: () => context.push('/settings'),
              icon: const Icon(Icons.tune_rounded),
            ),
        ],
      ),
      bottomNavigationBar: selected == null
          ? bottomActions
          : NavigationBar(
              selectedIndex: selected!,
              onDestinationSelected: (i) => context.go(switch (i) {
                0 => '/',
                1 => '/territory',
                _ => '/history',
              }),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.route_rounded),
                  label: 'Treinos',
                ),
                NavigationDestination(
                  icon: Icon(Icons.insights_rounded),
                  label: 'Território',
                ),
                NavigationDestination(
                  icon: Icon(Icons.history_rounded),
                  label: 'Histórico',
                ),
              ],
            ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              children: [
                if (controller.error != null)
                  MaterialBanner(
                    content: Text(controller.error!),
                    actions: [
                      TextButton(
                        onPressed: controller.clearError,
                        child: const Text('Fechar'),
                      ),
                    ],
                  ),
                Expanded(child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Color phaseColor(PhaseKind phase) => switch (phase) {
  PhaseKind.warmup => const Color(0xFFAA6615),
  PhaseKind.run => const Color(0xFFB77000),
  PhaseKind.recovery => const Color(0xFF5264AB),
  PhaseKind.cooldown => const Color(0xFF9D5284),
};
IconData phaseIcon(PhaseKind phase) => switch (phase) {
  PhaseKind.warmup => Icons.wb_sunny_outlined,
  PhaseKind.run => Icons.directions_run,
  PhaseKind.recovery => Icons.air_rounded,
  PhaseKind.cooldown => Icons.self_improvement,
};

class PhaseChips extends StatelessWidget {
  final Workout workout;
  const PhaseChips({super.key, required this.workout});
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final entry in [
        (PhaseKind.warmup, workout.warmupSeconds),
        (PhaseKind.run, workout.runSeconds),
        (PhaseKind.recovery, workout.recoverySeconds),
        (PhaseKind.cooldown, workout.cooldownSeconds),
      ])
        if (entry.$2 > 0)
          Chip(
            avatar: Icon(phaseIcon(entry.$1), size: 18),
            label: Text(
              '${entry.$1.label} ${clockText(Duration(seconds: entry.$2))}',
            ),
          ),
    ],
  );
}

class Metric extends StatelessWidget {
  final String value, label;
  const Metric(this.value, this.label, {super.key});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(value, style: Theme.of(context).textTheme.headlineMedium),
      Text(label),
    ],
  );
}

import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:corre_alonga/data/local_repository.dart';
import 'package:corre_alonga/domain/repository.dart';
import 'package:corre_alonga/domain/session.dart';
import 'package:corre_alonga/presentation/app.dart';
import 'package:corre_alonga/presentation/providers.dart';
import 'package:corre_alonga/services/device_audio.dart';
import 'package:corre_alonga/services/training_controller.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('treino real, background, reabertura SQLite e histórico', (
    tester,
  ) async {
    final dbName = 'integration_${DateTime.now().microsecondsSinceEpoch}';
    var repo = LocalRepository(AppDatabase(driftDatabase(name: dbName)));
    await repo.savePreferences(
      const Preferences(voice: false, sound: false, haptics: false),
    );
    var controller = TrainingController(repo, DeviceAudio());
    await controller.initialize();
    Future<void> waitFor(Finder finder) async {
      for (var i = 0; i < 100; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        if (finder.evaluate().isNotEmpty) return;
      }
      throw TestFailure('A tela esperada não apareceu em 10 segundos: $finder');
    }

    Future<void> mount() async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [trainingProvider.overrideWith((ref) => controller)],
          child: const CorreAlongaApp(),
        ),
      );
      await tester.pumpAndSettle();
    }

    await mount();
    await tester.ensureVisible(find.text('Criar treino'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Criar treino'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('workout-name')),
      'Integração local',
    );
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Salvar treino'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salvar treino'));
    await waitFor(find.text('corre & alonga'));
    await tester.scrollUntilVisible(
      find.text('Iniciar treino'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Iniciar treino'));
    // O relógio agenda frames continuamente; não esperar settle enquanto corre.
    await waitFor(find.text('Pausar'));
    await tester.pump(const Duration(seconds: 2));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await controller.persist();
    expect(controller.session!.status, SessionStatus.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
    await repo.close();
    repo = LocalRepository(AppDatabase(driftDatabase(name: dbName)));
    controller = TrainingController(repo, DeviceAudio());
    await controller.initialize();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    expect(controller.recovered, true);
    expect(controller.workouts.single.name, 'Integração local');
    await mount();
    await tester.tap(find.text('Abrir treino'));
    await tester.pumpAndSettle();
    expect(find.text('Em pausa'), findsOneWidget);
    await tester.ensureVisible(find.text('Encerrar treino'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Encerrar treino'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Encerrar'));
    await waitFor(find.text('Ver atividades'));
    await tester.tap(find.text('Ver atividades'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Interrompido'), findsOneWidget);
    expect(await repo.checkpoint(), null);
    await tester.pumpWidget(const SizedBox());
    await repo.close();
  });
}

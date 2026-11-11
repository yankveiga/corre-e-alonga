import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:corre_alonga/data/local_repository.dart';
import 'package:corre_alonga/domain/session.dart';
import 'package:corre_alonga/domain/location.dart';
import 'package:corre_alonga/presentation/app.dart';
import 'package:corre_alonga/presentation/providers.dart';
import 'package:corre_alonga/services/training_controller.dart';
import 'controller_test.dart' show SilentAudio;

void main() {
  testWidgets('editor valida, salva e inicia treino; pausa e retoma', (
    tester,
  ) async {
    final repo = LocalRepository(AppDatabase(NativeDatabase.memory()));
    final controller = TrainingController(
      repo,
      SilentAudio(),
      automaticTicks: false,
    );
    addTearDown(repo.close);
    await controller.initialize();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [trainingProvider.overrideWith((ref) => controller)],
        child: const CorreAlongaApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Criar treino'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Criar treino'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Salvar treino'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salvar treino'));
    await tester.pumpAndSettle();
    expect(find.text('Dê um nome ao treino.'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('workout-name')),
      -500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('workout-name')),
      'Parque de manhã',
    );
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Salvar treino'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salvar treino'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Iniciar treino'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Iniciar treino'));
    await tester.pumpAndSettle();
    expect(find.text('Pausar').hitTestable(), findsOneWidget);
    await tester.ensureVisible(find.text('Pausar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pausar'));
    await tester.pumpAndSettle();
    expect(controller.session!.status.name, 'paused');
    expect(find.text('Retomar'), findsOneWidget);
    await tester.tap(find.text('Retomar'));
    await tester.pumpAndSettle();
    expect(find.text('Pausar').hitTestable(), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('início suporta tela estreita e texto ampliado', (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final repo = LocalRepository(AppDatabase(NativeDatabase.memory()));
    final c = TrainingController(repo, SilentAudio(), automaticTicks: false);
    addTearDown(repo.close);
    await c.initialize();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [trainingProvider.overrideWith((ref) => c)],
        child: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: const CorreAlongaApp(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), null);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('histórico abre atividade e traçado local sem ativar rede', (
    tester,
  ) async {
    final repo = LocalRepository(AppDatabase(NativeDatabase.memory()));
    addTearDown(repo.close);
    final now = DateTime.now();
    await repo.finish(
      Activity(
        id: 'route',
        name: 'Volta no parque',
        elapsedMs: 300000,
        startedAt: now,
        completed: true,
        meters: 1000,
        points: [
          TrackPoint(-23.55, -46.63, 5, now, segmentStart: true),
          TrackPoint(-23.551, -46.63, 5, now.add(const Duration(seconds: 30))),
        ],
      ),
    );
    final c = TrainingController(repo, SilentAudio(), automaticTicks: false);
    await c.initialize();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [trainingProvider.overrideWith((ref) => c)],
        child: const CorreAlongaApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Histórico'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Volta no parque'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Volta no parque'));
    await tester.pumpAndSettle();
    expect(find.text('1.00 km'), findsOneWidget);
    expect(find.text('5:00 /km'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Mapa de base online'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    final toggle = tester.widget<SwitchListTile>(
      find.widgetWithText(SwitchListTile, 'Mapa de base online'),
    );
    expect(toggle.value, false);
    await tester.pumpWidget(const SizedBox());
  });
}

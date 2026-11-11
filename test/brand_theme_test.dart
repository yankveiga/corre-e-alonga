import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:corre_alonga/data/local_repository.dart';
import 'package:corre_alonga/domain/repository.dart';
import 'package:corre_alonga/domain/workout.dart';
import 'package:corre_alonga/presentation/app.dart';
import 'package:corre_alonga/presentation/app_theme.dart';
import 'package:corre_alonga/presentation/common_ui.dart';
import 'package:corre_alonga/presentation/providers.dart';
import 'package:corre_alonga/services/training_controller.dart';
import 'package:go_router/go_router.dart';
import 'controller_test.dart' show SilentAudio;

double contrast(Color a, Color b) {
  final l = [a.computeLuminance(), b.computeLuminance()]..sort();
  return (l.last + .05) / (l.first + .05);
}

void main() {
  test('paleta mantém contraste de texto nos dois temas e nas ações', () {
    for (final brightness in Brightness.values) {
      final colors = appTheme(brightness).colorScheme;
      for (final background in [colors.surface, colors.surfaceContainerLow]) {
        expect(
          contrast(colors.onSurface, background),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          contrast(colors.onSurfaceVariant, background),
          greaterThanOrEqualTo(4.5),
        );
        expect(contrast(colors.primary, background), greaterThanOrEqualTo(4.5));
      }
      expect(contrast(brandCharcoal, brandOrange), greaterThanOrEqualTo(4.5));
    }
  });

  for (final spec in [
    (Size(375, 812), 'light', 1.0),
    (Size(320, 700), 'dark', 2.0),
    (Size(844, 390), 'dark', 1.0),
    (Size(1024, 768), 'light', 1.3),
  ]) {
    testWidgets('marca, temas e navegação adaptam-se a $spec', (tester) async {
      tester.view.physicalSize = spec.$1;
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = spec.$3;
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      final repo = LocalRepository(AppDatabase(NativeDatabase.memory()));
      addTearDown(repo.close);
      final controller = TrainingController(
        repo,
        SilentAudio(),
        automaticTicks: false,
      );
      await controller.initialize();
      await controller.setPreferences(Preferences(theme: spec.$2));
      await controller.saveWorkout(
        Workout(id: 'brand', name: 'Volta no parque'),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [trainingProvider.overrideWith((ref) => controller)],
          child: const CorreAlongaApp(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(BrandLogo), findsOneWidget);
      expect(
        Theme.of(tester.element(find.byType(BrandLogo))).brightness,
        spec.$2 == 'dark' ? Brightness.dark : Brightness.light,
      );
      expect(tester.takeException(), isNull);
      final router = GoRouter.of(tester.element(find.byType(BrandLogo)));
      for (final path in ['/workout/new', '/settings', '/history']) {
        router.go(path);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: path);
      }
      await tester.runAsync(() => controller.start(controller.workouts.first));
      router.go('/session');
      await tester.pumpAndSettle();
      expect(find.text('Pausar').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}

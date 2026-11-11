import 'dart:io';
import 'dart:ui' as ui;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:corre_alonga/presentation/home_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:corre_alonga/data/local_repository.dart';
import 'package:corre_alonga/domain/repository.dart';
import 'package:corre_alonga/domain/workout.dart';
import 'package:corre_alonga/presentation/app.dart';
import 'package:corre_alonga/presentation/providers.dart';
import 'package:corre_alonga/services/training_controller.dart';
import '../test/controller_test.dart' show SilentAudio;

void main() {
  testWidgets('renderiza prévias para revisão visual', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await (FontLoader('RunSans')
          ..addFont(rootBundle.load('assets/fonts/Roboto-Regular.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Roboto-Bold.ttf')))
        .load();
    await (FontLoader(
      'Ahem',
    )..addFont(rootBundle.load('assets/fonts/Roboto-Regular.ttf'))).load();
    await (FontLoader('Roboto')
          ..addFont(rootBundle.load('assets/fonts/Roboto-Regular.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Roboto-Bold.ttf')))
        .load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    final repo = LocalRepository(AppDatabase(NativeDatabase.memory()));
    final controller = TrainingController(
      repo,
      SilentAudio(),
      automaticTicks: false,
    );
    addTearDown(repo.close);
    await controller.initialize();
    await controller.saveWorkout(
      Workout(id: 'preview', name: 'Primeiros quilômetros'),
    );
    final boundary = GlobalKey();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [trainingProvider.overrideWith((ref) => controller)],
        child: RepaintBoundary(key: boundary, child: const CorreAlongaApp()),
      ),
    );
    await tester.pumpAndSettle();
    Future<void> capture(String name) async {
      await tester.runAsync(() async {
        final render =
            boundary.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final image = await render.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(
          'docs/previews/$name.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }

    await tester.runAsync(
      () => precacheImage(
        const AssetImage('assets/branding/alongapet-logo.png'),
        boundary.currentContext!,
      ),
    );
    await tester.pumpAndSettle();
    await capture('inicio-claro');
    await tester.runAsync(
      () => controller.setPreferences(const Preferences(theme: 'dark')),
    );
    await tester.pumpAndSettle();
    await capture('inicio-escuro');
    await tester.runAsync(
      () => controller.setPreferences(const Preferences(theme: 'light')),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(() => controller.start(controller.workouts.first));
    GoRouter.of(tester.element(find.byType(HomeScreen))).go('/session');
    await tester.pumpAndSettle();
    expect(find.text('Pausar'), findsOneWidget);
    await capture('sessao');
    await tester.runAsync(
      () => controller.setPreferences(const Preferences(theme: 'dark')),
    );
    await tester.pumpAndSettle();
    await capture('sessao-escuro');
    GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/settings');
    await tester.pumpAndSettle();
    await capture('preferencias-escuro');
    GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/workout/new');
    await tester.pumpAndSettle();
    await capture('editor-escuro');
    await tester.pumpWidget(const SizedBox());
  });
}

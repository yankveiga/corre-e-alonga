import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'data/local_repository.dart';
import 'services/device_audio.dart';
import 'services/device_location.dart';
import 'services/training_controller.dart';
import 'presentation/app.dart';
import 'presentation/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString('assets/fonts/LICENSE.txt');
    yield LicenseEntryWithLineBreaks(['Roboto'], license);
  });
  final repository = LocalRepository(
    AppDatabase(driftDatabase(name: 'corre_alonga')),
  );
  final controller = TrainingController(
    repository,
    DeviceAudio(),
    location: DeviceLocation(),
  );
  runApp(
    ProviderScope(
      overrides: [trainingProvider.overrideWith((ref) => controller)],
      child: const CorreAlongaApp(),
    ),
  );
  await controller.initialize();
}

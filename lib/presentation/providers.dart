import 'package:flutter_riverpod/legacy.dart';
import '../services/training_controller.dart';

final trainingProvider = ChangeNotifierProvider<TrainingController>(
  (ref) =>
      throw UnimplementedError('Injete TrainingController no ProviderScope'),
);

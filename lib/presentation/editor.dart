import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../domain/workout.dart';
import 'providers.dart';
import 'common_ui.dart';

class WorkoutEditor extends ConsumerStatefulWidget {
  final String? id;
  const WorkoutEditor({super.key, this.id});
  @override
  ConsumerState<WorkoutEditor> createState() => _EditorState();
}

class _EditorState extends ConsumerState<WorkoutEditor> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController();
  final warmup = TextEditingController(text: '300');
  final run = TextEditingController(text: '60');
  final recovery = TextEditingController(text: '90');
  final cooldown = TextEditingController(text: '300');
  final repeats = TextEditingController(text: '8');
  bool saving = false;
  Workout? original;
  @override
  void initState() {
    super.initState();
    final found = ref
        .read(trainingProvider)
        .workouts
        .where((w) => w.id == widget.id);
    if (found.isNotEmpty) {
      original = found.first;
      name.text = original!.name;
      warmup.text = '${original!.warmupSeconds}';
      run.text = '${original!.runSeconds}';
      recovery.text = '${original!.recoverySeconds}';
      cooldown.text = '${original!.cooldownSeconds}';
      repeats.text = '${original!.repeats}';
    }
    for (final field in [warmup, run, recovery, cooldown, repeats]) {
      field.addListener(refresh);
    }
  }

  void refresh() {
    setState(() {});
  }

  @override
  void dispose() {
    for (final field in [name, warmup, run, recovery, cooldown, repeats]) {
      field.dispose();
    }
    super.dispose();
  }

  int number(TextEditingController field) => int.tryParse(field.text) ?? 0;
  Widget durationField(
    String label,
    TextEditingController controller, {
    bool required = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label, suffixText: 'segundos'),
      validator: (value) {
        final n = int.tryParse(value ?? '');
        return n == null || n < (required ? 1 : 0) || n > 3600
            ? 'Informe ${required ? 1 : 0} a 3600 segundos.'
            : null;
      },
    ),
  );
  @override
  Widget build(BuildContext context) {
    if (widget.id != null && original == null) {
      return const PageFrame(
        title: 'Treino',
        child: Center(child: Text('Treino não encontrado.')),
      );
    }
    final total =
        number(warmup) +
        number(cooldown) +
        number(run) * number(repeats) +
        number(recovery) * (number(repeats) - 1).clamp(0, 99);
    return PageFrame(
      title: original == null ? 'Novo treino' : 'Editar treino',
      child: Form(
        key: form,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Desenhe seu próximo passo.',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              const Text(
                'Configure cada fase em segundos. A recuperação acontece entre as corridas; depois da última, começa o desaquecimento.',
              ),
              const SizedBox(height: 24),
              TextFormField(
                key: const ValueKey('workout-name'),
                controller: name,
                maxLength: 80,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Nome do treino',
                  hintText: 'Ex.: Meu primeiro 5 km',
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Dê um nome ao treino.'
                    : null,
              ),
              const SizedBox(height: 16),
              durationField('Aquecimento', warmup),
              durationField('Corrida', run, required: true),
              durationField('Recuperação', recovery),
              TextFormField(
                controller: repeats,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Repetições de corrida',
                ),
                validator: (value) {
                  final n = int.tryParse(value ?? '');
                  return n == null || n < 1 || n > 100
                      ? 'Informe de 1 a 100 repetições.'
                      : null;
                },
              ),
              const SizedBox(height: 16),
              durationField('Desaquecimento', cooldown),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'DURAÇÃO TOTAL',
                        style: TextStyle(letterSpacing: 2, fontSize: 12),
                      ),
                      Text(
                        clockText(Duration(seconds: total.clamp(0, 999999))),
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const Text(
                        'Use 0 para omitir aquecimento, recuperação ou desaquecimento.',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: saving
                    ? null
                    : () async {
                        if (!form.currentState!.validate()) return;
                        setState(() {
                          saving = true;
                        });
                        final workout = Workout(
                          id:
                              widget.id ??
                              DateTime.now().microsecondsSinceEpoch.toString(),
                          name: name.text.trim(),
                          warmupSeconds: number(warmup),
                          runSeconds: number(run),
                          recoverySeconds: number(recovery),
                          cooldownSeconds: number(cooldown),
                          repeats: number(repeats),
                        );
                        final saved = await ref
                            .read(trainingProvider)
                            .saveWorkout(workout);
                        if (!mounted) return;
                        setState(() {
                          saving = false;
                        });
                        if (saved && context.mounted) context.pop();
                      },
                child: Text(saving ? 'Salvando…' : 'Salvar treino'),
              ),
              if (original != null) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () async {
                    final remove = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Excluir este treino?'),
                        content: const Text(
                          'As atividades já salvas serão mantidas.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancelar'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Excluir'),
                          ),
                        ],
                      ),
                    );
                    if (remove == true) {
                      final removed = await ref
                          .read(trainingProvider)
                          .deleteWorkout(widget.id!);
                      if (removed && context.mounted) context.pop();
                    }
                  },
                  child: const Text('Excluir treino'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

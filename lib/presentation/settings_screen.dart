import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/repository.dart';
import 'providers.dart';
import 'common_ui.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(trainingProvider);
    final p = c.preferences;
    void change({
      bool? voice,
      bool? sound,
      bool? haptics,
      String? theme,
      String? unit,
    }) => c.setPreferences(
      Preferences(
        voice: voice ?? p.voice,
        sound: sound ?? p.sound,
        haptics: haptics ?? p.haptics,
        theme: theme ?? p.theme,
        unit: unit ?? p.unit,
      ),
    );
    return PageFrame(
      title: 'Preferências',
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Do seu jeito.',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 24),
          SwitchListTile(
            title: const Text('Instruções por voz'),
            subtitle: const Text(
              'Usa a voz em português instalada no aparelho.',
            ),
            value: p.voice,
            onChanged: (v) => change(voice: v),
          ),
          SwitchListTile(
            title: const Text('Alertas sonoros'),
            subtitle: const Text('Um sinal curto a cada mudança de fase.'),
            value: p.sound,
            onChanged: (v) => change(sound: v),
          ),
          SwitchListTile(
            title: const Text('Feedback tátil'),
            value: p.haptics,
            onChanged: (v) => change(haptics: v),
          ),
          const SizedBox(height: 24),
          DropdownButtonFormField<String>(
            isExpanded: true,
            itemHeight: null,
            initialValue: p.theme,
            decoration: const InputDecoration(labelText: 'Aparência'),
            items: const [
              DropdownMenuItem(
                value: 'system',
                child: Text('Acompanhar sistema'),
              ),
              DropdownMenuItem(value: 'light', child: Text('Claro')),
              DropdownMenuItem(value: 'dark', child: Text('Escuro')),
            ],
            onChanged: (v) {
              if (v != null) change(theme: v);
            },
          ),
          const SizedBox(height: 24),
          DropdownButtonFormField<String>(
            isExpanded: true,
            itemHeight: null,
            initialValue: p.unit,
            decoration: const InputDecoration(labelText: 'Distância e ritmo'),
            items: const [
              DropdownMenuItem(value: 'km', child: Text('Quilômetros')),
              DropdownMenuItem(value: 'mi', child: Text('Milhas')),
            ],
            onChanged: (value) {
              if (value != null) change(unit: value);
            },
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () => showLicensePage(
              context: context,
              applicationName: 'AlongaPET',
              applicationVersion: '0.1.0',
            ),
            child: const Text('Licenças de software'),
          ),
          const Text(
            'Seus treinos são salvos localmente. Os treinos e o sinal sonoro funcionam offline; a voz depende de um idioma instalado. Esta versão pausa ao sair do app. O GPS funciona com o app visível. Mapas de base precisam de conexão. Notificações de intervalos em segundo plano ainda não estão disponíveis.',
          ),
        ],
      ),
    );
  }
}

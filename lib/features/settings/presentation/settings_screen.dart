import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/mapping_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nastavení')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.straighten),
                  title: const Text('Délka kroku'),
                  subtitle: const Text('Upravte podle vaší chůze (výchozí 0.70 m)'),
                  trailing: const Text('0.70 m'),
                  onTap: () {},
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.grid_on),
                  title: const Text('Rozlišení mapy'),
                  subtitle: const Text('Velikost jedné buňky'),
                  trailing: const Text('10 cm'),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pokročilé', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  const Text(
                    'Tato aplikace je komplexní demo architektury pro indoor SLAM. '
                    'V plné verzi by zde byly:\n\n'
                    '• Kalibrace gyroskopu a magnetometru\n'
                    '• Ladění parametrů filtrů (alpha, threshold)\n'
                    '• Export map do PLY / SVG / JSON\n'
                    '• Integrace ARCore / ARKit pro 3D\n'
                    '• Particle Filter a loop closure\n\n'
                    'Kód je připraven na další rozšíření.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: () {
              ref.read(mappingProvider.notifier).reset();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Všechna data byla resetována')),
              );
            },
            icon: const Icon(Icons.delete_forever),
            label: const Text('Resetovat všechna data'),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      ),
    );
  }
}

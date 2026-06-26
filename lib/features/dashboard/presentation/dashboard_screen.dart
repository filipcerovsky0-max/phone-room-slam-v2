import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../shared/providers/mapping_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mappingProvider);
    final pos = state.currentPosition;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Živé senzory'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Aktuální poloha', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _ValueTile('X', '${pos.x.toStringAsFixed(2)} m'),
                        _ValueTile('Y', '${pos.y.toStringAsFixed(2)} m'),
                        _ValueTile('Směr', '${(pos.heading * 180 / 3.14159).toStringAsFixed(0)}°'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: pos.confidence,
                      backgroundColor: Colors.grey.shade800,
                    ),
                    Text('Přesnost: ${(pos.confidence * 100).toInt()}%'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('Poslední data ze senzorů', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            if (state.recentSensorData.isNotEmpty) ...[
              _buildLiveChart(context, state),
            ] else
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('Spusťte mapování na záložce Mapa pro live data')),
                ),
              ),
            const SizedBox(height: 24),
            const Text(
              'Tip: Chodte po místnosti rovnoměrným krokem. Aplikace automaticky detekuje kroky a staví mapu.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveChart(BuildContext context, MappingState state) {
    final data = state.recentSensorData;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Magnituda akcelerace (kroky)'),
            SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: data.asMap().entries.map((e) {
                        return FlSpot(e.key.toDouble(), e.value.accelerationMagnitude);
                      }).toList(),
                      isCurved: true,
                      color: Colors.blueAccent,
                      barWidth: 2,
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ValueTile extends StatelessWidget {
  final String label;
  final String value;

  const _ValueTile(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        Text(value,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../repositories/auth_api.dart';
import '../state/entity_list_notifier.dart';
import '../widgets/list_state_body.dart';

/// П.20: отчёт стоимости складских остатков (price × quantity) со сводкой и диаграммой.
class InventoryReportScreen extends StatefulWidget {
  const InventoryReportScreen({super.key});

  @override
  State<InventoryReportScreen> createState() => _InventoryReportScreenState();
}

class _InventoryReportScreenState extends State<InventoryReportScreen> {
  LoadStatus _status = LoadStatus.idle;
  String? _error;
  List<Map<String, dynamic>> _rows = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _status = LoadStatus.loading;
      _error = null;
    });
    try {
      final rows = await context.read<AuthApi>().inventoryValuation();
      if (!mounted) return;
      setState(() {
        _rows = rows;
        _status = LoadStatus.success;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _status = LoadStatus.error;
      });
    }
  }

  double get _totalValue => _rows.fold<double>(
    0,
    (sum, r) => sum + ((r['total_value'] as num?)?.toDouble() ?? 0),
  );

  Map<String, double> get _byWarehouse {
    final map = <String, double>{};
    for (final r in _rows) {
      final name = r['warehouse_name'] as String? ?? '—';
      final v = (r['total_value'] as num?)?.toDouble() ?? 0;
      map[name] = (map[name] ?? 0) + v;
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final byWh = _byWarehouse;
    final maxV = byWh.values.fold<double>(0, (a, b) => a > b ? a : b);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Стоимость остатков'),
        actions: [
          IconButton(
            tooltip: 'Обновить',
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListStateBody(
        status: _status,
        error: _error,
        isEmpty: _rows.isEmpty,
        onRetry: _load,
        emptyTitle: 'Нет данных для отчёта',
        emptySubtitle: 'Добавьте товары на склады',
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Сводная стоимость активных остатков',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '${_totalValue.toStringAsFixed(2)} ₽',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: const Color(0xFF1976D2),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Расчёт: сумма (цена × количество) по товарам без логического удаления.',
              style: TextStyle(color: Colors.blueGrey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 24),
            Text('По складам', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ...byWh.entries.map((e) {
              final fraction = maxV <= 0 ? 0.0 : e.value / maxV;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(e.key, overflow: TextOverflow.ellipsis),
                        ),
                        Text('${e.value.toStringAsFixed(2)} ₽'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: fraction.clamp(0, 1),
                        minHeight: 12,
                        backgroundColor: Colors.blue.shade50,
                        color: const Color(0xFF1976D2),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),
            Text('Детализация', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ..._rows.map((r) {
              final wh = r['warehouse_name'] ?? '—';
              final cat = r['category_name'] ?? 'без категории';
              final value = (r['total_value'] as num?)?.toDouble() ?? 0;
              final qty = r['total_qty'] ?? 0;
              return Card(
                child: ListTile(
                  title: Text('$wh · $cat', overflow: TextOverflow.ellipsis),
                  subtitle: Text(
                    'Позиций: ${r['product_count'] ?? 0}, кол-во: $qty',
                  ),
                  trailing: Text('${value.toStringAsFixed(2)} ₽'),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

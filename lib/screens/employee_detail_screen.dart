import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../repositories/employee_repository.dart';

class EmployeeDetailScreen extends StatelessWidget {
  final int id;
  const EmployeeDetailScreen({super.key, required this.id});

  String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: context.read<EmployeeRepository>().findById(id),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final e = snapshot.data;
        if (e == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Сотрудник')),
            body: const Center(child: Text('Сотрудник не найден')),
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: Text(e.fullName),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/employees'),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => context.go('/employees/${e.id}/edit'),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _row('Email', e.email),
                      _row('Телефон', e.phone),
                      _row('Должность', e.position),
                      _row('Статус', e.isDeleted ? 'Удалён' : 'Активен'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Пропуск',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      _row('Номер', e.badge.number),
                      _row('Уровень', e.badge.level),
                      _row('Выдан', _fmt(e.badge.issuedAt)),
                      _row(
                        'Действует до',
                        e.badge.expiresAt == null
                            ? 'Бессрочно'
                            : _fmt(e.badge.expiresAt!),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        SizedBox(
          width: 140,
          child: Text(label, style: const TextStyle(color: Colors.blueGrey)),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/api_exceptions.dart';
import '../core/validators.dart';
import '../models/access_badge.dart';
import '../models/employee.dart';
import '../repositories/employee_repository.dart';
import '../state/employee_list_notifier.dart';
import '../widgets/unsaved_changes_scope.dart';

class EmployeeFormScreen extends StatefulWidget {
  final int? id;
  const EmployeeFormScreen({super.key, this.id});
  bool get isEditing => id != null;

  @override
  State<EmployeeFormScreen> createState() => _EmployeeFormScreenState();
}

class _EmployeeFormScreenState extends State<EmployeeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _positionCtrl = TextEditingController();
  final _badgeNumberCtrl = TextEditingController();
  final _badgeLevelCtrl = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  bool _dirty = false;
  Employee? _item;
  DateTime _issuedAt = DateTime.now();
  DateTime? _expiresAt;
  Map<String, String> _fieldErrors = {};

  static const levels = ['обычный', 'ограниченный', 'админ'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _positionCtrl.dispose();
    _badgeNumberCtrl.dispose();
    _badgeLevelCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    Employee? item;
    if (widget.isEditing) {
      item = await context.read<EmployeeRepository>().findById(widget.id!);
    }
    if (!mounted) return;

    if (item != null) {
      _nameCtrl.text = item.fullName;
      _emailCtrl.text = item.email;
      _phoneCtrl.text = item.phone;
      _positionCtrl.text = item.position;
      _badgeNumberCtrl.text = item.badge.number;
      _badgeLevelCtrl.text = item.badge.level;
      _issuedAt = item.badge.issuedAt;
      _expiresAt = item.badge.expiresAt;
    } else {
      _badgeLevelCtrl.text = 'обычный';
    }

    setState(() {
      _item = item;
      _loading = false;
    });
  }

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  Future<void> _pickDate({required bool expires}) async {
    final initial = expires
        ? (_expiresAt ?? DateTime.now().add(const Duration(days: 365)))
        : _issuedAt;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked == null) return;
    setState(() {
      if (expires) {
        _expiresAt = picked;
      } else {
        _issuedAt = picked;
      }
      _dirty = true;
    });
  }

  Future<void> _submit() async {
    setState(() => _fieldErrors = {});
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    final repo = context.read<EmployeeRepository>();

    final employee = Employee(
      id: widget.id ?? 0,
      fullName: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      position: _positionCtrl.text.trim(),
      badge: AccessBadge(
        number: _badgeNumberCtrl.text.trim(),
        level: _badgeLevelCtrl.text.trim(),
        issuedAt: _issuedAt,
        expiresAt: _expiresAt,
      ),
      deletedAt: _item?.deletedAt,
    );

    try {
      if (widget.isEditing) {
        await repo.update(employee);
      } else {
        await repo.create(employee);
      }
      _dirty = false;
      if (!mounted) return;
      await context.read<EmployeeListNotifier>().load();
      if (!mounted) return;
      context.go('/employees');
    } on ValidationException catch (e) {
      setState(() => _fieldErrors = e.errors);
      _formKey.currentState!.validate();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (widget.isEditing && _item == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Сотрудник')),
        body: const Center(child: Text('Сотрудник не найден')),
      );
    }

    final level = levels.contains(_badgeLevelCtrl.text)
        ? _badgeLevelCtrl.text
        : 'обычный';

    return UnsavedChangesScope(
      isDirty: _dirty,
      onPopConfirmed: () => context.go('/employees'),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.isEditing ? 'Редактирование сотрудника' : 'Новый сотрудник',
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/employees'),
          ),
        ),
        body: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'ФИО',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => _markDirty(),
                    validator: V.combine([
                      V.required(),
                      V.length(min: 3, max: 120),
                    ]),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) {
                      _fieldErrors.remove('email');
                      _markDirty();
                    },
                    validator: (v) {
                      final local = V.combine([V.required(), V.email()])(v);
                      if (local != null) return local;
                      return _fieldErrors['email'];
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Телефон',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => _markDirty(),
                    validator: V.combine([
                      V.required(),
                      V.length(min: 5, max: 40),
                    ]),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _positionCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Должность',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => _markDirty(),
                    validator: V.combine([
                      V.required(),
                      V.length(min: 2, max: 80),
                    ]),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Пропуск сотрудника',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.blue.shade800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _badgeNumberCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Номер пропуска',
                              border: OutlineInputBorder(),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            onChanged: (_) => _markDirty(),
                            validator: V.combine([
                              V.required(),
                              V.length(min: 3, max: 40),
                            ]),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            key: ValueKey('level-$level'),
                            initialValue: level,
                            decoration: const InputDecoration(
                              labelText: 'Уровень доступа',
                              border: OutlineInputBorder(),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            items: levels
                                .map(
                                  (l) => DropdownMenuItem(
                                    value: l,
                                    child: Text(l),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) {
                              if (v == null) return;
                              _badgeLevelCtrl.text = v;
                              _markDirty();
                            },
                            validator: (v) =>
                                v == null ? 'Выберите уровень' : null,
                          ),
                          const SizedBox(height: 16),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Дата выдачи'),
                            subtitle: Text(_fmt(_issuedAt)),
                            trailing: const Icon(Icons.calendar_today),
                            onTap: () => _pickDate(expires: false),
                          ),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Срок действия'),
                            subtitle: Text(
                              _expiresAt == null
                                  ? 'Бессрочно'
                                  : _fmt(_expiresAt!),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_expiresAt != null)
                                  IconButton(
                                    tooltip: 'Сделать бессрочным',
                                    onPressed: () => setState(() {
                                      _expiresAt = null;
                                      _dirty = true;
                                    }),
                                    icon: const Icon(Icons.clear),
                                  ),
                                const Icon(Icons.calendar_today),
                              ],
                            ),
                            onTap: () => _pickDate(expires: true),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _saving ? null : _submit,
                    child: Text(
                      widget.isEditing
                          ? 'Сохранить изменения'
                          : 'Создать сотрудника',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

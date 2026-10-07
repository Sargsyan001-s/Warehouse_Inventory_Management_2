import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/api_exceptions.dart';
import '../core/reference_cache.dart';
import '../core/validators.dart';
import '../models/category.dart';
import '../models/warehouse.dart';
import '../repositories/category_repository.dart';
import '../repositories/warehouse_repository.dart';
import '../state/warehouse_list_notifier.dart';
import '../widgets/entity_form.dart';
import '../widgets/unsaved_changes_scope.dart';

class WarehouseFormScreen extends StatefulWidget {
  final int? id;
  const WarehouseFormScreen({super.key, this.id});
  bool get isEditing => id != null;

  @override
  State<WarehouseFormScreen> createState() => _WarehouseFormScreenState();
}

class _WarehouseFormScreenState extends State<WarehouseFormScreen> {
  bool _loading = true;
  bool _dirty = false;
  Warehouse? _item;
  List<Category> _categories = [];
  List<int> _categoryIds = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final categoryRepo = context.read<CategoryRepository>();
    final warehouseRepo = context.read<WarehouseRepository>();
    final categories = await categoryRepo.findAll();
    Warehouse? item;
    if (widget.isEditing) {
      item = await warehouseRepo.findById(widget.id!);
    }
    if (!mounted) return;
    setState(() {
      _categories = categories;
      _item = item;
      _categoryIds = [...(item?.categoryIds ?? const [])];
      _loading = false;
    });
  }

  Future<Map<String, String>?> _submit(Map<String, dynamic> values) async {
    final repo = context.read<WarehouseRepository>();
    final warehouse = Warehouse(
      id: widget.id ?? 0,
      name: (values['name'] as String).trim(),
      code: (values['code'] as String).trim(),
      address: (values['address'] as String).trim(),
      city: (values['city'] as String).trim(),
      categoryIds: List<int>.from(values['categoryIds'] as List),
      deletedAt: _item?.deletedAt,
    );
    try {
      if (widget.isEditing) {
        await repo.update(warehouse);
      } else {
        await repo.create(warehouse);
      }
      if (!mounted) return null;
      context.read<ReferenceCache>().invalidate();
      _dirty = false;
      final listNotifier = context.read<WarehouseListNotifier>();
      await listNotifier.load();
      if (!mounted) return null;
      context.go('/warehouses');
      return null;
    } on ValidationException catch (e) {
      return e.errors;
    } on ConflictException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
      return null;
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (widget.isEditing && _item == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Склад')),
        body: const Center(child: Text('Склад не найден')),
      );
    }

    return UnsavedChangesScope(
      isDirty: _dirty,
      onPopConfirmed: () => context.go('/warehouses'),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.isEditing ? 'Редактирование склада' : 'Новый склад',
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/warehouses'),
          ),
        ),
        body: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: EntityForm(
                fields: [
                  EntityFieldSpec(
                    key: 'name',
                    label: 'Название',
                    kind: FormFieldKind.text,
                    validator: V.combine([
                      V.required(),
                      V.length(min: 2, max: 120),
                    ]),
                  ),
                  EntityFieldSpec(
                    key: 'code',
                    label: 'Код',
                    kind: FormFieldKind.text,
                    validator: V.combine([
                      V.required(),
                      V.length(min: 2, max: 20),
                    ]),
                  ),
                  EntityFieldSpec(
                    key: 'city',
                    label: 'Город',
                    kind: FormFieldKind.text,
                    validator: V.combine([
                      V.required(),
                      V.length(min: 2, max: 80),
                    ]),
                  ),
                  EntityFieldSpec(
                    key: 'address',
                    label: 'Адрес',
                    kind: FormFieldKind.text,
                    validator: V.combine([
                      V.required(),
                      V.length(min: 3, max: 200),
                    ]),
                  ),
                  EntityFieldSpec(
                    key: 'categoryIds',
                    label: 'Доступные категории',
                    kind: FormFieldKind.multiSelect,
                    chipOptions: _categories
                        .map((c) => ChipOption(id: c.id, label: c.name))
                        .toList(),
                  ),
                ],
                initialValues: {
                  'name': _item?.name ?? '',
                  'code': _item?.code ?? '',
                  'city': _item?.city ?? '',
                  'address': _item?.address ?? '',
                  'categoryIds': _categoryIds,
                },
                submitLabel: widget.isEditing
                    ? 'Сохранить изменения'
                    : 'Создать склад',
                onChanged: (v) {
                  setState(() {
                    _dirty = true;
                    _categoryIds = List<int>.from(
                      (v['categoryIds'] as List?) ?? const [],
                    );
                  });
                },
                onSubmit: _submit,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/api_exceptions.dart';
import '../core/reference_cache.dart';
import '../core/validators.dart';
import '../models/supplier.dart';
import '../repositories/supplier_repository.dart';
import '../state/supplier_list_notifier.dart';
import '../widgets/entity_form.dart';
import '../widgets/unsaved_changes_scope.dart';

class SupplierFormScreen extends StatefulWidget {
  final int? id;
  const SupplierFormScreen({super.key, this.id});
  bool get isEditing => id != null;

  @override
  State<SupplierFormScreen> createState() => _SupplierFormScreenState();
}

class _SupplierFormScreenState extends State<SupplierFormScreen> {
  bool _loading = true;
  bool _dirty = false;
  Supplier? _item;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    Supplier? item;
    if (widget.isEditing) {
      item = await context.read<SupplierRepository>().findById(widget.id!);
    }
    if (!mounted) return;
    setState(() {
      _item = item;
      _loading = false;
    });
  }

  Future<Map<String, String>?> _submit(Map<String, dynamic> values) async {
    final repo = context.read<SupplierRepository>();
    final supplier = Supplier(
      id: widget.id ?? 0,
      name: (values['name'] as String).trim(),
      country: (values['country'] as String).trim(),
      city: (values['city'] as String).trim(),
      phone: (values['phone'] as String).trim(),
      email: (values['email'] as String).trim(),
      deletedAt: _item?.deletedAt,
    );
    try {
      if (widget.isEditing) {
        await repo.update(supplier);
      } else {
        await repo.create(supplier);
      }
      if (!mounted) return null;
      context.read<ReferenceCache>().invalidate();
      _dirty = false;
      final listNotifier = context.read<SupplierListNotifier>();
      await listNotifier.load();
      if (!mounted) return null;
      context.go('/suppliers');
      return null;
    } on ValidationException catch (e) {
      return e.errors;
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
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
        appBar: AppBar(title: const Text('Поставщик')),
        body: const Center(child: Text('Поставщик не найден')),
      );
    }

    return UnsavedChangesScope(
      isDirty: _dirty,
      onPopConfirmed: () => context.go('/suppliers'),
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.isEditing ? 'Редактирование поставщика' : 'Новый поставщик'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/suppliers'),
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
                    validator: V.combine([V.required(), V.length(min: 2, max: 120)]),
                  ),
                  EntityFieldSpec(
                    key: 'country',
                    label: 'Страна',
                    kind: FormFieldKind.text,
                    validator: V.combine([V.required(), V.length(min: 2, max: 80)]),
                  ),
                  EntityFieldSpec(
                    key: 'city',
                    label: 'Город',
                    kind: FormFieldKind.text,
                    validator: V.combine([V.required(), V.length(min: 2, max: 80)]),
                  ),
                  EntityFieldSpec(
                    key: 'phone',
                    label: 'Телефон',
                    kind: FormFieldKind.text,
                    validator: V.combine([V.required(), V.length(min: 5, max: 40)]),
                  ),
                  EntityFieldSpec(
                    key: 'email',
                    label: 'Email',
                    kind: FormFieldKind.email,
                    validator: V.combine([V.required(), V.email()]),
                  ),
                ],
                initialValues: {
                  'name': _item?.name ?? '',
                  'country': _item?.country ?? '',
                  'city': _item?.city ?? '',
                  'phone': _item?.phone ?? '',
                  'email': _item?.email ?? '',
                },
                submitLabel: widget.isEditing ? 'Сохранить изменения' : 'Создать поставщика',
                onChanged: (_) => setState(() => _dirty = true),
                onSubmit: _submit,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

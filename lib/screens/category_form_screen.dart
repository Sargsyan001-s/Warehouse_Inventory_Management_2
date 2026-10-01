import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/validators.dart';
import '../models/category.dart';
import '../repositories/category_repository.dart';
import '../state/category_list_notifier.dart';
import '../widgets/entity_form.dart';
import '../widgets/unsaved_changes_scope.dart';

class CategoryFormScreen extends StatefulWidget {
  final int? id;
  const CategoryFormScreen({super.key, this.id});
  bool get isEditing => id != null;

  @override
  State<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends State<CategoryFormScreen> {
  bool _loading = true;
  bool _dirty = false;
  Category? _item;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    Category? item;
    if (widget.isEditing) {
      item = await context.read<CategoryRepository>().findById(widget.id!);
    }
    if (!mounted) return;
    setState(() {
      _item = item;
      _loading = false;
    });
  }

  Future<Map<String, String>?> _submit(Map<String, dynamic> values) async {
    final repo = context.read<CategoryRepository>();
    final category = Category(
      id: widget.id ?? 0,
      name: (values['name'] as String).trim(),
      description: (values['description'] as String).trim(),
      deletedAt: _item?.deletedAt,
    );
    if (widget.isEditing) {
      await repo.update(category);
    } else {
      await repo.create(category);
    }
    _dirty = false;
    if (!mounted) return null;
    final listNotifier = context.read<CategoryListNotifier>();
    await listNotifier.load();
    if (!mounted) return null;
    context.go('/categories');
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (widget.isEditing && _item == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Категория')),
        body: const Center(child: Text('Категория не найдена')),
      );
    }

    return UnsavedChangesScope(
      isDirty: _dirty,
      onPopConfirmed: () => context.go('/categories'),
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.isEditing ? 'Редактирование категории' : 'Новая категория'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/categories'),
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
                    validator: V.combine([V.required(), V.length(min: 2, max: 80)]),
                  ),
                  EntityFieldSpec(
                    key: 'description',
                    label: 'Описание',
                    kind: FormFieldKind.text,
                    maxLines: 3,
                    validator: V.length(max: 500),
                  ),
                ],
                initialValues: {
                  'name': _item?.name ?? '',
                  'description': _item?.description ?? '',
                },
                submitLabel: widget.isEditing ? 'Сохранить изменения' : 'Создать категорию',
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

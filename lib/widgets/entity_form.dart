import 'package:flutter/material.dart';

import '../core/validators.dart';

enum FormFieldKind { text, number, email, dropdown, multiSelect, section }

class DropdownOption {
  final int value;
  final String label;

  const DropdownOption({required this.value, required this.label});
}

class ChipOption {
  final int id;
  final String label;

  const ChipOption({required this.id, required this.label});
}

class EntityFieldSpec {
  final String key;
  final String label;
  final FormFieldKind kind;
  final Validator? validator;
  final TextInputType? keyboardType;
  final int maxLines;
  final List<DropdownOption> dropdownOptions;
  final List<ChipOption> chipOptions;
  final String? hint;

  const EntityFieldSpec({
    required this.key,
    required this.label,
    required this.kind,
    this.validator,
    this.keyboardType,
    this.maxLines = 1,
    this.dropdownOptions = const [],
    this.chipOptions = const [],
    this.hint,
  });
}

/// Общая форма: разметка и отправка едины для всех сущностей.
class EntityForm extends StatefulWidget {
  final List<EntityFieldSpec> fields;
  final Map<String, dynamic> initialValues;
  final String submitLabel;
  final Future<Map<String, String>?> Function(Map<String, dynamic> values) onSubmit;
  final ValueChanged<Map<String, dynamic>>? onChanged;
  final GlobalKey<FormState>? formKey;

  const EntityForm({
    super.key,
    required this.fields,
    required this.initialValues,
    required this.onSubmit,
    this.submitLabel = 'Сохранить',
    this.onChanged,
    this.formKey,
  });

  @override
  State<EntityForm> createState() => EntityFormState();
}

class EntityFormState extends State<EntityForm> {
  late final GlobalKey<FormState> _formKey;
  late Map<String, dynamic> _values;
  late Map<String, TextEditingController> _controllers;
  Map<String, String> _fieldErrors = {};
  bool _saving = false;
  bool dirty = false;

  @override
  void initState() {
    super.initState();
    _formKey = widget.formKey ?? GlobalKey<FormState>();
    _values = Map<String, dynamic>.from(widget.initialValues);
    _controllers = {};
    for (final field in widget.fields) {
      if (field.kind == FormFieldKind.text ||
          field.kind == FormFieldKind.number ||
          field.kind == FormFieldKind.email) {
        _controllers[field.key] = TextEditingController(
          text: '${_values[field.key] ?? ''}',
        );
      }
    }
  }

  @override
  void didUpdateWidget(covariant EntityForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Обновляем опции (каскад), значения контроллеров не трогаем.
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Map<String, dynamic> collect() {
    final result = Map<String, dynamic>.from(_values);
    for (final entry in _controllers.entries) {
      result[entry.key] = entry.value.text;
    }
    return result;
  }

  void _markDirty() {
    if (!dirty) {
      setState(() => dirty = true);
    }
    widget.onChanged?.call(collect());
  }

  void _setValue(String key, dynamic value) {
    setState(() {
      _values[key] = value;
      _fieldErrors.remove(key);
    });
    _markDirty();
  }

  Future<void> submit() async {
    setState(() => _fieldErrors = {});
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    final values = collect();
    final errors = await widget.onSubmit(values);
    if (!mounted) return;
    setState(() => _saving = false);

    if (errors != null && errors.isNotEmpty) {
      setState(() => _fieldErrors = errors);
      _formKey.currentState!.validate();
      return;
    }
    dirty = false;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...widget.fields.map(_buildField),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : submit,
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(widget.submitLabel),
          ),
        ],
      ),
    );
  }

  Widget _buildField(EntityFieldSpec field) {
    switch (field.kind) {
      case FormFieldKind.section:
        return Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Text(
            field.label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.blue.shade800,
                ),
          ),
        );
      case FormFieldKind.text:
      case FormFieldKind.number:
      case FormFieldKind.email:
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: TextFormField(
            controller: _controllers[field.key],
            keyboardType: field.keyboardType ??
                (field.kind == FormFieldKind.number
                    ? TextInputType.number
                    : field.kind == FormFieldKind.email
                        ? TextInputType.emailAddress
                        : TextInputType.text),
            maxLines: field.maxLines,
            decoration: InputDecoration(
              labelText: field.label,
              hintText: field.hint,
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) {
              _fieldErrors.remove(field.key);
              _markDirty();
            },
            validator: (value) {
              final local = field.validator?.call(value);
              if (local != null) return local;
              return _fieldErrors[field.key];
            },
          ),
        );
      case FormFieldKind.dropdown:
        final current = _values[field.key] as int?;
        final ids = field.dropdownOptions.map((o) => o.value).toSet();
        final safeValue = current != null && ids.contains(current) ? current : null;
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: DropdownButtonFormField<int>(
            key: ValueKey('${field.key}-$safeValue-${ids.length}'),
            initialValue: safeValue,
            decoration: InputDecoration(
              labelText: field.label,
              border: const OutlineInputBorder(),
            ),
            items: field.dropdownOptions
                .map((o) => DropdownMenuItem(value: o.value, child: Text(o.label)))
                .toList(),
            onChanged: (v) => _setValue(field.key, v),
            validator: (value) {
              if (value == null) return 'Выберите значение';
              return _fieldErrors[field.key];
            },
          ),
        );
      case FormFieldKind.multiSelect:
        final selected = List<int>.from((_values[field.key] as List?) ?? const []);
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: FormField<List<int>>(
            initialValue: selected,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Выберите хотя бы одно значение';
              }
              return _fieldErrors[field.key];
            },
            builder: (state) {
              return InputDecorator(
                decoration: InputDecoration(
                  labelText: field.label,
                  border: const OutlineInputBorder(),
                  errorText: state.errorText,
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: field.chipOptions.map((opt) {
                    final isSelected = state.value!.contains(opt.id);
                    return FilterChip(
                      label: Text(opt.label),
                      selected: isSelected,
                      onSelected: (_) {
                        final next = [...state.value!];
                        isSelected ? next.remove(opt.id) : next.add(opt.id);
                        state.didChange(next);
                        _setValue(field.key, next);
                      },
                    );
                  }).toList(),
                ),
              );
            },
          ),
        );
    }
  }
}

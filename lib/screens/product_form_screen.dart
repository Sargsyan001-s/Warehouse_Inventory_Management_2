import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/validators.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../models/supplier.dart';
import '../models/warehouse.dart';
import '../repositories/category_repository.dart';
import '../repositories/product_repository.dart';
import '../repositories/supplier_repository.dart';
import '../repositories/warehouse_repository.dart';
import '../state/product_list_notifier.dart';
import '../widgets/unsaved_changes_scope.dart';

class ProductFormScreen extends StatefulWidget {
  final int? id;

  const ProductFormScreen({super.key, this.id});

  bool get isEditing => id != null;

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _skuCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final _unitCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  bool _dirty = false;
  Product? _product;
  List<Warehouse> _warehouses = [];
  List<Category> _categories = [];
  List<Supplier> _suppliers = [];
  int? _warehouseId;
  List<int> _categoryIds = [];
  List<int> _supplierIds = [];
  Map<String, String> _fieldErrors = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _skuCtrl.dispose();
    _priceCtrl.dispose();
    _qtyCtrl.dispose();
    _unitCtrl.dispose();
    _yearCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final warehouseRepo = context.read<WarehouseRepository>();
    final categoryRepo = context.read<CategoryRepository>();
    final supplierRepo = context.read<SupplierRepository>();
    final productRepo = context.read<ProductRepository>();
    final warehouses = await warehouseRepo.findAll();
    final categories = await categoryRepo.findAll();
    final suppliers = await supplierRepo.findAll();
    Product? product;
    if (widget.isEditing) {
      product = await productRepo.findById(widget.id!);
    }

    if (!mounted) return;

    if (product != null) {
      _nameCtrl.text = product.name;
      _skuCtrl.text = product.sku;
      _priceCtrl.text = product.price.toString();
      _qtyCtrl.text = product.quantity.toString();
      _unitCtrl.text = product.unit;
      _yearCtrl.text = product.yearReceived.toString();
    } else {
      _unitCtrl.text = 'шт';
    }

    setState(() {
      _warehouses = warehouses;
      _categories = categories;
      _suppliers = suppliers;
      _product = product;
      _warehouseId = product?.warehouseId;
      _categoryIds = [...(product?.categoryIds ?? const [])];
      _supplierIds = [...(product?.supplierIds ?? const [])];
      _loading = false;
    });
  }

  List<Category> get _availableCategories {
    if (_warehouseId == null) return _categories;
    Warehouse? wh;
    for (final w in _warehouses) {
      if (w.id == _warehouseId) {
        wh = w;
        break;
      }
    }
    if (wh == null || wh.categoryIds.isEmpty) return _categories;
    return _categories.where((c) => wh!.categoryIds.contains(c.id)).toList();
  }

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  void _onWarehouseChanged(int? value) {
    setState(() {
      _warehouseId = value;
      _fieldErrors.remove('warehouseId');
      final allowed = _availableCategories.map((c) => c.id).toSet();
      _categoryIds = _categoryIds.where(allowed.contains).toList();
      _dirty = true;
    });
  }

  Future<bool> _confirmLeave() async {
    if (!_dirty) return true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Несохранённые изменения'),
        content: const Text('Уйти без сохранения? Изменения будут потеряны.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Остаться')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Уйти')),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _submit() async {
    setState(() => _fieldErrors = {});
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    final repo = context.read<ProductRepository>();
    final sku = _skuCtrl.text.trim();
    final unique = await repo.isSkuUnique(sku, excludeId: widget.id);
    if (!unique) {
      setState(() {
        _fieldErrors = {'sku': 'Товар с таким артикулом уже существует'};
        _saving = false;
      });
      _formKey.currentState!.validate();
      return;
    }

    final product = Product(
      id: widget.id ?? 0,
      name: _nameCtrl.text.trim(),
      sku: sku,
      warehouseId: _warehouseId!,
      categoryIds: _categoryIds,
      supplierIds: _supplierIds,
      price: double.parse(_priceCtrl.text.replaceAll(',', '.')),
      quantity: int.parse(_qtyCtrl.text),
      unit: _unitCtrl.text.trim(),
      yearReceived: int.parse(_yearCtrl.text),
      deletedAt: _product?.deletedAt,
    );

    if (widget.isEditing) {
      await repo.update(product);
    } else {
      await repo.create(product);
    }

    _dirty = false;
    if (!mounted) return;
    final listNotifier = context.read<ProductListNotifier>();
    await listNotifier.load();
    if (!mounted) return;
    context.go('/products');
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (widget.isEditing && _product == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Товар')),
        body: const Center(child: Text('Товар не найден')),
      );
    }

    final warehouseIds = _warehouses.map((w) => w.id).toSet();
    final safeWarehouse =
        _warehouseId != null && warehouseIds.contains(_warehouseId) ? _warehouseId : null;

    return UnsavedChangesScope(
      isDirty: _dirty,
      onPopConfirmed: () => context.go('/products'),
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.isEditing ? 'Редактирование товара' : 'Новый товар'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              if (await _confirmLeave() && context.mounted) {
                context.go('/products');
              }
            },
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
                      labelText: 'Название',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) {
                      _fieldErrors.remove('name');
                      _markDirty();
                    },
                    validator: V.combine([V.required(), V.length(min: 2, max: 200)]),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _skuCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Артикул (SKU)',
                      hintText: 'Уникальный код товара',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) {
                      _fieldErrors.remove('sku');
                      _markDirty();
                    },
                    validator: (v) {
                      final local = V.combine([V.required(), V.length(min: 3, max: 40)])(v);
                      if (local != null) return local;
                      return _fieldErrors['sku'];
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    key: ValueKey('wh-$safeWarehouse'),
                    initialValue: safeWarehouse,
                    decoration: const InputDecoration(
                      labelText: 'Склад',
                      border: OutlineInputBorder(),
                    ),
                    items: _warehouses
                        .map((w) => DropdownMenuItem(
                              value: w.id,
                              child: Text('${w.name} (${w.code})'),
                            ))
                        .toList(),
                    onChanged: _onWarehouseChanged,
                    validator: (v) => v == null ? 'Выберите склад' : null,
                  ),
                  const SizedBox(height: 8),
                  if (_warehouseId != null)
                    Text(
                      'Категории сужены по выбранному складу',
                      style: TextStyle(color: Colors.blueGrey.shade600, fontSize: 12),
                    ),
                  const SizedBox(height: 16),
                  FormField<List<int>>(
                    key: ValueKey('cats-$_warehouseId-${_categoryIds.join(',')}'),
                    initialValue: _categoryIds,
                    validator: (value) =>
                        (value == null || value.isEmpty) ? 'Выберите хотя бы одну категорию' : null,
                    builder: (field) {
                      return InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Категории',
                          border: const OutlineInputBorder(),
                          errorText: field.errorText,
                        ),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _availableCategories.map((c) {
                            final selected = field.value!.contains(c.id);
                            return FilterChip(
                              label: Text(c.name),
                              selected: selected,
                              onSelected: (_) {
                                final next = [...field.value!];
                                selected ? next.remove(c.id) : next.add(c.id);
                                field.didChange(next);
                                setState(() {
                                  _categoryIds = next;
                                  _dirty = true;
                                });
                              },
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  FormField<List<int>>(
                    initialValue: _supplierIds,
                    validator: (value) =>
                        (value == null || value.isEmpty) ? 'Выберите хотя бы одного поставщика' : null,
                    builder: (field) {
                      return InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Поставщики',
                          border: const OutlineInputBorder(),
                          errorText: field.errorText,
                        ),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _suppliers.map((s) {
                            final selected = field.value!.contains(s.id);
                            return FilterChip(
                              label: Text(s.name),
                              selected: selected,
                              onSelected: (_) {
                                final next = [...field.value!];
                                selected ? next.remove(s.id) : next.add(s.id);
                                field.didChange(next);
                                setState(() {
                                  _supplierIds = next;
                                  _dirty = true;
                                });
                              },
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _priceCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Цена',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => _markDirty(),
                    validator: V.combine([V.required(), V.positiveNumber()]),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _qtyCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Количество',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => _markDirty(),
                    validator: V.combine([V.required(), V.integer(min: 0)]),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _unitCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Ед. измерения',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => _markDirty(),
                    validator: V.combine([V.required(), V.length(min: 1, max: 20)]),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _yearCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Год поступления',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => _markDirty(),
                    validator: V.combine([V.required(), V.integer(min: 2000, max: 2100)]),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _saving ? null : _submit,
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(widget.isEditing ? 'Сохранить изменения' : 'Создать товар'),
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

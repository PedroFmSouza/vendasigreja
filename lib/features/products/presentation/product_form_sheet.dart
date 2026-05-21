import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../domain/product.dart';
import 'product_providers.dart';

const _kCategories = [
  'Bebidas',
  'Lanches',
  'Comida',
  'Doces',
  'Outros',
];

class ProductFormSheet extends ConsumerStatefulWidget {
  final Product? product;
  const ProductFormSheet({super.key, this.product});

  static Future<void> show(BuildContext context, {Product? product}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProductFormSheet(product: product),
    );
  }

  @override
  ConsumerState<ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends ConsumerState<ProductFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _price;
  late final TextEditingController _category;
  bool _saving = false;

  bool get _isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _name = TextEditingController(text: p?.name ?? '');
    _price = TextEditingController(
      text: p == null
          ? ''
          : (p.price / 100).toStringAsFixed(2).replaceAll('.', ','),
    );
    _category = TextEditingController(text: p?.category ?? 'Geral');
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _category.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final cents = Money.parse(_price.text)!;
    final notifier = ref.read(productListProvider.notifier);
    final cat =
        _category.text.trim().isEmpty ? 'Geral' : _category.text.trim();

    if (_isEdit) {
      await notifier.editProduct(widget.product!.copyWith(
        name: _name.text.trim(),
        price: cents,
        category: cat,
      ));
    } else {
      await notifier.createProduct(Product(
        name: _name.text.trim(),
        price: cents,
        category: cat,
        createdAt: DateTime.now(),
      ));
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + bottomInset),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _isEdit ? Icons.edit_rounded : Icons.add_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _isEdit ? 'Editar produto' : 'Novo produto',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Nome do produto',
                prefixIcon: const Icon(Icons.fastfood_rounded, size: 20),
                prefixIconColor: AppColors.textSecondary,
              ),
              style: GoogleFonts.inter(fontSize: 15),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Informe o nome' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _price,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: InputDecoration(
                labelText: 'Preço',
                prefixText: 'R\$ ',
                prefixIcon: const Icon(Icons.attach_money_rounded, size: 20),
                prefixIconColor: AppColors.textSecondary,
              ),
              style: GoogleFonts.inter(fontSize: 15),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Informe o preço';
                final cents = Money.parse(v);
                if (cents == null) return 'Preço inválido';
                if (cents == 0) return 'Preço deve ser maior que zero';
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _category,
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Categoria',
                hintText: 'Ex: Comidas Típicas',
                prefixIcon: const Icon(Icons.category_rounded, size: 20),
                prefixIconColor: AppColors.textSecondary,
              ),
              style: GoogleFonts.inter(fontSize: 15),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: _kCategories.map((cat) {
                final selected = _category.text.trim().toLowerCase() ==
                    cat.toLowerCase();
                return GestureDetector(
                  onTap: () => setState(() {
                    _category.text = cat;
                    _category.selection = TextSelection.fromPosition(
                      TextPosition(offset: cat.length),
                    );
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primary
                          : AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected
                            ? AppColors.primary
                            : AppColors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      cat,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? Colors.white
                            : AppColors.primary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(_isEdit ? 'Salvar alterações' : 'Adicionar produto'),
            ),
          ],
        ),
      ),
    );
  }
}

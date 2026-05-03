import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sunmi_pos/features/products/providers/product_provider.dart';
import 'package:sunmi_pos/features/products/providers/category_provider.dart';
import 'package:sunmi_pos/features/deals/providers/deal_provider.dart';
import 'package:sunmi_pos/features/pos/providers/cart_provider.dart';
import 'package:sunmi_pos/core/theme/app_theme.dart';
import 'package:sunmi_pos/models/category.dart';
import 'package:sunmi_pos/models/product.dart';
import 'package:sunmi_pos/models/deal.dart';
import 'package:sunmi_pos/models/product_variant.dart';

class ProductGrid extends StatelessWidget {
  final dynamic categoryId;

  const ProductGrid({
    super.key,
    this.categoryId,
  });

  @override
  Widget build(BuildContext context) {
    if (categoryId.toString().toUpperCase() == 'DEALS') {
      return const DealGrid();
    }

    return Consumer2<ProductProvider, CategoryProvider>(
      builder: (ctx, prodProvider, catProvider, _) {
        if (prodProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final products = prodProvider.products.where((p) {
          if (categoryId == null) return true;
          return p.categoryId == categoryId;
        }).toList();

        if (products.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2_outlined,
                    size: 48, color: AppTheme.textMuted.withOpacity(0.5)),
                const SizedBox(height: 16),
                const Text(
                  'NO PRODUCTS FOUND',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textMuted,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(20),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            childAspectRatio: 0.65,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            return _ProductTile(product: products[index]);
          },
        );
      },
    );
  }
}

class _ProductTile extends StatefulWidget {
  final Product product;

  const _ProductTile({required this.product});

  @override
  State<_ProductTile> createState() => _ProductTileState();
}

class _ProductTileState extends State<_ProductTile> {
  bool _isInverted = false;

  void _handleTap() async {
    setState(() => _isInverted = true);
    
    if (widget.product.variants.isNotEmpty) {
      final selected = await _showVariantDialog();
      if (selected != null && mounted) {
        Provider.of<CartProvider>(context, listen: false).addToCart(widget.product, variant: selected);
      }
    } else {
      Provider.of<CartProvider>(context, listen: false).addToCart(widget.product);
    }
    
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) setState(() => _isInverted = false);
    });
  }

  Future<ProductVariant?> _showVariantDialog() {
    return showDialog<ProductVariant>(
      context: context,
      builder: (ctx) => AlertDialog(
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radius)),
        title: Text('CHOOSE VARIANT: ${widget.product.name.toUpperCase()}', 
            style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w900)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...ListTile.divideTiles(
              context: ctx,
              color: AppTheme.outline,
              tiles: widget.product.variants.map((v) => ListTile(
                title: Text(v.name.toUpperCase(), style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w700)),
                trailing: Text('Rs. ${v.price.toStringAsFixed(0)}', style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w900)),
                onTap: () => Navigator.pop(ctx, v),
              )),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _isInverted ? AppTheme.primary : AppTheme.surface;
    final textColor = _isInverted ? Colors.white : AppTheme.onSurface;
    final borderColor = _isInverted ? AppTheme.primary : AppTheme.outline;

    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppTheme.radius),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Section
            Expanded(
              flex: 6,
              child: widget.product.imagePath != null
                  ? Image.file(
                      File(widget.product.imagePath!),
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: _isInverted ? Colors.white.withOpacity(0.05) : AppTheme.background,
                      child: Icon(
                        Icons.fastfood_outlined,
                        color: _isInverted ? Colors.white.withOpacity(0.2) : AppTheme.outline,
                        size: 32,
                      ),
                    ),
            ),
            // Name & Info Section
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.product.name.toUpperCase(),
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                        color: textColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Expanded(child: SizedBox(height: 2)),
                    if (widget.product.trackStock)
                      Text(
                        'STOCK: ${widget.product.stockQty}',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: _isInverted ? Colors.white.withOpacity(0.7) : AppTheme.textMuted,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Price Section
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: _isInverted ? Colors.white.withOpacity(0.1) : AppTheme.background,
                border: Border(top: BorderSide(color: _isInverted ? Colors.white.withOpacity(0.1) : AppTheme.outline)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Rs. ${widget.product.price.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: _isInverted ? Colors.white : AppTheme.primary,
                    ),
                  ),
                  if (widget.product.variants.isNotEmpty)
                    Icon(
                      Icons.layers_outlined,
                      size: 14,
                      color: _isInverted ? Colors.white.withOpacity(0.8) : AppTheme.textMuted,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DealGrid extends StatelessWidget {
  const DealGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DealProvider>(
      builder: (context, dealProvider, _) {
        if (dealProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final deals = dealProvider.deals.where((d) => d.isActive).toList();

        if (deals.isEmpty) {
          return const Center(
            child: Text(
              'NO ACTIVE DEALS',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
                color: AppTheme.textMuted,
              ),
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(20),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            childAspectRatio: 0.72,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: deals.length,
          itemBuilder: (context, index) {
            return _DealTile(deal: deals[index]);
          },
        );
      },
    );
  }
}

class _DealTile extends StatefulWidget {
  final Deal deal;

  const _DealTile({required this.deal});

  @override
  State<_DealTile> createState() => _DealTileState();
}

class _DealTileState extends State<_DealTile> {
  bool _isInverted = false;

  void _handleTap() async {
    final Map<int, ProductVariant> selections = {};
    
    setState(() => _isInverted = true);
    
    for (var di in widget.deal.items) {
      if (di.variantId == null && di.product != null && di.product!.variants.isNotEmpty) {
        final ProductVariant? selected = await _showDealVariantDialog(di);
        if (selected == null) {
          if (mounted) setState(() => _isInverted = false);
          return;
        }
        selections[di.id!] = selected;
      }
    }
    
    if (mounted) {
      Provider.of<CartProvider>(context, listen: false).addDealToCart(widget.deal, selections: selections);
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) setState(() => _isInverted = false);
      });
    }
  }

  Future<ProductVariant?> _showDealVariantDialog(DealItem di) {
    return showDialog<ProductVariant>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('DEAL: ${widget.deal.name.toUpperCase()}', 
                 style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.warning)),
            Text('CHOOSE ${di.product!.name.toUpperCase()}', 
                 style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Divider(),
              ...ListTile.divideTiles(
                context: ctx,
                color: AppTheme.outline,
                tiles: di.product!.variants.map((v) => ListTile(
                  title: Text(v.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w800)),
                  trailing: const Icon(Icons.chevron_right, color: AppTheme.primary),
                  onTap: () => Navigator.pop(ctx, v),
                )),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('CANCEL SELECTION', style: TextStyle(color: AppTheme.textMuted)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _isInverted ? AppTheme.primary : AppTheme.surface;
    final textColor = _isInverted ? Colors.white : AppTheme.onSurface;
    final borderColor = _isInverted ? AppTheme.primary : AppTheme.warning;

    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppTheme.radius),
          border: Border.all(color: borderColor, width: 2),
          boxShadow: [
            if (!_isInverted)
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Deal Image
            Expanded(
              flex: 5,
              child: widget.deal.imagePath != null
                  ? Image.file(
                      File(widget.deal.imagePath!),
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: AppTheme.warning.withOpacity(0.1),
                      child: const Icon(Icons.stars, color: AppTheme.warning, size: 40),
                    ),
            ),
            // Info Section
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.deal.name.toUpperCase(),
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                        height: 1.1,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.zero,
                        physics: const NeverScrollableScrollPhysics(),
                        children: widget.deal.items.map((i) => Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle, size: 10, color: _isInverted ? Colors.white70 : AppTheme.warning),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '${i.qty}x ${i.product?.name ?? "..."}',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 10,
                                    color: _isInverted
                                        ? Colors.white.withOpacity(0.7)
                                        : AppTheme.textMuted,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        )).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: _isInverted
                    ? Colors.white.withOpacity(0.1)
                    : AppTheme.warning.withOpacity(0.05),
                border: Border(
                    top: BorderSide(
                        color: _isInverted
                            ? Colors.white.withOpacity(0.2)
                            : AppTheme.warning.withOpacity(0.2))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Rs. ${widget.deal.price.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: _isInverted ? Colors.white : AppTheme.primary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: _isInverted ? Colors.white24 : AppTheme.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 18),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

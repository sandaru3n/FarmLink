import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product_model.dart';
import '../../providers/product_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_localizations.dart';
import 'add_product_screen.dart';
import 'edit_product_screen.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All'; // All, Available, Low stock, Out of stock
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      
      if (authProvider.userProfile != null) {
        productProvider.loadDistributorProducts(authProvider.userProfile!.uid);
      }
    });
    _searchController.addListener(() => setState(() {}));
  }

  Future<void> _deleteProduct(ProductModel product) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.get('delete_product')),
        content: Text('${l10n.get('delete_product_confirm')} "${product.productName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.get('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.get('delete')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      final success = await productProvider.deleteProduct(product.id);
      
      if (success && mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.get('product_deleted_success'))),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${productProvider.error}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Modern Header
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.orange.shade700,
                  Colors.orange.shade500,
                  Colors.orange.shade400,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.amber.shade400, Colors.amber.shade600],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.inventory_2,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          l10n.get('my_products'),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: Colors.white, size: 32),
                      onPressed: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const AddProductScreen(),
                          ),
                        );
                        // Refresh the list after adding a product
                        final authProvider = Provider.of<AuthProvider>(context, listen: false);
                        final productProvider = Provider.of<ProductProvider>(context, listen: false);
                        if (authProvider.userProfile != null) {
                          productProvider.loadDistributorProducts(authProvider.userProfile!.uid);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Consumer<ProductProvider>(
              builder: (context, productProvider, child) {
          if (productProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (productProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${productProvider.error}',
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      productProvider.clearError();
                      final authProvider = Provider.of<AuthProvider>(context, listen: false);
                      if (authProvider.userProfile != null) {
                        productProvider.loadDistributorProducts(authProvider.userProfile!.uid);
                      }
                    },
                    child: Text(l10n.get('retry')),
                  ),
                ],
              ),
            );
          }

          if (productProvider.distributorProducts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.inventory_2_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.get('no_products_yet'),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.get('add_first_product'),
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const AddProductScreen(),
                        ),
                      );
                      // Refresh the list after adding a product
                      final authProvider = Provider.of<AuthProvider>(context, listen: false);
                      if (authProvider.userProfile != null) {
                        productProvider.loadDistributorProducts(authProvider.userProfile!.uid);
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: Text(l10n.get('add_product')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }

          // Stats & filters
          final products = productProvider.distributorProducts;
          final int total = products.length;
          final int available = products.where((p) => p.isAvailable).length;
          final int lowStock = products.where((p) => p.reorderLevel > 0 && p.quantity <= p.reorderLevel && p.quantity > 0).length;
          final int outOfStock = products.where((p) => p.quantity == 0).length;

          // Apply search and filter
          List<ProductModel> filtered = products.where((p) {
            final matchesSearch = _searchController.text.trim().isEmpty ||
                p.productName.toLowerCase().contains(_searchController.text.trim().toLowerCase());
            bool matchesFilter = true;
            switch (_selectedFilter) {
              case 'Available':
                matchesFilter = p.isAvailable && p.quantity > 0;
                break;
              case 'Low stock':
                matchesFilter = p.reorderLevel > 0 && p.quantity <= p.reorderLevel && p.quantity > 0;
                break;
              case 'Out of stock':
                matchesFilter = p.quantity == 0;
                break;
              default:
                matchesFilter = true;
            }
            return matchesSearch && matchesFilter;
          }).toList();

          return Column(
            children: [
              _StatsHeader(
                total: total, 
                available: available, 
                lowStock: lowStock, 
                outOfStock: outOfStock,
                inventoryOverviewLabel: l10n.get('inventory_overview'),
                lowStockLabel: l10n.get('low_stock'),
                outOfStockLabel: l10n.get('out_of_stock'),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            children: [
                              Icon(Icons.search, color: Colors.grey[600]),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  decoration: InputDecoration(
                                    hintText: l10n.get('search_products'),
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedFilter,
                            items: [
                              DropdownMenuItem(value: 'All', child: Text(l10n.get('all'))),
                              DropdownMenuItem(value: 'Available', child: Text(l10n.get('available'))),
                              DropdownMenuItem(value: 'Low stock', child: Text(l10n.get('low_stock'))),
                              DropdownMenuItem(value: 'Out of stock', child: Text(l10n.get('out_of_stock'))),
                            ],
                            onChanged: (v) => setState(() => _selectedFilter = v ?? 'All'),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final product = filtered[index];
              final bool isLowStock = product.quantity <= product.reorderLevel && product.reorderLevel > 0;
                    return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 4,
                shadowColor: Colors.orange.withOpacity(0.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.orange.shade100, width: 1),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.white, Colors.orange.shade50.withOpacity(0.3)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Product Image
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: product.imageUrl.isNotEmpty
                              ? Image.network(
                                  product.imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey.shade200,
                                      child: const Icon(
                                        Icons.image_not_supported,
                                        color: Colors.grey,
                                      ),
                                    );
                                  },
                                )
                              : Container(
                                  color: Colors.grey.shade200,
                                  child: const Icon(
                                    Icons.image_not_supported,
                                    color: Colors.grey,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      
                      // Product Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.productName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Quantity: ${product.quantity.toStringAsFixed(1)} kg',
                              style: TextStyle(
                                fontSize: 14,
                                color: isLowStock ? Colors.red : Colors.grey[600],
                              ),
                            ),
                            if (isLowStock) ...[
                              const SizedBox(height: 2),
                              Text(
                                l10n.get('low_stock'),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.red,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                            const SizedBox(height: 4),
                            Text(
                              'Price: LKR ${product.pricePerKg.toStringAsFixed(2)}/kg',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${l10n.get('total_value')}: LKR ${(product.quantity * product.pricePerKg).toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.orange,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _StockBar(product: product),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(l10n.get('available'), style: const TextStyle(fontSize: 12)),
                                    const SizedBox(width: 6),
                                    Switch(
                                      value: product.isAvailable,
                                      onChanged: (val) async {
                                        final provider = Provider.of<ProductProvider>(context, listen: false);
                                        final ok = await provider.setAvailability(product.id, val);
                                        if (!ok && context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Error: ${provider.error}')),
                                          );
                                        }
                                      },
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ],
                                ),
                                OutlinedButton.icon(
                                  onPressed: () => _showAdjustDialog(context, product, -1),
                                  icon: const Icon(Icons.remove),
                                  label: const Text('-1kg'),
                                  style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () => _showAdjustDialog(context, product, 1),
                                  icon: const Icon(Icons.add),
                                  label: const Text('+1kg'),
                                  style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                                ),
                                // Set baseline button
                                OutlinedButton.icon(
                                  onPressed: () async {
                                    final provider = Provider.of<ProductProvider>(context, listen: false);
                                    final ok = await provider.setBaselineToCurrent(product.id);
                                    if (ok && context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(l10n.get('baseline_set'))),
                                      );
                                    } else if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Error: ${provider.error}')),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.speed),
                                  label: Text(l10n.get('set_baseline')),
                                  style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      // Edit & Delete Buttons
                      Column(
                        children: [
                          IconButton(
                            onPressed: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => EditProductScreen(product: product),
                                ),
                              );
                            },
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            tooltip: l10n.get('edit_product'),
                          ),
                          IconButton(
                            onPressed: () => _deleteProduct(product),
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.red,
                            ),
                            tooltip: l10n.get('delete_product'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
                  },
                ),
              ),
            ],
          );
                },
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showAdjustDialog(BuildContext context, ProductModel product, double suggestedDelta) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController(text: suggestedDelta.toStringAsFixed(0));
    final result = await showDialog<double>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.get('adjust_stock_kg')),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: 'e.g., -5 or 10'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.get('cancel'))),
            TextButton(onPressed: () {
              final d = double.tryParse(controller.text.trim());
              if (d == null) {
                Navigator.of(context).pop();
                return;
              }
              Navigator.of(context).pop(d);
            }, child: Text(l10n.get('apply'))),
          ],
        );
      },
    );

    if (result != null) {
      final provider = Provider.of<ProductProvider>(context, listen: false);
      final ok = await provider.adjustStock(product.id, result);
      if (ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.get('stock_adjusted'))),
        );
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${provider.error}')),
        );
      }
    }
  }

}

Widget _metric(String title, String value, Color color, IconData icon) {
  return Expanded(
    child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _StatsHeader extends StatelessWidget {
  final int total;
  final int available;
  final int lowStock;
  final int outOfStock;
  final String inventoryOverviewLabel;
  final String lowStockLabel;
  final String outOfStockLabel;
  
  const _StatsHeader({
    required this.total, 
    required this.available, 
    required this.lowStock, 
    required this.outOfStock,
    required this.inventoryOverviewLabel,
    required this.lowStockLabel,
    required this.outOfStockLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade50, Colors.white],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange.shade100, Colors.orange.shade50],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.inventory_2, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  inventoryOverviewLabel,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _metric('Total', '$total', Colors.orange.shade700, Icons.dashboard),
              const SizedBox(width: 10),
              _metric('Available', '$available', Colors.green.shade600, Icons.check_circle),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _metric(lowStockLabel, '$lowStock', Colors.amber.shade700, Icons.warning_amber),
              const SizedBox(width: 10),
              _metric(outOfStockLabel, '$outOfStock', Colors.red.shade600, Icons.remove_circle),
            ],
          ),
        ],
      ),
    );
  }
}

Widget _buildStatsHeader(int total, int available, int lowStock, int outOfStock) {
  return _StatsHeader(
    total: total, 
    available: available, 
    lowStock: lowStock, 
    outOfStock: outOfStock,
    inventoryOverviewLabel: 'Inventory Overview',
    lowStockLabel: 'Low Stock',
    outOfStockLabel: 'Out of Stock',
  );
}

class _StockBar extends StatelessWidget {
  final ProductModel product;
  const _StockBar({required this.product});

  @override
  Widget build(BuildContext context) {
    final bool hasBaseline = product.initialQuantity > 0;
    final double baseline = hasBaseline ? product.initialQuantity : (product.quantity > 0 ? product.quantity : 1);
    final double pct = (baseline == 0) ? 0 : (product.quantity / baseline).clamp(0, 1);
    final int pctInt = (pct * 100).round();
    final Color barColor = pct <= 0.2
        ? Colors.red
        : (pct <= 0.5 ? Colors.orange : Colors.green);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Chip(
              label: Text('$pctInt%'),
              backgroundColor: barColor.withOpacity(0.1),
              labelStyle: TextStyle(color: barColor, fontWeight: FontWeight.bold),
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Chip(
                label: Text(
                  '${product.quantity.toStringAsFixed(1)} / ${baseline.toStringAsFixed(1)} kg${hasBaseline ? '' : ' (set baseline)'}',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                backgroundColor: Colors.grey.shade100,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            minHeight: 8,
            value: pct,
            backgroundColor: Colors.grey.shade200,
            color: barColor,
          ),
        ),
      ],
    );
  }
} 
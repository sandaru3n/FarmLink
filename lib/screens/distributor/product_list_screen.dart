import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product_model.dart';
import '../../providers/product_provider.dart';
import '../../providers/auth_provider.dart';
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.productName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      final success = await productProvider.deleteProduct(product.id);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product deleted successfully!')),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Products'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
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
      body: Consumer<ProductProvider>(
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
                    child: const Text('Retry'),
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
                  const Text(
                    'No products yet',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Add your first product to start selling',
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
                    label: const Text('Add Product'),
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
              _buildStatsHeader(total, available, lowStock, outOfStock),
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
                                  decoration: const InputDecoration(
                                    hintText: 'Search products...',
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
                            items: const [
                              DropdownMenuItem(value: 'All', child: Text('All')),
                              DropdownMenuItem(value: 'Available', child: Text('Available')),
                              DropdownMenuItem(value: 'Low stock', child: Text('Low stock')),
                              DropdownMenuItem(value: 'Out of stock', child: Text('Out of stock')),
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
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
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
                              const Text(
                                'Low stock',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.red,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                            const SizedBox(height: 4),
                            Text(
                              'Price: ₹${product.pricePerKg.toStringAsFixed(2)}/kg',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Total Value: ₹${(product.quantity * product.pricePerKg).toStringAsFixed(2)}',
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
                                    const Text('Available', style: TextStyle(fontSize: 12)),
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
                                        const SnackBar(content: Text('Baseline set to current quantity')),
                                      );
                                    } else if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Error: ${provider.error}')),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.speed),
                                  label: const Text('Set baseline'),
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
                            tooltip: 'Edit Product',
                          ),
                          IconButton(
                            onPressed: () => _deleteProduct(product),
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.red,
                            ),
                            tooltip: 'Delete Product',
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
    );
  }

  Future<void> _showAdjustDialog(BuildContext context, ProductModel product, double suggestedDelta) async {
    final controller = TextEditingController(text: suggestedDelta.toStringAsFixed(0));
    final result = await showDialog<double>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Adjust Stock (kg)'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: 'e.g., -5 or 10'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
            TextButton(onPressed: () {
              final d = double.tryParse(controller.text.trim());
              if (d == null) {
                Navigator.of(context).pop();
                return;
              }
              Navigator.of(context).pop(d);
            }, child: const Text('Apply')),
          ],
        );
      },
    );

    if (result != null) {
      final provider = Provider.of<ProductProvider>(context, listen: false);
      final ok = await provider.adjustStock(product.id, result);
      if (ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Stock adjusted')),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
              Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ],
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
  const _StatsHeader({required this.total, required this.available, required this.lowStock, required this.outOfStock});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFF3E0), Color(0xFFFFFBF2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.inventory_2, color: Colors.orange),
              const SizedBox(width: 8),
              Text('Inventory Overview', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.orange[800])),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _metric('Total', '$total', Colors.orange, Icons.list_alt),
              const SizedBox(width: 8),
              _metric('Available', '$available', Colors.green, Icons.check_circle),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _metric('Low stock', '$lowStock', Colors.orange, Icons.error_outline),
              const SizedBox(width: 8),
              _metric('Out of stock', '$outOfStock', Colors.red, Icons.remove_shopping_cart),
            ],
          ),
        ],
      ),
    );
  }
}

Widget _buildStatsHeader(int total, int available, int lowStock, int outOfStock) {
  return _StatsHeader(total: total, available: available, lowStock: lowStock, outOfStock: outOfStock);
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
            Chip(
              label: Text('${product.quantity.toStringAsFixed(1)} / ${baseline.toStringAsFixed(1)} kg${hasBaseline ? '' : ' (set baseline)'}'),
              backgroundColor: Colors.grey.shade100,
              visualDensity: VisualDensity.compact,
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
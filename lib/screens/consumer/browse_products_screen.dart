import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product_model.dart';
import '../../providers/product_provider.dart';
import 'product_detail_screen.dart';

class BrowseProductsScreen extends StatefulWidget {
  const BrowseProductsScreen({super.key});

  @override
  State<BrowseProductsScreen> createState() => _BrowseProductsScreenState();
}

class _BrowseProductsScreenState extends State<BrowseProductsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'All';
  RangeValues _priceRange = const RangeValues(0, 1000);
  
  final List<String> _filterOptions = [
    'All',
    'Price: Low to High',
    'Price: High to Low',
    'Quantity: High to Low',
    'Quantity: Low to High',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      productProvider.loadAllAvailableProducts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse Products'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _showFilterDialog(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
                             decoration: InputDecoration(
                 hintText: 'Search products...',
                 prefixIcon: const Icon(Icons.search, color: Colors.orange),
                 suffixIcon: _searchQuery.isNotEmpty
                     ? IconButton(
                         icon: const Icon(Icons.clear, color: Colors.orange),
                         onPressed: () {
                           _searchController.clear();
                           setState(() {
                             _searchQuery = '';
                           });
                         },
                       )
                     : null,
                 border: OutlineInputBorder(
                   borderRadius: BorderRadius.circular(12),
                   borderSide: const BorderSide(color: Colors.orange, width: 2),
                 ),
                 enabledBorder: OutlineInputBorder(
                   borderRadius: BorderRadius.circular(12),
                   borderSide: const BorderSide(color: Colors.orange, width: 2),
                 ),
                 focusedBorder: OutlineInputBorder(
                   borderRadius: BorderRadius.circular(12),
                   borderSide: const BorderSide(color: Colors.orange, width: 3),
                 ),
                 filled: true,
                 fillColor: Colors.white,
                 contentPadding: const EdgeInsets.symmetric(
                   horizontal: 16,
                   vertical: 12,
                 ),
               ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          
          // Filter Chips
          if (_selectedFilter != 'All' || _priceRange.start > 0 || _priceRange.end < 1000)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          if (_selectedFilter != 'All')
                            _buildFilterChip(_selectedFilter, () {
                              setState(() {
                                _selectedFilter = 'All';
                              });
                            }),
                          if (_priceRange.start > 0 || _priceRange.end < 1000)
                            _buildFilterChip(
                              '₹${_priceRange.start.round()} - ₹${_priceRange.end.round()}',
                              () {
                                setState(() {
                                  _priceRange = const RangeValues(0, 1000);
                                });
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedFilter = 'All';
                        _priceRange = const RangeValues(0, 1000);
                      });
                    },
                    child: const Text('Clear All'),
                  ),
                ],
              ),
            ),
          
          // Products Grid
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
                      productProvider.loadAllAvailableProducts();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (productProvider.allAvailableProducts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.shopping_bag_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No products available',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Check back later for fresh products',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final filteredProducts = _getFilteredProducts(productProvider.allAvailableProducts);
          
          if (filteredProducts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.search_off,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No products found',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Try adjusting your search or filters',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: filteredProducts.length,
            itemBuilder: (context, index) {
              final product = filteredProducts[index];
              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ProductDetailScreen(product: product),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                                             // Product Image
                       Expanded(
                         flex: 3,
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12),
                            ),
                            color: Colors.grey.shade100,
                          ),
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12),
                            ),
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
                                          size: 48,
                                        ),
                                      );
                                    },
                                  )
                                : Container(
                                    color: Colors.grey.shade200,
                                    child: const Icon(
                                      Icons.image_not_supported,
                                      color: Colors.grey,
                                      size: 48,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      
                                             // Product Details
                       Expanded(
                         flex: 2,
                                                    child: Padding(
                             padding: const EdgeInsets.all(8),
                           child: Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                               Text(
                                 product.productName,
                                 style: const TextStyle(
                                   fontSize: 14,
                                   fontWeight: FontWeight.bold,
                                 ),
                                 maxLines: 1,
                                 overflow: TextOverflow.ellipsis,
                               ),
                               const SizedBox(height: 4),
                               Row(
                                 children: [
                                   Text(
                                     '${product.quantity.toStringAsFixed(1)} kg',
                                     style: TextStyle(
                                       fontSize: 12,
                                       color: Colors.grey[600],
                                     ),
                                   ),
                                   const Spacer(),
                                   Text(
                                     '₹${product.pricePerKg.toStringAsFixed(2)}/kg',
                                     style: const TextStyle(
                                       fontSize: 13,
                                       fontWeight: FontWeight.w600,
                                       color: Colors.orange,
                                     ),
                                   ),
                                 ],
                               ),
                               const Spacer(),
                               // View Button
                               SizedBox(
                                 width: double.infinity,
                                 height: 32,
                                 child: ElevatedButton(
                                   onPressed: () {
                                     Navigator.of(context).push(
                                       MaterialPageRoute(
                                         builder: (context) => ProductDetailScreen(product: product),
                                       ),
                                     );
                                   },
                                   style: ElevatedButton.styleFrom(
                                     backgroundColor: Colors.orange,
                                     foregroundColor: Colors.white,
                                     padding: const EdgeInsets.symmetric(vertical: 8),
                                     shape: RoundedRectangleBorder(
                                       borderRadius: BorderRadius.circular(8),
                                     ),
                                   ),
                                   child: const Text(
                                     'View',
                                     style: TextStyle(
                                       fontSize: 12,
                                       fontWeight: FontWeight.bold,
                                     ),
                                   ),
                                 ),
                               ),
                             ],
                           ),
                         ),
                       ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
            ),
        ],
      ),
    );
  }

  List<ProductModel> _getFilteredProducts(List<ProductModel> products) {
    List<ProductModel> filtered = products.where((product) {
      // Search filter
      final matchesSearch = _searchQuery.isEmpty ||
          product.productName.toLowerCase().contains(_searchQuery.toLowerCase());
      
      // Price range filter
      final matchesPrice = product.pricePerKg >= _priceRange.start &&
          product.pricePerKg <= _priceRange.end;
      
      return matchesSearch && matchesPrice;
    }).toList();

    // Sort filter
    switch (_selectedFilter) {
      case 'Price: Low to High':
        filtered.sort((a, b) => a.pricePerKg.compareTo(b.pricePerKg));
        break;
      case 'Price: High to Low':
        filtered.sort((a, b) => b.pricePerKg.compareTo(a.pricePerKg));
        break;
      case 'Quantity: High to Low':
        filtered.sort((a, b) => b.quantity.compareTo(a.quantity));
        break;
      case 'Quantity: Low to High':
        filtered.sort((a, b) => a.quantity.compareTo(b.quantity));
        break;
      default:
        // No sorting for 'All'
        break;
    }

    return filtered;
  }

  Widget _buildFilterChip(String label, VoidCallback onRemove) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(label),
        deleteIcon: const Icon(Icons.close, size: 16),
        onDeleted: onRemove,
        backgroundColor: Colors.orange.withOpacity(0.1),
        side: BorderSide(color: Colors.orange.withOpacity(0.3)),
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Filter Products'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Sort Options
                  const Text(
                    'Sort By',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedFilter,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: _filterOptions.map((String option) {
                      return DropdownMenuItem<String>(
                        value: option,
                        child: Text(option),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedFilter = newValue!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Price Range
                  const Text(
                    'Price Range (₹/kg)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  RangeSlider(
                    values: _priceRange,
                    min: 0,
                    max: 1000,
                    divisions: 100,
                    labels: RangeLabels(
                      '₹${_priceRange.start.round()}',
                      '₹${_priceRange.end.round()}',
                    ),
                    onChanged: (RangeValues values) {
                      setState(() {
                        _priceRange = values;
                      });
                    },
                  ),
                  Text(
                    '₹${_priceRange.start.round()} - ₹${_priceRange.end.round()}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    this.setState(() {});
                    Navigator.of(context).pop();
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }
} 
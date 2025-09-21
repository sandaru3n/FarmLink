import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../models/product_model.dart';
import 'product_detail_screen.dart';

class SavedProductsScreen extends StatefulWidget {
  const SavedProductsScreen({super.key});

  @override
  State<SavedProductsScreen> createState() => _SavedProductsScreenState();
}

class _SavedProductsScreenState extends State<SavedProductsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final favoritesProvider = Provider.of<FavoritesProvider>(context, listen: false);
      
      if (authProvider.userProfile != null) {
        favoritesProvider.loadUserFavorites(authProvider.userProfile!.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Products'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Consumer<FavoritesProvider>(
        builder: (context, favoritesProvider, child) {
          if (favoritesProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (favoritesProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading saved products',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    favoritesProvider.error!,
                    style: TextStyle(
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      final authProvider = Provider.of<AuthProvider>(context, listen: false);
                      if (authProvider.userProfile != null) {
                        favoritesProvider.loadUserFavorites(authProvider.userProfile!.uid);
                      }
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (favoritesProvider.favoriteProducts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No saved products',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Products you save will appear here',
                    style: TextStyle(
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: favoritesProvider.favoriteProducts.length,
            itemBuilder: (context, index) {
              final product = favoritesProvider.favoriteProducts[index];
              return _buildProductCard(product);
            },
          );
        },
      ),
    );
  }

  Widget _buildProductCard(ProductModel product) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(product: product),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Product Image
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: product.imageUrl.isNotEmpty
                      ? Image.network(
                          product.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => 
                              const Icon(Icons.image, color: Colors.grey),
                        )
                      : const Icon(Icons.image, color: Colors.grey),
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
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Available: ${product.quantity.toStringAsFixed(1)} kg',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '₹${product.pricePerKg.toStringAsFixed(2)}/kg',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.green,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${product.quantity.toStringAsFixed(1)} kg',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Remove from favorites button
              IconButton(
                icon: const Icon(
                  Icons.favorite,
                  color: Colors.red,
                ),
                onPressed: () async {
                  final authProvider = Provider.of<AuthProvider>(context, listen: false);
                  final favoritesProvider = Provider.of<FavoritesProvider>(context, listen: false);
                  
                  if (authProvider.userProfile != null) {
                    final success = await favoritesProvider.removeFromFavorites(
                      authProvider.userProfile!.uid,
                      product.id,
                    );
                    
                    if (success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Removed from saved products'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                tooltip: 'Remove from saved',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

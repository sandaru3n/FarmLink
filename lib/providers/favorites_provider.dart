import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/favorites_service.dart';

class FavoritesProvider extends ChangeNotifier {
  final FavoritesService _favoritesService = FavoritesService();
  
  List<ProductModel> _favoriteProducts = [];
  bool _isLoading = false;
  String? _error;

  List<ProductModel> get favoriteProducts => _favoriteProducts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Check if a product is favorited
  bool isFavorite(String productId) {
    return _favoriteProducts.any((product) => product.id == productId);
  }

  // Load user's favorite products
  void loadUserFavorites(String userId) {
    _isLoading = true;
    _error = null;
    notifyListeners();

    _favoritesService.getUserFavorites(userId).listen(
      (products) {
        _favoriteProducts = products;
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (error) {
        _isLoading = false;
        _error = error.toString();
        notifyListeners();
      },
    );
  }

  // Add product to favorites
  Future<bool> addToFavorites(String userId, ProductModel product) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _favoritesService.addToFavorites(userId, product);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Remove product from favorites
  Future<bool> removeFromFavorites(String userId, String productId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _favoritesService.removeFromFavorites(userId, productId);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Toggle favorite status
  Future<bool> toggleFavorite(String userId, ProductModel product) async {
    if (isFavorite(product.id)) {
      return await removeFromFavorites(userId, product.id);
    } else {
      return await addToFavorites(userId, product);
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}

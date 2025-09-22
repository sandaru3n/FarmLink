import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/product_service.dart';

class ProductProvider extends ChangeNotifier {
  final ProductService _productService = ProductService();
  
  List<ProductModel> _distributorProducts = [];
  List<ProductModel> _allAvailableProducts = [];
  bool _isLoading = false;
  String? _error;

  List<ProductModel> get distributorProducts => _distributorProducts;
  List<ProductModel> get allAvailableProducts => _allAvailableProducts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load distributor products
  void loadDistributorProducts(String distributorId) {
    _isLoading = true;
    _error = null;
    notifyListeners();

    _productService.getDistributorProducts(distributorId).listen(
      (products) {
        _distributorProducts = products;
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

  // Load all available products (for consumers)
  void loadAllAvailableProducts() {
    _isLoading = true;
    _error = null;
    notifyListeners();

    _productService.getAllAvailableProducts().listen(
      (products) {
        _allAvailableProducts = products;
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

  // Add a new product
  Future<bool> addProduct(ProductModel product) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _productService.addProduct(product);
      
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

  // Update a product
  Future<bool> updateProduct(ProductModel product) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _productService.updateProduct(product);
      
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

  // Delete a product
  Future<bool> deleteProduct(String productId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _productService.deleteProduct(productId);
      
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

  // Upload product image
  Future<String?> uploadProductImage(String filePath) async {
    try {
      return await _productService.uploadProductImage(filePath);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  // Adjust stock quantity
  Future<bool> adjustStock(String productId, double deltaKg) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _productService.adjustStock(productId, deltaKg);

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

  // Set product availability
  Future<bool> setAvailability(String productId, bool isAvailable) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _productService.setAvailability(productId, isAvailable);

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

  // Set reorder level
  Future<bool> setReorderLevel(String productId, double reorderLevel) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _productService.setReorderLevel(productId, reorderLevel);

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

  // Set baseline to current quantity
  Future<bool> setBaselineToCurrent(String productId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _productService.setBaselineToCurrent(productId);

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

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
} 
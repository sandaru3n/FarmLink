import 'package:flutter/material.dart';
import '../models/cart_item_model.dart';
import '../services/cart_service.dart';

class CartProvider extends ChangeNotifier {
  final CartService _cartService = CartService();
  
  List<CartItemModel> _cartItems = [];
  int _itemCount = 0;
  bool _isLoading = false;
  String? _error;

  List<CartItemModel> get cartItems => _cartItems;
  int get itemCount => _itemCount;
  bool get isLoading => _isLoading;
  String? get error => _error;

  double get totalAmount {
    return _cartItems.fold(0, (sum, item) => sum + item.totalPrice);
  }

  // Load user's cart
  void loadUserCart(String userId) {
    _isLoading = true;
    _error = null;
    notifyListeners();

    _cartService.getUserCart(userId).listen(
      (cartItems) {
        _cartItems = cartItems;
        _itemCount = cartItems.length;
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

  // Add item to cart
  Future<bool> addToCart(CartItemModel cartItem, String userId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _cartService.addToCart(cartItem, userId);
      
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

  // Update cart item quantity
  Future<bool> updateCartItemQuantity(String userId, String itemId, double quantity) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _cartService.updateCartItemQuantity(userId, itemId, quantity);
      
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

  // Remove item from cart
  Future<bool> removeFromCart(String userId, String itemId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _cartService.removeFromCart(userId, itemId);
      
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

  // Clear cart
  Future<bool> clearCart(String userId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _cartService.clearCart(userId);
      
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
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cart_item_model.dart';

class CartService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add item to cart
  Future<String> addToCart(CartItemModel cartItem, String userId) async {
    try {
      // Check if item already exists in cart
      final existingQuery = await _firestore
          .collection('carts')
          .doc(userId)
          .collection('items')
          .where('productId', isEqualTo: cartItem.productId)
          .get();

      if (existingQuery.docs.isNotEmpty) {
        // Update existing item
        final existingDoc = existingQuery.docs.first;
        final existingItem = CartItemModel.fromFirestore(existingDoc);
        final newQuantity = existingItem.quantity + cartItem.quantity;
        
        await _firestore
            .collection('carts')
            .doc(userId)
            .collection('items')
            .doc(existingDoc.id)
            .update({
          'quantity': newQuantity,
          'addedAt': Timestamp.fromDate(DateTime.now()),
        });
        
        return existingDoc.id;
      } else {
        // Add new item
        DocumentReference docRef = await _firestore
            .collection('carts')
            .doc(userId)
            .collection('items')
            .add(cartItem.toFirestore());
        return docRef.id;
      }
    } catch (e) {
      throw Exception('Failed to add to cart: $e');
    }
  }

  // Get user's cart items
  Stream<List<CartItemModel>> getUserCart(String userId) {
    return _firestore
        .collection('carts')
        .doc(userId)
        .collection('items')
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => CartItemModel.fromFirestore(doc)).toList();
    });
  }

  // Update cart item quantity
  Future<void> updateCartItemQuantity(String userId, String itemId, double quantity) async {
    try {
      await _firestore
          .collection('carts')
          .doc(userId)
          .collection('items')
          .doc(itemId)
          .update({
        'quantity': quantity,
      });
    } catch (e) {
      throw Exception('Failed to update cart item: $e');
    }
  }

  // Remove item from cart
  Future<void> removeFromCart(String userId, String itemId) async {
    try {
      await _firestore
          .collection('carts')
          .doc(userId)
          .collection('items')
          .doc(itemId)
          .delete();
    } catch (e) {
      throw Exception('Failed to remove from cart: $e');
    }
  }

  // Clear entire cart
  Future<void> clearCart(String userId) async {
    try {
      final cartItems = await _firestore
          .collection('carts')
          .doc(userId)
          .collection('items')
          .get();
      
      for (var doc in cartItems.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      throw Exception('Failed to clear cart: $e');
    }
  }

  // Get cart item count
  Stream<int> getCartItemCount(String userId) {
    return _firestore
        .collection('carts')
        .doc(userId)
        .collection('items')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
} 
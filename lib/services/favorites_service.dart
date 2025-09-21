import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';

class FavoritesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get _favoritesCollection => _firestore.collection('user_favorites');

  // Get user's favorite products
  Stream<List<ProductModel>> getUserFavorites(String userId) {
    return _favoritesCollection
        .doc(userId)
        .collection('products')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ProductModel.fromFirestore(doc)).toList();
    });
  }

  // Add product to favorites
  Future<void> addToFavorites(String userId, ProductModel product) async {
    try {
      await _favoritesCollection
          .doc(userId)
          .collection('products')
          .doc(product.id)
          .set(product.toFirestore());
    } catch (e) {
      throw Exception('Failed to add to favorites: $e');
    }
  }

  // Remove product from favorites
  Future<void> removeFromFavorites(String userId, String productId) async {
    try {
      await _favoritesCollection
          .doc(userId)
          .collection('products')
          .doc(productId)
          .delete();
    } catch (e) {
      throw Exception('Failed to remove from favorites: $e');
    }
  }

  // Check if product is favorited
  Future<bool> isFavorited(String userId, String productId) async {
    try {
      final doc = await _favoritesCollection
          .doc(userId)
          .collection('products')
          .doc(productId)
          .get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  // Get favorite count for user
  Future<int> getFavoriteCount(String userId) async {
    try {
      final snapshot = await _favoritesCollection
          .doc(userId)
          .collection('products')
          .get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import '../models/product_model.dart';
import 'storage_service.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StorageService _storageService = StorageService();

  // Add a new product
  Future<String> addProduct(ProductModel product) async {
    try {
      DocumentReference docRef = await _firestore.collection('products').add(product.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add product: $e');
    }
  }

  // Get all products for a specific distributor
  Stream<List<ProductModel>> getDistributorProducts(String distributorId) {
    return _firestore
        .collection('products')
        .where('distributorId', isEqualTo: distributorId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ProductModel.fromFirestore(doc)).toList();
    });
  }

  // Get all available products (for consumers to browse)
  Stream<List<ProductModel>> getAllAvailableProducts() {
    return _firestore
        .collection('products')
        .where('isAvailable', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ProductModel.fromFirestore(doc)).toList();
    });
  }

  // Update a product
  Future<void> updateProduct(ProductModel product) async {
    try {
      await _firestore
          .collection('products')
          .doc(product.id)
          .update(product.toFirestore());
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }

  // Delete a product
  Future<void> deleteProduct(String productId) async {
    try {
      // Get the product to delete its image
      DocumentSnapshot doc = await _firestore.collection('products').doc(productId).get();
      if (doc.exists) {
        ProductModel product = ProductModel.fromFirestore(doc);
        
        // Delete the image from storage if it exists
        if (product.imageUrl.isNotEmpty) {
          try {
            await _storageService.deleteCropImage(product.imageUrl);
          } catch (e) {
            // Continue even if image deletion fails
            print('Failed to delete image: $e');
          }
        }
      }
      
      // Delete the product document
      await _firestore.collection('products').doc(productId).delete();
    } catch (e) {
      throw Exception('Failed to delete product: $e');
    }
  }

  // Upload product image
  Future<String> uploadProductImage(String filePath) async {
    try {
      File imageFile = File(filePath);
      return await _storageService.uploadCropImage(imageFile);
    } catch (e) {
      throw Exception('Failed to upload product image: $e');
    }
  }

  // Get a single product by ID
  Future<ProductModel?> getProductById(String productId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('products').doc(productId).get();
      if (doc.exists) {
        return ProductModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get product: $e');
    }
  }
} 
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _contentTypeForExtension(String ext) {
    final e = ext.toLowerCase();
    if (e == 'jpg' || e == 'jpeg') return 'image/jpeg';
    if (e == 'png') return 'image/png';
    if (e == 'webp') return 'image/webp';
    if (e == 'gif') return 'image/gif';
    return 'application/octet-stream';
  }

  // Upload crop image to Firebase Storage
  Future<String> uploadCropImage(File imageFile) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated. Please log in to upload images.');
      }

      // Validate file exists
      if (!await imageFile.exists()) {
        throw Exception('Image file does not exist');
      }

      // Validate file size (max 10MB)
      final fileSize = await imageFile.length();
      if (fileSize > 10 * 1024 * 1024) {
        throw Exception('Image file is too large. Maximum size is 10MB');
      }

      // Create a unique filename with proper extension
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final originalName = imageFile.path.split('/').last;
      final extension = originalName.contains('.') 
          ? originalName.split('.').last 
          : 'jpg';
      final fileName = 'crops/$userId/${timestamp}.$extension';
      // Debug: print full storage path
      // ignore: avoid_print
      print('[StorageService] bucket: \'${Firebase.app().options.storageBucket}\' uid: $userId');
      // ignore: avoid_print
      print('[StorageService] Uploading crop image to: $fileName');
      
      // Create reference to the file location
      final storageRef = _storage.ref().child(fileName);
      final metadata = SettableMetadata(contentType: _contentTypeForExtension(extension));
      
      // Upload the file
      final uploadTask = storageRef.putFile(imageFile, metadata);
      
      // Wait for upload to complete
      final snapshot = await uploadTask;
      
      // Get the download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      if (e.toString().contains('permission-denied')) {
        throw Exception('Permission denied. Please check your internet connection and try again.');
      } else if (e.toString().contains('unauthenticated')) {
        throw Exception('Please log in again to upload images.');
      } else {
        throw Exception('Failed to upload image: $e');
      }
    }
  }

  // Upload profile image to Firebase Storage
  Future<String> uploadProfileImage(File imageFile) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated. Please log in to upload images.');
      }

      if (!await imageFile.exists()) {
        throw Exception('Image file does not exist');
      }

      final fileSize = await imageFile.length();
      if (fileSize > 10 * 1024 * 1024) {
        throw Exception('Image file is too large. Maximum size is 10MB');
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final originalName = imageFile.path.split('/').last;
      final extension = originalName.contains('.') 
          ? originalName.split('.').last 
          : 'jpg';
      final fileName = 'profiles/$userId/${timestamp}.$extension';
      // Debug: print full storage path
      // ignore: avoid_print
      print('[StorageService] bucket: \'${Firebase.app().options.storageBucket}\' uid: $userId');
      // ignore: avoid_print
      print('[StorageService] Uploading profile image to: $fileName');

      final storageRef = _storage.ref().child(fileName);
      final metadata = SettableMetadata(contentType: _contentTypeForExtension(extension));
      final uploadTask = storageRef.putFile(imageFile, metadata);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      if (e.toString().contains('permission-denied')) {
        throw Exception('Permission denied. Please check your internet connection and try again.');
      } else if (e.toString().contains('unauthenticated')) {
        throw Exception('Please log in again to upload images.');
      } else {
        throw Exception('Failed to upload profile image: $e');
      }
    }
  }

  // Delete crop image from Firebase Storage
  Future<void> deleteCropImage(String imageUrl) async {
    try {
      if (imageUrl.isEmpty || imageUrl.contains('placeholder')) {
        return; // Don't delete placeholder images
      }
      
      // Extract the file path from the URL
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      // Log error but don't throw - image deletion is not critical
      print('Failed to delete image: $e');
    }
  }

  // Get current user ID
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }
}

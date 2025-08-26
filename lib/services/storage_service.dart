import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Upload crop image to Firebase Storage
  Future<String> uploadCropImage(File imageFile) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
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
      
      // Create reference to the file location
      final storageRef = _storage.ref().child(fileName);
      
      // Upload the file
      final uploadTask = storageRef.putFile(imageFile);
      
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

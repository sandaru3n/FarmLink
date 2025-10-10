import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/rating_model.dart';

class RatingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get _ratingsCollection => _firestore.collection('ratings');

  // Create a new rating
  Future<void> createRating({
    required String deliveryOrderId,
    required String transporterId,
    required String distributorId,
    required String transporterName,
    required String distributorName,
    required double rating,
    String? comment,
    String? feedback,
    List<String>? categories,
  }) async {
    try {
      final ratingId = 'rating_${deliveryOrderId}_${DateTime.now().millisecondsSinceEpoch}';
      
      final ratingModel = RatingModel(
        id: ratingId,
        deliveryOrderId: deliveryOrderId,
        transporterId: transporterId,
        distributorId: distributorId,
        transporterName: transporterName,
        distributorName: distributorName,
        rating: rating,
        comment: comment,
        feedback: feedback,
        categories: categories,
        createdAt: DateTime.now(),
      );

      await _ratingsCollection.doc(ratingId).set(ratingModel.toMap());
      
      // Update transporter's average rating
      await _updateTransporterRating(transporterId);
      
      print('Rating created successfully: $ratingId');
    } catch (e) {
      print('Error creating rating: $e');
      throw Exception('Failed to create rating: $e');
    }
  }

  // Update an existing rating
  Future<void> updateRating({
    required String ratingId,
    double? rating,
    String? comment,
    String? feedback,
    List<String>? categories,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      if (rating != null) updateData['rating'] = rating;
      if (comment != null) updateData['comment'] = comment;
      if (feedback != null) updateData['feedback'] = feedback;
      if (categories != null) updateData['categories'] = categories;

      await _ratingsCollection.doc(ratingId).update(updateData);
      
      // Get transporter ID to update their average rating
      final ratingDoc = await _ratingsCollection.doc(ratingId).get();
      if (ratingDoc.exists) {
        final data = ratingDoc.data() as Map<String, dynamic>;
        await _updateTransporterRating(data['transporterId']);
      }
      
      print('Rating updated successfully: $ratingId');
    } catch (e) {
      print('Error updating rating: $e');
      throw Exception('Failed to update rating: $e');
    }
  }

  // Get rating by delivery order ID
  Future<RatingModel?> getRatingByDeliveryOrder(String deliveryOrderId) async {
    try {
      final querySnapshot = await _ratingsCollection
          .where('deliveryOrderId', isEqualTo: deliveryOrderId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        return RatingModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error getting rating: $e');
      throw Exception('Failed to get rating: $e');
    }
  }

  // Get all ratings for a transporter
  Stream<List<RatingModel>> getTransporterRatings(String transporterId) {
    return _ratingsCollection
        .where('transporterId', isEqualTo: transporterId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => 
        RatingModel.fromMap(doc.data() as Map<String, dynamic>)
      ).toList();
    });
  }

  // Get all ratings given by a distributor
  Stream<List<RatingModel>> getDistributorRatings(String distributorId) {
    return _ratingsCollection
        .where('distributorId', isEqualTo: distributorId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => 
        RatingModel.fromMap(doc.data() as Map<String, dynamic>)
      ).toList();
    });
  }

  // Get transporter's average rating
  Future<double> getTransporterAverageRating(String transporterId) async {
    try {
      final querySnapshot = await _ratingsCollection
          .where('transporterId', isEqualTo: transporterId)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return 0.0;
      }

      double totalRating = 0.0;
      int ratingCount = 0;

      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        totalRating += (data['rating'] ?? 0).toDouble();
        ratingCount++;
      }

      return ratingCount > 0 ? totalRating / ratingCount : 0.0;
    } catch (e) {
      print('Error getting average rating: $e');
      return 0.0;
    }
  }

  // Get transporter rating statistics
  Future<Map<String, dynamic>> getTransporterRatingStats(String transporterId) async {
    try {
      final querySnapshot = await _ratingsCollection
          .where('transporterId', isEqualTo: transporterId)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return {
          'averageRating': 0.0,
          'totalRatings': 0,
          'ratingDistribution': {'1': 0, '2': 0, '3': 0, '4': 0, '5': 0},
        };
      }

      double totalRating = 0.0;
      int ratingCount = 0;
      Map<String, int> ratingDistribution = {'1': 0, '2': 0, '3': 0, '4': 0, '5': 0};

      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final rating = (data['rating'] ?? 0).toDouble();
        totalRating += rating;
        ratingCount++;

        // Update rating distribution
        int ratingKey = rating.round();
        if (ratingKey >= 1 && ratingKey <= 5) {
          ratingDistribution[ratingKey.toString()] = 
              (ratingDistribution[ratingKey.toString()] ?? 0) + 1;
        }
      }

      return {
        'averageRating': ratingCount > 0 ? totalRating / ratingCount : 0.0,
        'totalRatings': ratingCount,
        'ratingDistribution': ratingDistribution,
      };
    } catch (e) {
      print('Error getting rating stats: $e');
      return {
        'averageRating': 0.0,
        'totalRatings': 0,
        'ratingDistribution': {'1': 0, '2': 0, '3': 0, '4': 0, '5': 0},
      };
    }
  }

  // Update transporter's average rating in their profile
  Future<void> _updateTransporterRating(String transporterId) async {
    try {
      final stats = await getTransporterRatingStats(transporterId);
      
      // Update transporter profile with new rating stats
      await _firestore.collection('transporter_profiles').doc(transporterId).update({
        'rating': stats['averageRating'],
        'totalDeliveries': stats['totalRatings'],
        'lastRatingUpdate': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('Error updating transporter rating: $e');
      // Don't throw error as this is not critical
    }
  }

  // Check if a delivery order has been rated
  Future<bool> hasBeenRated(String deliveryOrderId) async {
    try {
      final rating = await getRatingByDeliveryOrder(deliveryOrderId);
      return rating != null;
    } catch (e) {
      print('Error checking if rated: $e');
      return false;
    }
  }

  // Get recent ratings for a transporter (last 10)
  Stream<List<RatingModel>> getRecentTransporterRatings(String transporterId) {
    return _ratingsCollection
        .where('transporterId', isEqualTo: transporterId)
        .orderBy('createdAt', descending: true)
        .limit(10)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => 
        RatingModel.fromMap(doc.data() as Map<String, dynamic>)
      ).toList();
    }).handleError((error) {
      print('Error in getRecentTransporterRatings: $error');
      // Return empty list if there's an error (e.g., index not ready)
      return <RatingModel>[];
    });
  }

  // Fallback method that doesn't require composite index
  Future<List<RatingModel>> getRecentTransporterRatingsFallback(String transporterId) async {
    try {
      final querySnapshot = await _ratingsCollection
          .where('transporterId', isEqualTo: transporterId)
          .get();

      final ratings = querySnapshot.docs.map((doc) => 
        RatingModel.fromMap(doc.data() as Map<String, dynamic>)
      ).toList();

      // Sort manually by createdAt descending and limit to 10
      ratings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return ratings.take(10).toList();
    } catch (e) {
      print('Error in fallback method: $e');
      return [];
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/consumer_rating_model.dart';

class ConsumerRatingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get _consumerRatingsCollection => _firestore.collection('consumer_ratings');

  // Create a new consumer rating
  Future<void> createConsumerRating({
    required String consumerOrderId,
    required String consumerId,
    required String distributorId,
    required String consumerName,
    required String distributorName,
    required double rating,
    String? comment,
    String? feedback,
    List<String>? categories,
  }) async {
    try {
      final ratingId = 'consumer_rating_${consumerOrderId}_${DateTime.now().millisecondsSinceEpoch}';
      
      final ratingModel = ConsumerRatingModel(
        id: ratingId,
        consumerOrderId: consumerOrderId,
        consumerId: consumerId,
        distributorId: distributorId,
        consumerName: consumerName,
        distributorName: distributorName,
        rating: rating,
        comment: comment,
        feedback: feedback,
        categories: categories,
        createdAt: DateTime.now(),
      );

      await _consumerRatingsCollection.doc(ratingId).set(ratingModel.toMap());
      
      // Update distributor's average rating
      await _updateDistributorRating(distributorId);
      
      print('Consumer rating created successfully: $ratingId');
    } catch (e) {
      print('Error creating consumer rating: $e');
      throw Exception('Failed to create consumer rating: $e');
    }
  }

  // Update an existing consumer rating
  Future<void> updateConsumerRating({
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

      await _consumerRatingsCollection.doc(ratingId).update(updateData);
      
      // Get distributor ID to update their average rating
      final ratingDoc = await _consumerRatingsCollection.doc(ratingId).get();
      if (ratingDoc.exists) {
        final data = ratingDoc.data() as Map<String, dynamic>;
        await _updateDistributorRating(data['distributorId']);
      }
      
      print('Consumer rating updated successfully: $ratingId');
    } catch (e) {
      print('Error updating consumer rating: $e');
      throw Exception('Failed to update consumer rating: $e');
    }
  }

  // Get rating by consumer order ID
  Future<ConsumerRatingModel?> getRatingByConsumerOrder(String consumerOrderId) async {
    try {
      final querySnapshot = await _consumerRatingsCollection
          .where('consumerOrderId', isEqualTo: consumerOrderId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        return ConsumerRatingModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error getting consumer rating: $e');
      throw Exception('Failed to get consumer rating: $e');
    }
  }

  // Get all ratings for a distributor
  Stream<List<ConsumerRatingModel>> getDistributorRatings(String distributorId) {
    return _consumerRatingsCollection
        .where('distributorId', isEqualTo: distributorId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => 
        ConsumerRatingModel.fromMap(doc.data() as Map<String, dynamic>)
      ).toList();
    });
  }

  // Get all ratings given by a consumer
  Stream<List<ConsumerRatingModel>> getConsumerRatings(String consumerId) {
    return _consumerRatingsCollection
        .where('consumerId', isEqualTo: consumerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => 
        ConsumerRatingModel.fromMap(doc.data() as Map<String, dynamic>)
      ).toList();
    });
  }

  // Get distributor's average rating
  Future<double> getDistributorAverageRating(String distributorId) async {
    try {
      final querySnapshot = await _consumerRatingsCollection
          .where('distributorId', isEqualTo: distributorId)
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
      print('Error getting distributor average rating: $e');
      return 0.0;
    }
  }

  // Get distributor rating statistics
  Future<Map<String, dynamic>> getDistributorRatingStats(String distributorId) async {
    try {
      final querySnapshot = await _consumerRatingsCollection
          .where('distributorId', isEqualTo: distributorId)
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
      print('Error getting distributor rating stats: $e');
      return {
        'averageRating': 0.0,
        'totalRatings': 0,
        'ratingDistribution': {'1': 0, '2': 0, '3': 0, '4': 0, '5': 0},
      };
    }
  }

  // Update distributor's average rating in their profile
  Future<void> _updateDistributorRating(String distributorId) async {
    try {
      final stats = await getDistributorRatingStats(distributorId);
      
      // Update distributor profile with new rating stats
      await _firestore.collection('users').doc(distributorId).update({
        'averageRating': stats['averageRating'],
        'totalRatings': stats['totalRatings'],
        'lastRatingUpdate': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('Error updating distributor rating: $e');
      // Don't throw error as this is not critical
    }
  }

  // Check if a consumer order has been rated
  Future<bool> hasBeenRated(String consumerOrderId) async {
    try {
      final rating = await getRatingByConsumerOrder(consumerOrderId);
      return rating != null;
    } catch (e) {
      print('Error checking if consumer order rated: $e');
      return false;
    }
  }

  // Get recent ratings for a distributor (last 10)
  Stream<List<ConsumerRatingModel>> getRecentDistributorRatings(String distributorId) {
    return _consumerRatingsCollection
        .where('distributorId', isEqualTo: distributorId)
        .orderBy('createdAt', descending: true)
        .limit(10)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => 
        ConsumerRatingModel.fromMap(doc.data() as Map<String, dynamic>)
      ).toList();
    });
  }
}

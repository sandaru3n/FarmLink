import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get user details by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user details: $e');
    }
  }

  // Get user details stream by ID
  Stream<UserModel?> getUserByIdStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    });
  }

  // Get transporter details with additional contact information
  Future<Map<String, dynamic>?> getTransporterDetails(String transporterId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(transporterId).get();
      if (!userDoc.exists) {
        return null;
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      
      // Get additional transporter profile information if available
      final transporterProfileDoc = await _firestore
          .collection('transporter_profiles')
          .doc(transporterId)
          .get();

      Map<String, dynamic> transporterDetails = {
        'uid': transporterId,
        'email': userData['email'] ?? '',
        'displayName': userData['displayName'] ?? '',
        'primaryRole': userData['primaryRole'] ?? '',
        'currentActiveRole': userData['currentActiveRole'] ?? '',
        'createdAt': userData['createdAt'],
        'lastLoginAt': userData['lastLoginAt'],
        'isActive': userData['isActive'] ?? true,
      };

      // Add transporter-specific details if profile exists
      if (transporterProfileDoc.exists) {
        final profileData = transporterProfileDoc.data() as Map<String, dynamic>;
        transporterDetails.addAll({
          'phoneNumber': profileData['phoneNumber'] ?? '',
          'vehicleType': profileData['vehicleType'] ?? '',
          'licenseNumber': profileData['licenseNumber'] ?? '',
          'experience': profileData['experience'] ?? '',
          'rating': profileData['rating'] ?? 0.0,
          'totalDeliveries': profileData['totalDeliveries'] ?? 0,
          'address': profileData['address'] ?? '',
          'availability': profileData['availability'] ?? 'available',
          'specializations': profileData['specializations'] ?? [],
        });
      }

      return transporterDetails;
    } catch (e) {
      throw Exception('Failed to get transporter details: $e');
    }
  }

  // Get transporter details stream
  Stream<Map<String, dynamic>?> getTransporterDetailsStream(String transporterId) {
    return _firestore
        .collection('users')
        .doc(transporterId)
        .snapshots()
        .asyncMap((userDoc) async {
      if (!userDoc.exists) {
        return null;
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      
      // Get additional transporter profile information if available
      final transporterProfileDoc = await _firestore
          .collection('transporter_profiles')
          .doc(transporterId)
          .get();

      Map<String, dynamic> transporterDetails = {
        'uid': transporterId,
        'email': userData['email'] ?? '',
        'displayName': userData['displayName'] ?? '',
        'primaryRole': userData['primaryRole'] ?? '',
        'currentActiveRole': userData['currentActiveRole'] ?? '',
        'createdAt': userData['createdAt'],
        'lastLoginAt': userData['lastLoginAt'],
        'isActive': userData['isActive'] ?? true,
      };

      // Add transporter-specific details if profile exists
      if (transporterProfileDoc.exists) {
        final profileData = transporterProfileDoc.data() as Map<String, dynamic>;
        transporterDetails.addAll({
          'phoneNumber': profileData['phoneNumber'] ?? '',
          'vehicleType': profileData['vehicleType'] ?? '',
          'licenseNumber': profileData['licenseNumber'] ?? '',
          'experience': profileData['experience'] ?? '',
          'rating': profileData['rating'] ?? 0.0,
          'totalDeliveries': profileData['totalDeliveries'] ?? 0,
          'address': profileData['address'] ?? '',
          'availability': profileData['availability'] ?? 'available',
          'specializations': profileData['specializations'] ?? [],
        });
      }

      return transporterDetails;
    });
  }

  // Get delivery orders for a specific distributor
  Stream<List<Map<String, dynamic>>> getDistributorDeliveryOrders(String distributorId) {
    return _firestore
        .collection('delivery_orders')
        .where('distributorId', isEqualTo: distributorId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    });
  }
}

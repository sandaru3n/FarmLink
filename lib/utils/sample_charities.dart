import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/charity_model.dart';

class SampleCharities {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  static Future<void> addSampleCharities() async {
    final charities = [
      CharityModel(
        id: 'charity_1',
        name: 'Food Bank of Hope',
        description: 'Dedicated to fighting hunger in our community by providing nutritious food to families in need.',
        imageUrl: 'https://images.unsplash.com/photo-1559027615-cd4628902d4a?w=400',
        address: '123 Main Street, City Center',
        phone: '+1 (555) 123-4567',
        email: 'info@foodbankofhope.org',
        website: 'https://foodbankofhope.org',
        registrationNumber: 'FBH-2024-001',
        categories: ['food', 'community'],
        isActive: true,
        rating: 4.8,
        totalDonations: 156,
        createdAt: DateTime.now().subtract(const Duration(days: 365)),
      ),
      CharityModel(
        id: 'charity_2',
        name: 'Green Earth Foundation',
        description: 'Promoting sustainable agriculture and environmental conservation through community gardens and education.',
        imageUrl: 'https://images.unsplash.com/photo-1416879595882-3373a0480b5b?w=400',
        address: '456 Green Valley Road, Eco District',
        phone: '+1 (555) 234-5678',
        email: 'contact@greenearth.org',
        website: 'https://greenearth.org',
        registrationNumber: 'GEF-2024-002',
        categories: ['environment', 'education', 'food'],
        isActive: true,
        rating: 4.6,
        totalDonations: 89,
        createdAt: DateTime.now().subtract(const Duration(days: 200)),
      ),
      CharityModel(
        id: 'charity_3',
        name: 'Community Care Center',
        description: 'Supporting vulnerable families with essential services including food assistance and emergency relief.',
        imageUrl: 'https://images.unsplash.com/photo-1593113598332-cd288d649433?w=400',
        address: '789 Care Avenue, Support District',
        phone: '+1 (555) 345-6789',
        email: 'help@communitycare.org',
        website: 'https://communitycare.org',
        registrationNumber: 'CCC-2024-003',
        categories: ['community', 'health', 'food'],
        isActive: true,
        rating: 4.9,
        totalDonations: 203,
        createdAt: DateTime.now().subtract(const Duration(days: 500)),
      ),
      CharityModel(
        id: 'charity_4',
        name: 'Fresh Start Initiative',
        description: 'Helping individuals and families start fresh by providing access to fresh, healthy food and life skills training.',
        imageUrl: 'https://images.unsplash.com/photo-1584464491033-06628f3a6b7b?w=400',
        address: '321 Fresh Street, New Beginnings',
        phone: '+1 (555) 456-7890',
        email: 'freshstart@initiative.org',
        website: 'https://freshstart.org',
        registrationNumber: 'FSI-2024-004',
        categories: ['education', 'community', 'food'],
        isActive: true,
        rating: 4.7,
        totalDonations: 134,
        createdAt: DateTime.now().subtract(const Duration(days: 300)),
      ),
      CharityModel(
        id: 'charity_5',
        name: 'Harvest for All',
        description: 'Connecting local farmers with food assistance programs to ensure no one goes hungry in our community.',
        imageUrl: 'https://images.unsplash.com/photo-1500937386664-56d1dfef3854?w=400',
        address: '654 Harvest Lane, Farm District',
        phone: '+1 (555) 567-8901',
        email: 'harvest@forall.org',
        website: 'https://harvestforall.org',
        registrationNumber: 'HFA-2024-005',
        categories: ['food', 'agriculture', 'community'],
        isActive: true,
        rating: 4.5,
        totalDonations: 97,
        createdAt: DateTime.now().subtract(const Duration(days: 180)),
      ),
    ];

    try {
      for (final charity in charities) {
        await _firestore.collection('charities').doc(charity.id).set(charity.toMap());
        print('Added charity: ${charity.name}');
      }
      print('All sample charities added successfully!');
    } catch (e) {
      print('Error adding sample charities: $e');
    }
  }

  static Future<void> deleteSampleCharities() async {
    final charityIds = ['charity_1', 'charity_2', 'charity_3', 'charity_4', 'charity_5'];
    
    try {
      for (final id in charityIds) {
        await _firestore.collection('charities').doc(id).delete();
        print('Deleted charity: $id');
      }
      print('All sample charities deleted successfully!');
    } catch (e) {
      print('Error deleting sample charities: $e');
    }
  }
}

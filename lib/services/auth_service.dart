import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email and password
  Future<UserCredential> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    if (password != confirmPassword) {
      throw Exception('Passwords do not match');
    }

    if (password.length < 6) {
      throw Exception('Password must be at least 6 characters long');
    }

    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Update last login time
      await _updateLastLogin(userCredential.user!.uid);
      
      return userCredential;
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      // Clear only authentication-related local storage, keep onboarding status
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_role'); // Remove user role
      // Keep 'onboarding_completed' so user doesn't see onboarding again
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Create user profile in Firestore
  Future<void> createUserProfile({
    required String uid,
    required String email,
    required UserRole role,
    String? displayName,
  }) async {
    try {
      UserModel userModel = UserModel(
        uid: uid,
        email: email,
        primaryRole: role,
        secondaryRole: null, // No secondary role initially
        currentActiveRole: role,
        displayName: displayName,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(uid).set(userModel.toMap());
      
      // Save role to local storage
      await _saveUserRole(role);
    } catch (e) {
      throw Exception('Failed to create user profile: $e');
    }
  }

  // Get user profile from Firestore
  Future<UserModel?> getUserProfile(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user profile: $e');
    }
  }

  // Get real-time user profile stream from Firestore
  Stream<UserModel?> getUserProfileStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) {
          if (doc.exists) {
            return UserModel.fromMap(doc.data() as Map<String, dynamic>);
          }
          return null;
        })
        .handleError((error) {
          print('Error in user profile stream: $error');
          return null;
        });
  }

  // Update user role (legacy method - now updates current active role)
  Future<void> updateUserRole(String uid, UserRole newRole) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'currentActiveRole': newRole.toString().split('.').last,
      });
      
      // Update local storage
      await _saveUserRole(newRole);
    } catch (e) {
      throw Exception('Failed to update user role: $e');
    }
  }

  // Switch between existing roles
  Future<void> switchToRole(String uid, UserRole targetRole) async {
    try {
      // First get current user profile to validate the switch
      UserModel? userProfile = await getUserProfile(uid);
      if (userProfile == null) {
        throw Exception('User profile not found');
      }

      // Check if the target role is available
      if (!userProfile.availableRoles.contains(targetRole)) {
        throw Exception('Target role is not available for this user');
      }

      await _firestore.collection('users').doc(uid).update({
        'currentActiveRole': targetRole.toString().split('.').last,
      });
      
      // Update local storage
      await _saveUserRole(targetRole);
    } catch (e) {
      throw Exception('Failed to switch role: $e');
    }
  }

  // Flexible role switching - allows switching to any role based on business rules
  Future<void> switchToRoleFlexible(String uid, UserRole targetRole) async {
    try {
      // First get current user profile
      UserModel? userProfile = await getUserProfile(uid);
      if (userProfile == null) {
        throw Exception('User profile not found');
      }

      // Prepare update data
      Map<String, dynamic> updateData = {
        'currentActiveRole': targetRole.toString().split('.').last,
      };

      // Handle secondary role assignment - always set Consumer as secondary role
      if (targetRole == UserRole.consumer) {
        // When switching to Consumer, always set the current primary role as secondary
        updateData['secondaryRole'] = userProfile.primaryRole.toString().split('.').last;
      }
      // Handle switching from Consumer to other role - always set Consumer as secondary
      else if (userProfile.primaryRole == UserRole.consumer) {
        // When switching from Consumer to another role, always set Consumer as secondary
        updateData['secondaryRole'] = UserRole.consumer.toString().split('.').last;
      }
      // Handle switching between non-Consumer roles - always set Consumer as secondary
      else if (userProfile.primaryRole != UserRole.consumer && targetRole != UserRole.consumer) {
        // When switching between non-Consumer roles, always set Consumer as secondary
        updateData['secondaryRole'] = UserRole.consumer.toString().split('.').last;
      }

      // Update the user profile
      await _firestore.collection('users').doc(uid).update(updateData);
      
      // Update local storage
      await _saveUserRole(targetRole);
    } catch (e) {
      throw Exception('Failed to switch role: $e');
    }
  }

  // Add secondary role (Consumer + one other role)
  Future<void> addSecondaryRole(String uid, UserRole secondaryRole) async {
    try {
      // Get current user profile
      UserModel? userProfile = await getUserProfile(uid);
      if (userProfile == null) {
        throw Exception('User profile not found');
      }

      // Validate role combination
      if (!userProfile.canAddSecondaryRole(secondaryRole)) {
        throw Exception('Invalid role combination. Only Consumer + one other role is allowed.');
      }

      await _firestore.collection('users').doc(uid).update({
        'secondaryRole': secondaryRole.toString().split('.').last,
      });
    } catch (e) {
      throw Exception('Failed to add secondary role: $e');
    }
  }

  // Remove secondary role
  Future<void> removeSecondaryRole(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'secondaryRole': null,
        'currentActiveRole': null, // Will default to primaryRole in next login
      });
    } catch (e) {
      throw Exception('Failed to remove secondary role: $e');
    }
  }

  // Update last login time
  Future<void> _updateLastLogin(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'lastLoginAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      // Don't throw error for this as it's not critical
      print('Failed to update last login: $e');
    }
  }

  // Save user role to local storage
  Future<void> _saveUserRole(UserRole role) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_role', role.toString().split('.').last);
  }

  // Get user role from local storage
  Future<UserRole?> getUserRoleFromStorage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? roleString = prefs.getString('user_role');
    if (roleString != null) {
      return UserRole.values.firstWhere(
        (e) => e.toString().split('.').last == roleString,
        orElse: () => UserRole.consumer,
      );
    }
    return null;
  }

  // Check if user has completed onboarding
  Future<bool> hasCompletedOnboarding() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('onboarding_completed') ?? false;
  }

  // Mark onboarding as completed
  Future<void> markOnboardingCompleted() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    return _auth.currentUser != null;
  }

  // Handle Firebase Auth errors
  String _handleAuthError(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'weak-password':
          return 'The password provided is too weak.';
        case 'email-already-in-use':
          return 'An account already exists for that email.';
        case 'user-not-found':
          return 'No user found for that email.';
        case 'wrong-password':
          return 'Wrong password provided.';
        case 'invalid-email':
          return 'The email address is invalid.';
        case 'user-disabled':
          return 'This user account has been disabled.';
        case 'too-many-requests':
          return 'Too many requests. Try again later.';
        case 'operation-not-allowed':
          return 'Email/password accounts are not enabled.';
        default:
          return 'An error occurred. Please try again.';
      }
    }
    return 'An unexpected error occurred.';
  }
}

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../services/notification_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  User? _currentUser;
  UserModel? _userProfile;
  UserRole? _currentRole;
  bool _isLoading = false;
  String? _error;

  // Getters
  User? get currentUser => _currentUser;
  UserModel? get userProfile => _userProfile;
  UserRole? get currentRole => _currentRole;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null;

  // Initialize auth provider
  Future<void> initialize() async {
    _setLoading(true);
    try {
      _currentUser = _authService.currentUser;
      if (_currentUser != null) {
        await _loadUserProfile();
        await _loadUserRole();
        // Start listening to real-time profile updates
        startListeningToProfileUpdates();
        // Initialize notifications and register token
        await NotificationService().initialize(_currentUser!.uid);
      }
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Sign up
  Future<bool> signUp({
    required String fullName,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    _setLoading(true);
    _clearError();
    
    try {
      UserCredential userCredential = await _authService.signUpWithEmailAndPassword(
        email: email,
        password: password,
        confirmPassword: confirmPassword,
      );
      
      _currentUser = userCredential.user;
      
      // Update the user's display name in Firebase Auth
      if (_currentUser != null) {
        print('Updating Firebase Auth displayName to: $fullName');
        await _currentUser!.updateDisplayName(fullName);
        // Reload the user to get the updated display name
        await _currentUser!.reload();
        _currentUser = _authService.currentUser;
        print('Firebase Auth displayName after update: ${_currentUser!.displayName}');
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Create user profile with role
  Future<bool> createUserProfile({
    required UserRole role,
    String? displayName,
  }) async {
    if (_currentUser == null) {
      _setError('No authenticated user found');
      return false;
    }

    _setLoading(true);
    _clearError();
    
    try {
      // Use the display name from Firebase Auth (which should contain the full name from signup)
      final fullName = displayName ?? _currentUser!.displayName ?? 'User';
      
      // Debug: Print the full name being stored
      print('Creating user profile with displayName: $fullName');
      
      await _authService.createUserProfile(
        uid: _currentUser!.uid,
        email: _currentUser!.email!,
        role: role,
        displayName: fullName,
      );
      
      _currentRole = role;
      await _loadUserProfile();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Sign in
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();
    
    try {
      UserCredential userCredential = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      _currentUser = userCredential.user;
      await _loadUserProfile();
      await _loadUserRole();
      // Start listening to real-time profile updates
      startListeningToProfileUpdates();
      // Initialize notifications and register token
      if (_currentUser != null) {
        await NotificationService().initialize(_currentUser!.uid);
      }
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Sign in with Google
  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _clearError();
    
    try {
      UserCredential userCredential = await _authService.signInWithGoogle();
      
      _currentUser = userCredential.user;
      
      // Check if user profile exists, if not, they need to select a role
      await _loadUserProfile();
      await _loadUserRole();
      
      // If user profile exists, set the current role from the profile
      if (_userProfile != null && _userProfile!.currentActiveRole != null) {
        _currentRole = _userProfile!.currentActiveRole;
      }
      
      // Start listening to real-time profile updates
      startListeningToProfileUpdates();
      // Initialize notifications and register token
      if (_currentUser != null) {
        await NotificationService().initialize(_currentUser!.uid);
      }
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Sign out
  Future<void> signOut() async {
    _setLoading(true);
    try {
      await _authService.signOut();
      _currentUser = null;
      _userProfile = null;
      _currentRole = null;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Update user role (legacy - now updates current active role)
  Future<bool> updateUserRole(UserRole newRole) async {
    if (_currentUser == null) {
      _setError('No authenticated user found');
      return false;
    }

    _setLoading(true);
    _clearError();
    
    try {
      await _authService.updateUserRole(_currentUser!.uid, newRole);
      _currentRole = newRole;
      await _loadUserProfile();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Switch between existing roles
  Future<bool> switchToRole(UserRole targetRole) async {
    if (_currentUser == null) {
      _setError('No authenticated user found');
      return false;
    }

    _setLoading(true);
    _clearError();
    
    try {
      await _authService.switchToRole(_currentUser!.uid, targetRole);
      _currentRole = targetRole;
      await _loadUserProfile();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Flexible role switching - allows switching to any role based on business rules
  Future<bool> switchToRoleFlexible(UserRole targetRole) async {
    if (_currentUser == null) {
      _setError('No authenticated user found');
      return false;
    }

    _setLoading(true);
    _clearError();
    
    try {
      await _authService.switchToRoleFlexible(_currentUser!.uid, targetRole);
      
      // Update local role immediately for instant UI feedback
      _currentRole = targetRole;
      
      // Update user profile to get the latest data from Firestore
      await _loadUserProfile();
      
      // Force notify listeners to update all UI components
      notifyListeners();
      
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Add secondary role
  Future<bool> addSecondaryRole(UserRole secondaryRole) async {
    if (_currentUser == null) {
      _setError('No authenticated user found');
      return false;
    }

    _setLoading(true);
    _clearError();
    
    try {
      await _authService.addSecondaryRole(_currentUser!.uid, secondaryRole);
      await _loadUserProfile();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Remove secondary role
  Future<bool> removeSecondaryRole() async {
    if (_currentUser == null) {
      _setError('No authenticated user found');
      return false;
    }

    _setLoading(true);
    _clearError();
    
    try {
      await _authService.removeSecondaryRole(_currentUser!.uid);
      await _loadUserProfile();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Get current active role from user profile
  UserRole? get currentActiveRole {
    return _userProfile?.currentActiveRole ?? _currentRole;
  }

  // Check if user can switch roles
  bool get canSwitchRoles {
    return _userProfile?.canSwitchRoles ?? false;
  }

  // Get the inactive role that user can switch to
  UserRole? get inactiveRole {
    return _userProfile?.inactiveRole;
  }

  // Get available roles for the user
  List<UserRole> get availableRoles {
    return _userProfile?.availableRoles ?? [];
  }

  // Load user profile from Firestore
  Future<void> _loadUserProfile() async {
    if (_currentUser == null) return;
    
    try {
      _userProfile = await _authService.getUserProfile(_currentUser!.uid);
      notifyListeners();
    } catch (e) {
      print('Error loading user profile: $e');
    }
  }

  // Force refresh user profile (public method for manual refresh)
  Future<void> refreshUserProfile() async {
    await _loadUserProfile();
  }

  // Update user profile directly (for real-time updates)
  void updateUserProfile(UserModel userProfile) {
    // Only update if the profile has actually changed
    if (_userProfile?.currentActiveRole != userProfile.currentActiveRole ||
        _userProfile?.email != userProfile.email ||
        _userProfile?.displayName != userProfile.displayName) {
      _userProfile = userProfile;
      _currentRole = userProfile.currentActiveRole;
      notifyListeners();
    }
  }

  // Start listening to real-time user profile updates
  void startListeningToProfileUpdates() {
    if (_currentUser == null) return;
    
    _authService.getUserProfileStream(_currentUser!.uid).listen(
      (userProfile) {
        if (userProfile != null) {
          _userProfile = userProfile;
          notifyListeners();
        }
      },
      onError: (error) {
        print('Error listening to profile updates: $error');
      },
    );
  }

  // Load user role from local storage
  Future<void> _loadUserRole() async {
    try {
      _currentRole = await _authService.getUserRoleFromStorage();
      notifyListeners();
    } catch (e) {
      print('Error loading user role: $e');
    }
  }

  // Check if onboarding is completed
  Future<bool> hasCompletedOnboarding() async {
    return await _authService.hasCompletedOnboarding();
  }

  // Mark onboarding as completed
  Future<void> markOnboardingCompleted() async {
    await _authService.markOnboardingCompleted();
  }

  // Check if user is logged in
  Future<bool> isUserLoggedIn() async {
    return await _authService.isLoggedIn();
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  // Clear error manually
  void clearError() {
    _clearError();
  }
}

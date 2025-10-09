import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole {
  farmer,
  consumer,
  foodDistributor,
  transporter,
}

extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.farmer:
        return 'Farmer';
      case UserRole.consumer:
        return 'Consumer';
      case UserRole.foodDistributor:
        return 'Food Distributor';
      case UserRole.transporter:
        return 'Transporter';
    }
  }

  String get localizedName {
    // This will be handled by localization
    return displayName;
  }

  IconData get icon {
    switch (this) {
      case UserRole.farmer:
        return Icons.agriculture;
      case UserRole.consumer:
        return Icons.shopping_cart;
      case UserRole.foodDistributor:
        return Icons.store;
      case UserRole.transporter:
        return Icons.local_shipping;
    }
  }
}

class UserModel {
  final String uid;
  final String email;
  final UserRole primaryRole;
  final UserRole? secondaryRole;
  final UserRole currentActiveRole;
  final String? displayName;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final bool isActive;

  UserModel({
    required this.uid,
    required this.email,
    required this.primaryRole,
    this.secondaryRole,
    required this.currentActiveRole,
    this.displayName,
    this.photoUrl,
    required this.createdAt,
    required this.lastLoginAt,
    this.isActive = true,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      primaryRole: UserRole.values.firstWhere(
        (e) => e.toString() == 'UserRole.${map['primaryRole'] ?? map['role']}',
        orElse: () => UserRole.consumer,
      ),
      secondaryRole: map['secondaryRole'] != null 
          ? UserRole.values.firstWhere(
              (e) => e.toString() == 'UserRole.${map['secondaryRole']}',
              orElse: () => UserRole.consumer,
            )
          : null,
      currentActiveRole: UserRole.values.firstWhere(
        (e) => e.toString() == 'UserRole.${map['currentActiveRole'] ?? map['role']}',
        orElse: () => UserRole.consumer,
      ),
      displayName: map['displayName'],
      photoUrl: map['photoUrl'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      lastLoginAt: (map['lastLoginAt'] as Timestamp).toDate(),
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'primaryRole': primaryRole.toString().split('.').last,
      'secondaryRole': secondaryRole?.toString().split('.').last,
      'currentActiveRole': currentActiveRole.toString().split('.').last,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': Timestamp.fromDate(lastLoginAt),
      'isActive': isActive,
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    UserRole? primaryRole,
    UserRole? secondaryRole,
    UserRole? currentActiveRole,
    String? displayName,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? isActive,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      primaryRole: primaryRole ?? this.primaryRole,
      secondaryRole: secondaryRole ?? this.secondaryRole,
      currentActiveRole: currentActiveRole ?? this.currentActiveRole,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isActive: isActive ?? this.isActive,
    );
  }

  // Helper methods for role management
  bool get hasSecondaryRole => secondaryRole != null;
  
  bool get canSwitchRoles => hasSecondaryRole;
  
  UserRole get inactiveRole => hasSecondaryRole 
      ? (currentActiveRole == primaryRole ? secondaryRole! : primaryRole)
      : primaryRole;
      
  // Get the role that can be switched to (not the current active role)
  UserRole get switchableRole {
    if (currentActiveRole == UserRole.consumer) {
      return primaryRole;
    } else {
      return UserRole.consumer;
    }
  }
      
  List<UserRole> get availableRoles => hasSecondaryRole 
      ? [primaryRole, secondaryRole!] 
      : [primaryRole];
      
  // Get only the roles that can be switched to (excluding current active role)
  List<UserRole> get switchableRoles {
    if (currentActiveRole == UserRole.consumer) {
      return [primaryRole]; // Can switch back to primary role
    } else {
      return [UserRole.consumer]; // Can switch to Consumer
    }
  }
      
  bool canAddSecondaryRole(UserRole role) {
    // Can only add Consumer as secondary role if primary is not Consumer
    // Or can add any role as secondary if primary is Consumer
    if (primaryRole == UserRole.consumer) {
      return secondaryRole == null && role != UserRole.consumer;
    } else {
      return secondaryRole == null && role == UserRole.consumer;
    }
  }
  
  String get roleDisplayText {
    if (hasSecondaryRole) {
      return '${currentActiveRole.displayName} (${inactiveRole.displayName} available)';
    } else {
      return currentActiveRole.displayName;
    }
  }
  
  // Check if Consumer is the sticky secondary role
  bool get isConsumerStickySecondary {
    return hasSecondaryRole && secondaryRole == UserRole.consumer;
  }
  
  // Check if this is the first time switching to Consumer
  bool get isFirstTimeConsumerSwitch {
    return currentActiveRole == UserRole.consumer && 
           hasSecondaryRole && 
           secondaryRole == primaryRole;
  }
  

}

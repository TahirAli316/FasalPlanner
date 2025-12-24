/// User Model
///
/// Represents a user in the FasalPlanner app
/// Contains user profile data and farming preferences

import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String? region;
  final double? landSize;
  final String? soilType;
  final String? selectedCropId;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.region,
    this.landSize,
    this.soilType,
    this.selectedCropId,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create UserModel from Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      region: data['region'],
      landSize: data['landSize']?.toDouble(),
      soilType: data['soilType'],
      selectedCropId: data['selectedCropId'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert UserModel to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'region': region,
      'landSize': landSize,
      'soilType': soilType,
      'selectedCropId': selectedCropId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Create a copy with updated fields
  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? region,
    double? landSize,
    String? soilType,
    String? selectedCropId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      region: region ?? this.region,
      landSize: landSize ?? this.landSize,
      soilType: soilType ?? this.soilType,
      selectedCropId: selectedCropId ?? this.selectedCropId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if user has completed farm details
  bool get hasCompletedFarmDetails {
    return region != null && landSize != null && soilType != null;
  }
}

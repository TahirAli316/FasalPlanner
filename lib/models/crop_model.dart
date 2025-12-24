/// Crop Model
///
/// Represents a crop that can be recommended and selected by users
/// Contains crop details and growing requirements

import 'package:cloud_firestore/cloud_firestore.dart';

class CropModel {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final List<String> suitableRegions;
  final List<String> suitableSoilTypes;
  final double minLandSize;
  final int growingDurationDays;
  final String season;
  final double expectedYieldPerAcre;
  final String waterRequirement;

  CropModel({
    required this.id,
    required this.name,
    required this.description,
    this.imageUrl = '',
    required this.suitableRegions,
    required this.suitableSoilTypes,
    required this.minLandSize,
    required this.growingDurationDays,
    required this.season,
    required this.expectedYieldPerAcre,
    required this.waterRequirement,
  });

  /// Create CropModel from Firestore document
  factory CropModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CropModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      suitableRegions: List<String>.from(data['suitableRegions'] ?? []),
      suitableSoilTypes: List<String>.from(data['suitableSoilTypes'] ?? []),
      minLandSize: (data['minLandSize'] ?? 0).toDouble(),
      growingDurationDays: data['growingDurationDays'] ?? 90,
      season: data['season'] ?? 'All Season',
      expectedYieldPerAcre: (data['expectedYieldPerAcre'] ?? 0).toDouble(),
      waterRequirement: data['waterRequirement'] ?? 'Medium',
    );
  }

  /// Convert CropModel to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'suitableRegions': suitableRegions,
      'suitableSoilTypes': suitableSoilTypes,
      'minLandSize': minLandSize,
      'growingDurationDays': growingDurationDays,
      'season': season,
      'expectedYieldPerAcre': expectedYieldPerAcre,
      'waterRequirement': waterRequirement,
    };
  }

  /// Get crop icon based on crop name
  String get iconName {
    switch (name.toLowerCase()) {
      case 'wheat':
        return '🌾';
      case 'rice':
        return '🌾';
      case 'corn':
      case 'maize':
      case 'maize (corn)':
        return '🌽';
      case 'cotton':
        return '🌿';
      case 'sugarcane':
        return '🎋';
      case 'potato':
        return '🥔';
      case 'tomato':
        return '🍅';
      case 'onion':
        return '🧅';
      case 'soybean':
        return '🫘';
      // ML model crops
      case 'apple':
        return '🍎';
      case 'banana':
        return '🍌';
      case 'blackgram':
      case 'black gram':
        return '🫘';
      case 'chickpea':
        return '🫛';
      case 'coconut':
        return '🥥';
      case 'coffee':
        return '☕';
      case 'grapes':
        return '🍇';
      case 'jute':
        return '🌾';
      case 'kidneybeans':
      case 'kidney beans':
        return '🫘';
      case 'lentil':
        return '🫛';
      case 'mango':
        return '🥭';
      case 'mothbeans':
      case 'moth beans':
        return '🫘';
      case 'mungbean':
      case 'mung bean':
        return '🫛';
      case 'muskmelon':
        return '🍈';
      case 'orange':
        return '🍊';
      case 'papaya':
        return '🍈';
      case 'pigeonpeas':
      case 'pigeon peas':
        return '🫛';
      case 'pomegranate':
        return '🍎';
      case 'watermelon':
        return '🍉';
      default:
        return '🌱';
    }
  }
}

/// Farming Plan Model
///
/// Represents a farming plan with scheduled activities
/// Generated using Gemini AI for personalized recommendations

import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/services/gemini_service.dart';

class FarmingPlanModel {
  final String id;
  final String cropId;
  final String cropName;
  final String userId;
  final DateTime sowingDate;
  final DateTime harvestDate;
  final List<FarmingActivity> activities;
  final DateTime createdAt;
  final bool isAIGenerated;

  FarmingPlanModel({
    required this.id,
    required this.cropId,
    required this.cropName,
    required this.userId,
    required this.sowingDate,
    required this.harvestDate,
    required this.activities,
    required this.createdAt,
    this.isAIGenerated = false,
  });

  /// Create FarmingPlanModel from Firestore document
  factory FarmingPlanModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FarmingPlanModel(
      id: doc.id,
      cropId: data['cropId'] ?? '',
      cropName: data['cropName'] ?? '',
      userId: data['userId'] ?? '',
      sowingDate: (data['sowingDate'] as Timestamp).toDate(),
      harvestDate: (data['harvestDate'] as Timestamp).toDate(),
      activities:
          (data['activities'] as List<dynamic>?)
              ?.map((a) => FarmingActivity.fromMap(a))
              .toList() ??
          [],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isAIGenerated: data['isAIGenerated'] ?? false,
    );
  }

  /// Convert FarmingPlanModel to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'cropId': cropId,
      'cropName': cropName,
      'userId': userId,
      'sowingDate': Timestamp.fromDate(sowingDate),
      'harvestDate': Timestamp.fromDate(harvestDate),
      'activities': activities.map((a) => a.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'isAIGenerated': isAIGenerated,
    };
  }

  /// Copy with updated fields
  FarmingPlanModel copyWith({
    String? id,
    String? cropId,
    String? cropName,
    String? userId,
    DateTime? sowingDate,
    DateTime? harvestDate,
    List<FarmingActivity>? activities,
    DateTime? createdAt,
    bool? isAIGenerated,
  }) {
    return FarmingPlanModel(
      id: id ?? this.id,
      cropId: cropId ?? this.cropId,
      cropName: cropName ?? this.cropName,
      userId: userId ?? this.userId,
      sowingDate: sowingDate ?? this.sowingDate,
      harvestDate: harvestDate ?? this.harvestDate,
      activities: activities ?? this.activities,
      createdAt: createdAt ?? this.createdAt,
      isAIGenerated: isAIGenerated ?? this.isAIGenerated,
    );
  }

  /// Generate a farming plan using Gemini AI
  static Future<FarmingPlanModel> generateAIPlan({
    required String cropId,
    required String cropName,
    required String userId,
    required int growingDurationDays,
    required String region,
    required String soilType,
    required double landSize,
    DateTime? startDate,
  }) async {
    final sowing = startDate ?? DateTime.now();
    final harvest = sowing.add(Duration(days: growingDurationDays));

    // Generate activities using Gemini AI
    final activities = await GeminiService.generateFarmingPlan(
      cropName: cropName,
      region: region,
      soilType: soilType,
      landSize: landSize,
      growingDurationDays: growingDurationDays,
      startDate: sowing,
    );

    return FarmingPlanModel(
      id: '',
      cropId: cropId,
      cropName: cropName,
      userId: userId,
      sowingDate: sowing,
      harvestDate: harvest,
      activities: activities,
      createdAt: DateTime.now(),
      isAIGenerated: true,
    );
  }

  /// Generate a default farming plan (fallback, non-AI)
  factory FarmingPlanModel.generatePlan({
    required String cropId,
    required String cropName,
    required String userId,
    required int growingDurationDays,
    DateTime? startDate,
  }) {
    final sowing = startDate ?? DateTime.now();
    final harvest = sowing.add(Duration(days: growingDurationDays));

    // Generate standard farming activities
    final activities = <FarmingActivity>[
      FarmingActivity(
        id: '1',
        title: 'Land Preparation',
        description: 'Prepare the land by plowing and leveling',
        date: sowing.subtract(const Duration(days: 7)),
        type: ActivityType.preparation,
        isCompleted: false,
      ),
      FarmingActivity(
        id: '2',
        title: 'Sowing',
        description: 'Sow the seeds at appropriate depth and spacing',
        date: sowing,
        type: ActivityType.sowing,
        isCompleted: false,
      ),
      FarmingActivity(
        id: '3',
        title: 'First Irrigation',
        description: 'Water the field after sowing',
        date: sowing.add(const Duration(days: 1)),
        type: ActivityType.irrigation,
        isCompleted: false,
      ),
      FarmingActivity(
        id: '4',
        title: 'First Fertilizer Application',
        description: 'Apply basal dose of fertilizer',
        date: sowing.add(const Duration(days: 21)),
        type: ActivityType.fertilizer,
        isCompleted: false,
      ),
      FarmingActivity(
        id: '5',
        title: 'Second Irrigation',
        description: 'Water the field for healthy growth',
        date: sowing.add(const Duration(days: 30)),
        type: ActivityType.irrigation,
        isCompleted: false,
      ),
      FarmingActivity(
        id: '6',
        title: 'Second Fertilizer Application',
        description: 'Apply top dressing of fertilizer',
        date: sowing.add(const Duration(days: 45)),
        type: ActivityType.fertilizer,
        isCompleted: false,
      ),
      FarmingActivity(
        id: '7',
        title: 'Weeding',
        description: 'Remove weeds from the field',
        date: sowing.add(const Duration(days: 35)),
        type: ActivityType.maintenance,
        isCompleted: false,
      ),
      FarmingActivity(
        id: '8',
        title: 'Pest Control',
        description: 'Apply pest control measures if needed',
        date: sowing.add(const Duration(days: 50)),
        type: ActivityType.pestControl,
        isCompleted: false,
      ),
      FarmingActivity(
        id: '9',
        title: 'Third Irrigation',
        description: 'Water the field during flowering stage',
        date: sowing.add(Duration(days: (growingDurationDays * 0.6).round())),
        type: ActivityType.irrigation,
        isCompleted: false,
      ),
      FarmingActivity(
        id: '10',
        title: 'Harvesting',
        description: 'Harvest the mature crop',
        date: harvest,
        type: ActivityType.harvesting,
        isCompleted: false,
      ),
    ];

    return FarmingPlanModel(
      id: '',
      cropId: cropId,
      cropName: cropName,
      userId: userId,
      sowingDate: sowing,
      harvestDate: harvest,
      activities: activities,
      createdAt: DateTime.now(),
    );
  }
}

/// Enum for activity types
enum ActivityType {
  preparation,
  sowing,
  irrigation,
  fertilizer,
  pestControl,
  maintenance,
  harvesting,
  custom,
}

/// Model for individual farming activities
class FarmingActivity {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final ActivityType type;
  final bool isCompleted;
  final bool isCustom;

  FarmingActivity({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.type,
    required this.isCompleted,
    this.isCustom = false,
  });

  /// Create FarmingActivity from Map
  factory FarmingActivity.fromMap(Map<String, dynamic> map) {
    return FarmingActivity(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      type: ActivityType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => ActivityType.custom,
      ),
      isCompleted: map['isCompleted'] ?? false,
      isCustom: map['isCustom'] ?? false,
    );
  }

  /// Convert FarmingActivity to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': Timestamp.fromDate(date),
      'type': type.name,
      'isCompleted': isCompleted,
      'isCustom': isCustom,
    };
  }

  /// Get icon for activity type
  String get icon {
    switch (type) {
      case ActivityType.preparation:
        return '🚜';
      case ActivityType.sowing:
        return '🌱';
      case ActivityType.irrigation:
        return '💧';
      case ActivityType.fertilizer:
        return '🧪';
      case ActivityType.pestControl:
        return '🐛';
      case ActivityType.maintenance:
        return '🔧';
      case ActivityType.harvesting:
        return '🌾';
      case ActivityType.custom:
        return '📝';
    }
  }

  /// Copy with updated fields
  FarmingActivity copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? date,
    ActivityType? type,
    bool? isCompleted,
    bool? isCustom,
  }) {
    return FarmingActivity(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      type: type ?? this.type,
      isCompleted: isCompleted ?? this.isCompleted,
      isCustom: isCustom ?? this.isCustom,
    );
  }
}

/// ML Crop Service
///
/// Pre-trained ML inference for crop recommendation
/// Uses rule-based inference logic to recommend crops based on:
/// - Region
/// - Soil type
/// - Land size
///
/// NOTE: This implements a simple rule-based system that simulates
/// ML inference. The rules are based on agricultural best practices.

import '../../models/crop_model.dart';

class MLCropService {
  /// ============================================================
  /// PRE-TRAINED ML INFERENCE - CROP RECOMMENDATION ENGINE
  /// ============================================================
  ///
  /// This method uses rule-based inference to recommend suitable crops
  /// based on the user's farming conditions. The inference rules are
  /// derived from agricultural domain knowledge and can be extended
  /// to use actual ML models in the future.
  ///
  /// Input Features:
  /// - region: Geographic region of the farm
  /// - soilType: Type of soil available
  /// - landSize: Size of land in acres
  ///
  /// Output:
  /// - List of recommended crops sorted by suitability score
  /// ============================================================

  /// Main recommendation method - Pre-trained ML inference
  List<CropRecommendation> recommendCrops({
    required String region,
    required String soilType,
    required double landSize,
    required List<CropModel> availableCrops,
  }) {
    // Pre-trained ML inference: Calculate suitability score for each crop
    final recommendations = <CropRecommendation>[];

    for (final crop in availableCrops) {
      // Calculate feature-based score using inference rules
      final score = _calculateSuitabilityScore(
        crop: crop,
        region: region,
        soilType: soilType,
        landSize: landSize,
      );

      // Only include crops with positive suitability score
      if (score > 0) {
        recommendations.add(
          CropRecommendation(
            crop: crop,
            suitabilityScore: score,
            reasons: _generateRecommendationReasons(
              crop: crop,
              region: region,
              soilType: soilType,
              landSize: landSize,
            ),
          ),
        );
      }
    }

    // Sort by suitability score (descending)
    recommendations.sort(
      (a, b) => b.suitabilityScore.compareTo(a.suitabilityScore),
    );

    return recommendations;
  }

  /// ============================================================
  /// PRE-TRAINED ML INFERENCE - SUITABILITY SCORE CALCULATION
  /// ============================================================
  ///
  /// Multi-feature scoring function that combines:
  /// 1. Region compatibility (weight: 0.35)
  /// 2. Soil type compatibility (weight: 0.35)
  /// 3. Land size suitability (weight: 0.20)
  /// 4. Season factor (weight: 0.10)
  /// ============================================================
  double _calculateSuitabilityScore({
    required CropModel crop,
    required String region,
    required String soilType,
    required double landSize,
  }) {
    double score = 0.0;

    // Feature 1: Region compatibility (35% weight)
    // Pre-trained inference rule: Check if crop is suitable for region
    if (crop.suitableRegions.contains(region)) {
      score += 35.0;
    } else if (_isPartialRegionMatch(crop.suitableRegions, region)) {
      score += 15.0; // Partial match
    }

    // Feature 2: Soil type compatibility (35% weight)
    // Pre-trained inference rule: Check soil type suitability
    if (crop.suitableSoilTypes.contains(soilType)) {
      score += 35.0;
    } else if (_isSimilarSoilType(crop.suitableSoilTypes, soilType)) {
      score += 20.0; // Similar soil type
    }

    // Feature 3: Land size suitability (20% weight)
    // Pre-trained inference rule: Check if land size is sufficient
    if (landSize >= crop.minLandSize) {
      score += 20.0;
      // Bonus for optimal land size
      if (landSize >= crop.minLandSize * 2) {
        score += 5.0;
      }
    } else if (landSize >= crop.minLandSize * 0.5) {
      score += 10.0; // Can still grow with reduced yield
    }

    // Feature 4: Seasonal factor (10% weight)
    // Pre-trained inference rule: Current season suitability
    score += _getSeasonalScore(crop.season);

    return score;
  }

  /// Check for partial region match
  bool _isPartialRegionMatch(List<String> suitableRegions, String region) {
    // Inference rule: Adjacent or similar climate regions
    final regionGroups = {
      'Punjab': ['Sindh', 'KPK'],
      'Sindh': ['Punjab', 'Balochistan'],
      'KPK': ['Punjab'],
      'Balochistan': ['Sindh'],
    };

    final adjacentRegions = regionGroups[region] ?? [];
    return suitableRegions.any((r) => adjacentRegions.contains(r));
  }

  /// Check for similar soil types
  bool _isSimilarSoilType(List<String> suitableSoils, String soilType) {
    // Inference rule: Similar soil characteristics
    final soilGroups = {
      'Loamy': ['Sandy Loam', 'Clay'],
      'Sandy Loam': ['Loamy', 'Sandy'],
      'Clay': ['Loamy', 'Alluvial'],
      'Sandy': ['Sandy Loam'],
      'Alluvial': ['Loamy', 'Clay'],
    };

    final similarSoils = soilGroups[soilType] ?? [];
    return suitableSoils.any((s) => similarSoils.contains(s));
  }

  /// Calculate seasonal score based on current month
  double _getSeasonalScore(String cropSeason) {
    final currentMonth = DateTime.now().month;

    // Inference rule: Season-based scoring
    // Rabi (Oct-March), Kharif (April-September)

    if (cropSeason == 'Year-round') {
      return 10.0; // Always suitable
    }

    final isRabiSeason = currentMonth >= 10 || currentMonth <= 3;
    final isKharifSeason = currentMonth >= 4 && currentMonth <= 9;

    if (cropSeason.contains('Rabi') && isRabiSeason) {
      return 10.0;
    } else if (cropSeason.contains('Kharif') && isKharifSeason) {
      return 10.0;
    } else if (cropSeason.contains('Rabi') && !isRabiSeason) {
      return 3.0; // Off-season but possible
    } else if (cropSeason.contains('Kharif') && !isKharifSeason) {
      return 3.0;
    }

    return 5.0; // Default
  }

  /// ============================================================
  /// PRE-TRAINED ML INFERENCE - RECOMMENDATION REASONING
  /// ============================================================
  ///
  /// Generate human-readable explanations for the recommendation
  /// ============================================================
  List<String> _generateRecommendationReasons({
    required CropModel crop,
    required String region,
    required String soilType,
    required double landSize,
  }) {
    final reasons = <String>[];

    // Region-based reasoning
    if (crop.suitableRegions.contains(region)) {
      reasons.add('✓ Well-suited for $region region');
    } else {
      reasons.add('△ Can be grown in $region with care');
    }

    // Soil-based reasoning
    if (crop.suitableSoilTypes.contains(soilType)) {
      reasons.add('✓ Ideal for $soilType soil');
    } else {
      reasons.add('△ Adaptable to $soilType soil');
    }

    // Land size reasoning
    if (landSize >= crop.minLandSize) {
      reasons.add('✓ Land size (${landSize}ac) is sufficient');
    } else {
      reasons.add('△ Consider larger land for better yield');
    }

    // Additional info
    reasons.add('📅 Growing season: ${crop.season}');
    reasons.add('💧 Water requirement: ${crop.waterRequirement}');

    return reasons;
  }

  /// ============================================================
  /// UTILITY METHODS
  /// ============================================================

  /// Get available regions for dropdown
  static List<String> getAvailableRegions() {
    return ['Punjab', 'Sindh', 'KPK', 'Balochistan'];
  }

  /// Get available soil types for dropdown
  static List<String> getAvailableSoilTypes() {
    return ['Loamy', 'Sandy Loam', 'Clay', 'Sandy', 'Alluvial'];
  }

  /// Get pre-defined crops if Firestore is not available
  static List<CropModel> getDefaultCrops() {
    return [
      CropModel(
        id: 'wheat',
        name: 'Wheat',
        description: 'A staple grain crop grown in temperate climates',
        suitableRegions: ['Punjab', 'Sindh', 'KPK', 'Balochistan'],
        suitableSoilTypes: ['Loamy', 'Clay', 'Sandy Loam'],
        minLandSize: 1.0,
        growingDurationDays: 120,
        season: 'Rabi (Winter)',
        expectedYieldPerAcre: 40,
        waterRequirement: 'Medium',
      ),
      CropModel(
        id: 'rice',
        name: 'Rice',
        description: 'A major food crop requiring abundant water',
        suitableRegions: ['Punjab', 'Sindh'],
        suitableSoilTypes: ['Clay', 'Loamy'],
        minLandSize: 2.0,
        growingDurationDays: 150,
        season: 'Kharif (Summer)',
        expectedYieldPerAcre: 35,
        waterRequirement: 'High',
      ),
      CropModel(
        id: 'cotton',
        name: 'Cotton',
        description: 'A cash crop important for textile industry',
        suitableRegions: ['Punjab', 'Sindh'],
        suitableSoilTypes: ['Sandy Loam', 'Loamy', 'Alluvial'],
        minLandSize: 3.0,
        growingDurationDays: 180,
        season: 'Kharif (Summer)',
        expectedYieldPerAcre: 12,
        waterRequirement: 'Medium',
      ),
      CropModel(
        id: 'sugarcane',
        name: 'Sugarcane',
        description: 'A tall perennial crop for sugar production',
        suitableRegions: ['Punjab', 'Sindh', 'KPK'],
        suitableSoilTypes: ['Loamy', 'Clay', 'Alluvial'],
        minLandSize: 2.0,
        growingDurationDays: 365,
        season: 'Year-round',
        expectedYieldPerAcre: 250,
        waterRequirement: 'High',
      ),
      CropModel(
        id: 'maize',
        name: 'Maize (Corn)',
        description: 'A versatile grain crop used for food and feed',
        suitableRegions: ['Punjab', 'KPK', 'Sindh'],
        suitableSoilTypes: ['Loamy', 'Sandy Loam', 'Alluvial'],
        minLandSize: 1.0,
        growingDurationDays: 100,
        season: 'Kharif & Rabi',
        expectedYieldPerAcre: 30,
        waterRequirement: 'Medium',
      ),
      CropModel(
        id: 'potato',
        name: 'Potato',
        description: 'A root vegetable crop with high demand',
        suitableRegions: ['Punjab', 'KPK'],
        suitableSoilTypes: ['Sandy Loam', 'Loamy'],
        minLandSize: 0.5,
        growingDurationDays: 90,
        season: 'Rabi (Winter)',
        expectedYieldPerAcre: 100,
        waterRequirement: 'Medium',
      ),
      CropModel(
        id: 'tomato',
        name: 'Tomato',
        description: 'A popular vegetable crop grown throughout the year',
        suitableRegions: ['Punjab', 'Sindh', 'KPK', 'Balochistan'],
        suitableSoilTypes: ['Loamy', 'Sandy Loam'],
        minLandSize: 0.25,
        growingDurationDays: 75,
        season: 'Year-round',
        expectedYieldPerAcre: 80,
        waterRequirement: 'Medium',
      ),
      CropModel(
        id: 'onion',
        name: 'Onion',
        description: 'A bulb vegetable essential for cooking',
        suitableRegions: ['Punjab', 'Sindh', 'Balochistan'],
        suitableSoilTypes: ['Loamy', 'Sandy Loam', 'Alluvial'],
        minLandSize: 0.25,
        growingDurationDays: 120,
        season: 'Rabi (Winter)',
        expectedYieldPerAcre: 60,
        waterRequirement: 'Low',
      ),
    ];
  }
}

/// Model for crop recommendation with score and reasons
class CropRecommendation {
  final CropModel crop;
  final double suitabilityScore;
  final List<String> reasons;

  CropRecommendation({
    required this.crop,
    required this.suitabilityScore,
    required this.reasons,
  });

  /// Get score as percentage
  String get scorePercentage => '${suitabilityScore.toStringAsFixed(0)}%';

  /// Get suitability level text
  String get suitabilityLevel {
    if (suitabilityScore >= 80) return 'Excellent';
    if (suitabilityScore >= 60) return 'Good';
    if (suitabilityScore >= 40) return 'Moderate';
    return 'Low';
  }
}

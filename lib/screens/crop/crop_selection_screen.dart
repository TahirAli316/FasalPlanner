/// Crop Selection Screen
///
/// Shows user's selected crop with detailed info
/// and allows navigation to recommendations

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../core/services/firebase_service.dart';
import '../../core/services/ml_crop_service.dart';
import '../../core/services/tflite_crop_service.dart';
import '../../models/crop_model.dart';
import '../../models/user_model.dart';
import '../../widgets/custom_button.dart';

class CropSelectionScreen extends StatefulWidget {
  const CropSelectionScreen({super.key});

  @override
  State<CropSelectionScreen> createState() => _CropSelectionScreenState();
}

class _CropSelectionScreenState extends State<CropSelectionScreen> {
  final _firebaseService = FirebaseService();

  UserModel? _user;
  CropModel? _selectedCrop;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      // Get user data
      final user = await _firebaseService.getUserData(uid);

      // Get all crops to find selected one
      List<CropModel> crops;
      try {
        crops = await _firebaseService.getAllCrops();
        if (crops.isEmpty) {
          crops = MLCropService.getDefaultCrops();
        }
      } catch (e) {
        crops = MLCropService.getDefaultCrops();
      }

      // Get selected crop
      CropModel? selectedCrop;
      if (user?.selectedCropId != null) {
        final cropId = user!.selectedCropId!;

        // First try to find in default crops list
        try {
          selectedCrop = crops.firstWhere((c) => c.id == cropId);
        } catch (e) {
          // Not found in default crops - check if it's an ML crop
          selectedCrop = _createMLCrop(cropId, user);
        }
      }

      if (mounted) {
        setState(() {
          _user = user;
          _selectedCrop = selectedCrop;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Create a CropModel from ML crop info if not found in default crops
  CropModel? _createMLCrop(String cropId, UserModel? user) {
    final cropInfo = TFLiteCropService.cropInfo[cropId];
    if (cropInfo == null) return null;

    // Growing durations for ML crops
    const growingDurations = {
      'apple': 365,
      'banana': 300,
      'blackgram': 90,
      'chickpea': 120,
      'coconut': 365,
      'coffee': 365,
      'cotton': 180,
      'grapes': 150,
      'jute': 120,
      'kidneybeans': 90,
      'lentil': 110,
      'maize': 100,
      'mango': 365,
      'mothbeans': 75,
      'mungbean': 70,
      'muskmelon': 80,
      'orange': 365,
      'papaya': 270,
      'pigeonpeas': 150,
      'pomegranate': 180,
      'rice': 150,
      'watermelon': 85,
    };

    return CropModel(
      id: cropId,
      name: cropInfo['name'] ?? cropId,
      description: 'AI recommended crop: ${cropInfo['name'] ?? cropId}',
      season: cropInfo['season'] ?? 'Seasonal',
      growingDurationDays: growingDurations[cropId] ?? 120,
      suitableRegions: [user?.region ?? 'Punjab'],
      suitableSoilTypes: [user?.soilType ?? 'Loamy'],
      minLandSize: 0.5,
      expectedYieldPerAcre: 20.0,
      waterRequirement: 'Medium',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Selected Crop'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryGreen),
            )
          : _selectedCrop != null
          ? _buildSelectedCropView()
          : _buildNoCropSelectedView(),
    );
  }

  Widget _buildSelectedCropView() {
    final crop = _selectedCrop!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main Crop Card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                // Header with icon and name
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryGreen,
                        AppColors.primaryGreen.withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Text(
                            crop.iconName,
                            style: const TextStyle(fontSize: 48),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        crop.name,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${crop.season} Season',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Crop details
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        crop.description,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textGrey,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Info Grid
                      _buildInfoGrid(crop),

                      const SizedBox(height: 20),

                      // Suitable Conditions
                      const Text(
                        'Growing Conditions',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildConditionsSection(crop),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.calendar_month,
                  label: 'Farming Calendar',
                  color: AppColors.accentBlue,
                  onTap: () {
                    Navigator.pushNamed(context, AppRoutes.farmingCalendar);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.science,
                  label: 'Fertilizer Plan',
                  color: AppColors.accentOrange,
                  onTap: () {
                    Navigator.pushNamed(context, AppRoutes.fertilizerPlanner);
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Change Crop Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.cropRecommendation);
              },
              icon: const Icon(Icons.swap_horiz),
              label: const Text('Change Crop'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryGreen,
                side: const BorderSide(color: AppColors.primaryGreen),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildInfoGrid(CropModel crop) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.schedule,
                  label: 'Duration',
                  value: '${crop.growingDurationDays} days',
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.water_drop,
                  label: 'Water Need',
                  value: crop.waterRequirement,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.landscape,
                  label: 'Min Land',
                  value: '${crop.minLandSize} acres',
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.trending_up,
                  label: 'Yield/Acre',
                  value: '${crop.expectedYieldPerAcre.toStringAsFixed(0)} kg',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: AppColors.primaryGreen),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: AppColors.textGrey),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildConditionsSection(CropModel crop) {
    return Column(
      children: [
        // Regions
        _buildConditionRow(
          icon: Icons.location_on,
          label: 'Suitable Regions',
          values: crop.suitableRegions,
        ),
        const SizedBox(height: 12),
        // Soil Types
        _buildConditionRow(
          icon: Icons.terrain,
          label: 'Soil Types',
          values: crop.suitableSoilTypes,
        ),
      ],
    );
  }

  Widget _buildConditionRow({
    required IconData icon,
    required String label,
    required List<String> values,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.primaryGreen),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: values
                    .map(
                      (v) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          v,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.primaryGreen,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoCropSelectedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.eco,
                size: 64,
                color: AppColors.primaryGreen,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Crop Selected',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Get AI-powered recommendations based on your farm conditions and select the best crop for your land.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textGrey,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: 'Get AI Recommendations',
              icon: Icons.psychology,
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.cropRecommendation);
              },
            ),
          ],
        ),
      ),
    );
  }
}

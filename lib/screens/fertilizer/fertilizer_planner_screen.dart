/// Fertilizer Planner Screen
///
/// Displays fertilizer schedule based on selected crop
/// Data is derived from the farming plan

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../core/services/firebase_service.dart';
import '../../models/farming_plan_model.dart';

class FertilizerPlannerScreen extends StatefulWidget {
  const FertilizerPlannerScreen({super.key});

  @override
  State<FertilizerPlannerScreen> createState() =>
      _FertilizerPlannerScreenState();
}

class _FertilizerPlannerScreenState extends State<FertilizerPlannerScreen> {
  final _firebaseService = FirebaseService();

  FarmingPlanModel? _farmingPlan;
  List<FarmingActivity> _fertilizerActivities = [];
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

      // Load farming plan
      final plan = await _firebaseService.getFarmingPlan(uid);

      // Extract fertilizer activities
      List<FarmingActivity> fertilizerActivities = [];
      if (plan != null) {
        fertilizerActivities = plan.activities
            .where((a) => a.type == ActivityType.fertilizer)
            .toList();
      }

      if (mounted) {
        setState(() {
          _farmingPlan = plan;
          _fertilizerActivities = fertilizerActivities;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Fertilizer Planner'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryGreen),
            )
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_farmingPlan == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.science_outlined,
                size: 80,
                color: AppColors.textGrey,
              ),
              const SizedBox(height: 16),
              const Text(
                'No fertilizer plan available',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textGrey,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Select a crop first to get your fertilizer schedule',
                style: TextStyle(fontSize: 14, color: AppColors.textGrey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.cropRecommendation);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                ),
                child: const Text('Select a Crop'),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Crop info card
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.accentOrange.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.science,
                      color: AppColors.accentOrange,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Fertilizer Schedule',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'For ${_farmingPlan!.cropName}',
                          style: const TextStyle(color: AppColors.textGrey),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_fertilizerActivities.length} applications',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Fertilizer Tips Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.accentOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.accentOrange.withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: AppColors.accentOrange,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Fertilizer Tips',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accentOrange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildTipItem('Apply fertilizer early morning or late evening'),
                _buildTipItem('Ensure soil is moist before application'),
                _buildTipItem('Avoid fertilizer application before heavy rain'),
                _buildTipItem('Follow recommended dosage for best results'),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Schedule title
          const Text(
            'Application Schedule',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 16),

          // Fertilizer activities list
          if (_fertilizerActivities.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No fertilizer applications scheduled',
                  style: TextStyle(color: AppColors.textGrey),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _fertilizerActivities.length,
              itemBuilder: (context, index) {
                final activity = _fertilizerActivities[index];
                return _buildFertilizerCard(activity, index);
              },
            ),

          const SizedBox(height: 24),

          // Recommended fertilizers section
          const Text(
            'Recommended Fertilizers',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 16),

          _buildFertilizerRecommendationCard(
            'NPK (Nitrogen-Phosphorus-Potassium)',
            'Balanced nutrient supply for overall plant growth',
            'Apply 50kg/acre',
            Icons.grass,
          ),

          const SizedBox(height: 12),

          _buildFertilizerRecommendationCard(
            'Urea (Nitrogen)',
            'Promotes leafy growth and green color',
            'Apply 25kg/acre as top dressing',
            Icons.eco,
          ),

          const SizedBox(height: 12),

          _buildFertilizerRecommendationCard(
            'DAP (Di-ammonium Phosphate)',
            'Supports root development and flowering',
            'Apply 30kg/acre at sowing',
            Icons.spa,
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildTipItem(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: AppColors.accentOrange)),
          Expanded(
            child: Text(
              tip,
              style: const TextStyle(fontSize: 13, color: AppColors.textDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFertilizerCard(FarmingActivity activity, int index) {
    final isPast = activity.date.isBefore(DateTime.now());
    final daysUntil = activity.date.difference(DateTime.now()).inDays;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Step indicator
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isPast ? AppColors.primaryGreen : AppColors.accentOrange,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: isPast
                    ? const Icon(Icons.check, color: Colors.white)
                    : Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 16),

            // Activity details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isPast
                          ? AppColors.textGrey
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    activity.description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textGrey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: AppColors.accentOrange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${activity.date.day}/${activity.date.month}/${activity.date.year}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.accentOrange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Status
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isPast
                    ? AppColors.primaryGreen.withOpacity(0.1)
                    : daysUntil <= 7
                    ? AppColors.accentOrange.withOpacity(0.1)
                    : AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isPast
                    ? 'Done'
                    : daysUntil <= 0
                    ? 'Today!'
                    : 'In $daysUntil days',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isPast
                      ? AppColors.primaryGreen
                      : daysUntil <= 7
                      ? AppColors.accentOrange
                      : AppColors.textGrey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFertilizerRecommendationCard(
    String name,
    String description,
    String dosage,
    IconData icon,
  ) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primaryGreen),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textGrey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dosage,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

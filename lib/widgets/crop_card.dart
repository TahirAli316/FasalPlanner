/// Crop Card Widget
///
/// Displays crop information in a card format
/// Used for showing recommended crops and selected crops

import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../models/crop_model.dart';
import '../core/services/ml_crop_service.dart';

/// Standard crop card showing basic crop info
class CropCard extends StatelessWidget {
  final CropModel crop;
  final VoidCallback? onTap;
  final bool isSelected;

  const CropCard({
    super.key,
    required this.crop,
    this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isSelected ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isSelected
            ? const BorderSide(color: AppColors.primaryGreen, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Crop icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    crop.iconName,
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Crop details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      crop.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      crop.description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textGrey,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildTag('${crop.growingDurationDays} days'),
                        const SizedBox(width: 8),
                        _buildTag(crop.waterRequirement),
                      ],
                    ),
                  ],
                ),
              ),

              // Selection indicator
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: AppColors.primaryGreen,
                  size: 28,
                )
              else if (onTap != null)
                const Icon(
                  Icons.arrow_forward_ios,
                  color: AppColors.textGrey,
                  size: 16,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          color: AppColors.primaryGreen,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// Recommendation card with suitability score
class CropRecommendationCard extends StatelessWidget {
  final CropRecommendation recommendation;
  final VoidCallback? onSelect;

  const CropRecommendationCard({
    super.key,
    required this.recommendation,
    this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                // Crop icon
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.backgroundLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      recommendation.crop.iconName,
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Crop name and score
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recommendation.crop.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            recommendation.suitabilityLevel,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _getScoreColor(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '(${recommendation.scorePercentage})',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textGrey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Score indicator
                _buildScoreIndicator(),
              ],
            ),

            const Divider(height: 24),

            // Reasons list
            ...recommendation.reasons.map(
              (reason) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  reason,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Select button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onSelect,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'Select This Crop',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreIndicator() {
    return SizedBox(
      width: 50,
      height: 50,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: recommendation.suitabilityScore / 100,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(_getScoreColor()),
            strokeWidth: 6,
          ),
          Text(
            '${recommendation.suitabilityScore.toInt()}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: _getScoreColor(),
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor() {
    if (recommendation.suitabilityScore >= 80) return AppColors.primaryGreen;
    if (recommendation.suitabilityScore >= 60)
      return AppColors.primaryGreenLight;
    if (recommendation.suitabilityScore >= 40) return AppColors.accentOrange;
    return AppColors.accentRed;
  }
}

/// Small crop chip for displaying selected crop
class CropChip extends StatelessWidget {
  final CropModel crop;
  final VoidCallback? onRemove;

  const CropChip({super.key, required this.crop, this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Text(crop.iconName),
      label: Text(crop.name),
      deleteIcon: onRemove != null ? const Icon(Icons.close, size: 18) : null,
      onDeleted: onRemove,
      backgroundColor: AppColors.backgroundLight,
      labelStyle: const TextStyle(
        color: AppColors.primaryGreen,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

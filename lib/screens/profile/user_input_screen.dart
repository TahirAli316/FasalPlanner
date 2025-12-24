/// User Input Screen
///
/// Collects user's farm details:
/// - Region
/// - Land Size
/// - Soil Type
///
/// This data is used for crop recommendation

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/firebase_service.dart';
import '../../core/services/ml_crop_service.dart';
import '../../widgets/custom_button.dart';

class UserInputScreen extends StatefulWidget {
  const UserInputScreen({super.key});

  @override
  State<UserInputScreen> createState() => _UserInputScreenState();
}

class _UserInputScreenState extends State<UserInputScreen> {
  final _formKey = GlobalKey<FormState>();
  final _landSizeController = TextEditingController();
  final _firebaseService = FirebaseService();

  String? _selectedRegion;
  String? _selectedSoilType;
  bool _isLoading = false;

  final List<String> _regions = MLCropService.getAvailableRegions();
  final List<String> _soilTypes = MLCropService.getAvailableSoilTypes();

  @override
  void dispose() {
    _landSizeController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRegion == null || _selectedSoilType == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('User not logged in');

      await _firebaseService.updateUserFarmDetails(
        uid: uid,
        region: _selectedRegion!,
        landSize: double.parse(_landSizeController.text),
        soilType: _selectedSoilType!,
      );

      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
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
        title: const Text('Farm Details'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Center(
                child: Icon(
                  Icons.agriculture,
                  size: 80,
                  color: AppColors.primaryGreen,
                ),
              ),

              const SizedBox(height: 16),

              const Center(
                child: Text(
                  'Tell us about your farm',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              const Center(
                child: Text(
                  'This helps us provide better crop recommendations',
                  style: TextStyle(fontSize: 14, color: AppColors.textGrey),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 40),

              // Region Dropdown
              const Text(
                AppStrings.region,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedRegion,
                decoration: InputDecoration(
                  prefixIcon: const Icon(
                    Icons.location_on_outlined,
                    color: AppColors.primaryGreen,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.primaryGreen,
                      width: 2,
                    ),
                  ),
                ),
                hint: const Text('Select your region'),
                items: _regions.map((region) {
                  return DropdownMenuItem(value: region, child: Text(region));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedRegion = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a region';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Land Size Input
              const Text(
                AppStrings.landSize,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _landSizeController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  prefixIcon: const Icon(
                    Icons.square_foot_outlined,
                    color: AppColors.primaryGreen,
                  ),
                  suffixText: 'acres',
                  hintText: 'Enter land size',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.primaryGreen,
                      width: 2,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter land size';
                  }
                  final landSize = double.tryParse(value);
                  if (landSize == null || landSize <= 0) {
                    return 'Please enter a valid land size';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Soil Type Dropdown
              const Text(
                AppStrings.soilType,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedSoilType,
                decoration: InputDecoration(
                  prefixIcon: const Icon(
                    Icons.terrain_outlined,
                    color: AppColors.primaryGreen,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.primaryGreen,
                      width: 2,
                    ),
                  ),
                ),
                hint: const Text('Select soil type'),
                items: _soilTypes.map((soil) {
                  return DropdownMenuItem(value: soil, child: Text(soil));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSoilType = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a soil type';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 40),

              // Info card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.primaryGreen),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your farm details help our AI recommend the best crops for your conditions.',
                        style: TextStyle(
                          color: AppColors.primaryGreen,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Submit Button
              CustomButton(
                text: AppStrings.saveDetails,
                onPressed: _handleSubmit,
                isLoading: _isLoading,
              ),

              const SizedBox(height: 16),

              // Skip button (for existing users editing details)
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(
                      context,
                      AppRoutes.dashboard,
                    );
                  },
                  child: const Text(
                    'Skip for now',
                    style: TextStyle(color: AppColors.textGrey),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

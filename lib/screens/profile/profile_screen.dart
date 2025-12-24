/// Profile Screen
///
/// Shows user profile information
/// Provides logout functionality

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../core/services/firebase_service.dart';
import '../../models/user_model.dart';
import '../../widgets/custom_button.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _firebaseService = FirebaseService();
  UserModel? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final user = await _firebaseService.getUserData(uid);
      if (mounted) {
        setState(() {
          _user = user;
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentRed,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _firebaseService.logout();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.login,
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryGreen),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // Profile Avatar
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primaryGreen,
                        width: 3,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _user?.name.isNotEmpty == true
                            ? _user!.name[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // User Name
                  Text(
                    _user?.name ?? 'User',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // User Email
                  Text(
                    _user?.email ?? '',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textGrey,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Profile Info Cards
                  _buildInfoCard(
                    icon: Icons.person_outline,
                    title: 'Full Name',
                    value: _user?.name ?? 'Not set',
                  ),

                  _buildInfoCard(
                    icon: Icons.email_outlined,
                    title: 'Email',
                    value: _user?.email ?? 'Not set',
                  ),

                  _buildInfoCard(
                    icon: Icons.location_on_outlined,
                    title: 'Region',
                    value: _user?.region ?? 'Not set',
                  ),

                  _buildInfoCard(
                    icon: Icons.terrain_outlined,
                    title: 'Soil Type',
                    value: _user?.soilType ?? 'Not set',
                  ),

                  _buildInfoCard(
                    icon: Icons.square_foot_outlined,
                    title: 'Land Size',
                    value: _user?.landSize != null
                        ? '${_user!.landSize} acres'
                        : 'Not set',
                  ),

                  const SizedBox(height: 24),

                  // Edit Farm Details Button
                  CustomOutlinedButton(
                    text: 'Edit Farm Details',
                    icon: Icons.edit_outlined,
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.userInput);
                    },
                  ),

                  const SizedBox(height: 16),

                  // Logout Button
                  CustomButton(
                    text: 'Logout',
                    icon: Icons.logout,
                    backgroundColor: AppColors.accentRed,
                    onPressed: _handleLogout,
                  ),

                  const SizedBox(height: 32),

                  // App Version
                  const Text(
                    'FasalPlanner v1.0.0',
                    style: TextStyle(color: AppColors.textGrey, fontSize: 12),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Smart Weather-Based Farming Calendar',
                    style: TextStyle(color: AppColors.textGrey, fontSize: 12),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primaryGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primaryGreen),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

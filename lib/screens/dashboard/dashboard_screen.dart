/// Dashboard Screen
///
/// Main screen after login showing:
/// - Current weather information
/// - Quick navigation buttons
/// - User's selected crop info

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../core/services/firebase_service.dart';
import '../../core/services/weather_service.dart';
import '../../models/user_model.dart';
import '../../widgets/weather_card.dart';
import '../../widgets/custom_button.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with WidgetsBindingObserver, RouteAware {
  final _firebaseService = FirebaseService();
  final _weatherService = WeatherService();

  UserModel? _user;
  WeatherData? _weather;
  bool _isLoadingWeather = true;
  String? _weatherError;

  // Store selected crop in state to avoid FutureBuilder caching issues
  dynamic _selectedCrop;
  bool _isLoadingCrop = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadData(); // Reload when app comes to foreground
    }
  }

  Future<void> _loadData() async {
    await _loadUserData();
    await _loadSelectedCrop();
    await _loadWeather();
  }

  Future<void> _loadUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        final user = await _firebaseService.getUserData(uid);
        if (mounted) {
          setState(() {
            _user = user;
          });

          // Check if user has completed farm details
          if (user != null && !user.hasCompletedFarmDetails) {
            Navigator.pushReplacementNamed(context, AppRoutes.userInput);
          }
        }
      } catch (e) {
        // Handle permission error gracefully
        print('Error loading user data: $e');
      }
    }
  }

  Future<void> _loadSelectedCrop() async {
    if (_user?.selectedCropId == null) {
      if (mounted) {
        setState(() {
          _selectedCrop = null;
          _isLoadingCrop = false;
        });
      }
      return;
    }

    setState(() {
      _isLoadingCrop = true;
    });

    try {
      final crop = await _firebaseService.getCropById(_user!.selectedCropId!);
      if (mounted) {
        setState(() {
          _selectedCrop = crop;
          _isLoadingCrop = false;
        });
      }
    } catch (e) {
      print('Error loading selected crop: $e');
      if (mounted) {
        setState(() {
          _selectedCrop = null;
          _isLoadingCrop = false;
        });
      }
    }
  }

  Future<void> _loadWeather() async {
    setState(() {
      _isLoadingWeather = true;
      _weatherError = null;
    });

    try {
      // Use user's region or default city
      final city = _user?.region ?? 'Lahore';
      final weather = await _weatherService.getCurrentWeather(city);

      if (mounted) {
        setState(() {
          _weather = weather;
          _isLoadingWeather = false;
          _weatherError = null;
        });
      }
    } catch (e) {
      print('Weather loading error: $e');
      if (mounted) {
        setState(() {
          _isLoadingWeather = false;
          _weatherError = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.profile);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting
              if (_user != null)
                Text(
                  'Hello, ${_user!.name.split(' ').first}! 👋',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),

              const SizedBox(height: 8),

              const Text(
                'Check your farm\'s status today',
                style: TextStyle(fontSize: 14, color: AppColors.textGrey),
              ),

              const SizedBox(height: 24),

              // Weather Card
              const Text(
                'Current Weather',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 12),

              if (_isLoadingWeather)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(
                      color: AppColors.primaryGreen,
                    ),
                  ),
                )
              else if (_weather != null)
                WeatherCard(weather: _weather!, onRefresh: _loadWeather)
              else
                _buildWeatherErrorCard(),

              const SizedBox(height: 32),

              // Quick Actions
              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 16),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.1,
                children: [
                  QuickActionButton(
                    label: 'Crop\nRecommendation',
                    icon: Icons.eco,
                    onTap: () async {
                      await Navigator.pushNamed(
                        context,
                        AppRoutes.cropRecommendation,
                      );
                      // Reload data when returning from crop recommendation
                      _loadData();
                    },
                  ),
                  QuickActionButton(
                    label: 'Selected\nCrop',
                    icon: Icons.grass,
                    onTap: () async {
                      await Navigator.pushNamed(
                        context,
                        AppRoutes.cropSelection,
                      );
                      // Reload data when returning from crop selection
                      _loadData();
                    },
                  ),
                  QuickActionButton(
                    label: 'Farming\nCalendar',
                    icon: Icons.calendar_month,
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.farmingCalendar);
                    },
                  ),
                  QuickActionButton(
                    label: 'Fertilizer\nPlanner',
                    icon: Icons.science,
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.fertilizerPlanner);
                    },
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Selected Crop Info
              if (_user?.selectedCropId != null) ...[
                const Text(
                  'Your Selected Crop',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 12),

                if (_isLoadingCrop)
                  const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryGreen,
                    ),
                  )
                else if (_selectedCrop == null)
                  const Text('No crop selected')
                else
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      leading: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppColors.backgroundLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            _selectedCrop.iconName,
                            style: const TextStyle(fontSize: 28),
                          ),
                        ),
                      ),
                      title: Text(
                        _selectedCrop.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        '${_selectedCrop.growingDurationDays} days • ${_selectedCrop.season}',
                        style: const TextStyle(color: AppColors.textGrey),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: AppColors.primaryGreen,
                      ),
                      onTap: () {
                        Navigator.pushNamed(context, AppRoutes.farmingCalendar);
                      },
                    ),
                  ),
              ],

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherErrorCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.red.shade50,
        ),
        child: Column(
          children: [
            Icon(Icons.cloud_off, size: 48, color: Colors.red.shade300),
            const SizedBox(height: 12),
            const Text(
              'Failed to load weather',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _weatherError ?? 'Unknown error',
              style: TextStyle(fontSize: 12, color: Colors.red.shade700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadWeather,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

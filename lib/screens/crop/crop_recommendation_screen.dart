/// Crop Recommendation Screen
///
/// Uses TFLite ML model for crop recommendation based on:
/// - Soil nutrients (N, P, K)
/// - Temperature & Humidity (from weather API)
/// - Soil pH
/// - Rainfall
///
/// Displays AI-powered crop recommendations with confidence scores

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../core/services/firebase_service.dart';
import '../../core/services/ml_crop_service.dart';
import '../../core/services/tflite_crop_service.dart';
import '../../core/services/weather_service.dart';
import '../../models/user_model.dart';
import '../../models/crop_model.dart';
import '../../models/farming_plan_model.dart';
import '../../widgets/crop_card.dart';

class CropRecommendationScreen extends StatefulWidget {
  const CropRecommendationScreen({super.key});

  @override
  State<CropRecommendationScreen> createState() =>
      _CropRecommendationScreenState();
}

class _CropRecommendationScreenState extends State<CropRecommendationScreen> {
  final _firebaseService = FirebaseService();
  final _mlCropService = MLCropService();
  final _tfliteService = TFLiteCropService();
  final _weatherService = WeatherService();
  final _formKey = GlobalKey<FormState>();

  // Text controllers for user input
  final _nitrogenController = TextEditingController(text: '50');
  final _phosphorusController = TextEditingController(text: '50');
  final _potassiumController = TextEditingController(text: '50');
  final _temperatureController = TextEditingController(text: '25');
  final _humidityController = TextEditingController(text: '60');
  final _phController = TextEditingController(text: '6.5');
  final _rainfallController = TextEditingController(text: '200');

  UserModel? _user;
  List<CropRecommendation> _recommendations = [];
  List<CropPrediction> _mlPredictions = [];
  bool _isLoading = true;
  bool _useMLModel = true;
  bool _showInputForm = true;
  bool _hasRunPrediction = false;
  WeatherData? _weather;

  // Input values for ML model
  double _nitrogen = 50;
  double _phosphorus = 50;
  double _potassium = 50;
  double _temperature = 25;
  double _humidity = 60;
  double _ph = 6.5;
  double _rainfall = 200;

  @override
  void initState() {
    super.initState();
    _initializeAndLoad();
  }

  Future<void> _initializeAndLoad() async {
    // Load TFLite model
    await _tfliteService.loadModel();
    await _loadRecommendations();
  }

  @override
  void dispose() {
    _nitrogenController.dispose();
    _phosphorusController.dispose();
    _potassiumController.dispose();
    _temperatureController.dispose();
    _humidityController.dispose();
    _phController.dispose();
    _rainfallController.dispose();
    _tfliteService.dispose();
    super.dispose();
  }

  Future<void> _loadRecommendations() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get user data
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final user = await _firebaseService.getUserData(uid);
      if (user == null || !user.hasCompletedFarmDetails) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, AppRoutes.userInput);
        }
        return;
      }

      _user = user;

      // Get weather data for temperature and humidity (as suggestions)
      try {
        _weather = await _weatherService.getCurrentWeather(
          user.region ?? 'Lahore',
        );
        // Set weather values as defaults in controllers
        _temperatureController.text = _weather!.temperature.toStringAsFixed(1);
        _humidityController.text = _weather!.humidity.toString();
        _temperature = _weather!.temperature;
        _humidity = _weather!.humidity.toDouble();
      } catch (e) {
        print('Weather fetch failed, using defaults: $e');
      }

      // Get soil values based on soil type (as suggestions)
      final soilValues = TFLiteCropService.getDefaultSoilValues(
        user.soilType ?? 'Loamy',
      );
      _nitrogenController.text = soilValues['N']!.toStringAsFixed(0);
      _phosphorusController.text = soilValues['P']!.toStringAsFixed(0);
      _potassiumController.text = soilValues['K']!.toStringAsFixed(0);
      _phController.text = soilValues['pH']!.toStringAsFixed(1);

      _nitrogen = soilValues['N']!;
      _phosphorus = soilValues['P']!;
      _potassium = soilValues['K']!;
      _ph = soilValues['pH']!;

      // Get estimated rainfall based on region (as suggestion)
      final rainfall = TFLiteCropService.getEstimatedRainfall(
        user.region ?? 'Punjab',
      );
      _rainfallController.text = rainfall.toStringAsFixed(0);
      _rainfall = rainfall;

      // Also get rule-based recommendations as fallback
      List<CropModel> availableCrops;
      try {
        availableCrops = await _firebaseService.getAllCrops();
        if (availableCrops.isEmpty) {
          availableCrops = MLCropService.getDefaultCrops();
        }
      } catch (e) {
        availableCrops = MLCropService.getDefaultCrops();
      }

      _recommendations = _mlCropService.recommendCrops(
        region: user.region!,
        soilType: user.soilType!,
        landSize: user.landSize!,
        availableCrops: availableCrops,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading recommendations: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _runPrediction() {
    if (!_formKey.currentState!.validate()) return;

    // Parse values from controllers
    _nitrogen = double.tryParse(_nitrogenController.text) ?? 50;
    _phosphorus = double.tryParse(_phosphorusController.text) ?? 50;
    _potassium = double.tryParse(_potassiumController.text) ?? 50;
    _temperature = double.tryParse(_temperatureController.text) ?? 25;
    _humidity = double.tryParse(_humidityController.text) ?? 60;
    _ph = double.tryParse(_phController.text) ?? 6.5;
    _rainfall = double.tryParse(_rainfallController.text) ?? 200;

    // Run ML prediction
    if (_tfliteService.isModelLoaded) {
      _mlPredictions = _tfliteService.getTopRecommendations(
        nitrogen: _nitrogen,
        phosphorus: _phosphorus,
        potassium: _potassium,
        temperature: _temperature,
        humidity: _humidity,
        ph: _ph,
        rainfall: _rainfall,
        topN: 8,
      );
      print('✅ Got ${_mlPredictions.length} ML predictions');
    }

    setState(() {
      _showInputForm = false;
      _hasRunPrediction = true;
    });
  }

  Future<void> _selectCrop(CropModel crop) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 12),
                Text('Generating AI farming plan...'),
              ],
            ),
            duration: Duration(seconds: 10),
            backgroundColor: AppColors.primaryGreen,
          ),
        );
      }

      // Save selected crop to Firestore
      await _firebaseService.updateSelectedCrop(uid: uid, cropId: crop.id);

      // Generate AI-powered farming plan
      final plan = await FarmingPlanModel.generateAIPlan(
        cropId: crop.id,
        cropName: crop.name,
        userId: uid,
        growingDurationDays: crop.growingDurationDays,
        region: _user?.region ?? 'Punjab',
        soilType: _user?.soilType ?? 'Loamy',
        landSize: _user?.landSize ?? 1.0,
      );

      await _firebaseService.saveFarmingPlan(plan);

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${crop.name} selected! AI farming plan generated.'),
            backgroundColor: AppColors.primaryGreen,
          ),
        );
        Navigator.pushReplacementNamed(context, AppRoutes.farmingCalendar);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error selecting crop: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Crop Recommendation'),
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
    final hasMLPredictions = _mlPredictions.isNotEmpty;
    final hasRuleBased = _recommendations.isNotEmpty;

    // Show input form first, then results after prediction
    if (_showInputForm) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User's farm info summary
            if (_user != null) _buildFarmInfoCard(),
            const SizedBox(height: 16),
            // Input Form
            _buildInputForm(),
          ],
        ),
      );
    }

    if (!_hasRunPrediction && !hasMLPredictions && !hasRuleBased) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 80, color: AppColors.textGrey),
            const SizedBox(height: 16),
            const Text(
              'No recommendations found',
              style: TextStyle(fontSize: 18, color: AppColors.textGrey),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try updating your farm details',
              style: TextStyle(fontSize: 14, color: AppColors.textGrey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.userInput);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
              ),
              child: const Text('Update Farm Details'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User's farm info summary
          if (_user != null) _buildFarmInfoCard(),

          const SizedBox(height: 16),

          // ML Model Input Summary
          _buildMLInputCard(),

          const SizedBox(height: 16),

          // Toggle between ML and Rule-based
          _buildToggleCard(hasMLPredictions),

          const SizedBox(height: 24),

          // ML Predictions
          if (_useMLModel && hasMLPredictions) ...[
            _buildSectionHeader(
              '🤖 AI Model Predictions',
              'Based on TensorFlow Lite model',
            ),
            const SizedBox(height: 16),
            _buildMLPredictionsList(),
          ],

          // Rule-based recommendations
          if (!_useMLModel && hasRuleBased) ...[
            _buildSectionHeader(
              '📊 Rule-Based Recommendations',
              'Based on region, soil type, and land size',
            ),
            const SizedBox(height: 16),
            _buildRuleBasedList(),
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildFarmInfoCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Farm Details',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoChip(Icons.location_on, _user!.region!),
                _buildInfoChip(Icons.terrain, _user!.soilType!),
                _buildInfoChip(Icons.square_foot, '${_user!.landSize} acres'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMLInputCard() {
    if (_showInputForm) {
      return _buildInputForm();
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.science, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'ML Model Input Values',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _showInputForm = true;
                    });
                  },
                  icon: Icon(Icons.edit, size: 16, color: Colors.blue.shade700),
                  label: Text(
                    'Edit',
                    style: TextStyle(color: Colors.blue.shade700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildInputChip('N', _nitrogen.toStringAsFixed(0)),
                _buildInputChip('P', _phosphorus.toStringAsFixed(0)),
                _buildInputChip('K', _potassium.toStringAsFixed(0)),
                _buildInputChip('Temp', '${_temperature.toStringAsFixed(1)}°C'),
                _buildInputChip('Humidity', '${_humidity.toStringAsFixed(0)}%'),
                _buildInputChip('pH', _ph.toStringAsFixed(1)),
                _buildInputChip('Rain', '${_rainfall.toStringAsFixed(0)}mm'),
              ],
            ),
            if (_weather != null) ...[
              const SizedBox(height: 8),
              Text(
                '* Temperature & Humidity from live weather data',
                style: TextStyle(fontSize: 11, color: Colors.blue.shade600),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInputForm() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.edit_note, color: Colors.green.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Enter Soil & Weather Data',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Values are pre-filled based on your region and soil type. Adjust as needed.',
                style: TextStyle(fontSize: 12, color: Colors.green.shade600),
              ),
              const SizedBox(height: 16),

              // NPK Section
              Text(
                'Soil Nutrients (NPK)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.green.shade800,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildInputField(
                      controller: _nitrogenController,
                      label: 'Nitrogen (N)',
                      hint: 'mg/kg',
                      icon: Icons.grass,
                      min: 0,
                      max: 140,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildInputField(
                      controller: _phosphorusController,
                      label: 'Phosphorus (P)',
                      hint: 'mg/kg',
                      icon: Icons.science,
                      min: 5,
                      max: 145,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildInputField(
                      controller: _potassiumController,
                      label: 'Potassium (K)',
                      hint: 'mg/kg',
                      icon: Icons.eco,
                      min: 5,
                      max: 205,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Weather Section
              Text(
                'Weather Conditions',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.green.shade800,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildInputField(
                      controller: _temperatureController,
                      label: 'Temp (°C)',
                      hint: '°C',
                      icon: Icons.thermostat,
                      min: 8,
                      max: 44,
                      isDecimal: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildInputField(
                      controller: _humidityController,
                      label: 'Humidity (%)',
                      hint: '%',
                      icon: Icons.water_drop,
                      min: 14,
                      max: 100,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildInputField(
                      controller: _rainfallController,
                      label: 'Rainfall (mm)',
                      hint: 'mm/year',
                      icon: Icons.umbrella,
                      min: 20,
                      max: 300,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // pH Section
              Text(
                'Soil pH',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.green.shade800,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 150,
                child: _buildInputField(
                  controller: _phController,
                  label: 'pH Level',
                  hint: '0-14',
                  icon: Icons.water,
                  min: 3.5,
                  max: 9.5,
                  isDecimal: true,
                ),
              ),

              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _showInputForm = false;
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey.shade700,
                        side: BorderSide(color: Colors.grey.shade400),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _runPrediction,
                      icon: const Icon(Icons.psychology),
                      label: const Text('Get AI Recommendations'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required double min,
    required double max,
    bool isDecimal = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: isDecimal),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 18),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.primaryGreen, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      style: const TextStyle(fontSize: 14),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Required';
        }
        final num = double.tryParse(value);
        if (num == null) {
          return 'Invalid';
        }
        if (num < min || num > max) {
          return '$min-$max';
        }
        return null;
      },
    );
  }

  Widget _buildInputChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.blue.shade800,
        ),
      ),
    );
  }

  Widget _buildToggleCard(bool hasML) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: hasML ? () => setState(() => _useMLModel = true) : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _useMLModel
                        ? AppColors.primaryGreen
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.psychology,
                        color: _useMLModel ? Colors.white : Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'AI Model',
                        style: TextStyle(
                          color: _useMLModel ? Colors.white : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _useMLModel = false),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: !_useMLModel
                        ? AppColors.primaryGreen
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.rule,
                        color: !_useMLModel ? Colors.white : Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Rule-Based',
                        style: TextStyle(
                          color: !_useMLModel ? Colors.white : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppColors.primaryGreen.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMLPredictionsList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _mlPredictions.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final prediction = _mlPredictions[index];
        return _buildMLPredictionCard(prediction, index + 1);
      },
    );
  }

  Widget _buildMLPredictionCard(CropPrediction prediction, int rank) {
    final isTopPick = rank <= 3;

    return Card(
      elevation: isTopPick ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isTopPick
            ? const BorderSide(color: AppColors.primaryGreen, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => _selectMLCrop(prediction),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Rank badge
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isTopPick
                      ? AppColors.primaryGreen
                      : Colors.grey.shade300,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '#$rank',
                    style: TextStyle(
                      color: isTopPick ? Colors.white : Colors.grey.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Crop icon
              Text(prediction.icon, style: const TextStyle(fontSize: 36)),
              const SizedBox(width: 12),
              // Crop info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prediction.cropName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreen.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            prediction.season,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.primaryGreen,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Confidence score
              Column(
                children: [
                  Text(
                    '${prediction.confidence.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _getConfidenceColor(prediction.confidence),
                    ),
                  ),
                  const Text(
                    'confidence',
                    style: TextStyle(fontSize: 10, color: AppColors.textGrey),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: AppColors.textGrey),
            ],
          ),
        ),
      ),
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 70) return Colors.green;
    if (confidence >= 40) return Colors.orange;
    return Colors.red;
  }

  Future<void> _selectMLCrop(CropPrediction prediction) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 12),
                Text('Generating AI farming plan...'),
              ],
            ),
            duration: Duration(seconds: 10),
            backgroundColor: AppColors.primaryGreen,
          ),
        );
      }

      // Create a CropModel from prediction
      final crop = CropModel(
        id: prediction.cropKey,
        name: prediction.cropName,
        description: 'AI recommended crop: ${prediction.cropName}',
        season: prediction.season,
        growingDurationDays: _getGrowingDuration(prediction.cropKey),
        suitableRegions: [_user?.region ?? 'Punjab'],
        suitableSoilTypes: [_user?.soilType ?? 'Loamy'],
        minLandSize: 0.5,
        expectedYieldPerAcre: 20.0,
        waterRequirement: 'Medium',
      );

      await _firebaseService.updateSelectedCrop(uid: uid, cropId: crop.id);

      // Generate AI-powered farming plan
      final plan = await FarmingPlanModel.generateAIPlan(
        cropId: crop.id,
        cropName: crop.name,
        userId: uid,
        growingDurationDays: crop.growingDurationDays,
        region: _user?.region ?? 'Punjab',
        soilType: _user?.soilType ?? 'Loamy',
        landSize: _user?.landSize ?? 1.0,
      );

      await _firebaseService.saveFarmingPlan(plan);

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${crop.name} selected! AI farming plan generated.'),
            backgroundColor: AppColors.primaryGreen,
          ),
        );
        Navigator.pushReplacementNamed(context, AppRoutes.farmingCalendar);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  int _getGrowingDuration(String cropKey) {
    const durations = {
      'rice': 120,
      'wheat': 150,
      'maize': 90,
      'cotton': 180,
      'chickpea': 100,
      'lentil': 110,
      'mungbean': 70,
      'blackgram': 80,
      'pigeonpeas': 150,
      'kidneybeans': 90,
      'mothbeans': 75,
      'banana': 365,
      'mango': 120,
      'grapes': 180,
      'watermelon': 85,
      'muskmelon': 80,
      'apple': 150,
      'orange': 280,
      'papaya': 270,
      'coconut': 365,
      'coffee': 270,
      'jute': 120,
      'pomegranate': 180,
    };
    return durations[cropKey] ?? 100;
  }

  Widget _buildRuleBasedList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _recommendations.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final recommendation = _recommendations[index];
        return CropRecommendationCard(
          recommendation: recommendation,
          onSelect: () => _selectCrop(recommendation.crop),
        );
      },
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primaryGreen, size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

/// Gemini AI Service for FasalPlanner
///
/// Uses Google Gemini API to generate intelligent farming plans
/// and provide agricultural guidance

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/farming_plan_model.dart';

class GeminiService {
  // Gemini API Key - Replace with your actual API key
  static const String _apiKey = 'AIzaSyDdK_vmF6RLUX2iV3GqNhAy2iwH79OG1vk';
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

  /// Generate a farming plan using Gemini AI
  static Future<List<FarmingActivity>> generateFarmingPlan({
    required String cropName,
    required String region,
    required String soilType,
    required double landSize,
    required int growingDurationDays,
    DateTime? startDate,
  }) async {
    final sowingDate = startDate ?? DateTime.now();

    final prompt =
        '''
You are an agricultural expert. Generate a detailed weekly farming calendar for:
- Crop: $cropName
- Region: $region (Pakistan)
- Soil Type: $soilType
- Land Size: $landSize acres
- Growing Duration: $growingDurationDays days
- Sowing Date: ${sowingDate.day}/${sowingDate.month}/${sowingDate.year}

Generate 12-15 farming activities with EXACT dates. Each activity should include:
1. title (short, clear)
2. description (practical advice, 1-2 sentences)
3. daysFromSowing (number of days from sowing date, can be negative for preparation)
4. type (one of: preparation, sowing, irrigation, fertilizer, pestControl, maintenance, harvesting)

Consider local Pakistani farming practices, weather patterns, and soil conditions.

RESPOND ONLY WITH A VALID JSON ARRAY in this exact format, no other text:
[
  {"title": "Activity Name", "description": "What to do", "daysFromSowing": -7, "type": "preparation"},
  {"title": "Sowing", "description": "Plant seeds", "daysFromSowing": 0, "type": "sowing"}
]
''';

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt},
              ],
            },
          ],
          'generationConfig': {'temperature': 0.7, 'maxOutputTokens': 2048},
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text =
            data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';

        print('📝 Gemini Response: $text');

        // Parse the JSON response
        final activities = _parseActivitiesFromResponse(text, sowingDate);
        if (activities.isNotEmpty) {
          print('✅ Generated ${activities.length} activities with Gemini AI');
          return activities;
        }
      } else {
        print('❌ Gemini API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Gemini Service Error: $e');
    }

    // Return fallback activities if API fails
    return _getFallbackActivities(cropName, sowingDate, growingDurationDays);
  }

  /// Parse activities from Gemini response
  static List<FarmingActivity> _parseActivitiesFromResponse(
    String response,
    DateTime sowingDate,
  ) {
    try {
      // Extract JSON array from response
      final jsonMatch = RegExp(r'\[[\s\S]*\]').firstMatch(response);
      if (jsonMatch == null) {
        print('❌ No JSON array found in response');
        return [];
      }

      final jsonString = jsonMatch.group(0)!;
      final List<dynamic> activitiesJson = jsonDecode(jsonString);

      return activitiesJson.asMap().entries.map((entry) {
        final index = entry.key;
        final a = entry.value;
        final daysFromSowing = a['daysFromSowing'] ?? 0;
        final activityDate = sowingDate.add(Duration(days: daysFromSowing));

        return FarmingActivity(
          id: '${index + 1}',
          title: a['title'] ?? 'Activity ${index + 1}',
          description: a['description'] ?? '',
          date: activityDate,
          type: _parseActivityType(a['type'] ?? 'maintenance'),
          isCompleted: false,
        );
      }).toList();
    } catch (e) {
      print('❌ Error parsing Gemini response: $e');
      return [];
    }
  }

  /// Parse activity type from string
  static ActivityType _parseActivityType(String type) {
    switch (type.toLowerCase()) {
      case 'preparation':
        return ActivityType.preparation;
      case 'sowing':
        return ActivityType.sowing;
      case 'irrigation':
        return ActivityType.irrigation;
      case 'fertilizer':
        return ActivityType.fertilizer;
      case 'pestcontrol':
        return ActivityType.pestControl;
      case 'maintenance':
        return ActivityType.maintenance;
      case 'harvesting':
        return ActivityType.harvesting;
      default:
        return ActivityType.maintenance;
    }
  }

  /// Fallback activities if Gemini API fails
  static List<FarmingActivity> _getFallbackActivities(
    String cropName,
    DateTime sowingDate,
    int growingDurationDays,
  ) {
    final harvest = sowingDate.add(Duration(days: growingDurationDays));

    return [
      FarmingActivity(
        id: '1',
        title: 'Land Preparation',
        description:
            'Prepare the land by plowing, leveling, and removing debris',
        date: sowingDate.subtract(const Duration(days: 7)),
        type: ActivityType.preparation,
        isCompleted: false,
      ),
      FarmingActivity(
        id: '2',
        title: 'Soil Testing',
        description: 'Test soil pH and nutrient levels before sowing',
        date: sowingDate.subtract(const Duration(days: 5)),
        type: ActivityType.preparation,
        isCompleted: false,
      ),
      FarmingActivity(
        id: '3',
        title: 'Sowing $cropName',
        description:
            'Sow seeds at appropriate depth and spacing for optimal growth',
        date: sowingDate,
        type: ActivityType.sowing,
        isCompleted: false,
      ),
      FarmingActivity(
        id: '4',
        title: 'First Irrigation',
        description: 'Light irrigation immediately after sowing',
        date: sowingDate.add(const Duration(days: 1)),
        type: ActivityType.irrigation,
        isCompleted: false,
      ),
      FarmingActivity(
        id: '5',
        title: 'Germination Check',
        description: 'Check for seed germination and replant if needed',
        date: sowingDate.add(const Duration(days: 7)),
        type: ActivityType.maintenance,
        isCompleted: false,
      ),
      FarmingActivity(
        id: '6',
        title: 'First Weeding',
        description: 'Remove weeds to reduce competition for nutrients',
        date: sowingDate.add(const Duration(days: 14)),
        type: ActivityType.maintenance,
        isCompleted: false,
      ),
      FarmingActivity(
        id: '7',
        title: 'Basal Fertilizer Application',
        description: 'Apply nitrogen and phosphorus fertilizers',
        date: sowingDate.add(const Duration(days: 21)),
        type: ActivityType.fertilizer,
        isCompleted: false,
      ),
      FarmingActivity(
        id: '8',
        title: 'Second Irrigation',
        description: 'Deep irrigation for root development',
        date: sowingDate.add(const Duration(days: 28)),
        type: ActivityType.irrigation,
        isCompleted: false,
      ),
      FarmingActivity(
        id: '9',
        title: 'Pest Inspection',
        description: 'Check for pest infestation and diseases',
        date: sowingDate.add(const Duration(days: 35)),
        type: ActivityType.pestControl,
        isCompleted: false,
      ),
      FarmingActivity(
        id: '10',
        title: 'Top Dressing Fertilizer',
        description: 'Apply second dose of nitrogen fertilizer',
        date: sowingDate.add(const Duration(days: 45)),
        type: ActivityType.fertilizer,
        isCompleted: false,
      ),
      FarmingActivity(
        id: '11',
        title: 'Flowering Stage Care',
        description: 'Ensure adequate water and nutrients during flowering',
        date: sowingDate.add(
          Duration(days: (growingDurationDays * 0.5).round()),
        ),
        type: ActivityType.irrigation,
        isCompleted: false,
      ),
      FarmingActivity(
        id: '12',
        title: 'Pre-Harvest Assessment',
        description: 'Check crop maturity indicators',
        date: harvest.subtract(const Duration(days: 7)),
        type: ActivityType.maintenance,
        isCompleted: false,
      ),
      FarmingActivity(
        id: '13',
        title: 'Harvesting',
        description: 'Harvest the mature $cropName crop',
        date: harvest,
        type: ActivityType.harvesting,
        isCompleted: false,
      ),
    ];
  }

  /// Get farming advice for a specific query
  static Future<String> getFarmingAdvice({
    required String query,
    String? cropName,
    String? region,
  }) async {
    final contextInfo = cropName != null
        ? 'Context: Growing $cropName in ${region ?? "Pakistan"}.\n\n'
        : '';

    final prompt =
        '''
You are an expert agricultural advisor for Pakistani farmers. 
$contextInfo
User Question: $query

Provide a helpful, practical answer in 2-3 short paragraphs. Focus on:
- Local farming practices
- Cost-effective solutions
- Seasonal considerations
''';

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt},
              ],
            },
          ],
          'generationConfig': {'temperature': 0.7, 'maxOutputTokens': 500},
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['candidates']?[0]?['content']?['parts']?[0]?['text'] ??
            'Unable to get advice at this time.';
      }
    } catch (e) {
      print('❌ Gemini Advice Error: $e');
    }

    return 'Unable to connect to AI service. Please check your internet connection.';
  }
}

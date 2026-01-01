/// Weather Service
///
/// Fetches current weather data from OpenWeatherMap API
/// Provides weather information for the user's region

import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  // OpenWeatherMap API key
  static const String _apiKey = 'cd1f9aaceda42e95de6693c813756853';
  static const String _baseUrl =
      'https://api.openweathermap.org/data/2.5/weather';

  // Map Pakistani provinces to their capital/major cities for weather lookup
  static const Map<String, String> _provinceToCityMap = {
    'KPK': 'Peshawar',
    'Khyber Pakhtunkhwa': 'Peshawar',
    'Punjab': 'Lahore',
    'Sindh': 'Karachi',
    'Balochistan': 'Quetta',
    'Gilgit-Baltistan': 'Gilgit',
    'Azad Kashmir': 'Muzaffarabad',
    'Islamabad': 'Islamabad',
  };

  /// Convert province name to city name for weather API
  String _getWeatherCity(String location) {
    // Check if location is a province name
    final cityName = _provinceToCityMap[location];
    if (cityName != null) {
      return cityName;
    }
    // If not a province, assume it's already a city name
    return location;
  }

  /// Fetch current weather by city name
  Future<WeatherData> getCurrentWeather(String city) async {
    try {
      // Convert province to city if needed
      final weatherCity = _getWeatherCity(city);
      final url = Uri.parse(
        '$_baseUrl?q=$weatherCity,PK&appid=$_apiKey&units=metric',
      );
      print('Fetching weather from: $url'); // Debug log

      final response = await http
          .get(url)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw WeatherException(
                'Connection timeout. Please check your internet.',
              );
            },
          );

      print('Weather API Response Status: ${response.statusCode}'); // Debug log
      print('Weather API Response Body: ${response.body}'); // Debug log

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return WeatherData.fromJson(data);
      } else if (response.statusCode == 401) {
        throw WeatherException(
          'Invalid API key. Please check your OpenWeatherMap API key.',
        );
      } else if (response.statusCode == 404) {
        throw WeatherException(
          'City "$city" not found. Please check the city name.',
        );
      } else {
        final errorData = json.decode(response.body);
        throw WeatherException(
          errorData['message'] ?? 'Failed to fetch weather data',
        );
      }
    } on WeatherException {
      rethrow;
    } catch (e) {
      print('Weather API Error: $e'); // Debug log
      throw WeatherException('Failed to fetch weather: ${e.toString()}');
    }
  }

  /// Fetch current weather by coordinates (more accurate for real-time location)
  Future<WeatherData> getCurrentWeatherByCoords(double lat, double lon) async {
    try {
      final url = Uri.parse(
        '$_baseUrl?lat=$lat&lon=$lon&appid=$_apiKey&units=metric',
      );
      print('Fetching weather by coords from: $url'); // Debug log

      final response = await http
          .get(url)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw WeatherException(
                'Connection timeout. Please check your internet.',
              );
            },
          );

      print('Weather API Response Status: ${response.statusCode}'); // Debug log

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return WeatherData.fromJson(data);
      } else if (response.statusCode == 401) {
        throw WeatherException(
          'Invalid API key. Please check your OpenWeatherMap API key.',
        );
      } else {
        final errorData = json.decode(response.body);
        throw WeatherException(
          errorData['message'] ?? 'Failed to fetch weather data',
        );
      }
    } on WeatherException {
      rethrow;
    } catch (e) {
      print('Weather API Error: $e'); // Debug log
      throw WeatherException('Failed to fetch weather: ${e.toString()}');
    }
  }

  /// Get weather icon URL
  static String getIconUrl(String iconCode) {
    return 'https://openweathermap.org/img/wn/$iconCode@2x.png';
  }
}

/// Weather Data Model
class WeatherData {
  final String cityName;
  final double temperature;
  final double feelsLike;
  final int humidity;
  final String condition;
  final String description;
  final String iconCode;
  final double windSpeed;
  final int pressure;
  final int visibility;
  final DateTime lastUpdated;

  WeatherData({
    required this.cityName,
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.condition,
    required this.description,
    required this.iconCode,
    required this.windSpeed,
    required this.pressure,
    required this.visibility,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  /// Parse weather data from JSON
  factory WeatherData.fromJson(Map<String, dynamic> json) {
    final main = json['main'];
    final weather = json['weather'][0];
    final wind = json['wind'];

    return WeatherData(
      cityName: json['name'] ?? 'Unknown',
      temperature: (main['temp'] ?? 0).toDouble(),
      feelsLike: (main['feels_like'] ?? 0).toDouble(),
      humidity: main['humidity'] ?? 0,
      condition: weather['main'] ?? 'Unknown',
      description: weather['description'] ?? 'No description',
      iconCode: weather['icon'] ?? '01d',
      windSpeed: (wind['speed'] ?? 0).toDouble(),
      pressure: main['pressure'] ?? 0,
      visibility: (json['visibility'] ?? 10000) ~/ 1000, // Convert to km
      lastUpdated: DateTime.now(), // Real-time timestamp
    );
  }

  /// Create mock weather data for demo/testing
  factory WeatherData.mock(String city) {
    return WeatherData(
      cityName: city,
      temperature: 28.5,
      feelsLike: 30.2,
      humidity: 65,
      condition: 'Clear',
      description: 'Clear sky',
      iconCode: '01d',
      windSpeed: 3.5,
      pressure: 1013,
      visibility: 10,
    );
  }

  /// Get weather condition icon
  String get weatherIcon {
    switch (condition.toLowerCase()) {
      case 'clear':
        return '☀️';
      case 'clouds':
        return '☁️';
      case 'rain':
      case 'drizzle':
        return '🌧️';
      case 'thunderstorm':
        return '⛈️';
      case 'snow':
        return '❄️';
      case 'mist':
      case 'fog':
      case 'haze':
        return '🌫️';
      default:
        return '🌤️';
    }
  }

  /// Get farming advisory based on weather
  String get farmingAdvisory {
    if (condition.toLowerCase() == 'rain' ||
        condition.toLowerCase() == 'drizzle') {
      return 'Good for natural irrigation. Avoid fertilizer application.';
    } else if (condition.toLowerCase() == 'thunderstorm') {
      return 'Avoid outdoor farming activities. Check crop protection.';
    } else if (temperature > 35) {
      return 'High temperature alert! Ensure adequate irrigation.';
    } else if (temperature < 10) {
      return 'Low temperature alert! Protect sensitive crops from frost.';
    } else if (humidity > 80) {
      return 'High humidity may increase disease risk. Monitor crops closely.';
    } else {
      return 'Favorable conditions for farming activities.';
    }
  }
}

/// Custom exception for weather errors
class WeatherException implements Exception {
  final String message;
  WeatherException(this.message);

  @override
  String toString() => message;
}

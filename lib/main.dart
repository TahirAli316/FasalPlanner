/// FasalPlanner – Smart Weather-Based Farming Calendar App
/// Main entry point of the application

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app.dart';
import 'core/services/firebase_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Manual Firebase initialization (no flutterfire CLI)
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize sample crop data (RUN ONCE)
  final firebaseService = FirebaseService();
  //await firebaseService.initializeSampleCrops();

  runApp(const FasalPlannerApp());
}

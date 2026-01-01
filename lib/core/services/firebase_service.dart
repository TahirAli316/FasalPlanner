/// Firebase Service
///
/// Handles all Firebase operations including:
/// - Authentication (login, signup, logout)
/// - User data management in Firestore
/// - Crop data operations
/// - Farming plan operations
/// - Custom event operations

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../models/user_model.dart';
import '../../models/crop_model.dart';
import '../../models/farming_plan_model.dart';
import '../../models/event_model.dart';

class FirebaseService {
  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get _usersCollection => _firestore.collection('users');
  CollectionReference get _cropsCollection => _firestore.collection('crops');
  CollectionReference get _farmingPlansCollection =>
      _firestore.collection('farming_plans');
  CollectionReference get _eventsCollection => _firestore.collection('events');

  // ============ AUTHENTICATION METHODS ============

  /// Get current user
  User? get currentUser => _auth.currentUser;

  /// Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign up with email and password
  /// Creates user in Firebase Auth and stores profile in Firestore
  Future<UserModel?> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      // Create user in Firebase Auth
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Create user profile in Firestore
        final user = UserModel(
          uid: credential.user!.uid,
          name: name,
          email: email,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _usersCollection
            .doc(credential.user!.uid)
            .set(user.toFirestore());
        return user;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'An unexpected error occurred: $e';
    }
  }

  /// Login with email and password
  Future<UserModel?> login({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        return await getUserData(credential.user!.uid);
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'An unexpected error occurred: $e';
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      if (!kIsWeb) {
        final GoogleSignIn googleSignIn = GoogleSignIn();
        if (await googleSignIn.isSignedIn()) {
          await googleSignIn.disconnect();
        }
      }
    } catch (e) {
      // Ignore Google Sign-In errors during logout
    }
    await _auth.signOut();
  }

  /// Sign in with Google
  Future<UserModel?> signInWithGoogle() async {
    try {
      UserCredential userCredential;

      if (kIsWeb) {
        // For Web: Use Firebase Auth's signInWithPopup for proper account selection
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        // This parameter forces account selection every time
        googleProvider.setCustomParameters({
          'prompt': 'select_account',
          'login_hint': '',
        });

        // Sign out first to ensure fresh login
        await _auth.signOut();

        userCredential = await _auth.signInWithPopup(googleProvider);
      } else {
        // For Mobile (Android/iOS): Use google_sign_in package
        final GoogleSignIn googleSignIn = GoogleSignIn(
          scopes: ['email', 'profile'],
        );

        // Sign out first to always show account picker
        await googleSignIn.signOut();

        // Trigger the Google Sign-In flow
        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

        if (googleUser == null) {
          // User cancelled the sign-in
          return null;
        }

        // Obtain the auth details from the request
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        // Create a new credential
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        // Sign in to Firebase with the Google credential
        userCredential = await _auth.signInWithCredential(credential);
      }

      if (userCredential.user != null) {
        // Check if user already exists in Firestore
        final existingUser = await getUserData(userCredential.user!.uid);

        if (existingUser != null) {
          return existingUser;
        }

        // Create new user profile in Firestore
        final user = UserModel(
          uid: userCredential.user!.uid,
          name: userCredential.user!.displayName ?? 'User',
          email: userCredential.user!.email ?? '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _usersCollection
            .doc(userCredential.user!.uid)
            .set(user.toFirestore());
        return user;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Google Sign-In failed: $e';
    }
  }

  /// Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for this email.';
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'invalid-email':
        return 'Invalid email address.';
      default:
        return e.message ?? 'An error occurred.';
    }
  }

  // ============ USER DATA METHODS ============

  /// Get user data from Firestore
  Future<UserModel?> getUserData(String uid) async {
    try {
      final doc = await _usersCollection.doc(uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      // Return null if permission denied or other error
      print('Error fetching user data: $e');
      return null;
    }
  }

  /// Stream of user data
  Stream<UserModel?> getUserStream(String uid) {
    return _usersCollection.doc(uid).snapshots().map((doc) {
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    });
  }

  /// Update user profile data (region, land size, soil type)
  Future<void> updateUserFarmDetails({
    required String uid,
    required String region,
    required double landSize,
    required String soilType,
  }) async {
    await _usersCollection.doc(uid).update({
      'region': region,
      'landSize': landSize,
      'soilType': soilType,
      'updatedAt': Timestamp.now(),
    });
  }

  /// Update selected crop
  Future<void> updateSelectedCrop({
    required String uid,
    required String cropId,
  }) async {
    await _usersCollection.doc(uid).update({
      'selectedCropId': cropId,
      'updatedAt': Timestamp.now(),
    });
  }

  // ============ CROP DATA METHODS ============

  /// Get all crops
  Future<List<CropModel>> getAllCrops() async {
    try {
      final snapshot = await _cropsCollection.get();
      return snapshot.docs.map((doc) => CropModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error fetching crops: $e');
      return [];
    }
  }

  /// Get crop by ID
  Future<CropModel?> getCropById(String cropId) async {
    final doc = await _cropsCollection.doc(cropId).get();
    if (doc.exists) {
      return CropModel.fromFirestore(doc);
    }
    return null;
  }

  /// Initialize sample crops (call once to seed database)
  Future<void> initializeSampleCrops() async {
    final crops = [
      CropModel(
        id: 'wheat',
        name: 'Wheat',
        description: 'A staple grain crop grown in temperate climates',
        suitableRegions: ['Punjab', 'Sindh', 'KPK', 'Balochistan'],
        suitableSoilTypes: ['Loamy', 'Clay', 'Sandy Loam'],
        minLandSize: 1.0,
        growingDurationDays: 120,
        season: 'Rabi (Winter)',
        expectedYieldPerAcre: 40,
        waterRequirement: 'Medium',
      ),
      CropModel(
        id: 'rice',
        name: 'Rice',
        description: 'A major food crop requiring abundant water',
        suitableRegions: ['Punjab', 'Sindh'],
        suitableSoilTypes: ['Clay', 'Loamy'],
        minLandSize: 2.0,
        growingDurationDays: 150,
        season: 'Kharif (Summer)',
        expectedYieldPerAcre: 35,
        waterRequirement: 'High',
      ),
      CropModel(
        id: 'cotton',
        name: 'Cotton',
        description: 'A cash crop important for textile industry',
        suitableRegions: ['Punjab', 'Sindh'],
        suitableSoilTypes: ['Sandy Loam', 'Loamy', 'Alluvial'],
        minLandSize: 3.0,
        growingDurationDays: 180,
        season: 'Kharif (Summer)',
        expectedYieldPerAcre: 12,
        waterRequirement: 'Medium',
      ),
      CropModel(
        id: 'sugarcane',
        name: 'Sugarcane',
        description: 'A tall perennial crop for sugar production',
        suitableRegions: ['Punjab', 'Sindh', 'KPK'],
        suitableSoilTypes: ['Loamy', 'Clay', 'Alluvial'],
        minLandSize: 2.0,
        growingDurationDays: 365,
        season: 'Year-round',
        expectedYieldPerAcre: 250,
        waterRequirement: 'High',
      ),
      CropModel(
        id: 'maize',
        name: 'Maize (Corn)',
        description: 'A versatile grain crop used for food and feed',
        suitableRegions: ['Punjab', 'KPK', 'Sindh'],
        suitableSoilTypes: ['Loamy', 'Sandy Loam', 'Alluvial'],
        minLandSize: 1.0,
        growingDurationDays: 100,
        season: 'Kharif & Rabi',
        expectedYieldPerAcre: 30,
        waterRequirement: 'Medium',
      ),
      CropModel(
        id: 'potato',
        name: 'Potato',
        description: 'A root vegetable crop with high demand',
        suitableRegions: ['Punjab', 'KPK'],
        suitableSoilTypes: ['Sandy Loam', 'Loamy'],
        minLandSize: 0.5,
        growingDurationDays: 90,
        season: 'Rabi (Winter)',
        expectedYieldPerAcre: 100,
        waterRequirement: 'Medium',
      ),
      CropModel(
        id: 'tomato',
        name: 'Tomato',
        description: 'A popular vegetable crop grown throughout the year',
        suitableRegions: ['Punjab', 'Sindh', 'KPK', 'Balochistan'],
        suitableSoilTypes: ['Loamy', 'Sandy Loam'],
        minLandSize: 0.25,
        growingDurationDays: 75,
        season: 'Year-round',
        expectedYieldPerAcre: 80,
        waterRequirement: 'Medium',
      ),
      CropModel(
        id: 'onion',
        name: 'Onion',
        description: 'A bulb vegetable essential for cooking',
        suitableRegions: ['Punjab', 'Sindh', 'Balochistan'],
        suitableSoilTypes: ['Loamy', 'Sandy Loam', 'Alluvial'],
        minLandSize: 0.25,
        growingDurationDays: 120,
        season: 'Rabi (Winter)',
        expectedYieldPerAcre: 60,
        waterRequirement: 'Low',
      ),
    ];

    for (final crop in crops) {
      await _cropsCollection.doc(crop.id).set(crop.toFirestore());
    }
  }

  // ============ FARMING PLAN METHODS ============

  /// Get farming plan for user
  Future<FarmingPlanModel?> getFarmingPlan(String userId) async {
    try {
      final snapshot = await _farmingPlansCollection
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return FarmingPlanModel.fromFirestore(snapshot.docs.first);
      }
      return null;
    } catch (e) {
      // Fallback: query without orderBy if index is missing
      print('Error fetching farming plan with orderBy: $e');
      try {
        final snapshot = await _farmingPlansCollection
            .where('userId', isEqualTo: userId)
            .get();

        if (snapshot.docs.isNotEmpty) {
          // Sort locally and get the most recent
          final docs = snapshot.docs.toList();
          docs.sort((a, b) {
            final aTime = (a.data() as Map)['createdAt'] as Timestamp?;
            final bTime = (b.data() as Map)['createdAt'] as Timestamp?;
            if (aTime == null || bTime == null) return 0;
            return bTime.compareTo(aTime);
          });
          return FarmingPlanModel.fromFirestore(docs.first);
        }
        return null;
      } catch (e2) {
        print('Error fetching farming plan: $e2');
        return null;
      }
    }
  }

  /// Create or update farming plan
  Future<void> saveFarmingPlan(FarmingPlanModel plan) async {
    if (plan.id.isEmpty) {
      // Create new plan
      await _farmingPlansCollection.add(plan.toFirestore());
    } else {
      // Update existing plan
      await _farmingPlansCollection.doc(plan.id).set(plan.toFirestore());
    }
  }

  /// Update activity completion status in farming plan
  Future<void> updateActivityCompletion({
    required String planId,
    required String activityId,
    required bool isCompleted,
  }) async {
    try {
      // Get the current plan document
      final doc = await _farmingPlansCollection.doc(planId).get();
      if (!doc.exists) return;

      final data = doc.data() as Map<String, dynamic>;
      final activities = List<Map<String, dynamic>>.from(
        data['activities'] ?? [],
      );

      // Find and update the specific activity
      for (int i = 0; i < activities.length; i++) {
        if (activities[i]['id'] == activityId) {
          activities[i]['isCompleted'] = isCompleted;
          break;
        }
      }

      // Update the document
      await _farmingPlansCollection.doc(planId).update({
        'activities': activities,
      });
    } catch (e) {
      print('Error updating activity completion: $e');
      rethrow;
    }
  }

  /// Stream of farming plan
  Stream<FarmingPlanModel?> getFarmingPlanStream(String userId) {
    return _farmingPlansCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isNotEmpty) {
            return FarmingPlanModel.fromFirestore(snapshot.docs.first);
          }
          return null;
        });
  }

  // ============ CUSTOM EVENTS METHODS ============

  /// Get all custom events for user
  Future<List<EventModel>> getCustomEvents(String userId) async {
    try {
      // Try with orderBy (requires composite index)
      final snapshot = await _eventsCollection
          .where('userId', isEqualTo: userId)
          .orderBy('date')
          .get();

      return snapshot.docs.map((doc) => EventModel.fromFirestore(doc)).toList();
    } catch (e) {
      // Fallback: query without orderBy if index is missing
      print('Error fetching events with orderBy: $e');
      try {
        final snapshot = await _eventsCollection
            .where('userId', isEqualTo: userId)
            .get();

        final events = snapshot.docs
            .map((doc) => EventModel.fromFirestore(doc))
            .toList();
        // Sort locally
        events.sort((a, b) => a.date.compareTo(b.date));
        return events;
      } catch (e2) {
        print('Error fetching events: $e2');
        return [];
      }
    }
  }

  /// Stream of custom events (without orderBy to avoid index requirement)
  Stream<List<EventModel>> getCustomEventsStream(String userId) {
    return _eventsCollection.where('userId', isEqualTo: userId).snapshots().map(
      (snapshot) {
        final events = snapshot.docs
            .map((doc) => EventModel.fromFirestore(doc))
            .toList();
        // Sort locally
        events.sort((a, b) => a.date.compareTo(b.date));
        return events;
      },
    );
  }

  /// Add custom event
  Future<void> addCustomEvent(EventModel event) async {
    await _eventsCollection.add(event.toFirestore());
  }

  /// Update custom event
  Future<void> updateCustomEvent(EventModel event) async {
    await _eventsCollection.doc(event.id).update(event.toFirestore());
  }

  /// Delete custom event
  Future<void> deleteCustomEvent(String eventId) async {
    await _eventsCollection.doc(eventId).delete();
  }

  // ============ FERTILIZER SCHEDULE METHODS ============

  /// Get fertilizer schedule based on crop
  /// Returns a list of fertilizer activities from the farming plan
  Future<List<FarmingActivity>> getFertilizerSchedule(String userId) async {
    final plan = await getFarmingPlan(userId);
    if (plan != null) {
      return plan.activities
          .where((a) => a.type == ActivityType.fertilizer)
          .toList();
    }
    return [];
  }
}

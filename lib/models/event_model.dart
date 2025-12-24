/// Event Model
///
/// Represents custom events that users can add to their farming calendar
/// These are separate from the auto-generated farming plan activities

import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final DateTime date;
  final String? cropId;
  final bool isCompleted;
  final DateTime createdAt;

  EventModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.date,
    this.cropId,
    required this.isCompleted,
    required this.createdAt,
  });

  /// Create EventModel from Firestore document
  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EventModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      cropId: data['cropId'],
      isCompleted: data['isCompleted'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert EventModel to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'date': Timestamp.fromDate(date),
      'cropId': cropId,
      'isCompleted': isCompleted,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Copy with updated fields
  EventModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    DateTime? date,
    String? cropId,
    bool? isCompleted,
    DateTime? createdAt,
  }) {
    return EventModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      cropId: cropId ?? this.cropId,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

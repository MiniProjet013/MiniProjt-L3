import 'package:cloud_firestore/cloud_firestore.dart';

class ArchivedItem {
  final String id;
  final String originalId;
  final String itemType; // 'class', 'eleve', 'event', 'schedule', etc.
  final Map<String, dynamic> data;
  final Timestamp deletedAt;
  final String deletedBy;

  ArchivedItem({
    required this.id,
    required this.originalId,
    required this.itemType,
    required this.data,
    required this.deletedAt,
    required this.deletedBy,
  });

  factory ArchivedItem.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ArchivedItem(
      id: doc.id,
      originalId: data['originalId'] ?? '',
      itemType: data['itemType'] ?? '',
      data: data['data'] ?? {},
      deletedAt: data['deletedAt'] ?? Timestamp.now(),
      deletedBy: data['deletedBy'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'originalId': originalId,
      'itemType': itemType,
      'data': data,
      'deletedAt': deletedAt,
      'deletedBy': deletedBy,
    };
  }
}
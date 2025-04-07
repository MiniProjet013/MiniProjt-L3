import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 🔹 إضافة وثيقة جديدة إلى أي Collection
  Future<void> addDocument(String collection, Map<String, dynamic> data) async {
    await _db.collection(collection).add(data);
  }

  // 🔹 جلب جميع الوثائق من Collection معين
  Future<List<Map<String, dynamic>>> getDocuments(String collection) async {
    QuerySnapshot snapshot = await _db.collection(collection).get();
    return snapshot.docs
        .map((doc) => {"id": doc.id, ...doc.data() as Map<String, dynamic>})
        .toList();
  }

  // 🔹 تحديث وثيقة معينة
  Future<void> updateDocument(
      String collection, String docId, Map<String, dynamic> newData) async {
    await _db.collection(collection).doc(docId).update(newData);
  }

  // 🔹 حذف وثيقة معينة
  Future<void> deleteDocument(String collection, String docId) async {
    await _db.collection(collection).doc(docId).delete();
  }

  // 🔹 جلب وثيقة معينة حسب ID
  Future<Map<String, dynamic>?> getDocumentById(
      String collection, String docId) async {
    DocumentSnapshot doc = await _db.collection(collection).doc(docId).get();
    if (doc.exists) {
      return {"id": doc.id, ...doc.data() as Map<String, dynamic>};
    }
    return null;
  }
}

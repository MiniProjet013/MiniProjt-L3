import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ArchiveService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Archiver un élément
  Future<void> archiveItem({
    required String itemType,
    required String itemId,
    required Map<String, dynamic> itemData,
  }) async {
    try {
      // Obtenir l'ID de l'utilisateur actuel
      String? userId = _auth.currentUser?.uid;
      String? userEmail = _auth.currentUser?.email;
      
      // Créer un document d'archive avec toutes les données nécessaires
      await _db.collection('archives').add({
        'originalCollection': itemType,
        'originalId': itemId,
        'data': itemData,
        'deletedTimestamp': FieldValue.serverTimestamp(),
        'deletedBy': userEmail ?? userId ?? 'Utilisateur inconnu',
      });
    } catch (e) {
      print('❌ Erreur dans archiveItem: $e');
      throw e;
    }
  }

  // Récupérer les éléments archivés par type
  Future<List<Map<String, dynamic>>> getArchivedItems(String itemType) async {
    try {
      QuerySnapshot snapshot = await _db.collection('archives')
          .where('originalCollection', isEqualTo: itemType)
          .orderBy('deletedTimestamp', descending: true)
          .get();
      
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        Timestamp timestamp = data['deletedTimestamp'] as Timestamp;
        
        return {
          'id': doc.id,
          'data': data['data'],
          'deletedTimestamp': timestamp.toDate(),
          'deletedBy': data['deletedBy'] ?? 'Non spécifié',
        };
      }).toList();
    } catch (e) {
      print('❌ Erreur dans getArchivedItems: $e');
      throw e;
    }
  }

  // Restaurer un élément archivé
  Future<void> restoreItem(String archiveId, String collectionName) async {
    try {
      // Obtenir le document d'archive
      DocumentSnapshot archiveDoc = await _db.collection('archives').doc(archiveId).get();
      
      if (!archiveDoc.exists) {
        throw Exception("Document d'archive non trouvé");
      }
      
      Map<String, dynamic> archiveData = archiveDoc.data() as Map<String, dynamic>;
      Map<String, dynamic> itemData = archiveData['data'];
      String originalId = archiveData['originalId'];
      
      // Vérifier si l'ID existe déjà dans la collection active
      DocumentSnapshot existingDoc = await _db.collection(collectionName).doc(originalId).get();
      
      if (existingDoc.exists) {
        throw Exception("Un document avec cet ID existe déjà dans la collection active");
      }
      
      // Réinsérer dans la collection d'origine
      await _db.collection(collectionName).doc(originalId).set({
        ...itemData,
        'restoredAt': FieldValue.serverTimestamp(),
      });
      
      // Supprimer de la collection d'archives
      await _db.collection('archives').doc(archiveId).delete();
    } catch (e) {
      print('❌ Erreur dans restoreItem: $e');
      throw e;
    }
  }

  // Supprimer définitivement un élément archivé
  Future<void> permanentlyDeleteArchivedItem(String archiveId) async {
    try {
      await _db.collection('archives').doc(archiveId).delete();
    } catch (e) {
      print('❌ Erreur dans permanentlyDeleteArchivedItem: $e');
      throw e;
    }
  }
}
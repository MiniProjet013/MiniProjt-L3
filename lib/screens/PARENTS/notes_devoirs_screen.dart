import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotesDevoirsScreen extends StatefulWidget {
  @override
  _NotesDevoirsScreenState createState() => _NotesDevoirsScreenState();
}

class _NotesDevoirsScreenState extends State<NotesDevoirsScreen> {
  // Référence à la collection note_devoir
  final CollectionReference notesCollection = 
      FirebaseFirestore.instance.collection('note_devoir');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(232, 2, 196, 34),
        title: Text("Nouveaux de Devoirs")
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: notesCollection.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Une erreur est survenue'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('Aucune note trouvée'));
          }

          // Données disponibles
          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var noteData = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              String matiere = noteData['matiere'] ?? 'Matière non spécifiée';
              // Vérifier si la note est stockée sous forme de nombre ou de chaîne
              var noteValue = noteData['note'];
              String noteDisplay = noteValue is num ? '$noteValue/20' : noteValue.toString();

              return Card(
                elevation: 3,
                margin: EdgeInsets.symmetric(vertical: 10),
                child: ListTile(
                  leading: Icon(Icons.assignment, color: const Color.fromARGB(255, 255, 115, 1)),
                  title: Text(matiere, style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: noteData['nomComplet'] != null 
                      ? Text('Élève: ${noteData['nomComplet']}')
                      : null,
                  trailing: Text(noteDisplay, style: TextStyle(fontSize: 16)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
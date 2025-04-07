import 'package:flutter/material.dart';

class NotesExamensScreen extends StatelessWidget {
  final List<Map<String, String>> notes = [
    {"matiere": "Mathématiques", "note": "15/20"},
    {"matiere": "Physique", "note": "17/20"},
    {"matiere": "Histoire", "note": "13/20"},
    {"matiere": "Français", "note": "19/20"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(232, 2, 196, 34),
        title: Text("Nouveaux d'Examens")),
      body: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: notes.length,
        itemBuilder: (context, index) {
          return Card(
            elevation: 3,
            margin: EdgeInsets.symmetric(vertical: 10),
            child: ListTile(
              leading: Icon(Icons.note, color: const Color.fromARGB(255, 255, 96, 4)),
              title: Text(notes[index]["matiere"]!, style: TextStyle(fontWeight: FontWeight.bold)),
              trailing: Text(notes[index]["note"]!, style: TextStyle(fontSize: 16)),
            ),
          );
        },
      ),
    );
  }
}

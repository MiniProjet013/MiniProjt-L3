import 'package:flutter/material.dart';
import 'notes_devoirs_screen.dart';
import 'notes_examens_screen.dart';
import 'moyenne_annuelle_screen.dart';
class VoirNotesScreen extends StatelessWidget {
  final List<Map<String, dynamic>> categories = [
    {"title": "Nouveaux de Devoirs", "icon": Icons.assignment, "route": NotesDevoirsScreen()}, // 🔹 نقاط الفروض
    {"title": "Nouveaux d'Examens", "icon": Icons.note, "route": NotesExamensScreen()}, // 🔹 نقاط الامتحانات
    {"title": "Moyenne Annuelle", "icon": Icons.bar_chart, "route": MoyenneAnnuelleScreen()}, // 🔹 معدل السنوي
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(232, 2, 196, 34),
        title: Row(
          children: [
            Icon(Icons.grade, color: Colors.white),
            SizedBox(width: 10),
            Text("Voir les notes", style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // 🔹 الأعمدة أصبحت 2 لتكبير الأيقونات
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
            childAspectRatio: 1.2,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => categories[index]["route"]),
                );
              },
              child: Card(
                color: Colors.white,
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(categories[index]["icon"], size: 50, color: const Color.fromARGB(255, 223, 126, 0)),
                    SizedBox(height: 10),
                    Text(categories[index]["title"], style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

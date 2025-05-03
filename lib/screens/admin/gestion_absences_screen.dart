import 'package:flutter/material.dart';
import '../../widgets/category_card.dart';
import 'absences_prof_screen.dart';
import 'absences_eleve_screen.dart';

class GestionAbsencesScreen extends StatelessWidget {
  final List<Map<String, dynamic>> options = [
    {"title": "Absences des professeurs", "icon": Icons.school, "route": AbsencesProfScreen()},
    {"title": "Absences des élèves", "icon": Icons.person, "route": AbsencesEleveScreen()},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(232, 2, 196, 34),
        title: Text("Gestion des absences")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
            childAspectRatio: 1.2,
          ),
          itemCount: options.length,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => options[index]["route"]),
                );
              },
              child: CategoryCard(
                title: options[index]['title'],
                icon: options[index]['icon'], color: null,
              ),
            );
          },
        ),
      ),
    );
  }
}

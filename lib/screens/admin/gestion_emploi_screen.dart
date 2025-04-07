import 'package:flutter/material.dart';
import '../../widgets/category_card.dart';
import 'emploi_classes_screen.dart';
import 'emploi_examens_screen.dart';

class GestionEmploiScreen extends StatelessWidget {
  final List<Map<String, dynamic>> options = [
    {"title": "Emploi du temps des classes", "icon": Icons.class_, "route":EmploiDuTempsScreen ()},
    {"title": "Emploi du temps des examens", "icon": Icons.assignment, "route": EmploiExamensScreen()},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Color.fromARGB(232, 2, 196, 34),
        title: Text("Gestion de l'emploi du temps")),
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
                icon: options[index]['icon'],
              ),
            );
          },
        ),
      ),
    );
  }
}

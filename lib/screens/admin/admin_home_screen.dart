import 'package:flutter/material.dart';
import '../../widgets/category_card.dart';
import '../../utils/constants.dart';
import 'ajouter_utilisateur_screen.dart';
import 'gestion_absences_screen.dart';
import 'gestion_emploi_screen.dart';
import 'publier_evenement_screen.dart';
import 'modifier_screen.dart'; 
import 'supprimerscreen.dart';

// ✅ شاشة التعديل الجديدة

class AdminHomeScreen extends StatelessWidget {
  final List<Map<String, dynamic>> categories = [
    {"title": "Gestion des absences", "icon": Icons.event_busy, "route": GestionAbsencesScreen()},
    {"title": "Gestion emploi du temps", "icon": Icons.calendar_month, "route": GestionEmploiScreen()},
    {"title": "Ajouter", "icon": Icons.person_add, "route": AjouterUtilisateurScreen()},
    {"title": "Modifier",  "icon": Icons.edit, "route": ModifierScreen()}, // ✅ التوجيه لشاشة التعديل
    {"title": "Supprimer", "icon": Icons.delete, "route": SupprimerScreen()},

    {"title": "Publier des événements", "icon": Icons.event, "route": PublierEvenementScreen()},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: 180,
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(100),
                    bottomRight: Radius.circular(100),
                  ),
                ),
              ),
              CircleAvatar(
                radius: 50,
                backgroundColor: const Color.fromARGB(232, 241, 239, 236),
                child: Icon(Icons.admin_panel_settings, size: 50, color: primaryColor),
              ),
            ],
          ),
          SizedBox(height: 20),

          Expanded(
            child: Padding(
              padding: EdgeInsets.all(10),
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  childAspectRatio: 1.2,
                ),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      if (categories[index]["route"] != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => categories[index]["route"]),
                        );
                      } else if (categories[index]["title"] == "Supprimer") {
                        print("Supprimer action executed");
                      }
                    },
                    child: CategoryCard(
                      title: categories[index]['title'],
                      icon: categories[index]['icon'],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

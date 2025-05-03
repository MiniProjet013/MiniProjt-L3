import 'package:flutter/material.dart';
import '../../widgets/category_card.dart';
import 'voir_notes_screen.dart';
import '../deconnecter_screen.dart';

class ParentHomeScreen extends StatefulWidget {
  final Map<String, String> enfants;
  
  ParentHomeScreen({required this.enfants});

  @override
  _ParentHomeScreenState createState() => _ParentHomeScreenState();
}

class _ParentHomeScreenState extends State<ParentHomeScreen> {
  final List<Map<String, dynamic>> categories = [
    {
      "title": "Voir les notes",
      "icon": Icons.school,
      "route": VoirNotesScreen()
    },
    {
      "title": "Notifications d'absences",
      "icon": Icons.notifications_active,
      "route": null
    },
    {"title": "Emploi du temps", "icon": Icons.calendar_today, "route": null},
    {"title": "Devoirs", "icon": Icons.assignment, "route": null},
    {"title": "Remarques", "icon": Icons.sticky_note_2, "route": null},
    {"title": "Convocations", "icon": Icons.mail, "route": null},
  ];

  void _showLogoutDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DeconnecterScreen(
          onConfirm: () {
            Navigator.of(context).pushReplacementNamed('/login');
          },
          onCancel: () {
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.family_restroom, size: 28, color: Colors.white),
            SizedBox(width: 10),
            Text("Accueil Parent", style: TextStyle(color: Colors.white)),
          ],
        ),
        backgroundColor: Color.fromARGB(232, 2, 196, 34),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: _showLogoutDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(height: 10),
          Text(
            "Vos enfants",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Wrap(
            spacing: 10,
            children: widget.enfants.entries.map((entry) {
              return Chip(
                label: Text(entry.value,
                    style: TextStyle(fontSize: 16, color: Colors.white)),
                avatar: Icon(Icons.child_care, color: Colors.white),
                backgroundColor: Color.fromARGB(213, 230, 122, 0),
              );
            }).toList(),
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
                          MaterialPageRoute(
                              builder: (context) => categories[index]["route"]),
                        );
                      }
                    },
                    child: CategoryCard(
                      title: categories[index]['title'],
                      icon: categories[index]['icon'], color: null,
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
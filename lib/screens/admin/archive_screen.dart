import 'package:flutter/material.dart';
import '../../widgets/category_card.dart';
import '../../utils/constants.dart';
import 'archived_classes_screen.dart';
//import 'archived_eleves_screen.dart';
//import 'archived_events_screen.dart';
//import 'archives/archived_schedules_screen.dart';

class ArchiveScreen extends StatelessWidget {
  final List<Map<String, dynamic>> archiveCategories = [
    {"title": "Classes Archivées", "icon": Icons.class_, "route": ArchivedClassesScreen()},
    {"title": "Élèves Archivés", "icon": Icons.person, /*"route": ArchivedElevesScreen()*/},
    {"title": "Événements Archivés", "icon": Icons.event_note, /*"route": ArchivedEventsScreen()*/},
    {"title": "Emplois du Temps Archivés", "icon": Icons.schedule, /*"route": ArchivedSchedulesScreen()*/},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: Text("Archives"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              "Éléments supprimés",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
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
                itemCount: archiveCategories.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => archiveCategories[index]["route"],
                        ),
                      );
                    },
                    child: CategoryCard(
                      title: archiveCategories[index]['title'],
                      icon: archiveCategories[index]['icon'], color: null,
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
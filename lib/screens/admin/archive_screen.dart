import 'package:flutter/material.dart';
 
import 'archived_classes_screen.dart';
import 'archived_profs_screen.dart';
import 'archived_eleves_screen.dart';
import 'archived_events_screen.dart';

class ArchiveScreen extends StatelessWidget {
  final Color orangeColor = Color.fromARGB(255, 218, 64, 3);
  final Color greenColor = Color.fromARGB(255, 1, 110, 5);
  final Color lightColor = Color.fromARGB(255, 255, 255, 255);
  final Color darkColor = Color(0xFF333333);

  final List<Map<String, dynamic>> options = [
    {
      "title": "CLASSES",
      "icon": Icons.class_,
      "route": ArchivedClassesScreen(),
      "color": Color.fromARGB(255, 218, 64, 3) // orange
    },
    {
      "title": "PROFS",
      "icon": Icons.person,
      "route": ProfesseursScreen() ,
      "color": Color.fromARGB(255, 1, 110, 5) // vert
    },
    {
      "title": "ELEVES",
      "icon": Icons.school,
      "route": ArchiveElevesScreen(),
      "color": Color.fromARGB(255, 218, 64, 3) // orange
    },
    {
      "title": "EVENEMENTS",
      "icon": Icons.event,
      "route":  EvenementScreen (),
      "color": Color.fromARGB(255, 1, 110, 5) // vert
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 150.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [orangeColor.withOpacity(0.8), greenColor.withOpacity(0.8)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'Archives',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Sélectionnez l\'élément archivé',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.all(20),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: 1.0,
              ),
              delegate: SliverChildBuilderDelegate(
                (BuildContext context, int index) {
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(15),
                        onTap: () {
                          if (options[index]["route"] != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => options[index]["route"],
                              ),
                            );
                          } else {
                            print("${options[index]['title']} Archive action executed");
                          }
                        },
                        splashColor: index % 2 == 0 ? orangeColor.withOpacity(0.2) : greenColor.withOpacity(0.2),
                        highlightColor: Colors.transparent,
                        child: Padding(
                          padding: EdgeInsets.all(15),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      index % 2 == 0 
                                          ? orangeColor.withOpacity(0.2) 
                                          : greenColor.withOpacity(0.2),
                                      index % 2 == 0 
                                          ? orangeColor.withOpacity(0.4) 
                                          : greenColor.withOpacity(0.4),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Icon(
                                  options[index]['icon'],
                                  size: 30,
                                  color: index % 2 == 0 ? orangeColor : greenColor,
                                ),
                              ),
                              SizedBox(height: 15),
                              Text(
                                options[index]['title'],
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: darkColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
                childCount: options.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
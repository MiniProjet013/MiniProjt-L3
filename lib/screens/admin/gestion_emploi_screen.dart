import 'package:flutter/material.dart';
//import '../../widgets/category_card.dart';
import 'emploi_classes_screen.dart';
import 'emploi_examens_screen.dart';

class GestionEmploiScreen extends StatelessWidget {
  final orangeColor = Color.fromARGB(255, 218, 64, 3);
  final greenColor = Color.fromARGB(255, 1, 110, 5);
  final lightColor = Color.fromARGB(255, 255, 255, 255);
  final darkColor = Color(0xFF333333);

  final List<Map<String, dynamic>> options = [
    {
      "title": "Emploi des classes", 
      "icon": Icons.class_, 
      "route": EmploiDuTempsScreen(),
      "color": Color.fromARGB(255, 218, 64, 3) // برتقالي
    },
    {
      "title": "Emploi des examens", 
      "icon": Icons.assignment, 
      "route": EmploiExamensScreen(),
      "color": Color.fromARGB(255, 1, 110, 5) // أخضر
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
                          'Gestion des emplois',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Sélectionnez un type d\'emploi du temps',
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
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => options[index]["route"]),
                          );
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
import 'package:flutter/material.dart';
import 'dart:math';
import 'ajouter_utilisateur_screen.dart';
import 'gestion_absences_screen.dart';
import 'gestion_emploi_screen.dart';
//import 'publier_evenement_screen.dart';
import 'modifier_screen.dart';
import 'statistiquescreen.dart';
import 'archive_screen.dart';
import '../RoleSelectionScreen.dart'; // Import de l'écran de connexion

class AdminHomeScreen extends StatefulWidget {
  @override
  _AdminHomeScreenState createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final List<String> greetings = [
    'Bienvenue',
    'Espace Administration',
  ];

  final List<String> subheadings = [
    'Sélectionnez une fonction',
    'Options administratives',
    'Services administratifs',
  ];

  late String currentGreeting;
  late String currentSubheading;
  late String dateTime;

  @override
  void initState() {
    super.initState();
    _updatePhrases();
  }

  void _updatePhrases() {
    final random = Random();
    setState(() {
      currentGreeting = greetings[random.nextInt(greetings.length)];
      currentSubheading = subheadings[random.nextInt(subheadings.length)];
      final now = DateTime.now();
      dateTime = '${now.day}/${now.month}/${now.year}';
    });
  }

  final List<Map<String, dynamic>> categories = [
    {"title": "Discipline scolaire", "icon": Icons.event_busy, "route":DisciplineScolaireScreen()},
    {"title": "Gestion emploi", "icon": Icons.calendar_month, "route": GestionEmploiScreen()},
    {"title": "Ajouter", "icon": Icons.person_add, "route": AjouterUtilisateurScreen()},
    {"title": "Modifier données", "icon": Icons.edit, "route": ModifierScreen()},
    {"title": "Statistiques", "icon": Icons.analytics_rounded, "route": StatistiquesEtablissementScreen()},
    //{"title": "Publier événements", "icon": Icons.event, "route": PublierEvenementScreen()},
    {"title": "Archives", "icon": Icons.archive, "route": ArchiveScreen()},
  ];

  void _logout() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => CombinedRoleLoginScreen()),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(
            'Déconnexion',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 218, 64, 3),
            ),
          ),
          content: Text(
            'Êtes-vous sûr de vouloir vous déconnecter ?',
            style: TextStyle(
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Annuler',
                style: TextStyle(
                  color: Color.fromARGB(255, 1, 110, 5),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromARGB(255, 218, 64, 3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: _logout,
              child: Text(
                'DÉCONNECTER',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final orangeColor = Color.fromARGB(255, 218, 64, 3);
    final greenColor = Color.fromARGB(255, 1, 110, 5);
    final lightColor = Color.fromARGB(255, 255, 255, 255);
    final darkColor = Color(0xFF333333);

    return WillPopScope(
      onWillPop: () async {
        _showLogoutDialog();
        return false;
      },
      child: Scaffold(
        backgroundColor: lightColor,
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 180.0,
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
                            currentGreeting,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Administrateur',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                currentSubheading,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 16,
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.calendar_today, color: Colors.white, size: 16),
                                    SizedBox(width: 6),
                                    Text(
                                      dateTime,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.logout, color: Colors.white),
                  onPressed: _showLogoutDialog,
                ),
              ],
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
                            if (categories[index]["route"] != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => categories[index]["route"]),
                              ).then((_) => _updatePhrases());
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
                                    categories[index]['icon'],
                                    size: 30,
                                    color: index % 2 == 0 ? orangeColor : greenColor,
                                  ),
                                ),
                                SizedBox(height: 15),
                                Text(
                                  categories[index]['title'],
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
                  childCount: categories.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
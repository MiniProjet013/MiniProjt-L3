import 'package:flutter/material.dart';
import 'dart:math';
import 'devoir_screen.dart';
import 'absences_screen.dart';
import 'remarques_screen.dart';
import 'notes_screen.dart';
import 'convocations_screen.dart';
import 'student_list_screen.dart';
import 'examens_screen.dart';
import 'emploi_du_temps.dart';
import '../RoleSelectionScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EnseignantHomeScreen extends StatefulWidget {
  @override
  _EnseignantHomeScreenState createState() => _EnseignantHomeScreenState();
}

class _EnseignantHomeScreenState extends State<EnseignantHomeScreen> {
  final List<String> greetings = [
    'Bienvenue',
    'Espace Enseignant',
    'Bonjour Professeur',
  ];

  final List<String> subheadings = [
    'Sélectionnez une fonction',
    'Gestion de la classe',
    'Outils pédagogiques',
  ];

  late String currentGreeting;
  late String currentSubheading;
  late String dateTime;
  
  // Informations de l'enseignant
  String nom = "";
  String prenom = "";
  String email = "";
  String idProf = "";
  String matiere = "";
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _updatePhrases();
    _fetchProfessorData();
  }
  
  Future<void> _fetchProfessorData() async {
    try {
      // Obtenir l'utilisateur actuellement connecté
      User? currentUser = FirebaseAuth.instance.currentUser;
      
      if (currentUser != null) {
        // Récupérer les données du professeur depuis Firestore
        final docSnapshot = await FirebaseFirestore.instance
            .collection('profs')
            .where('email', isEqualTo: currentUser.email)
            .limit(1)
            .get();
        
        if (docSnapshot.docs.isNotEmpty) {
          final data = docSnapshot.docs.first.data();
          setState(() {
            nom = data['nom'] ?? 'Nom';
            prenom = data['prenom'] ?? 'Prénom';
            email = data['email'] ?? currentUser.email ?? 'Email';
            idProf = data['idProf'] ?? 'ID';
            matiere = data['matiere'] ?? 'Matière';
            isLoading = false;
          });
        } else {
          setState(() {
            email = currentUser.email ?? 'Email';
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print("Erreur lors de la récupération des données: $e");
      setState(() {
        isLoading = false;
      });
    }
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
    {
      "title": "Gestion des absences",
      "icon": Icons.event_busy,
      "route": AbsencesScreen()
    },
    {
      "title": "Emploi du temps",
      "icon": Icons.calendar_month,
      "route": ScheduleScreen()
    },
    {
      "title": "Liste d'élèves",
      "icon": Icons.people,
      "route": StudentListScreen()
    },
    {"title": "Saisie des notes", "icon": Icons.edit, "route": NotesScreen()},
    {"title": "Devoirs", "icon": Icons.assignment, "route": HomeworkScreen()},
    {"title": "Remarques", "icon": Icons.comment, "route": RemarquesScreen()},
    {
      "title": "Convocations",
      "icon": Icons.mail,
      "route": ConvocationsScreen()
    },
    {"title": "Événements", "icon": Icons.event, "route": ExamensScreen()},
  ];

  void _logout() {
    // Déconnexion de Firebase
    FirebaseAuth.instance.signOut().then((_) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => CombinedRoleLoginScreen()),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors de la déconnexion: $error")),
      );
    });
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
              onPressed: _logout,
              child: Text(
                'DÉCONNECTER',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromARGB(255, 218, 64, 3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
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
        // Suppression complète de l'AppBar
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      orangeColor.withOpacity(0.8),
                      greenColor.withOpacity(0.8)
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              currentGreeting,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 16,
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.logout, color: Colors.white),
                              onPressed: _showLogoutDialog,
                              tooltip: 'Déconnexion',
                              constraints: BoxConstraints(), // Réduit les contraintes d'espace
                              padding: EdgeInsets.zero, // Supprime le padding
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        // Informations de l'enseignant
                        isLoading 
                          ? Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Row(
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      prenom.isNotEmpty ? prenom[0].toUpperCase() : "P",
                                      style: TextStyle(
                                        color: orangeColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 24,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 15),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "$prenom $nom",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        "ID: $idProf | $matiere",
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.9),
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                        SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                currentSubheading,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 16,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.calendar_today,
                                      color: Colors.white, size: 16),
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
            SliverPadding(
              padding: EdgeInsets.all(16),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.2, // Ajusté pour éviter le débordement
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
                                MaterialPageRoute(
                                    builder: (context) =>
                                        categories[index]["route"]),
                              ).then((_) => _updatePhrases());
                            }
                          },
                          splashColor: index % 2 == 0
                              ? orangeColor.withOpacity(0.2)
                              : greenColor.withOpacity(0.2),
                          highlightColor: Colors.transparent,
                          child: Padding(
                            padding: EdgeInsets.all(10),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min, // Important pour éviter le débordement
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
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
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    categories[index]['icon'],
                                    size: 24,
                                    color: index % 2 == 0
                                        ? orangeColor
                                        : greenColor,
                                  ),
                                ),
                                SizedBox(height: 8),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    categories[index]['title'],
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                      color: darkColor,
                                    ),
                                    maxLines: 1,
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
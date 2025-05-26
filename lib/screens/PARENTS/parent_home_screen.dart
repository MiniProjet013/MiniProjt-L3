import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

import 'voir_notes_screen.dart';
import 'absences_eleve_screen.dart';
import 'devoirs_eleve.dart';
import 'voir_remarques_parent.dart';
import 'voir_convocations_parents.dart';
import 'voir_emploi_du_temps_parents.dart';
import 'evenement_screen.dart';
import '../RoleSelectionScreen.dart';

class ParentHomeScreen extends StatefulWidget {
  final Map<String, Map<String, dynamic>>? enfantsPreverifies;
  
  ParentHomeScreen({this.enfantsPreverifies});
  
  @override
  _ParentHomeScreenState createState() => _ParentHomeScreenState();
}

class _ParentHomeScreenState extends State<ParentHomeScreen> {
  Map<String, Map<String, dynamic>> enfants = {};
  List<TextEditingController> controllers = [TextEditingController()];
  bool isLoading = false;
  String? selectedStudentId;
  
  // Phrases d'accueil dynamiques
  final List<String> greetings = [
    'Bienvenue Parent',
    'Espace Famille',
    'Bonjour',
  ];

  final List<String> subheadings = [
    'Suivi de vos enfants',
    'Gestion familiale',
    'Tableau de bord parent',
  ];

  late String currentGreeting;
  late String currentSubheading;
  late String dateTime;

  late final List<Map<String, dynamic>> categories;

  @override
  void initState() {
    super.initState();
    _updatePhrases();

    categories = [
      {
        "title": "Notes",
        "icon": Icons.score,
        "route": (String studentId) => VoirNotesScreen(studentId: studentId)
      },
      {
        "title": "Absences",
        "icon": Icons.event_busy,
        "route": (String studentId) => AbsencesScreen(eleveId: studentId)
      },
      {
        "title": "Emploi du temps",
        "icon": Icons.calendar_today,
        "route": (String studentId) {
          final enfant = enfants[studentId];
          final classeId = enfant != null ? enfant['classeId'] ?? '' : '';
          final anneeScolaire = enfant != null ? enfant['anneeScolaire'] ?? '' : '';
          return ScheduleScreen(
            eleveId: studentId,
            classeId: classeId,
            anneeScolaire: anneeScolaire,
          );
        },
      },
      {
        "title": "Devoirs",
        "icon": Icons.assignment,
        "route": (String studentId) => HomeworkScreen(studentId: studentId)
      },
      {
        "title": "Remarques",
        "icon": Icons.comment,
        "route": (String studentId) => ConvocationScreen(eleveId: studentId)
      },
      {
        "title": "Convocation",
        "icon": Icons.notifications,
        "route": (String studentId) => RemarquesParentScreen(eleveId: studentId)
      },
      {
        "title": "Événements",
        "icon": Icons.event,
        "route": (String studentId) => EvenementsPage()
      },
    ];

    if (widget.enfantsPreverifies != null && widget.enfantsPreverifies!.isNotEmpty) {
      setState(() {
        enfants = widget.enfantsPreverifies!;
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final args = ModalRoute.of(context)?.settings.arguments;
        if (args != null && args is Map<String, dynamic>) {
          List<String>? prefilledIds = args['prefilledIds'] as List<String>?;
          if (prefilledIds != null && prefilledIds.isNotEmpty) {
            setState(() {
              controllers = prefilledIds
                  .map((id) => TextEditingController(text: id))
                  .toList();
            });
            _verifierEnfants();
          }
        }
      });
    }
  }

  final CollectionReference elevesCollection =
      FirebaseFirestore.instance.collection('eleves');


  void _updatePhrases() {
    final random = Random();
    setState(() {
      currentGreeting = greetings[random.nextInt(greetings.length)];
      currentSubheading = subheadings[random.nextInt(subheadings.length)];
      final now = DateTime.now();
      dateTime = '${now.day}/${now.month}/${now.year}';
    });
  }

  @override
  void dispose() {
    for (var controller in controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    if (selectedStudentId != null) {
      setState(() {
        selectedStudentId = null;
      });
      return false;
    } else if (enfants.isNotEmpty) {
      return await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(
            'Retour à la connexion',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 218, 64, 3), // Orange color
            ),
          ),
          content: Text(
            'Voulez-vous vraiment retourner à la page de connexion?',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Non',
                style: TextStyle(
                  color: Color.fromARGB(255, 1, 110, 5), // Green color
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  enfants.clear();
                  controllers = [TextEditingController()];
                });
                Navigator.of(context).pop(true);
              },
              child: Text(
                'OUI',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromARGB(255, 218, 64, 3), // Orange color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ) ?? false;
    }
    return true;
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
              color: Color.fromARGB(255, 218, 64, 3), // Orange color
            ),
          ),
          content: Text(
            'Êtes-vous sûr de vouloir vous déconnecter ?',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Annuler',
                style: TextStyle(
                  color: Color.fromARGB(255, 1, 110, 5), // Green color
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => CombinedRoleLoginScreen()),
                );
              },
              child: Text(
                'DÉCONNECTER',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromARGB(255, 218, 64, 3), // Orange color
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
    
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: isLoading
            ? Center(child: CircularProgressIndicator(color: orangeColor))
            : (enfants.isEmpty ? _buildIdInputScreen() : _buildHomeScreen()),
      ),
    );
  }

  Widget _buildIdInputScreen() {
    final orangeColor = Color.fromARGB(255, 218, 64, 3);
    final greenColor = Color.fromARGB(255, 1, 110, 5);
    
    return Container(
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
          padding: EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.family_restroom,
                size: 80,
                color: Colors.white,
              ),
              SizedBox(height: 20),
              Text(
                "Espace Parent",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),
              Text(
                "Veuillez entrer les ID de vos enfants",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.9),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 30),
              Column(
                children: List.generate(
                  controllers.length,
                  (index) => Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: TextField(
                              controller: controllers[index],
                              decoration: InputDecoration(
                                labelText: "ID de l'enfant ${index + 1}",
                                labelStyle: TextStyle(color: Colors.white70),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                                hintText: "Ex: E-3280",
                                hintStyle: TextStyle(color: Colors.white60),
                              ),
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        if (controllers.length > 1)
                          IconButton(
                            icon: Icon(Icons.remove_circle, color: Colors.white),
                            onPressed: () {
                              setState(() {
                                controllers.removeAt(index);
                              });
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        controllers.add(TextEditingController());
                      });
                    },
                    icon: Icon(Icons.add, size: 18),
                    label: Text("Ajouter ID"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _verifierEnfants(),
                    child: Text("Suivant"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: orangeColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _verifierEnfants() async {
    setState(() {
      isLoading = true;
    });

    Map<String, Map<String, dynamic>> enteredEnfants = {};

    try {
      for (var controller in controllers) {
        String id = controller.text.trim();

        if (id.isNotEmpty) {
          DocumentSnapshot eleveDoc = await elevesCollection.doc(id).get();

          if (eleveDoc.exists && eleveDoc.data() != null) {
            Map<String, dynamic> eleveData = eleveDoc.data() as Map<String, dynamic>;
            enteredEnfants[id] = eleveData;
          }
        }
      }

      if (enteredEnfants.isNotEmpty) {
        setState(() {
          enfants = enteredEnfants;
          selectedStudentId = null;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Aucun ID valide trouvé dans la base de données"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur de connexion: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget _buildHomeScreen() {
    if (selectedStudentId == null) {
      return _buildChildrenSelectionScreen();
    } else {
      return _buildChildSpecificScreen(selectedStudentId!);
    }
  }

  Widget _buildChildrenSelectionScreen() {
    final orangeColor = Color.fromARGB(255, 218, 64, 3);
    final greenColor = Color.fromARGB(255, 1, 110, 5);
    
    return WillPopScope(
      onWillPop: () async {
        _showLogoutDialog();
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
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
                              constraints: BoxConstraints(),
                              padding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.family_restroom,
                                  color: orangeColor,
                                  size: 30,
                                ),
                              ),
                            ),
                            SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Espace Parent",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    "${enfants.length} enfant${enfants.length > 1 ? 's' : ''} connecté${enfants.length > 1 ? 's' : ''}",
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
                                    style: TextStyle(color: Colors.white, fontSize: 14),
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
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) {
                    String id = enfants.keys.elementAt(index);
                    Map<String, dynamic> enfant = enfants[id]!;
                    String nom = enfant['nom'] ?? '';
                    String prenom = enfant['prenom'] ?? '';
                    String classe = enfant['classeId'] ?? '';
                    String niveau = enfant['niveau'] ?? '';

                    return Container(
                      margin: EdgeInsets.only(bottom: 16),
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
                            setState(() {
                              selectedStudentId = id;
                            });
                          },
                          splashColor: orangeColor.withOpacity(0.2),
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        orangeColor.withOpacity(0.2),
                                        greenColor.withOpacity(0.4),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  child: Center(
                                    child: Text(
                                      "${prenom.isNotEmpty ? prenom[0] : ''}${nom.isNotEmpty ? nom[0] : ''}",
                                      style: TextStyle(
                                        color: orangeColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
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
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        "Classe: $classe - $niveau",
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  color: orangeColor,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: enfants.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChildSpecificScreen(String studentId) {
    Map<String, dynamic> enfant = enfants[studentId]!;
    String nom = enfant['nom'] ?? '';
    String prenom = enfant['prenom'] ?? '';
    String classe = enfant['classeId'] ?? '';
    String niveau = enfant['niveau'] ?? '';
    
    final orangeColor = Color.fromARGB(255, 218, 64, 3);
    final greenColor = Color.fromARGB(255, 1, 110, 5);
    final lightColor = Colors.white;
    final darkColor = Color(0xFF333333);

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: lightColor,
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
                            IconButton(
                              icon: Icon(Icons.arrow_back, color: Colors.white),
                              onPressed: () => _onWillPop(),
                              constraints: BoxConstraints(),
                              padding: EdgeInsets.zero,
                            ),
                            IconButton(
                              icon: Icon(Icons.logout, color: Colors.white),
                              onPressed: _showLogoutDialog,
                              tooltip: 'Déconnexion',
                              constraints: BoxConstraints(),
                              padding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
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
                                  "${prenom.isNotEmpty ? prenom[0] : ''}${nom.isNotEmpty ? nom[0] : ''}",
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
                                    "Classe: $classe - $niveau",
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
                                    style: TextStyle(color: Colors.white, fontSize: 14),
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
                  childAspectRatio: 1.2,
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
                              MaterialPageRoute(
                                builder: (context) => categories[index]["route"](studentId),
                              ),
                            );
                          },
                          splashColor: index % 2 == 0
                              ? orangeColor.withOpacity(0.2)
                              : greenColor.withOpacity(0.2),
                          highlightColor: Colors.transparent,
                          child: Padding(
                            padding: EdgeInsets.all(10),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
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
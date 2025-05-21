import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'voir_notes_screen.dart';
import 'absences_eleve_screen.dart';
import 'devoirs_eleve.dart';
import 'voir_remarques_parent.dart';
import 'voir_convocations_parents.dart';
import 'voir_emploi_du_temps_parents.dart';
import 'evenement_screen.dart';
import '../RoleSelectionScreen.dart'; // Importation de l'écran de connexion

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
  ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;

  final List<Map<String, dynamic>> categories = [
    {
      "title": "Notes",
      "icon": Icons.score,
      "color": Colors.blue,
      "route": (String studentId) => VoirNotesScreen(studentId: studentId)
    },
    {
      "title": "Absences",
      "icon": Icons.event_busy,
      "color": Colors.red,
      "route": (String studentId) =>  AbsencesScreen(eleveId: studentId)
    }, 
    {
      "title": "Emploi",
      "icon": Icons.calendar_today,
      "color": Colors.purple,
      "route": (String studentId) => ScheduleScreen()
    },
    {
      "title": "Devoirs",
      "icon": Icons.assignment,
      "color": Colors.orange,
      "route": (String studentId) => HomeworkScreen()
    },
    {
      "title": "Convocation",
      "icon": Icons.notifications,
      "color": Colors.green,
      "route": (String studentId) => RemarquesParentScreen(eleveId: studentId)
    },
    {
      "title": "Remarques",
      "icon": Icons.comment,
      "color": Colors.pink,
      "route": (String studentId) => ConvocationScreen()
    },
    {
      "title": "Événements",
      "icon": Icons.event,
      "color": Colors.amber,
      "route": (String studentId) => EvenementsPage()
    },
  ];

  final CollectionReference elevesCollection =
      FirebaseFirestore.instance.collection('eleves');

  @override
  void initState() {
    super.initState();
    
    _scrollController.addListener(() {
      setState(() {
        // Limiter l'offset entre 0 et 100 pour l'effet parallaxe
        _scrollOffset = _scrollController.offset.clamp(0.0, 100.0);
      });
    });
    
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

  @override
  void dispose() {
    _scrollController.dispose();
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
          title: Text('Retour à la page de connexion'),
          content: Text('Voulez-vous vraiment retourner à la page de connexion?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Non'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  enfants.clear();
                  controllers = [TextEditingController()];
                });
                Navigator.of(context).pop(true);
              },
              child: Text('Oui'),
            ),
          ],
        ),
      ) ?? false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: isLoading
            ? Center(child: CircularProgressIndicator(color: Colors.white))
            : (enfants.isEmpty ? _buildIdInputScreen() : _buildHomeScreen()),
      ),
    );
  }

  Widget _buildIdInputScreen() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF4285F4), Color(0xFF5B6AF0)],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Veuillez entrer les ID de vos enfants",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                textAlign: TextAlign.center),
            SizedBox(height: 20),
            Column(
              children: List.generate(
                controllers.length,
                (index) => Padding(
                  padding: EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controllers[index],
                          decoration: InputDecoration(
                            labelText: "ID de l'enfant ${index + 1}",
                            labelStyle: TextStyle(color: Colors.white70),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.white),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.white70),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.white),
                            ),
                            hintText: "Ex: E-3280",
                            hintStyle: TextStyle(color: Colors.white60),
                          ),
                          style: TextStyle(color: Colors.white),
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
            SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  controllers.add(TextEditingController());
                });
              },
              icon: Icon(Icons.add),
              label: Text("Ajouter un autre ID"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Color(0xFF4285F4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _verifierEnfants(),
              child: Text("Suivant"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Color(0xFF4285F4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              ),
            ),
          ],
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
          SnackBar(content: Text("Aucun ID valide n'a été trouvé dans la base de données")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur de connexion à la base de données: ${e.toString()}")),
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
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF4285F4), Color(0xFF5B6AF0)],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            SizedBox(height: 40),
            Text("Sélectionnez un enfant",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                textAlign: TextAlign.center),
            SizedBox(height: 30),
            Expanded(
              child: ListView.builder(
                itemCount: enfants.length,
                itemBuilder: (context, index) {
                  String id = enfants.keys.elementAt(index);
                  Map<String, dynamic> enfant = enfants[id]!;
                  String nom = enfant['nom'] ?? '';
                  String prenom = enfant['prenom'] ?? '';
                  String classe = enfant['classeId'] ?? '';
                  String niveau = enfant['niveau'] ?? '';

                  return Card(
                    elevation: 4,
                    margin: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Color(0xFF4285F4),
                        child: Text("${prenom[0]}${nom[0]}", style: TextStyle(color: Colors.white)),
                      ),
                      title: Text("$prenom $nom", style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("Classe: $classe - $niveau"),
                      trailing: Icon(Icons.arrow_forward_ios, color: Color(0xFF4285F4)),
                      onTap: () {
                        setState(() {
                          selectedStudentId = id;
                        });
                      },
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton.icon(
              icon: Icon(Icons.logout),
              label: Text("Déconnexion"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Color(0xFF4285F4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onPressed: () {
                // Navigation vers l'écran de connexion
                Navigator.pushReplacement(
                  context, 
                  MaterialPageRoute(builder: (context) => CombinedRoleLoginScreen())
                );
              },
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

    return NestedScrollView(
      headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
        return [
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            backgroundColor: Color(0xFF4285F4),
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => _onWillPop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(""),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF4285F4), Color(0xFF5B6AF0)],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white,
                      child: Text("${prenom[0]}${nom[0]}", 
                          style: TextStyle(fontSize: 28, color: Color(0xFF4285F4))),
                    ),
                    SizedBox(height: 10),
                    Text("$prenom $nom", 
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text("Classe: $classe - $niveau", 
                        style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.8))),
                  ],
                ),
              ),
            ),
          ),
        ];
      },
      body: Container(
        padding: EdgeInsets.only(top: 10),
        child: GridView.builder(
          padding: EdgeInsets.fromLTRB(16, 20, 16, 16),
          physics: BouncingScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
            childAspectRatio: 1.1,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            return _buildCategoryCard(
              title: categories[index]['title'],
              icon: categories[index]['icon'],
              color: categories[index]['color'],
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => categories[index]["route"](studentId),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildCategoryCard({
    required String title, 
    required IconData icon, 
    required Color color,
    required VoidCallback onTap
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 30,
                  color: color,
                ),
              ),
              SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
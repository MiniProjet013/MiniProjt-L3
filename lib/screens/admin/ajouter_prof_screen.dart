import 'package:flutter/material.dart';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AjouterProfScreen extends StatefulWidget {
  @override
  _AjouterProfScreenState createState() => _AjouterProfScreenState();
}

class _AjouterProfScreenState extends State<AjouterProfScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final TextEditingController idProfController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController surnameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController subjectController = TextEditingController();

  List<String> selectedLevels = [];
  List<Map<String, dynamic>> availableClasses = [];
  Map<String, dynamic>? selectedClass;
  bool isLoading = false;

  // Couleurs pour correspondre au style AjouterEleveScreen
  final Color orangeColor = Color.fromARGB(255, 218, 64, 3);
  final Color greenColor = Color.fromARGB(255, 1, 110, 5);
  final Color lightColor = Color.fromARGB(255, 255, 255, 255);
  final Color darkColor = Color(0xFF333333);

  final List<String> levels = [
    "1ère année",
    "2ème année",
    "3ème année",
    "4ème année",
    "5ème année",
    "6ème année"
  ];

  final List<String> schoolYears = [
    "2023-2024",
    "2024-2025",
    "2025-2026",
    "2026-2027",
    "2027-2028"
  ];
  String? selectedYear;

  @override
  void initState() {
    super.initState();
    _generateAndSetId();
  }

  void _generateAndSetId() {
    String generatedId = "P-${Random().nextInt(9000) + 1000}";
    setState(() {
      idProfController.text = generatedId;
    });
  }

  Future<void> _fetchClassesForSelectedLevels() async {
    if (selectedLevels.isEmpty || selectedYear == null) {
      setState(() {
        availableClasses = [];
        selectedClass = null;
      });
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      QuerySnapshot snapshot = await _db
          .collection('classes')
          .where("niveauxEtude", arrayContainsAny: selectedLevels)
          .where("anneeScolaire", isEqualTo: selectedYear)
          .get();

      List<Map<String, dynamic>> classes = snapshot.docs.map((doc) {
        return {
          "idClasse": doc.id,
          "numeroClasse": doc["numeroClasse"],
          "niveau": doc["niveauxEtude"],
        };
      }).toList();

      setState(() {
        availableClasses = classes;
        selectedClass = null;
      });
    } catch (e) {
      print("❌ خطأ في جلب الأقسام: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("❌ Échec du chargement des classes!"),
        backgroundColor: Colors.red,
      ));
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _saveProfessor() async {
    String idProf = idProfController.text.trim();
    String name = nameController.text.trim();
    String surname = surnameController.text.trim();
    String email = emailController.text.trim();
    String password = passwordController.text.trim();
    String subject = subjectController.text.trim();

    if (name.isEmpty ||
        surname.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        subject.isEmpty ||
        selectedLevels.isEmpty ||
        selectedClass == null ||
        selectedYear == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("⚠️ Veuillez remplir tous les champs!"),
        backgroundColor: Colors.red,
      ));
      return;
    }

    setState(() => isLoading = true);

    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      Map<String, dynamic> profData = {
        "idProf": idProf,
        "nom": name,
        "prenom": surname,
        "email": email,
        "matiere": subject,
        "classeId": selectedClass!["idClasse"],
        "anneeScolaire": selectedYear,
        "numeroClasse": selectedClass!["numeroClasse"],
        "niveauClasse": selectedClass!["niveau"],
        "uid": userCredential.user!.uid,
      };

      await _db.collection('profs').doc(idProf).set(profData);

      await _db.collection('classes').doc(selectedClass!["idClasse"]).set({
        "profs": {
          idProf: {
            "nom": name,
            "prenom": surname,
            "matiere": subject,
          }
        }
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("✅ Professeur ajouté avec succès!"),
        backgroundColor: greenColor,
      ));

      // Retour à l'écran précédent après ajout réussi
      Navigator.pop(context, true);
    } on FirebaseAuthException catch (e) {
      print("❌ خطأ أثناء إنشاء الحساب: ${e.message}");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("❌ ${e.message}"),
        backgroundColor: Colors.red,
      ));
      setState(() => isLoading = false);
    } catch (e) {
      print("❌ خطأ أثناء الإضافة: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("❌ Échec de l'ajout du professeur! Réessayez."),
        backgroundColor: Colors.red,
      ));
      setState(() => isLoading = false);
    }
  }

  // Widget de champ de saisie personnalisé avec cadre
  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    bool readOnly = false,
    bool obscureText = false,
    Icon? suffixIcon,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: darkColor.withOpacity(0.2),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: darkColor.withOpacity(0.7),
              ),
            ),
            TextField(
              controller: controller,
              readOnly: readOnly,
              obscureText: obscureText,
              onTap: onTap,
              style: TextStyle(
                fontSize: 16,
                color: darkColor,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                suffixIcon: suffixIcon,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget de menu déroulant personnalisé avec cadre
  Widget _buildDropdownField<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12), 
        border: Border.all(
          color: darkColor.withOpacity(0.2),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: darkColor.withOpacity(0.7),
              ),
            ),
            DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value: value,
                items: items,
                onChanged: onChanged,
                isExpanded: true,
                icon: Icon(Icons.arrow_drop_down, color: greenColor),
                style: TextStyle(
                  fontSize: 16,
                  color: darkColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightColor,
      body: CustomScrollView(
        slivers: [
          // AppBar avec gradient
          SliverAppBar(
            expandedHeight: 150.0,
            floating: false,
            pinned: true,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
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
                          'Ajouter un professeur',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Nouveau professeur",
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
          
          // Formulaire ou indicateur de chargement
          isLoading && availableClasses.isEmpty
              ? SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(orangeColor),
                        ),
                        SizedBox(height: 16),
                        Text(
                          "Chargement des données...",
                          style: TextStyle(
                            fontSize: 16,
                            color: darkColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Section des informations personnelles
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 6,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          padding: EdgeInsets.all(20),
                          margin: EdgeInsets.only(bottom: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: orangeColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.person_add,
                                      color: orangeColor,
                                      size: 24,
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Text(
                                    "Informations personnelles",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: darkColor,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 20),
                              
                              // Champs des informations personnelles
                              _buildInputField(
                                controller: nameController,
                                label: "Nom",
                              ),
                              _buildInputField(
                                controller: surnameController,
                                label: "Prénom",
                              ),
                              _buildInputField(
                                controller: emailController,
                                label: "E-mail",
                                suffixIcon: Icon(Icons.email, color: greenColor),
                              ),
                              _buildInputField(
                                controller: passwordController,
                                label: "Mot de passe",
                                obscureText: true,
                                suffixIcon: Icon(Icons.lock, color: greenColor),
                              ),
                              _buildInputField(
                                controller: idProfController,
                                label: "ID Professeur (généré automatiquement)",
                                readOnly: true,
                              ),
                            ],
                          ),
                        ),
                        
                        // Section des informations académiques
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 6,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          padding: EdgeInsets.all(20),
                          margin: EdgeInsets.only(bottom: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: greenColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.school,
                                      color: greenColor,
                                      size: 24,
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Text(
                                    "Informations pédagogiques",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: darkColor,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 20),
                              
                              // Matière enseignée
                              _buildInputField(
                                controller: subjectController,
                                label: "Matière enseignée",
                                suffixIcon: Icon(Icons.book, color: greenColor),
                              ),
                              
                              // Année scolaire
                              _buildDropdownField<String>(
                                label: "Année scolaire",
                                value: selectedYear,
                                items: schoolYears.map((year) {
                                  return DropdownMenuItem(value: year, child: Text(year));
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    selectedYear = value;
                                    _fetchClassesForSelectedLevels();
                                  });
                                },
                              ),
                              
                              // Niveaux d'enseignement
                              Container(
                                margin: EdgeInsets.only(bottom: 16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 10.0),
                                      child: Text(
                                        "Niveaux d'enseignement",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: darkColor,
                                        ),
                                      ),
                                    ),
                                    Wrap(
                                      spacing: 10.0,
                                      runSpacing: 10.0,
                                      children: levels.map((level) {
                                        bool isSelected = selectedLevels.contains(level);
                                        return InkWell(
                                          onTap: () {
                                            setState(() {
                                              if (isSelected) {
                                                selectedLevels.remove(level);
                                              } else {
                                                selectedLevels.add(level);
                                              }
                                              _fetchClassesForSelectedLevels();
                                            });
                                          },
                                          child: Container(
                                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                            decoration: BoxDecoration(
                                              color: isSelected 
                                                  ? greenColor 
                                                  : Colors.grey.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(30),
                                              border: Border.all(
                                                color: isSelected
                                                    ? greenColor
                                                    : darkColor.withOpacity(0.2),
                                                width: 1.0,
                                              ),
                                            ),
                                            child: Text(
                                              level,
                                              style: TextStyle(
                                                color: isSelected ? Colors.white : darkColor,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Sélection de classe
                              Container(
                                margin: EdgeInsets.only(bottom: 16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 10.0),
                                      child: Text(
                                        "Sélectionner une classe",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: darkColor,
                                        ),
                                      ),
                                    ),
                                    isLoading && selectedLevels.isNotEmpty && selectedYear != null
                                      ? Center(
                                          child: CircularProgressIndicator(
                                            valueColor: AlwaysStoppedAnimation<Color>(greenColor),
                                          ),
                                        )
                                      : availableClasses.isEmpty && selectedLevels.isNotEmpty && selectedYear != null
                                        ? Container(
                                            padding: EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: Colors.red.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: Colors.red.withOpacity(0.3),
                                                width: 1.0,
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(Icons.warning_amber_rounded, color: Colors.red),
                                                SizedBox(width: 10),
                                                Expanded(
                                                  child: Text(
                                                    "Aucune classe disponible pour ces niveaux et cette année!",
                                                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                        : Wrap(
                                            spacing: 10.0,
                                            runSpacing: 10.0,
                                            children: availableClasses.map((classe) {
                                              bool isSelected = selectedClass != null && 
                                                  selectedClass!["idClasse"] == classe["idClasse"];
                                              return InkWell(
                                                onTap: () {
                                                  setState(() {
                                                    selectedClass = classe;
                                                  });
                                                },
                                                child: Container(
                                                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                                  decoration: BoxDecoration(
                                                    color: isSelected 
                                                        ? greenColor 
                                                        : Colors.grey.withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(30),
                                                    border: Border.all(
                                                      color: isSelected
                                                          ? greenColor
                                                          : darkColor.withOpacity(0.2),
                                                      width: 1.0,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    "CLASSE ${classe["numeroClasse"]}",
                                                    style: TextStyle(
                                                      color: isSelected ? Colors.white : darkColor,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Bouton d'enregistrement
                        Container(
                          height: 55,
                          margin: EdgeInsets.only(bottom: 30),
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _saveProfessor,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: orangeColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 3,
                            ),
                            child: isLoading
                              ? CircularProgressIndicator(color: Colors.white)
                              : Text(
                                  "Ajouter le professeur",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}
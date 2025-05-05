import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/constants.dart';

class ModifierProfScreen extends StatefulWidget {
  final String idProf;

  const ModifierProfScreen({Key? key, required this.idProf}) : super(key: key);

  @override
  _ModifierProfScreenState createState() => _ModifierProfScreenState();
}

class _ModifierProfScreenState extends State<ModifierProfScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

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
  bool dataLoaded = false;
  String? originalEmail;
  String? oldClassId;
  bool passwordChanged = false;

  // Colores para combinar con la interfaz ModifierEleveScreen
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
    _loadProfessorData();
  }

  Future<void> _loadProfessorData() async {
    setState(() => isLoading = true);

    try {
      // Recherche des données du professeur depuis Firestore
      DocumentSnapshot profDoc = 
          await _db.collection('profs').doc(widget.idProf).get();

      if (profDoc.exists) {
        Map<String, dynamic> profData = profDoc.data() as Map<String, dynamic>;
        
        // Remplir les champs avec les données actuelles
        idProfController.text = profData['idProf'] ?? '';
        nameController.text = profData['nom'] ?? '';
        surnameController.text = profData['prenom'] ?? '';
        emailController.text = profData['email'] ?? '';
        subjectController.text = profData['matiere'] ?? '';
        
        // Conserver l'email original et l'ID de classe pour une utilisation ultérieure
        originalEmail = profData['email'];
        oldClassId = profData['classeId'];
        
        // Définir l'année scolaire
        selectedYear = profData['anneeScolaire'];
        
        // Extraire le niveau de la classe à partir des données
        if (profData['niveauClasse'] is List) {
          selectedLevels = List<String>.from(profData['niveauClasse']);
        } else if (profData['niveauClasse'] != null) {
          selectedLevels = [profData['niveauClasse'].toString()];
        }
        
        // Récupérer les classes disponibles en fonction des niveaux sélectionnés
        await _fetchClassesForSelectedLevels();
        
        // Sélectionner la classe actuelle du professeur
        for (var classe in availableClasses) {
          if (classe['idClasse'] == profData['classeId']) {
            selectedClass = classe;
            break;
          }
        }
        
        setState(() => dataLoaded = true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("❌ Données du professeur non trouvées!"),
          backgroundColor: Colors.red,
        ));
      }
    } catch (e) {
      print("❌ Erreur lors du chargement des données: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("❌ Erreur lors du chargement des données: $e"),
        backgroundColor: Colors.red,
      ));
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchClassesForSelectedLevels() async {
    if (selectedLevels.isEmpty || selectedYear == null) {
      setState(() {
        availableClasses = [];
        selectedClass = null;
      });
      return;
    }

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
        // Conserver la classe sélectionnée si elle est toujours disponible
        if (selectedClass != null) {
          bool classStillExists = classes.any((c) => c["idClasse"] == selectedClass!["idClasse"]);
          if (!classStillExists) {
            selectedClass = null;
          }
        }
      });
    } catch (e) {
      print("❌ Erreur lors de la récupération des classes: $e");
    }
  }

  Future<void> _updateProfessor() async {
    String idProf = idProfController.text.trim();
    String name = nameController.text.trim();
    String surname = surnameController.text.trim();
    String email = emailController.text.trim();
    String subject = subjectController.text.trim();

    if (name.isEmpty ||
        surname.isEmpty ||
        email.isEmpty ||
        subject.isEmpty ||
        selectedLevels.isEmpty ||
        selectedClass == null ||
        selectedYear == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("⚠️ Veuillez remplir tous les champs requis!"),
        backgroundColor: Colors.red,
      ));
      return;
    }

    setState(() => isLoading = true);

    try {
      // 1. Mise à jour des données de l'utilisateur dans Firebase Authentication si l'e-mail ou le mot de passe a changé
      // Note: Dans cette version, nous ne permettons pas la modification de l'email/password
      
      // 2. Mise à jour des données du professeur dans la collection profs
      Map<String, dynamic> profData = {
        "nom": name,
        "prenom": surname,
        "email": email,
        "matiere": subject,
        "classeId": selectedClass!["idClasse"],
        "anneeScolaire": selectedYear,
        "numeroClasse": selectedClass!["numeroClasse"],
        "niveauClasse": selectedClass!["niveau"],
      };

      await _db.collection('profs').doc(idProf).update(profData);

      // 3. Si la classe a changé, nous devons mettre à jour les informations du professeur dans l'ancienne et la nouvelle classe
      if (oldClassId != selectedClass!["idClasse"]) {
        // Supprimer le professeur de l'ancienne classe
        await _db.collection('classes').doc(oldClassId).update({
          "profs.$idProf": FieldValue.delete()
        });
        
        // Ajouter le professeur à la nouvelle classe
        await _db.collection('classes').doc(selectedClass!["idClasse"]).set({
          "profs": {
            idProf: {
              "nom": name,
              "prenom": surname,
              "matiere": subject,
            }
          }
        }, SetOptions(merge: true));
      } else {
        // Mettre à jour les données du professeur dans la même classe
        await _db.collection('classes').doc(selectedClass!["idClasse"]).update({
          "profs.$idProf": {
            "nom": name,
            "prenom": surname,
            "matiere": subject,
          }
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("✅ Données du professeur mises à jour avec succès!"),
        backgroundColor: greenColor,
      ));
      
      // Retour à l'écran précédent après une mise à jour réussie
      Navigator.pop(context, true);
      
    } catch (e) {
      print("❌ Erreur lors de la mise à jour des données: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("❌ Échec de la mise à jour des données du professeur! $e"),
        backgroundColor: Colors.red,
      ));
    } finally {
      setState(() => isLoading = false);
    }
  }

  // Champ d'entrée personnalisé pour maintenir une conception cohérente
  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    bool readOnly = false,
    Icon? suffixIcon,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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

  // Champ dropdown personnalisé pour maintenir une conception cohérente
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
          // Gradient AppBar
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
                          'Modifier le professeur',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          idProfController.text.isNotEmpty 
                              ? "ID: ${idProfController.text}" 
                              : "Données du professeur",
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
          
          // Indicateur de chargement ou contenu du formulaire
          isLoading && !dataLoaded
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
                        // Carte de la section Formulaire - Informations personnelles
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
                                      Icons.person,
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
                              
                              // Champs d'informations personnelles
                              _buildInputField(
                                controller: idProfController,
                                label: "ID du professeur",
                                readOnly: true,
                              ),
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
                                label: "Email",
                                readOnly: true, // Email non modifiable
                                suffixIcon: Icon(Icons.lock, color: Colors.grey),
                              ),
                              _buildInputField(
                                controller: passwordController,
                                label: "Mot de passe",
                                readOnly: true, // Mot de passe non modifiable
                                suffixIcon: Icon(Icons.lock, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        
                        // Carte d'informations académiques
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
                                    "Informations académiques",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: darkColor,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 20),
                              
                              // Champ Matière
                              _buildInputField(
                                controller: subjectController,
                                label: "Matière enseignée",
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
                                  });
                                  _fetchClassesForSelectedLevels();
                                },
                              ),
                              
                              // Sélection des niveaux
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
                                              isSelected 
                                                  ? selectedLevels.remove(level)
                                                  : selectedLevels.add(level);
                                            });
                                            _fetchClassesForSelectedLevels();
                                          },
                                          child: Container(
                                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                            decoration: BoxDecoration(
                                              color: isSelected 
                                                  ? greenColor 
                                                  : Colors.grey.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(30),
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
                                    availableClasses.isEmpty
                                      ? Container(
                                          padding: EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: Colors.red.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(Icons.warning_amber_rounded, color: Colors.red),
                                              SizedBox(width: 10),
                                              Expanded(
                                                child: Text(
                                                  "Aucune classe disponible pour les niveaux et l'année sélectionnés!",
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
                        
                        // Bouton de sauvegarde
                        Container(
                          height: 55,
                          margin: EdgeInsets.only(bottom: 30),
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _updateProfessor,
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
                                    "Enregistrer les modifications",
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
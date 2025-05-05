import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'absence_details_screen.dart';
import 'package:intl/intl.dart';

class AbsencesScreen extends StatefulWidget {
  const AbsencesScreen({super.key});

  @override
  _AbsencesScreenState createState() => _AbsencesScreenState();
}

class _AbsencesScreenState extends State<AbsencesScreen> {
  String? selectedClass, selectedDate, selectedMatiere, selectedHeure;
  List<Map<String, dynamic>> classes = [];
  final List<String> matieres = [
    "Math",
    "Français",
    "Science",
    "Histoire",
    "Géographie",
    "Physique"
  ];
  final List<String> heures = ["08:00", "10:00", "12:00", "14:00", "16:00"];
  bool isLoading = true;
  
  // Couleurs pour correspondre au style AjouterProfScreen
  final Color orangeColor = Color.fromARGB(255, 218, 64, 3);
  final Color greenColor = Color.fromARGB(255, 1, 110, 5);
  final Color lightColor = Color.fromARGB(255, 255, 255, 255);
  final Color darkColor = Color(0xFF333333);

  @override
  void initState() {
    super.initState();
    _loadClasses();

    // Initialiser la date à aujourd'hui
    selectedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  // Charger les classes depuis Firebase
  Future<void> _loadClasses() async {
    setState(() {
      isLoading = true;
    });

    try {
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance.collection('classes').get();

      List<Map<String, dynamic>> loadedClasses = [];
      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        // Stocker l'ID du document et les informations de la classe
        loadedClasses.add({
          'id': doc.id,
          'nom': data['numeroClasse'] != null
              ? "${data['niveauEtude']?[0]['1ère année'] ?? ''} ${data['numeroClasse']}"
              : doc.id,
        });
      }

      setState(() {
        classes = loadedClasses;
        isLoading = false;
      });
    } catch (e) {
      print("Erreur lors du chargement des classes: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  // Sélectionner une date
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2025, 12, 31),
    );

    if (picked != null) {
      setState(() {
        selectedDate = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  // Widget de champ de saisie personnalisé avec cadre
  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?) onChanged,
    Icon? suffixIcon,
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
              child: DropdownButton<String>(
                value: value,
                items: items,
                onChanged: onChanged,
                isExpanded: true,
                icon: Icon(Icons.arrow_drop_down, color: greenColor),
                hint: Text(
                  "Sélectionner $label",
                  style: TextStyle(color: darkColor.withOpacity(0.5)),
                ),
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

  // Widget de champ de date personnalisé
  Widget _buildDateField() {
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
              "Date",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: darkColor.withOpacity(0.7),
              ),
            ),
            InkWell(
              onTap: () => _selectDate(context),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    selectedDate ?? "Sélectionner une date",
                    style: TextStyle(
                      fontSize: 16,
                      color: darkColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Icon(Icons.calendar_today, color: greenColor),
                ],
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
                          'Gestion des absences',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Enregistrement des absences",
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
          isLoading
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
                        // Section des critères d'absence
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
                                      Icons.school,
                                      color: orangeColor,
                                      size: 24,
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Text(
                                    "Informations de classe",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: darkColor,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 20),
                              
                              // Champ Classe
                              _buildDropdownField(
                                label: "Classe",
                                value: selectedClass,
                                items: classes.map((Map<String, dynamic> classItem) {
                                  return DropdownMenuItem<String>(
                                    value: classItem['id'],
                                    child: Text(classItem['nom']),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    selectedClass = value;
                                  });
                                },
                                suffixIcon: Icon(Icons.class_, color: greenColor),
                              ),
                            ],
                          ),
                        ),
                        
                        // Section des informations d'absence
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
                                      Icons.event_note,
                                      color: greenColor,
                                      size: 24,
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Text(
                                    "Détails de l'absence",
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
                              _buildDropdownField(
                                label: "Matière",
                                value: selectedMatiere,
                                items: matieres.map((String item) {
                                  return DropdownMenuItem<String>(
                                    value: item,
                                    child: Text(item),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    selectedMatiere = value;
                                  });
                                },
                                suffixIcon: Icon(Icons.book, color: greenColor),
                              ),
                              
                              // Champ Date
                              _buildDateField(),
                              
                              // Champ Heure
                              _buildDropdownField(
                                label: "Heure",
                                value: selectedHeure,
                                items: heures.map((String item) {
                                  return DropdownMenuItem<String>(
                                    value: item,
                                    child: Text(item),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    selectedHeure = value;
                                  });
                                },
                                suffixIcon: Icon(Icons.access_time, color: greenColor),
                              ),
                            ],
                          ),
                        ),
                        
                        // Bouton suivant
                        Container(
                          height: 55,
                          margin: EdgeInsets.only(bottom: 30),
                          child: ElevatedButton(
                            onPressed: () {
                              if (selectedClass != null &&
                                  selectedMatiere != null &&
                                  selectedDate != null &&
                                  selectedHeure != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AbsenceDetailsScreen(
                                      selectedClass: selectedClass!,
                                      selectedMatiere: selectedMatiere!,
                                      selectedDate: selectedDate!,
                                      selectedHeure: selectedHeure!,
                                    ),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        "⚠️ Veuillez sélectionner toutes les options."),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: orangeColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 3,
                            ),
                            child: Text(
                              "SUIVANT",
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
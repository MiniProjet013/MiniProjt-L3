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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(232, 2, 196, 34),
        title: Text("Absences"),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sélection de classe
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Classe",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        DropdownButton<String>(
                          value: selectedClass,
                          isExpanded: true,
                          hint: Text("Sélectionner une classe"),
                          items: classes.map((Map<String, dynamic> classItem) {
                            return DropdownMenuItem<String>(
                              value: classItem['id'],
                              child: Text(classItem['nom']),
                            );
                          }).toList(),
                          onChanged: (String? value) {
                            setState(() {
                              selectedClass = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                  // Sélection de matière
                  _buildDropdown(
                    "Matière",
                    matieres,
                    selectedMatiere,
                    (value) => setState(() => selectedMatiere = value),
                  ),

                  // Sélection de date
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Date",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Row(
                          children: [
                            Expanded(
                              child:
                                  Text(selectedDate ?? "Sélectionner une date"),
                            ),
                            IconButton(
                              icon: Icon(Icons.calendar_today),
                              onPressed: () => _selectDate(context),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Sélection d'heure
                  _buildDropdown(
                    "Heure",
                    heures,
                    selectedHeure,
                    (value) => setState(() => selectedHeure = value),
                  ),

                  SizedBox(height: 20),

                  // Bouton suivant
                  Center(
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
                                  "Veuillez sélectionner toutes les options."),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding:
                            EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                      ),
                      child: Text(
                        "SUIVANT",
                        style: TextStyle(color: Colors.deepOrangeAccent),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String? selectedItem,
      Function(String?) onChanged) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
          DropdownButton<String>(
            value: selectedItem,
            isExpanded: true,
            hint: Text("Sélectionner $label"),
            items: items.map((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(item),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

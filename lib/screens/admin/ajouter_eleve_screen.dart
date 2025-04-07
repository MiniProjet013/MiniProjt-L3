import 'package:flutter/material.dart';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class AjouterEleveScreen extends StatefulWidget {
  @override
  _AjouterEleveScreenState createState() => _AjouterEleveScreenState();
}

class _AjouterEleveScreenState extends State<AjouterEleveScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController surnameController = TextEditingController();
  final TextEditingController idController = TextEditingController();

  String? selectedDate;
  String? selectedLevel;
  String? selectedYear;
  Map<String, dynamic>? selectedClass;
  List<Map<String, dynamic>> availableClasses = [];

  final List<String> levels = [
    "1ère année", "2ème année", "3ème année",
    "4ème année", "5ème année", "6ème année"
  ];

  final List<String> schoolYears = [
    "2023-2024", "2024-2025", "2025-2026",
    "2026-2027", "2027-2028"
  ];

  @override
  void initState() {
    super.initState();
    _generateAndSetId();
  }

  void _generateAndSetId() {
    String generatedId = "E-${Random().nextInt(9000) + 1000}";
    setState(() {
      idController.text = generatedId;
    });
  }

  Future<void> _fetchClassesForSelectedLevelAndYear() async {
    if (selectedLevel == null || selectedYear == null) {
      setState(() {
        availableClasses = [];
        selectedClass = null;
      });
      return;
    }

    try {
      QuerySnapshot snapshot = await _db
          .collection('classes')
          .where("niveauxEtude", arrayContains: selectedLevel)
          .where("anneeScolaire", isEqualTo: selectedYear)
          .get();

      List<Map<String, dynamic>> classes = snapshot.docs.map((doc) {
        return {
          "idClasse": doc.id,
          "numeroClasse": doc["numeroClasse"],
        };
      }).toList();

      setState(() {
        availableClasses = classes;
        selectedClass = null;
      });
    } catch (e) {
      print("❌ خطأ في جلب الأقسام: $e");
    }
  }

  Future<void> _saveEleve() async {
    String idEleve = idController.text.trim();
    String name = nameController.text.trim();
    String surname = surnameController.text.trim();

    if (name.isEmpty || surname.isEmpty || selectedDate == null ||
        selectedLevel == null || selectedYear == null || selectedClass == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("⚠️ الرجاء إدخال جميع الحقول!"),
        backgroundColor: Colors.red,
      ));
      return;
    }

    try {
      Map<String, dynamic> eleveData = {
        "idEleve": idEleve,
        "nom": name,
        "prenom": surname,
        "dateNaissance": selectedDate,
        "niveau": selectedLevel,
        "anneeScolaire": selectedYear,
        "classeId": selectedClass!["idClasse"],
        "numeroClasse": selectedClass!["numeroClasse"],
      };

      await _db.collection('eleves').doc(idEleve).set(eleveData);

      await _db.collection('classes').doc(selectedClass!["idClasse"]).set({
        "eleves": {
          idEleve: {
            "nom": name,
            "prenom": surname,
          }
        }
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("✅ تم إضافة التلميذ بنجاح!"),
        backgroundColor: Colors.green,
      ));

      setState(() {
        _generateAndSetId();
        nameController.clear();
        surnameController.clear();
        selectedDate = null;
        selectedLevel = null;
        selectedYear = null;
        availableClasses.clear();
        selectedClass = null;
      });
    } catch (e) {
      print("❌ خطأ أثناء الإضافة: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("❌ فشل إضافة التلميذ! حاول مجددًا."),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(232, 2, 196, 34),
        title: Text("Ajouter un élève"),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(controller: nameController, decoration: InputDecoration(labelText: "Nom", border: OutlineInputBorder())),
            SizedBox(height: 10),
            TextField(controller: surnameController, decoration: InputDecoration(labelText: "Prénom", border: OutlineInputBorder())),
            SizedBox(height: 10),

            // ✅ اختيار تاريخ الميلاد بطريقة احترافية
            Text("Date de naissance", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            TextField(
              decoration: InputDecoration(
                hintText: "Sélectionner une date",
                suffixIcon: Icon(Icons.calendar_today),
                border: OutlineInputBorder(),
              ),
              readOnly: true,
              controller: TextEditingController(text: selectedDate),
              onTap: () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2101),
                );
                if (pickedDate != null) {
                  setState(() {
                    selectedDate = "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
                  });
                }
              },
            ),
            SizedBox(height: 10),

            TextField(controller: idController, decoration: InputDecoration(labelText: "ID Élève", border: OutlineInputBorder()), readOnly: true),
            SizedBox(height: 10),

            DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: "Niveau d'étude", border: OutlineInputBorder()),
              value: selectedLevel,
              items: levels.map((level) {
                return DropdownMenuItem(value: level, child: Text(level));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedLevel = value;
                  _fetchClassesForSelectedLevelAndYear();
                });
              },
            ),
            SizedBox(height: 10),

            DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: "Année scolaire", border: OutlineInputBorder()),
              value: selectedYear,
              items: schoolYears.map((year) {
                return DropdownMenuItem(value: year, child: Text(year));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedYear = value;
                  _fetchClassesForSelectedLevelAndYear();
                });
              },
            ),
            SizedBox(height: 10),

            Text("Sélectionner un Classe", style: TextStyle(fontWeight: FontWeight.bold)),
            availableClasses.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text("⚠️ لا توجد أقسام متاحة لهذه السنة والمستوى!",
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  )
                : Wrap(
                    spacing: 8.0,
                    children: availableClasses.map((classe) {
                      return ChoiceChip(
                        label: Text("CLASSE ${classe["numeroClasse"]}"),
                        selected: selectedClass == classe,
                        onSelected: (selected) {
                          setState(() {
                            selectedClass = selected ? classe : null;
                          });
                        },
                      );
                    }).toList(),
                  ),
            SizedBox(height: 20),

            ElevatedButton(
              onPressed: _saveEleve,
              child: Text("Enregistrer", style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrangeAccent),
            ),
          ],
        ),
      ),
    );
  }
}

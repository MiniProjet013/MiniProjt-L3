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
        content: Text("⚠️ الرجاء إدخال جميع الحقول!"),
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
        content: Text("✅ تم إضافة الأستاذ بنجاح!"),
        backgroundColor: Colors.green,
      ));

      setState(() {
        _generateAndSetId();
        nameController.clear();
        surnameController.clear();
        emailController.clear();
        passwordController.clear();
        subjectController.clear();
        selectedLevels.clear();
        availableClasses.clear();
        selectedClass = null;
        selectedYear = null;
        isLoading = false;
      });
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
        content: Text("❌ فشل إضافة الأستاذ! حاول مجددًا."),
        backgroundColor: Colors.red,
      ));
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 62, 184, 6),
        title: Text("Ajouter un professeur"),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
                controller: idProfController,
                decoration: InputDecoration(
                    labelText: "ID Professeur", border: OutlineInputBorder()),
                readOnly: true),
            SizedBox(height: 10),
            TextField(
                controller: nameController,
                decoration: InputDecoration(
                    labelText: "Nom", border: OutlineInputBorder())),
            SizedBox(height: 10),
            TextField(
                controller: surnameController,
                decoration: InputDecoration(
                    labelText: "Prénom", border: OutlineInputBorder())),
            SizedBox(height: 10),
            TextField(
                controller: emailController,
                decoration: InputDecoration(
                    labelText: "E-mail", border: OutlineInputBorder())),
            SizedBox(height: 10),
            TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                    labelText: "Mot de passe", border: OutlineInputBorder())),
            SizedBox(height: 10),
            TextField(
                controller: subjectController,
                decoration: InputDecoration(
                    labelText: "Matière", border: OutlineInputBorder())),
            SizedBox(height: 10),

            Text("Sélectionner l'année scolaire", style: TextStyle(fontWeight: FontWeight.bold)),
            DropdownButtonFormField<String>(
              value: selectedYear,
              decoration: InputDecoration(border: OutlineInputBorder()),
              items: schoolYears.map((year) {
                return DropdownMenuItem(
                  value: year,
                  child: Text(year),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedYear = value;
                });
                _fetchClassesForSelectedLevels();
              },
            ),
            SizedBox(height: 10),

            Wrap(
              spacing: 8.0,
              children: levels.map((level) {
                return FilterChip(
                  label: Text(level),
                  selected: selectedLevels.contains(level),
                  onSelected: (selected) {
                    setState(() {
                      selected
                          ? selectedLevels.add(level)
                          : selectedLevels.remove(level);
                    });
                    _fetchClassesForSelectedLevels();
                  },
                );
              }).toList(),
            ),
            SizedBox(height: 10),

            Text("Sélectionner Numéro de Classe", style: TextStyle(fontWeight: FontWeight.bold)),
            Wrap(
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
            isLoading
                ? Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _saveProfessor,
                    child: Text("Enregistrer",style: TextStyle(color: Colors.white),),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrangeAccent),
                  ),
          ],
        ),
      ),
    );
  }
}

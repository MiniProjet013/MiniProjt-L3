import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class AjouterClasseScreen extends StatefulWidget {
  @override
  _AjouterClasseScreenState createState() => _AjouterClasseScreenState();
}

class _AjouterClasseScreenState extends State<AjouterClasseScreen> {
  final TextEditingController idController = TextEditingController();
  final TextEditingController numberController = TextEditingController();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final List<String> levels = [
    "1ère année", "2ème année", "3ème année",
    "4ème année", "5ème année", "6ème année"
  ];
  List<String> selectedLevels = [];

  // ✅ قائمة السنوات الدراسية
  final List<String> schoolYears = [
    "2023-2024",
    "2024-2025",
    "2025-2026",
    "2026-2027",
    "2027-2028"
  ];
  String? selectedYear; // ✅ المتغير لحفظ السنة المختارة

  @override
  void initState() {
    super.initState();
    idController.text = _generateId();
  }

  String _generateId() {
    return "C-${Random().nextInt(9000) + 1000}";
  }

  Future<void> _saveClass() async {
    String idClasse = idController.text.trim();
    String numeroClasse = numberController.text.trim();

    if (idClasse.isEmpty || numeroClasse.isEmpty || selectedLevels.isEmpty || selectedYear == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ الرجاء إدخال جميع الحقول!"), backgroundColor: Colors.red),
      );
      return;
    }

    try {
      await _db.collection('classes').doc(idClasse).set({
        "idClasse": idClasse,
        "numeroClasse": numeroClasse,
        "niveauxEtude": selectedLevels,
        "anneeScolaire": selectedYear, // ✅ حفظ السنة الدراسية في Firestore
         "timestamp": FieldValue.serverTimestamp(), // ✅ إضافة الطابع الزمني
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ تم إضافة القسم بنجاح!"), backgroundColor: Colors.green),
      );

      setState(() {
        idController.text = _generateId();
        numberController.clear();
        selectedLevels.clear();
        selectedYear = null;
      });

    } catch (e) {
      print("❌ خطأ أثناء الإضافة: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ فشل إضافة القسم! حاول مجدداً."), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(232, 2, 196, 34),
        title: Text("Ajouter une classe"),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // ✅ إدخال معرف القسم
            TextField(
              controller: idController,
              decoration: InputDecoration(labelText: "ID Classe", border: OutlineInputBorder()),
              readOnly: true, 
            ),
            SizedBox(height: 10),

            // ✅ إدخال رقم القسم
            TextField(
              controller: numberController,
              decoration: InputDecoration(labelText: "Numéro de classe", border: OutlineInputBorder()),
            ),
            SizedBox(height: 10),

            // ✅ اختيار السنة الدراسية
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
              },
            ),
            SizedBox(height: 10),

            // ✅ اختيار المراحل الدراسية
            Text("Sélectionner les niveaux d'étude", style: TextStyle(fontWeight: FontWeight.bold)),
            Wrap(
              children: levels.map((level) {
                return ChoiceChip(
                  label: Text(level),
                  selected: selectedLevels.contains(level),
                  onSelected: (selected) {
                    setState(() {
                      selected ? selectedLevels.add(level) : selectedLevels.remove(level);
                    });
                  },
                );
              }).toList(),
            ),
            SizedBox(height: 20),

            // ✅ زر الحفظ في Firestore
            ElevatedButton(
              onPressed: _saveClass,
              child: Text("Enregistrer", style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrangeAccent,
                padding: EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class RemarquesScreen extends StatefulWidget {
  @override
  _RemarquesScreenState createState() => _RemarquesScreenState();
}

class _RemarquesScreenState extends State<RemarquesScreen> {
  String? selectedClasse;
  String? selectedEleve;
  String? selectedDate;
  final TextEditingController remarqueController = TextEditingController();

  final List<String> classes = ["Classe 1", "Classe 2", "Classe 3"];
  final Map<String, List<String>> eleves = {
    "Classe 1": ["Ali", "Fatima", "Omar"],
    "Classe 2": ["Youssef", "Sara", "Kamal"],
    "Classe 3": ["Lina", "Hassan", "Meryem"],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Remarques"),
        backgroundColor: Color.fromARGB(232, 2, 196, 34),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // اختيار القسم
            Text("Classe",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            DropdownButton<String>(
              value: selectedClasse,
              hint: Text("Sélectionner une classe"),
              items: classes.map((classe) {
                return DropdownMenuItem(
                  value: classe,
                  child: Text(classe),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedClasse = value;
                  selectedEleve = null; // إعادة تعيين التلميذ عند تغيير القسم
                });
              },
            ),

            SizedBox(height: 10),

            // اختيار التلميذ
            Text("Élève",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            DropdownButton<String>(
              value: selectedEleve,
              hint: Text("Sélectionner un élève"),
              items: (eleves[selectedClasse] ?? []).map((eleve) {
                return DropdownMenuItem(
                  value: eleve,
                  child: Text(eleve),
                );
              }).toList(),
              onChanged: selectedClasse == null
                  ? null
                  : (value) {
                      setState(() {
                        selectedEleve = value;
                      });
                    },
            ),

            SizedBox(height: 10),

            // اختيار يوم إدخال الملاحظة
            Text("Date",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            TextField(
              decoration: InputDecoration(
                hintText: "Sélectionner une date",
                suffixIcon: Icon(Icons.calendar_today),
              ),
              readOnly: true,
              onTap: () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2101),
                );
                if (pickedDate != null) {
                  setState(() {
                    selectedDate =
                        "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
                  });
                }
              },
            ),

            SizedBox(height: 10),

            // مكان كتابة الملاحظة
            Text("Remarque",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            TextField(
              controller: remarqueController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "Écrire une remarque...",
                border: OutlineInputBorder(),
              ),
            ),

            SizedBox(height: 20),

            // زر النشر
            Center(
              child: ElevatedButton(
                onPressed: () {
                  if (selectedClasse != null &&
                      selectedEleve != null &&
                      selectedDate != null &&
                      remarqueController.text.isNotEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Remarque ajoutée avec succès!")),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text("Veuillez remplir tous les champs.")),
                    );
                  }
                },
                child: Text(
                  "Publier",
                  style: TextStyle(color: Colors.deepOrangeAccent),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

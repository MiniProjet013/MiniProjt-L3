import 'package:flutter/material.dart';
import 'absence_details_screen.dart';

class AbsencesScreen extends StatefulWidget {
  @override
  _AbsencesScreenState createState() => _AbsencesScreenState();
}

class _AbsencesScreenState extends State<AbsencesScreen> {
  String? selectedClass, selectedDate, selectedMatiere, selectedHeure;
  final List<String> classes = ["Classe 1", "Classe 2", "Classe 3"];
  final List<String> matieres = ["Math", "Science", "Histoire"];
  final List<String> heures = ["08:00", "10:00", "14:00"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
         backgroundColor: Color.fromARGB(232, 2, 196, 34),
          title: Text("Absences")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDropdown("Classe", classes, selectedClass,
                (value) => setState(() => selectedClass = value)),
            _buildDropdown("Matière", matieres, selectedMatiere,
                (value) => setState(() => selectedMatiere = value)),
            _buildDropdown("Heure", heures, selectedHeure,
                (value) => setState(() => selectedHeure = value)),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  if (selectedClass != null &&
                      selectedMatiere != null &&
                      selectedHeure != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AbsenceDetailsScreen(
                          selectedClass: selectedClass!,
                          selectedMatiere: selectedMatiere!,
                          selectedDate: DateTime.now().toString().split(" ")[0],
                          selectedHeure: selectedHeure!,
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              "Veuillez sélectionner toutes les options.")),
                    );
                  }
                },
                child: Text("SUIVANT",style:TextStyle(color: Colors.deepOrangeAccent),),
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
              return DropdownMenuItem(value: item, child: Text(item));
            }).toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

class MoyenneAnnuelleScreen extends StatelessWidget {
  final List<Map<String, dynamic>> notes = [
    {
      "matiere": "Mathématiques",
      "devoirs": "14",
      "examens": "15",
      "evaluation": "16",
      "moyenne": "15"
    },
    {
      "matiere": "Physique",
      "devoirs": "16",
      "examens": "17",
      "evaluation": "14",
      "moyenne": "15.7"
    },
    {
      "matiere": "Histoire",
      "devoirs": "12",
      "examens": "13",
      "evaluation": "15",
      "moyenne": "13.3"
    },
    {
      "matiere": "Français",
      "devoirs": "18",
      "examens": "19",
      "evaluation": "17",
      "moyenne": "18"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(232, 2, 196, 34),title: Text("Moyenne Annuelle")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: [
              DataColumn(label: Text("Matière")),
              DataColumn(label: Text("Devoirs")),
              DataColumn(label: Text("Examens")),
              DataColumn(label: Text("Évaluation")),
              DataColumn(label: Text("Moyenne")),
            ],
            rows: notes.map((note) {
              return DataRow(cells: [
                DataCell(Text(note["matiere"]!)),
                DataCell(Text(note["devoirs"]!)),
                DataCell(Text(note["examens"]!)),
                DataCell(Text(note["evaluation"]!)),
                DataCell(Text(note["moyenne"]!,
                    style: TextStyle(fontWeight: FontWeight.bold))),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }
}

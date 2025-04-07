import 'package:flutter/material.dart';
import 'eleve_absence_details_screen.dart';

class AbsencesEleveScreen extends StatelessWidget {
  final List<Map<String, String>> eleveAbsences = [
    {"name": "Ali Mohamed", "time": "08:00", "date": "10/03/2024"},
    {"name": "Fatima Youssef", "time": "10:00", "date": "11/03/2024"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Color.fromARGB(232, 2, 196, 34),
      title: Text("Absences des élèves")),
      body: ListView.builder(
        itemCount: eleveAbsences.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(eleveAbsences[index]["name"]!),
            subtitle: Text("📅 ${eleveAbsences[index]["date"]}  🕒 ${eleveAbsences[index]["time"]}"),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EleveAbsenceDetailsScreen(
                    name: eleveAbsences[index]["name"]!,
                    time: eleveAbsences[index]["time"]!,
                    date: eleveAbsences[index]["date"]!,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

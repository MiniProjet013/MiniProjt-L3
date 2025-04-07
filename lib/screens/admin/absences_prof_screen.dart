import 'package:flutter/material.dart';
import 'prof_absence_details_screen.dart';

class AbsencesProfScreen extends StatelessWidget {
  final List<Map<String, String>> profAbsences = [
    {"name": "Salem Mohammed", "time": "08:00", "date": "10/03/2024", "reason": "Maladie"},
    {"name": "Bensmain Hichem", "time": "10:00", "date": "11/03/2024", "reason": "Voyage"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(232, 2, 196, 34),
        title: Text("Absences des professeurs")),
      body: ListView.builder(
        itemCount: profAbsences.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(profAbsences[index]["name"]!),
            subtitle: Text("📅 ${profAbsences[index]["date"]}  🕒 ${profAbsences[index]["time"]}"),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfAbsenceDetailsScreen(
                    name: profAbsences[index]["name"]!,
                    time: profAbsences[index]["time"]!,
                    date: profAbsences[index]["date"]!,
                    reason: profAbsences[index]["reason"]!,
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

import 'package:flutter/material.dart';

class ExamensScreen extends StatelessWidget {
  final List<Map<String, String>> events = [
    {"title": "Cérémonie de fin d'année", "date": "10 Juin 2024"},
    {"title": "Réunion des parents", "date": "15 Juin 2024"},
    {"title": "Examen final", "date": "20 Juin 2024"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
       backgroundColor: Color.fromARGB(232, 2, 196, 34),
        title: Row(
          children: [
            Icon(Icons.school, color: Colors.white),
            SizedBox(width: 10),
            Text("EVENTES", style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            for (var event in events) 
              Card(
                elevation: 3,
                child: ListTile(
                  leading: Icon(Icons.event, color: const Color.fromARGB(185, 255, 81, 0)),
                  title: Text(event["title"]!, style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("📅 ${event["date"]}"),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

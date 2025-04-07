import 'package:flutter/material.dart';

class ProfAbsenceDetailsScreen extends StatelessWidget {
  final String name;
  final String time;
  final String date;
  final String reason;

  ProfAbsenceDetailsScreen({required this.name, required this.time, required this.date, required this.reason});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(232, 2, 196, 34),
        title: Text("Détails de l'absence")),
      body: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color.fromARGB(230, 241, 146, 4).withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: const Color.fromARGB(255, 255, 153, 0), width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.person, size: 100, color: const Color.fromARGB(255, 255, 123, 0)),
              SizedBox(height: 20),
              _buildInfoRow("👤 Nom:", name),
              _buildInfoRow("📅 Date d'absence:", date),
              _buildInfoRow("🕒 Heure d'absence:", time),
              _buildInfoRow("📌 Raison:", reason, color: Colors.red),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color color = Colors.black87}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(value, style: TextStyle(fontSize: 20, color: color)),
        ],
      ),
    );
  }
}

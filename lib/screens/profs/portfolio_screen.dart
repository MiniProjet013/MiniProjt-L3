import 'package:flutter/material.dart';

class PortfolioScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
       backgroundColor: Color.fromARGB(232, 2, 196, 34),
        title: Row(
          children: [
            Icon(Icons.person, color: Colors.white),
            SizedBox(width: 10),
            Text("PORTFOLIO", style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
      body: Center(
        child: Column(
          children: [
            SizedBox(height: 20),
            CircleAvatar(
                radius: 50, backgroundImage: AssetImage("assets/teacher.jpg")),
            SizedBox(height: 20),
            Text("Nom: M. Jean Dupont",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text("Matière: Mathématiques", style: TextStyle(fontSize: 16)),
            Text("Téléphone: +212 600 000 000", style: TextStyle(fontSize: 16)),
            Text("E-mail: jean.dupont@email.com",
                style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

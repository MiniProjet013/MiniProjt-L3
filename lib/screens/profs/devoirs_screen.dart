import 'package:flutter/material.dart';

class DevoirScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor:  Color.fromARGB(232, 2, 196, 34),
        title: Row(
          children: [
            Icon(Icons.assignment, color: Colors.white),
            SizedBox(width: 10),
            Text("DEVOIRS", style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("SUJET", style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 5),
            TextField(
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Écrire le sujet...",
              ),
            ),
            SizedBox(height: 20),
            _buildButton("AJOUTER", () {}),
            SizedBox(height: 10),
            Center(child: Text("OU", style: TextStyle(fontWeight: FontWeight.bold))),
            SizedBox(height: 10),
            _buildButton("AJOUTER DEVOIR PDF", () {}),
            SizedBox(height: 10),
            Center(child: Text("OU", style: TextStyle(fontWeight: FontWeight.bold))),
            SizedBox(height: 10),
            _buildButton("AJOUTER DEVOIR PHOTO", () {}),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(String text, VoidCallback onPressed) {
    return Center(
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor:Color.fromARGB(213, 230, 122, 0),
          shape: StadiumBorder(),
          padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
        ),
        child: Text(text, style: TextStyle(color: Colors.white, fontSize: 16)),
      ),
    );
  }
}

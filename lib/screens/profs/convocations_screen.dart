import 'package:flutter/material.dart';

class ConvocationsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor:  Color.fromARGB(232, 2, 196, 34),
        title: Row(
          children: [
            Icon(Icons.mail, color: Colors.white),
            SizedBox(width: 10),
            Text("CONVOCATIONS", style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildDropdown("CLASSE", ["Classe 1", "Classe 2", "Classe 3"]),
            _buildDropdown("ÉLÈVE", ["Ali", "Fatima", "Omar"]),
            TextField(
              decoration: InputDecoration(labelText: "MESSAGE", border: OutlineInputBorder()),
              maxLines: 3,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(185, 255, 123, 0), shape: StadiumBorder(),
              ),
              child: Text("ENVOYER", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: DropdownButtonFormField(
        decoration: InputDecoration(labelText: label, border: OutlineInputBorder()),
        items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
        onChanged: (value) {},
      ),
    );
  }
}

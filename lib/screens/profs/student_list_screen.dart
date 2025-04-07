import 'package:flutter/material.dart';

class StudentListScreen extends StatefulWidget {
  @override
  _StudentListScreenState createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  String? selectedClass;
  final Map<String, List<String>> studentsByClass = {
    "Classe 1": ["Ali", "Fatima", "Omar"],
    "Classe 2": ["Youssef", "Sara", "Kamal"],
    "Classe 3": ["Lina", "Hassan", "Meryem"],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
      backgroundColor: Color.fromARGB(232, 2, 196, 34),
        title: Row(
          children: [
            Icon(Icons.people, color: Colors.white),
            SizedBox(width: 10),
            Text("LISTE D'ÉLÈVES", style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildDropdown("CLASSE", studentsByClass.keys.toList()),
          Expanded(
            child: ListView.builder(
              itemCount: selectedClass == null ? 0 : studentsByClass[selectedClass!]!.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(studentsByClass[selectedClass!]![index]),
                  leading: Icon(Icons.person),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: DropdownButtonFormField(
        decoration: InputDecoration(labelText: label, border: OutlineInputBorder()),
        items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
        onChanged: (value) => setState(() => selectedClass = value as String),
      ),
    );
  }
}

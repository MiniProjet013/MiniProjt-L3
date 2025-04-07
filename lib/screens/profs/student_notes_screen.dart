import 'package:flutter/material.dart';

class StudentNotesScreen extends StatefulWidget {
  @override
  _StudentNotesScreenState createState() => _StudentNotesScreenState();
}

class _StudentNotesScreenState extends State<StudentNotesScreen> {
  List<Map<String, dynamic>> students = [
    {"name": "Jean Dupont", "note": ""},
    {"name": "Marie Curie", "note": ""},
    {"name": "Albert Einstein", "note": ""},
    {"name": "Isaac Newton", "note": ""},
    {"name": "Galilée Galiléo", "note": ""},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Entrer les notes"),
       backgroundColor: Color.fromARGB(232, 2, 196, 34),
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: students.length,
                itemBuilder: (context, index) {
                  return Card(
                    elevation: 2,
                    margin: EdgeInsets.symmetric(vertical: 10),
                    child: ListTile(
                      title: Text(students[index]["name"],
                          style: TextStyle(fontSize: 18)),
                      trailing: Container(
                        width: 80,
                        child: TextField(
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: "Note",
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            setState(() {
                              students[index]["note"] = value;
                            });
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // ✅ هنا يمكن تنفيذ عملية حفظ النقاط أو إرسالها إلى قاعدة بيانات
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content:
                          Text("Les notes ont été enregistrées avec succès !")),
                );
              },
              child: Text("PUBLIER LES NOTES",style: TextStyle(color: Colors.white),),
              style: ElevatedButton.styleFrom(
                backgroundColor:  const Color.fromARGB(255, 235, 125, 0),
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                textStyle: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

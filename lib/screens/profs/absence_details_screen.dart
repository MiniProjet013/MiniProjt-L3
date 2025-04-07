import 'package:flutter/material.dart';

class AbsenceDetailsScreen extends StatefulWidget {
  final String selectedClass; // ✅ استلام القسم المحدد من الشاشة السابقة
  final String selectedMatiere;
  final String selectedDate;
  final String selectedHeure;

  AbsenceDetailsScreen({
    required this.selectedClass,
    required this.selectedMatiere,
    required this.selectedDate,
    required this.selectedHeure,
  });

  @override
  _AbsenceDetailsScreenState createState() => _AbsenceDetailsScreenState();
}

class _AbsenceDetailsScreenState extends State<AbsenceDetailsScreen> {
  // ✅ قائمة التلاميذ بناءً على القسم المحدد
  Map<String, List<String>> studentsByClass = {
    "Classe 1": ["Ali", "Fatima", "Omar"],
    "Classe 2": ["Youssef", "Sara", "Kamal"],
    "Classe 3": ["Lina", "Hassan", "Meryem"],
  };

  // ✅ قائمة حالات الغياب لكل تلميذ
  Map<String, bool> absences = {};

  @override
  void initState() {
    super.initState();
    // ✅ إعداد القائمة بناءً على القسم المحدد
    if (studentsByClass.containsKey(widget.selectedClass)) {
      for (var student in studentsByClass[widget.selectedClass]!) {
        absences[student] = false; // الافتراضي: الجميع "Présent"
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Color.fromARGB(232, 2, 196, 34),title: Text("Détails des absences")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ عرض المعلومات المحددة مسبقًا
            Text("📚 Matière: ${widget.selectedMatiere}", style: TextStyle(fontSize: 16)),
            Text("📅 Date: ${widget.selectedDate}", style: TextStyle(fontSize: 16)),
            Text("⏰ Heure: ${widget.selectedHeure}", style: TextStyle(fontSize: 16)),
            SizedBox(height: 20),

            // ✅ قائمة التلاميذ مع خيار الحضور/الغياب
            Expanded(
              child: ListView.builder(
                itemCount: studentsByClass[widget.selectedClass]?.length ?? 0,
                itemBuilder: (context, index) {
                  String student = studentsByClass[widget.selectedClass]![index];
                  return Card(
                    elevation: 2,
                    margin: EdgeInsets.symmetric(vertical: 5),
                    child: ListTile(
                      title: Text(student, style: TextStyle(fontSize: 18)),
                      trailing: Switch(
                        value: absences[student]!,
                        onChanged: (value) {
                          setState(() {
                            absences[student] = value;
                          });
                        },
                        activeColor: Colors.red,
                        inactiveTrackColor: Colors.green,
                        inactiveThumbColor: Colors.white,
                      ),
                    ),
                  );
                },
              ),
            ),

            SizedBox(height: 20),

            // ✅ زر الحفظ
            Center(
              child: ElevatedButton(
                onPressed: () {
                  // ✅ تنفيذ حفظ الغيابات
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Absences enregistrées avec succès!")),
                  );
                },
                child: Text("ENREGISTRER"),
                style: ElevatedButton.styleFrom(
                  backgroundColor:   Color.fromARGB(213, 230, 122, 0),
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  textStyle: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

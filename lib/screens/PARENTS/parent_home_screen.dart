import 'package:flutter/material.dart';
import '../../widgets/category_card.dart';
//import '../utils/constants.dart';
import 'voir_notes_screen.dart'; // ✅ استيراد شاشة النقاط

class ParentHomeScreen extends StatefulWidget {
  @override
  _ParentHomeScreenState createState() => _ParentHomeScreenState();
}

class _ParentHomeScreenState extends State<ParentHomeScreen> {
  Map<String, String> enfants = {}; // ✅ تخزين الـ ID مع أسماء الأبناء
  List<TextEditingController> controllers = [TextEditingController()];

  // ✅ قاعدة بيانات محلية لأسماء الأبناء بناءً على الـ ID
  final Map<String, String> database = {
    "123": "Ahmed",
    "456": "Yasmine",
    "789": "Omar",
    "101": "Fatima",
  };

  final List<Map<String, dynamic>> categories = [
    {
      "title": "Voir les notes",
      "icon": Icons.school,
      "route": VoirNotesScreen()
    },
    {
      "title": "Notifications d'absences",
      "icon": Icons.notifications_active,
      "route": null
    },
    {"title": "Emploi du temps", "icon": Icons.calendar_today, "route": null},
    {"title": "Devoirs", "icon": Icons.assignment, "route": null},
    {"title": "Remarques", "icon": Icons.sticky_note_2, "route": null},
    {"title": "Convocations", "icon": Icons.mail, "route": null},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: enfants.isNotEmpty
          ? _buildAppBar()
          : null, // ✅ إظهار AppBar بعد إدخال ID
      body: enfants.isEmpty
          ? _buildIdInputScreen()
          : _buildHomeScreen(), // ✅ التنقل بين الواجهتين
    );
  }

  // ✅ شاشة إدخال ID الأبناء
  Widget _buildIdInputScreen() {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Veuillez entrer les ID de vos enfants",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),

          // ✅ إدخال ID الأبناء
          Column(
            children: List.generate(
              controllers.length,
              (index) => Padding(
                padding: EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    // 🔹 إدخال ID
                    Expanded(
                      child: TextField(
                        controller: controllers[index],
                        decoration: InputDecoration(
                          labelText: "ID de l'enfant ${index + 1}",
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    // 🔹 زر حذف إذا كان أكثر من إدخال واحد
                    if (controllers.length > 1)
                      IconButton(
                        icon: Icon(Icons.remove_circle, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            enfants.remove(controllers[index].text);
                            controllers.removeAt(index);
                          });
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 10),

          // ✅ زر لإضافة ID جديد
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                controllers.add(TextEditingController());
              });
            },
            icon: Icon(Icons.add),
            label: Text(
              "Ajouter un autre ID",
              style: TextStyle(color: Colors.deepOrangeAccent),
            ),
          ),

          SizedBox(height: 20),

          // ✅ زر "Suivant" للانتقال إلى الواجهة الرئيسية
          ElevatedButton(
            onPressed: () {
              Map<String, String> enteredEnfants = {};
              for (var controller in controllers) {
                String id = controller.text.trim();
                if (id.isNotEmpty && database.containsKey(id)) {
                  enteredEnfants[id] = database[id]!;
                }
              }

              if (enteredEnfants.isNotEmpty) {
                setState(() {
                  enfants = enteredEnfants;
                });
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Aucun ID valide n'a été entré")),
                );
              }
            },
            child: Text(
              "Suivant",
              style: TextStyle(color: Colors.deepOrangeAccent),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ الشاشة الرئيسية مع عرض أسماء الأبناء
  Widget _buildHomeScreen() {
    return Column(
      children: [
        SizedBox(height: 10),
        Text(
          "Vos enfants",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),

        // ✅ عرض أسماء الأبناء
        Wrap(
          spacing: 10,
          children: enfants.entries.map((entry) {
            return Chip(
              label: Text(entry.value,
                  style: TextStyle(
                      fontSize: 16,
                      color: const Color.fromARGB(255, 233, 225, 235))),
              avatar: Icon(Icons.child_care,
                  color: const Color.fromARGB(255, 233, 225, 235)),
              backgroundColor: Color.fromARGB(213, 230, 122, 0),
            );
          }).toList(),
        ),

        SizedBox(height: 20),

        Expanded(
          child: Padding(
            padding: EdgeInsets.all(10),
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 1.2,
              ),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    if (categories[index]["route"] != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => categories[index]["route"]),
                      );
                    }
                  },
                  child: CategoryCard(
                    title: categories[index]['title'],
                    icon: categories[index]['icon'],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  // ✅ `AppBar` بنفس التصميم السابق مع اللون البنفسجي
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.family_restroom,
            size: 28,
            color: Colors.white,
          ),
          SizedBox(width: 10),
          Text("Accueil Parent",
              style: TextStyle(
                color: Colors.white,
              )),
        ],
      ),
      backgroundColor: Color.fromARGB(232, 2, 196, 34),
      centerTitle: true,
    );
  }
}

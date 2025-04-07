import 'package:flutter/material.dart';
import '../../widgets/category_card.dart';
import '../../utils/constants.dart';
import 'devoir_screen.dart';
import 'absences_screen.dart';
import 'remarques_screen.dart';
import 'notes_screen.dart';
import 'convocations_screen.dart';
import 'student_list_screen.dart';
import 'portfolio_screen.dart';
import 'examens_screen.dart';

class HomeScreen extends StatelessWidget {
  final List<Map<String, dynamic>> categories = [
    {"title": "PORTFOLIO", "icon": Icons.folder, "route": PortfolioScreen()},
    {"title": "DEVOIRS", "icon": Icons.assignment, "route": DevoirScreen()},
    {"title": "NOTES", "icon": Icons.grade, "route": NotesScreen()},
    {"title": "EMPLOI DU TEMPS", "icon": Icons.schedule},
    {"title": "REMARQUES", "icon": Icons.comment, "route": RemarquesScreen()},
    {"title": "Liste d'eleves", "icon": Icons.people, "route": StudentListScreen()},
    {"title": "ABSENCES", "icon": Icons.event_busy, "route": AbsencesScreen()},
    {"title": "Convocations", "icon": Icons.mail, "route": ConvocationsScreen()},
    {"title": "Evenments", "icon": Icons.event, "route": ExamensScreen()},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // ✅ الجزء العلوي (الخلفية الزرقاء + أيقونة الحساب)
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: 180,
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(100),
                    bottomRight: Radius.circular(100),
                  ),
                ),
              ),
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.white,
                child: Icon(Icons.account_circle, size: 50, color: primaryColor),
              ),
            ],
          ),

          SizedBox(height: 20),

          // ✅ عرض الأيقونات في GridView
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(10),
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      if (categories[index]["route"] != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => categories[index]["route"]),
                        );
                      }
                    },
                    child: CategoryCard(
                      title: categories[index]['title'],
                      icon: categories[index]['icon'], // ✅ استخدام الأيقونة فقط
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

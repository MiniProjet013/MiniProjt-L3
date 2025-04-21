import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/constants.dart';
import 'modifier_prof_screen.dart'; // استيراد واجهة تعديل بيانات الأستاذ

class ModifierProfsScreen extends StatefulWidget {
  @override
  _ModifierProfsScreenState createState() => _ModifierProfsScreenState();
}

class _ModifierProfsScreenState extends State<ModifierProfsScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  bool isLoading = false;
  List<Map<String, dynamic>> profs = [];
  List<Map<String, dynamic>> filteredProfs = [];
  TextEditingController searchController = TextEditingController();
  String? selectedYear;

  final List<String> schoolYears = [
    "Tous",
    "2023-2024",
    "2024-2025",
    "2025-2026",
    "2026-2027",
    "2027-2028"
  ];

  @override
  void initState() {
    super.initState();
    selectedYear = "Tous";
    _loadProfessors();
    searchController.addListener(_filterProfs);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProfessors() async {
    setState(() => isLoading = true);

    try {
      QuerySnapshot querySnapshot;

      if (selectedYear == "Tous") {
        querySnapshot = await _db.collection('profs').get();
      } else {
        querySnapshot = await _db
            .collection('profs')
            .where("anneeScolaire", isEqualTo: selectedYear)
            .get();
      }

      List<Map<String, dynamic>> loadedProfs = querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return {
          "idProf": data["idProf"] ?? "",
          "nom": data["nom"] ?? "",
          "prenom": data["prenom"] ?? "",
          "matiere": data["matiere"] ?? "",
          "email": data["email"] ?? "",
          "numeroClasse": data["numeroClasse"] ?? "",
          "anneeScolaire": data["anneeScolaire"] ?? "",
        };
      }).toList();

      setState(() {
        profs = loadedProfs;
        _filterProfs();
      });
    } catch (e) {
      print("❌ خطأ أثناء تحميل بيانات الأساتذة: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("❌ فشل تحميل بيانات الأساتذة"),
        backgroundColor: Colors.red,
      ));
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _filterProfs() {
    String query = searchController.text.toLowerCase();

    setState(() {
      filteredProfs = profs.where((prof) {
        return prof["nom"].toLowerCase().contains(query) ||
            prof["prenom"].toLowerCase().contains(query) ||
            prof["idProf"].toLowerCase().contains(query) ||
            prof["matiere"].toLowerCase().contains(query) ||
            prof["email"].toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: Text("Modifier Professeurs"),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    labelText: "Rechercher",
                    hintText: "Nom, prénom, matière...",
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    Text("Année scolaire: ", 
                      style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedYear,
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.symmetric(horizontal: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        items: schoolYears.map((year) {
                          return DropdownMenuItem(
                            value: year,
                            child: Text(year),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedYear = value;
                          });
                          _loadProfessors();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : filteredProfs.isEmpty
                    ? Center(
                        child: Text(
                          "Aucun professeur trouvé",
                          style: TextStyle(fontSize: 18),
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredProfs.length,
                        itemBuilder: (context, index) {
                          final prof = filteredProfs[index];
                          return Card(
                            margin: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            elevation: 2,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.deepOrangeAccent,
                                child: Icon(Icons.person, color: Colors.white),
                              ),
                              title: Text(
                                "${prof["nom"]} ${prof["prenom"]}",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Matière: ${prof["matiere"]}"),
                                  Text("Classe: ${prof["numeroClasse"]} - ${prof["anneeScolaire"]}"),
                                  Text("ID: ${prof["idProf"]}", style: TextStyle(fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                              isThreeLine: true,
                              trailing: IconButton(
                                icon: Icon(Icons.edit, color: Colors.blue),
                                onPressed: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ModifierProfScreen(
                                        idProf: prof["idProf"],
                                      ),
                                    ),
                                  );
                                  
                                  // إذا تم تحديث البيانات، نقوم بإعادة تحميل القائمة
                                  if (result == true) {
                                    _loadProfessors();
                                  }
                                },
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
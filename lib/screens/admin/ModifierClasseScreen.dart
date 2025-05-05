import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/constants.dart';

class ModifierClasseScreen extends StatefulWidget {
  final String classId;
  
  ModifierClasseScreen({required this.classId});

  @override
  _ModifierClasseScreenState createState() => _ModifierClasseScreenState();
}

class _ModifierClasseScreenState extends State<ModifierClasseScreen> {
  final TextEditingController idController = TextEditingController();
  final TextEditingController numberController = TextEditingController();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  bool isLoading = true;
  bool isSaving = false;

  final Color orangeColor = Color.fromARGB(255, 218, 64, 3);
  final Color greenColor = Color.fromARGB(255, 1, 110, 5);
  final Color lightColor = Color.fromARGB(255, 255, 255, 255);
  final Color darkColor = Color(0xFF333333);

  final List<String> levels = [
    "1ère année", "2ème année", "3ème année",
    "4ème année", "5ème année", "6ème année"
  ];
  List<String> selectedLevels = [];

  final List<String> schoolYears = [
    "2023-2024",
    "2024-2025",
    "2025-2026",
    "2026-2027",
    "2027-2028"
  ];
  String? selectedYear;

  @override
  void initState() {
    super.initState();
    _loadClassData();
  }

  Future<void> _loadClassData() async {
    try {
      setState(() {
        isLoading = true;
      });

      DocumentSnapshot classDoc = await _db.collection('classes').doc(widget.classId).get();
      
      if (classDoc.exists) {
        Map<String, dynamic> data = classDoc.data() as Map<String, dynamic>;
        
        setState(() {
          idController.text = data['idClasse'] ?? '';
          numberController.text = data['numeroClasse'] ?? '';
          selectedYear = data['anneeScolaire'];
          
          if (data['niveauxEtude'] is List) {
            selectedLevels = List<String>.from(data['niveauxEtude']);
          }
        });
      } else {
        Navigator.pop(context);
      }
    } catch (e) {
      print("❌ Erreur lors du chargement des données: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _updateClass() async {
    String idClasse = idController.text.trim();
    String numeroClasse = numberController.text.trim();

    if (idClasse.isEmpty || numeroClasse.isEmpty || selectedLevels.isEmpty || selectedYear == null) {
      return;
    }

    try {
      setState(() {
        isSaving = true;
      });

      await _db.collection('classes').doc(idClasse).update({
        "numeroClasse": numeroClasse,
        "niveauxEtude": selectedLevels,
        "anneeScolaire": selectedYear,
        "lastUpdated": FieldValue.serverTimestamp(),
      });

      await _updateRelatedStudents(idClasse, numeroClasse);
      await _updateRelatedSchedules(idClasse, numeroClasse);

      Navigator.pop(context, true);

    } catch (e) {
      print("❌ Erreur lors de la modification: $e");
    } finally {
      setState(() {
        isSaving = false;
      });
    }
  }

  Future<void> _updateRelatedStudents(String classId, String newClassName) async {
    QuerySnapshot studentsSnapshot = await _db.collection('students')
      .where('idClasse', isEqualTo: classId)
      .get();

    WriteBatch batch = _db.batch();
    for (var doc in studentsSnapshot.docs) {
      batch.update(doc.reference, {
        'numeroClasse': newClassName,
        'anneeScolaire': selectedYear,
      });
    }
    
    if (studentsSnapshot.docs.isNotEmpty) {
      await batch.commit();
    }
  }

  Future<void> _updateRelatedSchedules(String classId, String newClassName) async {
    QuerySnapshot schedulesSnapshot = await _db.collection('schedules')
      .where('idClasse', isEqualTo: classId)
      .get();

    WriteBatch batch = _db.batch();
    for (var doc in schedulesSnapshot.docs) {
      batch.update(doc.reference, {
        'nomClasse': newClassName,
        'anneeScolaire': selectedYear,
      });
    }
    
    if (schedulesSnapshot.docs.isNotEmpty) {
      await batch.commit();
    }
  }

  Widget _buildInputField(String label, TextEditingController controller, {bool readOnly = false}) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 12, bottom: 4),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: darkColor,
              ),
            ),
          ),
          TextFormField(
            controller: controller,
            readOnly: readOnly,
            decoration: InputDecoration(
              hintText: "Entrez $label",
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.transparent),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.transparent),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: greenColor, width: 1),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightColor,
      body: CustomScrollView(
        slivers: [
          // En-tête avec gradient
          SliverAppBar(
            expandedHeight: 150.0,
            floating: false,
            pinned: true,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [orangeColor.withOpacity(0.8), greenColor.withOpacity(0.8)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'Modifier la Classe',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'ID: ${widget.classId}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Contenu
          isLoading
              ? SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(orangeColor),
                    ),
                  ),
                )
              : SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Champs d'entrée
                        _buildInputField("ID Classe", idController, readOnly: true),
                        _buildInputField("Numéro de classe", numberController),
                        
                        // Sélection de l'année scolaire
                        Container(
                          margin: EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 16, top: 12, bottom: 4),
                                child: Text(
                                  "Année scolaire",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: darkColor,
                                  ),
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButtonFormField<String>(
                                    value: selectedYear,
                                    decoration: InputDecoration(
                                      contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                                      border: InputBorder.none,
                                    ),
                                    icon: Icon(Icons.arrow_drop_down, color: greenColor),
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
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Sélection des niveaux d'étude
                        Container(
                          margin: EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 16, top: 12, bottom: 8),
                                child: Text(
                                  "Niveaux d'étude",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: darkColor,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
                                child: Wrap(
                                  spacing: 8.0,
                                  runSpacing: 8.0,
                                  children: levels.map((level) {
                                    final isSelected = selectedLevels.contains(level);
                                    return InkWell(
                                      onTap: () {
                                        setState(() {
                                          if (isSelected) {
                                            selectedLevels.remove(level);
                                          } else {
                                            selectedLevels.add(level);
                                          }
                                        });
                                      },
                                      child: Container(
                                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: isSelected 
                                              ? orangeColor.withOpacity(0.2) 
                                              : Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: isSelected 
                                                ? orangeColor 
                                                : Colors.grey.shade300,
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (isSelected)
                                              Padding(
                                                padding: const EdgeInsets.only(right: 6),
                                                child: Icon(
                                                  Icons.check,
                                                  size: 16,
                                                  color: orangeColor,
                                                ),
                                              ),
                                            Text(
                                              level,
                                              style: TextStyle(
                                                color: isSelected ? orangeColor : Colors.grey.shade700,
                                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Bouton de sauvegarde
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: isSaving ? null : _updateClass,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: orangeColor,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.grey.shade400,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: isSaving
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Text(
                                        "Enregistrement...",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  )
                                : Text(
                                    "Enregistrer les modifications",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}
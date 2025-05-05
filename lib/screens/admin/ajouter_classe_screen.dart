import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class AjouterClasseScreen extends StatefulWidget {
  @override
  _AjouterClasseScreenState createState() => _AjouterClasseScreenState();
}

class _AjouterClasseScreenState extends State<AjouterClasseScreen> {
  final TextEditingController idController = TextEditingController();
  final TextEditingController numberController = TextEditingController();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

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
  bool isLoading = false;
  
  // Couleurs pour harmoniser avec les autres interfaces
  final Color orangeColor = Color.fromARGB(255, 218, 64, 3);
  final Color greenColor = Color.fromARGB(255, 1, 110, 5);
  final Color lightColor = Color.fromARGB(255, 255, 255, 255);
  final Color darkColor = Color(0xFF333333);

  @override
  void initState() {
    super.initState();
    idController.text = _generateId();
  }

  String _generateId() {
    return "C-${Random().nextInt(9000) + 1000}";
  }

  Future<void> _saveClass() async {
    String idClasse = idController.text.trim();
    String numeroClasse = numberController.text.trim();

    if (idClasse.isEmpty || numeroClasse.isEmpty || selectedLevels.isEmpty || selectedYear == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ Veuillez remplir tous les champs!"), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await _db.collection('classes').doc(idClasse).set({
        "idClasse": idClasse,
        "numeroClasse": numeroClasse,
        "niveauxEtude": selectedLevels,
        "anneeScolaire": selectedYear,
        "timestamp": FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Classe ajoutée avec succès!"), backgroundColor: greenColor),
      );

      // Réinitialiser le formulaire ou revenir à l'écran précédent
      Navigator.pop(context, true);

    } catch (e) {
      print("❌ Erreur lors de l'ajout: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Échec de l'ajout de la classe! Réessayez."), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Widget de champ de saisie personnalisé avec cadre
  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    bool readOnly = false,
    Icon? suffixIcon,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: darkColor.withOpacity(0.2),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: darkColor.withOpacity(0.7),
              ),
            ),
            TextField(
              controller: controller,
              readOnly: readOnly,
              style: TextStyle(
                fontSize: 16,
                color: darkColor,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                suffixIcon: suffixIcon,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget de menu déroulant personnalisé avec cadre
  Widget _buildDropdownField<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12), 
        border: Border.all(
          color: darkColor.withOpacity(0.2),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: darkColor.withOpacity(0.7),
              ),
            ),
            DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value: value,
                items: items,
                onChanged: onChanged,
                isExpanded: true,
                icon: Icon(Icons.arrow_drop_down, color: greenColor),
                style: TextStyle(
                  fontSize: 16,
                  color: darkColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightColor,
      body: CustomScrollView(
        slivers: [
          // AppBar avec gradient
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
                          'Ajouter une classe',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Nouvelle classe",
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
          
          // Formulaire
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Section des informations de la classe
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.all(20),
                    margin: EdgeInsets.only(bottom: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: orangeColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.class_,
                                color: orangeColor,
                                size: 24,
                              ),
                            ),
                            SizedBox(width: 16),
                            Text(
                              "Informations de la classe",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: darkColor,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                        
                        // ID de la classe
                        _buildInputField(
                          controller: idController,
                          label: "ID Classe",
                          readOnly: true,
                          suffixIcon: Icon(Icons.tag, color: greenColor),
                        ),
                        
                        // Numéro de la classe
                        _buildInputField(
                          controller: numberController,
                          label: "Numéro de classe",
                          suffixIcon: Icon(Icons.numbers, color: greenColor),
                        ),
                      ],
                    ),
                  ),
                  
                  // Section informations académiques
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.all(20),
                    margin: EdgeInsets.only(bottom: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: greenColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.school,
                                color: greenColor,
                                size: 24,
                              ),
                            ),
                            SizedBox(width: 16),
                            Text(
                              "Informations académiques",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: darkColor,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                        
                        // Année scolaire
                        _buildDropdownField<String>(
                          label: "Année scolaire",
                          value: selectedYear,
                          items: schoolYears.map((year) {
                            return DropdownMenuItem(value: year, child: Text(year));
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedYear = value;
                            });
                          },
                        ),
                        
                        // Niveaux d'étude
                        Container(
                          margin: EdgeInsets.only(bottom: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10.0),
                                child: Text(
                                  "Niveaux d'étude",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: darkColor,
                                  ),
                                ),
                              ),
                              Wrap(
                                spacing: 10.0,
                                runSpacing: 10.0,
                                children: levels.map((level) {
                                  bool isSelected = selectedLevels.contains(level);
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
                                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: isSelected 
                                            ? greenColor 
                                            : Colors.grey.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(30),
                                        border: Border.all(
                                          color: isSelected
                                              ? greenColor
                                              : darkColor.withOpacity(0.2),
                                          width: 1.0,
                                        ),
                                      ),
                                      child: Text(
                                        level,
                                        style: TextStyle(
                                          color: isSelected ? Colors.white : darkColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Bouton d'enregistrement
                  Container(
                    height: 55,
                    margin: EdgeInsets.only(bottom: 30),
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _saveClass,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: orangeColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                      ),
                      child: isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text(
                            "Enregistrer la classe",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
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
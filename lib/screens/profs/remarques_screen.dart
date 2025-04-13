import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class RemarquesScreen extends StatefulWidget {
  const RemarquesScreen({Key? key}) : super(key: key);

  @override
  _RemarquesScreenState createState() => _RemarquesScreenState();
}

class _RemarquesScreenState extends State<RemarquesScreen> {
  String? selectedClasseId;
  String? selectedEleveId;
  String? selectedDate;
  final TextEditingController remarqueController = TextEditingController();

  List<Map<String, dynamic>> classes = [];
  List<Map<String, dynamic>> eleves = [];
  bool isLoadingClasses = true;
  bool isLoadingEleves = false;

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    // تنفيذ جلب الأقسام بعد بناء الواجهة
    Future.microtask(() => fetchClasses());
  }

  Future<void> fetchClasses() async {
    setState(() {
      isLoadingClasses = true;
    });

    try {
      QuerySnapshot snapshot = await _db.collection('classes')
          .orderBy('timestamp', descending: true)
          .get();

      List<Map<String, dynamic>> loadedClasses = [];
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        loadedClasses.add({
          'id': doc.id,
          'idClasse': data['idClasse'] ?? doc.id,
          'numeroClasse': data['numeroClasse'] ?? 'N/A',
          'anneeScolaire': data['anneeScolaire'] ?? 'N/A',
          'niveauxEtude': data['niveauxEtude'] ?? [],
        });
      }

      setState(() {
        classes = loadedClasses;
        isLoadingClasses = false;
      });
    } catch (e) {
      print("❌ Erreur lors du chargement des classes : $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Échec du chargement des classes!"), backgroundColor: Colors.red),
      );
      setState(() {
        isLoadingClasses = false;
      });
    }
  }

  Future<void> fetchEleves(String classeId) async {
    setState(() {
      isLoadingEleves = true;
      eleves = [];
    });

    try {
      // Essayons d'abord de charger les élèves depuis la collection "eleves" en filtrant par classeId
      QuerySnapshot eleveSnapshot = await _db
          .collection('eleves')
          .where('classeId', isEqualTo: classeId)
          .get();

      if (eleveSnapshot.docs.isNotEmpty) {
        // Si nous avons trouvé des élèves dans la collection "eleves"
        List<Map<String, dynamic>> loadedEleves = [];
        for (var doc in eleveSnapshot.docs) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          loadedEleves.add({
            'id': doc.id,
            'nom': data['nom'] ?? 'N/A',
            'prenom': data['prenom'] ?? 'N/A',
            'nomComplet': "${data['prenom'] ?? ''} ${data['nom'] ?? ''}",
          });
        }
        
        setState(() {
          eleves = loadedEleves;
          isLoadingEleves = false;
        });
      } else {
        // Solution alternative: vérifier s'il y a un champ "eleves" dans le document de classe
        DocumentSnapshot classeDoc = await _db
            .collection('classes')
            .doc(classeId)
            .get();

        if (classeDoc.exists) {
          Map<String, dynamic> classeData = classeDoc.data() as Map<String, dynamic>;
          
          if (classeData.containsKey('eleves') && classeData['eleves'] is List) {
            List<dynamic> elevesList = classeData['eleves'];
            List<Map<String, dynamic>> loadedEleves = [];
            
            for (int i = 0; i < elevesList.length; i++) {
              var eleve = elevesList[i];
              
              // Vérifier si l'élève est une chaîne ou un objet
              if (eleve is String) {
                loadedEleves.add({
                  'id': 'eleve-$i',
                  'nomComplet': eleve,
                });
              } else if (eleve is Map) {
                loadedEleves.add({
                  'id': eleve['id'] ?? 'eleve-$i',
                  'nom': eleve['nom'] ?? 'N/A',
                  'prenom': eleve['prenom'] ?? 'N/A',
                  'nomComplet': "${eleve['prenom'] ?? ''} ${eleve['nom'] ?? ''}",
                });
              }
            }
            
            setState(() {
              eleves = loadedEleves;
              isLoadingEleves = false;
            });
          } else {
            setState(() {
              eleves = [];
              isLoadingEleves = false;
            });
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Aucun élève trouvé pour cette classe."),
                backgroundColor: Colors.orange,
              ),
            );
          }
        } else {
          setState(() {
            isLoadingEleves = false;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("La classe sélectionnée n'existe pas."),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print("❌ Erreur lors du chargement des élèves : $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Échec du chargement des élèves!"),
          backgroundColor: Colors.red,
        ),
      );
      
      setState(() {
        isLoadingEleves = false;
      });
    }
  }

  Future<void> saveRemarque() async {
    if (selectedClasseId == null || 
        selectedEleveId == null || 
        selectedDate == null || 
        remarqueController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Veuillez remplir tous les champs."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Trouver les détails de la classe et de l'élève pour les inclure dans la remarque
    Map<String, dynamic> selectedClasseData = classes.firstWhere(
      (classe) => classe['id'] == selectedClasseId,
      orElse: () => {},
    );
    
    Map<String, dynamic> selectedEleveData = eleves.firstWhere(
      (eleve) => eleve['id'] == selectedEleveId,
      orElse: () => {},
    );

    try {
      await _db.collection('remarques').add({
        'classeId': selectedClasseId,
        'classeNumero': selectedClasseData['numeroClasse'] ?? 'N/A',
        'classeNiveaux': selectedClasseData['niveauxEtude'] ?? [],
        'anneeScolaire': selectedClasseData['anneeScolaire'] ?? 'N/A',
        'eleveId': selectedEleveId,
        'eleveNom': selectedEleveData['nomComplet'] ?? 'N/A',
        'date': selectedDate,
        'remarque': remarqueController.text,
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("✅ Remarque ajoutée avec succès!"),
          backgroundColor: Colors.green,
        ),
      );
      
      // Réinitialiser les champs
      setState(() {
        selectedEleveId = null;
        selectedDate = null;
        remarqueController.clear();
      });
    } catch (e) {
      print("❌ Erreur lors de l'ajout de la remarque: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Erreur lors de l'ajout de la remarque."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Remarques"),
        backgroundColor: Color.fromARGB(232, 2, 196, 34),
      ),
      body: isLoadingClasses
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titre de la page
                  Center(
                    child: Text(
                      "Ajouter une remarque",
                      style: TextStyle(
                        fontSize: 22, 
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(232, 2, 196, 34),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  
                  // Section Classe
                  Container(
                    padding: EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Classe",
                          style: TextStyle(
                            fontSize: 16, 
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 8),
                        classes.isEmpty 
                          ? Text(
                              "Aucune classe disponible",
                              style: TextStyle(color: Colors.red),
                            )
                          : DropdownButtonFormField<String>(
                              value: selectedClasseId,
                              decoration: InputDecoration(
                                hintText: "Sélectionner une classe",
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              items: classes.map((classe) {
                                String displayText = "Classe ${classe['numeroClasse']}";
                                if (classe['niveauxEtude'] is List && (classe['niveauxEtude'] as List).isNotEmpty) {
                                  displayText += " - ${(classe['niveauxEtude'] as List).join(', ')}";
                                }
                                return DropdownMenuItem<String>(
                                  value: classe['id'],
                                  child: Text(displayText),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedClasseId = value;
                                  selectedEleveId = null;
                                });
                                if (value != null) {
                                  fetchEleves(value);
                                }
                              },
                            ),
                      ],
                    ),
                  ),

                  SizedBox(height: 15),

                  // Section Élève
                  Container(
                    padding: EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Élève",
                          style: TextStyle(
                            fontSize: 16, 
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 8),
                        isLoadingEleves
                          ? Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 10),
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : DropdownButtonFormField<String>(
                              value: selectedEleveId,
                              decoration: InputDecoration(
                                hintText: selectedClasseId == null 
                                  ? "Veuillez d'abord sélectionner une classe" 
                                  : "Sélectionner un élève",
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              items: eleves.map((eleve) {
                                return DropdownMenuItem<String>(
                                  value: eleve['id'],
                                  child: Text(eleve['nomComplet']),
                                );
                              }).toList(),
                              onChanged: selectedClasseId == null
                                ? null
                                : (value) {
                                    setState(() {
                                      selectedEleveId = value;
                                    });
                                  },
                            ),
                      ],
                    ),
                  ),

                  SizedBox(height: 15),

                  // Section Date
                  Container(
                    padding: EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Date",
                          style: TextStyle(
                            fontSize: 16, 
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 8),
                        TextFormField(
                          decoration: InputDecoration(
                            hintText: "Sélectionner une date",
                            suffixIcon: Icon(Icons.calendar_today),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          readOnly: true,
                          controller: TextEditingController(text: selectedDate ?? ''),
                          onTap: () async {
                            DateTime? pickedDate = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: ColorScheme.light(
                                      primary: Color.fromARGB(232, 2, 196, 34),
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (pickedDate != null) {
                              setState(() {
                                selectedDate = "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 15),

                  // Section Remarque
                  Container(
                    padding: EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Remarque",
                          style: TextStyle(
                            fontSize: 16, 
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 8),
                        TextFormField(
                          controller: remarqueController,
                          maxLines: 5,
                          decoration: InputDecoration(
                            hintText: "Écrire une remarque...",
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 25),

                  // Bouton pour publier
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        saveRemarque();
                      },
                      icon: Icon(Icons.check, color: Colors.white),
                      label: Text(
                        "Enregistrer la remarque",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrangeAccent,
                        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
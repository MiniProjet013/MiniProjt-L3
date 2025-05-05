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

  // Couleurs pour correspondre au style AjouterProfScreen
  final Color orangeColor = Color.fromARGB(255, 218, 64, 3);
  final Color greenColor = Color.fromARGB(232, 2, 196, 34);
  final Color lightColor = Color.fromARGB(255, 255, 255, 255);
  final Color darkColor = Color(0xFF333333);

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
          content: Text("✅ Convocation ajoutée avec succès!"),
          backgroundColor: greenColor,
        ),
      );
      
      // Réinitialiser les champs
      setState(() {
        selectedEleveId = null;
        selectedDate = null;
        remarqueController.clear();
      });
    } catch (e) {
      print("❌ Erreur lors de l'ajout de la convocation: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Erreur lors de l'ajout de la convocation."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Widget de champ de saisie personnalisé avec cadre
  Widget _buildInputField({
    required String label,
    TextEditingController? controller,
    bool readOnly = false,
    bool multiline = false,
    Icon? suffixIcon,
    VoidCallback? onTap,
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
            if (controller != null)
              TextField(
                controller: controller,
                readOnly: readOnly,
                maxLines: multiline ? 5 : 1,
                onTap: onTap,
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

  // Widget pour les menus déroulants
  Widget _buildDropdownField<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
    bool isLoading = false,
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
            isLoading
                ? Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(greenColor),
                        ),
                      ),
                    ),
                  )
                : DropdownButtonHideUnderline(
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
                          'Convocations',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Ajouter une nouvelle convocation",
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
          
          // Formulaire ou indicateur de chargement
          isLoadingClasses
              ? SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(orangeColor),
                        ),
                        SizedBox(height: 16),
                        Text(
                          "Chargement des données...",
                          style: TextStyle(
                            fontSize: 16,
                            color: darkColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Section Classe
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
                                    "Sélection de la classe",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: darkColor,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 20),
                              
                              _buildDropdownField<String>(
                                label: "Classe",
                                value: selectedClasseId,
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
                        
                        // Section Élève
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
                                      Icons.person,
                                      color: greenColor,
                                      size: 24,
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Text(
                                    "Informations de l'élève",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: darkColor,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 20),
                              
                              _buildDropdownField<String>(
                                label: "Élève",
                                value: selectedEleveId,
                                isLoading: isLoadingEleves,
                                items: eleves.map((eleve) {
                                  return DropdownMenuItem<String>(
                                    value: eleve['id'],
                                    child: Text(eleve['nomComplet']),
                                  );
                                }).toList(),
                                onChanged: selectedClasseId == null
                                  ? (value) {}
                                  : (value) {
                                      setState(() {
                                        selectedEleveId = value;
                                      });
                                    },
                              ),
                              
                              _buildInputField(
                                label: "Date de convocation",
                                controller: TextEditingController(text: selectedDate ?? ''),
                                readOnly: true,
                                suffixIcon: Icon(Icons.calendar_today, color: greenColor),
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
                                            primary: greenColor,
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
                        
                        // Section Remarque
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
                                      Icons.description,
                                      color: orangeColor,
                                      size: 24,
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Text(
                                    "Détails de la convocation",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: darkColor,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 20),
                              
                              _buildInputField(
                                label: "Motif de la convocation",
                                controller: remarqueController,
                                multiline: true,
                              ),
                            ],
                          ),
                        ),
                        
                        // Bouton d'enregistrement
                        Container(
                          height: 55,
                          margin: EdgeInsets.only(bottom: 30),
                          child: ElevatedButton(
                            onPressed: saveRemarque,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: orangeColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 3,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.save),
                                SizedBox(width: 8),
                                Text(
                                  "Enregistrer la convocation",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
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
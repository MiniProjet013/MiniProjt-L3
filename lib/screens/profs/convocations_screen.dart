import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ConvocationsScreen extends StatefulWidget {
  @override
  _ConvocationsScreenState createState() => _ConvocationsScreenState();
}

class _ConvocationsScreenState extends State<ConvocationsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Controllers
  String? selectedClasseId;
  String? selectedEleveId;
  TextEditingController messageController = TextEditingController();

  // Dropdown Data
  List<Map<String, dynamic>> classes = [];
  List<Map<String, dynamic>> eleves = [];
  bool isLoading = false;

  // Couleurs pour correspondre au style AjouterProfScreen
  final Color orangeColor = Color.fromARGB(255, 218, 64, 3);
  final Color greenColor = Color.fromARGB(255, 1, 110, 5);
  final Color lightColor = Color.fromARGB(255, 255, 255, 255);
  final Color darkColor = Color(0xFF333333);

  @override
  void initState() {
    super.initState();
    _fetchClasses();
  }

  // Fetch classes from Firebase
  Future<void> _fetchClasses() async {
    setState(() {
      isLoading = true;
    });
    
    try {
      final snapshot = await _firestore.collection('classes').get();
      setState(() {
        classes = snapshot.docs
            .map((doc) => {
                  'idClasse': doc.data()['idClasse'],
                  'numeroClasse': doc.data()['numeroClasse'].toString(),
                  'niveaux': doc.data()['niveauxEtude'][0], // Example for levels
                })
            .toList();
      });
    } catch (e) {
      print("Erreur lors du chargement des classes: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("❌ Échec du chargement des classes!"),
        backgroundColor: Colors.red,
      ));
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Fetch students based on selected class
  Future<void> _fetchEleves(String classeId) async {
    setState(() {
      isLoading = true;
    });
    
    try {
      final snapshot = await _firestore
          .collection('eleves')
          .where('classeId', isEqualTo: classeId)
          .get();
      setState(() {
        eleves = snapshot.docs
            .map((doc) => {
                  'idEleve': doc.data()['idEleve'],
                  'nom': doc.data()['nom'],
                  'prenom': doc.data()['prenom'],
                })
            .toList();
      });
    } catch (e) {
      print("Erreur lors du chargement des élèves: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("❌ Échec du chargement des élèves!"),
        backgroundColor: Colors.red,
      ));
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Submit convocation to Firebase
  Future<void> _submitConvocation() async {
    if (selectedClasseId != null &&
        selectedEleveId != null &&
        messageController.text.isNotEmpty) {
      setState(() {
        isLoading = true;
      });
      
      try {
        // Ajouter une convocation dans Firestore
        await _firestore.collection('convocation').add({
          'classeId': selectedClasseId,
          'eleveId': selectedEleveId,
          'message': messageController.text,
          'timestamp': DateTime.now(),
        });
        
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("✅ Remarque ajoutée avec succès !"),
          backgroundColor: greenColor,
        ));
        
        messageController.clear();
        setState(() {
          selectedClasseId = null;
          selectedEleveId = null;
          eleves = [];
        });
      } catch (e) {
        // Afficher l'erreur exacte
        print("Erreur lors de l'ajout de la convocation : $e");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("❌ Erreur : $e"),
          backgroundColor: Colors.red,
        ));
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("⚠️ Veuillez remplir tous les champs !"),
        backgroundColor: Colors.orange,
      ));
    }
  }

  // Widget de champ de saisie personnalisé avec cadre
  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    bool readOnly = false,
    int maxLines = 1,
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
              maxLines: maxLines,
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
                      padding: EdgeInsets.symmetric(vertical: 8.0),
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
                      hint: Text(
                        "Sélectionner une option",
                        style: TextStyle(
                          fontSize: 16,
                          color: darkColor.withOpacity(0.5),
                        ),
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
                    colors: [
                      orangeColor.withOpacity(0.8),
                      greenColor.withOpacity(0.8)
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.mail, color: Colors.white, size: 28),
                            SizedBox(width: 10),
                            Text(
                              'REMARQUES',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Envoyer une remarque à un élève",
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

          // Contenu principal
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Section sélection de la classe et de l'élève
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
                                Icons.school,
                                color: orangeColor,
                                size: 24,
                              ),
                            ),
                            SizedBox(width: 16),
                            Text(
                              "Sélection de l'élève",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: darkColor,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),

                        // Dropdown pour la classe
                        _buildDropdownField<String>(
                          label: "CLASSE",
                          value: selectedClasseId,
                          isLoading: isLoading && classes.isEmpty,
                          items: classes.map((classe) {
                            return DropdownMenuItem<String>(
                              value: classe['idClasse'] as String,
                              child: Text(
                                  '${classe['niveaux'] as String} - Classe ${classe['numeroClasse'] as String}'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedClasseId = value;
                              selectedEleveId = null;
                              eleves = [];
                            });
                            if (value != null) {
                              _fetchEleves(value);
                            }
                          },
                        ),

                        // Dropdown pour l'élève
                        _buildDropdownField<String>(
                          label: "ÉLÈVE",
                          value: selectedEleveId,
                          isLoading: isLoading && selectedClasseId != null && eleves.isEmpty,
                          items: eleves.map((eleve) {
                            return DropdownMenuItem<String>(
                              value: eleve['idEleve'] as String,
                              child: Text(
                                  '${eleve['prenom'] as String} ${eleve['nom'] as String}'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedEleveId = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                  // Section message
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
                                Icons.message,
                                color: greenColor,
                                size: 24,
                              ),
                            ),
                            SizedBox(width: 16),
                            Text(
                              "Contenu de la remarque",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: darkColor,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),

                        // Champ de texte pour le message
                        _buildInputField(
                          controller: messageController,
                          label: "MESSAGE",
                          maxLines: 5,
                          suffixIcon: Icon(Icons.edit, color: greenColor),
                        ),
                      ],
                    ),
                  ),

                  // Bouton d'envoi
                  Container(
                    height: 55,
                    margin: EdgeInsets.only(bottom: 30),
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _submitConvocation,
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
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.send),
                                SizedBox(width: 10),
                                Text(
                                  "ENVOYER LA REMARQUE",
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
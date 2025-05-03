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

  @override
  void initState() {
    super.initState();
    _fetchClasses();
  }

  // Fetch classes from Firebase
  Future<void> _fetchClasses() async {
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
  }

  // Fetch students based on selected class
  Future<void> _fetchEleves(String classeId) async {
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
  }

  // Submit convocation to Firebase
  Future<void> _submitConvocation() async {
    if (selectedClasseId != null &&
        selectedEleveId != null &&
        messageController.text.isNotEmpty) {
      try {
        // Ajouter une convocation dans Firestore
        await _firestore.collection('convocation').add({
          'classeId': selectedClasseId,
          'eleveId': selectedEleveId,
          'message': messageController.text,
          'timestamp': DateTime.now(),
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Convocation ajoutée avec succès !"),
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
          content: Text("Erreur : $e"),
        ));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Veuillez remplir tous les champs !"),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(232, 2, 196, 34),
        title: Row(
          children: [
            Icon(Icons.mail, color: Colors.white),
            SizedBox(width: 10),
            Text("CONVOCATIONS", style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Dropdown for Classes
            _buildDropdown(
              label: "CLASSE",
              items: classes.map((classe) {
                return {
                  'value': classe['idClasse'] as String,
                  'label':
                      '${classe['niveaux'] as String} - Classe ${classe['numeroClasse'] as String}',
                };
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
              value: selectedClasseId,
            ),

            // Dropdown for Eleves
            _buildDropdown(
              label: "ÉLÈVE",
              items: eleves.map((eleve) {
                return {
                  'value': eleve['idEleve'] as String,
                  'label':
                      '${eleve['prenom'] as String} ${eleve['nom'] as String}',
                };
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedEleveId = value;
                });
              },
              value: selectedEleveId,
            ),

            // TextField for Message
            TextField(
              controller: messageController,
              decoration: InputDecoration(
                labelText: "MESSAGE",
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            SizedBox(height: 20),

            // Submit Button
            ElevatedButton(
              onPressed: _submitConvocation,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(185, 255, 123, 0),
                shape: StadiumBorder(),
              ),
              child: Text("ENVOYER", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // Dropdown Widget Builder
  Widget _buildDropdown({
    required String label,
    required List<Map<String, String>> items,
    required ValueChanged<String?> onChanged,
    String? value,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        items: items
            .map((item) => DropdownMenuItem<String>(
                  value: item['value'],
                  child: Text(item['label']!),
                ))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}
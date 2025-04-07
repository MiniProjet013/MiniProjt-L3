import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class ModifierProfsScreen extends StatefulWidget {
  @override
  _ModifierProfsScreenState createState() => _ModifierProfsScreenState();
}

class _ModifierProfsScreenState extends State<ModifierProfsScreen> {
  final TextEditingController searchController = TextEditingController();
  bool isLoading = false;
  StreamController<bool> filterStreamController =
      StreamController<bool>.broadcast();

  @override
  void dispose() {
    filterStreamController.close();
    searchController.dispose();
    super.dispose();
  }

  void _updateFilters() {
    filterStreamController.add(true);
  }

  void _clearFilters() {
    setState(() {
      searchController.clear();
      _updateFilters();
    });
  }

  void _showEditDialog(BuildContext context, Map<String, dynamic> prof) {
    TextEditingController nameController =
        TextEditingController(text: prof["nom"]);
    TextEditingController prenomController =
        TextEditingController(text: prof["prenom"]);
    TextEditingController emailController =
        TextEditingController(text: prof["email"] ?? '');
    TextEditingController phoneController =
        TextEditingController(text: prof["telephone"] ?? '');
    TextEditingController classeController =
        TextEditingController(text: prof["numeroClasse"]?.toString() ?? '');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Modifier Professeur",
              style: TextStyle(
                  color: Colors.green[700], fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: "Nom",
                    labelStyle: TextStyle(color: Colors.green[700]),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.green[700]!),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: prenomController,
                  decoration: InputDecoration(
                    labelText: "Prénom",
                    labelStyle: TextStyle(color: Colors.green[700]),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.green[700]!),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: "Email",
                    labelStyle: TextStyle(color: Colors.green[700]),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.green[700]!),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: 10),
                TextField(
                  controller: phoneController,
                  decoration: InputDecoration(
                    labelText: "Téléphone",
                    labelStyle: TextStyle(color: Colors.green[700]),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.green[700]!),
                    ),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                SizedBox(height: 10),
                TextField(
                  controller: classeController,
                  decoration: InputDecoration(
                    labelText: "Numéro de Classe",
                    labelStyle: TextStyle(color: Colors.green[700]),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.green[700]!),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text("Annuler", style: TextStyle(color: Colors.red)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
              ),
              child: Text("Enregistrer", style: TextStyle(color: Colors.white)),
              onPressed: () {
                if (nameController.text.isEmpty ||
                    prenomController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Le nom et prénom sont obligatoires"),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                _updateProfData(
                  context,
                  prof["idProf"],
                  nameController.text,
                  prenomController.text,
                  emailController.text,
                  phoneController.text,
                  int.tryParse(classeController.text) ?? 0,
                );
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateProfData(
    BuildContext context,
    String idProf,
    String nom,
    String prenom,
    String email,
    String telephone,
    int numeroClasse,
  ) async {
    setState(() {
      isLoading = true;
    });

    try {
      await FirebaseFirestore.instance.collection('profs').doc(idProf).update({
        "nom": nom,
        "prenom": prenom,
        "email": email.isNotEmpty ? email : FieldValue.delete(),
        "telephone": telephone.isNotEmpty ? telephone : FieldValue.delete(),
        "numeroClasse": numeroClasse > 0 ? numeroClasse : FieldValue.delete(),
        "lastUpdated": FieldValue.serverTimestamp(),
        "displayText": "$prenom $nom"
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("✅ Professeur mis à jour avec succès!"),
          backgroundColor: Colors.green[700],
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Erreur lors de la mise à jour: ${e.toString()}"),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: searchController,
      decoration: InputDecoration(
        labelText: "Rechercher par nom/prénom",
        labelStyle: TextStyle(color: Colors.green[700]),
        prefixIcon: Icon(Icons.search, color: Colors.green[700]),
        suffixIcon: searchController.text.isEmpty
            ? null
            : IconButton(
                icon: Icon(Icons.clear, color: Colors.red),
                onPressed: () {
                  setState(() {
                    searchController.clear();
                    _updateFilters();
                  });
                },
              ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: Colors.green[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: Colors.green[700]!, width: 2.0),
        ),
        filled: true,
        fillColor: Colors.grey[100],
      ),
      onChanged: (value) => _updateFilters(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green[700],
        title:
            Text("Modifier Professeurs", style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _clearFilters,
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Barre de recherche
            _buildSearchBar(),
            SizedBox(height: 20),

            // Liste des professeurs
            Expanded(
              child: Stack(
                children: [
                  StreamBuilder<bool>(
                    stream: filterStreamController.stream,
                    builder: (context, _) {
                      return StreamBuilder<List<QueryDocumentSnapshot>>(
                        stream: _fetchProfs(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                                  ConnectionState.waiting &&
                              !snapshot.hasData) {
                            return Center(
                                child: CircularProgressIndicator(
                                    color: Colors.green[700]));
                          }

                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.person_off,
                                      size: 64, color: Colors.grey),
                                  SizedBox(height: 16),
                                  Text(
                                    "Aucun professeur trouvé",
                                    style: TextStyle(
                                        fontSize: 18, color: Colors.grey),
                                  ),
                                ],
                              ),
                            );
                          }

                          final docs = snapshot.data!;
                          return ListView.builder(
                            itemCount: docs.length,
                            itemBuilder: (context, index) {
                              final doc = docs[index];
                              final prof = doc.data() as Map<String, dynamic>;

                              return Card(
                                elevation: 2,
                                margin: EdgeInsets.symmetric(vertical: 6),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                  side: BorderSide(
                                      color: Colors.green[100]!, width: 1),
                                ),
                                child: ListTile(
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.green[700],
                                    child: Text(
                                      "${prof["prenom"][0]}${prof["nom"][0]}"
                                          .toUpperCase(),
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  title: Text(
                                    "${prof["prenom"]} ${prof["nom"]}",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(height: 4),
                                      if (prof["email"] != null)
                                        Text("Email: ${prof["email"]}"),
                                      if (prof["numeroClasse"] != null)
                                        Text("Classe: ${prof["numeroClasse"]}"),
                                    ],
                                  ),
                                  trailing: IconButton(
                                    icon:
                                        Icon(Icons.edit, color: Colors.orange),
                                    onPressed: () {
                                      _showEditDialog(context, {
                                        ...prof,
                                        "idProf": doc.id,
                                      });
                                    },
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                  if (isLoading)
                    Container(
                      color: Colors.black.withOpacity(0.3),
                      child: Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Stream<List<QueryDocumentSnapshot>> _fetchProfs() {
    Query query = FirebaseFirestore.instance.collection('profs').orderBy("nom");

    if (searchController.text.isNotEmpty) {
      String searchText = searchController.text.toLowerCase();
      return query.snapshots().map((snapshot) {
        return snapshot.docs.where((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          String nom = (data['nom'] ?? '').toLowerCase();
          String prenom = (data['prenom'] ?? '').toLowerCase();
          return nom.contains(searchText) || prenom.contains(searchText);
        }).toList();
      });
    }

    return query.snapshots().map((snapshot) => snapshot.docs);
  }
}

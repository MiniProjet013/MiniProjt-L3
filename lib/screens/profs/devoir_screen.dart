import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeworkScreen extends StatefulWidget {
  const HomeworkScreen({Key? key}) : super(key: key);

  @override
  State<HomeworkScreen> createState() => _HomeworkScreenState();
}

class _HomeworkScreenState extends State<HomeworkScreen> {
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _correctionController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  bool _isCorrectionMode = false;
  String? _selectedHomeworkId;
  List<QueryDocumentSnapshot> _homeworks = [];

  // Couleurs pour correspondre au style AjouterProfScreen
  final Color orangeColor = Color.fromARGB(255, 218, 64, 3);
  final Color greenColor = Color.fromARGB(255, 1, 110, 5);
  final Color lightColor = Color.fromARGB(255, 255, 255, 255);
  final Color darkColor = Color(0xFF333333);

  @override
  void initState() {
    super.initState();
    _loadHomeworks();
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _correctionController.dispose();
    super.dispose();
  }

  // Load homeworks from Firestore
  Future<void> _loadHomeworks() async {
    try {
      QuerySnapshot querySnapshot = await _firestore.collection('devoir').get();
      setState(() {
        _homeworks = querySnapshot.docs;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur de chargement: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Function to add homework to Firestore
  Future<void> _addHomework() async {
    if (_subjectController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ Veuillez écrire un sujet'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Create a new document in the "devoir" collection
      await _firestore.collection('devoir').add({
        'subject': _subjectController.text,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Devoir ajouté avec succès!'),
          backgroundColor: greenColor,
        ),
      );
      _subjectController.clear();
      _loadHomeworks(); // Refresh the list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Function to add correction to an existing homework
  Future<void> _addCorrection() async {
    setState(() {
      _isCorrectionMode = true;
    });

    if (_homeworks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ Aucun devoir trouvé pour ajouter une correction'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show a dialog to select which homework to add a correction to
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: greenColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.assignment, color: greenColor),
            ),
            SizedBox(width: 12),
            Text('Choisir un devoir'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _homeworks.length,
            itemBuilder: (context, index) {
              final homework = _homeworks[index];
              return Container(
                margin: EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: darkColor.withOpacity(0.1),
                  ),
                ),
                child: ListTile(
                  title: Text(
                    homework['subject'],
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: darkColor,
                    ),
                  ),
                  leading: Icon(Icons.description, color: orangeColor),
                  onTap: () {
                    setState(() {
                      _selectedHomeworkId = homework.id;
                      _subjectController.text = homework['subject'];
                    });
                    Navigator.pop(context);
                  },
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _isCorrectionMode = false;
              });
            },
            child: Text(
              'Annuler',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );

    if (_selectedHomeworkId == null) {
      setState(() {
        _isCorrectionMode = false;
      });
    }
  }

  // Function to submit correction
  Future<void> _submitCorrection() async {
    if (_correctionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ Veuillez écrire une correction'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Update the selected homework document with the correction
      await _firestore.collection('devoir').doc(_selectedHomeworkId).update({
        'correction': _correctionController.text,
        'correctionTimestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Correction ajoutée avec succès!'),
          backgroundColor: greenColor,
        ),
      );
      
      setState(() {
        _isCorrectionMode = false;
        _selectedHomeworkId = null;
        _subjectController.clear();
        _correctionController.clear();
      });
      
      _loadHomeworks(); // Refresh the list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Cancel correction mode
  void _cancelCorrection() {
    setState(() {
      _isCorrectionMode = false;
      _selectedHomeworkId = null;
      _subjectController.clear();
      _correctionController.clear();
    });
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
                          'Devoirs',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          _isCorrectionMode ? "Ajouter une correction" : "Ajouter un devoir",
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
                  // Section principale
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
                                Icons.assignment,
                                color: orangeColor,
                                size: 24,
                              ),
                            ),
                            SizedBox(width: 16),
                            Text(
                              _isCorrectionMode ? "Ajouter une correction" : "Ajouter un devoir",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: darkColor,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                        
                        // Champ de saisie pour le sujet
                        _buildInputField(
                          controller: _subjectController,
                          label: "Sujet du devoir",
                          readOnly: _isCorrectionMode,
                          maxLines: 3,
                          suffixIcon: Icon(Icons.subject, color: greenColor),
                        ),
                        
                        // Champ de correction (si en mode correction)
                        if (_isCorrectionMode)
                          _buildInputField(
                            controller: _correctionController,
                            label: "Correction",
                            maxLines: 5,
                            suffixIcon: Icon(Icons.edit_note, color: greenColor),
                          ),
                        
                        SizedBox(height: 20),
                        
                        // Boutons d'action
                        if (_isCorrectionMode) ...[
                          // Boutons en mode correction
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 55,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _submitCorrection,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: greenColor,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 3,
                                    ),
                                    child: _isLoading
                                        ? CircularProgressIndicator(color: Colors.white)
                                        : Text(
                                            "Enregistrer la correction",
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 10),
                              Container(
                                height: 55,
                                child: ElevatedButton(
                                  onPressed: _cancelCorrection,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey.shade500,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 3,
                                  ),
                                  child: Text(
                                    "Annuler",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          // Bouton pour ajouter un devoir
                          Container(
                            height: 55,
                            margin: EdgeInsets.only(bottom: 20),
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _addHomework,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: orangeColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 3,
                              ),
                              child: _isLoading
                                  ? CircularProgressIndicator(color: Colors.white)
                                  : Text(
                                      "Ajouter le devoir",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                          
                          // Séparateur
                          Container(
                            margin: EdgeInsets.symmetric(vertical: 16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Divider(color: darkColor.withOpacity(0.2)),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    "OU",
                                    style: TextStyle(
                                      color: darkColor.withOpacity(0.6),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(color: darkColor.withOpacity(0.2)),
                                ),
                              ],
                            ),
                          ),
                          
                          // Bouton pour ajouter une correction
                          Container(
                            height: 55,
                            child: ElevatedButton(
                              onPressed: _addCorrection,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: greenColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 3,
                              ),
                              child: Text(
                                "Ajouter une correction",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  // Section des devoirs récents
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
                                Icons.history,
                                color: greenColor,
                                size: 24,
                              ),
                            ),
                            SizedBox(width: 16),
                            Text(
                              "Devoirs récents",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: darkColor,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                        
                        // Liste des devoirs récents
                        _homeworks.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Text(
                                    "Aucun devoir disponible",
                                    style: TextStyle(
                                      color: darkColor.withOpacity(0.6),
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                itemCount: _homeworks.length > 5 ? 5 : _homeworks.length,
                                itemBuilder: (context, index) {
                                  final homework = _homeworks[index];
                                  final hasCorrection = homework.data().toString().contains('correction');
                                  
                                  return Container(
                                    margin: EdgeInsets.only(bottom: 8),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: darkColor.withOpacity(0.1),
                                      ),
                                    ),
                                    child: ListTile(
                                      title: Text(
                                        homework['subject'],
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          color: darkColor,
                                        ),
                                      ),
                                      subtitle: hasCorrection
                                          ? Text(
                                              "Correction disponible",
                                              style: TextStyle(
                                                color: greenColor,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            )
                                          : Text(
                                              "Pas encore corrigé",
                                              style: TextStyle(
                                                color: orangeColor,
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                      leading: Container(
                                        padding: EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: hasCorrection
                                              ? greenColor.withOpacity(0.1)
                                              : orangeColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          hasCorrection ? Icons.check_circle : Icons.pending,
                                          color: hasCorrection ? greenColor : orangeColor,
                                        ),
                                      ),
                                      trailing: Icon(
                                        Icons.arrow_forward_ios,
                                        size: 16,
                                        color: darkColor.withOpacity(0.3),
                                      ),
                                      onTap: () {
                                        // Action pour voir les détails du devoir
                                        // Pourrait être implémenté dans une future mise à jour
                                      },
                                    ),
                                  );
                                },
                              ),
                      ],
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
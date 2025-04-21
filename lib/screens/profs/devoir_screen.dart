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
        const SnackBar(
          content: Text('Veuillez écrire un sujet'),
          backgroundColor: Color(0xFF4CAF50),
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
        const SnackBar(
          content: Text('Devoir ajouté avec succès!'),
          backgroundColor: Color(0xFF4CAF50),
        ),
      );
      _subjectController.clear();
      _loadHomeworks(); // Refresh the list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
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
        const SnackBar(
          content: Text('Aucun devoir trouvé pour ajouter une correction'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show a dialog to select which homework to add a correction to
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choisir un devoir'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _homeworks.length,
            itemBuilder: (context, index) {
              final homework = _homeworks[index];
              return ListTile(
                title: Text(homework['subject']),
                onTap: () {
                  setState(() {
                    _selectedHomeworkId = homework.id;
                    _subjectController.text = homework['subject'];
                  });
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
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
        const SnackBar(
          content: Text('Veuillez écrire une correction'),
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
        const SnackBar(
          content: Text('Correction ajoutée avec succès!'),
          backgroundColor: Color(0xFF4CAF50),
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
          content: Text('Erreur: ${e.toString()}'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.assignment, color: Colors.white),
            SizedBox(width: 8),
            Text('DEVOIRS'),
          ],
        ),
        backgroundColor: const Color(0xFF4CAF50),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Subject Label
            Text(
              _isCorrectionMode ? 'SUJET (lecture seule)' : 'SUJET',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Subject Text Field (Larger)
            TextField(
              controller: _subjectController,
              readOnly: _isCorrectionMode, // Read-only in correction mode
              maxLines: 3, // Make it larger
              decoration: InputDecoration(
                hintText: 'Écrire le sujet...',
                border: const OutlineInputBorder(),
                filled: _isCorrectionMode,
                fillColor: _isCorrectionMode ? Colors.grey[200] : null,
              ),
            ),
            const SizedBox(height: 16),

            // Correction Field (shown only in correction mode)
            if (_isCorrectionMode) ...[
              const Text(
                'CORRECTION',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _correctionController,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: 'Écrire la correction...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              
              // Submit and Cancel buttons for correction mode
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitCorrection,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('ENREGISTRER LA CORRECTION'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _cancelCorrection,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('ANNULER'),
                  ),
                ],
              ),
            ] else ...[
              // Add Homework Button (shown only in normal mode)
              ElevatedButton(
                onPressed: _isLoading ? null : _addHomework,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE67E22),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('AJOUTER LE DEVOIR'),
              ),

              // OR Divider
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Center(
                  child: Text(
                    'OU',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              // Add Correction Button
              ElevatedButton(
                onPressed: _addCorrection,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE67E22),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('METTRE LA CORRECTION'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
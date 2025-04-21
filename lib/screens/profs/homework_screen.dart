import 'package:flutter/material.dart';

class HomeworkScreen extends StatefulWidget {
  const HomeworkScreen({Key? key}) : super(key: key);

  @override
  State<HomeworkScreen> createState() => _HomeworkScreenState();
}

class _HomeworkScreenState extends State<HomeworkScreen> {
  final TextEditingController _subjectController = TextEditingController();

  @override
  void dispose() {
    _subjectController.dispose();
    super.dispose();
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
        backgroundColor:
            const Color(0xFF4CAF50), // Green color from first image
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
            const Text(
              'SUJET',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Subject Text Field
            TextField(
              controller: _subjectController,
              decoration: const InputDecoration(
                hintText: 'Écrire le sujet...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            // Add Homework Button
            ElevatedButton(
              onPressed: () {
                // Handle add homework button press
                if (_subjectController.text.isNotEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ajout du devoir en cours...'),
                      backgroundColor: Color(0xFF4CAF50), // Green color
                    ),
                  );
                  _subjectController.clear();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Veuillez écrire un sujet'),
                      backgroundColor: Color(0xFF4CAF50), // Green color
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(0xFFE67E22), // Orange color from first image
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('AJOUTER LE DEVOIR'),
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
              onPressed: () {
                // Handle add correction button press
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ajout de la correction en cours...'),
                    backgroundColor: Color(0xFF4CAF50), // Green color
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(0xFFE67E22), // Orange color from first image
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('METTRE LA CORRECTION'),
            ),
          ],
        ),
      ),
    );
  }
}

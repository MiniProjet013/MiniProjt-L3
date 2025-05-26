import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MoyenneAnnuelleScreen extends StatefulWidget {
  final String studentId;

  const MoyenneAnnuelleScreen({super.key, required this.studentId});

  @override
  State<MoyenneAnnuelleScreen> createState() => _MoyenneAnnuelleScreenState();
}

class _MoyenneAnnuelleScreenState extends State<MoyenneAnnuelleScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String selectedTrimester = '1er trimestre'; // Trimestre sélectionné

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // En-tête avec gradient comme dans les autres interfaces
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              colors: [Color.fromARGB(255, 40, 141, 0), Color.fromARGB(255, 63, 136, 3)],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Barre de navigation
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Text(
                          "MOYENNE TRIMESTRIELLE",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),
                  
                  // Sélecteur du trimestre
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 32),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButton<String>(
                        value: selectedTrimester,
                        onChanged: (newValue) {
                          setState(() {
                            selectedTrimester = newValue!;
                          });
                        },
                        items: ['1er trimestre', '2ème trimestre', '3ème trimestre']
                            .map((trimester) => DropdownMenuItem(
                          value: trimester,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              trimester,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ))
                            .toList(),
                        underline: Container(),
                        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                        isExpanded: true,
                        dropdownColor: const Color.fromARGB(255, 218, 88, 2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Affichage des moyennes après sélection
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchStudentAverages(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4285F4)),
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          "Erreur de chargement",
                          style: TextStyle(
                            color: Colors.grey[800],
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          snapshot.error.toString(),
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => setState(() {}),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4285F4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "Réessayer",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.assignment_outlined,
                          size: 60,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Aucune note disponible",
                          style: TextStyle(
                            color: Colors.grey[800],
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Pour le $selectedTrimester",
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                final averages = snapshot.data!;
                final overallAverage = _calculateOverallAverage(averages);
                final (strongPoints, weakPoints) = _analyzePerformance(averages);

                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Carte de la moyenne générale
                        _buildOverallAverageCard(overallAverage),
                        
                        const SizedBox(height: 20),
                        
                        // Tableau des moyennes par matière
                        _buildAveragesTable(averages),
                        
                        const SizedBox(height: 20),
                        
                        // Points forts et points faibles
                        _buildPerformanceAnalysis(strongPoints, weakPoints),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Carte de la moyenne générale
  Widget _buildOverallAverageCard(double overallAverage) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'Moyenne Générale',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _getGradeColor(overallAverage).withOpacity(0.2),
                    _getGradeColor(overallAverage).withOpacity(0.4),
                  ],
                ),
              ),
              child: Text(
                '${overallAverage.toStringAsFixed(2)}', // Modifié pour afficher /10
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: _getGradeColor(overallAverage),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _getAppreciation(overallAverage),
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Tableau des moyennes par matière
  Widget _buildAveragesTable(List<Map<String, dynamic>> averages) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Détail par matière',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 20,
                columns: const [
                  DataColumn(
                    label: Text(
                      "Matière",
                      style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4285F4)),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      "Examen",
                      style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4285F4)),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      "Devoir",
                      style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4285F4)),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      "Moyenne",
                      style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4285F4)),
                    ),
                  ),
                ],
                rows: averages.map((avg) {
                  return DataRow(
                    cells: [
                      DataCell(
                        Text(
                          avg['matiere'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataCell(
                        Text(
                          '${avg['examen'].toStringAsFixed(2)}', // Modifié pour afficher /10
                          style: TextStyle(
                            color: _getNoteColor(avg['examen']),
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          '${avg['devoir'].toStringAsFixed(2)}', // Modifié pour afficher /10
                          style: TextStyle(
                            color: _getNoteColor(avg['devoir']),
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getGradeColor(avg['moyenne']).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${avg['moyenne'].toStringAsFixed(2)}', // Modifié pour afficher /10
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _getGradeColor(avg['moyenne']),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Analyse des performances (points forts/faibles)
  Widget _buildPerformanceAnalysis(List<String> strongPoints, List<String> weakPoints) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Analyse des performances',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),
            
            // Points forts
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.thumb_up, color: Colors.green, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Points forts',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (strongPoints.isEmpty)
                        Text(
                          'Aucun point fort identifié',
                          style: TextStyle(color: Colors.grey[600]),
                        )
                      else
                        ...strongPoints.map((matiere) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '• $matiere',
                            style: TextStyle(color: Colors.grey[800]),
                          ),
                        )),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Points faibles
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.thumb_down, color: Colors.red, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Points à améliorer',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (weakPoints.isEmpty)
                        Text(
                          'Aucun point faible identifié',
                          style: TextStyle(color: Colors.grey[600]),
                        )
                      else
                        ...weakPoints.map((matiere) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '• $matiere',
                            style: TextStyle(color: Colors.grey[800]),
                          ),
                        )),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Fonction pour analyser les performances
  (List<String>, List<String>) _analyzePerformance(List<Map<String, dynamic>> averages) {
    List<String> strongPoints = [];
    List<String> weakPoints = [];
    
    for (var avg in averages) {
      if (avg['moyenne'] >= 7) { // Modifié pour système sur 10
        strongPoints.add(avg['matiere']);
      } else if (avg['moyenne'] < 5) { // Modifié pour système sur 10
        weakPoints.add(avg['matiere']);
      }
    }
    
    return (strongPoints, weakPoints);
  }

  // Fonction pour obtenir une appréciation textuelle (adaptée pour 10)
  String _getAppreciation(double moyenne) {
    if (moyenne >= 8) return 'Excellente performance ! Continue comme ça !';
    if (moyenne >= 7) return 'Très bon travail, tu peux encore progresser !';
    if (moyenne >= 6) return 'Bon travail, quelques efforts supplémentaires seraient bénéfiques.';
    if (moyenne >= 5) return 'Résultats corrects, mais des progrès sont nécessaires.';
    return 'Des efforts importants sont nécessaires pour améliorer tes résultats.';
  }

  // Fonction pour obtenir la couleur en fonction de la note (adaptée pour 10)
  Color _getNoteColor(double note) {
    if (note >= 8) return const Color(0xFF4CAF50); // Vert
    if (note >= 6) return const Color(0xFF8BC34A); // Vert clair
    if (note >= 4) return const Color(0xFFFFA726);  // Orange
    return const Color(0xFFF44336);  // Rouge
  }

  // Fonction pour obtenir la couleur en fonction de la moyenne (adaptée pour 10)
  Color _getGradeColor(double? grade) {
    if (grade == null) return Colors.grey;
    if (grade >= 8) return const Color(0xFF4CAF50); // Vert
    if (grade >= 7) return const Color(0xFF8BC34A); // Vert clair
    if (grade >= 6) return const Color(0xFFFFA726); // Orange
    return const Color(0xFFF44336); // Rouge
  }

  Future<List<Map<String, dynamic>>> _fetchStudentAverages() async {
    List<Map<String, dynamic>> allAverages = [];

    var devoirsSnapshot = await _firestore.collection('note_devoir').get();
    var examensSnapshot = await _firestore.collection('note_examen').get();

    List<Map<String, dynamic>> devoirs = _extractNotes(devoirsSnapshot.docs, 'Devoir');
    List<Map<String, dynamic>> examens = _extractNotes(examensSnapshot.docs, 'Examen');

    // Calcul des moyennes par matière
    Map<String, Map<String, double>> subjectData = {};

    for (var exam in examens) {
      String matiere = exam['matiere'];
      // Convertir la note d'examen de 20 à 10
      double examNote = (exam['note'] ?? 0.0) / 2;

      double devoirNote = devoirs.firstWhere(
            (devoir) => devoir['matiere'] == matiere,
        orElse: () => {'note': 0.0},
      )['note'] / 2; // Convertir la note de devoir de 20 à 10

      double moyenne = ['Arabe', 'Français', 'Math'].contains(matiere)
          ? (examNote + devoirNote) / 2
          : examNote;

      subjectData[matiere] = {
        'examen': examNote,
        'devoir': devoirNote,
        'moyenne': moyenne,
      };
    }

    subjectData.forEach((matiere, data) {
      allAverages.add({
        'matiere': matiere,
        'examen': data['examen'],
        'devoir': data['devoir'],
        'moyenne': data['moyenne'],
      });
    });

    return allAverages;
  }

  double _calculateOverallAverage(List<Map<String, dynamic>> averages) {
    double total = averages.fold(0.0, (sum, avg) => sum + avg['moyenne']);
    return averages.isNotEmpty ? total / averages.length : 0.0;
  }

  List<Map<String, dynamic>> _extractNotes(List<QueryDocumentSnapshot> docs, String type) {
    List<Map<String, dynamic>> notes = [];

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;

      if (data.containsKey(selectedTrimester)) {
        final trimestreData = data[selectedTrimester];
        if (trimestreData is Map<String, dynamic> && trimestreData.containsKey(widget.studentId)) {
          final studentNoteData = trimestreData[widget.studentId];
          if (studentNoteData is Map<String, dynamic>) {
            notes.add({
              'matiere': data['matiere'] ?? 'Matière inconnue',
              'note': studentNoteData['note']?.toDouble() ?? 0.0,
            });
          }
        }
      }
    }
    return notes;
  }
}
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class NotesExamensScreen extends StatefulWidget {
  final String studentId;

  const NotesExamensScreen({super.key, required this.studentId});

  @override
  State<NotesExamensScreen> createState() => _NotesExamensScreenState();
}

class _NotesExamensScreenState extends State<NotesExamensScreen> with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late TabController _tabController;
  String? _selectedMatiere;
  List<Map<String, dynamic>> _allNotes = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadNotes();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadNotes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final snapshot = await _firestore
          .collection('note_examen')
          .orderBy('dateCreation', descending: true)
          .get();

      if (snapshot.docs.isEmpty) {
        setState(() {
          _allNotes = [];
          _isLoading = false;
        });
        return;
      }

      _allNotes = _extractNotes(snapshot.docs);
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _extractNotes(List<QueryDocumentSnapshot> docs) {
    List<Map<String, dynamic>> notes = [];

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      
      // Vérifie les trois trimestres possibles
      final trimestres = ['1er trimestre', '2ème trimestre', '3ème trimestre'];
      
      for (String trimestre in trimestres) {
        if (data.containsKey(trimestre)) {
          final trimestreData = data[trimestre];
          if (trimestreData is Map<String, dynamic> && 
              trimestreData.containsKey(widget.studentId)) {
            
            final studentNoteData = trimestreData[widget.studentId];
            if (studentNoteData is Map<String, dynamic>) {
              notes.add({
                'note': studentNoteData['note'],
                'nomComplet': studentNoteData['nomComplet'] ?? 'Inconnu',
                'date': _parseDate(data),
                'matiere': data['matiere'] ?? 'Matière inconnue',
                'trimestre': trimestre,
                'classe': data['classe'] ?? 'Inconnue',
                'anneeScolaire': data['anneeScolaire'] ?? data['anneSocialre'] ?? '',
                'commentaire': studentNoteData['commentaire'] ?? '',
              });
            }
          }
        }
      }
    }

    return notes;
  }

  DateTime _parseDate(Map<String, dynamic> data) {
    try {
      if (data['dateCreation'] is Timestamp) {
        return (data['dateCreation'] as Timestamp).toDate();
      } else if (data['dateCreation'] is String) {
        return DateFormat('d MMMM yyyy', 'fr_FR')
            .parse(data['dateCreation'].split(' à ')[0]);
      }
    } catch (e) {
      debugPrint('Erreur parsing date: $e');
    }
    return DateTime.now();
  }

  List<String> get _matieres {
    final Set<String> matieres = _allNotes.map((note) => note['matiere'] as String).toSet();
    final List<String> matieresList = matieres.toList()..sort();
    return ['Toutes les matières', ...matieresList];
  }

  List<Map<String, dynamic>> get _filteredNotes {
    if (_selectedMatiere == null || _selectedMatiere == 'Toutes les matières') {
      return _allNotes.where((note) {
        final trimestre = note['trimestre'];
        if (_tabController.index == 0) return trimestre == '1er trimestre';
        if (_tabController.index == 1) return trimestre == '2ème trimestre';
        return trimestre == '3ème trimestre';
      }).toList();
    }
    
    return _allNotes.where((note) {
      final matiere = note['matiere'];
      final trimestre = note['trimestre'];
      
      bool correctTrimestre = false;
      if (_tabController.index == 0) correctTrimestre = trimestre == '1er trimestre';
      else if (_tabController.index == 1) correctTrimestre = trimestre == '2ème trimestre';
      else correctTrimestre = trimestre == '3ème trimestre';
      
      return matiere == _selectedMatiere && correctTrimestre;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // En-tête avec gradient comme dans VoirNotesScreen
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF4285F4), Color(0xFF5B6AF0)],
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
                          "NOTES D'EXAMENS",
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
                  // TabBar
                  TabBar(
                    controller: _tabController,
                    onTap: (_) => setState(() {}),
                    tabs: const [
                      Tab(text: "1er Trimestre"),
                      Tab(text: "2ème Trimestre"),
                      Tab(text: "3ème Trimestre"),
                    ],
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white70,
                    indicatorColor: Colors.white,
                    indicatorWeight: 3,
                    indicatorSize: TabBarIndicatorSize.label,
                  ),
                ],
              ),
            ),
          ),
          
          // Corps du contenu
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4285F4)),
                    ),
                  )
                : _error != null
                    ? _buildErrorWidget(_error!)
                    : _allNotes.isEmpty
                        ? _buildEmptyWidget()
                        : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final filteredNotes = _filteredNotes;
    
    return Column(
      children: [
        // Filtre par matière
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Filtrer par matière',
                labelStyle: TextStyle(color: Color(0xFF4285F4)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Color(0xFF4285F4), width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              value: _selectedMatiere ?? 'Toutes les matières',
              style: TextStyle(color: Colors.black87, fontSize: 16),
              dropdownColor: Colors.white,
              icon: Icon(Icons.arrow_drop_down, color: Color(0xFF4285F4)),
              isExpanded: true,
              items: _matieres.map((matiere) {
                return DropdownMenuItem<String>(
                  value: matiere,
                  child: Text(matiere),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedMatiere = value;
                });
              },
            ),
          ),
        ),
        
        // Liste des notes
        Expanded(
          child: filteredNotes.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.info_outline, size: 64, color: Color(0xFF4285F4).withOpacity(0.5)),
                    const SizedBox(height: 16),
                    Text(
                      'Aucune note disponible',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pour ${_selectedMatiere ?? 'ce trimestre'}',
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredNotes.length,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) => _buildNoteCard(filteredNotes[index]),
              ),
        ),
      ],
    );
  }

  Widget _buildNoteCard(Map<String, dynamic> note) {
    final noteValue = note['note']?.toDouble() ?? 0;
    final noteColor = _getNoteColor(noteValue);
    final DateTime noteDate = note['date'];

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          // En-tête de la carte avec matière et note
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: noteColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    note['matiere'],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: noteColor.withOpacity(0.8),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: noteColor.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    '${noteValue.toStringAsFixed(1)}/20',
                    style: TextStyle(
                      color: noteColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Corps de la carte avec les informations
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow("Élève", note['nomComplet'], Icons.person),
                _buildInfoRow("Classe", note['classe'], Icons.school),
                _buildInfoRow("Date de l'examen", DateFormat('dd/MM/yyyy').format(noteDate), Icons.calendar_today),
                _buildInfoRow("Année scolaire", note['anneeScolaire'], Icons.date_range),
                
                if (note['commentaire'] != null && note['commentaire'].isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.comment, size: 18, color: Color(0xFF4285F4)),
                          SizedBox(width: 8),
                          Text(
                            "Commentaire du professeur :",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4285F4),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 8, left: 26),
                        padding: const EdgeInsets.all(12),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.2),
                          ),
                        ),
                        child: Text(
                          note['commentaire'],
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Color(0xFF5B6AF0)),
          const SizedBox(width: 8),
          SizedBox(
            width: 110,
            child: Text(
              "$label :",
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getNoteColor(double note) {
    if (note >= 16) return Color(0xFF4CAF50); // Vert
    if (note >= 12) return Color(0xFF8BC34A); // Vert clair
    if (note >= 8) return Color(0xFFFFA726);  // Orange
    return Color(0xFFF44336);                 // Rouge
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Color(0xFFF44336), size: 64),
          const SizedBox(height: 24),
          const Text(
            'Erreur de chargement', 
            style: TextStyle(
              fontSize: 20, 
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadNotes,
            icon: const Icon(Icons.refresh, color: Colors.white),
            label: const Text('Réessayer', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF4285F4),
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment,
            color: Color(0xFF4285F4),
            size: 64,
          ),
          const SizedBox(height: 24),
          const Text(
            'Aucune note disponible',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
          ),
          Text(
            'Pour l\'élève: ${widget.studentId}',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadNotes,
            icon: const Icon(Icons.refresh, color: Colors.white),
            label: const Text('Actualiser', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF4285F4),
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}